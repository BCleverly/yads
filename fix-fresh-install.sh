#!/bin/bash

# YADS Fresh Install Fix Script
# Fixes common issues after a fresh YADS installation

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

info "🔧 YADS Fresh Install Fix Script"
info "This script will fix common issues after a fresh YADS installation"
echo

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    error "This script should not be run as root"
    error "Please run as a regular user with sudo access"
    exit 1
fi

# Function to fix Cursor CLI
fix_cursor_cli() {
    info "🎯 Fixing Cursor CLI..."
    
    if command -v cursor-agent >/dev/null 2>&1; then
        success "Cursor CLI is already available"
        return 0
    fi
    
    # Try to find Cursor CLI in common locations
    local cursor_paths=(
        "$HOME/.cursor/bin/cursor-agent"
        "/usr/local/bin/cursor-agent"
        "/opt/cursor/bin/cursor-agent"
    )
    
    local found_cursor=""
    for path in "${cursor_paths[@]}"; do
        if [[ -f "$path" ]]; then
            found_cursor="$path"
            break
        fi
    done
    
    if [[ -n "$found_cursor" ]]; then
        # Add to PATH
        local cursor_dir="$(dirname "$found_cursor")"
        export PATH="$cursor_dir:$PATH"
        
        # Add to shell config
        local shell_config=""
        if [[ -n "${ZSH_VERSION:-}" ]]; then
            shell_config="$HOME/.zshrc"
        else
            shell_config="$HOME/.bashrc"
        fi
        
        if ! grep -q "cursor-agent" "$shell_config" 2>/dev/null; then
            echo "export PATH=\"$cursor_dir:\$PATH\"" >> "$shell_config"
            info "Added Cursor CLI to $shell_config"
        fi
        
        success "Cursor CLI found and added to PATH"
    else
        warning "Cursor CLI not found, attempting to install..."
        
        # Install Cursor CLI
        curl https://cursor.com/install -fsS | bash
        
        # Check if installation was successful
        if command -v cursor-agent >/dev/null 2>&1; then
            success "Cursor CLI installed successfully"
        else
            error "Failed to install Cursor CLI"
            return 1
        fi
    fi
}

# Function to fix VS Code Server installation
fix_vscode_server() {
    info "💻 Fixing VS Code Server installation..."
    
    # Check if code-server is available
    if command -v code-server >/dev/null 2>&1; then
        success "VS Code Server is already available"
        return 0
    fi
    
    # Install VS Code Server using official method
    info "Installing VS Code Server using official install script..."
    curl -fsSL https://code-server.dev/install.sh | sh
    
    # Verify installation
    if command -v code-server >/dev/null 2>&1; then
        success "VS Code Server installed successfully"
    else
        error "Failed to install VS Code Server"
        return 1
    fi
}

# Function to fix PATH issues
fix_path_issues() {
    info "🔧 Fixing PATH issues..."
    
    # Add essential paths to current session
    export PATH="/usr/local/bin:$PATH"
    export PATH="$HOME/.local/bin:$PATH"
    export PATH="$HOME/.cursor/bin:$PATH"
    
    # Update shell configuration
    local shell_config=""
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        shell_config="$HOME/.zshrc"
    else
        shell_config="$HOME/.bashrc"
    fi
    
    # Add comprehensive PATH to shell config
    if ! grep -q "YADS PATH Configuration" "$shell_config" 2>/dev/null; then
        cat >> "$shell_config" << 'EOF'

# YADS PATH Configuration
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.local/bin:$HOME/.cursor/bin:$PATH"
EOF
        info "Added comprehensive PATH to $shell_config"
    fi
    
    success "PATH configuration updated"
}

# Function to test all commands
test_commands() {
    info "🧪 Testing commands..."
    
    local commands=("yads" "cursor-agent" "code-server")
    local all_working=true
    
    for cmd in "${commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            success "$cmd is available"
        else
            error "$cmd is not available"
            all_working=false
        fi
    done
    
    if [[ "$all_working" == true ]]; then
        success "All commands are working!"
    else
        warning "Some commands are still not available"
        warning "Please run 'source ~/.bashrc' or restart your terminal"
    fi
}

# Main execution
main() {
    info "Starting YADS fresh install fix..."
    echo
    
    # Fix Cursor CLI
    fix_cursor_cli
    echo
    
    # Fix VS Code Server installation
    fix_vscode_server
    echo
    
    # Fix PATH issues
    fix_path_issues
    echo
    
    # Test commands
    test_commands
    echo
    
    success "🎉 YADS fresh install fix completed!"
    info "Next steps:"
    info "1. Run 'source ~/.bashrc' or restart your terminal"
    info "2. Test: yads status"
    info "3. Test: cursor-agent --help"
    info "4. Test: yads vscode setup"
}

# Run main function
main "$@"
