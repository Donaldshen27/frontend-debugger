#!/bin/bash

# Test script for the frontend debugger system

echo "Frontend Debugger Test Script"
echo "============================="
echo ""
echo "This script will trigger the frontend debugging workflow."
echo ""

# Check if target URL is provided
TARGET_URL="${1:-https://example.com}"
EMAIL="${2:-donaldshen27@gmail.com}"

echo "Target URL: $TARGET_URL"
echo "Notification Email: $EMAIL"
echo ""

# Check if n8n is running
echo "Checking n8n status..."
if curl -s http://localhost:5678/healthz > /dev/null; then
    echo "✓ n8n is running"
else
    echo "✗ n8n is not running. Please ensure Docker services are up."
    echo "  Run: cd docker && docker compose up -d"
    exit 1
fi

# Trigger the workflow
echo ""
echo "Triggering frontend debug workflow..."
RESPONSE=$(curl -s -X POST http://localhost:5678/webhook/frontend-debug-start \
  -H "Content-Type: application/json" \
  -d "{
    \"targetUrl\": \"$TARGET_URL\",
    \"notificationEmail\": \"$EMAIL\"
  }")

echo "Response: $RESPONSE"
echo ""
echo "The debugging session has started!"
echo ""
echo "You can monitor progress at:"
echo "- n8n UI: http://localhost:5678"
echo "- Database: http://localhost:8080 (adminer)"
echo "  - Server: postgres"
echo "  - Username: postgres"
echo "  - Password: postgres"
echo "  - Database: frontend_debugger"