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

# Fix Node.js module resolution issues
fix_node_module_resolution() {
    info "🔧 Fixing Node.js module resolution issues..."
    
    # Check if running as root or with sudo
    if [[ $EUID -ne 0 ]]; then
        warning "VS Code Server module requires root privileges for system fixes"
        warning "Please run: sudo yads vscode setup"
        return 1
    fi
    
    # Fix /usr/local permissions
    chown -R root:root /usr/local 2>/dev/null || true
    chmod -R 755 /usr/local 2>/dev/null || true
    
    # Remove broken symlinks
    find /usr/local -type l -exec test ! -e {} \; -delete 2>/dev/null || true
    find /usr/bin -type l -exec test ! -e {} \; -delete 2>/dev/null || true
    
    # Fix Node.js and npm permissions
    if command -v node >/dev/null 2>&1; then
        local node_path=$(which node)
        if [[ -f "$node_path" ]]; then
            chmod +x "$node_path" 2>/dev/null || warning "Could not change permissions for $node_path"
            chown root:root "$node_path" 2>/dev/null || warning "Could not change ownership for $node_path"
        fi
    fi
    
    if command -v npm >/dev/null 2>&1; then
        local npm_path=$(which npm)
        if [[ -f "$npm_path" ]]; then
            chmod +x "$npm_path" 2>/dev/null || warning "Could not change permissions for $npm_path"
            chown root:root "$npm_path" 2>/dev/null || warning "Could not change ownership for $npm_path"
        fi
        
        # Clear npm configuration issues
        npm cache clean --force 2>/dev/null || true
        npm config delete prefix 2>/dev/null || true
        npm config delete globalconfig 2>/dev/null || true
    fi
    
    # Fix VS Code Server binary permissions
    if command -v code-server >/dev/null 2>&1; then
        local code_server_path=$(which code-server)
        if [[ -f "$code_server_path" ]]; then
            chmod +x "$code_server_path" 2>/dev/null || warning "Could not change permissions for $code_server_path"
            chown root:root "$code_server_path" 2>/dev/null || warning "Could not change ownership for $code_server_path"
        fi
        
        # Remove broken symlinks around code-server
        local code_server_dir=$(dirname "$code_server_path")
        find "$code_server_dir" -type l -exec test ! -e {} \; -delete 2>/dev/null || true
    fi
    
    # Fix NVM configuration for vscode user
    if id vscode >/dev/null 2>&1; then
        local vscode_home="/home/vscode"
        if [[ -s "$vscode_home/.nvm/nvm.sh" ]]; then
            chown -R vscode:vscode "$vscode_home/.nvm" 2>/dev/null || true
            chmod -R 755 "$vscode_home/.nvm" 2>/dev/null || true
            
            # Fix .npmrc conflicts for vscode user
            local npmrc_file="$vscode_home/.npmrc"
            if [[ -f "$npmrc_file" ]]; then
                # Backup original .npmrc
                cp "$npmrc_file" "$npmrc_file.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
                
                # Remove conflicting settings
                sudo -u vscode sed -i '/^globalconfig/d' "$npmrc_file" 2>/dev/null || true
                sudo -u vscode sed -i '/^prefix/d' "$npmrc_file" 2>/dev/null || true
                sudo -u vscode sed -i '/^$/N;/^\n$/d' "$npmrc_file" 2>/dev/null || true
            fi
            
            # Clear NVM prefix issues for all installed versions
            sudo -u vscode bash -c "
                export NVM_DIR='$vscode_home/.nvm'
                [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"
                
                # Clear prefix for all installed versions
                nvm list --no-alias | grep -E '^[[:space:]]*v[0-9]' | while read -r version; do
                    version=\$(echo \$version | tr -d '[:space:]')
                    nvm use --delete-prefix \"\$version\" --silent 2>/dev/null || true
                done
                
                # Set default and use LTS
                nvm use --delete-prefix --lts --silent 2>/dev/null || true
                nvm alias default lts/* 2>/dev/null || true
            " 2>/dev/null || true
        fi
    fi
    
    success "Node.js module resolution issues fixed"
}

# Configure VS Code Server
configure_vscode() {
    info "💻 Configuring VS Code Server..."
    
    # Fix Node.js module resolution first
    if ! fix_node_module_resolution; then
        warning "Some system fixes failed, but continuing with VS Code Server setup..."
    fi
    
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
    
    # Set proper permissions (file already owned by vscode user)
    sudo -u "$vscode_user" chmod 600 "$vscode_home/.config/code-server/config.yaml"
    
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
    
    # Get server IP for remote access
    local server_ip
    server_ip=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    info "Access: http://$server_ip:8080"
    info "Local access: http://localhost:8080"
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
        local server_ip
        server_ip=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
        info "Access: http://$server_ip:8080"
        info "Local access: http://localhost:8080"
        info "Remote access: https://code.remote.domain.tld (when tunnel is configured)"
    else
        info "VS Code Server: Stopped"
    fi
}

# Start VS Code Server
start_vscode() {
    info "🚀 Starting VS Code Server..."
    
    # Fix Node.js module resolution first
    if ! fix_node_module_resolution; then
        warning "Some system fixes failed, but continuing with VS Code Server start..."
    fi
    
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
