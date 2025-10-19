#!/bin/bash

# YADS Installation Diagnostic Script
# Checks what was installed and what might be missing

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

# Check if YADS is installed
check_yads_installation() {
    info "🔍 Checking YADS installation..."
    
    if [[ -d "/opt/yads" ]]; then
        success "YADS directory exists: /opt/yads"
        if [[ -f "/opt/yads/yads" ]]; then
            success "YADS script found: /opt/yads/yads"
        else
            error "YADS script missing: /opt/yads/yads"
        fi
    else
        error "YADS not installed: /opt/yads directory missing"
    fi
}

# Check Cursor CLI installation
check_cursor_cli() {
    info "🎯 Checking Cursor CLI installation..."
    
    # Check if cursor-agent command exists
    if command -v cursor-agent >/dev/null 2>&1; then
        success "cursor-agent command found"
        cursor-agent --version 2>/dev/null || info "cursor-agent version check failed"
    else
        error "cursor-agent command not found"
    fi
    
    # Check common installation locations
    local cursor_locations=(
        "$HOME/.cursor/bin/cursor-agent"
        "/usr/local/bin/cursor-agent"
        "/opt/cursor/bin/cursor-agent"
    )
    
    local found=false
    for location in "${cursor_locations[@]}"; do
        if [[ -f "$location" ]]; then
            success "Found cursor-agent at: $location"
            found=true
        fi
    done
    
    if [[ "$found" == false ]]; then
        error "cursor-agent not found in common locations"
    fi
}

# Check PATH configuration
check_path_config() {
    info "🔧 Checking PATH configuration..."
    
    echo "Current PATH:"
    echo "$PATH" | tr ':' '\n' | grep -E "(local|cursor)" || echo "No local/cursor paths found"
    
    # Check shell config files
    local shell_configs=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
    
    for config in "${shell_configs[@]}"; do
        if [[ -f "$config" ]]; then
            if grep -q "cursor" "$config"; then
                success "Cursor paths found in: $config"
            else
                warning "No cursor paths in: $config"
            fi
        fi
    done
}

# Check system services
check_services() {
    info "🔧 Checking YADS services..."
    
    local services=("vscode-server" "cloudflared" "mysql" "redis-server")
    
    for service in "${services[@]}"; do
        if systemctl list-unit-files | grep -q "^$service.service"; then
            if systemctl is-active --quiet "$service"; then
                success "$service: Running"
            else
                warning "$service: Installed but not running"
            fi
        else
            warning "$service: Not installed"
        fi
    done
}

# Check installation logs
check_installation_logs() {
    info "📋 Checking installation logs..."
    
    if [[ -f "/var/log/yads-install.log" ]]; then
        success "Installation log found: /var/log/yads-install.log"
        echo "Last 10 lines:"
        tail -10 /var/log/yads-install.log
    else
        warning "No installation log found"
    fi
    
    # Check systemd logs for YADS
    if command -v journalctl >/dev/null 2>&1; then
        echo "Recent YADS-related systemd logs:"
        journalctl --no-pager -u yads* --since "1 hour ago" 2>/dev/null || echo "No YADS systemd logs found"
    fi
}

# Provide recommendations
provide_recommendations() {
    info "💡 Recommendations:"
    echo
    
    if ! command -v cursor-agent >/dev/null 2>&1; then
        echo "1. Install Cursor CLI manually:"
        echo "   curl https://cursor.com/install -fsS | bash"
        echo "   echo 'export PATH=\"\$HOME/.cursor/bin:\$PATH\"' >> ~/.bashrc"
        echo "   source ~/.bashrc"
        echo
    fi
    
    if [[ ! -d "/opt/yads" ]]; then
        echo "2. Run full YADS installation:"
        echo "   sudo ./install.sh"
        echo
    fi
    
    echo "3. Check YADS status:"
    echo "   yads status"
    echo
}

# Main diagnostic function
main() {
    setup_colors
    
    info "🔍 YADS Installation Diagnostic"
    echo
    
    check_yads_installation
    echo
    
    check_cursor_cli
    echo
    
    check_path_config
    echo
    
    check_services
    echo
    
    check_installation_logs
    echo
    
    provide_recommendations
}

# Run main function
main "$@"
