#!/bin/bash

# Fix line endings in yads script
echo "Fixing line endings in yads script..."

# Read the file and convert CRLF to LF
tr -d '\r' < yads > yads.tmp
mv yads.tmp yads

echo "Line endings fixed!"
echo "Testing syntax..."

if bash -n yads; then
    echo "SUCCESS: Syntax is now correct"
else
    echo "ERROR: Still has syntax issues"
    exit 1
fi

echo "Testing version command..."
if bash yads --version; then
    echo "SUCCESS: yads --version now works"
else
    echo "ERROR: yads --version still fails"
    exit 1
fi
