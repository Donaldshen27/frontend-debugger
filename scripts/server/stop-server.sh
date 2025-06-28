#!/bin/bash

# Frontend Debugger Server Stop Script
# This script cleanly stops all services

echo "Frontend Debugger - Server Shutdown"
echo "==================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Navigate to project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Stop Docker services
echo -e "${YELLOW}Stopping Docker services...${NC}"
cd docker
docker compose down

echo -e "\n${GREEN}✓ All services stopped${NC}"
echo ""