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
    if [[ $EUID -eq 0 ]]; then
        # Running as root
        mkdir -p "$vscode_dir/.config/code-server"
    else
        # Running as regular user, use sudo
        info "Using sudo to create VS Code Server directories..."
        sudo mkdir -p "$vscode_dir/.config/code-server"
    fi
    
    # Generate new password if needed
    local password
    if [[ ! -f "$vscode_dir/.password" ]]; then
        password=$(openssl rand -base64 32)
        if [[ $EUID -eq 0 ]]; then
            # Running as root
            echo "$password" > "$vscode_dir/.password"
            chown "$vscode_user:$vscode_user" "$vscode_dir/.password"
            chmod 600 "$vscode_dir/.password"
        else
            # Running as regular user, use sudo
            echo "$password" | sudo tee "$vscode_dir/.password" > /dev/null
            sudo chown "$vscode_user:$vscode_user" "$vscode_dir/.password"
            sudo chmod 600 "$vscode_dir/.password"
        fi
    else
        if [[ $EUID -eq 0 ]]; then
            password=$(cat "$vscode_dir/.password")
        else
            password=$(sudo cat "$vscode_dir/.password")
        fi
    fi
    
    # Create VS Code Server configuration with proper permissions
    info "📝 Creating VS Code Server configuration..."
    if [[ $EUID -eq 0 ]]; then
        # Running as root
        cat > "$vscode_dir/.config/code-server/config.yaml" << EOF
bind-addr: 0.0.0.0:8080
auth: password
password: $password
cert: false
EOF
    else
        # Running as regular user, use sudo
        sudo tee "$vscode_dir/.config/code-server/config.yaml" > /dev/null << EOF
bind-addr: 0.0.0.0:8080
auth: password
password: $password
cert: false
EOF
    fi
    
    # Set proper permissions
    if [[ $EUID -eq 0 ]]; then
        # Running as root
        chown -R "$vscode_user:$vscode_user" "$vscode_dir/.config"
        chmod 600 "$vscode_dir/.config/code-server/config.yaml"
    else
        # Running as regular user, use sudo
        sudo chown -R "$vscode_user:$vscode_user" "$vscode_dir/.config"
        sudo chmod 600 "$vscode_dir/.config/code-server/config.yaml"
    fi
    
    # Install useful extensions with proper Node.js environment
    info "Installing VS Code extensions..."
    
    # Ensure Node.js is available for vscode user
    local vscode_node_path
    vscode_node_path=$(sudo -u "$vscode_user" bash -c 'export NVM_DIR="/opt/vscode-server/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; which node' 2>/dev/null || echo "")
    
    if [[ -n "$vscode_node_path" ]]; then
        # Set up environment for vscode user
        sudo -u "$vscode_user" bash -c "
            export NVM_DIR='/opt/vscode-server/.nvm'
            [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"
            code-server --install-extension ms-vscode.vscode-json
            code-server --install-extension bradlc.vscode-tailwindcss
            code-server --install-extension ms-vscode.vscode-typescript-next
            code-server --install-extension ms-vscode.vscode-php-debug
        "
    else
        warning "Node.js not found for vscode user, skipping extension installation"
        warning "VS Code Server will work but extensions may not install properly"
    fi
    
    # Restart VS Code Server
    info "🔄 Restarting VS Code Server..."
    if [[ $EUID -eq 0 ]]; then
        # Running as root
        systemctl restart vscode-server
    else
        # Running as regular user, use sudo
        sudo systemctl restart vscode-server
    fi
    
    success "VS Code Server configured"
    info "Password: $password"
    info "Access: http://localhost:8080"
}

# Show VS Code Server status
show_status() {
    info "💻 VS Code Server Status:"
    
    if systemctl is-active --quiet vscode-server; then
        success "VS Code Server: Running"
        
        # Show password
        if [[ -f "/opt/vscode-server/.password" ]]; then
            local password
            password=$(cat /opt/vscode-server/.password)
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
    
    if systemctl is-active --quiet vscode-server; then
        info "VS Code Server is already running"
        return
    fi
    
    systemctl start vscode-server
    systemctl enable vscode-server
    
    success "VS Code Server started"
}

# Stop VS Code Server
stop_vscode() {
    info "🛑 Stopping VS Code Server..."
    
    if ! systemctl is-active --quiet vscode-server; then
        info "VS Code Server is already stopped"
        return
    fi
    
    systemctl stop vscode-server
    systemctl disable vscode-server
    
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
    
    # Update password in config
    local vscode_dir="/opt/vscode-server"
    local vscode_user="vscode"
    
    # Update config file
    sed -i "s/password: .*/password: $new_password/" "$vscode_dir/.config/code-server/config.yaml"
    
    # Update password file
    echo "$new_password" > "$vscode_dir/.password"
    chown "$vscode_user:$vscode_user" "$vscode_dir/.password"
    chmod 600 "$vscode_dir/.password"
    
    # Restart service
    systemctl restart vscode-server
    
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
