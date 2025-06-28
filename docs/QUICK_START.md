# Quick Start Guide

## 1-Minute Setup

```bash
# Install Claude CLI (if not already installed)
npm install -g @anthropic-ai/claude-code

# Clone the repo
git clone git@github.com:Donaldshen27/frontend-debugger.git
cd frontend-debugger

# Configure Puppeteer MCP
claude mcp add puppeteer -- docker run -i --rm --init -e DOCKER_CONTAINER=true mcp/puppeteer

# Run your first test!
./scripts/testing/quick-test.sh https://example.com
```

## What Just Happened?

1. **Claude CLI** - The AI agent that does the testing
2. **Puppeteer MCP** - Gives Claude browser control abilities
3. **Quick Test** - Fast check showing [OK] and [ERROR] markers

## Next Steps

- Try testing your own website
- Run `./scripts/testing/frontend-debug-realtime.sh` for detailed testing
- Check the results in the created directories

## Common First-Time Issues

### "Claude not found"
```bash
npm install -g @anthropic-ai/claude-code
```

### "Docker not running"
Start Docker Desktop or:
```bash
sudo systemctl start docker
```

### Test times out
- Try a simpler site first
- Check if the URL is accessible
- Make sure Docker is running