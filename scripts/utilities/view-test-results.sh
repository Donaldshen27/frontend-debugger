#!/bin/bash

# View test results
# Usage: ./view-test-results.sh [results-directory]

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get results directory
if [[ $# -eq 1 ]]; then
    RESULTS_DIR="$1"
else
    # Find the most recent results
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
    RESULTS_DIR=$(ls -td "${PROJECT_ROOT}/results/test-"* 2>/dev/null | head -1)
fi

if [[ -z "${RESULTS_DIR}" ]] || [[ ! -d "${RESULTS_DIR}" ]]; then
    echo "Error: No results directory found"
    echo "Usage: $0 [results-directory]"
    exit 1
fi

echo -e "${BLUE}Test Results Viewer${NC}"
echo -e "${BLUE}==================${NC}"
echo ""
echo -e "Results Directory: ${GREEN}${RESULTS_DIR}${NC}"
echo ""

# Show Claude's output
if [[ -f "${RESULTS_DIR}/logs/claude-output.log" ]]; then
    echo -e "${YELLOW}Claude's Test Summary:${NC}"
    echo "----------------------"
    cat "${RESULTS_DIR}/logs/claude-output.log"
    echo ""
fi

# Show generated report if exists
if [[ -f "${RESULTS_DIR}/tested-buttons-and-pages.md" ]]; then
    echo -e "${YELLOW}Generated Report:${NC}"
    echo "-----------------"
    head -20 "${RESULTS_DIR}/tested-buttons-and-pages.md"
    echo "..."
    echo ""
fi

# List screenshots
echo -e "${YELLOW}Screenshots:${NC}"
echo "------------"
if [[ -d "${RESULTS_DIR}/screenshots" ]]; then
    ls -1 "${RESULTS_DIR}/screenshots/" 2>/dev/null || echo "No screenshots found"
else
    echo "No screenshots directory"
fi
echo ""

# Show files
echo -e "${YELLOW}All Files:${NC}"
echo "----------"
find "${RESULTS_DIR}" -type f -name "*" | sed "s|${RESULTS_DIR}/||g"