#!/bin/bash
set -euo pipefail

# Direct Button & CSS Testing Script (without monitoring)
# Usage: ./test-buttons-css-direct.sh <target-url>

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Check arguments
if [[ $# -lt 1 ]]; then
    echo -e "${RED}Error: No URL provided${NC}"
    echo "Usage: $0 <target-url>"
    exit 1
fi

TARGET_URL="$1"
DOMAIN=$(echo "${TARGET_URL}" | sed -E 's|https?://||' | sed -E 's|/.*||' | sed 's|[^a-zA-Z0-9-]|_|g')
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_DIR="${PROJECT_ROOT}/results/test-${DOMAIN}-${TIMESTAMP}"

# Create output directory
mkdir -p "${OUTPUT_DIR}"

echo -e "${BLUE}Button & CSS Testing System${NC}"
echo -e "${BLUE}=========================${NC}"
echo ""
echo -e "Target URL: ${GREEN}${TARGET_URL}${NC}"
echo -e "Output Directory: ${GREEN}${OUTPUT_DIR}${NC}"
echo ""

# Create a simplified prompt
cat > "${OUTPUT_DIR}/prompt.md" << 'EOF'
You have access to Puppeteer MCP for browser automation. Please test the buttons and interactive elements on the provided website.

**Target URL:** TARGET_URL_PLACEHOLDER

**Your task:**

1. Navigate to the URL
2. Take a screenshot of the page
3. Find all clickable elements (buttons, links styled as buttons, inputs, elements with click handlers)
4. For each element:
   - Test hover state (if possible)
   - Test click functionality
   - Check CSS properties
   - Note any accessibility issues
5. Test at different viewport sizes: 375px (mobile), 768px (tablet), 1920px (desktop)
6. Generate a markdown report

**Report format:**
```markdown
# CSS Test Report for [domain]

## Summary
- Total interactive elements found: X
- Issues found: Y
- Viewports tested: 375px, 768px, 1920px

## Elements Tested

### Element 1: [description]
- Selector: [css selector]
- Type: button/link/input
- States tested: default, hover, active, focus
- CSS properties:
  - Background: [color]
  - Text color: [color]
  - Border: [style]
- Issues: [any problems found]
- Screenshot: [if taken]

## Accessibility Issues
[List any missing ARIA labels, focus indicators, etc.]

## Responsive Behavior
[How elements behave at different viewport sizes]

## Recommendations
[Prioritized list of improvements]
```

Please be thorough but focus on actual user-facing issues. Save any screenshots to help document the findings.
EOF

# Replace placeholder with actual URL
sed -i "s|TARGET_URL_PLACEHOLDER|${TARGET_URL}|g" "${OUTPUT_DIR}/prompt.md"

echo -e "${YELLOW}Launching Claude Code CLI with Puppeteer MCP...${NC}"
echo -e "${YELLOW}This will test all buttons and CSS states on ${TARGET_URL}${NC}"
echo ""

# Run Claude with output directly to terminal and log
claude --dangerously-skip-permissions \
    --mcp-config "${PROJECT_ROOT}/claude/mcp/puppeteer-config.json" \
    -p "$(cat "${OUTPUT_DIR}/prompt.md")" \
    2>&1 | tee "${OUTPUT_DIR}/test-output.log"

echo ""
echo -e "${GREEN}Testing complete!${NC}"
echo -e "${GREEN}=================${NC}"
echo ""
echo -e "Results saved in: ${BLUE}${OUTPUT_DIR}${NC}"
echo ""
echo "Files created:"
echo "  - Test Output: ${OUTPUT_DIR}/test-output.log"
echo "  - Prompt Used: ${OUTPUT_DIR}/prompt.md"
echo ""
echo "To view the test output:"
echo "  cat ${OUTPUT_DIR}/test-output.log"