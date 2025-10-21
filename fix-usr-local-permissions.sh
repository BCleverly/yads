#!/bin/bash

# Fix /usr/local permission issues for YADS
# This script resolves permission denied errors for /usr/local and VS Code Server

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
    log "${YELLOW}⚠️  Warning: $1${NC}"
}

error() {
    log "${RED}❌ Error: $1${NC}"
}

# Initialize colors
setup_colors

info "🔧 Fixing /usr/local permission issues for YADS..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
    exit 1
fi

# Fix /usr/local permissions
info "📁 Fixing /usr/local permissions..."
chown -R root:root /usr/local
chmod -R 755 /usr/local

# Ensure /usr/local/bin is in PATH and has proper permissions
info "🔗 Ensuring /usr/local/bin is accessible..."
chmod 755 /usr/local/bin
chown root:root /usr/local/bin

# Fix VS Code Server permissions
info "💻 Fixing VS Code Server permissions..."

# Create vscode user if it doesn't exist
if ! id vscode >/dev/null 2>&1; then
    useradd -r -s /bin/bash -d /home/vscode -m vscode
    success "Created vscode user"
fi

# Fix ownership of vscode user's home directory
chown -R vscode:vscode /home/vscode
chmod -R 755 /home/vscode

# Create VS Code Server configuration directory with proper permissions
info "📁 Creating VS Code Server configuration directory..."
mkdir -p /home/vscode/.config/code-server
chown -R vscode:vscode /home/vscode/.config

# Generate password and create config file with proper permissions
info "📝 Creating VS Code Server configuration..."
password=$(openssl rand -base64 32)

# Create config file as vscode user to avoid permission issues
sudo -u vscode tee /home/vscode/.config/code-server/config.yaml > /dev/null << EOF
bind-addr: 0.0.0.0:8080
auth: password
password: $password
cert: false
EOF

# Set proper permissions
chown vscode:vscode /home/vscode/.config/code-server/config.yaml
chmod 600 /home/vscode/.config/code-server/config.yaml

# Fix Node.js and NVM permissions for vscode user
info "📦 Fixing Node.js permissions for vscode user..."

# Ensure vscode user has access to Node.js
if [[ -d "/home/vscode/.nvm" ]]; then
    chown -R vscode:vscode /home/vscode/.nvm
    chmod -R 755 /home/vscode/.nvm
fi

# Fix any global Node.js installations
if [[ -d "/usr/local/lib/node_modules" ]]; then
    chown -R root:root /usr/local/lib/node_modules
    chmod -R 755 /usr/local/lib/node_modules
fi

# Ensure code-server binary has proper permissions
if command -v code-server >/dev/null 2>&1; then
    info "🔧 Fixing code-server binary permissions..."
    code_server_path=$(which code-server)
    chown root:root "$code_server_path"
    chmod 755 "$code_server_path"
    success "code-server binary permissions fixed"
fi

# Start VS Code Server with proper user service
info "🚀 Starting VS Code Server..."
systemctl enable code-server@vscode
systemctl start code-server@vscode

# Check service status
info "📊 Checking VS Code Server status..."
sleep 3  # Give it a moment to start

if systemctl is-active --quiet code-server@vscode; then
    success "VS Code Server is running successfully!"
    info "Access VS Code Server at: http://localhost:8080"
    info "Password: $password"
    
    # Test that VS Code Server can access its configuration
    info "🧪 Testing VS Code Server configuration access..."
    if sudo -u vscode test -r /home/vscode/.config/code-server/config.yaml; then
        success "VS Code Server can read its configuration file"
    else
        warning "VS Code Server may have issues reading its configuration"
    fi
    
else
    error "VS Code Server failed to start"
    info "Check logs with: journalctl -u code-server@vscode -f"
    exit 1
fi

# Fix YADS script permissions
info "🔧 Fixing YADS script permissions..."
if [[ -f "/usr/local/bin/yads" ]]; then
    chown root:root /usr/local/bin/yads
    chmod 755 /usr/local/bin/yads
    success "YADS script permissions fixed"
fi

# Test YADS command
info "🧪 Testing YADS command..."
if command -v yads >/dev/null 2>&1; then
    success "YADS command is accessible"
    info "Testing YADS version..."
    yads --version || warning "YADS version check failed"
else
    warning "YADS command not found in PATH"
    info "You may need to run: source ~/.bashrc"
fi

success "🎉 /usr/local permission issues fixed!"
info "VS Code Server should now work properly"
info "Access: http://localhost:8080"
info "Password: $password"
