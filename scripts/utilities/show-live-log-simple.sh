#!/bin/bash

# Simple Live Dashboard for Button & CSS Testing
# Usage: ./show-live-log-simple.sh <output-dir>

# Check arguments
if [ $# -lt 1 ]; then
    echo "Error: No output directory provided"
    echo "Usage: $0 <output-dir>"
    exit 1
fi

OUTPUT_DIR="$1"

# Validate directory
if [ ! -d "${OUTPUT_DIR}" ]; then
    echo "Error: Directory not found: ${OUTPUT_DIR}"
    exit 1
fi

# Files to monitor
REPORT_FILE="${OUTPUT_DIR}/tested-buttons-and-pages.md"
CLAUDE_LOG="${OUTPUT_DIR}/logs/claude-output.log"

echo "=================================="
echo "Button & CSS Testing Live Monitor"
echo "=================================="
echo "Output Directory: ${OUTPUT_DIR}"
echo ""

# Main monitoring loop
while true; do
    clear
    echo "Button & CSS Testing Live Monitor"
    echo "================================="
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # Show statistics from report if it exists
    if [ -f "${REPORT_FILE}" ]; then
        echo "📊 Testing Statistics:"
        echo "---------------------"
        grep -E "^- Total Buttons Found:|^- CSS Issues Found:|^- Critical:|^- High:|^- Medium:|^- Low:" "${REPORT_FILE}" 2>/dev/null || echo "Loading..."
        echo ""
    else
        echo "Waiting for test to start..."
        echo ""
    fi
    
    # Show recent activity from Claude log
    if [ -f "${CLAUDE_LOG}" ]; then
        echo "🔄 Recent Activity:"
        echo "------------------"
        # Show last 10 relevant lines
        grep -E "BUTTON_FOUND|CSS_STATE|CSS_ISSUE|SCREENSHOT|TEST_COMPLETE" "${CLAUDE_LOG}" 2>/dev/null | tail -10 | while IFS= read -r line; do
            # Add simple prefixes for different types
            if echo "${line}" | grep -q "BUTTON_FOUND"; then
                echo "✓ ${line}"
            elif echo "${line}" | grep -q "CSS_STATE"; then
                echo "🔍 ${line}"
            elif echo "${line}" | grep -q "CSS_ISSUE"; then
                echo "⚠️  ${line}"
            elif echo "${line}" | grep -q "SCREENSHOT"; then
                echo "📸 ${line}"
            elif echo "${line}" | grep -q "TEST_COMPLETE"; then
                echo "✅ ${line}"
            else
                echo "  ${line}"
            fi
        done
        echo ""
    fi
    
    # Show current test status
    echo "📍 Status:"
    echo "----------"
    if [ -f "${CLAUDE_LOG}" ] && grep -q "ALL_TESTS_COMPLETE" "${CLAUDE_LOG}" 2>/dev/null; then
        echo "✅ Testing Complete!"
    else
        echo "🔄 Testing in progress..."
    fi
    echo ""
    
    echo "Press Ctrl+C to exit"
    echo "Report: ${REPORT_FILE}"
    
    # Wait before refresh
    sleep 2
done