#!/bin/bash

# Test script to verify yads version command works
set -euo pipefail

echo "Testing YADS version command..."

# Test if yads script exists
if [[ ! -f "yads" ]]; then
    echo "ERROR: yads script not found"
    exit 1
fi

# Test syntax
echo "Checking syntax..."
if ! bash -n yads; then
    echo "ERROR: Syntax error in yads script"
    exit 1
fi

# Test version command
echo "Testing version command..."
if bash yads --version; then
    echo "SUCCESS: yads --version works"
else
    echo "ERROR: yads --version failed"
    exit 1
fi

echo "All tests passed!"
