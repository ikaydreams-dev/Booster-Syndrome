# API Gateway

Go-based API gateway for routing requests to microservices.

## Features

- Request routing
- Rate limiting
- CORS handling
- Logging
- Metrics collection
- Service discovery

## Tech Stack

- Go
- Gin web framework
- Redis for caching
- Prometheus for metrics

## Running

```bash
# Install dependencies
go mod download

# Start server
go run main.go
```

## Routes

- `/api/v1/auth/*` - Auth service
- `/api/v1/users/*` - User service
- `/api/v1/analytics/*` - Analytics service
- `/health` - Health check

## Environment Variables

See `.env.example` for configuration.
