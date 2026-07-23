#!/bin/bash

echo "Checking service ports..."

PORTS=(8000 8001 8002 8003 8004 8005 8006 8007 9090 5432 27017 6379 5672 9200)

for port in "${PORTS[@]}"; do
  if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
    echo "Port $port: IN USE"
  else
    echo "Port $port: Available"
  fi
done
