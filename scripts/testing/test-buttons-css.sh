#!/bin/bash
set -euo pipefail

# Button & CSS Testing Script with Puppeteer MCP
# Usage: ./test-buttons-css.sh <target-url> [options]
# Options:
#   --output-dir <dir>    Custom output directory
#   --viewport <sizes>    Comma-separated viewport sizes (default: 375,768,1920)
#   --no-monitor         Skip real-time monitoring

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Default values
DEFAULT_VIEWPORTS="375,768,1920"
ENABLE_MONITOR=true

# Parse arguments
TARGET_URL=""
OUTPUT_DIR=""
VIEWPORTS="${DEFAULT_VIEWPORTS}"

while [[ $# -gt 0 ]]; do
    case $1 in
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --viewport)
            VIEWPORTS="$2"
            shift 2
            ;;
        --no-monitor)
            ENABLE_MONITOR=false
            shift
            ;;
        *)
            if [[ -z "${TARGET_URL}" ]]; then
                TARGET_URL="$1"
            else
                echo -e "${RED}Error: Unknown argument: $1${NC}"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate URL
if [[ -z "${TARGET_URL}" ]]; then
    echo -e "${RED}Error: No URL provided${NC}"
    echo "Usage: $0 <target-url> [options]"
    echo ""
    echo "Options:"
    echo "  --output-dir <dir>    Custom output directory"
    echo "  --viewport <sizes>    Comma-separated viewport sizes (default: 375,768,1920)"
    echo "  --no-monitor         Skip real-time monitoring"
    exit 1
fi

# Extract domain from URL for output naming
DOMAIN=$(echo "${TARGET_URL}" | sed -E 's|https?://||' | sed -E 's|/.*||' | sed 's|[^a-zA-Z0-9-]|_|g')
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Set output directory
if [[ -z "${OUTPUT_DIR}" ]]; then
    OUTPUT_DIR="${PROJECT_ROOT}/results/test-${DOMAIN}-${TIMESTAMP}"
fi

# Create output directory
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}/screenshots"
mkdir -p "${OUTPUT_DIR}/logs"

echo -e "${BLUE}Button & CSS Testing System${NC}"
echo -e "${BLUE}=========================${NC}"
echo ""
echo -e "Target URL: ${GREEN}${TARGET_URL}${NC}"
echo -e "Output Directory: ${GREEN}${OUTPUT_DIR}${NC}"
echo -e "Viewports: ${GREEN}${VIEWPORTS}${NC}"
echo -e "Monitor Enabled: ${GREEN}${ENABLE_MONITOR}${NC}"
echo ""

# Create the test prompt
echo -e "${YELLOW}Creating test prompt...${NC}"

# Check if strict prompt exists, use it as template
if [[ -f "${PROJECT_ROOT}/claude/prompts/button-css-test-strict.md" ]]; then
    cp "${PROJECT_ROOT}/claude/prompts/button-css-test-strict.md" "${OUTPUT_DIR}/prompt.md"
    # Replace the URL placeholder
    sed -i "s|{{url}}|${TARGET_URL}|g" "${OUTPUT_DIR}/prompt.md"
else
    # Fall back to inline prompt
    cat > "${OUTPUT_DIR}/prompt.md" << EOF
You are an automated frontend testing assistant with access to Puppeteer for browser automation.
Your task is to systematically test all buttons and interactive elements on the website, with a focus on CSS validation.

## Target URL: ${TARGET_URL}

## Testing Instructions:

### 1. Initial Setup
- Navigate to the URL using Puppeteer MCP
- Take a full-page screenshot
- Wait for the page to fully load (including dynamic content)

### 2. Button Discovery
- Find ALL clickable elements including:
  - \`<button>\` elements
  - \`<a>\` tags styled as buttons
  - \`<input type="button|submit|reset">\`
  - Elements with \`role="button"\`
  - Elements with click handlers
- For each element, output: \`[BUTTON_FOUND: <selector>] <text or aria-label>\`

### 3. CSS State Testing
For each button found, test the following states:

#### Default State:
- Get computed styles using \`window.getComputedStyle()\`
- Record: background-color, color, border, padding, font properties
- Take screenshot: \`[SCREENSHOT: button-default-<index>.png]\`

#### Hover State:
- Use \`locator.hover()\`
- Wait 100ms for transitions
- Get computed styles again
- Record style changes
- Output: \`[CSS_STATE: hover] <selector>\`
- Take screenshot: \`[SCREENSHOT: button-hover-<index>.png]\`

#### Active/Pressed State:
- Simulate mousedown event
- Get computed styles
- Output: \`[CSS_STATE: active] <selector>\`
- Release mouse

#### Focus State:
- Use \`locator.focus()\`
- Get computed styles including outline
- Output: \`[CSS_STATE: focus] <selector>\`
- Take screenshot if visual change detected

#### Disabled State (if applicable):
- Check for disabled attribute
- Get computed styles
- Output: \`[CSS_STATE: disabled] <selector>\`

### 4. CSS Validation
For each state transition, validate:
- Color contrast ratios (WCAG compliance)
- Transition/animation properties
- Box model changes (padding, margin, border)
- Transform properties
- Opacity changes
- CSS custom properties (variables)

Report issues with severity:
- \`[CSS_ISSUE: CRITICAL]\` - No visual feedback on interaction
- \`[CSS_ISSUE: HIGH]\` - Poor contrast, missing focus indicators
- \`[CSS_ISSUE: MEDIUM]\` - Inconsistent styling, jarring transitions
- \`[CSS_ISSUE: LOW]\` - Minor visual glitches

### 5. Responsive Testing
Test each button at different viewports:
EOF

# Add viewports to prompt
IFS=',' read -ra VIEWPORT_ARRAY <<< "${VIEWPORTS}"
for viewport in "${VIEWPORT_ARRAY[@]}"; do
    echo "- ${viewport}px width" >> "${OUTPUT_DIR}/prompt.md"
done

cat >> "${OUTPUT_DIR}/prompt.md" << EOF

### 6. Output Format
Use these exact markers for the monitoring system:
- \`[PAGE_LOADED: <url>]\` - When page is ready
- \`[BUTTON_FOUND: <selector>] <text>\` - For each button discovered
- \`[CSS_STATE: <state>] <selector>\` - When testing a state
- \`[CSS_PROPERTY: <property>] <value>\` - For important CSS values
- \`[CSS_ISSUE: <severity>] <selector> - <description>\` - For issues found
- \`[SCREENSHOT: <filename>]\` - When saving screenshots
- \`[VIEWPORT_TEST: <width>px]\` - When changing viewport
- \`[TEST_COMPLETE: <selector>]\` - When done testing a button
- \`[ALL_TESTS_COMPLETE]\` - When finished

### 7. Performance Notes
- Use \`Promise.all()\` for batch operations where possible
- Set reasonable timeouts (3 seconds per element)
- Handle errors gracefully and continue testing
- Save screenshots to minimize file size

Please be thorough but efficient. Focus on actual user-facing issues rather than minor pixel differences.
EOF

# Function to cleanup on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}Cleaning up...${NC}"
    if [[ -n "${MONITOR_PID:-}" ]] && kill -0 "${MONITOR_PID}" 2>/dev/null; then
        kill "${MONITOR_PID}"
    fi
    exit 0
}

trap cleanup EXIT INT TERM

# Start monitoring script if enabled
MONITOR_PID=""
if [[ "${ENABLE_MONITOR}" == "true" ]]; then
    echo -e "${YELLOW}Starting monitoring script...${NC}"
    # Create a named pipe for monitoring
    PIPE_FILE="${OUTPUT_DIR}/monitor.pipe"
    mkfifo "${PIPE_FILE}"
    
    # Start monitor reading from pipe
    node "${PROJECT_ROOT}/n8n/scripts/monitor-button-test.js" \
        "${TARGET_URL}" \
        "${OUTPUT_DIR}" \
        < "${PIPE_FILE}" \
        2>&1 | tee "${OUTPUT_DIR}/logs/monitor.log" &
    MONITOR_PID=$!
    sleep 2 # Give monitor time to start
fi

# Run Claude with Puppeteer MCP
echo -e "${YELLOW}Launching Claude Code CLI with Puppeteer MCP...${NC}"
echo -e "${YELLOW}This will test all buttons and CSS states on ${TARGET_URL}${NC}"
echo ""

if [[ "${ENABLE_MONITOR}" == "true" ]] && [[ -n "${PIPE_FILE}" ]]; then
    # Run Claude and tee output to both log and pipe
    claude --dangerously-skip-permissions \
        --mcp-config "${PROJECT_ROOT}/claude/mcp/puppeteer-config.json" \
        -p "$(cat "${OUTPUT_DIR}/prompt.md")" \
        2>&1 | tee "${OUTPUT_DIR}/logs/claude-output.log" "${PIPE_FILE}"
else
    # Run Claude without monitoring
    claude --dangerously-skip-permissions \
        --mcp-config "${PROJECT_ROOT}/claude/mcp/puppeteer-config.json" \
        -p "$(cat "${OUTPUT_DIR}/prompt.md")" \
        2>&1 | tee "${OUTPUT_DIR}/logs/claude-output.log"
fi

# Wait for monitor to finish processing
if [[ "${ENABLE_MONITOR}" == "true" ]] && [[ -n "${MONITOR_PID}" ]]; then
    echo ""
    echo -e "${YELLOW}Waiting for monitor to finish processing...${NC}"
    sleep 3
    if kill -0 "${MONITOR_PID}" 2>/dev/null; then
        kill -TERM "${MONITOR_PID}"
    fi
fi

echo ""
echo -e "${GREEN}Testing complete!${NC}"
echo -e "${GREEN}=================${NC}"
echo ""
echo -e "Results saved in: ${BLUE}${OUTPUT_DIR}${NC}"
echo ""
echo "Files created:"
echo "  - Test Report: ${OUTPUT_DIR}/tested-buttons-and-pages.md"
echo "  - Claude Log: ${OUTPUT_DIR}/logs/claude-output.log"
echo "  - Screenshots: ${OUTPUT_DIR}/screenshots/"
echo ""

# Show summary if report exists
if [[ -f "${OUTPUT_DIR}/tested-buttons-and-pages.md" ]]; then
    echo -e "${YELLOW}Summary:${NC}"
    grep -E "^- Total|^- CSS Issues" "${OUTPUT_DIR}/tested-buttons-and-pages.md" || true
fi
fi