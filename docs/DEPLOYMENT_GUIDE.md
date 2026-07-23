# Deployment Guide

## Local Development
```bash
docker-compose -f docker-compose.dev.yml up
```

## Production Deployment
```bash
./scripts/deploy.sh production
```

## Configuration
Edit `.env` files for each environment.

## Monitoring
- Prometheus: :9090
- Grafana: :3003
