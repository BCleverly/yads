#!/bin/bash

# YADS Installation Script
# Remote PHP Web Development Server with Cloudflared Tunnels

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

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root or with sudo"
    fi
}

# Detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS="$ID"
        OS_VERSION="$VERSION_ID"
    elif [[ -f /etc/redhat-release ]]; then
        OS="rhel"
        OS_VERSION=$(cat /etc/redhat-release | grep -oE '[0-9]+' | head -1)
    else
        error_exit "Unsupported operating system"
    fi
    
    info "Detected OS: $OS $OS_VERSION"
}

# Update system packages
update_system() {
    info "🔄 Updating system packages..."
    
    case "$OS" in
        ubuntu|debian)
            apt-get update
            apt-get upgrade -y
            apt-get install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
            ;;
        centos|rhel|fedora)
            if command -v dnf >/dev/null 2>&1; then
                dnf update -y
                dnf install -y curl wget git unzip
            else
                yum update -y
                yum install -y curl wget git unzip
            fi
            ;;
        arch)
            pacman -Syu --noconfirm
            pacman -S --noconfirm curl wget git unzip
            ;;
        *)
            error_exit "Unsupported OS: $OS"
            ;;
    esac
    
    success "System packages updated"
}

# Install Docker
install_docker() {
    info "🐳 Installing Docker..."
    
    if command -v docker >/dev/null 2>&1; then
        info "Docker already installed"
        return
    fi
    
    # Use official Docker installation script
    # This follows the official Docker installation guide: https://docs.docker.com/engine/install/
    info "Using official Docker installation script..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    
    # Clean up
    rm get-docker.sh
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    # Add current user to docker group (if not root)
    if [[ "$SUDO_USER" != "" ]]; then
        usermod -aG docker "$SUDO_USER"
    fi
    
    success "Docker installed and started"
}

# Install NVM and Node.js
install_nodejs() {
    info "📦 Installing NVM and Node.js..."
    
    # Determine the actual user's home directory (handle sudo case)
    local user_home=""
    if [[ -n "${SUDO_USER:-}" ]]; then
        # Running with sudo, use the original user's home
        user_home="/home/$SUDO_USER"
        info "Installing for user: $SUDO_USER in $user_home"
    else
        # Running as regular user
        user_home="$HOME"
        info "Installing for current user in $user_home"
    fi
    
    # Check if NVM is already installed for the user
    if [[ -d "$user_home/.nvm" ]] && sudo -u "$SUDO_USER" bash -c 'command -v nvm >/dev/null 2>&1' 2>/dev/null; then
        info "NVM already installed for user"
        # Source NVM to make it available
        export NVM_DIR="$user_home/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    else
        info "Installing NVM for user..."
        
        # Install NVM for the actual user (not root)
        if [[ -n "${SUDO_USER:-}" ]]; then
            # Running with sudo, install for the original user
            sudo -u "$SUDO_USER" bash -c '
                curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
            '
        else
            # Running as regular user
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        fi
        
        # Source NVM to make it available in current session
        export NVM_DIR="$user_home/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
        
        success "NVM installed successfully for user"
    fi
    
    # Install latest LTS Node.js for the user
    info "Installing latest LTS Node.js for user..."
    if [[ -n "${SUDO_USER:-}" ]]; then
        # Running with sudo, install Node.js for the original user
        sudo -u "$SUDO_USER" bash -c "
            export NVM_DIR='$user_home/.nvm'
            [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"
            nvm install --lts || nvm install node
            nvm use --lts || nvm use node
            nvm alias default lts/* || nvm alias default node
        "
    else
        # Running as regular user
        nvm install --lts || nvm install node
        nvm use --lts || nvm use node
        nvm alias default lts/* || nvm alias default node
    fi
    
    # Verify installation
    if [[ -n "${SUDO_USER:-}" ]]; then
        local node_version=$(sudo -u "$SUDO_USER" bash -c "export NVM_DIR='$user_home/.nvm'; [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"; node --version")
        local npm_version=$(sudo -u "$SUDO_USER" bash -c "export NVM_DIR='$user_home/.nvm'; [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"; npm --version")
    else
        local node_version=$(node --version)
        local npm_version=$(npm --version)
    fi
    
    success "Node.js $node_version and npm $npm_version installed for user"
    
    # Install global packages useful for development
    info "Installing global npm packages for user..."
    if [[ -n "${SUDO_USER:-}" ]]; then
        sudo -u "$SUDO_USER" bash -c "
            export NVM_DIR='$user_home/.nvm'
            [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"
            npm install -g yarn pnpm
        "
    else
        npm install -g yarn pnpm
    fi
    
    # Add NVM to shell configuration for the user
    local shell_config=""
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        shell_config="$user_home/.zshrc"
    else
        shell_config="$user_home/.bashrc"
    fi
    
    # Add NVM to user's shell config if not already there
    if ! grep -q "NVM_DIR" "$shell_config" 2>/dev/null; then
        cat >> "$shell_config" << EOF

# NVM Configuration
export NVM_DIR="$user_home/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"
EOF
        info "Added NVM to $shell_config"
    fi
    
    # Create symlinks for system-wide access using user's Node.js
    if [[ -n "${SUDO_USER:-}" ]]; then
        # Get the user's Node.js paths
        local user_node_path=$(sudo -u "$SUDO_USER" bash -c "export NVM_DIR='$user_home/.nvm'; [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"; which node")
        local user_npm_path=$(sudo -u "$SUDO_USER" bash -c "export NVM_DIR='$user_home/.nvm'; [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"; which npm")
        local user_yarn_path=$(sudo -u "$SUDO_USER" bash -c "export NVM_DIR='$user_home/.nvm'; [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"; which yarn" 2>/dev/null || echo "")
        local user_pnpm_path=$(sudo -u "$SUDO_USER" bash -c "export NVM_DIR='$user_home/.nvm'; [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"; which pnpm" 2>/dev/null || echo "")
        
        # Create symlinks
        ln -sf "$user_node_path" /usr/local/bin/node
        ln -sf "$user_npm_path" /usr/local/bin/npm
        [[ -n "$user_yarn_path" ]] && ln -sf "$user_yarn_path" /usr/local/bin/yarn
        [[ -n "$user_pnpm_path" ]] && ln -sf "$user_pnpm_path" /usr/local/bin/pnpm
    else
        # Running as regular user
        ln -sf "$(which node)" /usr/local/bin/node
        ln -sf "$(which npm)" /usr/local/bin/npm
        ln -sf "$(which yarn)" /usr/local/bin/yarn 2>/dev/null || true
        ln -sf "$(which pnpm)" /usr/local/bin/pnpm 2>/dev/null || true
    fi
    
    success "Node.js ecosystem installed and configured"
}

# Install VS Code Server
install_vscode_server() {
    info "💻 Installing VS Code Server..."
    
    local vscode_dir="/opt/vscode-server"
    local vscode_user="vscode"
    
    # Create vscode user
    if ! id "$vscode_user" >/dev/null 2>&1; then
        useradd -r -s /bin/bash -d "$vscode_dir" -m "$vscode_user"
    fi
    
    # Create vscode directory
    mkdir -p "$vscode_dir"
    chown -R "$vscode_user:$vscode_user" "$vscode_dir"
    
    # Ensure NVM is available for vscode user
    info "Setting up NVM for vscode user..."
    sudo -u "$vscode_user" bash -c '
        export NVM_DIR="/opt/vscode-server/.nvm"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install --lts || nvm install node
        nvm use --lts || nvm use node
    ' || warning "NVM setup for vscode user had issues, but continuing..."
    
    # Create system-wide Node.js symlinks for VS Code Server
    info "Creating system-wide Node.js symlinks..."
    local vscode_node_path
    vscode_node_path=$(sudo -u "$vscode_user" bash -c 'export NVM_DIR="/opt/vscode-server/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; which node' 2>/dev/null || echo "")
    
    if [[ -n "$vscode_node_path" ]] && [[ -f "$vscode_node_path" ]]; then
        # Create symlinks for system-wide access
        ln -sf "$vscode_node_path" /usr/local/bin/node
        ln -sf "$(dirname "$vscode_node_path")/npm" /usr/local/bin/npm 2>/dev/null || true
        
        # Create the directory that code-server expects
        mkdir -p /usr/local/lib
        ln -sf "$vscode_node_path" /usr/local/lib/node
        
        success "Node.js symlinks created for VS Code Server"
    else
        warning "Could not find Node.js for vscode user, VS Code Server may not work properly"
    fi
    
    # Install VS Code Server using official install script
    info "Installing VS Code Server using official install script..."
    
    # Use the official code-server install script
    # This handles all the complexity and follows their recommended approach
    curl -fsSL https://code-server.dev/install.sh | sh
    
    # Verify installation
    if ! command -v code-server >/dev/null 2>&1; then
        error_exit "VS Code Server installation failed"
    fi
    
    success "VS Code Server installed successfully"
    
    # Follow official code-server installation approach
    # The official install script creates a user service, so we'll do the same
    # But we need to set up the vscode user properly first
    
    # Create vscode user's home directory and config
    mkdir -p "/home/$vscode_user/.config"
    chown -R "$vscode_user:$vscode_user" "/home/$vscode_user"
    
    # Set up NVM for vscode user in their home directory
    info "Setting up NVM for vscode user..."
    sudo -u "$vscode_user" bash -c '
        # Create NVM directory first
        mkdir -p /home/vscode/.nvm
        
        # Install NVM
        export NVM_DIR="/home/vscode/.nvm"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        
        # Source NVM and install Node.js
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install --lts || nvm install node
        nvm use --lts || nvm use node
        nvm alias default lts/* || nvm alias default node
    ' || warning "NVM setup for vscode user had issues, but continuing..."
    
    # Create VS Code Server configuration for vscode user
    sudo -u "$vscode_user" mkdir -p "/home/$vscode_user/.config/code-server"
    
    # Generate password for vscode user
    local password
    password=$(openssl rand -base64 32)
    
    # Create config file as vscode user to avoid permission issues
    sudo -u "$vscode_user" tee "/home/$vscode_user/.config/code-server/config.yaml" > /dev/null << EOF
bind-addr: 0.0.0.0:8080
auth: password
password: $password
cert: false
EOF
    
    # Set proper permissions
    chown "$vscode_user:$vscode_user" "/home/$vscode_user/.config/code-server/config.yaml"
    chmod 600 "/home/$vscode_user/.config/code-server/config.yaml"
    
    # Enable and start the official user service
    systemctl enable "code-server@$vscode_user"
    systemctl start "code-server@$vscode_user"
    
    # Ensure VS Code Server has proper permissions
    info "🔧 Ensuring VS Code Server permissions are correct..."
    chown -R "$vscode_user:$vscode_user" "/home/$vscode_user"
    chmod -R 755 "/home/$vscode_user"
    chmod 600 "/home/$vscode_user/.config/code-server/config.yaml"
    
    # Fix any Node.js permission issues
    if [[ -d "/home/$vscode_user/.nvm" ]]; then
        chown -R "$vscode_user:$vscode_user" "/home/$vscode_user/.nvm"
        chmod -R 755 "/home/$vscode_user/.nvm"
    fi
    
    success "VS Code Server permissions fixed"
    
    success "VS Code Server installed"
    info "VS Code Server password: $password"
    info "VS Code Server will be accessible at: http://localhost:8080"
}

# Install Cloudflared
install_cloudflared() {
    info "☁️  Installing Cloudflared..."
    
    if command -v cloudflared >/dev/null 2>&1; then
        info "Cloudflared already installed"
        return
    fi
    
    # Download and install cloudflared
    case "$(uname -m)" in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="arm"
            ;;
        *)
            error_exit "Unsupported architecture: $(uname -m)"
            ;;
    esac
    
    local latest_version
    latest_version=$(curl -s https://api.github.com/repos/cloudflare/cloudflared/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    
    wget "https://github.com/cloudflare/cloudflared/releases/download/${latest_version}/cloudflared-linux-${ARCH}"
    mv "cloudflared-linux-${ARCH}" /usr/local/bin/cloudflared
    chmod +x /usr/local/bin/cloudflared
    
    success "Cloudflared installed"
}

# Install PHP and Composer
install_php() {
    info "🐘 Installing PHP and Composer..."
    
    case "$OS" in
        ubuntu|debian)
            # Add Ondřej Surý's PPA for multiple PHP versions
            add-apt-repository ppa:ondrej/php -y
            apt-get update
            apt-get install -y php8.4 php8.4-cli php8.4-fpm php8.4-mysql php8.4-pgsql php8.4-curl php8.4-gd php8.4-mbstring php8.4-xml php8.4-zip php8.4-bcmath php8.4-intl php8.4-redis
            ;;
        centos|rhel|fedora)
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y php php-cli php-fpm php-mysqlnd php-pgsql php-curl php-gd php-mbstring php-xml php-zip php-bcmath php-intl php-redis
            else
                yum install -y php php-cli php-fpm php-mysqlnd php-pgsql php-curl php-gd php-mbstring php-xml php-zip php-bcmath php-intl php-redis
            fi
            ;;
        arch)
            pacman -S --noconfirm php php-fpm php-gd php-intl php-redis
            ;;
    esac
    
    # Install Composer
    if ! command -v composer >/dev/null 2>&1; then
        # Download Composer installer
        curl -sS https://getcomposer.org/installer -o composer-setup.php
        
        # Install Composer with proper handling for root user
        if [[ $EUID -eq 0 ]]; then
            # Running as root, install to /usr/local/bin
            php composer-setup.php --install-dir=/usr/local/bin --filename=composer
        else
            # Running as regular user
            php composer-setup.php
            mv composer.phar /usr/local/bin/composer
        fi
        
        chmod +x /usr/local/bin/composer
        rm -f composer-setup.php
    fi
    
    # Install Laravel installer (skip if running as root to avoid security warning)
    if [[ $EUID -ne 0 ]]; then
        composer global require laravel/installer
    else
        info "Skipping Laravel installer installation (running as root)"
        info "You can install it later with: composer global require laravel/installer"
    fi
    
    success "PHP and Composer installed"
}

# Install web servers
install_webservers() {
    info "🌐 Installing web servers..."
    
    case "$OS" in
        ubuntu|debian)
            apt-get install -y nginx apache2
            ;;
        centos|rhel|fedora)
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y nginx httpd
            else
                yum install -y nginx httpd
            fi
            ;;
        arch)
            pacman -S --noconfirm nginx apache
            ;;
    esac
    
    success "Web servers installed"
}

# Install databases
install_databases() {
    info "🗄️  Installing databases..."
    
    case "$OS" in
        ubuntu|debian)
            apt-get install -y mysql-server postgresql postgresql-contrib redis-server
            ;;
        centos|rhel|fedora)
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y mysql-server postgresql postgresql-server redis
            else
                yum install -y mysql-server postgresql postgresql-server redis
            fi
            ;;
        arch)
            pacman -S --noconfirm mysql postgresql redis
            ;;
    esac
    
    # Start and enable services
    systemctl start mysql redis-server
    systemctl enable mysql redis-server
    
    # Initialize PostgreSQL
    if [[ "$OS" == "arch" ]]; then
        sudo -u postgres initdb -D /var/lib/postgres/data
    fi
    systemctl start postgresql
    systemctl enable postgresql
    
    success "Databases installed and started"
}

# Install GitHub CLI
install_gh_cli() {
    info "🐙 Installing GitHub CLI..."
    
    if command -v gh >/dev/null 2>&1; then
        info "GitHub CLI already installed"
        return
    fi
    
    # Use official GitHub CLI installation method
    # This follows the official GitHub CLI installation guide
    case "$OS" in
        ubuntu|debian)
            # Official GitHub CLI installation for Debian/Ubuntu
            type -p curl >/dev/null || (apt-get update && apt-get install curl -y)
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            apt-get update
            apt-get install -y gh
            ;;
        centos|rhel|fedora)
            # Official GitHub CLI installation for RHEL-based systems
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y 'https://github.com/cli/cli/releases/download/v2.40.1/gh_2.40.1_linux_amd64.rpm'
            else
                yum install -y 'https://github.com/cli/cli/releases/download/v2.40.1/gh_2.40.1_linux_amd64.rpm'
            fi
            ;;
        arch)
            # Official GitHub CLI installation for Arch Linux
            pacman -S --noconfirm github-cli
            ;;
    esac
    
    success "GitHub CLI installed"
}


# Install Cursor CLI
install_cursor_cli() {
    info "🎯 Installing Cursor CLI..."
    
    if command -v cursor-agent >/dev/null 2>&1; then
        info "Cursor CLI already installed"
        return
    fi
    
    # Determine user's home directory (handle sudo case)
    local user_home=""
    if [[ -n "${SUDO_USER:-}" ]]; then
        # Running with sudo, use the original user's home
        user_home="/home/$SUDO_USER"
    else
        # Running as regular user
        user_home="$HOME"
    fi
    
    # Install Cursor CLI using the official installer for the correct user
    if [[ -n "${SUDO_USER:-}" ]]; then
        # Running with sudo, install for the original user
        sudo -u "$SUDO_USER" bash -c 'curl https://cursor.com/install -fsS | bash'
    else
        # Running as regular user
        curl https://cursor.com/install -fsS | bash
    fi
    
    # Add to PATH if not already there
    if ! command -v cursor-agent >/dev/null 2>&1; then
        # Try to find the installation directory
        local cursor_path=""
        if [[ -f "$user_home/.cursor/bin/cursor-agent" ]]; then
            cursor_path="$user_home/.cursor/bin"
        elif [[ -f "/usr/local/bin/cursor-agent" ]]; then
            cursor_path="/usr/local/bin"
        fi
        
        if [[ -n "$cursor_path" ]]; then
            # Add to system PATH
            echo "export PATH=\"$cursor_path:\$PATH\"" >> /etc/environment
            export PATH="$cursor_path:$PATH"
        fi
    fi
    
    # Ensure cursor-agent is ready and waiting on CLI
    info "🎯 Setting up Cursor Agent for CLI use..."
    
    # Add to user's shell configuration (handle sudo case)
    local user_home=""
    local shell_config=""
    
    if [[ -n "${SUDO_USER:-}" ]]; then
        # Running with sudo, use the original user's home
        user_home="/home/$SUDO_USER"
    else
        # Running as regular user
        user_home="$HOME"
    fi
    
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        shell_config="$user_home/.zshrc"
    else
        shell_config="$user_home/.bashrc"
    fi
    
    # Add Cursor Agent to PATH in user's shell config
    if ! grep -q "cursor-agent" "$shell_config" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_config"
        echo 'export PATH="$HOME/.cursor/bin:$PATH"' >> "$shell_config"
        info "Added Cursor Agent to PATH in $shell_config"
    fi
    
    # Create a symlink in /usr/local/bin for system-wide access
    if [[ -f "$HOME/.cursor/bin/cursor-agent" ]]; then
        ln -sf "$HOME/.cursor/bin/cursor-agent" /usr/local/bin/cursor-agent
        chmod +x /usr/local/bin/cursor-agent
        info "Created system-wide symlink for cursor-agent"
    fi
    
    # Test cursor-agent availability
    if command -v cursor-agent >/dev/null 2>&1; then
        success "Cursor Agent is ready and available on CLI"
        info "You can now use: cursor-agent"
    else
        warning "Cursor Agent may need a shell restart to be available"
        info "Run: source $shell_config"
    fi
    
    success "Cursor CLI installed"
}

# Create YADS directory structure
create_yads_structure() {
    info "📁 Creating YADS directory structure..."
    
    local yads_dir="/opt/yads"
    local projects_dir="/var/www/projects"
    local script_dir=""
    
    # Get script directory with better detection
    if [[ -n "${BASH_SOURCE[0]}" ]]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    else
        script_dir="$(pwd)"
    fi
    
    # Debug: Show what directory we're looking in
    info "Looking for YADS files in: $script_dir"
    
    mkdir -p "$yads_dir"/{modules,config,logs}
    mkdir -p "$projects_dir"
    mkdir -p /etc/yads
    
    # Set up comprehensive permissions for web development
    info "🔐 Setting up comprehensive permissions for web development..."
    
    # Get the current user (the one who will be developing)
    local dev_user=""
    if [[ -n "${SUDO_USER:-}" ]]; then
        dev_user="$SUDO_USER"
    else
        dev_user="$(whoami)"
    fi
    
    # Create a web development group
    if ! getent group webdev >/dev/null 2>&1; then
        groupadd webdev
        success "Created webdev group"
    else
        info "webdev group already exists"
    fi
    
    # Add the development user to the webdev group
    usermod -a -G webdev "$dev_user"
    success "Added $dev_user to webdev group"
    
    # Set up VS Code Server permissions
    info "💻 Setting up VS Code Server permissions..."
    
    # Add vscode user to webdev group if it exists
    if id vscode >/dev/null 2>&1; then
        usermod -a -G webdev vscode
        success "Added vscode user to webdev group"
    fi
    
    # Set proper ownership and permissions for projects directory
    chown -R "$dev_user:webdev" "$projects_dir"
    chmod -R 775 "$projects_dir"
    
    # Set up proper permissions for web server access
    # Allow webdev group to write to projects directory
    if command -v setfacl >/dev/null 2>&1; then
        setfacl -R -m g:webdev:rwx "$projects_dir"
        setfacl -R -d -m g:webdev:rwx "$projects_dir"
        success "ACL permissions set for webdev group"
    else
        warning "setfacl not available, using standard permissions"
    fi
    
    # Ensure web server can read the projects
    chmod 755 "$projects_dir"
    
    # Set up web server permissions
    info "🌐 Setting up web server permissions..."
    
    # Configure Nginx to run as webdev group
    if command -v nginx >/dev/null 2>&1; then
        # Update nginx.conf to run as webdev group
        sed -i 's/user www-data;/user webdev;/' /etc/nginx/nginx.conf 2>/dev/null || true
        success "Nginx configured for webdev group"
    fi
    
    # Configure PHP-FPM to run as webdev group
    if command -v php-fpm8.4 >/dev/null 2>&1; then
        local pool_file="/etc/php/8.4/fpm/pool.d/www.conf"
        if [[ -f "$pool_file" ]]; then
            sed -i 's/group = www-data/group = webdev/' "$pool_file"
            sed -i 's/user = www-data/user = webdev/' "$pool_file"
            success "PHP-FPM configured for webdev group"
        fi
    fi
    
    # Set up development tools permissions
    info "🛠️  Setting up development tools permissions..."
    
    # Node.js and npm permissions
    if command -v node >/dev/null 2>&1; then
        # Set up npm global directory for the development user
        local npm_dir="/home/$dev_user/.npm-global"
        mkdir -p "$npm_dir"
        chown -R "$dev_user:webdev" "$npm_dir"
        
        # Configure npm to use the global directory
        sudo -u "$dev_user" npm config set prefix "$npm_dir" 2>/dev/null || true
        success "Node.js permissions configured"
    fi
    
    # Composer permissions
    if command -v composer >/dev/null 2>&1; then
        # Set up composer cache directory
        local composer_dir="/home/$dev_user/.composer"
        mkdir -p "$composer_dir"
        chown -R "$dev_user:webdev" "$composer_dir"
        success "Composer permissions configured"
    fi
    
    # Create a test project to verify permissions
    info "🧪 Creating test project to verify permissions..."
    local test_project="/var/www/projects/permission-test"
    
    # Create test project as development user
    sudo -u "$dev_user" mkdir -p "$test_project"
    sudo -u "$dev_user" tee "$test_project/index.php" > /dev/null << 'EOF'
<?php
echo "<h1>Permission Test</h1>";
echo "<p>User: " . get_current_user() . "</p>";
echo "<p>Group: " . posix_getgrgid(posix_getgid())['name'] . "</p>";
echo "<p>Document Root: " . $_SERVER['DOCUMENT_ROOT'] . "</p>";
echo "<p>PHP Version: " . phpversion() . "</p>";
echo "<p>✅ Permissions working correctly!</p>";
?>
EOF
    
    # Set proper permissions
    chown -R "$dev_user:webdev" "$test_project"
    chmod -R 775 "$test_project"
    
    # Test write permissions
    if sudo -u "$dev_user" touch "$test_project/test-write.txt" 2>/dev/null; then
        success "Write permissions working for $dev_user"
        rm -f "$test_project/test-write.txt"
    else
        error "Write permissions not working for $dev_user"
    fi
    
    success "Comprehensive permissions set up for user: $dev_user"
    success "Projects directory: $projects_dir (owned by $dev_user:webdev)"
    
    # Try multiple locations for YADS files
    local found_yads=false
    local yads_script=""
    local modules_dir=""
    
    # Check current script directory first
    if [[ -f "$script_dir/yads" ]] && [[ -d "$script_dir/modules" ]]; then
        yads_script="$script_dir/yads"
        modules_dir="$script_dir/modules"
        found_yads=true
        info "Found YADS files in script directory: $script_dir"
    fi
    
    # If not found and running with sudo, try user's home directory
    if [[ "$found_yads" == false ]] && [[ -n "${SUDO_USER:-}" ]]; then
        local user_home="/home/$SUDO_USER"
        local user_yads_dir="$user_home/yads"
        
        info "Trying user's YADS directory: $user_yads_dir"
        
        if [[ -f "$user_yads_dir/yads" ]] && [[ -d "$user_yads_dir/modules" ]]; then
            yads_script="$user_yads_dir/yads"
            modules_dir="$user_yads_dir/modules"
            found_yads=true
            info "Found YADS files in user directory: $user_yads_dir"
        fi
    fi
    
    # If still not found, try current working directory
    if [[ "$found_yads" == false ]]; then
        local cwd="$(pwd)"
        info "Trying current working directory: $cwd"
        
        if [[ -f "$cwd/yads" ]] && [[ -d "$cwd/modules" ]]; then
            yads_script="$cwd/yads"
            modules_dir="$cwd/modules"
            found_yads=true
            info "Found YADS files in current directory: $cwd"
        fi
    fi
    
    if [[ "$found_yads" == false ]]; then
        error_exit "YADS files not found. Please run from the YADS repository directory or ensure yads script and modules directory exist."
    fi
    
    # Copy modules
    cp -r "$modules_dir"/* "$yads_dir/modules/"
    chmod +x "$yads_dir/modules"/*.sh
    success "Modules copied from: $modules_dir"
    
    # Copy main yads script
    cp "$yads_script" "$yads_dir/"
    chmod +x "$yads_dir/yads"
    success "YADS script copied from: $yads_script"
    
    # Create symlink with proper permissions
    ln -sf "$yads_dir/yads" /usr/local/bin/yads
    chmod 755 /usr/local/bin/yads
    chown root:root /usr/local/bin/yads
    
    # Create version file
    if [[ -f "$script_dir/version" ]]; then
        cp "$script_dir/version" "$yads_dir/"
    else
        echo "1.0.0" > "$yads_dir/version"
    fi
    
    success "YADS structure created"
    
    # Ensure /usr/local has proper permissions
    info "🔧 Ensuring /usr/local permissions are correct..."
    chown -R root:root /usr/local
    chmod -R 755 /usr/local
    success "/usr/local permissions fixed"
}

# Configure firewall
configure_firewall() {
    info "🔥 Configuring firewall..."
    
    if command -v ufw >/dev/null 2>&1; then
        ufw allow 22/tcp
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw allow 8080/tcp
        ufw --force enable
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --permanent --add-port=8080/tcp
        firewall-cmd --reload
    fi
    
    success "Firewall configured"
}

# Verify and fix PATH configuration
verify_and_fix_path() {
    info "🔍 Verifying PATH configuration..."
    
    local path_issues=false
    local fixes_applied=false
    
    # Check if yads command is available
    if ! command -v yads >/dev/null 2>&1; then
        warning "yads command not found in PATH"
        path_issues=true
        
        # Try to fix by adding /usr/local/bin to PATH
        if [[ -f "/usr/local/bin/yads" ]]; then
            info "Adding /usr/local/bin to current session PATH..."
            export PATH="/usr/local/bin:$PATH"
            fixes_applied=true
        fi
    else
        success "yads command is available"
    fi
    
    # Check if cursor-agent command is available
    if ! command -v cursor-agent >/dev/null 2>&1; then
        warning "cursor-agent command not found in PATH"
        path_issues=true
        
        # Try to fix by adding Cursor paths to PATH
        local cursor_paths=("$HOME/.cursor/bin" "/usr/local/bin")
        for cursor_path in "${cursor_paths[@]}"; do
            if [[ -f "$cursor_path/cursor-agent" ]]; then
                info "Adding $cursor_path to current session PATH..."
                export PATH="$cursor_path:$PATH"
                fixes_applied=true
                break
            fi
        done
    else
        success "cursor-agent command is available"
    fi
    
    # Check if other important commands are available
    local important_commands=("composer" "php" "git" "node" "npm" "nvm")
    for cmd in "${important_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            warning "$cmd command not found in PATH"
            path_issues=true
        else
            success "$cmd command is available"
        fi
    done
    
    # Fix shell configuration if needed
    if [[ "$path_issues" == true ]]; then
        info "🔧 Applying PATH fixes to shell configuration..."
        
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
        
        # Add essential paths to shell config
        local essential_paths=(
            "/usr/local/bin"
            "$HOME/.local/bin"
            "$HOME/.cursor/bin"
        )
        
        for path_dir in "${essential_paths[@]}"; do
            if [[ -d "$path_dir" ]] && ! grep -q "export PATH.*$path_dir" "$shell_config" 2>/dev/null; then
                info "Adding $path_dir to $shell_config"
                echo "export PATH=\"$path_dir:\$PATH\"" >> "$shell_config"
                fixes_applied=true
            fi
        done
        
        # Create a comprehensive PATH export
        if [[ "$fixes_applied" == true ]]; then
            info "Creating comprehensive PATH configuration..."
            cat >> "$shell_config" << 'EOF'

# YADS PATH Configuration
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.local/bin:$HOME/.cursor/bin:$PATH"
EOF
        fi
    fi
    
    # Final verification
    info "🔍 Final PATH verification..."
    local final_issues=false
    
    if ! command -v yads >/dev/null 2>&1; then
        error "yads command still not available after fixes"
        final_issues=true
    fi
    
    if ! command -v cursor-agent >/dev/null 2>&1; then
        warning "cursor-agent command still not available (may need shell restart)"
    fi
    
    if [[ "$final_issues" == true ]]; then
        warning "Some PATH issues remain. Please run: source ~/.bashrc"
        warning "Or restart your terminal and try again."
    else
        success "✅ All PATH issues resolved!"
    fi
    
    # Show current PATH for debugging
    info "Current PATH: $PATH"
    
    # Test commands
    info "🧪 Testing commands..."
    if command -v yads >/dev/null 2>&1; then
        info "Testing yads --version:"
        yads --version 2>/dev/null || warning "yads --version failed"
    fi
    
    if command -v cursor-agent >/dev/null 2>&1; then
        info "Testing cursor-agent --help:"
        cursor-agent --help >/dev/null 2>&1 || warning "cursor-agent --help failed"
    fi
}

# Main installation function
main() {
    setup_colors
    
    log "${CYAN}🚀 YADS - Remote PHP Development Server Installation${NC}"
    log "${BLUE}================================================${NC}"
    
    # Check if we're in the right directory
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ ! -f "$script_dir/yads" ]] || [[ ! -d "$script_dir/modules" ]]; then
        error_exit "Please run this script from the YADS repository directory"
    fi
    
    # Ensure script is executable
    if [[ ! -x "$0" ]]; then
        warning "Making install script executable..."
        chmod +x "$0"
    fi
    
    # Fix line endings for all scripts
    info "🔧 Fixing line endings for all scripts..."
    if [[ -f "$script_dir/fix-all-line-endings.sh" ]]; then
        chmod +x "$script_dir/fix-all-line-endings.sh"
        bash "$script_dir/fix-all-line-endings.sh"
    else
        # Fallback: fix line endings manually
        warning "fix-all-line-endings.sh not found, using manual fix..."
        find "$script_dir" -name "*.sh" -o -name "yads" | while read -r file; do
            if [[ -f "$file" ]]; then
                # Fix line endings
                if command -v dos2unix >/dev/null 2>&1; then
                    dos2unix "$file" 2>/dev/null || true
                else
                    sed -i 's/\r$//' "$file" 2>/dev/null || true
                fi
                # Make executable
                chmod +x "$file"
            fi
        done
    fi
    
    check_root
    detect_os
    
    info "Starting YADS installation..."
    
    update_system
    install_docker
    install_nodejs
    install_vscode_server
    install_cloudflared
    install_php
    install_webservers
    install_databases
    install_gh_cli
    install_cursor_cli
    create_yads_structure
    configure_firewall
    
    success "🎉 YADS installation completed!"
    
    # Final permission verification and fix
    info "🔍 Running final permission verification..."
    
    # Ensure /usr/local permissions are correct
    chown -R root:root /usr/local
    chmod -R 755 /usr/local
    
    # Ensure VS Code Server permissions are correct
    if id vscode >/dev/null 2>&1; then
        chown -R vscode:vscode /home/vscode
        chmod -R 755 /home/vscode
        chmod 600 /home/vscode/.config/code-server/config.yaml 2>/dev/null || true
    fi
    
    # Ensure YADS script has proper permissions
    if [[ -f "/usr/local/bin/yads" ]]; then
        chown root:root /usr/local/bin/yads
        chmod 755 /usr/local/bin/yads
    fi
    
    success "Final permission verification completed"
    
    # Verify and fix PATH configuration
    verify_and_fix_path
    
    # Run post-installation setup
    if [[ -f "$script_dir/post-install.sh" ]]; then
        info "🔧 Running post-installation setup..."
        bash "$script_dir/post-install.sh"
    fi
    
    log "${YELLOW}Next steps:${NC}"
    log "1. Restart your terminal or run: source ~/.bashrc"
    log "2. Configure Cloudflared tunnel: yads tunnel setup"
    log "3. Configure VS Code Server: yads vscode setup"
    log "4. Create your first project: yads project myapp"
    log "5. Check service status: yads status"
    
    log "${BLUE}VS Code Server:${NC} http://localhost:8080"
    log "${BLUE}Projects directory:${NC} /var/www/projects"
    log "${BLUE}YADS directory:${NC} /opt/yads"
}

# Run main function
main "$@"

