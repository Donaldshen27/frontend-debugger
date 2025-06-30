#!/bin/bash

# Button Testing with Structured Output
# Usage: ./test-buttons-structured.sh <url>

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

# Create prompt that asks for structured output
cat > "${OUTPUT_DIR}/prompt.txt" << 'PROMPT_END'
You have Puppeteer MCP access. Test all buttons and interactive elements on the provided URL.

Target URL: URL_PLACEHOLDER

Tasks:
1. Navigate to the page
2. Find all buttons, links, and clickable elements
3. Test CSS states: default, hover, active, focus
4. Check for accessibility issues

After testing, provide your findings in this EXACT format:

=== TEST RESULTS START ===
URL: [tested url]
Total Elements: [number]
Total Issues: [number]

ELEMENTS:
[selector] | [text] | [type] | [issues if any]

ISSUES BY SEVERITY:
CRITICAL: [number]
- [description if any]
HIGH: [number]
- [description if any]
MEDIUM: [number]
- [description if any]
LOW: [number]
- [description if any]

SUMMARY:
[Brief summary of findings]
=== TEST RESULTS END ===
PROMPT_END

# Replace URL placeholder
sed -i "s|URL_PLACEHOLDER|${URL}|g" "${OUTPUT_DIR}/prompt.txt"

# Run Claude normally and capture output
echo "Running Claude..."
claude --dangerously-skip-permissions \
    --mcp-config claude/mcp/puppeteer-config.json \
    -p "$(cat "${OUTPUT_DIR}/prompt.txt")" \
    2>&1 | tee "${OUTPUT_DIR}/output.log"

echo ""
echo "Test complete! Parsing results..."

# Extract structured data
if grep -q "=== TEST RESULTS START ===" "${OUTPUT_DIR}/output.log"; then
    # Extract the structured section
    sed -n '/=== TEST RESULTS START ===/,/=== TEST RESULTS END ===/p' "${OUTPUT_DIR}/output.log" > "${OUTPUT_DIR}/results.txt"
    
    # Parse key metrics
    echo ""
    echo "Summary:"
    echo "========"
    grep "Total Elements:" "${OUTPUT_DIR}/results.txt" || echo "Total Elements: Not found"
    grep "Total Issues:" "${OUTPUT_DIR}/results.txt" || echo "Total Issues: Not found"
    echo ""
    
    # Show issues by severity
    echo "Issues by Severity:"
    echo "=================="
    sed -n '/ISSUES BY SEVERITY:/,/SUMMARY:/p' "${OUTPUT_DIR}/results.txt" | head -n -1
    echo ""
    
    echo "Full results saved in: ${OUTPUT_DIR}/results.txt"
else
    echo "Warning: Could not find structured results in output"
    echo "Check the full log: ${OUTPUT_DIR}/output.log"
fi