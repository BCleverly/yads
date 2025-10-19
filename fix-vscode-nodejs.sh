#!/bin/bash

# Fix VS Code Server Node.js environment issues
# This script resolves the "Cannot find module '/usr/local'" error

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

info "🔧 Fixing VS Code Server Node.js environment issues..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
    exit 1
fi

# Stop VS Code Server if running
info "🛑 Stopping VS Code Server..."
systemctl stop vscode-server 2>/dev/null || true

# Create wrapper script for VS Code Server
info "📝 Creating VS Code Server wrapper script..."
cat > /usr/local/bin/vscode-server-wrapper << 'EOF'
#!/bin/bash
# VS Code Server wrapper script with proper Node.js environment

export NVM_DIR="/opt/vscode-server/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Start VS Code Server with proper environment
exec /usr/local/bin/code-server "$@"
EOF

chmod +x /usr/local/bin/vscode-server-wrapper

# Update systemd service to use wrapper
info "🔧 Updating VS Code Server systemd service..."
cat > /etc/systemd/system/vscode-server.service << 'EOF'
[Unit]
Description=VS Code Server
After=network.target

[Service]
Type=simple
User=vscode
WorkingDirectory=/opt/vscode-server
ExecStart=/usr/local/bin/vscode-server-wrapper --bind-addr 0.0.0.0:8080 --auth password
Restart=always
RestartSec=10
Environment=PASSWORD_FILE=/opt/vscode-server/.password

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and restart service
info "🔄 Reloading systemd and restarting VS Code Server..."
systemctl daemon-reload
systemctl enable vscode-server
systemctl start vscode-server

# Check service status
info "📊 Checking VS Code Server status..."
if systemctl is-active --quiet vscode-server; then
    success "VS Code Server is running successfully!"
    info "Access VS Code Server at: http://localhost:8080"
    
    # Show password
    if [[ -f "/opt/vscode-server/.password" ]]; then
        local password=$(cat /opt/vscode-server/.password)
        info "Password: $password"
    fi
else
    error "VS Code Server failed to start"
    info "Check logs with: journalctl -u vscode-server -f"
    exit 1
fi

success "🎉 VS Code Server Node.js environment fixed!"
