#!/bin/bash

# Fix Cursor Agent PATH Issues
# Specifically addresses cursor-agent command not found

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

# Find Cursor Agent installation
find_cursor_agent() {
    info "🔍 Searching for Cursor Agent installation..."
    
    local possible_paths=(
        "$HOME/.cursor/bin/cursor-agent"
        "/usr/local/bin/cursor-agent"
        "/usr/bin/cursor-agent"
        "$HOME/.local/bin/cursor-agent"
        "/opt/cursor/bin/cursor-agent"
    )
    
    for path in "${possible_paths[@]}"; do
        if [[ -f "$path" ]]; then
            info "Found Cursor Agent at: $path"
            echo "$path"
            return 0
        fi
    done
    
    warning "Cursor Agent not found in common locations"
    return 1
}

# Install Cursor CLI if not found
install_cursor_cli() {
    info "🎯 Installing Cursor CLI..."
    
    # Check if already installed
    if command -v cursor-agent >/dev/null 2>&1; then
        success "Cursor Agent already available"
        return 0
    fi
    
    # Try to find existing installation
    local cursor_path
    if cursor_path=$(find_cursor_agent); then
        info "Using existing Cursor Agent at: $cursor_path"
    else
        info "Installing Cursor CLI..."
        
        # Install using official installer
        curl https://cursor.com/install -fsS | bash
        
        # Wait a moment for installation
        sleep 2
        
        # Try to find the installation
        if ! cursor_path=$(find_cursor_agent); then
            error "Failed to install Cursor CLI"
            return 1
        fi
    fi
    
    # Add to PATH for current session
    local cursor_dir=$(dirname "$cursor_path")
    export PATH="$cursor_dir:$PATH"
    info "Added $cursor_dir to current session PATH"
    
    # Test if it works now
    if command -v cursor-agent >/dev/null 2>&1; then
        success "Cursor Agent is now available in current session"
    else
        warning "Cursor Agent still not available in current session"
    fi
}

# Fix shell configuration
fix_shell_config() {
    info "🔧 Fixing shell configuration..."
    
    # Determine user's home directory (handle sudo case)
    local user_home=""
    if [[ -n "${SUDO_USER:-}" ]]; then
        user_home="/home/$SUDO_USER"
    else
        user_home="$HOME"
    fi
    
    # Determine shell config file
    local shell_config=""
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        shell_config="$user_home/.zshrc"
    else
        shell_config="$user_home/.bashrc"
    fi
    
    info "Updating shell config: $shell_config"
    
    # Find Cursor Agent path
    local cursor_path
    if cursor_path=$(find_cursor_agent); then
        local cursor_dir=$(dirname "$cursor_path")
        info "Adding Cursor Agent path: $cursor_dir"
        
        # Add to shell config if not already there
        if ! grep -q "cursor-agent" "$shell_config" 2>/dev/null; then
            echo "export PATH=\"$cursor_dir:\$PATH\"" >> "$shell_config"
            success "Added Cursor Agent to $shell_config"
        else
            info "Cursor Agent already in $shell_config"
        fi
        
        # Also add to current session
        export PATH="$cursor_dir:$PATH"
        
    else
        warning "Could not find Cursor Agent to add to PATH"
    fi
    
    # Add comprehensive PATH configuration
    if ! grep -q "YADS PATH Configuration" "$shell_config" 2>/dev/null; then
        cat >> "$shell_config" << 'EOF'

# YADS PATH Configuration
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.local/bin:$HOME/.cursor/bin:$PATH"
EOF
        success "Added comprehensive PATH to $shell_config"
    fi
}

# Create system-wide symlink
create_symlink() {
    info "🔗 Creating system-wide symlink..."
    
    local cursor_path
    if cursor_path=$(find_cursor_agent); then
        local symlink_path="/usr/local/bin/cursor-agent"
        
        # Remove existing symlink if it exists
        if [[ -L "$symlink_path" ]]; then
            rm "$symlink_path"
        fi
        
        # Create new symlink
        ln -sf "$cursor_path" "$symlink_path"
        chmod +x "$symlink_path"
        
        success "Created symlink: $symlink_path -> $cursor_path"
        
        # Add /usr/local/bin to PATH if not already there
        if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
            export PATH="/usr/local/bin:$PATH"
            info "Added /usr/local/bin to current session PATH"
        fi
    else
        warning "Could not create symlink - Cursor Agent not found"
    fi
}

# Test Cursor Agent
test_cursor_agent() {
    info "🧪 Testing Cursor Agent..."
    
    if command -v cursor-agent >/dev/null 2>&1; then
        success "✅ cursor-agent command is available"
        
        # Test if it actually works
        if cursor-agent --help >/dev/null 2>&1; then
            success "✅ cursor-agent --help works"
        else
            warning "⚠️  cursor-agent --help failed"
        fi
        
        # Show version if possible
        if cursor-agent --version >/dev/null 2>&1; then
            info "Cursor Agent version: $(cursor-agent --version 2>/dev/null || echo 'unknown')"
        fi
        
    else
        error "❌ cursor-agent command still not available"
        
        # Show current PATH
        info "Current PATH: $PATH"
        
        # Show where we looked
        info "Searched locations:"
        find_cursor_agent || true
        
        return 1
    fi
}

# Main function
main() {
    setup_colors
    
    log "${CYAN}🎯 Cursor Agent Fix Script${NC}"
    log "${BLUE}==========================${NC}"
    echo
    
    # Check if we're in the right directory
    if [[ ! -f "yads" ]] || [[ ! -d "modules" ]]; then
        error "Please run this script from the YADS repository directory"
        exit 1
    fi
    
    # Step 1: Install or find Cursor CLI
    install_cursor_cli
    echo
    
    # Step 2: Fix shell configuration
    fix_shell_config
    echo
    
    # Step 3: Create system-wide symlink
    create_symlink
    echo
    
    # Step 4: Test Cursor Agent
    test_cursor_agent
    echo
    
    if command -v cursor-agent >/dev/null 2>&1; then
        success "🎉 Cursor Agent fix completed successfully!"
        
        log "${YELLOW}Next steps:${NC}"
        log "1. Restart your terminal or run: source ~/.bashrc"
        log "2. Test: cursor-agent --help"
        log "3. If still not working, run: ./diagnose-installation.sh"
    else
        error "❌ Cursor Agent fix failed"
        
        log "${YELLOW}Troubleshooting:${NC}"
        log "1. Check if Cursor CLI is installed: ls -la ~/.cursor/bin/"
        log "2. Run: ./diagnose-installation.sh"
        log "3. Try manual installation: curl https://cursor.com/install -fsS | bash"
    fi
    echo
}

# Run main function
main "$@"
