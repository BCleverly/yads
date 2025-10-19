#!/bin/bash

# YADS Tunnel Module
# Handles Cloudflared tunnel configuration

set -euo pipefail

# Color setup
setup_colors() {
    if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        CYAN='\033[0;36m'
        NC='\033[0m' # No Color
    else
        RED=''
        GREEN=''
        YELLOW=''
        NC=''
    fi
}

# Logging functions
log() {
    echo -e "$1" >&2
}

error_exit() {
    log "${RED}❌ Error: $1${NC}"
    exit 1
}

warning() {
    log "${YELLOW}⚠️  Warning: $1${NC}"
}

info() {
    log "${BLUE}ℹ️  $1${NC}"
}

success() {
    log "${GREEN}✅ $1${NC}"
}

# Check if cloudflared is installed
check_cloudflared() {
    if ! command -v cloudflared >/dev/null 2>&1; then
        error_exit "Cloudflared is not installed. Run 'yads install' first."
    fi
}

# Setup Cloudflared tunnel
setup_tunnel() {
    info "☁️  Setting up Cloudflared tunnel..."
    
    check_cloudflared
    
    # Create cloudflared directory
    mkdir -p /etc/cloudflared
    mkdir -p /var/log/cloudflared
    
    # Login to Cloudflare
    info "Please login to your Cloudflare account:"
    cloudflared tunnel login
    
    # Create tunnel
    local tunnel_name
    tunnel_name="${1:-yads-dev-server}"
    
    info "Creating tunnel: $tunnel_name"
    cloudflared tunnel create "$tunnel_name"
    
    # Get tunnel ID
    local tunnel_id
    tunnel_id=$(cloudflared tunnel list | grep "$tunnel_name" | awk '{print $1}')
    
    if [[ -z "$tunnel_id" ]]; then
        error_exit "Failed to get tunnel ID"
    fi
    
    # Create tunnel configuration
    cat > /etc/cloudflared/config.yml << EOF
tunnel: $tunnel_id
credentials-file: /root/.cloudflared/$tunnel_id.json

ingress:
  # VS Code Server
  - hostname: code.remote.domain.tld
    service: http://localhost:8080
    originRequest:
      noTLSVerify: true
  
  # Wildcard for projects
  - hostname: "*.remote.domain.tld"
    service: http://localhost:80
    originRequest:
      noTLSVerify: true
  
  # Catch-all rule
  - service: http_status:404
EOF
    
    # Create DNS records
    info "Creating DNS records..."
    cloudflared tunnel route dns "$tunnel_name" code.remote.domain.tld
    cloudflared tunnel route dns "$tunnel_name" "*.remote.domain.tld"
    
    # Create systemd service
    cat > /etc/systemd/system/cloudflared.service << EOF
[Unit]
Description=Cloudflared tunnel
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/cloudflared tunnel --config /etc/cloudflared/config.yml run
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # Start tunnel service
    systemctl daemon-reload
    systemctl enable cloudflared
    systemctl start cloudflared
    
    success "Cloudflared tunnel configured"
    info "Tunnel ID: $tunnel_id"
    info "VS Code Server: https://code.remote.domain.tld"
    info "Projects: https://*.remote.domain.tld"
}

# Show tunnel status
show_status() {
    info "☁️  Tunnel Status:"
    
    if systemctl is-active --quiet cloudflared; then
        success "Cloudflared tunnel: Running"
        
        # Show tunnel info
        if [[ -f "/etc/cloudflared/config.yml" ]]; then
            local tunnel_id
            tunnel_id=$(grep "tunnel:" /etc/cloudflared/config.yml | awk '{print $2}')
            info "Tunnel ID: $tunnel_id"
        fi
        
        # Show active tunnels
        info "Active tunnels:"
        cloudflared tunnel list
    else
        info "Cloudflared tunnel: Stopped"
    fi
}

# Start tunnel
start_tunnel() {
    info "🚀 Starting Cloudflared tunnel..."
    
    check_cloudflared
    
    if systemctl is-active --quiet cloudflared; then
        info "Tunnel is already running"
        return
    fi
    
    systemctl start cloudflared
    systemctl enable cloudflared
    
    success "Tunnel started"
}

# Stop tunnel
stop_tunnel() {
    info "🛑 Stopping Cloudflared tunnel..."
    
    if ! systemctl is-active --quiet cloudflared; then
        info "Tunnel is already stopped"
        return
    fi
    
    systemctl stop cloudflared
    systemctl disable cloudflared
    
    success "Tunnel stopped"
}

# Restart tunnel
restart_tunnel() {
    info "🔄 Restarting Cloudflared tunnel..."
    
    stop_tunnel
    start_tunnel
}

# Update tunnel configuration
update_config() {
    info "📝 Updating tunnel configuration..."
    
    if [[ ! -f "/etc/cloudflared/config.yml" ]]; then
        error_exit "Tunnel configuration not found. Run 'yads tunnel setup' first."
    fi
    
    # Backup current config
    cp /etc/cloudflared/config.yml /etc/cloudflared/config.yml.backup
    
    # Update configuration
    local domain
    domain="${1:-remote.domain.tld}"
    
    cat > /etc/cloudflared/config.yml << EOF
tunnel: $(grep "tunnel:" /etc/cloudflared/config.yml.backup | awk '{print $2}')
credentials-file: /root/.cloudflared/$(grep "tunnel:" /etc/cloudflared/config.yml.backup | awk '{print $2}').json

ingress:
  # VS Code Server
  - hostname: code.$domain
    service: http://localhost:8080
    originRequest:
      noTLSVerify: true
  
  # Wildcard for projects
  - hostname: "*.$domain"
    service: http://localhost:80
    originRequest:
      noTLSVerify: true
  
  # Catch-all rule
  - service: http_status:404
EOF
    
    # Restart tunnel
    restart_tunnel
    
    success "Tunnel configuration updated for domain: $domain"
}

# Main tunnel function
tunnel_main() {
    setup_colors
    
    case "${1:-}" in
        "")
            show_status
            info "Use 'yads tunnel setup' to configure tunnel"
            ;;
        setup)
            setup_tunnel "${2:-}"
            ;;
        start)
            start_tunnel
            ;;
        stop)
            stop_tunnel
            ;;
        restart)
            restart_tunnel
            ;;
        status)
            show_status
            ;;
        update)
            update_config "${2:-}"
            ;;
        *)
            error_exit "Unknown tunnel option: $1"
            ;;
    esac
}
