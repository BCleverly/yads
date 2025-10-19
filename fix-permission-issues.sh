#!/bin/bash

# Fix permission issues for YADS commands
# This script resolves "Permission denied" errors for webserver and project commands

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

info "🔧 Fixing YADS permission issues..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
    exit 1
fi

# Create /var/www/projects directory with proper permissions
info "📁 Creating projects directory..."
mkdir -p "/var/www/projects"
chown -R "$SUDO_USER:$SUDO_USER" "/var/www/projects"
chmod 755 "/var/www/projects"

# Create Nginx configuration
info "🌐 Creating Nginx configuration..."
cat > /etc/nginx/sites-available/yads << 'EOF'
server {
    listen 80;
    server_name localhost *.localhost;
    root /var/www/projects;
    index index.php index.html index.htm;
    
    # Enable PHP processing
    location / {
        try_files $uri $uri/ =404;
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
info "🔗 Enabling Nginx site..."
ln -sf /etc/nginx/sites-available/yads /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
info "🧪 Testing Nginx configuration..."
nginx -t

# Restart Nginx
info "🔄 Restarting Nginx..."
systemctl restart nginx
systemctl enable nginx

# Check Nginx status
if systemctl is-active --quiet nginx; then
    success "Nginx is running successfully!"
else
    error "Nginx failed to start"
    info "Check logs with: journalctl -u nginx -f"
    exit 1
fi

success "🎉 Permission issues fixed!"
info "You can now run:"
info "  yads server nginx"
info "  yads project myapp"
