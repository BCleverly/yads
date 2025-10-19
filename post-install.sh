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
    
    # Add to current session PATH
    export PATH="$HOME/.local/bin:$PATH"
    export PATH="$HOME/.cursor/bin:$PATH"
    export PATH="/usr/local/bin:$PATH"
    
    success "PATH updated for current session"
}

# Update shell configuration
update_shell_config() {
    info "📝 Updating shell configuration..."
    
    local shell_config=""
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        shell_config="$HOME/.zshrc"
    else
        shell_config="$HOME/.bashrc"
    fi
    
    # Add YADS and Cursor paths
    if ! grep -q "yads" "$shell_config" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_config"
        echo 'export PATH="$HOME/.cursor/bin:$PATH"' >> "$shell_config"
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
    
    # Fix current session
    fix_current_session
    echo
    
    # Update shell configuration
    update_shell_config
    echo
    
    # Test commands
    test_commands
    echo
    
    # Show next steps
    show_next_steps
}

# Run main function
main "$@"
