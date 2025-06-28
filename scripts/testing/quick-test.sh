#!/bin/bash

# Quick Frontend Test - Fast basic check
echo "⚡ Quick Frontend Test"
echo "====================="
echo ""

URL="${1:-https://example.com}"
echo "Testing: $URL"
echo ""

# Simple prompt for quick testing
claude --dangerously-skip-permissions \
       --mcp-config claude/mcp/puppeteer-config.json \
       -p "Navigate to $URL with Puppeteer. Take a screenshot. Click any visible buttons. Check for console errors. Report what you find in a brief summary. Use these markers: [OK] for things that work, [ERROR] for problems found." \
       2>&1 | grep -E "(\[OK\]|\[ERROR\]|error|Error)" || echo "Test completed"