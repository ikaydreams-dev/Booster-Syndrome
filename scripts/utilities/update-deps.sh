#!/bin/bash

echo "Updating dependencies..."

# Update Rust deps
echo "Updating Rust dependencies..."
find . -name "Cargo.toml" -execdir cargo update \;

# Update Node deps
echo "Updating Node dependencies..."
find . -name "package.json" -execdir npm update \;

# Update Python deps
echo "Updating Python dependencies..."
find . -name "requirements.txt" -execdir pip install --upgrade -r requirements.txt \;

# Update Go deps
echo "Updating Go dependencies..."
find . -name "go.mod" -execdir go get -u ./... \;

echo "Dependencies updated!"
