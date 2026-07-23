#!/bin/bash

set -e

ENV=${1:-staging}

echo "Deploying to $ENV environment..."

# Build all services
echo "Building services..."
docker-compose build

# Tag images
echo "Tagging images..."
docker tag booster/gateway:latest booster/gateway:$ENV
docker tag booster/auth-service:latest booster/auth-service:$ENV

# Push to registry
echo "Pushing to registry..."
docker push booster/gateway:$ENV
docker push booster/auth-service:$ENV

# Apply Kubernetes configurations
echo "Deploying to Kubernetes..."
kubectl apply -f infrastructure/kubernetes/namespace.yaml
kubectl apply -f infrastructure/kubernetes/deployment.yaml

echo "Deployment to $ENV complete!"
