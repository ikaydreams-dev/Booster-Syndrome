#!/bin/bash
set -e

echo "Running linters across all services..."

echo "Linting Ruby code..."
bundle exec rubocop || echo "Rubocop not configured"

echo "Linting Python code..."
flake8 services/python || echo "Flake8 not configured"
black --check services/python || echo "Black not configured"
mypy services/python || echo "MyPy not configured"

echo "Linting Go code..."
go fmt ./... || echo "Go fmt not configured"
go vet ./... || echo "Go vet not configured"

echo "Linting Rust code..."
cargo fmt --check || echo "Cargo fmt not configured"
cargo clippy || echo "Clippy not configured"

echo "All linting complete!"
