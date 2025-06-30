#!/bin/bash
set -euo pipefail

# Live Dashboard for Button & CSS Testing
# Usage: ./show-live-log.sh <output-dir>

# Ensure we're running with bash
if [ -z "${BASH_VERSION:-}" ]; then
    echo "Error: This script must be run with bash, not sh"
    echo "Usage: bash $0 <output-dir>"
    exit 1
fi

# Check if we have proper echo support
if ! echo -e "test" >/dev/null 2>&1; then
    # Use printf as fallback
    alias echo='printf %s\n'
fi

# Colors (using tput for better compatibility)
if command -v tput >/dev/null 2>&1 && [ -t 1 ]; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    BOLD=$(tput bold)
    NC=$(tput sgr0)
else
    # No color support
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    MAGENTA=''
    BOLD=''
    NC=''
fi

# Check arguments
if [[ $# -lt 1 ]]; then
    printf "${RED}Error: No output directory provided${NC}\n"
    printf "Usage: $0 <output-dir>\n"
    exit 1
fi

OUTPUT_DIR="$1"

# Validate directory
if [[ ! -d "${OUTPUT_DIR}" ]]; then
    printf "${RED}Error: Directory not found: ${OUTPUT_DIR}${NC}\n"
    exit 1
fi

# Files to monitor
CLAUDE_LOG="${OUTPUT_DIR}/logs/claude-output.log"
MONITOR_LOG="${OUTPUT_DIR}/logs/monitor.log"
REPORT_FILE="${OUTPUT_DIR}/tested-buttons-and-pages.md"

# Function to display header
show_header() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${BOLD}${CYAN}Button & CSS Testing Live Dashboard${NC}                               ${BLUE}║${NC}"
    echo -e "${BLUE}╠════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC}  Output Directory: ${GREEN}${OUTPUT_DIR}${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to show statistics
show_stats() {
    if [[ -f "${REPORT_FILE}" ]]; then
        echo -e "${YELLOW}${BOLD}📊 Testing Statistics:${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        # Extract stats from report
        local total_buttons=$(grep -m1 "Total Buttons Found:" "${REPORT_FILE}" 2>/dev/null | sed 's/.*: //' || echo "0")
        local buttons_with_issues=$(grep -m1 "Buttons with Issues:" "${REPORT_FILE}" 2>/dev/null | sed 's/.*: //' || echo "0")
        local total_issues=$(grep -m1 "CSS Issues Found:" "${REPORT_FILE}" 2>/dev/null | sed 's/.*: //' || echo "0")
        local critical=$(grep -m1 "Critical:" "${REPORT_FILE}" 2>/dev/null | sed 's/.*: //' || echo "0")
        local high=$(grep -m1 "High:" "${REPORT_FILE}" 2>/dev/null | sed 's/.*: //' || echo "0")
        local medium=$(grep -m1 "Medium:" "${REPORT_FILE}" 2>/dev/null | sed 's/.*: //' || echo "0")
        local low=$(grep -m1 "Low:" "${REPORT_FILE}" 2>/dev/null | sed 's/.*: //' || echo "0")
        
        echo -e "  ${CYAN}Total Buttons:${NC} ${BOLD}${total_buttons}${NC}"
        echo -e "  ${CYAN}Buttons with Issues:${NC} ${BOLD}${buttons_with_issues}${NC}"
        echo -e "  ${CYAN}Total Issues:${NC} ${BOLD}${total_issues}${NC}"
        
        if [[ "${total_issues}" != "0" ]]; then
            echo ""
            echo -e "  ${RED}🔴 Critical:${NC} ${critical}"
            echo -e "  ${YELLOW}🟠 High:${NC} ${high}"
            echo -e "  ${YELLOW}🟡 Medium:${NC} ${medium}"
            echo -e "  ${BLUE}🔵 Low:${NC} ${low}"
        fi
        echo ""
    else
        echo -e "${YELLOW}Waiting for test to start...${NC}"
        echo ""
    fi
}

# Function to show recent activity
show_activity() {
    echo -e "${MAGENTA}${BOLD}🔄 Recent Activity:${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━${NC}"
    
    if [[ -f "${CLAUDE_LOG}" ]]; then
        # Show last few relevant lines
        grep -E "\[BUTTON_FOUND|\[CSS_STATE|\[CSS_ISSUE|\[SCREENSHOT|\[TEST_COMPLETE" "${CLAUDE_LOG}" 2>/dev/null | tail -5 | while IFS= read -r line; do
            if [[ "${line}" =~ \[BUTTON_FOUND ]]; then
                echo -e "  ${GREEN}✓${NC} ${line}"
            elif [[ "${line}" =~ \[CSS_STATE ]]; then
                echo -e "  ${CYAN}🔍${NC} ${line}"
            elif [[ "${line}" =~ \[CSS_ISSUE ]]; then
                if [[ "${line}" =~ CRITICAL ]]; then
                    echo -e "  ${RED}⚠️${NC} ${line}"
                else
                    echo -e "  ${YELLOW}⚠️${NC} ${line}"
                fi
            elif [[ "${line}" =~ \[SCREENSHOT ]]; then
                echo -e "  ${BLUE}📸${NC} ${line}"
            elif [[ "${line}" =~ \[TEST_COMPLETE ]]; then
                echo -e "  ${GREEN}✅${NC} ${line}"
            fi
        done
    else
        echo -e "  ${YELLOW}Waiting for activity...${NC}"
    fi
    echo ""
}

# Function to show current status
show_status() {
    echo -e "${GREEN}${BOLD}📍 Current Status:${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━${NC}"
    
    if [[ -f "${MONITOR_LOG}" ]]; then
        # Get last status from monitor
        local last_status=$(tail -5 "${MONITOR_LOG}" 2>/dev/null | grep -E "Page loaded|Testing.*state|Found button|Completed testing" | tail -1 || echo "")
        if [[ -n "${last_status}" ]]; then
            echo -e "  ${last_status}"
        else
            echo -e "  ${YELLOW}Initializing...${NC}"
        fi
    else
        echo -e "  ${YELLOW}Monitor starting...${NC}"
    fi
    echo ""
}

# Function to display dashboard
display_dashboard() {
    show_header
    
    # Create two-column layout
    echo -e "${BOLD}┌─ Live Testing Progress ─────────────────────────────────────────────┐${NC}"
    echo ""
    
    # Left column: Stats and Status
    show_stats
    show_status
    
    # Right column: Recent Activity
    show_activity
    
    echo -e "${BOLD}└─────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Show instructions
    echo -e "${CYAN}${BOLD}Instructions:${NC}"
    echo -e "  • Press ${BOLD}Ctrl+C${NC} to exit"
    echo -e "  • View full report: ${BLUE}${REPORT_FILE}${NC}"
    echo -e "  • Screenshots saved in: ${BLUE}${OUTPUT_DIR}/screenshots/${NC}"
}

# Main loop
echo -e "${GREEN}Starting live dashboard...${NC}"
sleep 1

# Use watch for auto-refresh, or manual loop if watch not available
if command -v watch &> /dev/null; then
    # Use watch command for better performance
    watch -n 1 -t "$(declare -f show_header show_stats show_activity show_status display_dashboard); display_dashboard"
else
    # Manual refresh loop
    while true; do
        display_dashboard
        sleep 1
    done
fi