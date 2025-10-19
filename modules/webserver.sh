#!/bin/bash

# YADS Web Server Module
# Handles web server configuration (Apache, Nginx, FrankenPHP)

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

# Detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS="$ID"
        OS_VERSION="$VERSION_ID"
    else
        error_exit "Cannot detect operating system"
    fi
}

# Configure Apache
configure_apache() {
    info "🌐 Configuring Apache..."
    
    # Enable required modules
    a2enmod rewrite
    a2enmod ssl
    a2enmod headers
    a2enmod proxy
    a2enmod proxy_fcgi
    a2enmod setenvif
    
    # Create main Apache configuration
    cat > /etc/apache2/sites-available/yads.conf << 'EOF'
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/projects
    
    <Directory /var/www/projects>
        AllowOverride All
        Require all granted
    </Directory>
    
    # Proxy to VS Code Server
    ProxyPreserveHost On
    ProxyPass /code/ http://localhost:8080/
    ProxyPassReverse /code/ http://localhost:8080/
    
    # Wildcard subdomain support
    ServerAlias *.localhost
    VirtualDocumentRoot /var/www/projects/%1
    
    <Directory /var/www/projects>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
    
    # Enable the site
    a2ensite yads
    a2dissite 000-default
    
    # Start Apache
    systemctl restart apache2
    systemctl enable apache2
    
    success "Apache configured"
}

# Configure Nginx
configure_nginx() {
    info "🌐 Configuring Nginx..."
    
    # Create main Nginx configuration
    cat > /etc/nginx/sites-available/yads << 'EOF'
server {
    listen 80;
    server_name localhost *.localhost;
    root /var/www/projects;
    index index.php index.html index.htm;
    
    # VS Code Server proxy
    location /code/ {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Wildcard subdomain support
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    # PHP processing
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF
    
    # Enable the site
    ln -sf /etc/nginx/sites-available/yads /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test configuration
    nginx -t
    
    # Start Nginx
    systemctl restart nginx
    systemctl enable nginx
    
    success "Nginx configured"
}

# Install and configure FrankenPHP
configure_frankenphp() {
    info "🚀 Installing FrankenPHP..."
    
    # Download FrankenPHP
    local latest_version
    latest_version=$(curl -s https://api.github.com/repos/dunglas/frankenphp/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    
    wget "https://github.com/dunglas/frankenphp/releases/download/${latest_version}/frankenphp-linux-x86_64"
    mv frankenphp-linux-x86_64 /usr/local/bin/frankenphp
    chmod +x /usr/local/bin/frankenphp
    
    # Create FrankenPHP configuration
    cat > /etc/frankenphp/Caddyfile << 'EOF'
{
    auto_https off
}

localhost, *.localhost {
    root * /var/www/projects
    php_fastcgi unix//var/run/php/php8.4-fpm.sock
    
    # VS Code Server
    handle /code/* {
        reverse_proxy localhost:8080
    }
    
    # Wildcard subdomain support
    handle {
        try_files {path} {path}/ /index.php?{query}
    }
}
EOF
    
    # Create systemd service
    cat > /etc/systemd/system/frankenphp.service << 'EOF'
[Unit]
Description=FrankenPHP
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/projects
ExecStart=/usr/local/bin/frankenphp run --config /etc/frankenphp/Caddyfile
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Start FrankenPHP
    systemctl daemon-reload
    systemctl enable frankenphp
    systemctl start frankenphp
    
    success "FrankenPHP configured"
}

# Stop other web servers
stop_other_servers() {
    local target_server="$1"
    
    case "$target_server" in
        apache)
            if systemctl is-active --quiet nginx; then
                systemctl stop nginx
                systemctl disable nginx
            fi
            if systemctl is-active --quiet frankenphp; then
                systemctl stop frankenphp
                systemctl disable frankenphp
            fi
            ;;
        nginx)
            if systemctl is-active --quiet apache2; then
                systemctl stop apache2
                systemctl disable apache2
            fi
            if systemctl is-active --quiet frankenphp; then
                systemctl stop frankenphp
                systemctl disable frankenphp
            fi
            ;;
        frankenphp)
            if systemctl is-active --quiet apache2; then
                systemctl stop apache2
                systemctl disable apache2
            fi
            if systemctl is-active --quiet nginx; then
                systemctl stop nginx
                systemctl disable nginx
            fi
            ;;
    esac
}

# Show current web server status
show_status() {
    info "🌐 Web Server Status:"
    
    if systemctl is-active --quiet apache2; then
        success "Apache2: Running"
    else
        info "Apache2: Stopped"
    fi
    
    if systemctl is-active --quiet nginx; then
        success "Nginx: Running"
    else
        info "Nginx: Stopped"
    fi
    
    if systemctl is-active --quiet frankenphp; then
        success "FrankenPHP: Running"
    else
        info "FrankenPHP: Stopped"
    fi
}

# Main web server function
webserver_main() {
    setup_colors
    detect_os
    
    case "${1:-}" in
        "")
            show_status
            info "Use 'yads server <apache|nginx|frankenphp>' to switch web server"
            ;;
        apache)
            stop_other_servers apache
            configure_apache
            ;;
        nginx)
            stop_other_servers nginx
            configure_nginx
            ;;
        frankenphp)
            stop_other_servers frankenphp
            configure_frankenphp
            ;;
        status)
            show_status
            ;;
        *)
            error_exit "Unknown web server: $1. Use apache, nginx, or frankenphp"
            ;;
    esac
}
