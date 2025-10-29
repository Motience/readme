# Motience - DePin Data Streaming Platform

A B2B SaaS platform for Decentralized Physical Infrastructure Networks (DePin) data streaming. The system connects IoT data producers and data consumers through a secure, real-time WebSocket infrastructure.

## 🏗️ Architecture Overview

```
IoT Devices (Producers) → wss1 → Data Stream Manager → Redis Pub/Sub → wss2 → Consumers
                            ↓                                              ↓
                     Authentication Service                    Subscription Manager
                            ↓                                              ↓
                        PostgreSQL                                   PostgreSQL
```

## 📦 Microservices

### 1. **ap** - Authentication Service
- **Tech**: Node.js + Express + PostgreSQL
- **Port**: 3001
- **Purpose**: User registration, authentication, JWT token issuance
- **Endpoints**:
  - `POST /register` - Register new user/device
  - `POST /login` - Login and get tokens
  - `GET /producers` - List all producers
  - `GET /consumers` - List all consumers
  - `POST /refresh` - Refresh access token

### 2. **sm** - Subscription Manager
- **Tech**: Node.js + Express + PostgreSQL
- **Port**: 3002
- **Purpose**: Manage consumer subscriptions to producers
- **Endpoints**:
  - `POST /subscribe` - Subscribe to a producer
  - `DELETE /unsubscribe` - Unsubscribe from a producer
  - `GET /subscriptions/:consumerId` - Get subscriptions for a consumer
  - `GET /subscribers/:producerId` - Get subscribers for a producer

### 3. **dsm** - Data Stream Manager
- **Tech**: Node.js + Redis Pub/Sub
- **Port**: 3003
- **Purpose**: Core routing logic, receives data from wss1 and broadcasts via Redis
- **Features**:
  - Receives data from producers
  - Checks subscription mappings
  - Publishes to Redis channels
  - Optional data persistence

### 4. **wss1** - WebSocket Server for Producers
- **Tech**: Node.js + ws
- **Port**: 8001
- **Endpoint**: `ws://localhost:8001/producer`
- **Purpose**: Accept connections from IoT devices, validate tokens, forward data to DSM

### 5. **wss2** - WebSocket Server for Consumers
- **Tech**: Node.js + ws + Redis
- **Port**: 8002
- **Endpoint**: `ws://localhost:8002/consumer`
- **Purpose**: Accept connections from consumers, subscribe to Redis channels, stream data

### 6. **iot_plugin** - IoT Device Client
- **Tech**: Rust
- **Purpose**: Runs on Raspberry Pi or edge devices
- **Features**:
  - Authentication with AP service
  - WebSocket connection to wss1
  - Continuous data streaming
  - Auto-reconnection logic

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- Rust 1.70+ (for iot_plugin)
- Docker & Docker Compose (for PostgreSQL and Redis)

### 1. Start Infrastructure
```bash
# Use docker compose (modern syntax)
docker compose up -d

# Or if you have standalone docker-compose installed
docker-compose up -d
```

### 2. Start All Services
```bash
# Terminal 1 - Authentication Service
cd ap
npm install
npm start

# Terminal 2 - Subscription Manager
cd sm
npm install
npm start

# Terminal 3 - Data Stream Manager
cd dsm
npm install
npm start

# Terminal 4 - WebSocket Server 1 (Producers)
cd wss1
npm install
npm start

# Terminal 5 - WebSocket Server 2 (Consumers)
cd wss2
npm install
npm start

# Terminal 6 - IoT Plugin (Producer)
cd iot_plugin
cargo build --release
cargo run
```

## 🔐 Authentication Flow

1. Producer/Consumer registers via `POST /register` on AP service
2. Login via `POST /login` to get `access_token` and `refresh_token`
3. Use `access_token` in WebSocket connection:
   ```
   ws://localhost:8001/producer?token=<access_token>
   ```

## 📊 Data Flow Example

### Producer sends data:
```json
{
  "device_id": "rpi_001",
  "timestamp": "2025-01-29T11:35:00Z",
  "data": {
    "temperature": 24.3,
    "humidity": 51,
    "pressure": 1013.25
  }
}
```

### Consumer receives:
```json
{
  "producer_id": "123",
  "device_id": "rpi_001",
  "timestamp": "2025-01-29T11:35:00Z",
  "data": {
    "temperature": 24.3,
    "humidity": 51,
    "pressure": 1013.25
  }
}
```

## 🗄️ Database Schema

### Users Table (PostgreSQL - AP service)
```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL, -- 'producer' or 'consumer'
  device_id VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Subscriptions Table (PostgreSQL - SM service)
```sql
CREATE TABLE subscriptions (
  id SERIAL PRIMARY KEY,
  consumer_id INTEGER NOT NULL,
  producer_id INTEGER NOT NULL,
  status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(consumer_id, producer_id)
);
```

## 🔧 Configuration

Each service uses environment variables. Create `.env` files in each service directory:

```env
# Common
NODE_ENV=development
JWT_SECRET=your-secret-key-here
JWT_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=7d

# PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_NAME=motience
DB_USER=postgres
DB_PASSWORD=postgres

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Service Ports
AP_PORT=3001
SM_PORT=3002
DSM_PORT=3003
WSS1_PORT=8001
WSS2_PORT=8002
```

## 📡 API Documentation

Full API documentation with interactive Swagger UI:
- **Authentication Service:** `http://localhost:3001/api-docs`
- **Subscription Manager:** `http://localhost:3002/api-docs`
- **Data Stream Manager:** `http://localhost:3003/api-docs`

## 🧪 WebSocket Testing UIs

Interactive web interfaces for testing WebSocket connections:
- **WSS1 (Producer Tester):** `http://localhost:3010`
  - Test producer WebSocket connections
  - Send data messages with custom JSON
  - Real-time logging and statistics
  
- **WSS2 (Consumer Tester):** `http://localhost:3011`
  - Test consumer WebSocket connections
  - View subscriptions and received data
  - Real-time data visualization

## 🧪 Testing

```bash
# Test Authentication
curl -X POST http://localhost:3001/register \
  -H "Content-Type: application/json" \
  -d '{"username":"producer1","password":"pass123","role":"producer","device_id":"rpi_001"}'

# Test WebSocket Producer (using wscat)
npm install -g wscat
wscat -c "ws://localhost:8001/producer?token=<your-token>"

# Test WebSocket Consumer
wscat -c "ws://localhost:8002/consumer?token=<your-token>"
```

## 📝 License

MIT

## 🤝 Contributing

Contributions welcome! Please read CONTRIBUTING.md for details.
