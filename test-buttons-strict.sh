#!/bin/bash

# Strict Button Testing Script with Required Markers
# Usage: ./test-buttons-strict.sh <url>

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

# Create very explicit prompt
cat > "${OUTPUT_DIR}/prompt.txt" << 'PROMPT_END'
You have Puppeteer MCP access. Follow these steps EXACTLY and output the specified markers.

Target URL: URL_PLACEHOLDER

STEP 1: Navigate to the page
Output: [PAGE_LOADED: URL_PLACEHOLDER]

STEP 2: Find ALL buttons, links, and clickable elements
For EACH element found, output:
[BUTTON_FOUND: <css-selector>] <text content>

STEP 3: For EACH element found above, test these states:
a) Default state - output: [CSS_STATE: default] <selector>
b) Hover state - output: [CSS_STATE: hover] <selector>
c) Active state - output: [CSS_STATE: active] <selector>  
d) Focus state - output: [CSS_STATE: focus] <selector>

STEP 4: Report any CSS issues found:
- No hover effect: [CSS_ISSUE: HIGH] <selector> - Missing hover feedback
- No focus indicator: [CSS_ISSUE: HIGH] <selector> - Missing focus outline
- Poor contrast: [CSS_ISSUE: MEDIUM] <selector> - Low contrast ratio
- Other issues: [CSS_ISSUE: LOW] <selector> - <description>

STEP 5: After testing each element:
[TEST_COMPLETE: <selector>]

STEP 6: When ALL elements are tested:
[ALL_TESTS_COMPLETE]

YOU MUST OUTPUT ALL THESE MARKERS. Start now:
PROMPT_END

# Replace URL placeholder
sed -i "s|URL_PLACEHOLDER|${URL}|g" "${OUTPUT_DIR}/prompt.txt"

# Run Claude with explicit instructions
echo "Running Claude with strict marker requirements..."
claude --dangerously-skip-permissions \
    --mcp-config claude/mcp/puppeteer-config.json \
    -p "$(cat "${OUTPUT_DIR}/prompt.txt")" \
    2>&1 | tee "${OUTPUT_DIR}/output.log"

echo ""
echo "Test complete!"
echo ""

# Parse results
echo "Parsing results..."
echo "Buttons found:"
grep "\[BUTTON_FOUND:" "${OUTPUT_DIR}/output.log" 2>/dev/null || echo "  None found with markers"
echo ""
echo "Issues found:"
grep "\[CSS_ISSUE:" "${OUTPUT_DIR}/output.log" 2>/dev/null || echo "  None found with markers"
echo ""
echo "Full results in: ${OUTPUT_DIR}/output.log"