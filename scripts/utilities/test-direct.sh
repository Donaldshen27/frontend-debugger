#!/bin/bash

# Direct test of the monitor script
echo "Testing Claude Monitor directly..."
echo "================================"

cd /home/a11a2/projects/n8n_tests/frontend-debugger

# Test the monitor script directly
TARGET_URL="https://example.com" \
DB_HOST=localhost \
DB_PORT=6666 \
N8N_WEBHOOK_URL=http://localhost:5678/webhook/frontend-debug-callback \
node n8n/scripts/monitor-claude.js