# Booster Syndrome - Distributed Microservices Platform

A comprehensive multi-language microservices platform demonstrating distributed systems architecture with services written in Rust, Go, Ruby, Python, TypeScript, Elixir, and more.

## Architecture Overview

This platform implements a complete distributed system with:

- **API Gateway** (Go) - High-performance request routing
- **Auth Service** (Rust) - Secure authentication and JWT management
- **User Service** (TypeScript/Node.js) - User management and profiles
- **Analytics Service** (Python) - Data processing and ML pipelines
- **Notification Service** (Ruby) - Multi-channel notifications
- **Message Queue** (Go) - Event-driven communication
- **Cache Layer** (Redis) - Distributed caching
- **Search Service** (Elixir) - Full-text search capabilities
- **File Storage Service** (Rust) - Object storage management
- **Metrics & Monitoring** (Go) - Observability stack
- **Web Frontend** (React/TypeScript) - Modern SPA
- **Mobile API** (Go) - Mobile-optimized endpoints
- **Worker Pools** (Python) - Background job processing
- **Database Migrations** (Multiple) - Schema management
- **CI/CD Pipeline** (GitHub Actions) - Automated deployment

## Tech Stack

### Backend Services
- **Rust** - Auth, File Storage, WebSocket Server
- **Go** - API Gateway, Message Queue, Metrics
- **Python** - Analytics, ML Models, Workers
- **Ruby** - Notifications, Admin Panel
- **Node.js/TypeScript** - User Service, Real-time APIs
- **Elixir** - Search, Chat Service

### Frontend
- **React** - Web application
- **TypeScript** - Type-safe frontend
- **Next.js** - SSR capabilities
- **React Native** - Mobile apps

### Infrastructure
- **PostgreSQL** - Primary database
- **MongoDB** - Document store
- **Redis** - Cache and session store
- **RabbitMQ** - Message broker
- **Elasticsearch** - Search engine
- **Docker** - Containerization
- **Kubernetes** - Orchestration
- **Terraform** - Infrastructure as Code

## Project Structure

```
booster-syndrome/
├── services/
│   ├── auth-service/          # Rust - Authentication
│   ├── user-service/          # TypeScript - User management
│   ├── analytics-service/     # Python - Data analytics
│   ├── notification-service/  # Ruby - Notifications
│   ├── gateway/              # Go - API Gateway
│   ├── message-queue/        # Go - Event broker
│   ├── search-service/       # Elixir - Search engine
│   ├── file-service/         # Rust - File storage
│   ├── metrics-service/      # Go - Monitoring
│   └── chat-service/         # Elixir - Real-time chat
├── web/
│   ├── frontend/             # React app
│   ├── admin/                # Admin dashboard
│   └── mobile/               # React Native
├── workers/
│   ├── python-workers/       # Background jobs
│   └── ruby-workers/         # Scheduled tasks
├── shared/
│   ├── proto/                # Protobuf definitions
│   ├── types/                # Shared TypeScript types
│   └── libs/                 # Common libraries
├── infrastructure/
│   ├── docker/               # Dockerfiles
│   ├── kubernetes/           # K8s manifests
│   ├── terraform/            # IaC
│   └── monitoring/           # Grafana, Prometheus
├── scripts/
│   ├── setup/                # Setup scripts
│   ├── deploy/               # Deployment scripts
│   └── migrations/           # Database migrations
└── docs/                     # Documentation

```

## Getting Started

### Prerequisites
- Docker & Docker Compose
- Rust (1.70+)
- Go (1.21+)
- Node.js (18+)
- Python (3.11+)
- Ruby (3.2+)
- Elixir (1.15+)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/ikaydreams-dev/Booster-Syndrome.git
cd Booster-Syndrome
```

2. Run setup script:
```bash
./scripts/setup/install.sh
```

3. Start all services:
```bash
docker-compose up -d
```

## Development

Each service has its own README with specific instructions.

### Running Individual Services

```bash
# Auth Service (Rust)
cd services/auth-service && cargo run

# API Gateway (Go)
cd services/gateway && go run main.go

# User Service (TypeScript)
cd services/user-service && npm run dev

# Analytics Service (Python)
cd services/analytics-service && python -m uvicorn main:app --reload
```

## Testing

```bash
# Run all tests
./scripts/test-all.sh

# Test specific service
cd services/auth-service && cargo test
```

## Deployment

Supports deployment to:
- Docker Swarm
- Kubernetes
- AWS ECS
- Google Cloud Run

See `infrastructure/` for deployment configurations.

## Contributing

This project demonstrates advanced distributed systems patterns. Contributions welcome!

## License

MIT License - See LICENSE file for details

## Authors

Built by @ikaydreams-dev (ikaydreams108@gmail.com)

---

**Note**: This is a comprehensive demonstration project showcasing polyglot microservices architecture.
