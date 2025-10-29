#!/bin/bash

# Motience Platform - Stop All Services Script

echo "🛑 Stopping Motience DePin Platform..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to stop a service
stop_service() {
    local service_name=$1
    local pid_file="logs/${service_name}.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo -e "  Stopping ${service_name}..."
            kill "$pid"
            rm "$pid_file"
        else
            echo -e "  ${service_name} is not running"
            rm "$pid_file"
        fi
    else
        echo -e "  ${service_name} PID file not found"
    fi
}

# Stop all Node.js services
stop_service "Authentication Service (ap)"
stop_service "Subscription Manager (sm)"
stop_service "Data Stream Manager (dsm)"
stop_service "WebSocket Server 1 (wss1)"
stop_service "WebSocket Server 2 (wss2)"

# Stop Docker containers
echo ""
echo "🐳 Stopping Docker containers..."
# Try docker compose first (modern), fallback to docker-compose (legacy)
docker compose down 2>/dev/null || docker-compose down

echo ""
echo -e "${GREEN}✅ All services stopped${NC}"
echo ""
