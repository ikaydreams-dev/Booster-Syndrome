# Go Services

High-performance Go microservices.

## Services

- **networking.go** - TCP/UDP servers, HTTP client, WebSocket, load balancer
- **microservices.go** - Service registry, API gateway, event bus
- **grpc_service.go** - gRPC with interceptors and circuit breakers
- **distributed_cache.go** - Consistent hashing, LRU cache, Bloom filter

## Setup

```bash
go mod download
go build ./...
go test ./...
```
