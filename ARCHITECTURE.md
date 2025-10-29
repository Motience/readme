# Motience Platform Architecture

## Overview

Motience is a decentralized physical infrastructure network (DePin) platform for real-time IoT data streaming with subscription-based access control.

## System Architecture

<img width="1667" height="864" alt="Screenshot 2025-10-29 at 19 46 59" src="https://github.com/user-attachments/assets/1ef5a936-cb95-43dc-a55c-98280ad81c58" />

## Components

### 1. IoT Plugin (Rust)
**Repository:** https://github.com/Motience/DepinPlugin

- Runs on Raspberry Pi or IoT devices
- Collects system metrics (CPU, memory, temperature, etc.)
- WebSocket client connecting to WSS1
- JWT authentication
- Auto-reconnection with exponential backoff

### 2. Authentication Platform (AP)
**Repository:** https://github.com/Motience/AuthenticationPlatform
**Port:** 3001

- User registration and login
- JWT token generation (access + refresh tokens)
- Role-based access control (producer/consumer)
- Token verification for other services
- Swagger documentation at `/api-docs`

### 3. Subscription Manager (SM)
**Repository:** https://github.com/Motience/SubscriptionManager
**Port:** 3002

- Manage producer-consumer subscriptions
- Create/delete subscriptions
- Query subscribers by producer
- Query subscriptions by consumer
- Swagger documentation at `/api-docs`

### 4. Data Stream Manager (DSM)
**Repository:** https://github.com/Motience/DataStreamManager
**Port:** 3003

- Core data routing service
- Receives data from WSS1
- Queries SM for active subscribers
- Publishes to Redis Pub/Sub channels
- Optional data persistence
- Cache subscription data for performance
- Swagger documentation at `/api-docs`

### 5. WebSocket Server 1 (WSS1)
**Repository:** https://github.com/Motience/WebSocket-Server1
**Ports:** 8001 (WebSocket), 3010 (HTTP)

- Accepts producer connections
- Authenticates via AP service
- Receives IoT data
- Forwards to DSM
- Sends acknowledgments with subscriber count
- Interactive testing UI at http://localhost:3010

### 6. WebSocket Server 2 (WSS2)
**Repository:** https://github.com/Motience/Websocket-Server2
**Ports:** 8002 (WebSocket), 3011 (HTTP)

- Accepts consumer connections
- Authenticates via AP service
- Subscribes to Redis channels
- Delivers data based on subscriptions
- Interactive testing UI at http://localhost:3011

## Data Flow

### Producer → Consumer Flow

```
1. Producer authenticates with AP
   POST /api/auth/login → access_token

2. Producer connects to WSS1
   ws://localhost:8001/producer?token=xxx

3. Producer sends data
   { type: "data", payload: {...} }

4. WSS1 forwards to DSM
   POST /api/data

5. DSM queries SM for subscribers
   GET /api/subscribers/:producerId

6. DSM publishes to Redis
   PUBLISH consumer_X {...data...}

7. WSS2 receives from Redis
   Subscribed to consumer_X channel

8. WSS2 forwards to Consumer
   { type: "data", payload: {...} }

9. WSS1 sends acknowledgment to Producer
   { type: "ack", subscriberCount: 1 }
```

### Subscription Flow

```
1. Consumer authenticates with AP
   POST /api/auth/login → access_token

2. Consumer creates subscription
   POST /api/subscribe { producer_id: 1 }

3. Consumer connects to WSS2
   ws://localhost:8002/consumer?token=xxx

4. WSS2 queries SM for subscriptions
   GET /api/subscriptions/:consumerId

5. WSS2 subscribes to Redis channels
   SUBSCRIBE consumer_X

6. Data flows when producer sends
   (See Producer → Consumer Flow above)
```

## Technology Stack

### Backend Services
- **Node.js** with Express.js
- **PostgreSQL** for persistent storage
- **Redis** for Pub/Sub messaging
- **WebSocket** (ws library) for real-time communication

### IoT Client
- **Rust** with Tokio async runtime
- **tokio-tungstenite** for WebSocket
- **reqwest** for HTTP requests

### Documentation
- **Swagger/OpenAPI** for REST APIs
- **Interactive Web UIs** for WebSocket testing

### Infrastructure
- **Docker** for PostgreSQL and Redis
- **Docker Compose** for orchestration

## Security

### Authentication
- JWT-based authentication
- Access tokens (1 hour expiry)
- Refresh tokens (7 days expiry)
- bcrypt password hashing

### Authorization
- Role-based access control (producer/consumer)
- Token verification on all protected endpoints
- WebSocket authentication via query parameters

### API Security
- Helmet.js for HTTP headers
- CORS configuration
- Rate limiting
- Express validator for input validation

## Scalability Considerations

### Horizontal Scaling
- **WSS1/WSS2:** Multiple instances behind load balancer
- **DSM:** Stateless, can scale horizontally
- **AP/SM:** Database connection pooling

### Performance Optimization
- **DSM:** Subscription caching to reduce SM queries
- **Redis Pub/Sub:** Efficient message distribution
- **WebSocket:** Non-blocking I/O, concurrent connections
- **Connection pooling:** PostgreSQL

### High Availability
- **Redis:** Can use Redis Cluster or Sentinel
- **PostgreSQL:** Master-slave replication
- **Load balancing:** Distribute WebSocket connections

## Ports Reference

| Service | Port(s) | Description |
|---------|---------|-------------|
| PostgreSQL | 5432 | Database |
| Redis | 6379 | Pub/Sub |
| AP | 3001 | Authentication REST API + Swagger |
| SM | 3002 | Subscription REST API + Swagger |
| DSM | 3003 | Data Stream REST API + Swagger |
| WSS1 | 8001, 3010 | Producer WebSocket + HTTP UI |
| WSS2 | 8002, 3011 | Consumer WebSocket + HTTP UI |

## Repository Structure

```
Motience Platform (GitHub Organization)
├── DepinPlugin                    # IoT device client (Rust)
├── AuthenticationPlatform         # User authentication (Node.js)
├── SubscriptionManager            # Subscription management (Node.js)
├── DataStreamManager              # Data routing (Node.js)
├── WebSocket-Server1              # Producer WebSocket (Node.js)
├── Websocket-Server2              # Consumer WebSocket (Node.js)
└── readme                         # Platform documentation & scripts
```

## Development Setup

See `QUICK_START.md` for detailed setup instructions.

Quick commands:
```bash
# Start infrastructure
docker compose up -d

# Start all services
./start-all.sh

# Stop all services
./stop-all.sh
```

## API Documentation

All REST services include interactive Swagger documentation:
- **AP:** http://localhost:3001/api-docs
- **SM:** http://localhost:3002/api-docs
- **DSM:** http://localhost:3003/api-docs

## Testing UIs

Interactive WebSocket testing interfaces:
- **Producer UI:** http://localhost:3010
- **Consumer UI:** http://localhost:3011

## Future Enhancements

- [ ] Blockchain integration for micropayments
- [ ] Data encryption at rest
- [ ] Advanced analytics dashboard
- [ ] Mobile SDKs (iOS/Android)
- [ ] Multi-region deployment
- [ ] GraphQL API layer
- [ ] Real-time monitoring with Prometheus/Grafana
- [ ] Automated testing suite
- [ ] CI/CD pipeline
- [ ] Kubernetes deployment configurations
