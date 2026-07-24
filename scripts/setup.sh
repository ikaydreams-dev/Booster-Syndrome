#!/bin/bash
set -e

echo "Setting up Booster Syndrome..."

echo "Installing dependencies..."
npm install || true
bundle install || true
pip install -r requirements.txt || true
cargo build || true
go mod download || true

echo "Setting up database..."
docker-compose up -d postgres redis mongodb

echo "Setup complete!"
