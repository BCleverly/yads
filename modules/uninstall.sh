#!/bin/bash

# YADS Uninstall Module
# Handles uninstallation while preserving SSH keys

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

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "Uninstall must be run as root or with sudo"
    fi
}

# Stop and remove services
remove_services() {
    info "🛑 Stopping YADS services..."
    
    # Stop VS Code Server
    if systemctl is-active --quiet vscode-server; then
        info "Stopping VS Code Server..."
        systemctl stop vscode-server
        systemctl disable vscode-server
    fi
    
    # Stop Cloudflared tunnel
    if systemctl is-active --quiet cloudflared; then
        info "Stopping Cloudflared tunnel..."
        systemctl stop cloudflared
        systemctl disable cloudflared
    fi
    
    success "Services stopped"
}

# Remove systemd services
remove_systemd_services() {
    info "🗑️  Removing systemd services..."
    
    # Remove VS Code Server service
    if [[ -f "/etc/systemd/system/vscode-server.service" ]]; then
        systemctl stop vscode-server 2>/dev/null || true
        systemctl disable vscode-server 2>/dev/null || true
        rm -f /etc/systemd/system/vscode-server.service
        systemctl daemon-reload
    fi
    
    # Remove Cloudflared service
    if [[ -f "/etc/systemd/system/cloudflared.service" ]]; then
        systemctl stop cloudflared 2>/dev/null || true
        systemctl disable cloudflared 2>/dev/null || true
        rm -f /etc/systemd/system/cloudflared.service
        systemctl daemon-reload
    fi
    
    success "Systemd services removed"
}

# Remove YADS files
remove_yads_files() {
    info "🗑️  Removing YADS files..."
    
    # Remove YADS directory
    if [[ -d "/opt/yads" ]]; then
        rm -rf /opt/yads
    fi
    
    # Remove symlink
    if [[ -L "/usr/local/bin/yads" ]]; then
        rm -f /usr/local/bin/yads
    fi
    
    # Remove configuration directory
    if [[ -d "/etc/yads" ]]; then
        rm -rf /etc/yads
    fi
    
    success "YADS files removed"
}

# Preserve user data
preserve_user_data() {
    info "💾 Preserving user data..."
    
    local backup_dir="/tmp/yads-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup SSH keys
    if [[ -d "/root/.ssh" ]]; then
        cp -r /root/.ssh "$backup_dir/ssh-keys"
        info "SSH keys backed up to: $backup_dir/ssh-keys"
    fi
    
    # Backup projects (ask user)
    if [[ -d "/var/www/projects" ]]; then
        read -p "Do you want to backup projects directory? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            info "Skipping projects backup"
        else
            cp -r /var/www/projects "$backup_dir/projects"
            info "Projects backed up to: $backup_dir/projects"
        fi
    fi
    
    # Backup VS Code Server data
    if [[ -d "/opt/vscode-server" ]]; then
        read -p "Do you want to backup VS Code Server data? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            info "Skipping VS Code Server backup"
        else
            cp -r /opt/vscode-server "$backup_dir/vscode-server"
            info "VS Code Server data backed up to: $backup_dir/vscode-server"
        fi
    fi
    
    success "User data preserved in: $backup_dir"
}

# Remove optional components
remove_optional_components() {
    info "🧹 Removing optional components..."
    
    # Ask about removing Docker
    if command -v docker >/dev/null 2>&1; then
        read -p "Do you want to remove Docker? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            info "Removing Docker..."
            systemctl stop docker 2>/dev/null || true
            systemctl disable docker 2>/dev/null || true
            # Note: Docker removal is complex and OS-specific, so we'll just stop it
            warning "Docker service stopped. Manual removal may be required."
        fi
    fi
    
    # Ask about removing databases
    if systemctl is-active --quiet mysql; then
        read -p "Do you want to remove MySQL? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            info "Stopping MySQL..."
            systemctl stop mysql
            systemctl disable mysql
        fi
    fi
    
    if systemctl is-active --quiet postgresql; then
        read -p "Do you want to remove PostgreSQL? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            info "Stopping PostgreSQL..."
            systemctl stop postgresql
            systemctl disable postgresql
        fi
    fi
    
    if systemctl is-active --quiet redis; then
        read -p "Do you want to remove Redis? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            info "Stopping Redis..."
            systemctl stop redis
            systemctl disable redis
        fi
    fi
    
    success "Optional components processed"
}

# Main uninstall function
uninstall_main() {
    setup_colors
    
    log "${RED}🚨 YADS UNINSTALLATION 🚨${NC}"
    log "${YELLOW}This will remove YADS and its components.${NC}"
    log "${YELLOW}SSH keys and user data will be preserved.${NC}"
    echo
    
    check_root
    
    read -p "Are you sure you want to uninstall YADS? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Uninstall cancelled"
        exit 0
    fi
    
    remove_services
    remove_systemd_services
    preserve_user_data
    remove_optional_components
    remove_yads_files
    
    success "🎉 YADS uninstalled successfully!"
    info "User data has been preserved in /tmp/yads-backup-*"
    info "You can manually remove backup directories when no longer needed"
}
