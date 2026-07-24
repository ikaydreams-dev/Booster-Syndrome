#!/bin/bash
set -e

echo "Deploying Booster Syndrome..."

echo "Building Docker images..."
docker-compose build

echo "Starting services..."
docker-compose up -d

echo "Checking health..."
sleep 5
docker-compose ps

echo "Deployment complete!"
echo "Services available at http://localhost:3000"
