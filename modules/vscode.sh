#!/bin/bash

# YADS VS Code Server Module
# Handles VS Code Server configuration and management

set -euo pipefail

# Color setup
setup_colors() {
    if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;94m'      # Light blue instead of dark blue
        CYAN='\033[0;96m'      # Light cyan
        WHITE='\033[1;37m'     # Bright white for better contrast
        GRAY='\033[0;37m'      # Light gray for secondary text
        NC='\033[0m' # No Color
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

# Check if VS Code Server is installed
check_vscode_server() {
    if ! command -v code-server >/dev/null 2>&1; then
        error_exit "VS Code Server is not installed. Run 'yads install' first."
    fi
}

# Configure VS Code Server
configure_vscode() {
    info "💻 Configuring VS Code Server..."
    
    check_vscode_server
    
    local vscode_dir="/opt/vscode-server"
    local vscode_user="vscode"
    
    # Create VS Code Server configuration directory with proper permissions
    info "📁 Creating VS Code Server directories..."
    # Use vscode user's home directory instead of /opt/vscode-server
    local vscode_home="/home/$vscode_user"
    sudo -u "$vscode_user" mkdir -p "$vscode_home/.config/code-server"
    
    # Generate new password
    local password
    password=$(openssl rand -base64 32)
    
    # Create VS Code Server configuration with proper permissions
    info "📝 Creating VS Code Server configuration..."
    # Create config file as vscode user to avoid permission issues
    sudo -u "$vscode_user" tee "$vscode_home/.config/code-server/config.yaml" > /dev/null << EOF
bind-addr: 0.0.0.0:8080
auth: password
password: $password
cert: false
EOF
    
    # Set proper permissions
    chown "$vscode_user:$vscode_user" "$vscode_home/.config/code-server/config.yaml"
    chmod 600 "$vscode_home/.config/code-server/config.yaml"
    
    # Install useful extensions with proper Node.js environment
    info "Installing VS Code extensions..."
    
    # Use the vscode user's home directory and NVM setup
    sudo -u "$vscode_user" bash -c "
        export NVM_DIR='/home/vscode/.nvm'
        [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"
        code-server --install-extension ms-vscode.vscode-json
        code-server --install-extension bradlc.vscode-tailwindcss
        code-server --install-extension ms-vscode.vscode-typescript-next
        code-server --install-extension ms-vscode.vscode-php-debug
    " || warning "Extension installation had issues, but VS Code Server should still work"
    
    # Restart VS Code Server using official user service
    info "🔄 Restarting VS Code Server..."
    if [[ $EUID -eq 0 ]]; then
        # Running as root
        systemctl restart "code-server@$vscode_user"
    else
        # Running as regular user, use sudo
        sudo systemctl restart "code-server@$vscode_user"
    fi
    
    success "VS Code Server configured"
    info "Password: $password"
    info "Access: http://localhost:8080"
}

# Show VS Code Server status
show_status() {
    info "💻 VS Code Server Status:"
    
    if systemctl is-active --quiet "code-server@vscode"; then
        success "VS Code Server: Running"
        
        # Show password from vscode user's config
        if [[ -f "/home/vscode/.config/code-server/config.yaml" ]]; then
            local password
            password=$(grep "password:" /home/vscode/.config/code-server/config.yaml | cut -d' ' -f2)
            info "Password: $password"
        fi
        
        # Show access URL
        info "Access: http://localhost:8080"
        info "Remote access: https://code.remote.domain.tld (when tunnel is configured)"
    else
        info "VS Code Server: Stopped"
    fi
}

# Start VS Code Server
start_vscode() {
    info "🚀 Starting VS Code Server..."
    
    check_vscode_server
    
    if systemctl is-active --quiet "code-server@vscode"; then
        info "VS Code Server is already running"
        return
    fi
    
    systemctl start "code-server@vscode"
    systemctl enable "code-server@vscode"
    
    success "VS Code Server started"
}

# Stop VS Code Server
stop_vscode() {
    info "🛑 Stopping VS Code Server..."
    
    if ! systemctl is-active --quiet "code-server@vscode"; then
        info "VS Code Server is already stopped"
        return
    fi
    
    systemctl stop "code-server@vscode"
    systemctl disable "code-server@vscode"
    
    success "VS Code Server stopped"
}

# Restart VS Code Server
restart_vscode() {
    info "🔄 Restarting VS Code Server..."
    
    stop_vscode
    start_vscode
}

# Change password
change_password() {
    info "🔐 Changing VS Code Server password..."
    
    check_vscode_server
    
    local new_password
    new_password=$(openssl rand -base64 32)
    
    # Update password in vscode user's config
    local vscode_user="vscode"
    local vscode_home="/home/$vscode_user"
    
    # Update config file in vscode user's home
    sudo -u "$vscode_user" sed -i "s/password: .*/password: $new_password/" "$vscode_home/.config/code-server/config.yaml"
    
    # Restart service
    systemctl restart "code-server@$vscode_user"
    
    success "Password changed"
    info "New password: $new_password"
}

# Install extension
install_extension() {
    local extension="$1"
    
    if [[ -z "$extension" ]]; then
        error_exit "Extension name required"
    fi
    
    info "Installing extension: $extension"
    
    check_vscode_server
    
    local vscode_user="vscode"
    sudo -u "$vscode_user" code-server --install-extension "$extension"
    
    success "Extension installed: $extension"
}

# List installed extensions
list_extensions() {
    info "📦 Installed VS Code extensions:"
    
    check_vscode_server
    
    local vscode_user="vscode"
    sudo -u "$vscode_user" code-server --list-extensions
}

# Main VS Code function
vscode_main() {
    setup_colors
    
    case "${1:-}" in
        "")
            show_status
            info "Use 'yads vscode setup' to configure VS Code Server"
            ;;
        setup)
            configure_vscode
            ;;
        start)
            start_vscode
            ;;
        stop)
            stop_vscode
            ;;
        restart)
            restart_vscode
            ;;
        status)
            show_status
            ;;
        password)
            change_password
            ;;
        install)
            install_extension "${2:-}"
            ;;
        list)
            list_extensions
            ;;
        *)
            error_exit "Unknown VS Code option: $1"
            ;;
    esac
}
