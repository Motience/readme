# Motience - Quick Start Guide

Get the Motience DePin platform up and running in 5 minutes.

> **Note:** This guide assumes you're starting from the `readme` repository, which contains documentation, Docker configurations, and orchestration scripts. Individual services are in separate repositories.

## Prerequisites

- **Node.js** 18+ and npm
- **Rust** 1.70+ (for IoT plugin and BlockchainHandler)
- **Docker** and Docker Compose
- **Git** (to clone service repositories)

## Step 0: Clone Repositories

```bash
# Create workspace directory
mkdir motience-platform && cd motience-platform

# Clone all service repositories
git clone https://github.com/Motience/readme.git
git clone https://github.com/Motience/DepinPlugin.git
git clone https://github.com/Motience/AuthenticationPlatform.git
git clone https://github.com/Motience/SubscriptionManager.git
git clone https://github.com/Motience/DataStreamManager.git
git clone https://github.com/Motience/WebSocket-Server1.git
git clone https://github.com/Motience/Websocket-Server2.git
git clone https://github.com/Motience/BlockchainHandler.git
```

## Step 1: Start Infrastructure & Services

```bash
# Navigate to readme repository
cd readme

# First, start infrastructure (PostgreSQL & Redis)
docker compose up -d

# Make scripts executable
chmod +x start-all.sh stop-all.sh

# Start all services
./start-all.sh
```

This will start:
- PostgreSQL database
- Redis server
- Authentication Service (port 3001)
- Subscription Manager (port 3002)
- Data Stream Manager (port 3003)
- WebSocket Server 1 - Producers (port 8001)
- WebSocket Server 2 - Consumers (port 8002)

## Step 2: Register Users

### Register a Producer

```bash
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "producer1",
    "password": "pass123",
    "role": "producer",
    "device_id": "rpi_001"
  }'
```

### Register a Consumer

```bash
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "consumer1",
    "password": "pass123",
    "role": "consumer"
  }'
```

## Step 3: Login and Get Tokens

### Producer Login

```bash
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "producer1",
    "password": "pass123"
  }'
```

Save the `access_token` from the response.

### Consumer Login

```bash
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "consumer1",
    "password": "pass123"
  }'
```

Save the `access_token` and `user_id` from the response.

## Step 4: Create Subscription

Subscribe consumer to producer (use consumer's token and producer's ID):

```bash
curl -X POST http://localhost:3002/api/subscribe \
  -H "Authorization: Bearer <CONSUMER_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "producer_id": 1
  }'
```

## Step 5: Test Data Flow

### Option A: Using IoT Plugin (Rust)

```bash
cd iot_plugin

# Configure
cp .env.example .env
# Edit .env with producer1 credentials

# Run
cargo run --release
```

### Option B: Using wscat (Quick Test)

```bash
# Install wscat
npm install -g wscat

# Connect as producer
wscat -c "ws://localhost:8001/producer?token=<PRODUCER_TOKEN>"

# Send data
> {"type":"data","payload":{"device_id":"rpi_001","temperature":24.3,"humidity":51}}

# You'll receive acknowledgment with transaction_id from blockchain
< {"type":"ack","subscriberCount":1,"transaction_id":"..."}
```

### Option C: Test Consumer

```bash
# Connect as consumer
wscat -c "ws://localhost:8002/consumer?token=<CONSUMER_TOKEN>"

# You'll receive data automatically from subscribed producers
```

## Step 6: Monitor

### Check Service Health

```bash
# Auth Service
curl http://localhost:3001/health

# Subscription Manager
curl http://localhost:3002/health

# Data Stream Manager
curl http://localhost:3003/health

# WSS1 Stats
curl http://localhost:3010/stats

# WSS2 Stats
curl http://localhost:3011/stats
```

### View Logs

```bash
# Service logs (from readme directory)
tail -f logs/Authentication\ Service\ \(ap\).log
tail -f logs/WebSocket\ Server\ 1\ \(wss1\).log

# Docker logs
cd readme
docker compose logs -f
```

## Complete Example Flow

```bash
# Navigate to readme repo
cd readme

# 1. Start everything
./start-all.sh

# 2. Register producer
PRODUCER_RESPONSE=$(curl -s -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"producer1","password":"pass123","role":"producer","device_id":"rpi_001"}')

# 3. Register consumer
CONSUMER_RESPONSE=$(curl -s -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"consumer1","password":"pass123","role":"consumer"}')

# 4. Login as producer
PRODUCER_LOGIN=$(curl -s -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"producer1","password":"pass123"}')

PRODUCER_TOKEN=$(echo $PRODUCER_LOGIN | jq -r '.access_token')
echo "Producer token: $PRODUCER_TOKEN"

# 5. Login as consumer
CONSUMER_LOGIN=$(curl -s -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"consumer1","password":"pass123"}')

CONSUMER_TOKEN=$(echo $CONSUMER_LOGIN | jq -r '.access_token')
echo "Consumer token: $CONSUMER_TOKEN"

# 6. Create subscription
curl -X POST http://localhost:3002/api/subscribe \
  -H "Authorization: Bearer $CONSUMER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"producer_id": 1}'

# 7. Test with IoT Plugin
cd ../DepinPlugin
cat > .env << EOF
DEVICE_ID=rpi_001
USERNAME=producer1
PASSWORD=pass123
AUTH_URL=http://localhost:3001/api/auth
WEBSOCKET_URL=ws://localhost:8001/producer
SEND_INTERVAL_SECS=1
RUST_LOG=info
EOF

cargo run --release
```

## Troubleshooting

### Services won't start

```bash
# Check if ports are already in use
lsof -i :3001
lsof -i :8001

# Check Docker
docker ps
docker-compose logs
```

### Database connection errors

```bash
# Navigate to readme repo
cd readme

# Restart infrastructure
docker compose down
docker compose up -d

# Wait for initialization
sleep 10
```

### WebSocket connection fails

```bash
# Verify token is valid
curl http://localhost:3001/api/auth/verify \
  -H "Authorization: Bearer <TOKEN>"

# Check WebSocket server
curl http://localhost:3010/health  # WSS1
curl http://localhost:3011/health  # WSS2
```

## Stopping Everything

```bash
# From readme directory
cd readme
./stop-all.sh
```

## Next Steps

- Read the main [README.md](README.md) for architecture details
- Check [ARCHITECTURE.md](ARCHITECTURE.md) for detailed system design
- Explore individual service repositories for specific documentation
- Configure production settings in `.env` files
- Review blockchain integration in [BlockchainHandler](https://github.com/Motience/BlockchainHandler)
- Set up monitoring and logging
- Deploy to production infrastructure

## Repository Links

All Motience repositories:
- **readme**: https://github.com/Motience/readme (Documentation & orchestration)
- **DepinPlugin**: https://github.com/Motience/DepinPlugin (IoT client)
- **AuthenticationPlatform**: https://github.com/Motience/AuthenticationPlatform
- **SubscriptionManager**: https://github.com/Motience/SubscriptionManager
- **DataStreamManager**: https://github.com/Motience/DataStreamManager
- **WebSocket-Server1**: https://github.com/Motience/WebSocket-Server1
- **Websocket-Server2**: https://github.com/Motience/Websocket-Server2
- **BlockchainHandler**: https://github.com/Motience/BlockchainHandler (Linera blockchain)

## Architecture Diagram

```
┌─────────────┐
│  IoT Device │
│  (Producer) │
└──────┬──────┘
       │ ① Authenticate
       ▼
┌─────────────────┐
│ Auth Service    │
│ (port 3001)     │
└─────────────────┘
       │ ② Get Token
       ▼
┌─────────────────┐
│ WebSocket       │
│ Server 1 (8001) │ ③ Send Data
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Data Stream     │
│ Manager (3003)  │ ④ Route Data
└────────┬────────┘
         │
         ▼
    ┌────────┐
    │ Redis  │ ⑤ Pub/Sub
    └────┬───┘
         │
         ▼
┌─────────────────┐
│ WebSocket       │
│ Server 2 (8002) │ ⑥ Stream to Consumer
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Consumer      │
│   Application   │
└─────────────────┘
```

## Resources

- [Main Documentation](README.md)
- [API Documentation](docs/API.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
