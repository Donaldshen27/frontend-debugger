# Frontend Debugger - Automated Testing with n8n and Claude Code CLI

An automated frontend debugging system that combines n8n workflow automation with Claude Code CLI and Puppeteer to systematically test web applications and report issues.

## Features

- 🤖 **Automated Testing**: Claude Code CLI autonomously navigates and tests frontend applications
- 🔄 **Memory Management**: Automatic context clearing between pages to handle large applications
- 📊 **Progress Tracking**: Real-time monitoring of testing progress with PostgreSQL database
- 🐛 **Issue Reporting**: Categorized issues by severity (CRITICAL, HIGH, MEDIUM, LOW)
- 📸 **Visual Testing**: Screenshots captured for each page and issue
- 🔧 **Recovery Mechanism**: Automatic restart and resume from checkpoints
- 📧 **Notifications**: Email and push notifications for completion and errors

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌──────────────┐
│   n8n       │────▶│   Claude    │────▶│  Puppeteer   │
│  Workflow   │◀────│   Monitor   │     │     MCP      │
└─────────────┘     └─────────────┘     └──────────────┘
       │                    │                     │
       ▼                    ▼                     ▼
┌─────────────┐     ┌─────────────┐     ┌──────────────┐
│ PostgreSQL  │     │   Claude    │     │   Target     │
│  Database   │     │   Code CLI  │     │   Website    │
└─────────────┘     └─────────────┘     └──────────────┘
```

## Prerequisites

- Docker and Docker Compose
- Node.js 18+ and npm
- Claude Code CLI installed (`npm install -g @anthropic-ai/claude-code`)
- Puppeteer MCP server configured (see setup-mcp-servers.sh)
- Git

## Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd frontend-debugger
   ```

2. **Copy environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Install dependencies**
   ```bash
   npm install
   ```

4. **Start the Docker services**
   ```bash
   cd docker
   docker-compose up -d
   ```

5. **Initialize the database**
   ```bash
   # Database schema is automatically applied on first startup
   ```

6. **Import n8n workflow**
   - Access n8n at http://localhost:5678 (default: admin/admin)
   - Import `n8n/workflows/frontend-debugger.json`
   - Configure credentials for PostgreSQL, SMTP, and Pushover (optional)

7. **Start a debugging session**
   ```bash
   curl -X POST http://localhost:5678/webhook/frontend-debug-start \
     -H "Content-Type: application/json" \
     -d '{
       "targetUrl": "https://example.com",
       "notificationEmail": "your-email@example.com"
     }'
   ```

## Configuration

### Claude Configuration (CLAUDE.md)
The `claude/CLAUDE.md` file contains instructions for Claude's testing behavior. Modify this file to customize:
- Testing priorities
- Issue severity definitions
- Specific testing workflows
- Memory management rules

### Prompt Template
Edit `claude/prompts/frontend-debug-prompt.md` to customize the initial prompt sent to Claude.

### MCP Configuration
The Puppeteer MCP configuration is in `claude/mcp/puppeteer-config.json`. Adjust viewport sizes and other Puppeteer settings here.

## Project Structure

```
frontend-debugger/
├── n8n/
│   ├── workflows/        # n8n workflow definitions
│   └── scripts/          # Node.js monitoring script
├── claude/
│   ├── CLAUDE.md         # Claude instructions
│   ├── prompts/          # Prompt templates
│   └── mcp/              # MCP server configs
├── database/
│   └── schema.sql        # PostgreSQL schema
├── docker/
│   └── docker-compose.yml # Docker services
└── README.md
```

## Database Schema

### Tables
- **sessions**: Overall debugging sessions
- **pages**: Individual page testing progress
- **issues**: Discovered issues with severity levels

### Views
- **session_summary**: Aggregated session statistics

## Monitoring

### Database
Access Adminer at http://localhost:8080 to view:
- Session progress
- Issues found
- Token usage

### Logs
Monitor Claude CLI output:
```bash
docker-compose logs -f n8n
```

## API Endpoints

### Start Debugging Session
```http
POST /webhook/frontend-debug-start
{
  "targetUrl": "https://example.com",
  "notificationEmail": "user@example.com"
}
```

### Callback Events (Internal)
The system uses internal webhooks for communication between Claude Monitor and n8n:
- `page_complete`: Page testing completed
- `issue_found`: New issue discovered
- `all_complete`: All pages tested
- `error`: Error occurred
- `claude_crashed`: Claude CLI crashed

## Troubleshooting

### Claude CLI Not Found
Ensure Claude Code CLI is installed globally:
```bash
npm install -g @anthropic-ai/claude-code
```

### Puppeteer MCP Connection Issues
1. Check Docker is running
2. Verify Puppeteer MCP is configured:
   ```bash
   claude mcp list
   ```

### Database Connection Errors
1. Ensure PostgreSQL is running:
   ```bash
   docker-compose ps
   ```
2. Check database credentials in `.env`

### Memory Issues
If Claude runs out of context:
- The system automatically detects `[CLEAR_MEMORY_REQUEST]` markers
- Claude is restarted with a summary of completed pages
- Adjust page testing granularity in CLAUDE.md if needed

## Development

### Running Tests
```bash
npm test
```

### Adding New Features
1. Update the monitoring script (`n8n/scripts/monitor-claude.js`)
2. Modify the n8n workflow as needed
3. Update database schema if required
4. Test thoroughly with different websites

## Security Considerations

- Use `--dangerously-skip-permissions` only in controlled environments
- Run in Docker containers for isolation
- Avoid testing sites with sensitive data
- Use environment variables for credentials
- Regularly update dependencies

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Acknowledgments

- Anthropic for Claude Code CLI
- n8n for workflow automation
- MCP community for Puppeteer server