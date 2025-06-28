#!/bin/bash

# Frontend Debugger Server Startup Script
# This script ensures a clean start by clearing ports and starting all services

set -e

echo "Frontend Debugger - Server Startup"
echo "================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to kill process on port
kill_port() {
    local port=$1
    echo -e "${YELLOW}Checking port $port...${NC}"
    
    if check_port $port; then
        echo -e "${RED}Port $port is in use. Attempting to free it...${NC}"
        
        # Get PIDs using the port
        local pids=$(lsof -ti:$port)
        
        if [ ! -z "$pids" ]; then
            echo "Found processes: $pids"
            
            # Try graceful shutdown first
            for pid in $pids; do
                echo "Stopping process $pid..."
                kill $pid 2>/dev/null || true
            done
            
            sleep 2
            
            # Force kill if still running
            for pid in $pids; do
                if kill -0 $pid 2>/dev/null; then
                    echo "Force killing process $pid..."
                    kill -9 $pid 2>/dev/null || true
                fi
            done
            
            echo -e "${GREEN}Port $port cleared${NC}"
        fi
    else
        echo -e "${GREEN}Port $port is free${NC}"
    fi
}

# Function to stop Docker containers on specific ports
stop_docker_on_port() {
    local port=$1
    echo -e "${YELLOW}Checking for Docker containers on port $port...${NC}"
    
    # Find containers using the port
    local containers=$(docker ps --format "table {{.ID}}\t{{.Ports}}" | grep ":$port->" | awk '{print $1}')
    
    if [ ! -z "$containers" ]; then
        echo -e "${RED}Found Docker containers using port $port${NC}"
        for container in $containers; do
            echo "Stopping container $container..."
            docker stop $container 2>/dev/null || true
        done
        echo -e "${GREEN}Docker containers stopped${NC}"
    fi
}

# Navigate to project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Stop any existing Docker compose services
echo -e "\n${YELLOW}Stopping existing Docker services...${NC}"
cd docker
docker compose down 2>/dev/null || true
cd ..

# Clear required ports
echo -e "\n${YELLOW}Clearing required ports...${NC}"

# Clear n8n port
stop_docker_on_port 5678
kill_port 5678

# Clear PostgreSQL port (we're using 6666)
stop_docker_on_port 6666
kill_port 6666

# Clear Adminer port
stop_docker_on_port 8080
kill_port 8080

# Clear default PostgreSQL port (in case something is still using it)
stop_docker_on_port 5432
kill_port 5432

# Remove orphan containers if any
echo -e "\n${YELLOW}Removing orphan containers...${NC}"
docker compose -f docker/docker-compose.yml down --remove-orphans 2>/dev/null || true

# Start services
echo -e "\n${YELLOW}Starting Docker services...${NC}"
cd docker
docker compose up -d

# Wait for services to be ready
echo -e "\n${YELLOW}Waiting for services to start...${NC}"

# Wait for PostgreSQL
echo -n "Waiting for PostgreSQL..."
for i in {1..30}; do
    if docker exec docker-postgres-1 pg_isready -U postgres >/dev/null 2>&1; then
        echo -e " ${GREEN}Ready!${NC}"
        break
    fi
    echo -n "."
    sleep 1
done

# Wait for n8n
echo -n "Waiting for n8n..."
for i in {1..60}; do
    if curl -s http://localhost:5678/healthz >/dev/null 2>&1; then
        echo -e " ${GREEN}Ready!${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

# Final status check
echo -e "\n${YELLOW}Checking service status...${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(docker-n8n|docker-postgres|docker-adminer)" || true

echo -e "\n${GREEN}✓ All services started successfully!${NC}"
echo ""
echo "Access points:"
echo "- n8n UI: http://localhost:5678"
echo "  - Email: donaldshen27@gmail.com"
echo "  - Password: Sjd04052!"
echo "- Adminer: http://localhost:8080"
echo "  - Server: postgres"
echo "  - Username: postgres"
echo "  - Password: postgres"
echo "  - Database: frontend_debugger"
echo ""
echo "Next steps:"
echo "1. Open http://localhost:5678"
echo "2. Import the workflow from: n8n/workflows/frontend-debugger.json"
echo "3. Configure credentials if needed"
echo "4. Test with: ./test-frontend-debug.sh https://example.com"
echo ""