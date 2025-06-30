const { spawn } = require('child_process');
const fs = require('fs').promises;
const path = require('path');
const winston = require('winston');

// Configure logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.printf(({ timestamp, level, message }) => {
      return `[${timestamp}] ${level.toUpperCase()}: ${message}`;
    })
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.colorize({ all: true })
    })
  ]
});

class ButtonTestMonitor {
  constructor(targetUrl, outputDir) {
    this.targetUrl = targetUrl;
    this.outputDir = outputDir;
    this.reportPath = path.join(outputDir, 'tested-buttons-and-pages.md');
    this.currentPage = null;
    this.buttons = new Map(); // selector -> button data
    this.issues = [];
    this.screenshots = [];
    this.currentButton = null;
    this.currentViewport = '1920';
    this.stats = {
      totalButtons: 0,
      buttonsWithIssues: 0,
      criticalIssues: 0,
      highIssues: 0,
      mediumIssues: 0,
      lowIssues: 0,
      statesTested: 0
    };
  }

  async initialize() {
    logger.info(`Monitoring button tests for: ${this.targetUrl}`);
    logger.info(`Output directory: ${this.outputDir}`);
    
    // Initialize report
    await this.updateReport();
  }

  async processLine(line) {
    // Page loaded
    const pageLoadMatch = line.match(/\[PAGE_LOADED: (.+?)\]/);
    if (pageLoadMatch) {
      this.currentPage = pageLoadMatch[1];
      logger.info(`Page loaded: ${this.currentPage}`);
      return;
    }

    // Button found
    const buttonMatch = line.match(/\[BUTTON_FOUND: (.+?)\]\s*(.*)/);
    if (buttonMatch) {
      const selector = buttonMatch[1].trim();
      const text = buttonMatch[2].trim();
      this.stats.totalButtons++;
      
      this.buttons.set(selector, {
        selector,
        text: text || 'No text',
        states: {},
        cssProperties: {},
        issues: [],
        screenshots: []
      });
      
      this.currentButton = selector;
      logger.info(`Found button: ${selector} - ${text}`);
      await this.updateReport();
      return;
    }

    // CSS state testing
    const stateMatch = line.match(/\[CSS_STATE: (.+?)\]\s*(.+)/);
    if (stateMatch) {
      const state = stateMatch[1];
      const selector = stateMatch[2].trim();
      
      if (this.buttons.has(selector)) {
        this.buttons.get(selector).states[state] = true;
        this.stats.statesTested++;
        logger.info(`Testing ${state} state for: ${selector}`);
      }
      await this.updateReport();
      return;
    }

    // CSS property capture
    const propertyMatch = line.match(/\[CSS_PROPERTY: (.+?)\]\s*(.+)/);
    if (propertyMatch && this.currentButton) {
      const property = propertyMatch[1];
      const value = propertyMatch[2];
      
      const button = this.buttons.get(this.currentButton);
      if (button) {
        if (!button.cssProperties[property]) {
          button.cssProperties[property] = {};
        }
        button.cssProperties[property].current = value;
      }
      return;
    }

    // CSS issue found
    const issueMatch = line.match(/\[CSS_ISSUE: (.+?)\]\s*(.+?)\s*-\s*(.+)/);
    if (issueMatch) {
      const severity = issueMatch[1];
      const selector = issueMatch[2].trim();
      const description = issueMatch[3].trim();
      
      const issue = {
        severity,
        selector,
        description,
        viewport: this.currentViewport
      };
      
      this.issues.push(issue);
      
      // Update stats
      this.stats[`${severity.toLowerCase()}Issues`]++;
      
      // Add to button's issues
      if (this.buttons.has(selector)) {
        this.buttons.get(selector).issues.push(issue);
        if (!this.stats.buttonsWithIssues) {
          this.stats.buttonsWithIssues = 0;
        }
      }
      
      logger.warn(`${severity} issue: ${selector} - ${description}`);
      await this.updateReport();
      return;
    }

    // Screenshot saved
    const screenshotMatch = line.match(/\[SCREENSHOT: (.+?)\]/);
    if (screenshotMatch) {
      const filename = screenshotMatch[1];
      this.screenshots.push(filename);
      
      if (this.currentButton && this.buttons.has(this.currentButton)) {
        this.buttons.get(this.currentButton).screenshots.push(filename);
      }
      
      logger.info(`Screenshot saved: ${filename}`);
      return;
    }

    // Viewport change
    const viewportMatch = line.match(/\[VIEWPORT_TEST: (.+?)px\]/);
    if (viewportMatch) {
      this.currentViewport = viewportMatch[1];
      logger.info(`Testing at viewport: ${this.currentViewport}px`);
      return;
    }

    // Test complete for button
    const completeMatch = line.match(/\[TEST_COMPLETE: (.+?)\]/);
    if (completeMatch) {
      const selector = completeMatch[1];
      logger.info(`Completed testing: ${selector}`);
      
      // Count buttons with issues
      if (this.buttons.has(selector)) {
        const button = this.buttons.get(selector);
        if (button.issues.length > 0) {
          this.stats.buttonsWithIssues++;
        }
      }
      
      await this.updateReport();
      return;
    }

    // All tests complete
    if (line.includes('[ALL_TESTS_COMPLETE]')) {
      logger.info('All button tests completed!');
      await this.finalizeReport();
      return;
    }
  }

  async updateReport() {
    const domain = this.targetUrl.replace(/https?:\/\//, '').replace(/\/.*/, '');
    const timestamp = new Date().toISOString();
    
    let report = `# Button & CSS Test Report for ${domain}\n`;
    report += `Generated: ${timestamp}\n\n`;
    
    // Summary section
    report += `## Summary\n`;
    report += `- Target URL: ${this.targetUrl}\n`;
    report += `- Total Buttons Found: ${this.stats.totalButtons}\n`;
    report += `- Buttons with Issues: ${this.stats.buttonsWithIssues || 0}\n`;
    report += `- Total States Tested: ${this.stats.statesTested}\n`;
    report += `- CSS Issues Found: ${this.issues.length}\n`;
    if (this.issues.length > 0) {
      report += `  - Critical: ${this.stats.criticalIssues}\n`;
      report += `  - High: ${this.stats.highIssues}\n`;
      report += `  - Medium: ${this.stats.mediumIssues}\n`;
      report += `  - Low: ${this.stats.lowIssues}\n`;
    }
    report += `\n`;
    
    // Current page section
    if (this.currentPage) {
      report += `## Current Page: ${this.currentPage}\n\n`;
    }
    
    // Buttons section
    if (this.buttons.size > 0) {
      report += `## Buttons Tested\n\n`;
      
      for (const [selector, button] of this.buttons) {
        report += `### Button: ${button.text}\n`;
        report += `- **Selector**: \`${selector}\`\n`;
        
        // States tested
        const statesList = Object.keys(button.states);
        if (statesList.length > 0) {
          report += `- **States Tested**: `;
          report += statesList.map(state => {
            return `✅ ${state.charAt(0).toUpperCase() + state.slice(1)}`;
          }).join(' ');
          report += '\n';
        }
        
        // CSS Properties
        if (Object.keys(button.cssProperties).length > 0) {
          report += `- **CSS Properties**:\n`;
          for (const [prop, values] of Object.entries(button.cssProperties)) {
            report += `  - ${prop}: \`${values.current}\`\n`;
          }
        }
        
        // Screenshots
        if (button.screenshots.length > 0) {
          report += `- **Screenshots**: `;
          report += button.screenshots.map(s => `[${s}](screenshots/${s})`).join(', ');
          report += '\n';
        }
        
        // Issues
        if (button.issues.length > 0) {
          report += `- **Issues**:\n`;
          for (const issue of button.issues) {
            const icon = this.getSeverityIcon(issue.severity);
            report += `  - ${icon} **${issue.severity}**: ${issue.description}`;
            if (issue.viewport !== '1920') {
              report += ` (at ${issue.viewport}px)`;
            }
            report += '\n';
          }
        } else {
          report += `- **Issues**: None found ✅\n`;
        }
        
        report += '\n';
      }
    }
    
    // Issues section
    if (this.issues.length > 0) {
      report += `## All Issues\n\n`;
      
      // Group by severity
      const groupedIssues = {
        CRITICAL: [],
        HIGH: [],
        MEDIUM: [],
        LOW: []
      };
      
      for (const issue of this.issues) {
        if (groupedIssues[issue.severity]) {
          groupedIssues[issue.severity].push(issue);
        }
      }
      
      for (const [severity, issues] of Object.entries(groupedIssues)) {
        if (issues.length > 0) {
          const icon = this.getSeverityIcon(severity);
          report += `### ${icon} ${severity} Issues (${issues.length})\n`;
          for (const issue of issues) {
            report += `- \`${issue.selector}\`: ${issue.description}`;
            if (issue.viewport !== '1920') {
              report += ` (${issue.viewport}px viewport)`;
            }
            report += '\n';
          }
          report += '\n';
        }
      }
    }
    
    // CSS Coverage section
    report += `## CSS Coverage\n\n`;
    report += `### Properties Tested\n`;
    report += `- Background colors and images\n`;
    report += `- Text colors and typography\n`;
    report += `- Borders and outlines\n`;
    report += `- Padding and margins\n`;
    report += `- Transitions and animations\n`;
    report += `- Transform properties\n`;
    report += `- Focus indicators\n`;
    report += `- Hover effects\n`;
    report += `- Active/pressed states\n`;
    report += `- Disabled states\n`;
    report += `\n`;
    
    report += `### Responsive Testing\n`;
    report += `- Mobile (375px)\n`;
    report += `- Tablet (768px)\n`;
    report += `- Desktop (1920px)\n`;
    report += `\n`;
    
    // Testing status
    report += `## Testing Status\n`;
    report += this.buttons.size === 0 ? '🔄 In Progress...\n' : '✅ Testing Active\n';
    report += `\n`;
    
    // Write report
    await fs.writeFile(this.reportPath, report);
  }
  
  async finalizeReport() {
    await this.updateReport();
    
    // Append final summary
    let appendix = '\n---\n\n';
    appendix += `## Test Completed\n`;
    appendix += `✅ All buttons and CSS states have been tested.\n\n`;
    
    // Recommendations
    if (this.issues.length > 0) {
      appendix += `### Recommendations\n`;
      
      if (this.stats.criticalIssues > 0) {
        appendix += `- **Critical**: Address ${this.stats.criticalIssues} critical issues immediately\n`;
      }
      if (this.stats.highIssues > 0) {
        appendix += `- **High Priority**: Fix ${this.stats.highIssues} accessibility/UX issues\n`;
      }
      if (this.stats.mediumIssues > 0) {
        appendix += `- **Medium Priority**: Improve ${this.stats.mediumIssues} styling inconsistencies\n`;
      }
      if (this.stats.lowIssues > 0) {
        appendix += `- **Low Priority**: Consider fixing ${this.stats.lowIssues} minor visual issues\n`;
      }
    } else {
      appendix += `### Result\n`;
      appendix += `🎉 No CSS issues found! All buttons have proper styling and state feedback.\n`;
    }
    
    const currentContent = await fs.readFile(this.reportPath, 'utf8');
    await fs.writeFile(this.reportPath, currentContent + appendix);
    
    logger.info('Report finalized!');
  }
  
  getSeverityIcon(severity) {
    const icons = {
      CRITICAL: '🔴',
      HIGH: '🟠',
      MEDIUM: '🟡',
      LOW: '🔵'
    };
    return icons[severity] || '⚪';
  }
}

// Main execution
async function main() {
  const targetUrl = process.argv[2];
  const outputDir = process.argv[3];
  
  if (!targetUrl || !outputDir) {
    console.error('Usage: node monitor-button-test.js <target_url> <output_dir>');
    process.exit(1);
  }
  
  const monitor = new ButtonTestMonitor(targetUrl, outputDir);
  
  try {
    await monitor.initialize();
    
    // Read from stdin
    process.stdin.setEncoding('utf8');
    
    let buffer = '';
    process.stdin.on('data', async (chunk) => {
      buffer += chunk;
      const lines = buffer.split('\n');
      buffer = lines.pop(); // Keep incomplete line in buffer
      
      for (const line of lines) {
        if (line.trim()) {
          await monitor.processLine(line);
        }
      }
    });
    
    process.stdin.on('end', async () => {
      // Process any remaining buffer
      if (buffer.trim()) {
        await monitor.processLine(buffer);
      }
      logger.info('Monitor shutting down');
    });
    
  } catch (error) {
    logger.error('Fatal error:', error);
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on('SIGINT', () => {
  logger.info('Received SIGINT, shutting down gracefully');
  process.exit(0);
});

process.on('SIGTERM', () => {
  logger.info('Received SIGTERM, shutting down gracefully');
  process.exit(0);
});

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { ButtonTestMonitor };