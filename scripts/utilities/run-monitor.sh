#!/bin/bash

# This script runs the monitor from the host system
# It's called by n8n but executes on the host

echo "Frontend Debug Monitor Launcher"
echo "=============================="
echo "Target URL: $1"
echo ""

# Set up environment
export TARGET_URL="$1"
export DB_HOST=localhost
export DB_PORT=6666
export DB_NAME=frontend_debugger
export DB_USER=postgres
export DB_PASSWORD=postgres
export N8N_WEBHOOK_URL=http://localhost:5678/webhook/frontend-debug-callback

# Change to project directory
cd /home/a11a2/projects/n8n_tests/frontend-debugger

# Check if Claude is available
if ! command -v claude &> /dev/null; then
    echo "ERROR: Claude CLI not found!"
    echo "Please install with: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

echo "Starting Claude monitor..."
# Run the monitor script
node n8n/scripts/monitor-claude.js