# Motience - Agentic DePin DataFi Platform

Motience builds the infrastructure for Decentralized Physical Artificial Intelligence (DePAI), connecting real-world devices, robots, and sensors into an intelligent data network. It enables real-time data exchange between producers and consumers, powered by blockchain for traceability and monetization, and enhanced by agentic AI layers that transform raw signals into structured intelligence.

## 📚 Repository Overview

Motience platform consists of multiple specialized repositories:

| Repository | Description | Technology | Purpose |
|------------|-------------|------------|----------|
| [readme](https://github.com/Motience/readme) | Platform documentation, setup scripts & orchestration | Bash, Markdown | Central hub for documentation and deployment |
| [DepinPlugin](https://github.com/Motience/DepinPlugin) | IoT device client for data collection | Rust | Runs on edge devices (Raspberry Pi) to collect and stream sensor data |
| [AuthenticationPlatform](https://github.com/Motience/AuthenticationPlatform) | User authentication & authorization service | Node.js, Express, PostgreSQL | JWT-based auth, role management (producer/consumer) |
| [SubscriptionManager](https://github.com/Motience/SubscriptionManager) | Subscription management service | Node.js, Express, PostgreSQL | Manages producer-consumer subscription relationships |
| [DataStreamManager](https://github.com/Motience/DataStreamManager) | Core data routing & blockchain integration | Node.js, Redis | Routes data, interacts with blockchain for transparent record-keeping |
| [WebSocket-Server1](https://github.com/Motience/WebSocket-Server1) | Producer WebSocket server | Node.js, WebSocket | Accepts connections from IoT producers |
| [Websocket-Server2](https://github.com/Motience/Websocket-Server2) | Consumer WebSocket server | Node.js, WebSocket, Redis | Delivers data streams to consumers |
| [BlockchainHandler](https://github.com/Motience/BlockchainHandler) | Linera blockchain integration | Rust, Linera SDK | Records data transactions |

## 🏗️ Architecture Overview

```
IoT Devices (Producers) → wss1 → Data Stream Manager → Redis Pub/Sub → wss2 → Consumers
                            ↓              ↓                                   ↓
                     Authentication   Blockchain Handler          Subscription Manager
                         Service      (Linera Chain)                      ↓
                            ↓              ↓                          PostgreSQL
                        PostgreSQL   Transaction Records
                                     (Who→Who, Timestamp)
                                            ↓
                                  Decentralized File Storage
                                        (Raw Data)
```

## 🔗 Blockchain Integration

The **Linera blockchain** provides:
- **Transparent Records**: Immutable logs of who sends data to whom
- **Fair Monetization**: Stakeholder payment mechanisms
- **Timestamp Verification**: Accurate recording of data consumption events
- **Decentralized Storage**: Raw data stored in distributed file systems
- **API Integration**: Data Stream Manager calls BlockchainHandler APIs to record transactions

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

> **Note**: This repository (`readme`) contains documentation, Docker configurations, and orchestration scripts. Individual services are in separate repositories (see table above).

### Prerequisites
- Node.js 18+
- Rust 1.70+ (for IoT plugin and BlockchainHandler)
- Docker & Docker Compose
- Git (to clone service repositories)

### 1. Clone Repositories

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

### 2. Start Infrastructure

```bash
# Navigate to readme repository
cd readme

# Start PostgreSQL and Redis using Docker Compose
docker compose up -d
```

### 3. Start All Services

**Option A: Using the start script (from readme repo)**
```bash
cd readme
chmod +x start-all.sh
./start-all.sh
```

**Option B: Manual start**
```bash
# Terminal 1 - Authentication Service
cd AuthenticationPlatform
npm install
npm start

# Terminal 2 - Subscription Manager
cd SubscriptionManager
npm install
npm start

# Terminal 3 - Data Stream Manager
cd DataStreamManager
npm install
npm start

# Terminal 4 - WebSocket Server 1 (Producers)
cd WebSocket-Server1
npm install
npm start

# Terminal 5 - WebSocket Server 2 (Consumers)
cd Websocket-Server2
npm install
npm start

# Terminal 6 - Blockchain Handler
cd BlockchainHandler
cargo build --release
cargo run

# Terminal 7 - IoT Plugin (Producer)
cd DepinPlugin
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

## 📂 Repository Structure

```
motience-platform/
├── readme/                      # This repo - Documentation & orchestration
│   ├── README.md               # Platform overview (this file)
│   ├── ARCHITECTURE.md         # Detailed architecture
│   ├── QUICK_START.md          # Setup guide
│   ├── docker-compose.yml      # Infrastructure setup
│   ├── start-all.sh            # Start all services script
│   └── stop-all.sh             # Stop all services script
├── DepinPlugin/                # IoT device client (Rust)
├── AuthenticationPlatform/     # Auth service (Node.js)
├── SubscriptionManager/        # Subscription service (Node.js)
├── DataStreamManager/          # Data routing + blockchain calls (Node.js)
├── WebSocket-Server1/          # Producer WebSocket (Node.js)
├── Websocket-Server2/          # Consumer WebSocket (Node.js)
└── BlockchainHandler/          # Linera blockchain integration (Rust)
```

## 🔍 How Data Flows with Blockchain

1. **Producer sends data** → WSS1 → Data Stream Manager
2. **DSM records transaction** → Calls BlockchainHandler API
3. **Blockchain records**:
   - Who sent data (producer ID)
   - Who receives data (consumer IDs)
   - Timestamp of transaction
   - Data hash/reference
4. **Raw data stored** → Decentralized file storage
5. **Data delivered** → Redis → WSS2 → Consumer
6. **Monetization triggered** → Blockchain smart contracts calculate payments

## 📖 Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Detailed system architecture
- **[QUICK_START.md](QUICK_START.md)** - Step-by-step setup guide
- **API Docs** - Swagger UI at service endpoints (see below)

## 📝 License

MIT

## 🤝 Contributing

Contributions welcome! Please read CONTRIBUTING.md for details.
