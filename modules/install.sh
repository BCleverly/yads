#!/bin/bash

# Installation module for YADS

# Detect and remove existing software
detect_and_remove() {
    local software="$1"
    local package_name="$2"
    
    info "Checking for existing $software installation..."
    
    case "$software" in
        "php")
            if command -v php &> /dev/null; then
                warning "PHP is already installed. Removing for clean install..."
                remove_php
            fi
            ;;
        "mysql")
            if command -v mysql &> /dev/null; then
                warning "MySQL is already installed. Removing for clean install..."
                remove_mysql
            fi
            ;;
        "postgresql")
            if command -v psql &> /dev/null; then
                warning "PostgreSQL is already installed. Removing for clean install..."
                remove_postgresql
            fi
            ;;
        "nginx")
            if command -v nginx &> /dev/null; then
                warning "NGINX is already installed. Removing for clean install..."
                remove_nginx
            fi
            ;;
        "cloudflared")
            if command -v cloudflared &> /dev/null; then
                warning "Cloudflare tunnel is already installed. Removing for clean install..."
                remove_cloudflared
            fi
            ;;
        "gh")
            if command -v gh &> /dev/null; then
                warning "GitHub CLI is already installed. Removing for clean install..."
                remove_github_cli
            fi
            ;;
        "composer")
            if command -v composer &> /dev/null; then
                warning "Composer is already installed. Removing for clean install..."
                remove_composer
            fi
            ;;
        "apache2")
            if command -v apache2 &> /dev/null || command -v httpd &> /dev/null; then
                echo
                echo "=================================================="
                log "${RED}🚨 CRITICAL WARNING: APACHE2 CONFLICT DETECTED 🚨${NC}"
                echo "=================================================="
                echo
                warning "Apache2/HTTPD is already installed and will CONFLICT with YADS."
                echo
                log "${RED}⚠️  DESTRUCTIVE ACTION REQUIRED ⚠️${NC}"
                echo
                log "${YELLOW}YADS requires NGINX or FrankenPHP as web server.${NC}"
                log "${YELLOW}Apache2/HTTPD cannot coexist with YADS web servers.${NC}"
                echo
                log "${RED}🔥 WHAT WILL BE DELETED IF YOU CONTINUE:${NC}"
                echo "  🗑️  Apache2/HTTPD will be COMPLETELY REMOVED"
                echo "  🛑 All Apache2/HTTPD services will be STOPPED"
                echo "  📁 All Apache2/HTTPD configuration files will be DELETED"
                echo "  🗂️  All Apache2/HTTPD log files will be REMOVED"
                echo "  ⚙️  All Apache2/HTTPD modules will be UNINSTALLED"
                echo "  🔄 YADS will install NGINX or FrankenPHP instead"
                echo
                log "${YELLOW}⚠️  THIS ACTION CANNOT BE UNDONE! ⚠️${NC}"
                echo
                log "${GREEN}Your options:${NC}"
                echo "  [y] YES - DELETE Apache2/HTTPD and continue with YADS installation"
                echo "  [n] NO  - Cancel installation and keep Apache2/HTTPD"
                echo
                log "${RED}⚠️  WARNING: Continuing will PERMANENTLY DELETE Apache2/HTTPD! ⚠️${NC}"
                echo
                read -p "${RED}🔥 Do you want to DELETE Apache2/HTTPD and continue? [y/N]: ${NC}" REMOVE_APACHE
                if [[ "$REMOVE_APACHE" =~ ^[yY]$ ]]; then
                    echo
                    log "${RED}🔥 Proceeding to DELETE Apache2/HTTPD...${NC}"
                    remove_apache2
                else
                    error_exit "Installation cancelled. Apache2/HTTPD will not be removed."
                fi
            fi
            ;;
    esac
}

# Remove PHP
remove_php() {
    case "$OS" in
        "ubuntu"|"debian")
            sudo apt-get remove --purge -y php* libapache2-mod-php* || true
            sudo apt-get autoremove -y || true
            sudo apt-get autoclean || true
            ;;
        "centos"|"rhel"|"fedora")
            sudo yum remove -y php* || true
            ;;
        "arch")
            sudo pacman -Rns --noconfirm php || true
            ;;
    esac
}

# Remove MySQL
remove_mysql() {
    case "$OS" in
        "ubuntu"|"debian")
            sudo systemctl stop mysql || true
            sudo apt-get remove --purge -y mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-* || true
            sudo apt-get autoremove -y || true
            sudo apt-get autoclean || true
            sudo rm -rf /var/lib/mysql || true
            sudo rm -rf /var/log/mysql || true
            sudo rm -rf /etc/mysql || true
            ;;
        "centos"|"rhel"|"fedora")
            sudo systemctl stop mysqld || true
            sudo yum remove -y mysql-server mysql || true
            ;;
        "arch")
            sudo systemctl stop mysqld || true
            sudo pacman -Rns --noconfirm mysql || true
            ;;
    esac
}

# Remove PostgreSQL
remove_postgresql() {
    case "$OS" in
        "ubuntu"|"debian")
            sudo systemctl stop postgresql || true
            sudo apt-get remove --purge -y postgresql postgresql-* || true
            sudo apt-get autoremove -y || true
            sudo apt-get autoclean || true
            sudo rm -rf /var/lib/postgresql || true
            sudo rm -rf /var/log/postgresql || true
            sudo rm -rf /etc/postgresql || true
            ;;
        "centos"|"rhel"|"fedora")
            sudo systemctl stop postgresql || true
            sudo yum remove -y postgresql postgresql-server || true
            ;;
        "arch")
            sudo systemctl stop postgresql || true
            sudo pacman -Rns --noconfirm postgresql || true
            ;;
    esac
}

# Remove NGINX
remove_nginx() {
    case "$OS" in
        "ubuntu"|"debian")
            sudo systemctl stop nginx || true
            sudo apt-get remove --purge -y nginx nginx-* || true
            sudo apt-get autoremove -y || true
            sudo apt-get autoclean || true
            sudo rm -rf /etc/nginx || true
            sudo rm -rf /var/log/nginx || true
            ;;
        "centos"|"rhel"|"fedora")
            sudo systemctl stop nginx || true
            sudo yum remove -y nginx || true
            ;;
        "arch")
            sudo systemctl stop nginx || true
            sudo pacman -Rns --noconfirm nginx || true
            ;;
    esac
}

# Remove Cloudflare tunnel
remove_cloudflared() {
    sudo systemctl stop cloudflared || true
    sudo systemctl disable cloudflared || true
    sudo rm -f /usr/local/bin/cloudflared || true
    sudo rm -f /etc/systemd/system/cloudflared.service || true
    sudo rm -rf /etc/cloudflared || true
}

# Remove GitHub CLI
remove_github_cli() {
    case "$OS" in
        "ubuntu"|"debian")
            sudo apt-get remove --purge -y gh || true
            ;;
        "centos"|"rhel"|"fedora")
            sudo yum remove -y gh || true
            ;;
        "arch")
            sudo pacman -Rns --noconfirm github-cli || true
            ;;
    esac
}

# Remove Composer
remove_composer() {
    sudo rm -f /usr/local/bin/composer || true
    sudo rm -f /usr/bin/composer || true
}

# Remove Apache2/HTTPD
remove_apache2() {
    info "Stopping Apache2/HTTPD services..."
    sudo systemctl stop apache2 httpd 2>/dev/null || true
    sudo systemctl disable apache2 httpd 2>/dev/null || true
    
    case "$OS" in
        "ubuntu"|"debian")
            info "Removing Apache2 packages..."
            sudo apt-get remove --purge -y apache2 apache2-utils apache2-bin apache2-data 2>/dev/null || true
            sudo apt-get autoremove -y 2>/dev/null || true
            ;;
        "centos"|"rhel"|"fedora")
            info "Removing HTTPD packages..."
            sudo yum remove -y httpd httpd-tools 2>/dev/null || true
            sudo dnf remove -y httpd httpd-tools 2>/dev/null || true
            ;;
        "arch")
            info "Removing Apache packages..."
            sudo pacman -R --noconfirm apache 2>/dev/null || true
            ;;
    esac
    
    # Remove configuration files
    info "Removing Apache2/HTTPD configuration files..."
    sudo rm -rf /etc/apache2 /etc/httpd /var/www/html /var/log/apache2 /var/log/httpd
    
    success "Apache2/HTTPD removed"
}

# Update system packages
update_system() {
    info "Updating system packages..."
    case "$OS" in
        "ubuntu"|"debian")
            sudo apt-get update
            sudo apt-get upgrade -y
            sudo apt-get install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates
            ;;
        "centos"|"rhel"|"fedora")
            sudo yum update -y
            sudo yum install -y curl wget gnupg2
            ;;
        "arch")
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm curl wget gnupg
            ;;
    esac
    success "System packages updated"
}

# Install PHP 8.4
install_php() {
    info "Installing PHP 8.4..."
    detect_and_remove "php" "php"
    
    case "$OS" in
        "ubuntu"|"debian")
            # Add Ondrej's PHP repository
            sudo apt-get install -y software-properties-common
            sudo add-apt-repository ppa:ondrej/php -y
            sudo apt-get update
            sudo apt-get install -y php8.4 php8.4-cli php8.4-fpm php8.4-mysql php8.4-pgsql php8.4-curl php8.4-gd php8.4-mbstring php8.4-xml php8.4-zip php8.4-bcmath php8.4-intl php8.4-redis php8.4-memcached php8.4-xdebug
            ;;
        "centos"|"rhel"|"fedora")
            sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.rpm
            sudo dnf module enable php:remi-8.4 -y
            sudo dnf install -y php php-cli php-fpm php-mysqlnd php-pgsql php-curl php-gd php-mbstring php-xml php-zip php-bcmath php-intl php-redis php-memcached php-xdebug
            ;;
        "arch")
            sudo pacman -S --noconfirm php php-fpm php-gd php-intl php-redis php-memcached php-xdebug
            ;;
    esac
    
    # Configure PHP
    configure_php
    success "PHP 8.4 installed and configured"
}

# Configure PHP
configure_php() {
    local php_ini="/etc/php/8.4/fpm/php.ini"
    if [[ ! -f "$php_ini" ]]; then
        php_ini="/etc/php/php.ini"
    fi
    
    if [[ -f "$php_ini" ]]; then
        info "Configuring PHP settings..."
        sudo sed -i 's/upload_max_filesize = .*/upload_max_filesize = 256M/' "$php_ini"
        sudo sed -i 's/post_max_size = .*/post_max_size = 256M/' "$php_ini"
        sudo sed -i 's/memory_limit = .*/memory_limit = 512M/' "$php_ini"
        sudo sed -i 's/max_execution_time = .*/max_execution_time = 300/' "$php_ini"
        sudo sed -i 's/;date.timezone =/date.timezone = UTC/' "$php_ini"
        
        # Enable Xdebug
        sudo sed -i 's/;zend_extension=xdebug/zend_extension=xdebug/' "$php_ini"
        echo "xdebug.mode=debug" | sudo tee -a "$php_ini"
        echo "xdebug.start_with_request=yes" | sudo tee -a "$php_ini"
        echo "xdebug.client_host=127.0.0.1" | sudo tee -a "$php_ini"
        echo "xdebug.client_port=9003" | sudo tee -a "$php_ini"
    fi
}

# Install MySQL
install_mysql() {
    info "Installing MySQL..."
    detect_and_remove "mysql" "mysql"
    
    case "$OS" in
        "ubuntu"|"debian")
            sudo apt-get install -y mysql-server mysql-client
            sudo systemctl start mysql
            sudo systemctl enable mysql
            ;;
        "centos"|"rhel"|"fedora")
            sudo dnf install -y mysql-server mysql
            sudo systemctl start mysqld
            sudo systemctl enable mysqld
            ;;
        "arch")
            sudo pacman -S --noconfirm mysql
            sudo systemctl start mysqld
            sudo systemctl enable mysqld
            ;;
    esac
    
    # Secure MySQL installation
    secure_mysql
    success "MySQL installed and configured"
}

# Secure MySQL installation
secure_mysql() {
    info "Securing MySQL installation..."
    
    # Generate random password
    MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
    
    # Create MySQL configuration file
    sudo tee /etc/mysql/mysql.conf.d/yads.cnf > /dev/null << EOF
[mysqld]
bind-address = 127.0.0.1
max_connections = 200
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT
query_cache_type = 1
query_cache_size = 32M
query_cache_limit = 2M
tmp_table_size = 64M
max_heap_table_size = 64M
EOF
    
    # Restart MySQL
    sudo systemctl restart mysql || sudo systemctl restart mysqld
    
    # Run mysql_secure_installation
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';"
    sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
    sudo mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    sudo mysql -e "DROP DATABASE IF EXISTS test;"
    sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
    sudo mysql -e "FLUSH PRIVILEGES;"
    
    # Save password to config
    echo "MYSQL_ROOT_PASSWORD='$MYSQL_ROOT_PASSWORD'" >> "$CONFIG_FILE"
    
    success "MySQL secured with password saved to config"
}

# Install PostgreSQL
install_postgresql() {
    info "Installing PostgreSQL..."
    detect_and_remove "postgresql" "postgresql"
    
    case "$OS" in
        "ubuntu"|"debian")
            sudo apt-get install -y postgresql postgresql-contrib
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
            ;;
        "centos"|"rhel"|"fedora")
            sudo dnf install -y postgresql postgresql-server postgresql-contrib
            sudo postgresql-setup --initdb
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
            ;;
        "arch")
            sudo pacman -S --noconfirm postgresql
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
            ;;
    esac
    
    # Configure PostgreSQL
    configure_postgresql
    success "PostgreSQL installed and configured"
}

# Configure PostgreSQL
configure_postgresql() {
    info "Configuring PostgreSQL..."
    
    # Create development user
    sudo -u postgres psql -c "CREATE USER yads WITH PASSWORD 'yads_dev_$(openssl rand -base64 16)';"
    sudo -u postgres psql -c "CREATE DATABASE yads_dev OWNER yads;"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE yads_dev TO yads;"
    
    # Configure PostgreSQL for development
    sudo tee -a /etc/postgresql/*/main/postgresql.conf > /dev/null << EOF
# YADS Development Configuration
listen_addresses = 'localhost'
port = 5432
max_connections = 100
shared_buffers = 128MB
effective_cache_size = 512MB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
EOF
    
    # Restart PostgreSQL
    sudo systemctl restart postgresql
    success "PostgreSQL configured for development"
}

# Install Composer
install_composer() {
    info "Installing Composer..."
    detect_and_remove "composer" "composer"
    
    # Download and install Composer
    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
    sudo chmod +x /usr/local/bin/composer
    
    # Install Laravel globally
    composer global require laravel/installer
    
    # Add Composer global bin to PATH
    echo 'export PATH="$HOME/.composer/vendor/bin:$PATH"' >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.composer/vendor/bin:$PATH"' >> "$HOME/.zshrc"
    
    success "Composer and Laravel installer installed"
}

# Install GitHub CLI
install_github_cli() {
    info "Installing GitHub CLI..."
    detect_and_remove "gh" "github-cli"
    
    case "$OS" in
        "ubuntu"|"debian")
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y gh
            ;;
        "centos"|"rhel"|"fedora")
            sudo dnf install -y 'https://github.com/cli/cli/releases/download/v2.40.1/gh_2.40.1_linux_amd64.rpm'
            ;;
        "arch")
            sudo pacman -S --noconfirm github-cli
            ;;
    esac
    
    success "GitHub CLI installed"
}

# Install Cursor CLI
install_cursor_cli() {
    info "Installing Cursor CLI..."
    
    # Download and install Cursor CLI
    curl -fsSL https://cursor.sh/install.sh | sh
    
    success "Cursor CLI installed"
}

# Install Cloudflare tunnel
install_cloudflared() {
    info "Installing Cloudflare tunnel..."
    detect_and_remove "cloudflared" "cloudflared"
    
    # Download and install cloudflared
    wget -O cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared.deb
    rm cloudflared.deb
    
    # Create systemd service
    sudo tee /etc/systemd/system/cloudflared.service > /dev/null << EOF
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=simple
User=cloudflared
ExecStart=/usr/local/bin/cloudflared tunnel --config /etc/cloudflared/config.yml run
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    # Create cloudflared user
    sudo useradd -r -s /bin/false cloudflared
    
    # Create config directory
    sudo mkdir -p /etc/cloudflared
    
    success "Cloudflare tunnel installed"
}

# Choose web server
choose_web_server() {
    info "Choose your web server:"
    echo "1) NGINX (recommended for most projects)"
    echo "2) FrankenPHP (modern PHP server with built-in features)"
    echo
    read -p "Enter your choice (1-2): " choice
    
    case $choice in
        1)
            WEB_SERVER="nginx"
            install_nginx
            ;;
        2)
            WEB_SERVER="frankenphp"
            install_frankenphp
            ;;
        *)
            warning "Invalid choice. Defaulting to NGINX."
            WEB_SERVER="nginx"
            install_nginx
            ;;
    esac
}

# Install NGINX
install_nginx() {
    info "Installing NGINX..."
    detect_and_remove "nginx" "nginx"
    
    case "$OS" in
        "ubuntu"|"debian")
            sudo apt-get install -y nginx
            ;;
        "centos"|"rhel"|"fedora")
            sudo dnf install -y nginx
            ;;
        "arch")
            sudo pacman -S --noconfirm nginx
            ;;
    esac
    
    # Configure NGINX
    configure_nginx
    success "NGINX installed and configured"
}

# Configure NGINX
configure_nginx() {
    info "Configuring NGINX..."
    
    # Create main configuration
    sudo tee /etc/nginx/nginx.conf > /dev/null << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log;
    
    # Basic settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=login:10m rate=10r/m;
    limit_req_zone $binary_remote_addr zone=api:10m rate=100r/m;
    
    # Include server configurations
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF
    
    # Create sites directory structure
    sudo mkdir -p /etc/nginx/sites-available
    sudo mkdir -p /etc/nginx/sites-enabled
    sudo mkdir -p /var/www/html
    
    # Create default site
    sudo tee /etc/nginx/sites-available/default > /dev/null << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/html;
    index index.php index.html index.htm;
    
    server_name _;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF
    
    # Enable default site
    sudo ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
    
    # Test configuration
    sudo nginx -t
    
    # Start and enable NGINX
    sudo systemctl start nginx
    sudo systemctl enable nginx
    
    success "NGINX configured"
}

# Install FrankenPHP
install_frankenphp() {
    info "Installing FrankenPHP..."
    
    # Download FrankenPHP
    wget -O frankenphp.tar.gz https://github.com/dunglas/frankenphp/releases/latest/download/frankenphp-linux-x86_64.tar.gz
    tar -xzf frankenphp.tar.gz
    sudo mv frankenphp /usr/local/bin/
    sudo chmod +x /usr/local/bin/frankenphp
    rm frankenphp.tar.gz
    
    # Create systemd service
    sudo tee /etc/systemd/system/frankenphp.service > /dev/null << EOF
[Unit]
Description=FrankenPHP
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
ExecStart=/usr/local/bin/frankenphp run --config /etc/frankenphp/Caddyfile
Restart=always
RestartSec=5
WorkingDirectory=/var/www/html

[Install]
WantedBy=multi-user.target
EOF
    
    # Create FrankenPHP configuration
    sudo mkdir -p /etc/frankenphp
    sudo tee /etc/frankenphp/Caddyfile > /dev/null << 'EOF'
{
    auto_https off
    servers {
        protocols h1 h2 h3
    }
}

:80 {
    root * /var/www/html
    php_fastcgi unix//var/run/php/php8.4-fpm.sock
    file_server
}
EOF
    
    # Start and enable FrankenPHP
    sudo systemctl start frankenphp
    sudo systemctl enable frankenphp
    
    success "FrankenPHP installed and configured"
}

# Configure user permissions
configure_permissions() {
    info "Configuring user permissions..."
    
    # Add user to www-data group
    sudo usermod -a -G www-data "$USER"
    
    # Set proper permissions for web directory
    sudo chown -R www-data:www-data /var/www/html
    sudo chmod -R 755 /var/www/html
    
    # Create user development directory
    mkdir -p "$HOME/development"
    sudo chown -R "$USER:$USER" "$HOME/development"
    
    success "User permissions configured"
}

# Configure SSH keys
configure_ssh_keys() {
    info "Configuring SSH keys for Git services..."
    
    # Generate SSH key if it doesn't exist
    if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
        ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f "$HOME/.ssh/id_ed25519" -N ""
        success "SSH key generated"
    else
        info "SSH key already exists"
    fi
    
    # Start SSH agent and add key
    eval "$(ssh-agent -s)"
    ssh-add "$HOME/.ssh/id_ed25519"
    
    # Display public key
    echo
    info "Your SSH public key (add this to GitHub, GitLab, Bitbucket):"
    echo
    cat "$HOME/.ssh/id_ed25519.pub"
    echo
    read -p "Press Enter after adding the key to your Git services..."
    
    # Test GitHub connection
    if command -v gh &> /dev/null; then
        info "Testing GitHub connection..."
        if gh auth status &> /dev/null; then
            success "GitHub authentication successful"
        else
            warning "GitHub authentication failed. Please run 'gh auth login' manually."
        fi
    fi
    
    success "SSH keys configured"
}

# Check prerequisites before installation
check_prerequisites() {
    log "${CYAN}Checking YADS installation prerequisites...${NC}"
    echo
    
    local missing_prereqs=()
    local warnings=()
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error_exit "This script should not be run as root. Please run as a regular user with sudo privileges."
    fi
    
    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        warning "Sudo access required. You may be prompted for your password during installation."
    fi
    
    # Check internet connectivity
    if ! ping -c 1 google.com &> /dev/null; then
        warnings+=("Internet connectivity issues detected. Some downloads may fail.")
    fi
    
    # Check available disk space (minimum 2GB)
    local available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 2097152 ]]; then  # 2GB in KB
        warnings+=("Low disk space detected. At least 2GB free space recommended.")
    fi
    
    # Check memory (minimum 1GB)
    local total_memory=$(free -m | awk 'NR==2{print $2}')
    if [[ $total_memory -lt 1024 ]]; then
        warnings+=("Low memory detected. At least 1GB RAM recommended.")
    fi
    
    # Check required commands
    local required_commands=("curl" "wget" "tar" "gzip" "openssl")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_prereqs+=("$cmd")
        fi
    done
    
    # Check for conflicting software
    local conflicting_software=()
    if command -v apache2 &> /dev/null; then
        conflicting_software+=("Apache2")
    fi
    if command -v httpd &> /dev/null; then
        conflicting_software+=("Apache HTTPD")
    fi
    if command -v lighttpd &> /dev/null; then
        conflicting_software+=("Lighttpd")
    fi
    
    # Display prerequisites status
    log "${BLUE}Prerequisites Check Results:${NC}"
    echo
    
    # Required commands
    if [[ ${#missing_prereqs[@]} -eq 0 ]]; then
        success "All required commands are available"
    else
        error_exit "Missing required commands: ${missing_prereqs[*]}. Please install them first."
    fi
    
    # Warnings
    if [[ ${#warnings[@]} -gt 0 ]]; then
        for warning in "${warnings[@]}"; do
            warning "$warning"
        done
        echo
    fi
    
    # Conflicting software
    if [[ ${#conflicting_software[@]} -gt 0 ]]; then
        warning "The following web servers are already installed and may conflict:"
        for software in "${conflicting_software[@]}"; do
            warning "  - $software"
        done
        echo
        read -p "Do you want to continue anyway? (y/N): " continue_install
        if [[ ! "$continue_install" =~ ^[Yy]$ ]]; then
            error_exit "Installation cancelled by user"
        fi
    fi
    
    # System requirements notice
    log "${YELLOW}System Requirements:${NC}"
    echo "  • Operating System: Ubuntu 20.04+, Debian 11+, CentOS 8+, RHEL 8+, Fedora 35+, Arch Linux"
    echo "  • Memory: Minimum 2GB RAM (4GB recommended)"
    echo "  • Storage: Minimum 10GB free space"
    echo "  • Network: Internet connection for package downloads"
    echo "  • Domain: A domain name for SSL certificates and remote access"
    echo
    
    # Installation notice
    log "${YELLOW}Installation Notice:${NC}"
    echo "  • This will install PHP 8.4, MySQL, PostgreSQL, and your choice of web server"
    echo "  • Existing installations of these software will be removed for clean install"
    echo "  • SSL certificates will be automatically configured"
    echo "  • Cloudflare tunnel will be set up for remote access"
    echo "  • Development tools (GitHub CLI, Cursor CLI, Composer) will be installed"
    echo
    
    # Time estimate
    log "${YELLOW}Estimated Installation Time:${NC}"
    echo "  • Fast connection: 5-10 minutes"
    echo "  • Slow connection: 15-30 minutes"
    echo "  • Total download size: ~500MB"
    echo
    
    # Confirmation
    read -p "Do you want to proceed with the installation? (y/N): " confirm_install
    if [[ ! "$confirm_install" =~ ^[Yy]$ ]]; then
        error_exit "Installation cancelled by user"
    fi
    
    success "Prerequisites check completed. Starting installation..."
    echo
}

# Main installation function
install_all() {
    log "${CYAN}Starting YADS installation...${NC}"
    
    # Check prerequisites first
    check_prerequisites
    
    # Update system
    update_system
    
    # Install core software
    install_php
    install_mysql
    install_postgresql
    install_composer
    install_github_cli
    install_cursor_cli
    install_cloudflared
    
    # Check for conflicting web servers
    detect_and_remove "apache2" "apache2"
    
    # Choose and install web server
    choose_web_server
    
    # Configure permissions
    configure_permissions
    
    # Configure SSH keys
    configure_ssh_keys
    
    # Save configuration
    save_config
    
    success "YADS installation completed successfully!"
    info "You can now use 'yads domains' to configure your domain and 'yads create <project>' to create new projects."
}

