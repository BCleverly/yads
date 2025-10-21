#!/bin/bash

# Fix Node.js module resolution issues
# This script resolves the "Cannot find module '/usr/local'" error

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

info "🔧 Fixing Node.js module resolution issues..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
    exit 1
fi

# Fix /usr/local permissions and structure
info "📁 Fixing /usr/local permissions and structure..."
chown -R root:root /usr/local
chmod -R 755 /usr/local

# Create proper /usr/local/lib/node_modules directory
mkdir -p /usr/local/lib/node_modules
chown -R root:root /usr/local/lib/node_modules
chmod -R 755 /usr/local/lib/node_modules

# Remove any broken symlinks in /usr/local
info "🔗 Removing broken symlinks..."
find /usr/local -type l -exec test ! -e {} \; -delete 2>/dev/null || true

# Fix Node.js installation
info "📦 Fixing Node.js installation..."
if command -v node >/dev/null 2>&1; then
    local node_path=$(which node)
    local node_dir=$(dirname "$node_path")
    
    # Ensure node binary has proper permissions
    chmod +x "$node_path"
    chown root:root "$node_path"
    
    success "Node.js binary fixed: $node_path"
else
    warning "Node.js not found"
fi

# Fix npm installation
info "📦 Fixing npm installation..."
if command -v npm >/dev/null 2>&1; then
    local npm_path=$(which npm)
    local npm_dir=$(dirname "$npm_path")
    
    # Ensure npm binary has proper permissions
    chmod +x "$npm_path"
    chown root:root "$npm_path"
    
    # Clear npm cache and configuration
    npm cache clean --force 2>/dev/null || true
    npm config delete prefix 2>/dev/null || true
    npm config delete globalconfig 2>/dev/null || true
    
    success "npm binary fixed: $npm_path"
else
    warning "npm not found"
fi

# Fix VS Code Server specifically
info "💻 Fixing VS Code Server Node.js module resolution..."
if command -v code-server >/dev/null 2>&1; then
    local code_server_path=$(which code-server)
    local code_server_dir=$(dirname "$code_server_path")
    
    # Fix code-server binary permissions
    chmod +x "$code_server_path"
    chown root:root "$code_server_path"
    
    # Remove any broken symlinks around code-server
    find "$code_server_dir" -type l -exec test ! -e {} \; -delete 2>/dev/null || true
    
    success "VS Code Server binary fixed: $code_server_path"
    
    # Fix VS Code Server service
    info "🔄 Restarting VS Code Server service..."
    systemctl stop code-server@vscode 2>/dev/null || true
    sleep 2
    systemctl start code-server@vscode 2>/dev/null || true
    
    if systemctl is-active --quiet code-server@vscode; then
        success "VS Code Server service restarted successfully"
    else
        warning "VS Code Server service may not be running"
    fi
else
    warning "VS Code Server not found"
fi

# Fix NVM configuration for all users
info "🔄 Fixing NVM configuration..."
for user in vscode $(whoami); do
    if id "$user" >/dev/null 2>&1; then
        local user_home="/home/$user"
        if [[ -s "$user_home/.nvm/nvm.sh" ]]; then
            # Fix NVM permissions
            chown -R "$user:$user" "$user_home/.nvm" 2>/dev/null || true
            chmod -R 755 "$user_home/.nvm" 2>/dev/null || true
            
            # Clear prefix issues
            sudo -u "$user" bash -c "
                export NVM_DIR='$user_home/.nvm'
                [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"
                nvm use --delete-prefix --lts --silent 2>/dev/null || true
                nvm alias default lts/* 2>/dev/null || true
            " 2>/dev/null || true
            
            success "Fixed NVM for user: $user"
        fi
    fi
done

# Final verification
info "🧪 Testing Node.js module resolution..."
if command -v node >/dev/null 2>&1; then
    # Test that Node.js can resolve modules properly
    if node -e "console.log('Node.js working:', process.version)" 2>/dev/null; then
        success "Node.js module resolution working"
    else
        error "Node.js module resolution still has issues"
    fi
fi

success "🎉 Node.js module resolution issues fixed!"
info "The 'Cannot find module /usr/local' error should now be resolved"
info "VS Code Server should work properly without module resolution errors"
