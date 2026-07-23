#!/bin/bash

echo "Generating documentation..."

# Generate Rust docs
echo "Generating Rust documentation..."
cd services/auth-service && cargo doc --no-deps && cd ../..
cd services/file-service && cargo doc --no-deps && cd ../..

# Generate TypeScript docs
echo "Generating TypeScript documentation..."
cd services/user-service && npx typedoc --out docs src && cd ../..

# Generate Python docs
echo "Generating Python documentation..."
cd services/analytics-service && pdoc --html -o docs app && cd ../..

echo "Documentation generation complete!"
