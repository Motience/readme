#!/bin/bash

# Motience Platform - Start All Services Script
# This script starts all microservices in the correct order

set -e

echo "🚀 Starting Motience DePin Platform..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Start infrastructure (PostgreSQL and Redis)
echo -e "${BLUE}📦 Starting infrastructure (PostgreSQL & Redis)...${NC}"
# Try docker compose first (modern), fallback to docker-compose (legacy)
if command -v docker &> /dev/null; then
    docker compose up -d 2>/dev/null || docker-compose up -d
else
    echo -e "${YELLOW}⚠️  Docker not found. Please install Docker Desktop first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Infrastructure started${NC}"
echo ""

# Wait for databases to be ready
echo -e "${YELLOW}⏳ Waiting for databases to initialize...${NC}"
sleep 5

# Function to start a service
start_service() {
    local service_name=$1
    local service_dir=$2
    local port=$3
    
    echo -e "${BLUE}🔧 Starting ${service_name}...${NC}"
    cd "$service_dir"
    
    # Create .env if it doesn't exist
    if [ ! -f .env ]; then
        cp .env.example .env
        echo -e "${YELLOW}⚠️  Created .env file. Please configure it for production use.${NC}"
    fi
    
    # Install dependencies if needed
    if [ ! -d node_modules ]; then
        echo "  📥 Installing dependencies..."
        npm install > /dev/null 2>&1
    fi
    
    # Start service in background
    npm start > "../logs/${service_name}.log" 2>&1 &
    echo $! > "../logs/${service_name}.pid"
    
    echo -e "${GREEN}✅ ${service_name} started on port ${port}${NC}"
    cd ..
}

# Create logs directory
mkdir -p logs

# Start services in order
echo -e "${BLUE}🎯 Starting microservices...${NC}"
echo ""

start_service "Authentication Service (ap)" "ap" "3001"
sleep 2

start_service "Subscription Manager (sm)" "sm" "3002"
sleep 2

start_service "Data Stream Manager (dsm)" "dsm" "3003"
sleep 2

start_service "WebSocket Server 1 (wss1)" "wss1" "8001"
sleep 2

start_service "WebSocket Server 2 (wss2)" "wss2" "8002"
sleep 2

echo ""
echo -e "${GREEN}✅ All services started successfully!${NC}"
echo ""
echo "📋 Service Status:"
echo "  • PostgreSQL:     http://localhost:5432"
echo "  • Redis:          http://localhost:6379"
echo "  • Auth Service:   http://localhost:3001"
echo "  • Sub Manager:    http://localhost:3002"
echo "  • Data Manager:   http://localhost:3003"
echo "  • WSS1 (Producer): ws://localhost:8001"
echo "  • WSS2 (Consumer): ws://localhost:8002"
echo ""
echo "📖 View logs: tail -f logs/<service-name>.log"
echo "🛑 Stop all: ./stop-all.sh"
echo ""
