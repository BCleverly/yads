#!/bin/bash

# Fix VS Code Server permissions for vscode user
# This script resolves the permission denied error for config files

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

info "🔧 Fixing VS Code Server permissions..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
    exit 1
fi

# Fix ownership of vscode user's home directory
info "👤 Fixing ownership of vscode user's home directory..."
chown -R "vscode:vscode" "/home/vscode"

# Create VS Code Server configuration directory with proper permissions
info "📁 Creating VS Code Server configuration directory..."
mkdir -p "/home/vscode/.config/code-server"
chown -R "vscode:vscode" "/home/vscode/.config"

# Generate password and create config file with proper permissions
info "📝 Creating VS Code Server configuration..."
local password
password=$(openssl rand -base64 32)

# Create config file as vscode user
sudo -u vscode tee "/home/vscode/.config/code-server/config.yaml" > /dev/null << EOF
bind-addr: 0.0.0.0:8080
auth: password
password: $password
cert: false
EOF

# Set proper permissions
chown "vscode:vscode" "/home/vscode/.config/code-server/config.yaml"
chmod 600 "/home/vscode/.config/code-server/config.yaml"

# Start VS Code Server with official user service
info "🚀 Starting VS Code Server..."
systemctl enable "code-server@vscode"
systemctl start "code-server@vscode"

# Check service status
info "📊 Checking VS Code Server status..."
sleep 3  # Give it a moment to start

if systemctl is-active --quiet "code-server@vscode"; then
    success "VS Code Server is running successfully!"
    info "Access VS Code Server at: http://localhost:8080"
    info "Password: $password"
    
    # Test extensions installation
    info "🧪 Testing extensions installation..."
    sudo -u vscode bash -c '
        export NVM_DIR="/home/vscode/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        code-server --install-extension ms-vscode.vscode-json
    ' && success "Extensions installation working!" || warning "Extensions installation had issues"
    
else
    error "VS Code Server failed to start"
    info "Check logs with: journalctl -u code-server@vscode -f"
    exit 1
fi

success "🎉 VS Code Server permissions fixed and service started!"
info "You can now access VS Code Server at http://localhost:8080"
