#!/bin/bash

# Import workflow to n8n via API
# This script imports the frontend-debugger workflow

echo "n8n Workflow Importer"
echo "===================="
echo ""

# Read the workflow file
WORKFLOW_JSON=$(cat n8n/workflows/frontend-debugger.json)

# First, we need to get an API token
# Note: This requires the n8n API to be enabled
echo "Attempting to import workflow via n8n container..."

# Copy workflow file to container and import directly
docker cp n8n/workflows/frontend-debugger.json docker-n8n-1:/tmp/workflow.json

# Import using n8n CLI inside container
docker exec docker-n8n-1 n8n import:workflow --input=/tmp/workflow.json

echo ""
echo "If the import was successful, you should see the workflow in n8n UI."
echo "Remember to:"
echo "1. Open the workflow"
echo "2. Click the 'Active' toggle to enable it"
echo "3. Save the workflow"
echo ""
echo "Login credentials:"
echo "Email: admin@example.com"
echo "Password: admin123"