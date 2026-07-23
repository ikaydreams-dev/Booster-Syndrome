#!/bin/bash

set -e

echo "Running performance benchmarks..."

echo "Benchmarking API Gateway..."
ab -n 1000 -c 10 http://localhost:8000/health

echo "Benchmarking Auth Service..."
ab -n 500 -c 5 http://localhost:8001/health

echo "Benchmarking User Service..."
ab -n 500 -c 5 http://localhost:8002/health

echo "Benchmarks complete!"
