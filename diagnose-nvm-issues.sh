#!/bin/bash

# Diagnose NVM and .npmrc configuration issues
# This script helps identify what's causing the NVM warnings

set -euo pipefail

# Color setup
setup_colors() {
    if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;94m'
        CYAN='\033[0;96m'
        WHITE='\033[1;37m'
        GRAY='\033[0;37m'
        NC='\033[0m'
    else
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        CYAN=''
        WHITE=''
        GRAY=''
        NC=''
    fi
}

# Logging functions
log() {
    echo -e "$1" >&2
}

info() {
    log "${BLUE}ℹ️  $1${NC}"
}

success() {
    log "${GREEN}✅ $1${NC}"
}

warning() {
    log "${YELLOW}⚠️  $1${NC}"
}

error() {
    log "${RED}❌ Error: $1${NC}"
}

# Initialize colors
setup_colors

info "🔍 Diagnosing NVM and .npmrc configuration issues..."

echo
info "👤 User Information:"
echo "  User: $(whoami)"
echo "  Home: $HOME"
echo "  Shell: $SHELL"

echo
info "📝 Checking .npmrc file..."
npmrc_file="$HOME/.npmrc"
if [[ -f "$npmrc_file" ]]; then
    success ".npmrc file exists: $npmrc_file"
    echo "  Content:"
    cat "$npmrc_file" | sed 's/^/    /'
    
    # Check for problematic settings
    if grep -q "globalconfig" "$npmrc_file"; then
        error "Found 'globalconfig' setting in .npmrc (conflicts with NVM)"
    fi
    
    if grep -q "^prefix" "$npmrc_file"; then
        error "Found 'prefix' setting in .npmrc (conflicts with NVM)"
    fi
else
    info "No .npmrc file found"
fi

echo
info "🔄 Checking NVM installation..."
if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    success "NVM found: $HOME/.nvm/nvm.sh"
    
    # Source NVM
    export NVM_DIR="$HOME/.nvm"
    source "$NVM_DIR/nvm.sh"
    
    echo "  NVM version: $(nvm --version)"
    echo "  Current Node: $(nvm current)"
    echo "  Installed versions:"
    nvm list | sed 's/^/    /'
    
    # Check for prefix issues
    echo
    info "🔍 Checking for prefix issues..."
    if nvm current | grep -q "system"; then
        warning "Using system Node.js (may cause conflicts)"
    fi
    
    # Test npm configuration
    if command -v npm >/dev/null 2>&1; then
        echo "  npm version: $(npm --version)"
        echo "  npm prefix: $(npm config get prefix 2>/dev/null || echo 'not set')"
        echo "  npm globalconfig: $(npm config get globalconfig 2>/dev/null || echo 'not set')"
    fi
    
else
    error "NVM not found in $HOME/.nvm/nvm.sh"
fi

echo
info "📦 Checking Node.js and npm..."
if command -v node >/dev/null 2>&1; then
    success "Node.js found: $(which node)"
    echo "  Version: $(node --version)"
else
    error "Node.js not found"
fi

if command -v npm >/dev/null 2>&1; then
    success "npm found: $(which npm)"
    echo "  Version: $(npm --version)"
else
    error "npm not found"
fi

echo
info "🔧 Checking shell configuration..."
shell_configs=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
for config in "${shell_configs[@]}"; do
    if [[ -f "$config" ]]; then
        echo "  $config exists"
        if grep -q "NVM_DIR" "$config"; then
            success "  Contains NVM configuration"
        else
            warning "  Missing NVM configuration"
        fi
    fi
done

echo
info "📊 Summary:"
echo "If you see any errors or warnings above, run:"
echo "  ./fix-nvm-npmrc-conflicts.sh"
echo
echo "This will:"
echo "  - Remove conflicting .npmrc settings"
echo "  - Clear NVM prefix issues"
echo "  - Set up proper Node.js/npm configuration"
