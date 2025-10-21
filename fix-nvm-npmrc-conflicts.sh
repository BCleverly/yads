#!/bin/bash

# Fix NVM and .npmrc configuration conflicts
# This script resolves the "globalconfig" and "prefix" setting conflicts

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
    log "${YELLOW}⚠️  Warning: $1${NC}"
}

error() {
    log "${RED}❌ Error: $1${NC}"
}

# Initialize colors
setup_colors

info "🔧 Fixing NVM and .npmrc configuration conflicts..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    error "This script should not be run as root"
    error "Run as your regular user to fix your personal .npmrc configuration"
    exit 1
fi

# Get user's home directory
user_home="$HOME"
npmrc_file="$user_home/.npmrc"

info "👤 Fixing configuration for user: $(whoami)"
info "📁 Home directory: $user_home"

# Check if .npmrc exists
if [[ -f "$npmrc_file" ]]; then
    info "📝 Found .npmrc file: $npmrc_file"
    
    # Show current .npmrc content
    info "Current .npmrc content:"
    cat "$npmrc_file" | sed 's/^/  /'
    echo
    
    # Backup the original .npmrc
    cp "$npmrc_file" "$npmrc_file.backup.$(date +%Y%m%d_%H%M%S)"
    success "Backed up original .npmrc file"
    
    # Remove problematic settings
    info "🔧 Removing conflicting settings from .npmrc..."
    
    # Remove globalconfig and prefix settings
    sed -i '/^globalconfig/d' "$npmrc_file"
    sed -i '/^prefix/d' "$npmrc_file"
    
    # Remove any empty lines at the end
    sed -i '/^$/N;/^\n$/d' "$npmrc_file"
    
    success "Removed conflicting settings from .npmrc"
    
    # Show updated .npmrc content
    info "Updated .npmrc content:"
    if [[ -s "$npmrc_file" ]]; then
        cat "$npmrc_file" | sed 's/^/  /'
    else
        info "  (file is now empty or only contains comments)"
    fi
    echo
    
else
    info "📝 No .npmrc file found, creating a clean one..."
    touch "$npmrc_file"
fi

# Set up NVM properly
info "🔄 Setting up NVM configuration..."

# Source NVM if available
if [[ -s "$user_home/.nvm/nvm.sh" ]]; then
    export NVM_DIR="$user_home/.nvm"
    source "$NVM_DIR/nvm.sh"
    success "NVM loaded successfully"
    
    # Use the delete-prefix option to clear any existing prefix
    info "🧹 Clearing NVM prefix settings..."
    
    # Get current Node version
    current_version=$(nvm current 2>/dev/null || echo "none")
    info "Current Node version: $current_version"
    
    if [[ "$current_version" != "none" && "$current_version" != "system" ]]; then
        # Use delete-prefix to clear the prefix
        nvm use --delete-prefix "$current_version" --silent 2>/dev/null || true
        success "Cleared prefix for version: $current_version"
    fi
    
    # Set up default Node version properly
    info "📦 Setting up Node.js versions..."
    
    # Install and use LTS version
    nvm install --lts --no-progress 2>/dev/null || true
    nvm use --lts --silent 2>/dev/null || true
    nvm alias default lts/* 2>/dev/null || true
    
    success "Node.js LTS version configured"
    
    # Verify Node.js and npm work
    info "🧪 Testing Node.js and npm..."
    
    if command -v node >/dev/null 2>&1; then
        node_version=$(node --version)
        success "Node.js working: $node_version"
    else
        warning "Node.js not found in PATH"
    fi
    
    if command -v npm >/dev/null 2>&1; then
        npm_version=$(npm --version)
        success "npm working: $npm_version"
    else
        warning "npm not found in PATH"
    fi
    
else
    warning "NVM not found in $user_home/.nvm/nvm.sh"
    info "You may need to install NVM first"
fi

# Clean up any global npm installations that might conflict
info "🧹 Cleaning up potential global npm conflicts..."

# Remove any global npm cache that might have permission issues
if command -v npm >/dev/null 2>&1; then
    # Clear npm cache
    npm cache clean --force 2>/dev/null || true
    
    # Reset npm configuration to defaults
    npm config delete prefix 2>/dev/null || true
    npm config delete globalconfig 2>/dev/null || true
    
    success "Cleaned up npm configuration"
fi

# Set up proper shell configuration
info "📝 Updating shell configuration..."

# Determine shell config file
shell_config=""
if [[ -n "${ZSH_VERSION:-}" ]]; then
    shell_config="$user_home/.zshrc"
elif [[ -n "${BASH_VERSION:-}" ]]; then
    shell_config="$user_home/.bashrc"
else
    shell_config="$user_home/.profile"
fi

# Add NVM configuration if not already present
if [[ -f "$shell_config" ]] && ! grep -q "NVM_DIR" "$shell_config"; then
    info "Adding NVM configuration to $shell_config..."
    cat >> "$shell_config" << 'EOF'

# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
    success "Added NVM configuration to $shell_config"
fi

# Final verification
info "🔍 Final verification..."

# Test that NVM works without warnings
if [[ -s "$user_home/.nvm/nvm.sh" ]]; then
    export NVM_DIR="$user_home/.nvm"
    source "$NVM_DIR/nvm.sh"
    
    # This should not produce the warning messages
    nvm current >/dev/null 2>&1 || true
    success "NVM is working without configuration conflicts"
else
    warning "NVM not properly installed"
fi

success "🎉 NVM and .npmrc configuration conflicts fixed!"
info "You may need to restart your terminal or run: source $shell_config"
info "If you still see warnings, try: nvm use --delete-prefix"
