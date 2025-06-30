#!/bin/bash

# Stream-based Button Testing with Claude Code CLI
# Usage: ./test-buttons-stream.sh <url>

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

# Create monitoring script
cat > "${OUTPUT_DIR}/stream-monitor.js" << 'MONITOR_END'
const readline = require('readline');
const fs = require('fs');

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: false
});

let stats = {
    buttonsFound: 0,
    issues: [],
    currentState: 'starting'
};

let buffer = '';

rl.on('line', (line) => {
    // Try to parse as JSON
    if (line.trim().startsWith('{')) {
        try {
            const data = JSON.parse(line);
            if (data.content) {
                processContent(data.content);
            }
        } catch (e) {
            // Not JSON, process as text
            processContent(line);
        }
    } else {
        processContent(line);
    }
});

function processContent(content) {
    // Look for button mentions
    if (content.match(/button|click|element/i)) {
        const buttonMatches = content.match(/\d+\s*(button|element|link)/gi);
        if (buttonMatches) {
            buttonMatches.forEach(match => {
                const num = parseInt(match);
                if (!isNaN(num) && num > stats.buttonsFound) {
                    stats.buttonsFound = num;
                }
            });
        }
    }
    
    // Look for issues
    if (content.match(/issue|missing|fail|error|problem/i)) {
        if (content.match(/hover|focus|contrast|accessibility/i)) {
            stats.issues.push(content.trim());
        }
    }
    
    // Update state
    if (content.match(/complete|finish|done/i)) {
        stats.currentState = 'complete';
    } else if (content.match(/test|check|analyze/i)) {
        stats.currentState = 'testing';
    }
    
    // Output progress
    console.error(`[Monitor] Buttons: ${stats.buttonsFound}, Issues: ${stats.issues.length}, State: ${stats.currentState}`);
}

process.on('exit', () => {
    // Write final stats
    fs.writeFileSync('stats.json', JSON.stringify(stats, null, 2));
    console.error('[Monitor] Final stats written to stats.json');
});
MONITOR_END

# Create the testing prompt
cat > "${OUTPUT_DIR}/prompt.txt" << 'PROMPT_END'
You have Puppeteer MCP access. Test all buttons and interactive elements on the provided URL.

Target URL: URL_PLACEHOLDER

Please:
1. Navigate to the page
2. Count and list all buttons/clickable elements
3. Test CSS states for each element
4. Report any issues found
5. Be specific about numbers and issues

Provide a detailed analysis.
PROMPT_END

# Replace URL placeholder
sed -i "s|URL_PLACEHOLDER|${URL}|g" "${OUTPUT_DIR}/prompt.txt"

# Run Claude with stream-json output and monitor
echo "Running Claude with stream monitoring..."
cd "${OUTPUT_DIR}"

claude --dangerously-skip-permissions \
    --mcp-config "${PROJECT_ROOT:-/home/a11a2/projects/n8n_tests/frontend-debugger}/claude/mcp/puppeteer-config.json" \
    --output-format stream-json \
    -p "$(cat prompt.txt)" \
    2>error.log | tee output.json | node stream-monitor.js

echo ""
echo "Test complete!"

# Check results
if [ -f "stats.json" ]; then
    echo ""
    echo "Summary:"
    cat stats.json
    echo ""
fi

# Parse stats for pass/fail
if [ -f "stats.json" ]; then
    ISSUES=$(cat stats.json | grep -o '"issues":\s*\[[^]]*\]' | grep -o '\[.*\]' | sed 's/[\[\]]//g' | grep -c '"' || echo "0")
    if [ "${ISSUES}" -gt "0" ]; then
        echo "❌ Test FAILED - Found ${ISSUES} issues"
        exit 1
    else
        echo "✅ Test PASSED"
        exit 0
    fi
else
    echo "⚠️  Could not determine test result"
    exit 2
fi