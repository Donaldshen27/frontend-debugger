# Frontend Debugger - AI-Powered Web Testing with Claude

An intelligent automated frontend testing system that uses Claude Code CLI with Puppeteer to systematically test web applications and report issues.

## 🚀 Quick Start

```bash
# 1. Clone and setup
git clone git@github.com:Donaldshen27/frontend-debugger.git
cd frontend-debugger

# 2. Configure Puppeteer MCP (one-time setup)
claude mcp add puppeteer -- docker run -i --rm --init -e DOCKER_CONTAINER=true mcp/puppeteer

# 3. Run a quick test
./scripts/testing/quick-test.sh https://example.com
```

## 🌟 Features

- **🤖 AI-Powered Testing**: Claude autonomously navigates and tests websites
- **📸 Visual Testing**: Screenshots and visual regression detection
- **🐛 Smart Issue Detection**: Categorized by severity (CRITICAL, HIGH, MEDIUM, LOW)
- **⚡ Real-time Feedback**: Colorized output with progress tracking
- **🔄 No Setup Required**: Works without database or complex configuration
- **🎯 Comprehensive Coverage**: Tests buttons, forms, links, responsive design

## 📦 Prerequisites

- **Claude Code CLI**: Install with `npm install -g @anthropic-ai/claude-code`
- **Docker**: For running Puppeteer MCP server
- **Node.js 18+**: For utility scripts
- **Git**: For version control

## 🛠️ Available Testing Scripts

### 1. Quick Test (`scripts/testing/quick-test.sh`)
Fast basic check - perfect for rapid testing:
```bash
./scripts/testing/quick-test.sh https://your-website.com
```
- ⚡ Takes ~30 seconds
- ✅ Shows [OK] for working features
- ❌ Shows [ERROR] for issues found

### 2. Real-time Debugger (`scripts/testing/frontend-debug-realtime.sh`)
Comprehensive testing with live feedback:
```bash
./scripts/testing/frontend-debug-realtime.sh https://your-website.com
```
- 🎨 Colorized output by severity
- 📊 Progress tracking with markers
- 📁 Saves detailed logs
- 📈 Summary statistics

### 3. Simple Debugger (`scripts/testing/frontend-debug-simple.sh`)
Full testing with complete documentation:
```bash
./scripts/testing/frontend-debug-simple.sh https://your-website.com
```
- 📝 Comprehensive testing
- 💾 Saves all results to timestamped directory
- 🔍 Best for detailed analysis

## 📋 Test Coverage

Each test checks:
- ✅ Page load and performance
- ✅ Console errors
- ✅ Network errors (4xx/5xx)
- ✅ Interactive elements (buttons, links, forms)
- ✅ Responsive design (mobile, tablet, desktop)
- ✅ JavaScript functionality
- ✅ Navigation flow

## 🎯 Issue Severity Levels

- **🔴 CRITICAL**: Complete failures, crashes, security issues
- **🟠 HIGH**: Major UX problems, broken features, data loss risks
- **🟡 MEDIUM**: Minor bugs, performance issues, inconsistencies
- **🔵 LOW**: Cosmetic issues, minor text problems

## 📂 Project Structure

```
frontend-debugger/
├── scripts/
│   ├── testing/           # Main testing scripts
│   │   ├── quick-test.sh
│   │   ├── frontend-debug-realtime.sh
│   │   └── frontend-debug-simple.sh
│   ├── server/            # Server management
│   │   ├── start-server.sh
│   │   └── stop-server.sh
│   └── utilities/         # Helper scripts
├── claude/                # Claude configuration
│   ├── CLAUDE.md          # Testing instructions
│   └── mcp/               # MCP server configs
├── n8n/                   # n8n workflows (optional)
├── database/              # Database schema (optional)
└── docker/                # Docker configuration
```

## 🔧 Advanced Usage

### Custom Testing Profile
Create a custom CLAUDE.md for specific testing needs:
```bash
cp claude/CLAUDE.md claude/CLAUDE-ecommerce.md
# Edit for e-commerce specific tests
CLAUDE_CONFIG=claude/CLAUDE-ecommerce.md ./scripts/testing/quick-test.sh
```

### Batch Testing
Test multiple sites:
```bash
for site in site1.com site2.com site3.com; do
  ./scripts/testing/quick-test.sh "https://$site" > "results-$site.log"
done
```

### CI/CD Integration
```yaml
# GitHub Actions example
- name: Test Website
  run: |
    npm install -g @anthropic-ai/claude-code
    ./scripts/testing/quick-test.sh ${{ env.WEBSITE_URL }}
```

## 🐛 Troubleshooting

### Claude CLI Not Found
```bash
npm install -g @anthropic-ai/claude-code
```

### Puppeteer MCP Not Working
```bash
# Re-add Puppeteer server
claude mcp add puppeteer -- docker run -i --rm --init -e DOCKER_CONTAINER=true mcp/puppeteer

# Check if it's listed
claude mcp list
```

### Tests Timing Out
- Check if the website is accessible
- Try with a simpler site first (e.g., https://example.com)
- Ensure Docker is running for Puppeteer

## 📊 Example Output

```
⚡ Quick Frontend Test
=====================
Testing: https://example.com

[OK] Successfully navigated to https://example.com
[OK] Page loaded without any console errors
[ERROR] Submit button is disabled on mobile viewport
[OK] All links are functional
[ERROR] Form validation not working for email field
```

## 🚀 Optional: Full System with n8n and Database

For persistent tracking and advanced features:
```bash
# Start all services
./scripts/server/start-server.sh

# Access n8n at http://localhost:5678
# Import workflow from n8n/workflows/
```

This enables:
- Progress tracking across sessions
- Historical test comparisons
- Team collaboration features
- Automated scheduling

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Test your changes
4. Commit (`git commit -m 'Add amazing feature'`)
5. Push (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## 📄 License

MIT License - see LICENSE file

## 🙏 Acknowledgments

- [Anthropic](https://anthropic.com) for Claude Code CLI
- [Puppeteer](https://pptr.dev) for browser automation
- [MCP](https://modelcontextprotocol.io) for the protocol
- [n8n](https://n8n.io) for workflow automation

---

**Built with ❤️ by Donald Shen**

*Need help? Open an issue on [GitHub](https://github.com/Donaldshen27/frontend-debugger/issues)*