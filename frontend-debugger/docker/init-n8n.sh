#!/bin/bash

# Initialize n8n with workflow and credentials
# This script runs after n8n is up and running

echo "Waiting for n8n to be ready..."
until curl -s http://localhost:5678/healthz > /dev/null; do
  sleep 2
done

echo "n8n is ready!"

# Create credentials via API (example)
# Note: In production, use proper credential management

# PostgreSQL credential for frontend_debugger database
curl -X POST http://admin:admin@localhost:5678/api/v1/credentials \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Frontend Debugger DB",
    "type": "postgres",
    "data": {
      "host": "postgres",
      "port": 5432,
      "database": "frontend_debugger",
      "user": "postgres",
      "password": "postgres"
    }
  }'

echo "Setup complete!"