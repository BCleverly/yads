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
        BLUE='\033[0;94m'      # Light blue instead of dark blue
        CYAN='\033[0;96m'      # Light cyan
        WHITE='\033[1;37m'     # Bright white for better contrast
        GRAY='\033[0;37m'      # Light gray for secondary text
        NC='\033[0m' # No Color
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
    info "Following Cloudflare dashboard instructions: https://one.dash.cloudflare.com/networks/tunnels"
    
    check_cloudflared
    
    # Create cloudflared directory with proper permissions
    info "📁 Creating Cloudflared directories..."
    if [[ $EUID -eq 0 ]]; then
        # Running as root
        mkdir -p /etc/cloudflared
        mkdir -p /var/log/cloudflared
        chown cloudflared:cloudflared /var/log/cloudflared 2>/dev/null || true
    else
        # Running as regular user, use sudo
        info "Using sudo to create system directories..."
        sudo mkdir -p /etc/cloudflared
        sudo mkdir -p /var/log/cloudflared
        sudo chown cloudflared:cloudflared /var/log/cloudflared 2>/dev/null || true
    fi
    
    # Login to Cloudflare (opens browser for authentication)
    info "🔐 Authenticating with Cloudflare..."
    info "This will open your browser to login to Cloudflare"
    cloudflared tunnel login
    
    # Create tunnel with proper naming
    local tunnel_name
    tunnel_name="${1:-yads-dev-server}"
    
    info "📡 Creating tunnel: $tunnel_name"
    cloudflared tunnel create "$tunnel_name"
    
    # Get tunnel ID and credentials
    local tunnel_id
    tunnel_id=$(cloudflared tunnel list | grep "$tunnel_name" | awk '{print $1}')
    
    if [[ -z "$tunnel_id" ]]; then
        error_exit "Failed to get tunnel ID. Please check your Cloudflare dashboard."
    fi
    
    info "✅ Tunnel created successfully"
    info "Tunnel ID: $tunnel_id"
    info "Credentials saved to: /root/.cloudflared/$tunnel_id.json"
    
    # Create tunnel configuration pointing to NPM
    info "📝 Creating tunnel configuration for NPM..."
    if [[ $EUID -eq 0 ]]; then
        # Running as root
        cat > /etc/cloudflared/config.yml << EOF
tunnel: $tunnel_id
credentials-file: /root/.cloudflared/$tunnel_id.json

ingress:
  # All traffic goes to NPM
  - hostname: "*.$domain"
    service: http://localhost:81
    originRequest:
      noTLSVerify: true
  
  # Catch-all rule
  - service: http_status:404
EOF
    else
        # Running as regular user, use sudo
        sudo tee /etc/cloudflared/config.yml > /dev/null << EOF
tunnel: $tunnel_id
credentials-file: /root/.cloudflared/$tunnel_id.json

ingress:
  # All traffic goes to NPM
  - hostname: "*.$domain"
    service: http://localhost:81
    originRequest:
      noTLSVerify: true
  
  # Catch-all rule
  - service: http_status:404
EOF
    fi
    
    # Create DNS records (following Cloudflare dashboard workflow)
    info "🌐 Setting up DNS records..."
    info "This will create DNS records in your Cloudflare dashboard"
    
    # Get domain from user or use default
    local domain
    domain="${2:-remote.domain.tld}"
    
    info "Creating DNS records for domain: $domain"
    cloudflared tunnel route dns "$tunnel_name" "code.$domain"
    cloudflared tunnel route dns "$tunnel_name" "*.$domain"
    
    success "DNS records created:"
    info "  - code.$domain (VS Code Server)"
    info "  - *.$domain (Wildcard for projects)"
    
    # Create systemd service with proper permissions
    info "⚙️  Creating systemd service..."
    if [[ $EUID -eq 0 ]]; then
        # Running as root
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
    else
        # Running as regular user, use sudo
        sudo tee /etc/systemd/system/cloudflared.service > /dev/null << EOF
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
    fi
    
    # Start tunnel service
    info "🚀 Starting Cloudflared service..."
    if [[ $EUID -eq 0 ]]; then
        # Running as root
        systemctl daemon-reload
        systemctl enable cloudflared
        systemctl start cloudflared
    else
        # Running as regular user, use sudo
        sudo systemctl daemon-reload
        sudo systemctl enable cloudflared
        sudo systemctl start cloudflared
    fi
    
    # Auto-configure NPM routes
    info "🔧 Auto-configuring NPM routes..."
    if command -v yads >/dev/null 2>&1; then
        yads proxy setup "$domain"
    else
        warning "YADS not found in PATH, skipping NPM auto-configuration"
        info "Run 'yads proxy setup $domain' to configure NPM routes"
    fi
    
    success "🎉 Cloudflared tunnel configured successfully!"
    
    # Show configuration summary
    info "📋 Configuration Summary:"
    info "  Tunnel ID: $tunnel_id"
    info "  Domain: $domain"
    info "  VS Code Server: https://code.$domain"
    info "  Projects: https://*.$domain"
    info "  Dashboard: https://one.dash.cloudflare.com/networks/tunnels"
    
    # Show next steps
    info "🚀 Next Steps:"
    info "  1. Check your Cloudflare dashboard for the tunnel"
    info "  2. Verify DNS records are created"
    info "  3. Test access to your services"
    info "  4. Run 'yads status' to check tunnel status"
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

# Show Cloudflare dashboard help
show_dashboard_help() {
    info "🌐 Cloudflare Dashboard Setup:"
    echo
    info "1. Visit: https://one.dash.cloudflare.com/networks/tunnels"
    info "2. Click 'Create a tunnel'"
    info "3. Choose 'Cloudflared' connector"
    info "4. Follow the setup wizard"
    echo
    info "Alternative: Use 'yads tunnel setup' for automated setup"
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
            setup_tunnel "${2:-}" "${3:-}"
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
        dashboard)
            show_dashboard_help
            ;;
        *)
            error_exit "Unknown tunnel option: $1"
            ;;
    esac
}
