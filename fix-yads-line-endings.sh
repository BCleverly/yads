#!/bin/bash

# Fix line endings in yads script
echo "Fixing line endings in yads script..."

# Create a temporary file with proper line endings
tr -d '\r' < yads > yads.tmp

# Replace the original file
mv yads.tmp yads

# Make it executable
chmod +x yads

echo "Line endings fixed!"
echo "Testing syntax..."

if bash -n yads; then
    echo "SUCCESS: Syntax is now correct"
    echo "Testing version command..."
    if bash yads --version; then
        echo "SUCCESS: yads --version now works"
    else
        echo "ERROR: yads --version still fails"
        exit 1
    fi
else
    echo "ERROR: Still has syntax issues"
    exit 1
fi

echo "All tests passed!"
