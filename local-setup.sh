#!/bin/bash

# YADS Local Setup Script
# Makes yads command available locally without full installation

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

info() {
    log "${BLUE}ℹ️  $1${NC}"
}

success() {
    log "${GREEN}✅ $1${NC}"
}

warning() {
    log "${YELLOW}⚠️  Warning: $1${NC}"
}

# Main setup function
main() {
    setup_colors
    
    log "${CYAN}🔧 YADS Local Setup - Making yads command available${NC}"
    log "${BLUE}================================================${NC}"
    
    # Get current directory
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Check if we're in the right directory
    if [[ ! -f "$script_dir/yads" ]] || [[ ! -d "$script_dir/modules" ]]; then
        log "${RED}❌ Error: Please run this script from the YADS repository directory${NC}"
        exit 1
    fi
    
    # Make scripts executable and fix line endings
    info "Setting executable permissions and fixing line endings..."
    
    # Fix line endings for yads script
    if command -v dos2unix >/dev/null 2>&1; then
        dos2unix "$script_dir/yads" 2>/dev/null || true
    else
        # Fallback: use sed to convert CRLF to LF
        sed -i 's/\r$//' "$script_dir/yads" 2>/dev/null || true
    fi
    
    chmod +x "$script_dir/yads"
    chmod +x "$script_dir/install.sh"
    chmod +x "$script_dir/manual-uninstall.sh"
    chmod +x "$script_dir/modules"/*.sh 2>/dev/null || true
    
    # Create local bin directory if it doesn't exist
    local local_bin="$HOME/.local/bin"
    mkdir -p "$local_bin"
    
    # Create symlink to yads
    if [[ -L "$local_bin/yads" ]]; then
        warning "yads symlink already exists, updating..."
        rm "$local_bin/yads"
    fi
    
    ln -sf "$script_dir/yads" "$local_bin/yads"
    
    # Verify the symlink works
    if [[ -x "$local_bin/yads" ]]; then
        success "yads symlink created and is executable"
    else
        warning "yads symlink created but may not be executable"
        info "Checking file permissions..."
        ls -la "$local_bin/yads"
    fi
    
    # Add to PATH if not already there
    local shell_config=""
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        shell_config="$HOME/.zshrc"
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        shell_config="$HOME/.bashrc"
    else
        shell_config="$HOME/.profile"
    fi
    
    if [[ -f "$shell_config" ]] && ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" "$shell_config"; then
        info "Adding ~/.local/bin to PATH in $shell_config"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_config"
        warning "Please run 'source $shell_config' or restart your terminal to use yads command"
    fi
    
    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$local_bin:"* ]]; then
        export PATH="$local_bin:$PATH"
        warning "Added ~/.local/bin to current session PATH"
    fi
    
    success "yads command is now available locally!"
    
    log "${YELLOW}Usage:${NC}"
    log "  yads help                    # Show help"
    log "  yads version                 # Show version"
    log "  yads install                 # Run full installation"
    log ""
    log "${YELLOW}Note:${NC} Some commands require full installation (sudo ./install.sh)"
    log "${YELLOW}Note:${NC} You may need to restart your terminal or run 'source $shell_config'"
}

# Run main function
main "$@"
