#!/bin/bash

# Booster Syndrome Deployment Script
# Author: ikaydreams108@gmail.com

set -e

ENV=${1:-production}
VERSION=${2:-latest}

echo "🚀 Deploying Booster Syndrome to $ENV environment..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate environment
if [[ ! "$ENV" =~ ^(development|staging|production)$ ]]; then
    log_error "Invalid environment: $ENV"
    log_info "Usage: ./deploy.sh [development|staging|production] [version]"
    exit 1
fi

# Check prerequisites
command -v kubectl >/dev/null 2>&1 || { log_error "kubectl is required but not installed"; exit 1; }
command -v docker >/dev/null 2>&1 || { log_error "docker is required but not installed"; exit 1; }

log_info "Building Docker images..."

# Build all services
services=(
    "auth-service"
    "gateway"
    "user-service"
    "analytics-service"
    "notification-service"
    "file-service"
    "chat-service"
    "search-service"
    "metrics-service"
    "message-queue"
)

for service in "${services[@]}"; do
    log_info "Building $service:$VERSION..."
    docker build -t "boostersyndrome/$service:$VERSION" -f "infrastructure/docker/$service.Dockerfile" .

    if [ $? -eq 0 ]; then
        log_info "✓ $service built successfully"
    else
        log_error "✗ Failed to build $service"
        exit 1
    fi
done

# Push images to registry
log_info "Pushing images to registry..."
for service in "${services[@]}"; do
    docker push "boostersyndrome/$service:$VERSION"
done

# Apply Kubernetes manifests
log_info "Applying Kubernetes manifests..."
kubectl apply -f infrastructure/kubernetes/ -n $ENV

# Wait for rollout
log_info "Waiting for deployment rollout..."
for service in "${services[@]}"; do
    kubectl rollout status deployment/$service -n $ENV --timeout=5m
done

log_info "Running database migrations..."
kubectl run migration-job --image=boostersyndrome/auth-service:$VERSION \
    --restart=Never -n $ENV -- /app/run-migrations.sh

log_info "✅ Deployment complete!"
log_info "Check status: kubectl get pods -n $ENV"
