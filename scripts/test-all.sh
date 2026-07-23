#!/bin/bash

set -e

echo "Running all tests..."

echo "Testing Rust services..."
cd services/auth-service && cargo test && cd ../..
cd services/file-service && cargo test && cd ../..

echo "Testing Go services..."
cd services/gateway && go test ./... && cd ../..
cd services/message-queue && go test ./... && cd ../..

echo "Testing TypeScript services..."
cd services/user-service && npm test && cd ../..

echo "Testing Python services..."
cd services/analytics-service && pytest && cd ../..

echo "Testing frontend..."
cd web/frontend && npm test && cd ../..

echo "All tests passed!"
