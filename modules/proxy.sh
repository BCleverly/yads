#!/bin/bash

# YADS NGINX Proxy Manager Module
# Handles NGINX Proxy Manager installation and configuration

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

# Check if Node.js is installed
check_nodejs() {
    if ! command -v node >/dev/null 2>&1; then
        error_exit "Node.js is not installed. Run 'yads install' first."
    fi
}

# Install NGINX Proxy Manager
install_npm() {
    info "🌐 Installing NGINX Proxy Manager..."
    
    check_nodejs
    
    # Create NPM user
    if ! id npm >/dev/null 2>&1; then
        useradd -r -s /bin/bash -d /opt/npm -m npm
        success "Created npm user"
    fi
    
    # Create NPM directories
    mkdir -p /opt/npm/{data,letsencrypt,logs}
    chown -R npm:npm /opt/npm
    
    # Install NPM globally
    info "Installing NGINX Proxy Manager..."
    npm install -g nginx-proxy-manager
    
    # Create systemd service
    cat > /etc/systemd/system/npm.service << 'EOF'
[Unit]
Description=NGINX Proxy Manager
After=network.target

[Service]
Type=simple
User=npm
WorkingDirectory=/opt/npm
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # Start and enable service
    systemctl daemon-reload
    systemctl enable npm
    systemctl start npm
    
    success "NGINX Proxy Manager installed"
    info "Admin panel: http://localhost:81"
    info "Default login: admin@example.com / changeme"
}

# Configure NPM for YADS
configure_npm_for_yads() {
    info "🔧 Configuring NPM for YADS..."
    
    # Create NPM configuration
    cat > /opt/npm/config.json << 'EOF'
{
    "database": {
        "engine": "mysql",
        "host": "localhost",
        "port": 3306,
        "user": "npm",
        "password": "npm_password",
        "name": "npm"
    },
    "port": 81,
    "ssl": {
        "email": "admin@yourdomain.com",
        "domains": ["yourdomain.com"]
    }
}
EOF
    
    # Set proper permissions
    chown npm:npm /opt/npm/config.json
    chmod 600 /opt/npm/config.json
    
    success "NPM configured for YADS"
}

# Add proxy host for YADS services
add_yads_proxy_host() {
    local domain="$1"
    local target="$2"
    local port="$3"
    local ssl_enabled="${4:-true}"
    
    info "Adding YADS proxy host: $domain → $target:$port"
    
    # Create proxy host configuration
    local proxy_config="/opt/npm/proxy-hosts/${domain}.json"
    mkdir -p /opt/npm/proxy-hosts
    
    cat > "$proxy_config" << EOF
{
    "domain_names": ["$domain"],
    "forward_scheme": "http",
    "forward_host": "$target",
    "forward_port": $port,
    "ssl_forced": $ssl_enabled,
    "caching_enabled": true,
    "block_exploits": true,
    "access_list_id": 0
}
EOF
    
    chown npm:npm "$proxy_config"
    chmod 644 "$proxy_config"
    
    # Reload NPM configuration
    systemctl reload npm
    
    success "Proxy host added: $domain"
}

# Setup VS Code Server proxy
setup_vscode_proxy() {
    info "💻 Setting up VS Code Server proxy..."
    
    local domain="${1:-code-server.yourdomain.com}"
    
    add_yads_proxy_host "$domain" "localhost" "8080" "true"
    
    success "VS Code Server proxy configured"
    info "Access: https://$domain"
}

# Setup project proxy
setup_project_proxy() {
    local project_name="$1"
    local port="$2"
    local domain="${3:-$project_name.projects.code-server.yourdomain.com}"
    
    info "📁 Setting up project proxy: $project_name"
    
    add_yads_proxy_host "$domain" "localhost" "$port" "true"
    
    success "Project proxy configured: $domain"
}

# Setup standard YADS routes
setup_standard_routes() {
    local domain="${1:-yourdomain.com}"
    
    info "🔧 Setting up standard YADS routes..."
    
    # VS Code Server
    add_yads_proxy_host "code-server.$domain" "localhost" "8080" "true"
    
    # NPM Admin
    add_yads_proxy_host "proxy-manager.code-server.$domain" "localhost" "81" "true"
    
    # phpMyAdmin
    add_yads_proxy_host "phpmyadmin.code-server.$domain" "localhost" "8080" "true"
    
    # Projects List
    add_yads_proxy_host "projects.code-server.$domain" "localhost" "8080" "true"
    
    success "Standard YADS routes configured"
    info "VS Code Server: https://code-server.$domain"
    info "NPM Admin: https://proxy-manager.code-server.$domain"
    info "phpMyAdmin: https://phpmyadmin.code-server.$domain"
    info "Projects List: https://projects.code-server.$domain"
}

# Show NPM status
show_npm_status() {
    info "🌐 NGINX Proxy Manager Status:"
    
    if systemctl is-active --quiet npm; then
        success "NPM: Running"
        info "Admin panel: http://localhost:81"
        info "Web interface: https://proxy-manager.code-server.yourdomain.com (when tunnel configured)"
    else
        warning "NPM: Stopped"
    fi
    
    # Show configured proxy hosts
    if [[ -d "/opt/npm/proxy-hosts" ]]; then
        info "Configured proxy hosts:"
        for config in /opt/npm/proxy-hosts/*.json; do
            if [[ -f "$config" ]]; then
                local domain=$(basename "$config" .json)
                info "  - $domain"
            fi
        done
    fi
}

# Start NPM
start_npm() {
    info "🚀 Starting NGINX Proxy Manager..."
    
    systemctl start npm
    systemctl enable npm
    
    success "NPM started"
}

# Stop NPM
stop_npm() {
    info "🛑 Stopping NGINX Proxy Manager..."
    
    systemctl stop npm
    systemctl disable npm
    
    success "NPM stopped"
}

# Restart NPM
restart_npm() {
    info "🔄 Restarting NGINX Proxy Manager..."
    
    systemctl restart npm
    
    success "NPM restarted"
}

# Main proxy function
proxy_main() {
    setup_colors
    
    case "${1:-}" in
        "")
            show_npm_status
            ;;
        install)
            install_npm
            configure_npm_for_yads
            ;;
        status)
            show_npm_status
            ;;
        start)
            start_npm
            ;;
        stop)
            stop_npm
            ;;
        restart)
            restart_npm
            ;;
        vscode)
            setup_vscode_proxy "${2:-}"
            ;;
        project)
            setup_project_proxy "${2:-}" "${3:-8081}" "${4:-}"
            ;;
        add)
            add_yads_proxy_host "${2:-}" "${3:-localhost}" "${4:-80}" "${5:-true}"
            ;;
        setup)
            setup_standard_routes "${2:-}"
            ;;
        *)
            error_exit "Unknown proxy option: $1"
            ;;
    esac
}
