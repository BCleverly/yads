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
        BLUE='\033[0;34m'
        CYAN='\033[0;36m'
        NC='\033[0m' # No Color
    else
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        CYAN=''
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
    
    case "$OS" in
        ubuntu|debian)
            # Add Docker's official GPG key
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # Add Docker repository
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            apt-get update
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        centos|rhel|fedora)
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y dnf-plugins-core
                dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
                dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            else
                yum install -y yum-utils
                yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            fi
            ;;
        arch)
            pacman -S --noconfirm docker docker-compose
            ;;
    esac
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    # Add current user to docker group (if not root)
    if [[ "$SUDO_USER" != "" ]]; then
        usermod -aG docker "$SUDO_USER"
    fi
    
    success "Docker installed and started"
}

# Install Node.js and npm
install_nodejs() {
    info "📦 Installing Node.js and npm..."
    
    if command -v node >/dev/null 2>&1; then
        info "Node.js already installed"
        return
    fi
    
    # Install NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    
    case "$OS" in
        ubuntu|debian)
            apt-get install -y nodejs
            ;;
        centos|rhel|fedora)
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y nodejs npm
            else
                yum install -y nodejs npm
            fi
            ;;
        arch)
            pacman -S --noconfirm nodejs npm
            ;;
    esac
    
    success "Node.js and npm installed"
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
    
    # Download and install VS Code Server
    local latest_version
    latest_version=$(curl -s https://api.github.com/repos/coder/code-server/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    
    cd /tmp
    wget "https://github.com/coder/code-server/releases/download/${latest_version}/code-server-${latest_version#v}-linux-amd64.tar.gz"
    tar -xzf "code-server-${latest_version#v}-linux-amd64.tar.gz"
    cp "code-server-${latest_version#v}-linux-amd64/code-server" /usr/local/bin/
    chmod +x /usr/local/bin/code-server
    
    # Create systemd service
    cat > /etc/systemd/system/vscode-server.service << EOF
[Unit]
Description=VS Code Server
After=network.target

[Service]
Type=simple
User=$vscode_user
WorkingDirectory=$vscode_dir
ExecStart=/usr/local/bin/code-server --bind-addr 0.0.0.0:8080 --auth password
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Generate random password
    local password
    password=$(openssl rand -base64 32)
    echo "$password" > "$vscode_dir/.password"
    chown "$vscode_user:$vscode_user" "$vscode_dir/.password"
    chmod 600 "$vscode_dir/.password"
    
    systemctl daemon-reload
    systemctl enable vscode-server
    systemctl start vscode-server
    
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
            apt-get install -y php8.2 php8.2-cli php8.2-fpm php8.2-mysql php8.2-pgsql php8.2-curl php8.2-gd php8.2-mbstring php8.2-xml php8.2-zip php8.2-bcmath php8.2-intl php8.2-redis
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
        curl -sS https://getcomposer.org/installer | php
        mv composer.phar /usr/local/bin/composer
        chmod +x /usr/local/bin/composer
    fi
    
    # Install Laravel installer
    composer global require laravel/installer
    
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
    systemctl start mysql redis
    systemctl enable mysql redis
    
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
    
    case "$OS" in
        ubuntu|debian)
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            apt-get update
            apt-get install -y gh
            ;;
        centos|rhel|fedora)
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y 'https://github.com/cli/cli/releases/download/v2.40.1/gh_2.40.1_linux_amd64.rpm'
            else
                yum install -y 'https://github.com/cli/cli/releases/download/v2.40.1/gh_2.40.1_linux_amd64.rpm'
            fi
            ;;
        arch)
            pacman -S --noconfirm github-cli
            ;;
    esac
    
    success "GitHub CLI installed"
}

# Create YADS directory structure
create_yads_structure() {
    info "📁 Creating YADS directory structure..."
    
    local yads_dir="/opt/yads"
    local projects_dir="/var/www/projects"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    mkdir -p "$yads_dir"/{modules,config,logs}
    mkdir -p "$projects_dir"
    mkdir -p /etc/yads
    
    # Copy modules from script directory
    if [[ -d "$script_dir/modules" ]]; then
        cp -r "$script_dir/modules"/* "$yads_dir/modules/"
        chmod +x "$yads_dir/modules"/*.sh
    else
        error_exit "Modules directory not found at $script_dir/modules"
    fi
    
    # Create main yads script
    if [[ -f "$script_dir/yads" ]]; then
        cp "$script_dir/yads" "$yads_dir/"
        chmod +x "$yads_dir/yads"
    else
        error_exit "Main yads script not found at $script_dir/yads"
    fi
    
    # Create symlink
    ln -sf "$yads_dir/yads" /usr/local/bin/yads
    
    # Create version file
    if [[ -f "$script_dir/version" ]]; then
        cp "$script_dir/version" "$yads_dir/"
    else
        echo "1.0.0" > "$yads_dir/version"
    fi
    
    success "YADS structure created"
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
    create_yads_structure
    configure_firewall
    
    success "🎉 YADS installation completed!"
    
    log "${YELLOW}Next steps:${NC}"
    log "1. Configure Cloudflared tunnel: yads tunnel setup"
    log "2. Configure VS Code Server: yads vscode setup"
    log "3. Create your first project: yads project myapp"
    log "4. Check service status: yads status"
    
    log "${BLUE}VS Code Server:${NC} http://localhost:8080"
    log "${BLUE}Projects directory:${NC} /var/www/projects"
    log "${BLUE}YADS directory:${NC} /opt/yads"
}

# Run main function
main "$@"
