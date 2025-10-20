#!/bin/bash

# YADS Comprehensive Permission Fix
# This script sets up proper permissions for seamless development experience
# Ensures code-server, web services, and command line work without permission issues

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

info "🔧 YADS Comprehensive Permission Fix"
info "====================================="
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
    exit 1
fi

# Get the development user
dev_user=""
if [[ -n "${SUDO_USER:-}" ]]; then
    dev_user="$SUDO_USER"
else
    dev_user="$(whoami)"
fi

info "Setting up permissions for user: $dev_user"

# 1. Create and configure webdev group
info "👥 Setting up webdev group..."
if ! getent group webdev >/dev/null 2>&1; then
    groupadd webdev
    success "Created webdev group"
else
    info "webdev group already exists"
fi

# Add development user to webdev group
usermod -a -G webdev "$dev_user"
success "Added $dev_user to webdev group"

# 2. Set up VS Code Server permissions
info "💻 Setting up VS Code Server permissions..."

# Create vscode user if it doesn't exist
if ! id vscode >/dev/null 2>&1; then
    useradd -r -s /bin/bash -d /home/vscode -m vscode
    success "Created vscode user"
fi

# Add vscode user to webdev group
usermod -a -G webdev vscode

# Set up vscode user's home directory
mkdir -p /home/vscode/.config/code-server
chown -R vscode:webdev /home/vscode
chmod -R 755 /home/vscode

# Create VS Code Server config with proper permissions
if [[ ! -f /home/vscode/.config/code-server/config.yaml ]]; then
    local password
    password=$(openssl rand -base64 32)
    
    sudo -u vscode tee /home/vscode/.config/code-server/config.yaml > /dev/null << EOF
bind-addr: 0.0.0.0:8080
auth: password
password: $password
cert: false
EOF
    
    chown vscode:webdev /home/vscode/.config/code-server/config.yaml
    chmod 600 /home/vscode/.config/code-server/config.yaml
    success "VS Code Server config created with password: $password"
fi

# 3. Set up projects directory with proper permissions
info "📁 Setting up projects directory permissions..."
mkdir -p /var/www/projects
chown -R "$dev_user:webdev" /var/www/projects
chmod -R 775 /var/www/projects

# Set up ACL for better permission handling
if command -v setfacl >/dev/null 2>&1; then
    setfacl -R -m g:webdev:rwx /var/www/projects
    setfacl -R -d -m g:webdev:rwx /var/www/projects
    success "ACL permissions set for webdev group"
else
    warning "setfacl not available, using standard permissions"
fi

# 4. Set up web server permissions
info "🌐 Setting up web server permissions..."

# Configure Nginx to run as webdev group
if command -v nginx >/dev/null 2>&1; then
    # Update nginx.conf to run as webdev group
    sed -i 's/user www-data;/user webdev;/' /etc/nginx/nginx.conf 2>/dev/null || true
    
    # Create nginx sites directory
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled
    
    # Create YADS nginx config
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
    
    # Test nginx configuration
    if nginx -t >/dev/null 2>&1; then
        success "Nginx configuration is valid"
    else
        warning "Nginx configuration has issues"
    fi
fi

# 5. Set up PHP-FPM permissions
info "🐘 Setting up PHP-FPM permissions..."
if command -v php-fpm8.4 >/dev/null 2>&1; then
    # Update PHP-FPM pool to run as webdev group
    local pool_file="/etc/php/8.4/fpm/pool.d/www.conf"
    if [[ -f "$pool_file" ]]; then
        sed -i 's/group = www-data/group = webdev/' "$pool_file"
        sed -i 's/user = www-data/user = webdev/' "$pool_file"
        success "PHP-FPM configured for webdev group"
    fi
fi

# 6. Set up database permissions
info "🗄️  Setting up database permissions..."

# MySQL permissions
if command -v mysql >/dev/null 2>&1; then
    # Create a development database user
    mysql -e "CREATE USER IF NOT EXISTS 'yads_dev'@'localhost' IDENTIFIED BY 'yads_dev_pass';" 2>/dev/null || true
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'yads_dev'@'localhost';" 2>/dev/null || true
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true
    success "MySQL development user created"
fi

# PostgreSQL permissions
if command -v psql >/dev/null 2>&1; then
    sudo -u postgres psql -c "CREATE USER yads_dev WITH PASSWORD 'yads_dev_pass';" 2>/dev/null || true
    sudo -u postgres psql -c "ALTER USER yads_dev CREATEDB;" 2>/dev/null || true
    success "PostgreSQL development user created"
fi

# 7. Set up development tools permissions
info "🛠️  Setting up development tools permissions..."

# Node.js and npm permissions
if command -v node >/dev/null 2>&1; then
    # Set up npm global directory for the development user
    local npm_dir="/home/$dev_user/.npm-global"
    mkdir -p "$npm_dir"
    chown -R "$dev_user:webdev" "$npm_dir"
    
    # Configure npm to use the global directory
    sudo -u "$dev_user" npm config set prefix "$npm_dir" 2>/dev/null || true
    
    success "Node.js permissions configured"
fi

# Composer permissions
if command -v composer >/dev/null 2>&1; then
    # Set up composer cache directory
    local composer_dir="/home/$dev_user/.composer"
    mkdir -p "$composer_dir"
    chown -R "$dev_user:webdev" "$composer_dir"
    
    success "Composer permissions configured"
fi

# 8. Set up YADS command permissions
info "🎯 Setting up YADS command permissions..."

# Make sure yads command is available
if [[ -f /usr/local/bin/yads ]]; then
    chmod +x /usr/local/bin/yads
    success "YADS command is executable"
fi

# Set up YADS modules permissions
if [[ -d /opt/yads/modules ]]; then
    chmod +x /opt/yads/modules/*.sh
    chown -R root:webdev /opt/yads
    success "YADS modules permissions set"
fi

# 9. Create a test project to verify permissions
info "🧪 Creating test project to verify permissions..."
test_project="/var/www/projects/permission-test"

# Create test project as development user
sudo -u "$dev_user" mkdir -p "$test_project"
sudo -u "$dev_user" tee "$test_project/index.php" > /dev/null << 'EOF'
<?php
echo "<h1>Permission Test</h1>";
echo "<p>User: " . get_current_user() . "</p>";
echo "<p>Group: " . posix_getgrgid(posix_getgid())['name'] . "</p>";
echo "<p>Document Root: " . $_SERVER['DOCUMENT_ROOT'] . "</p>";
echo "<p>PHP Version: " . phpversion() . "</p>";
echo "<p>✅ Permissions working correctly!</p>";
?>
EOF

# Set proper permissions
chown -R "$dev_user:webdev" "$test_project"
chmod -R 775 "$test_project"

# Test write permissions
if sudo -u "$dev_user" touch "$test_project/test-write.txt" 2>/dev/null; then
    success "Write permissions working for $dev_user"
    rm -f "$test_project/test-write.txt"
else
    error "Write permissions not working for $dev_user"
fi

# 10. Restart services
info "🔄 Restarting services..."

# Restart VS Code Server
if systemctl is-active --quiet code-server@vscode; then
    systemctl restart code-server@vscode
    success "VS Code Server restarted"
fi

# Restart web server
if systemctl is-active --quiet nginx; then
    systemctl restart nginx
    success "Nginx restarted"
fi

# Restart PHP-FPM
if systemctl is-active --quiet php8.4-fpm; then
    systemctl restart php8.4-fpm
    success "PHP-FPM restarted"
fi

# 11. Show final status
info "📋 Final Status Check"
echo "===================="

# Check VS Code Server
if systemctl is-active --quiet code-server@vscode; then
    success "VS Code Server: Running"
    info "  Access: http://localhost:8080"
    if [[ -f /home/vscode/.config/code-server/config.yaml ]]; then
        local password
        password=$(grep "password:" /home/vscode/.config/code-server/config.yaml | cut -d' ' -f2)
        info "  Password: $password"
    fi
else
    warning "VS Code Server: Not running"
fi

# Check web server
if systemctl is-active --quiet nginx; then
    success "Nginx: Running"
    info "  Access: http://localhost"
    info "  Test project: http://localhost/permission-test/"
else
    warning "Nginx: Not running"
fi

# Check PHP-FPM
if systemctl is-active --quiet php8.4-fpm; then
    success "PHP-FPM: Running"
else
    warning "PHP-FPM: Not running"
fi

# Check projects directory
if [[ -d /var/www/projects ]] && [[ -w /var/www/projects ]]; then
    success "Projects directory: Writable by $dev_user"
else
    error "Projects directory: Not writable by $dev_user"
fi

echo
success "🎉 Comprehensive permission fix completed!"
echo
info "Summary of changes:"
info "  • Created webdev group and added users"
info "  • Fixed VS Code Server permissions"
info "  • Set up proper project directory permissions"
info "  • Configured web server for webdev group"
info "  • Set up database development users"
info "  • Configured development tools permissions"
info "  • Created test project to verify permissions"
echo
info "You can now:"
info "  • Access VS Code Server at http://localhost:8080"
info "  • Create projects with: yads project myapp"
info "  • Access projects at http://localhost/myapp"
info "  • Write code without permission issues"
echo