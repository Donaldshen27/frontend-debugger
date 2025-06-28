# Frontend Debugger - Automated Testing with n8n and Claude Code CLI

An intelligent automated frontend debugging system that combines n8n workflow automation with Claude Code CLI and Puppeteer to systematically test web applications, discover issues, and generate comprehensive reports.

## 🌟 Features

- **🤖 AI-Powered Testing**: Claude Code CLI autonomously navigates and tests frontend applications
- **🔄 Smart Memory Management**: Automatic context clearing between pages to handle large applications
- **📊 Real-Time Progress Tracking**: Monitor testing progress with PostgreSQL database and n8n UI
- **🐛 Intelligent Issue Detection**: Categorized issues by severity (CRITICAL, HIGH, MEDIUM, LOW)
- **📸 Visual Testing**: Screenshots captured for each page and issue found
- **🔧 Self-Recovery**: Automatic restart and resume from checkpoints on failures
- **📧 Multi-Channel Notifications**: Email and push notifications for completion and errors
- **🎯 Systematic Coverage**: Ensures all pages and interactive elements are tested

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [How It Works](#how-it-works)
- [API Reference](#api-reference)
- [Database Schema](#database-schema)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)
- [Contributing](#contributing)
- [License](#license)

## 🏗️ Architecture Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌──────────────────┐
│   n8n Workflow  │────▶│ Claude Monitor  │────▶│ Puppeteer MCP    │
│   Orchestrator  │◀────│   (Node.js)     │     │ Browser Control  │
└─────────────────┘     └─────────────────┘     └──────────────────┘
         │                       │                        │
         ▼                       ▼                        ▼
┌─────────────────┐     ┌─────────────────┐     ┌──────────────────┐
│   PostgreSQL    │     │ Claude Code CLI │     │  Target Website  │
│    Database     │     │   (AI Agent)    │     │  Under Test      │
└─────────────────┘     └─────────────────┘     └──────────────────┘
```

### Component Responsibilities

- **n8n Workflow**: Orchestrates the entire process, handles webhooks, manages lifecycle
- **Claude Monitor**: Node.js script that launches and monitors Claude CLI, parses output
- **Claude Code CLI**: AI agent that performs the actual testing using natural language understanding
- **Puppeteer MCP**: Provides browser automation capabilities to Claude
- **PostgreSQL**: Stores progress, issues found, and session information

## 📦 Prerequisites

- **Docker** and **Docker Compose** (v2.0+)
- **Node.js** (v18+) and npm
- **Claude Code CLI** installed globally:
  ```bash
  npm install -g @anthropic-ai/claude-code
  ```
- **Puppeteer MCP** configured (use the provided `setup-mcp-servers.sh` script)
- **Git** for version control
- **Linux/macOS/WSL** (Windows users should use WSL2)
- At least **8GB RAM** recommended
- **Ports available**: 5678 (n8n), 6666 (PostgreSQL), 8080 (Adminer)

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone <repository-url>
cd frontend-debugger

# 2. Start all services
./start-server.sh

# 3. Open n8n UI and import workflow
# Navigate to: http://localhost:5678 (admin/admin)
# Import: n8n/workflows/frontend-debugger.json

# 4. Test the system
./test-frontend-debug.sh https://example.com
```

## 📥 Installation

### 1. Clone and Setup

```bash
# Clone repository
git clone <repository-url>
cd frontend-debugger

# Copy environment configuration
cp .env.example .env

# Edit .env with your settings
nano .env
```

### 2. Configure Environment Variables

Edit `.env` file:
```env
# Database Configuration
DB_HOST=localhost
DB_PORT=6666  # Changed from 5432 to avoid conflicts
DB_NAME=frontend_debugger
DB_USER=postgres
DB_PASSWORD=postgres

# n8n Configuration
N8N_WEBHOOK_URL=http://localhost:5678/webhook/frontend-debug-callback
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=admin

# Notification Settings
NOTIFICATION_EMAIL=your-email@example.com

# Optional: Push notifications
PUSHOVER_USER_KEY=your_key_here
PUSHOVER_API_TOKEN=your_token_here
```

### 3. Install Dependencies

```bash
# Install Node.js dependencies
npm install

# Install Claude Code CLI globally (if not already installed)
npm install -g @anthropic-ai/claude-code

# Configure MCP servers (including Puppeteer)
../setup-mcp-servers.sh  # If available
# Or manually:
claude mcp add puppeteer -- docker run -i --rm --init -e DOCKER_CONTAINER=true mcp/puppeteer
```

### 4. Start Services

```bash
# Start all services (handles port conflicts automatically)
./start-server.sh

# Services will be available at:
# - n8n: http://localhost:5678
# - Adminer: http://localhost:8080
# - PostgreSQL: localhost:6666
```

### 5. Import n8n Workflow

1. Open http://localhost:5678
2. Login with `admin` / `admin`
3. Click "Workflows" → "Import from File"
4. Select `n8n/workflows/frontend-debugger.json`
5. Click "Import"
6. Open the imported workflow and click "Active" toggle

### 6. Configure Credentials (Optional)

In n8n UI, configure:
- **PostgreSQL**: Should auto-connect to the Docker PostgreSQL
- **SMTP**: For email notifications (optional)
- **Pushover**: For push notifications (optional)

## ⚙️ Configuration

### Claude Configuration (`claude/CLAUDE.md`)

This file contains instructions for Claude's testing behavior. Key sections:

- **Testing Priorities**: What to test and in what order
- **Issue Severity Levels**: How to categorize found issues
- **Progress Markers**: Special strings Claude outputs for monitoring
- **Memory Management**: When to request context clearing

### Prompt Template (`claude/prompts/frontend-debug-prompt.md`)

The initial prompt sent to Claude. Includes:
- Testing instructions
- Progress tracking markers
- Issue reporting format
- Memory management triggers

### MCP Configuration (`claude/mcp/puppeteer-config.json`)

Puppeteer settings including:
- Viewport dimensions
- Headless mode settings
- Docker configuration

## 📖 Usage

### Starting a Debug Session

#### Via cURL:
```bash
curl -X POST http://localhost:5678/webhook/frontend-debug-start \
  -H "Content-Type: application/json" \
  -d '{
    "targetUrl": "https://example.com",
    "notificationEmail": "your-email@example.com"
  }'
```

#### Via Test Script:
```bash
./test-frontend-debug.sh https://example.com your-email@example.com
```

### Monitoring Progress

1. **n8n UI** (http://localhost:5678):
   - Watch workflow execution in real-time
   - See data passed between nodes
   - View execution history

2. **Database** (http://localhost:8080):
   - Server: `postgres`
   - Username: `postgres`
   - Password: `postgres`
   - Database: `frontend_debugger`
   - View tables: `sessions`, `pages`, `issues`

3. **Logs**:
   ```bash
   # View all logs
   docker compose -f docker/docker-compose.yml logs -f

   # View specific service
   docker compose -f docker/docker-compose.yml logs -f n8n
   ```

### Server Management

```bash
# Start all services
./start-server.sh

# Stop all services
./stop-server.sh

# Restart services
./stop-server.sh
```

## 🔄 How It Works

### 1. Initialization Phase
- User triggers webhook with target URL
- n8n creates git checkpoint for recovery
- Launches Claude Monitor Node.js script

### 2. Testing Phase
- Claude Monitor starts Claude Code CLI with Puppeteer access
- Claude navigates to target URL
- For each page:
  - Takes screenshot
  - Tests all interactive elements
  - Checks responsive design
  - Documents issues found
  - Outputs progress markers

### 3. Memory Management
- Claude outputs `[CLEAR_MEMORY_REQUEST]` when done with a page
- Monitor kills Claude process
- Restarts with summary of completed pages
- Continues from next unvisited page

### 4. Completion Phase
- Claude outputs `[ALL_PAGES_COMPLETE]`
- System generates summary report
- Sends notifications
- Stores all data in PostgreSQL

### Progress Markers

Claude outputs these exact markers for the monitoring system:

- `[PAGE_COMPLETE: <url>]` - Finished testing a page
- `[ISSUE: <severity>] <url> - <description>` - Found an issue
- `[CLEAR_MEMORY_REQUEST]` - Ready for memory clear
- `[ALL_PAGES_COMPLETE]` - All testing complete
- `[ERROR: <description>]` - Encountered blocking error

## 📡 API Reference

### Start Debugging Session

**Endpoint**: `POST /webhook/frontend-debug-start`

**Request Body**:
```json
{
  "targetUrl": "https://example.com",
  "notificationEmail": "user@example.com"
}
```

**Response**:
```json
{
  "message": "Frontend Debugger Started",
  "sessionId": 123,
  "targetUrl": "https://example.com"
}
```

### Internal Callback Events

The system uses internal webhooks for Claude Monitor → n8n communication:

- `page_complete`: Page testing completed
- `issue_found`: New issue discovered
- `all_complete`: All pages tested
- `error`: Error occurred
- `claude_crashed`: Claude CLI crashed

## 💾 Database Schema

### Tables

#### `sessions`
- `id`: Primary key
- `started_at`: Timestamp
- `completed_at`: Timestamp (nullable)
- `target_url`: Website being tested
- `git_commit_hash`: Recovery checkpoint
- `status`: running|complete|failed|paused

#### `pages`
- `id`: Primary key
- `session_id`: Foreign key to sessions
- `url`: Page URL
- `status`: pending|testing|complete|failed
- `completed_at`: Timestamp
- `token_count`: Tokens used for this page

#### `issues`
- `id`: Primary key
- `session_id`: Foreign key to sessions
- `page_url`: Where issue was found
- `severity`: CRITICAL|HIGH|MEDIUM|LOW
- `description`: Issue description
- `screenshot_path`: Path to screenshot

### Views

#### `session_summary`
Aggregated view showing:
- Total pages tested
- Issues by severity
- Total tokens used
- Session duration

## 🔧 Troubleshooting

### Common Issues

#### Port Conflicts
```bash
# Use the start script which handles conflicts
./start-server.sh

# Or manually check what's using a port
lsof -i :5678
```

#### Claude CLI Not Found
```bash
# Install globally
npm install -g @anthropic-ai/claude-code

# Verify installation
claude --version
```

#### Puppeteer MCP Issues
```bash
# List configured MCP servers
claude mcp list

# Re-add Puppeteer server
claude mcp add puppeteer -- docker run -i --rm --init -e DOCKER_CONTAINER=true mcp/puppeteer
```

#### Database Connection Failed
```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Check logs
docker logs docker-postgres-1

# Verify connection
psql -h localhost -p 6666 -U postgres -d frontend_debugger
```

#### Memory/Context Issues
- Adjust testing granularity in `CLAUDE.md`
- Increase frequency of `[CLEAR_MEMORY_REQUEST]`
- Test smaller sections of large sites

### Debug Mode

Enable detailed logging:
```bash
# Set in .env
LOG_LEVEL=debug

# Or when running directly
LOG_LEVEL=debug node n8n/scripts/monitor-claude.js https://example.com
```

## 🚀 Advanced Usage

### Custom Testing Profiles

Create custom CLAUDE.md files for different testing scenarios:

```bash
# E-commerce testing
cp claude/CLAUDE.md claude/CLAUDE-ecommerce.md
# Edit to add specific e-commerce tests

# Use custom profile
CLAUDE_PROFILE=ecommerce ./test-frontend-debug.sh
```

### Parallel Testing

Run multiple sessions for different sites:
```bash
# Terminal 1
./test-frontend-debug.sh https://site1.com

# Terminal 2
./test-frontend-debug.sh https://site2.com
```

### Integration with CI/CD

```yaml
# Example GitHub Actions
- name: Run Frontend Tests
  run: |
    ./start-server.sh
    ./test-frontend-debug.sh ${{ env.STAGING_URL }}
    ./stop-server.sh
```

### Custom Issue Handlers

Extend `monitor-claude.js` to integrate with:
- Jira/GitHub Issues
- Slack notifications
- Custom databases
- Screenshot storage (S3, etc.)

## 🧪 Development

### Project Structure
```
frontend-debugger/
├── n8n/
│   ├── workflows/          # n8n workflow definitions
│   └── scripts/            # Node.js monitoring script
├── claude/
│   ├── CLAUDE.md           # Claude instructions
│   ├── prompts/            # Prompt templates
│   └── mcp/                # MCP configurations
├── database/
│   └── schema.sql          # PostgreSQL schema
├── docker/
│   ├── docker-compose.yml  # Service definitions
│   └── init-n8n.sh         # n8n initialization
├── .env.example            # Environment template
├── start-server.sh         # Start script
├── stop-server.sh          # Stop script
├── test-frontend-debug.sh  # Test script
├── package.json            # Node dependencies
└── README.md               # This file
```

### Adding Features

1. **New Progress Markers**:
   - Add to `claude/CLAUDE.md`
   - Update parser in `monitor-claude.js`
   - Add handler function

2. **New Issue Severities**:
   - Update `database/schema.sql`
   - Modify `CLAUDE.md` instructions
   - Update monitoring script

3. **Additional Notifications**:
   - Add to n8n workflow
   - Configure new credentials
   - Update notification node

### Testing

```bash
# Unit tests (when implemented)
npm test

# Integration test
./test-frontend-debug.sh https://httpbin.org/html

# Load test
for i in {1..10}; do
  ./test-frontend-debug.sh https://example.com &
done
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Contribution Guidelines

- Follow existing code style
- Add tests for new features
- Update documentation
- Keep commits atomic and descriptive
- Ensure all tests pass

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

## 🙏 Acknowledgments

- [Anthropic](https://anthropic.com) for Claude Code CLI
- [n8n](https://n8n.io) for workflow automation
- [MCP](https://modelcontextprotocol.io) community for Puppeteer server
- All contributors and testers

## 📚 Resources

- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
- [n8n Documentation](https://docs.n8n.io)
- [MCP Documentation](https://modelcontextprotocol.io/docs)
- [Puppeteer Documentation](https://pptr.dev)

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/yourrepo/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourrepo/discussions)
- **Email**: support@example.com

---

Built with ❤️ by the Frontend Debugger Team