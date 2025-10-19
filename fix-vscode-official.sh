#!/bin/bash

# Fix VS Code Server to use official code-server installation approach
# This script resolves Node.js module loading issues by following official patterns

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

info "🔧 Fixing VS Code Server to use official code-server approach..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
    exit 1
fi

# Stop any existing VS Code Server services
info "🛑 Stopping existing VS Code Server services..."
systemctl stop vscode-server 2>/dev/null || true
systemctl stop "code-server@vscode" 2>/dev/null || true
systemctl disable vscode-server 2>/dev/null || true

# Remove old systemd service
info "🗑️  Removing old systemd service..."
rm -f /etc/systemd/system/vscode-server.service
systemctl daemon-reload

# Ensure vscode user exists and has proper home directory
info "👤 Setting up vscode user..."
if ! id "vscode" >/dev/null 2>&1; then
    useradd -r -s /bin/bash -d "/home/vscode" -m vscode
fi

# Create vscode user's home directory and config
mkdir -p "/home/vscode/.config"
chown -R "vscode:vscode" "/home/vscode"

# Set up NVM for vscode user in their home directory
info "📦 Setting up Node.js for vscode user..."
sudo -u vscode bash -c '
    export NVM_DIR="/home/vscode/.nvm"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts || nvm install node
    nvm use --lts || nvm use node
'

# Create VS Code Server configuration for vscode user
info "📝 Creating VS Code Server configuration..."
sudo -u vscode mkdir -p "/home/vscode/.config/code-server"

# Generate password for vscode user
local password
password=$(openssl rand -base64 32)
sudo -u vscode tee "/home/vscode/.config/code-server/config.yaml" > /dev/null << EOF
bind-addr: 0.0.0.0:8080
auth: password
password: $password
cert: false
EOF

chown "vscode:vscode" "/home/vscode/.config/code-server/config.yaml"
chmod 600 "/home/vscode/.config/code-server/config.yaml"

# Enable and start the official user service
info "🚀 Starting VS Code Server with official user service..."
systemctl enable "code-server@vscode"
systemctl start "code-server@vscode"

# Check service status
info "📊 Checking VS Code Server status..."
sleep 3  # Give it a moment to start

if systemctl is-active --quiet "code-server@vscode"; then
    success "VS Code Server is running successfully!"
    info "Access VS Code Server at: http://localhost:8080"
    info "Password: $password"
    
    # Install some basic extensions
    info "📦 Installing VS Code extensions..."
    sudo -u vscode bash -c "
        export NVM_DIR='/home/vscode/.nvm'
        [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"
        code-server --install-extension ms-vscode.vscode-json
        code-server --install-extension bradlc.vscode-tailwindcss
    " || warning "Extension installation had issues, but VS Code Server is working"
    
else
    error "VS Code Server failed to start"
    info "Check logs with: journalctl -u code-server@vscode -f"
    exit 1
fi

success "🎉 VS Code Server is now using the official code-server approach!"
info "This should resolve the Node.js module loading errors."
