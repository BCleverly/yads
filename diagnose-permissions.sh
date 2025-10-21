#!/bin/bash

# Diagnose permission issues for YADS
# This script helps identify what permission problems exist

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

info "🔍 Diagnosing YADS permission issues..."

echo
info "📁 Checking /usr/local permissions..."
if [[ -d "/usr/local" ]]; then
    ls -la /usr/local | head -5
    if [[ -w "/usr/local" ]]; then
        success "/usr/local is writable"
    else
        error "/usr/local is not writable"
    fi
else
    error "/usr/local directory does not exist"
fi

echo
info "🔗 Checking /usr/local/bin permissions..."
if [[ -d "/usr/local/bin" ]]; then
    ls -la /usr/local/bin | head -5
    if [[ -x "/usr/local/bin" ]]; then
        success "/usr/local/bin is executable"
    else
        error "/usr/local/bin is not executable"
    fi
else
    error "/usr/local/bin directory does not exist"
fi

echo
info "📦 Checking YADS installation..."
if command -v yads >/dev/null 2>&1; then
    success "YADS command found: $(which yads)"
    ls -la "$(which yads)"
else
    error "YADS command not found in PATH"
fi

echo
info "💻 Checking VS Code Server..."
if command -v code-server >/dev/null 2>&1; then
    success "VS Code Server found: $(which code-server)"
    ls -la "$(which code-server)"
else
    error "VS Code Server not found"
fi

echo
info "👤 Checking vscode user..."
if id vscode >/dev/null 2>&1; then
    success "vscode user exists"
    id vscode
else
    error "vscode user does not exist"
fi

echo
info "📁 Checking vscode user home directory..."
if [[ -d "/home/vscode" ]]; then
    ls -la /home/vscode
    if [[ -r "/home/vscode" ]]; then
        success "/home/vscode is readable"
    else
        error "/home/vscode is not readable"
    fi
else
    error "/home/vscode directory does not exist"
fi

echo
info "📝 Checking VS Code Server configuration..."
if [[ -f "/home/vscode/.config/code-server/config.yaml" ]]; then
    success "VS Code Server config file exists"
    ls -la /home/vscode/.config/code-server/config.yaml
    if sudo -u vscode test -r /home/vscode/.config/code-server/config.yaml 2>/dev/null; then
        success "vscode user can read config file"
    else
        error "vscode user cannot read config file"
    fi
else
    error "VS Code Server config file does not exist"
fi

echo
info "🔄 Checking VS Code Server service..."
if systemctl is-active --quiet code-server@vscode; then
    success "VS Code Server service is running"
else
    error "VS Code Server service is not running"
    info "Service status:"
    systemctl status code-server@vscode --no-pager -l
fi

echo
info "🌐 Testing VS Code Server access..."
if curl -s --connect-timeout 5 http://localhost:8080 >/dev/null 2>&1; then
    success "VS Code Server is accessible on localhost:8080"
else
    error "VS Code Server is not accessible on localhost:8080"
fi

echo
info "📊 Summary:"
echo "If you see any errors above, run: sudo ./fix-usr-local-permissions.sh"
echo "This will fix the permission issues and restart the services."
