#!/bin/bash

# Simple Frontend Debugger - Direct Claude execution
echo "Simple Frontend Debugger"
echo "======================="
echo ""

# Get target URL
TARGET_URL="${1:-https://example.com}"
OUTPUT_DIR="debug-results-$(date +%Y%m%d-%H%M%S)"

echo "Target URL: $TARGET_URL"
echo "Output Directory: $OUTPUT_DIR"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Create the debug prompt
cat > "$OUTPUT_DIR/prompt.md" << EOF
You are an automated frontend debugging assistant with access to Puppeteer for browser automation.

Your task is to systematically test the frontend application starting at: $TARGET_URL

## Instructions:

1. Navigate to the starting URL using Puppeteer MCP
2. Take a screenshot of the page
3. Test all interactive elements (buttons, links, forms)
4. Check for console errors
5. Test responsive design at different viewports (mobile: 375px, tablet: 768px, desktop: 1920px)
6. Document any issues found with severity levels:
   - CRITICAL: Broken functionality, crashes
   - HIGH: Major UX issues
   - MEDIUM: Minor bugs
   - LOW: Cosmetic issues

7. After testing the main page, list all internal links found
8. Output a summary of your findings

Please be thorough but concise in your testing and reporting.
EOF

echo "Starting Claude Code CLI..."
echo "============================"

# Run Claude with the debug prompt
claude --dangerously-skip-permissions \
       --mcp-config claude/mcp/puppeteer-config.json \
       -p "$(cat $OUTPUT_DIR/prompt.md)" \
       2>&1 | tee "$OUTPUT_DIR/debug-log.txt"

echo ""
echo "Debug session complete!"
echo "Results saved in: $OUTPUT_DIR/"
echo ""
echo "Files created:"
ls -la "$OUTPUT_DIR/"