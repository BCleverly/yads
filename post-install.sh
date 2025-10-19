#!/bin/bash

# YADS Post-Installation Setup Script
# Helps configure user environment after installation

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

# Check if commands are available
check_commands() {
    info "🔍 Checking command availability..."
    
    local commands=("yads" "cursor-agent")
    local all_available=true
    
    for cmd in "${commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            success "$cmd is available"
        else
            error "$cmd is not available"
            all_available=false
        fi
    done
    
    return $all_available
}

# Fix PATH for current session
fix_current_session() {
    info "🔧 Fixing PATH for current session..."
    
    # Determine user's home directory (handle sudo case)
    local user_home=""
    if [[ -n "${SUDO_USER:-}" ]]; then
        # Running with sudo, use the original user's home
        user_home="/home/$SUDO_USER"
    else
        # Running as regular user
        user_home="$HOME"
    fi
    
    # Add to current session PATH
    export PATH="$user_home/.local/bin:$PATH"
    export PATH="$user_home/.cursor/bin:$PATH"
    export PATH="/usr/local/bin:$PATH"
    
    success "PATH updated for current session"
}

# Update shell configuration
update_shell_config() {
    info "📝 Updating shell configuration..."
    
    # Determine user's home directory (handle sudo case)
    local user_home=""
    if [[ -n "${SUDO_USER:-}" ]]; then
        # Running with sudo, use the original user's home
        user_home="/home/$SUDO_USER"
    else
        # Running as regular user
        user_home="$HOME"
    fi
    
    local shell_config=""
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        shell_config="$user_home/.zshrc"
    else
        shell_config="$user_home/.bashrc"
    fi
    
    # Add YADS and Cursor paths
    if ! grep -q "yads" "$shell_config" 2>/dev/null; then
        echo "export PATH=\"$user_home/.local/bin:\$PATH\"" >> "$shell_config"
        echo "export PATH=\"$user_home/.cursor/bin:\$PATH\"" >> "$shell_config"
        echo 'export PATH="/usr/local/bin:$PATH"' >> "$shell_config"
        success "Added paths to $shell_config"
    else
        info "Paths already configured in $shell_config"
    fi
}

# Test commands
test_commands() {
    info "🧪 Testing commands..."
    
    echo "Testing yads:"
    if yads --version >/dev/null 2>&1; then
        success "yads --version works"
        yads --version
    else
        error "yads --version failed"
    fi
    
    echo
    echo "Testing cursor-agent:"
    if cursor-agent --help >/dev/null 2>&1; then
        success "cursor-agent --help works"
    else
        error "cursor-agent --help failed"
    fi
}

# Comprehensive PATH verification
verify_path_comprehensive() {
    info "🔍 Comprehensive PATH verification..."
    
    # Check for missing commands and fix them
    local missing_commands=()
    
    # Check yads
    if ! command -v yads >/dev/null 2>&1; then
        missing_commands+=("yads")
        warning "yads command not found"
        
        # Try to fix by adding /usr/local/bin
        if [[ -f "/usr/local/bin/yads" ]]; then
            export PATH="/usr/local/bin:$PATH"
            info "Added /usr/local/bin to PATH for yads"
        fi
    fi
    
    # Check cursor-agent
    if ! command -v cursor-agent >/dev/null 2>&1; then
        missing_commands+=("cursor-agent")
        warning "cursor-agent command not found"
        
        # Try multiple Cursor paths
        local user_home=""
        if [[ -n "${SUDO_USER:-}" ]]; then
            user_home="/home/$SUDO_USER"
        else
            user_home="$HOME"
        fi
        local cursor_paths=("$user_home/.cursor/bin" "/usr/local/bin")
        for cursor_path in "${cursor_paths[@]}"; do
            if [[ -f "$cursor_path/cursor-agent" ]]; then
                export PATH="$cursor_path:$PATH"
                info "Added $cursor_path to PATH for cursor-agent"
                break
            fi
        done
    fi
    
    # If we still have missing commands, apply comprehensive fix
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        warning "Still missing commands: ${missing_commands[*]}"
        info "Applying comprehensive PATH fix..."
        
        # Create a comprehensive PATH
        local user_home=""
        if [[ -n "${SUDO_USER:-}" ]]; then
            user_home="/home/$SUDO_USER"
        else
            user_home="$HOME"
        fi
        export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$user_home/.local/bin:$user_home/.cursor/bin:$PATH"
        
        # Update shell config with comprehensive PATH
        local shell_config=""
        if [[ -n "${ZSH_VERSION:-}" ]]; then
            shell_config="$user_home/.zshrc"
        else
            shell_config="$user_home/.bashrc"
        fi
        
        # Add comprehensive PATH to shell config
        if ! grep -q "YADS PATH Configuration" "$shell_config" 2>/dev/null; then
            cat >> "$shell_config" << EOF

# YADS PATH Configuration
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$user_home/.local/bin:$user_home/.cursor/bin:\$PATH"
EOF
            info "Added comprehensive PATH to $shell_config"
        fi
    fi
    
    # Final verification
    info "🔍 Final verification..."
    local still_missing=()
    
    for cmd in yads cursor-agent; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            still_missing+=("$cmd")
        fi
    done
    
    if [[ ${#still_missing[@]} -eq 0 ]]; then
        success "✅ All commands are now available!"
    else
        warning "⚠️  Some commands still missing: ${still_missing[*]}"
        warning "You may need to restart your terminal or run: source ~/.bashrc"
    fi
}

# Show next steps
show_next_steps() {
    info "🚀 Next Steps:"
    echo
    info "1. Restart your terminal or run:"
    info "   source ~/.bashrc"
    echo
    info "2. Test YADS:"
    info "   yads status"
    info "   yads help"
    echo
    info "3. Test Cursor Agent:"
    info "   cursor-agent --help"
    echo
    info "4. Configure YADS:"
    info "   yads tunnel setup"
    info "   yads vscode setup"
    echo
}

# Main function
main() {
    setup_colors
    
    info "🔧 YADS Post-Installation Setup"
    echo "================================="
    echo
    
    # Check if commands are already available
    if check_commands; then
        success "All commands are already available!"
        test_commands
        exit 0
    fi
    
    # Comprehensive PATH fix
    info "🔧 Applying comprehensive PATH fixes..."
    
    # Fix current session
    fix_current_session
    echo
    
    # Update shell configuration
    update_shell_config
    echo
    
    # Additional PATH verification and fixes
    verify_path_comprehensive
    echo
    
    # Test commands
    test_commands
    echo
    
    # Show next steps
    show_next_steps
}

# Run main function
main "$@"
