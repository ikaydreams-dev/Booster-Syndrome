.PHONY: help install build test clean deploy

help:
	@echo "Booster Syndrome - Available commands:"
	@echo "  make install   - Install all dependencies"
	@echo "  make build     - Build all services"
	@echo "  make test      - Run all tests"
	@echo "  make dev       - Start development environment"
	@echo "  make deploy    - Deploy to production"
	@echo "  make clean     - Clean build artifacts"

install:
	@echo "Installing dependencies..."
	@./scripts/setup/install.sh

build:
	@echo "Building all services..."
	@docker-compose build

test:
	@echo "Running tests..."
	@cd services/auth-service && cargo test
	@cd services/gateway && go test ./...
	@cd services/user-service && npm test

dev:
	@echo "Starting development environment..."
	@docker-compose up

deploy:
	@echo "Deploying..."
	@./scripts/deploy/deploy.sh production

clean:
	@echo "Cleaning..."
	@docker-compose down -v
	@find . -name "target" -type d -exec rm -rf {} +
	@find . -name "node_modules" -type d -exec rm -rf {} +
	@find . -name "dist" -type d -exec rm -rf {} +
