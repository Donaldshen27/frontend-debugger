const { spawn } = require('child_process');
const fs = require('fs').promises;
const path = require('path');
const { Client } = require('pg');
const winston = require('winston');
const axios = require('axios');

// Configure logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

// Database configuration
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'frontend_debugger',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres'
};

// n8n webhook URL for callbacks
const N8N_WEBHOOK_URL = process.env.N8N_WEBHOOK_URL || 'http://localhost:5678/webhook/frontend-debug-callback';

class ClaudeMonitor {
  constructor(targetUrl, sessionId) {
    this.targetUrl = targetUrl;
    this.sessionId = sessionId;
    this.completedPages = [];
    this.issues = [];
    this.currentPage = null;
    this.claudeProcess = null;
    this.db = null;
    this.tokenCount = 0;
  }

  async initialize() {
    // Connect to database
    this.db = new Client(dbConfig);
    await this.db.connect();
    logger.info('Connected to database');

    // Create new session
    const result = await this.db.query(
      'INSERT INTO sessions (started_at, target_url) VALUES (NOW(), $1) RETURNING id',
      [this.targetUrl]
    );
    this.sessionId = result.rows[0].id;
    logger.info(`Created session ${this.sessionId}`);
  }

  async startClaude(resumeContext = null) {
    const promptPath = path.join(__dirname, '../../claude/prompts/frontend-debug-prompt.md');
    const mcpConfigPath = path.join(__dirname, '../../claude/mcp/puppeteer-config.json');
    
    // Read and prepare prompt
    let prompt = await fs.readFile(promptPath, 'utf8');
    prompt = prompt.replace('{{url}}', this.targetUrl);
    prompt = prompt.replace('{{completed_pages}}', resumeContext || 'None');

    // Start Claude process
    const args = [
      '--dangerously-skip-permissions',
      '--mcp-config', mcpConfigPath,
      '-p', prompt,
      '--output-format', 'stream-json'
    ];

    logger.info('Starting Claude with args:', args);
    this.claudeProcess = spawn('claude', args);

    // Handle stdout
    this.claudeProcess.stdout.on('data', async (data) => {
      const output = data.toString();
      await this.processOutput(output);
    });

    // Handle stderr
    this.claudeProcess.stderr.on('data', (data) => {
      logger.error('Claude stderr:', data.toString());
    });

    // Handle exit
    this.claudeProcess.on('exit', async (code) => {
      logger.info(`Claude process exited with code ${code}`);
      await this.handleClaudeExit(code);
    });
  }

  async processOutput(output) {
    try {
      // Try to parse as JSON first (stream-json format)
      const lines = output.split('\n').filter(line => line.trim());
      
      for (const line of lines) {
        if (line.startsWith('{')) {
          try {
            const json = JSON.parse(line);
            if (json.content) {
              await this.parseMarkers(json.content);
            }
          } catch (e) {
            // Not JSON, process as regular text
            await this.parseMarkers(line);
          }
        } else {
          await this.parseMarkers(line);
        }
      }
    } catch (error) {
      logger.error('Error processing output:', error);
    }
  }

  async parseMarkers(content) {
    // Check for page completion
    const pageCompleteMatch = content.match(/\[PAGE_COMPLETE: (.+?)\]/);
    if (pageCompleteMatch) {
      const url = pageCompleteMatch[1];
      await this.handlePageComplete(url);
    }

    // Check for issues
    const issueMatches = content.matchAll(/\[ISSUE: (CRITICAL|HIGH|MEDIUM|LOW)\] (.+?) - (.+)/g);
    for (const match of issueMatches) {
      await this.handleIssue({
        severity: match[1],
        pageUrl: match[2],
        description: match[3]
      });
    }

    // Check for memory clear request
    if (content.includes('[CLEAR_MEMORY_REQUEST]')) {
      await this.handleMemoryClear();
    }

    // Check for all pages complete
    if (content.includes('[ALL_PAGES_COMPLETE]')) {
      await this.handleAllPagesComplete();
    }

    // Check for errors
    const errorMatch = content.match(/\[ERROR: (.+?)\]/);
    if (errorMatch) {
      await this.handleError(errorMatch[1]);
    }

    // Track token usage (approximate)
    this.tokenCount += content.length / 4; // Rough approximation
  }

  async handlePageComplete(url) {
    logger.info(`Page completed: ${url}`);
    
    // Save to database
    await this.db.query(
      'INSERT INTO pages (session_id, url, status, completed_at, token_count) VALUES ($1, $2, $3, NOW(), $4)',
      [this.sessionId, url, 'complete', this.tokenCount]
    );

    this.completedPages.push(url);
    
    // Notify n8n
    await this.notifyN8n('page_complete', { url, tokenCount: this.tokenCount });
  }

  async handleIssue(issue) {
    logger.info(`Issue found: ${issue.severity} - ${issue.pageUrl} - ${issue.description}`);
    
    // Save to database
    await this.db.query(
      'INSERT INTO issues (session_id, page_url, severity, description) VALUES ($1, $2, $3, $4)',
      [this.sessionId, issue.pageUrl, issue.severity, issue.description]
    );

    this.issues.push(issue);
    
    // Notify n8n
    await this.notifyN8n('issue_found', issue);
  }

  async handleMemoryClear() {
    logger.info('Memory clear requested');
    
    // Kill current Claude process
    if (this.claudeProcess) {
      this.claudeProcess.kill();
    }

    // Prepare resume context
    const resumeContext = this.completedPages.join(', ');
    
    // Wait a bit then restart
    setTimeout(() => {
      this.startClaude(resumeContext);
    }, 2000);
  }

  async handleAllPagesComplete() {
    logger.info('All pages completed');
    
    // Update session
    await this.db.query(
      'UPDATE sessions SET completed_at = NOW(), status = $1 WHERE id = $2',
      ['complete', this.sessionId]
    );

    // Notify n8n
    await this.notifyN8n('all_complete', {
      completedPages: this.completedPages,
      totalIssues: this.issues.length,
      issues: this.issues
    });

    // Clean up
    await this.cleanup();
  }

  async handleError(error) {
    logger.error(`Claude reported error: ${error}`);
    
    // Notify n8n
    await this.notifyN8n('error', { error });
  }

  async handleClaudeExit(code) {
    if (code !== 0) {
      logger.error(`Claude exited abnormally with code ${code}`);
      await this.notifyN8n('claude_crashed', { exitCode: code });
    }
  }

  async notifyN8n(event, data) {
    try {
      await axios.post(N8N_WEBHOOK_URL, {
        sessionId: this.sessionId,
        event,
        data,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      logger.error('Failed to notify n8n:', error.message);
    }
  }

  async cleanup() {
    if (this.claudeProcess) {
      this.claudeProcess.kill();
    }
    if (this.db) {
      await this.db.end();
    }
  }
}

// Main execution
async function main() {
  const targetUrl = process.env.TARGET_URL || process.argv[2];
  const sessionId = process.env.SESSION_ID || process.argv[3];

  if (!targetUrl) {
    console.error('Usage: node monitor-claude.js <target_url> [session_id]');
    process.exit(1);
  }

  const monitor = new ClaudeMonitor(targetUrl, sessionId);
  
  try {
    await monitor.initialize();
    await monitor.startClaude();
  } catch (error) {
    logger.error('Fatal error:', error);
    await monitor.cleanup();
    process.exit(1);
  }

  // Handle graceful shutdown
  process.on('SIGINT', async () => {
    logger.info('Received SIGINT, shutting down gracefully');
    await monitor.cleanup();
    process.exit(0);
  });
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { ClaudeMonitor };