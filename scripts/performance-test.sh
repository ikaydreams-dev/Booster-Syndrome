#!/bin/bash

# Performance Testing Script using Apache Bench
# Author: ikaydreams108@gmail.com

set -e

HOST=${1:-http://localhost:8080}
CONCURRENT=${2:-50}
REQUESTS=${3:-1000}

echo "⚡ Running performance tests..."
echo "Target: $HOST"
echo "Concurrent requests: $CONCURRENT"
echo "Total requests: $REQUESTS"
echo "================================"

# Check if ab (Apache Bench) is installed
if ! command -v ab &> /dev/null; then
    echo "Error: Apache Bench (ab) is not installed"
    echo "Install with: sudo apt-get install apache2-utils (Linux)"
    echo "or: brew install apache2 (macOS)"
    exit 1
fi

# Test endpoints
endpoints=(
    "/health"
    "/api/v1/users"
    "/api/auth/login"
)

for endpoint in "${endpoints[@]}"; do
    echo ""
    echo "Testing: $HOST$endpoint"
    echo "--------------------------------"

    ab -n $REQUESTS -c $CONCURRENT -g "results_${endpoint//\//_}.tsv" \
        "$HOST$endpoint" 2>&1 | grep -E "(Requests per second|Time per request|Transfer rate)"

    if [ $? -eq 0 ]; then
        echo "✓ Test completed"
    else
        echo "✗ Test failed"
    fi
done

echo ""
echo "================================"
echo "✅ Performance tests complete"
echo "Results saved in results_*.tsv files"
