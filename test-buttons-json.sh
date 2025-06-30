#!/bin/bash

# Button Testing with JSON Output
# Usage: ./test-buttons-json.sh <url>

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

# Create prompt that requests JSON output
cat > "${OUTPUT_DIR}/prompt.txt" << 'PROMPT_END'
You have Puppeteer MCP access. Test all buttons and interactive elements on the provided URL.

Target URL: URL_PLACEHOLDER

Tasks:
1. Navigate to the page
2. Find all buttons, links, and clickable elements
3. Test CSS states: default, hover, active, focus
4. Check for accessibility issues
5. Test at viewports: 375px, 768px, 1920px

Return a JSON object with this structure:
{
  "url": "the tested URL",
  "timestamp": "ISO timestamp",
  "summary": {
    "totalElements": number,
    "totalIssues": number,
    "criticalIssues": number,
    "highIssues": number,
    "mediumIssues": number,
    "lowIssues": number
  },
  "elements": [
    {
      "selector": "css selector",
      "text": "button text",
      "type": "button|link|input",
      "states": {
        "default": { "background": "color", "color": "color", "border": "style" },
        "hover": { "background": "color", "color": "color", "border": "style" },
        "active": { "background": "color", "color": "color", "border": "style" },
        "focus": { "outline": "style", "background": "color" }
      },
      "issues": [
        { "severity": "HIGH", "description": "Missing focus indicator" }
      ]
    }
  ],
  "viewportTests": {
    "375": { "passed": true, "issues": [] },
    "768": { "passed": true, "issues": [] },
    "1920": { "passed": true, "issues": [] }
  }
}
PROMPT_END

# Replace URL placeholder
sed -i "s|URL_PLACEHOLDER|${URL}|g" "${OUTPUT_DIR}/prompt.txt"

# Run Claude with JSON output
echo "Running Claude with JSON output..."
claude --dangerously-skip-permissions \
    --mcp-config claude/mcp/puppeteer-config.json \
    --output-format json \
    -p "$(cat "${OUTPUT_DIR}/prompt.txt")" \
    > "${OUTPUT_DIR}/result.json" 2>"${OUTPUT_DIR}/error.log"

# Check if we got valid JSON
if [ -s "${OUTPUT_DIR}/result.json" ]; then
    echo "Test complete! Processing results..."
    
    # Pretty print and save
    cat "${OUTPUT_DIR}/result.json" | python3 -m json.tool > "${OUTPUT_DIR}/result-pretty.json" 2>/dev/null || cp "${OUTPUT_DIR}/result.json" "${OUTPUT_DIR}/result-pretty.json"
    
    # Extract summary using Python
    python3 -c "
import json
import sys

try:
    with open('${OUTPUT_DIR}/result.json', 'r') as f:
        data = json.load(f)
    
    print('\nTest Summary:')
    print('=============')
    if 'summary' in data:
        s = data['summary']
        print(f'Total Elements: {s.get(\"totalElements\", 0)}')
        print(f'Total Issues: {s.get(\"totalIssues\", 0)}')
        if s.get('totalIssues', 0) > 0:
            print(f'  - Critical: {s.get(\"criticalIssues\", 0)}')
            print(f'  - High: {s.get(\"highIssues\", 0)}')
            print(f'  - Medium: {s.get(\"mediumIssues\", 0)}')
            print(f'  - Low: {s.get(\"lowIssues\", 0)}')
    
    print('\nElements Found:')
    print('===============')
    if 'elements' in data:
        for elem in data['elements'][:5]:  # Show first 5
            print(f\"- {elem.get('selector', 'unknown')}: {elem.get('text', 'no text')}\")
            if elem.get('issues'):
                for issue in elem['issues']:
                    print(f\"  ⚠️  {issue.get('severity', '')}: {issue.get('description', '')}\")
        if len(data.get('elements', [])) > 5:
            print(f'  ... and {len(data[\"elements\"]) - 5} more')
    
except Exception as e:
    print(f'Error parsing JSON: {e}')
    print('Raw output saved in ${OUTPUT_DIR}/result.json')
" 2>/dev/null || echo "Could not parse JSON summary"
    
    echo ""
    echo "Full results saved in:"
    echo "  JSON: ${OUTPUT_DIR}/result.json"
    echo "  Pretty: ${OUTPUT_DIR}/result-pretty.json"
    
    # Generate markdown report from JSON
    echo ""
    echo "Generating markdown report..."
    python3 -c "
import json
import sys
from datetime import datetime

try:
    with open('${OUTPUT_DIR}/result.json', 'r') as f:
        data = json.load(f)
    
    report = []
    report.append(f\"# Button & CSS Test Report\")
    report.append(f\"URL: {data.get('url', '${URL}')}\\n\")
    report.append(f\"Generated: {data.get('timestamp', datetime.now().isoformat())}\\n\")
    
    if 'summary' in data:
        report.append(f\"## Summary\")
        s = data['summary']
        report.append(f\"- Total Elements: {s.get('totalElements', 0)}\")
        report.append(f\"- Total Issues: {s.get('totalIssues', 0)}\")
        report.append(f\"- Critical Issues: {s.get('criticalIssues', 0)}\")
        report.append(f\"- High Priority Issues: {s.get('highIssues', 0)}\")
        report.append(f\"- Medium Priority Issues: {s.get('mediumIssues', 0)}\")
        report.append(f\"- Low Priority Issues: {s.get('lowIssues', 0)}\\n\")
    
    if 'elements' in data and data['elements']:
        report.append(f\"## Elements Tested\\n\")
        for elem in data['elements']:
            report.append(f\"### {elem.get('text', 'Unnamed Element')}\")
            report.append(f\"- **Selector**: \`{elem.get('selector', 'unknown')}\`\")
            report.append(f\"- **Type**: {elem.get('type', 'unknown')}\")
            
            if 'states' in elem:
                report.append(f\"- **States Tested**: ✓ Default ✓ Hover ✓ Active ✓ Focus\")
            
            if elem.get('issues'):
                report.append(f\"- **Issues**:\")
                for issue in elem['issues']:
                    report.append(f\"  - {issue.get('severity', '')}: {issue.get('description', '')}\")
            else:
                report.append(f\"- **Issues**: None ✓\")
            report.append(\"\")
    
    with open('${OUTPUT_DIR}/report.md', 'w') as f:
        f.write('\\n'.join(report))
    
    print('Markdown report generated: ${OUTPUT_DIR}/report.md')
    
except Exception as e:
    print(f'Error generating report: {e}')
" 2>/dev/null || echo "Could not generate markdown report"
    
else
    echo "Error: No JSON output received"
    echo "Check error log: ${OUTPUT_DIR}/error.log"
    if [ -f "${OUTPUT_DIR}/error.log" ]; then
        echo ""
        echo "Error details:"
        cat "${OUTPUT_DIR}/error.log"
    fi
fi