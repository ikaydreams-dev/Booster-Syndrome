#!/bin/bash

echo "Cleaning build artifacts..."

# Clean Rust
find . -type d -name "target" -exec rm -rf {} + 2>/dev/null || true

# Clean Node
find . -type d -name "node_modules" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "dist" -exec rm -rf {} + 2>/dev/null || true

# Clean Python
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true

# Clean logs
find . -type f -name "*.log" -delete 2>/dev/null || true

echo "Clean complete!"
