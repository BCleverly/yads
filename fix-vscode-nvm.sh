#!/bin/bash

# Fix NVM setup for vscode user
# This script resolves the NVM directory and command issues

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
    log "${RED}❌ $1${NC}"
}

# Initialize colors
setup_colors

info "🔧 Fixing NVM setup for vscode user..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
    exit 1
fi

# Ensure vscode user exists
if ! id "vscode" >/dev/null 2>&1; then
    error "vscode user does not exist. Run the main installation first."
    exit 1
fi

# Create vscode user's home directory if it doesn't exist
mkdir -p "/home/vscode"
chown -R "vscode:vscode" "/home/vscode"

# Remove any existing NVM directory that might be causing issues
info "🧹 Cleaning up existing NVM setup..."
rm -rf "/home/vscode/.nvm" 2>/dev/null || true

# Set up NVM properly for vscode user
info "📦 Setting up NVM for vscode user..."
sudo -u vscode bash -c '
    # Create NVM directory
    mkdir -p /home/vscode/.nvm
    
    # Install NVM
    export NVM_DIR="/home/vscode/.nvm"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    
    # Source NVM and install Node.js
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts || nvm install node
    nvm use --lts || nvm use node
    nvm alias default lts/* || nvm alias default node
'

# Verify NVM installation
info "🔍 Verifying NVM installation..."
if sudo -u vscode bash -c 'export NVM_DIR="/home/vscode/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; nvm --version' >/dev/null 2>&1; then
    success "NVM is working for vscode user"
    
    # Show Node.js version
    local node_version
    node_version=$(sudo -u vscode bash -c 'export NVM_DIR="/home/vscode/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; node --version' 2>/dev/null || echo "Unknown")
    info "Node.js version: $node_version"
else
    warning "NVM setup had issues, but VS Code Server should still work"
fi

# Test VS Code Server extensions installation
info "🧪 Testing VS Code Server extensions installation..."
sudo -u vscode bash -c '
    export NVM_DIR="/home/vscode/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    code-server --install-extension ms-vscode.vscode-json
' && success "Extensions installation test passed" || warning "Extensions installation had issues"

success "🎉 NVM setup for vscode user completed!"
info "VS Code Server should now work without Node.js module errors."
