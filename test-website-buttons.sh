#!/bin/bash

# Quick launcher for button & CSS testing
# Usage: ./test-website-buttons.sh <url>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if URL provided
if [ $# -lt 1 ]; then
    echo "Button & CSS Testing System"
    echo "=========================="
    echo ""
    echo "Usage: $0 <website-url>"
    echo ""
    echo "Examples:"
    echo "  $0 https://example.com"
    echo "  $0 https://twentyfourpoints.com"
    echo ""
    echo "The test will:"
    echo "  - Find all buttons and clickable elements"
    echo "  - Test CSS states (hover, active, focus)"
    echo "  - Take screenshots of each state"
    echo "  - Generate a detailed report"
    echo ""
    exit 1
fi

URL="$1"

echo "Starting Button & CSS Testing System"
echo "===================================="
echo "Target: ${URL}"
echo ""

# Run the test
cd "${SCRIPT_DIR}/scripts/testing"
./test-buttons-css.sh "${URL}"

# Get the latest results directory
LATEST_RESULTS=$(ls -td "${SCRIPT_DIR}/results/test-"* 2>/dev/null | head -1)

if [ -n "${LATEST_RESULTS}" ]; then
    echo ""
    echo "Test complete! Results saved in:"
    echo "${LATEST_RESULTS}"
    echo ""
    echo "To view the live dashboard, run:"
    echo "  ${SCRIPT_DIR}/scripts/utilities/show-live-log-simple.sh ${LATEST_RESULTS}"
    echo ""
    echo "To view the report:"
    echo "  cat ${LATEST_RESULTS}/tested-buttons-and-pages.md"
fi