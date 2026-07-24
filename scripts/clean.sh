#!/bin/bash

echo "Cleaning build artifacts..."

rm -rf node_modules dist build target
rm -rf __pycache__ *.pyc .pytest_cache
rm -rf vendor .bundle
rm -rf coverage htmlcov
rm -f *.log

echo "Clean complete!"
