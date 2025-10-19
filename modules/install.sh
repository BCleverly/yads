#!/bin/bash

# YADS Install Module
# Handles installation and setup of the development server

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

# Check if YADS is already installed
check_existing_installation() {
    if [[ -f "/opt/yads/yads" ]]; then
        warning "YADS appears to be already installed at /opt/yads"
        read -p "Do you want to reinstall? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Installation cancelled"
            exit 0
        fi
    fi
}

# Install YADS
install_yads() {
    info "🚀 Installing YADS Remote Development Server..."
    
    # Check for existing installation
    check_existing_installation
    
    # Get the script directory
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local main_install_script="$script_dir/../install.sh"
    
    # Check if main install script exists
    if [[ ! -f "$main_install_script" ]]; then
        error_exit "Main installation script not found at $main_install_script"
    fi
    
    # Run the main installation script
    info "Running main installation script..."
    bash "$main_install_script"
}

# Main install function
install_main() {
    setup_colors
    
    case "${1:-}" in
        "")
            install_yads
            ;;
        *)
            error_exit "Unknown install option: $1"
            ;;
    esac
}
