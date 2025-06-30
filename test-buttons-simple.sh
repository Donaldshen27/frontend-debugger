#!/bin/bash

# Simple Button Testing Script
# Usage: ./test-buttons-simple.sh <url>

if [ $# -lt 1 ]; then
    echo "Usage: $0 <url>"
    echo "Example: $0 https://example.com"
    exit 1
fi

URL="$1"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_DIR="results/button-test-${TIMESTAMP}"

mkdir -p "${OUTPUT_DIR}"

echo "Testing buttons on: ${URL}"
echo "Output directory: ${OUTPUT_DIR}"
echo ""

# Create prompt with strict markers
cat > "${OUTPUT_DIR}/prompt.txt" << 'PROMPT_END'
You have access to Puppeteer MCP. Test the buttons on the provided URL.

IMPORTANT: Output these EXACT markers as you work:
- When page loads: [PAGE_LOADED: url]
- For each button found: [BUTTON_FOUND: selector] text
- When testing states: [CSS_STATE: hover] selector
- For issues: [CSS_ISSUE: HIGH] selector - description
- When done: [ALL_TESTS_COMPLETE]

URL: URL_PLACEHOLDER

1. Navigate to the page
2. Find all buttons and clickable elements
3. Test hover, active, focus states
4. Report CSS issues
5. Output [ALL_TESTS_COMPLETE] when done

Be concise but use the markers!
PROMPT_END

# Replace URL placeholder
sed -i "s|URL_PLACEHOLDER|${URL}|g" "${OUTPUT_DIR}/prompt.txt"

# Run Claude
echo "Running Claude with Puppeteer MCP..."
claude --dangerously-skip-permissions \
    --mcp-config claude/mcp/puppeteer-config.json \
    -p "$(cat "${OUTPUT_DIR}/prompt.txt")" \
    2>&1 | tee "${OUTPUT_DIR}/output.log"

echo ""
echo "Test complete!"
echo "Results saved in: ${OUTPUT_DIR}"
echo ""
echo "View results with:"
echo "  cat ${OUTPUT_DIR}/output.log"