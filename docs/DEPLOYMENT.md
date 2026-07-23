# Deployment Guide

## Prerequisites

- Docker & Docker Compose
- Kubernetes cluster (for production)
- AWS account (optional, for cloud deployment)
- Terraform (for infrastructure)

## Local Development

### Using Docker Compose

```bash
# Install dependencies
make install

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Individual Services

#### Auth Service (Rust)
```bash
cd services/auth-service
cargo run
```

#### User Service (TypeScript)
```bash
cd services/user-service
npm install
npm run dev
```

#### Analytics Service (Python)
```bash
cd services/analytics-service
pip install -r requirements.txt
python -m uvicorn main:app --reload
```

## Production Deployment

### Using Kubernetes

1. Create namespace:
```bash
kubectl apply -f infrastructure/kubernetes/namespace.yaml
```

2. Deploy services:
```bash
kubectl apply -f infrastructure/kubernetes/deployment.yaml
```

3. Verify deployment:
```bash
kubectl get pods -n booster-syndrome
```

### Using Terraform

1. Initialize Terraform:
```bash
cd infrastructure/terraform
terraform init
```

2. Plan deployment:
```bash
terraform plan
```

3. Apply changes:
```bash
terraform apply
```

### Using AWS ECS

1. Build and push images:
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

docker build -t booster/gateway services/gateway
docker tag booster/gateway:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/booster/gateway:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/booster/gateway:latest
```

2. Create ECS task definitions and services via AWS Console or CLI

## Environment Variables

### Required Variables

```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/db
MONGODB_URI=mongodb://host:27017/db

# Redis
REDIS_URL=redis://host:6379

# Secrets
JWT_SECRET=your-secret-key

# Services
AUTH_SERVICE_URL=http://auth-service:8001
USER_SERVICE_URL=http://user-service:8002
```

## Monitoring

### Health Checks

All services expose `/health` endpoint:
```bash
curl http://localhost:8000/health
```

### Logs

View service logs:
```bash
# Docker Compose
docker-compose logs -f service-name

# Kubernetes
kubectl logs -f deployment/gateway-deployment -n booster-syndrome
```

## Scaling

### Horizontal Scaling

```bash
# Kubernetes
kubectl scale deployment gateway-deployment --replicas=5 -n booster-syndrome

# Docker Compose
docker-compose up -d --scale gateway=3
```

## Rollback

### Kubernetes

```bash
kubectl rollout undo deployment/gateway-deployment -n booster-syndrome
```

### Docker Compose

```bash
docker-compose down
git checkout previous-version
docker-compose up -d
```

## Backup

### Database Backups

```bash
# PostgreSQL
pg_dump -h localhost -U postgres booster_db > backup.sql

# MongoDB
mongodump --uri="mongodb://localhost:27017/user_db" --out=backup/
```

## Security

- Use secrets management (AWS Secrets Manager, Kubernetes Secrets)
- Enable TLS/SSL for all services
- Rotate credentials regularly
- Use IAM roles for AWS resources
- Enable firewall rules
