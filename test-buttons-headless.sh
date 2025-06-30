#!/bin/bash

# Headless Button Testing with Claude Code CLI
# Usage: ./test-buttons-headless.sh <url>

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

# Create a prompt that asks for specific output
cat > "${OUTPUT_DIR}/prompt.txt" << 'PROMPT_END'
You have Puppeteer MCP access. Test all buttons on the provided URL and return "OK" if successful or "FAIL" if there were issues.

Target URL: URL_PLACEHOLDER

Tasks:
1. Navigate to the page using Puppeteer
2. Find all buttons and clickable elements
3. Test each button's CSS states (hover, active, focus)
4. Check for accessibility issues

After testing, output ONLY one of these:
- If all buttons have proper CSS states and no critical issues: output "OK"
- If there are missing hover states, focus indicators, or other CSS issues: output "FAIL: <brief description>"

Be concise. Output only the result.
PROMPT_END

# Replace URL placeholder
sed -i "s|URL_PLACEHOLDER|${URL}|g" "${OUTPUT_DIR}/prompt.txt"

# Run Claude in headless mode
echo "Running Claude in headless mode..."
RESULT=$(claude --dangerously-skip-permissions \
    --mcp-config claude/mcp/puppeteer-config.json \
    -p "$(cat "${OUTPUT_DIR}/prompt.txt")" 2>&1)

echo "Result: ${RESULT}"

# Save result
echo "${RESULT}" > "${OUTPUT_DIR}/result.txt"

# Check if test passed
if echo "${RESULT}" | grep -q "^OK"; then
    echo "✅ Test PASSED"
    exit 0
else
    echo "❌ Test FAILED"
    echo "${RESULT}" | grep "FAIL:" || echo "See full output in: ${OUTPUT_DIR}/result.txt"
    exit 1
fi