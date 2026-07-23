#!/bin/bash

# Health Check Script for All Services
# Author: ikaydreams108@gmail.com

set -e

SERVICES=(
    "auth-service:3000"
    "user-service:3001"
    "analytics-service:8001"
    "gateway:8080"
    "notification-service:4001"
    "file-service:5000"
    "chat-service:4000"
    "search-service:8002"
    "metrics-service:9090"
    "message-queue:5672"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🏥 Running health checks..."
echo "================================"

FAILED=0
PASSED=0

for service_port in "${SERVICES[@]}"; do
    IFS=':' read -r service port <<< "$service_port"

    echo -n "Checking $service (port $port)... "

    # Try HTTP health endpoint
    if curl -sf "http://localhost:$port/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ HEALTHY${NC}"
        ((PASSED++))
    elif curl -sf "http://localhost:$port" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠ REACHABLE (no health endpoint)${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ DOWN${NC}"
        ((FAILED++))
    fi
done

echo "================================"
echo "Summary: $PASSED passed, $FAILED failed"

# Check database connectivity
echo ""
echo "🗄️  Database connectivity..."

# PostgreSQL
if pg_isready -h localhost -p 5432 > /dev/null 2>&1; then
    echo -e "PostgreSQL: ${GREEN}✓${NC}"
else
    echo -e "PostgreSQL: ${RED}✗${NC}"
    ((FAILED++))
fi

# MongoDB
if mongosh --host localhost:27017 --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
    echo -e "MongoDB: ${GREEN}✓${NC}"
else
    echo -e "MongoDB: ${RED}✗${NC}"
    ((FAILED++))
fi

# Redis
if redis-cli ping > /dev/null 2>&1; then
    echo -e "Redis: ${GREEN}✓${NC}"
else
    echo -e "Redis: ${RED}✗${NC}"
    ((FAILED++))
fi

# RabbitMQ
if curl -sf http://localhost:15672/api/overview > /dev/null 2>&1; then
    echo -e "RabbitMQ: ${GREEN}✓${NC}"
else
    echo -e "RabbitMQ: ${RED}✗${NC}"
    ((FAILED++))
fi

echo ""
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All systems operational${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAILED component(s) down${NC}"
    exit 1
fi
