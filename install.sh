#!/bin/bash

# YADS Installation Script
# This script downloads and installs YADS on your system

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
YADS_INSTALL_DIR="$HOME/.local/bin"
YADS_REPO_URL="https://raw.githubusercontent.com/BCleverly/yads/main"

# Logging function
log() {
    echo -e "$1"
}

# Error handling
error_exit() {
    log "${RED}ERROR: $1${NC}"
    exit 1
}

# Success message
success() {
    log "${GREEN}✓ $1${NC}"
}

# Info message
info() {
    log "${BLUE}ℹ $1${NC}"
}

# Warning message
warning() {
    log "${YELLOW}⚠ $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error_exit "This script should not be run as root. Please run as a regular user with sudo privileges."
    fi
}

# Check if curl is available
check_curl() {
    if ! command -v curl &> /dev/null; then
        error_exit "curl is required but not installed. Please install curl first."
    fi
}

# Create installation directory
create_install_dir() {
    info "Creating installation directory..."
    mkdir -p "$YADS_INSTALL_DIR"
    success "Installation directory created"
}

# Download YADS
download_yads() {
    info "Downloading YADS..."
    
    # Download main script
    curl -fsSL "$YADS_REPO_URL/yads" -o "$YADS_INSTALL_DIR/yads"
    chmod +x "$YADS_INSTALL_DIR/yads"
    
    # Create modules directory
    mkdir -p "$YADS_INSTALL_DIR/modules"
    
    # Download modules
    curl -fsSL "$YADS_REPO_URL/modules/install.sh" -o "$YADS_INSTALL_DIR/modules/install.sh"
    curl -fsSL "$YADS_REPO_URL/modules/domains.sh" -o "$YADS_INSTALL_DIR/modules/domains.sh"
    curl -fsSL "$YADS_REPO_URL/modules/projects.sh" -o "$YADS_INSTALL_DIR/modules/projects.sh"
    
    # Make modules executable
    chmod +x "$YADS_INSTALL_DIR/modules"/*.sh
    
    success "YADS downloaded"
}

# Add to PATH
add_to_path() {
    info "Adding YADS to PATH..."
    
    # Check if already in PATH
    if [[ ":$PATH:" == *":$YADS_INSTALL_DIR:"* ]]; then
        info "YADS is already in PATH"
        return
    fi
    
    # Add to shell configuration
    for shell_config in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        if [[ -f "$shell_config" ]]; then
            # Check if PATH export already exists
            if ! grep -q "export PATH.*$YADS_INSTALL_DIR" "$shell_config"; then
                echo "export PATH=\"$YADS_INSTALL_DIR:\$PATH\"" >> "$shell_config"
                success "Added to $shell_config"
            else
                info "Already configured in $shell_config"
            fi
        fi
    done
    
    # Add to current session
    export PATH="$YADS_INSTALL_DIR:$PATH"
    
    success "YADS added to PATH"
}

# Create symlink for easy access
create_symlink() {
    info "Creating symlink..."
    
    # Try to create system-wide symlink
    if sudo ln -sf "$YADS_INSTALL_DIR/yads" /usr/local/bin/yads 2>/dev/null; then
        success "System-wide symlink created in /usr/local/bin"
        success "YADS is now available globally as 'yads'"
    else
        warning "Could not create system-wide symlink. YADS is available in your PATH."
        info "You can run YADS with: $YADS_INSTALL_DIR/yads"
    fi
}

# Verify installation
verify_installation() {
    info "Verifying installation..."
    
    if command -v yads &> /dev/null; then
        success "YADS is installed and available globally"
        success "You can now use 'yads' from anywhere in your system"
        echo
        info "Testing YADS functionality..."
        yads help
    else
        error_exit "YADS installation failed"
    fi
}

# Show next steps
show_next_steps() {
    log "${CYAN}YADS Installation Complete!${NC}"
    echo
    log "${GREEN}YADS is now available globally!${NC}"
    echo "You can use 'yads' from anywhere in your system:"
    echo "  • From any directory"
    echo "  • From any terminal session"
    echo "  • From scripts and automation"
    echo
    log "${GREEN}Next steps:${NC}"
    echo "1. Run 'yads prerequisites' to check your system"
    echo "2. Run 'yads install' to set up your development server"
    echo "3. Run 'yads domains' to configure your domain"
    echo "4. Run 'yads create <project>' to create your first project"
    echo
    log "${BLUE}For help, run: yads help${NC}"
    echo
    log "${YELLOW}Note: If YADS is not immediately available, restart your terminal or run 'source ~/.bashrc'${NC}"
}

# Main installation function
main() {
    log "${CYAN}Installing YADS - Yet Another Development Server${NC}"
    echo
    
    # Pre-installation checks
    check_root
    check_curl
    
    # Installation steps
    create_install_dir
    download_yads
    add_to_path
    create_symlink
    verify_installation
    show_next_steps
}

# Run main function
main "$@"

