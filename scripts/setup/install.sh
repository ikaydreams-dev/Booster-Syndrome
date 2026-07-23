#!/bin/bash

set -e

echo "Installing Booster Syndrome..."

# Check prerequisites
command -v docker >/dev/null 2>&1 || { echo "Docker is required but not installed. Aborting." >&2; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "Docker Compose is required but not installed. Aborting." >&2; exit 1; }

# Create environment file
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
fi

# Start infrastructure services
echo "Starting infrastructure services..."
docker-compose up -d postgres mongodb redis rabbitmq

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 10

# Build and start application services
echo "Building application services..."
docker-compose build

echo "Starting application services..."
docker-compose up -d

echo "Installation complete!"
echo "Access the application at http://localhost:3000"
echo "API Gateway: http://localhost:8000"
