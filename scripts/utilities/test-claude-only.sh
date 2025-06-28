#!/bin/bash

# Test Claude CLI directly without database
echo "Testing Claude Code CLI directly..."
echo "=================================="

# Test URL
URL="${1:-https://example.com}"

echo "Target URL: $URL"
echo ""

# Create a simple prompt
PROMPT="You are testing a website. Navigate to $URL using Puppeteer MCP and tell me what you see. Take a screenshot and describe the main elements on the page."

# Run Claude with the prompt
claude --dangerously-skip-permissions \
       --mcp-config claude/mcp/puppeteer-config.json \
       -p "$PROMPT"