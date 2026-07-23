# Metrics Service

Go service for collecting and exposing Prometheus metrics.

## Features

- Prometheus integration
- Request metrics
- Performance metrics
- Custom counters/gauges

## Tech Stack

- Go
- Prometheus client
- Gin

## Running

```bash
# Install dependencies
go mod download

# Run
go run main.go
```

## Endpoints

- GET `/metrics` - Prometheus metrics
- GET `/health` - Health check

## Metrics Collected

- `http_requests_total` - Total requests
- `http_request_duration_seconds` - Request duration
- `active_connections` - Active connections
