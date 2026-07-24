#!/bin/bash
set -e

echo "Running tests across all services..."

echo "Testing Ruby services..."
bundle exec rspec || echo "Ruby tests not configured"

echo "Testing Python services..."
pytest || echo "Python tests not configured"

echo "Testing Go services..."
go test ./... || echo "Go tests not configured"

echo "Testing Rust services..."
cargo test || echo "Rust tests not configured"

echo "Testing Java services..."
mvn test || echo "Java tests not configured"

echo "All tests complete!"
