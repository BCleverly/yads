#!/bin/bash

# Quick Fix Script for YADS Line Ending Issues
# Run this immediately after cloning to fix the "cannot execute" error

set -euo pipefail

echo "🔧 Quick Fix for YADS Line Ending Issues"
echo "======================================="
echo

# Check if we're in the right directory
if [[ ! -f "yads" ]] || [[ ! -d "modules" ]]; then
    echo "❌ Error: Please run this script from the YADS repository directory"
    exit 1
fi

echo "🔍 Fixing line endings for all scripts..."

# Fix all shell scripts and the main yads script
find . -name "*.sh" -o -name "yads" | while read -r file; do
    if [[ -f "$file" ]]; then
        echo "  Fixing: $file"
        
        # Fix line endings (CRLF to LF)
        if command -v dos2unix >/dev/null 2>&1; then
            dos2unix "$file" 2>/dev/null || true
        else
            sed -i 's/\r$//' "$file" 2>/dev/null || true
        fi
        
        # Make executable
        chmod +x "$file"
    fi
done

echo
echo "✅ Line endings fixed!"
echo

# Test the yads script
echo "🧪 Testing yads script..."
if [[ -f "yads" ]]; then
    # Check if it's executable
    if [[ -x "yads" ]]; then
        echo "✅ yads is executable"
    else
        echo "⚠️  Making yads executable..."
        chmod +x yads
    fi
    
    # Check shebang
    first_line=$(head -n1 yads)
    if [[ "$first_line" == "#!/bin/bash" ]]; then
        echo "✅ yads shebang is correct"
    else
        echo "⚠️  yads shebang: $first_line"
    fi
    
    # Test syntax
    if bash -n yads 2>/dev/null; then
        echo "✅ yads script syntax is valid"
    else
        echo "❌ yads script has syntax errors"
    fi
fi

echo
echo "🎉 Quick fix completed!"
echo
echo "Next steps:"
echo "1. Test: ./yads --version"
echo "2. If working, run: sudo ./install.sh"
echo "3. If still issues, run: ./diagnose-installation.sh"
echo
