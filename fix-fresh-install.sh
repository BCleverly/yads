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

# Function to fix Node.js for VS Code Server
fix_nodejs_vscode() {
    info "🐘 Fixing Node.js for VS Code Server..."
    
    # Check if Node.js is available
    if command -v node >/dev/null 2>&1; then
        local node_path="$(which node)"
        info "Node.js found at: $node_path"
        
        # Create symlinks for VS Code Server
        sudo ln -sf "$node_path" /usr/local/bin/node 2>/dev/null || true
        sudo ln -sf "$(dirname "$node_path")/npm" /usr/local/bin/npm 2>/dev/null || true
        
        # Create the directory that code-server expects
        sudo mkdir -p /usr/local/lib
        sudo ln -sf "$node_path" /usr/local/lib/node
        
        success "Node.js symlinks created for VS Code Server"
    else
        warning "Node.js not found, attempting to install..."
        
        # Install Node.js via NVM
        if [[ ! -d "$HOME/.nvm" ]]; then
            info "Installing NVM..."
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        fi
        
        # Source NVM
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        # Install Node.js LTS
        info "Installing Node.js LTS..."
        nvm install --lts || nvm install node
        nvm use --lts || nvm use node
        
        # Create symlinks
        local node_path="$(which node)"
        sudo ln -sf "$node_path" /usr/local/bin/node
        sudo ln -sf "$(dirname "$node_path")/npm" /usr/local/bin/npm
        sudo mkdir -p /usr/local/lib
        sudo ln -sf "$node_path" /usr/local/lib/node
        
        success "Node.js installed and symlinks created"
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
    
    local commands=("yads" "cursor-agent" "node" "npm")
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
    
    # Fix Node.js for VS Code Server
    fix_nodejs_vscode
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
