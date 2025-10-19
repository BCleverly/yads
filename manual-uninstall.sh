#!/bin/bash

# YADS Manual Uninstall Script
# Use this when normal uninstall fails

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

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root or with sudo"
    fi
}

# Manual uninstall process
manual_uninstall() {
    log "${RED}🚨 MANUAL YADS UNINSTALLATION 🚨${NC}"
    log "${YELLOW}This will forcefully remove YADS and its components.${NC}"
    log "${YELLOW}SSH keys and user data will be preserved.${NC}"
    echo
    
    check_root
    
    log "${RED}🔥 DESTRUCTIVE ACTIONS:${NC}"
    echo "  🗑️  YADS directory: /opt/yads"
    echo "  🗑️  YADS symlink: /usr/local/bin/yads"
    echo "  🗑️  YADS config: /etc/yads"
    echo "  🛑 All YADS services will be stopped"
    echo "  🛑 All YADS systemd services will be removed"
    echo
    
    read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Uninstall cancelled"
        exit 0
    fi
    
    # Stop all services
    info "🛑 Stopping all YADS services..."
    systemctl stop vscode-server 2>/dev/null || true
    systemctl stop cloudflared 2>/dev/null || true
    systemctl stop frankenphp 2>/dev/null || true
    
    # Remove systemd services
    info "🗑️  Removing systemd services..."
    rm -f /etc/systemd/system/vscode-server.service
    rm -f /etc/systemd/system/cloudflared.service
    rm -f /etc/systemd/system/frankenphp.service
    systemctl daemon-reload
    
    # Remove YADS files
    info "🗑️  Removing YADS files..."
    rm -rf /opt/yads
    rm -f /usr/local/bin/yads
    rm -rf /etc/yads
    
    # Preserve user data
    info "💾 Preserving user data..."
    local backup_dir="/tmp/yads-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup SSH keys
    if [[ -d "/root/.ssh" ]]; then
        cp -r /root/.ssh "$backup_dir/ssh-keys"
        info "SSH keys backed up to: $backup_dir/ssh-keys"
    fi
    
    # Backup projects
    if [[ -d "/var/www/projects" ]]; then
        cp -r /var/www/projects "$backup_dir/projects"
        info "Projects backed up to: $backup_dir/projects"
    fi
    
    # Backup VS Code Server data
    if [[ -d "/opt/vscode-server" ]]; then
        cp -r /opt/vscode-server "$backup_dir/vscode-server"
        info "VS Code Server data backed up to: $backup_dir/vscode-server"
    fi
    
    success "🎉 YADS manually uninstalled!"
    info "User data has been preserved in: $backup_dir"
    info "You can manually remove backup directories when no longer needed"
}

# Main function
main() {
    setup_colors
    manual_uninstall
}

# Run main function
main "$@"
