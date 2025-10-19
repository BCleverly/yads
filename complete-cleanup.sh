#!/bin/bash

# YADS Complete Cleanup Script
# Removes ALL YADS components and related software

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

# Confirm cleanup
confirm_cleanup() {
    warning "🚨 COMPLETE YADS CLEANUP"
    warning "This will remove ALL YADS components and related software:"
    warning "  - YADS system installation"
    warning "  - VS Code Server"
    warning "  - Cloudflared"
    warning "  - Web servers (Apache, Nginx, FrankenPHP)"
    warning "  - Databases (MySQL, PostgreSQL, Redis)"
    warning "  - PHP and development tools"
    warning "  - Cursor CLI"
    warning "  - GitHub CLI"
    warning "  - All configuration files"
    echo
    warning "This action CANNOT be undone!"
    echo
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        info "Cleanup cancelled"
        exit 0
    fi
}

# Stop all services
stop_services() {
    info "🛑 Stopping all services..."
    
    local services=("yads" "vscode-server" "cloudflared" "apache2" "nginx" "frankenphp" "mysql" "postgresql" "redis-server")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            sudo systemctl stop "$service"
            info "Stopped $service"
        fi
    done
}

# Remove systemd services
remove_services() {
    info "🗑️  Removing systemd services..."
    
    local services=("yads" "vscode-server" "cloudflared" "apache2" "nginx" "frankenphp" "mysql" "postgresql" "redis-server")
    
    for service in "${services[@]}"; do
        if systemctl list-unit-files | grep -q "^$service.service"; then
            sudo systemctl disable "$service" 2>/dev/null || true
            sudo rm -f "/etc/systemd/system/$service.service"
            sudo rm -f "/etc/systemd/system/multi-user.target.wants/$service.service"
            info "Removed $service service"
        fi
    done
}

# Remove YADS files
remove_yads_files() {
    info "🗑️  Removing YADS files..."
    
    sudo rm -rf /opt/yads
    sudo rm -rf /etc/yads
    sudo rm -rf /var/log/yads*
    sudo rm -rf /opt/vscode-server
    sudo rm -rf /etc/cloudflared
    sudo rm -rf /root/.cloudflared
    sudo rm -f /usr/local/bin/cloudflared
    sudo rm -f /usr/local/bin/frankenphp
    sudo rm -f /usr/local/bin/composer
    sudo rm -f /usr/local/bin/cursor-agent
    
    success "YADS files removed"
}

# Remove web servers
remove_web_servers() {
    info "🗑️  Removing web servers..."
    
    # Apache
    sudo apt-get remove --purge apache2 apache2-utils apache2-bin -y 2>/dev/null || true
    
    # Nginx
    sudo apt-get remove --purge nginx nginx-common nginx-core -y 2>/dev/null || true
    
    # FrankenPHP (manual removal)
    sudo rm -f /usr/local/bin/frankenphp
    
    success "Web servers removed"
}

# Remove databases
remove_databases() {
    info "🗑️  Removing databases..."
    
    # MySQL
    sudo apt-get remove --purge mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-* -y 2>/dev/null || true
    sudo rm -rf /var/lib/mysql
    sudo rm -rf /var/log/mysql
    
    # PostgreSQL
    sudo apt-get remove --purge postgresql postgresql-contrib postgresql-client postgresql-client-common -y 2>/dev/null || true
    sudo rm -rf /var/lib/postgresql
    sudo rm -rf /var/log/postgresql
    
    # Redis
    sudo apt-get remove --purge redis-server redis-tools -y 2>/dev/null || true
    sudo rm -rf /var/lib/redis
    sudo rm -rf /var/log/redis
    
    success "Databases removed"
}

# Remove PHP and development tools
remove_development_tools() {
    info "🗑️  Removing development tools..."
    
    # PHP
    sudo apt-get remove --purge php* -y 2>/dev/null || true
    
    # Composer
    sudo rm -f /usr/local/bin/composer
    
    # Cursor CLI
    sudo rm -f /usr/local/bin/cursor-agent
    rm -rf ~/.cursor
    
    # GitHub CLI
    sudo apt-get remove --purge gh -y 2>/dev/null || true
    
    success "Development tools removed"
}

# Clean up user files
cleanup_user_files() {
    info "🗑️  Cleaning up user files..."
    
    # Remove user YADS files
    rm -rf ~/yads
    rm -f ~/.local/bin/yads
    rm -f ~/.local/bin/cursor-agent
    
    # Clean up shell configuration
    sed -i '/yads/d' ~/.bashrc 2>/dev/null || true
    sed -i '/cursor/d' ~/.bashrc 2>/dev/null || true
    sed -i '/\.local\/bin/d' ~/.bashrc 2>/dev/null || true
    sed -i '/\.cursor\/bin/d' ~/.bashrc 2>/dev/null || true
    
    success "User files cleaned"
}

# Clean up system files
cleanup_system_files() {
    info "🗑️  Cleaning up system files..."
    
    # Remove project directory
    sudo rm -rf /var/www/projects
    
    # Clean up package cache
    sudo apt-get autoremove -y
    sudo apt-get autoclean
    
    # Reload systemd
    sudo systemctl daemon-reload
    
    success "System files cleaned"
}

# Main cleanup function
main() {
    setup_colors
    
    info "🧹 YADS Complete Cleanup Script"
    echo
    
    confirm_cleanup
    
    stop_services
    echo
    
    remove_services
    echo
    
    remove_yads_files
    echo
    
    remove_web_servers
    echo
    
    remove_databases
    echo
    
    remove_development_tools
    echo
    
    cleanup_user_files
    echo
    
    cleanup_system_files
    echo
    
    success "🎉 Complete cleanup finished!"
    echo
    info "To start fresh:"
    info "  git clone https://github.com/BCleverly/yads.git && cd yads && chmod +x *.sh && sudo ./install.sh"
}

# Run main function
main "$@"
