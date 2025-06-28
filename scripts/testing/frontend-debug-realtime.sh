#!/bin/bash

# Real-time Frontend Debugger
echo "🔍 Real-time Frontend Debugger"
echo "=============================="
echo ""

# Get target URL
TARGET_URL="${1:-https://example.com}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_DIR="debug-results-$TIMESTAMP"

echo "🌐 Target URL: $TARGET_URL"
echo "📁 Output Directory: $OUTPUT_DIR"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Create a streaming prompt that gives real-time feedback
cat > "$OUTPUT_DIR/prompt.md" << 'EOF'
You are testing a website. Please provide real-time feedback as you work.

**IMPORTANT**: Output status updates using these exact markers so I can track progress:
- When starting a page: `[TESTING] <url>`
- When you find an issue: `[ISSUE: <severity>] <description>`
- When done with a page: `[COMPLETE] <url>`
- For general status: `[STATUS] <message>`

Target URL: TARGET_URL_PLACEHOLDER

Please:
1. Navigate to the URL
2. Announce each action you take with [STATUS]
3. Test all interactive elements
4. Report issues immediately with [ISSUE: severity]
5. Check responsive design
6. List found links at the end

Start testing now!
EOF

# Replace placeholder with actual URL
sed -i "s|TARGET_URL_PLACEHOLDER|$TARGET_URL|g" "$OUTPUT_DIR/prompt.md"

echo "🚀 Starting Claude Code CLI..."
echo "==============================="
echo ""

# Function to colorize output based on markers
colorize_output() {
    while IFS= read -r line; do
        case "$line" in
            *"[TESTING]"*)
                echo -e "\033[1;34m$line\033[0m"  # Blue
                ;;
            *"[ISSUE: CRITICAL]"*)
                echo -e "\033[1;31m$line\033[0m"  # Red
                ;;
            *"[ISSUE: HIGH]"*)
                echo -e "\033[1;33m$line\033[0m"  # Yellow
                ;;
            *"[ISSUE: MEDIUM]"*)
                echo -e "\033[0;33m$line\033[0m"  # Orange
                ;;
            *"[ISSUE: LOW]"*)
                echo -e "\033[0;36m$line\033[0m"  # Cyan
                ;;
            *"[COMPLETE]"*)
                echo -e "\033[1;32m$line\033[0m"  # Green
                ;;
            *"[STATUS]"*)
                echo -e "\033[0;37m$line\033[0m"  # Gray
                ;;
            *)
                echo "$line"
                ;;
        esac
        
        # Also save to file
        echo "$line" >> "$OUTPUT_DIR/debug-log.txt"
    done
}

# Run Claude with real-time output processing
claude --dangerously-skip-permissions \
       --mcp-config claude/mcp/puppeteer-config.json \
       -p "$(cat $OUTPUT_DIR/prompt.md)" \
       2>&1 | colorize_output

echo ""
echo "✅ Debug session complete!"
echo "📊 Results saved in: $OUTPUT_DIR/"
echo ""

# Parse results for summary
echo "📈 Summary:"
echo "==========="
if [ -f "$OUTPUT_DIR/debug-log.txt" ]; then
    echo "Pages tested: $(grep -c "\[COMPLETE\]" "$OUTPUT_DIR/debug-log.txt" || echo "0")"
    echo "Critical issues: $(grep -c "\[ISSUE: CRITICAL\]" "$OUTPUT_DIR/debug-log.txt" || echo "0")"
    echo "High issues: $(grep -c "\[ISSUE: HIGH\]" "$OUTPUT_DIR/debug-log.txt" || echo "0")"
    echo "Medium issues: $(grep -c "\[ISSUE: MEDIUM\]" "$OUTPUT_DIR/debug-log.txt" || echo "0")"
    echo "Low issues: $(grep -c "\[ISSUE: LOW\]" "$OUTPUT_DIR/debug-log.txt" || echo "0")"
fi

echo ""
echo "📄 Files created:"
ls -la "$OUTPUT_DIR/"