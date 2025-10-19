#!/bin/bash

# YADS Installation Diagnostic Script
# Helps diagnose installation issues and PATH problems

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

# Check system information
check_system() {
    info "🔍 System Information:"
    echo "  OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Unknown')"
    echo "  User: $(whoami)"
    echo "  Home: $HOME"
    echo "  Current Directory: $(pwd)"
    echo "  SUDO_USER: ${SUDO_USER:-'Not set'}"
    echo
}

# Check YADS repository files
check_yads_files() {
    info "📁 YADS Repository Files:"
    
    local current_dir="$(pwd)"
    local script_dir=""
    
    # Try to get script directory
    if [[ -n "${BASH_SOURCE[0]}" ]]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    else
        script_dir="$current_dir"
    fi
    
    echo "  Script Directory: $script_dir"
    echo "  Current Directory: $current_dir"
    echo
    
    # Check for yads script
    if [[ -f "$script_dir/yads" ]]; then
        success "yads script found at: $script_dir/yads"
        if [[ -x "$script_dir/yads" ]]; then
            success "yads script is executable"
        else
            warning "yads script is not executable"
        fi
    else
        error "yads script not found at: $script_dir/yads"
    fi
    
    # Check for modules directory
    if [[ -d "$script_dir/modules" ]]; then
        success "modules directory found at: $script_dir/modules"
        local module_count=$(find "$script_dir/modules" -name "*.sh" | wc -l)
        echo "  Module files: $module_count"
    else
        error "modules directory not found at: $script_dir/modules"
    fi
    
    # Check for install.sh
    if [[ -f "$script_dir/install.sh" ]]; then
        success "install.sh found at: $script_dir/install.sh"
        if [[ -x "$script_dir/install.sh" ]]; then
            success "install.sh is executable"
        else
            warning "install.sh is not executable"
        fi
    else
        error "install.sh not found at: $script_dir/install.sh"
    fi
    
    echo
}

# Check PATH configuration
check_path() {
    info "🛤️  PATH Configuration:"
    
    echo "  Current PATH:"
    echo "$PATH" | tr ':' '\n' | sed 's/^/    /'
    echo
    
    # Check for ~/.local/bin in PATH
    if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
        success "~/.local/bin is in PATH"
    else
        warning "~/.local/bin is NOT in PATH"
    fi
    
    # Check for /usr/local/bin in PATH
    if [[ ":$PATH:" == *":/usr/local/bin:"* ]]; then
        success "/usr/local/bin is in PATH"
    else
        warning "/usr/local/bin is NOT in PATH"
    fi
    
    echo
}

# Check shell configuration
check_shell_config() {
    info "🐚 Shell Configuration:"
    
    local shell_config=""
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        shell_config="$HOME/.zshrc"
    else
        shell_config="$HOME/.bashrc"
    fi
    
    echo "  Shell config: $shell_config"
    
    if [[ -f "$shell_config" ]]; then
        success "Shell config file exists"
        
        # Check for YADS PATH entries
        if grep -q "yads" "$shell_config" 2>/dev/null; then
            success "YADS PATH entries found in shell config"
        else
            warning "No YADS PATH entries found in shell config"
        fi
        
        # Check for Cursor Agent PATH entries
        if grep -q "cursor-agent" "$shell_config" 2>/dev/null; then
            success "Cursor Agent PATH entries found in shell config"
        else
            warning "No Cursor Agent PATH entries found in shell config"
        fi
    else
        error "Shell config file not found: $shell_config"
    fi
    
    echo
}

# Check command availability
check_commands() {
    info "🔧 Command Availability:"
    
    local commands=("yads" "cursor-agent" "code-server" "composer" "php" "git")
    
    for cmd in "${commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            success "$cmd is available"
            local cmd_path=$(command -v "$cmd")
            echo "    Path: $cmd_path"
        else
            error "$cmd is NOT available"
        fi
    done
    
    echo
}

# Check YADS installation
check_yads_installation() {
    info "🏗️  YADS Installation:"
    
    # Check for YADS directory
    if [[ -d "/opt/yads" ]]; then
        success "YADS directory exists: /opt/yads"
        
        if [[ -f "/opt/yads/yads" ]]; then
            success "YADS script exists in /opt/yads"
            if [[ -x "/opt/yads/yads" ]]; then
                success "YADS script is executable"
            else
                warning "YADS script is not executable"
            fi
        else
            error "YADS script not found in /opt/yads"
        fi
        
        if [[ -d "/opt/yads/modules" ]]; then
            success "YADS modules directory exists"
            local module_count=$(find "/opt/yads/modules" -name "*.sh" | wc -l)
            echo "    Module files: $module_count"
        else
            error "YADS modules directory not found"
        fi
    else
        error "YADS directory not found: /opt/yads"
    fi
    
    # Check for symlink
    if [[ -L "/usr/local/bin/yads" ]]; then
        success "YADS symlink exists: /usr/local/bin/yads"
        local symlink_target=$(readlink "/usr/local/bin/yads")
        echo "    Target: $symlink_target"
    else
        error "YADS symlink not found: /usr/local/bin/yads"
    fi
    
    echo
}

# Check services
check_services() {
    info "⚙️  Services:"
    
    local services=("apache2" "nginx" "mysql" "postgresql" "redis-server" "code-server")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            success "$service is running"
        elif systemctl is-enabled --quiet "$service" 2>/dev/null; then
            warning "$service is enabled but not running"
        else
            info "$service is not active"
        fi
    done
    
    echo
}

# Provide recommendations
provide_recommendations() {
    info "💡 Recommendations:"
    echo
    
    # Check if we're in the right directory
    if [[ ! -f "yads" ]] || [[ ! -d "modules" ]]; then
        warning "You may not be in the YADS repository directory"
        echo "  Try: cd ~/yads"
        echo
    fi
    
    # Check if install.sh is executable
    if [[ -f "install.sh" ]] && [[ ! -x "install.sh" ]]; then
        warning "install.sh is not executable"
        echo "  Try: chmod +x install.sh"
        echo
    fi
    
    # Check PATH issues
    if ! command -v yads >/dev/null 2>&1; then
        warning "yads command not found"
        echo "  Try: source ~/.bashrc"
        echo "  Or: export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo
    fi
    
    if ! command -v cursor-agent >/dev/null 2>&1; then
        warning "cursor-agent command not found"
        echo "  Try: source ~/.bashrc"
        echo "  Or: export PATH=\"\$HOME/.cursor/bin:\$PATH\""
        echo
    fi
    
    # Installation recommendations
    if [[ ! -d "/opt/yads" ]]; then
        warning "YADS not installed"
        echo "  Try: sudo ./install.sh"
        echo
    fi
}

# Main function
main() {
    setup_colors
    
    log "${CYAN}🔍 YADS Installation Diagnostic${NC}"
    log "${BLUE}==============================${NC}"
    echo
    
    check_system
    check_yads_files
    check_path
    check_shell_config
    check_commands
    check_yads_installation
    check_services
    provide_recommendations
    
    success "Diagnostic complete!"
}

# Run main function
main "$@"