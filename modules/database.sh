#!/bin/bash

# YADS Database Module
# Handles database installation and configuration

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

# Detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS="$ID"
        OS_VERSION="$VERSION_ID"
    else
        error_exit "Cannot detect operating system"
    fi
}

# Install MySQL
install_mysql() {
    info "🗄️  Installing MySQL..."
    
    case "$OS" in
        ubuntu|debian)
            # Set MySQL root password
            debconf-set-selections <<< 'mysql-server mysql-server/root_password password yads123'
            debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password yads123'
            
            apt-get install -y mysql-server mysql-client
            
            # Secure MySQL installation
            mysql -u root -pyads123 -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'yads123';"
            mysql -u root -pyads123 -e "DELETE FROM mysql.user WHERE User='';"
            mysql -u root -pyads123 -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
            mysql -u root -pyads123 -e "DROP DATABASE IF EXISTS test;"
            mysql -u root -pyads123 -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
            mysql -u root -pyads123 -e "FLUSH PRIVILEGES;"
            ;;
        centos|rhel|fedora)
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y mysql-server mysql
            else
                yum install -y mysql-server mysql
            fi
            
            systemctl start mysqld
            systemctl enable mysqld
            
            # Get temporary password
            local temp_password
            temp_password=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
            
            # Set root password
            mysql -u root -p"$temp_password" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'yads123';" --connect-expired-password
            ;;
        arch)
            pacman -S --noconfirm mysql
            systemctl start mysqld
            systemctl enable mysqld
            
            # Initialize MySQL
            mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
            systemctl restart mysqld
            
            # Set root password
            mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'yads123';"
            ;;
    esac
    
    # Start and enable MySQL
    systemctl start mysql
    systemctl enable mysql
    
    success "MySQL installed with root password: yads123"
}

# Install PostgreSQL
install_postgresql() {
    info "🐘 Installing PostgreSQL..."
    
    case "$OS" in
        ubuntu|debian)
            apt-get install -y postgresql postgresql-contrib
            ;;
        centos|rhel|fedora)
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y postgresql postgresql-server postgresql-contrib
            else
                yum install -y postgresql postgresql-server postgresql-contrib
            fi
            
            # Initialize PostgreSQL
            postgresql-setup --initdb
            ;;
        arch)
            pacman -S --noconfirm postgresql
            sudo -u postgres initdb -D /var/lib/postgres/data
            ;;
    esac
    
    # Start and enable PostgreSQL
    systemctl start postgresql
    systemctl enable postgresql
    
    # Set postgres user password
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'yads123';"
    
    success "PostgreSQL installed with postgres password: yads123"
}

# Install Redis
install_redis() {
    info "🔴 Installing Redis..."
    
    case "$OS" in
        ubuntu|debian)
            apt-get install -y redis-server
            ;;
        centos|rhel|fedora)
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y redis
            else
                yum install -y redis
            fi
            ;;
        arch)
            pacman -S --noconfirm redis
            ;;
    esac
    
    # Configure Redis
    cat > /etc/redis/redis.conf << 'EOF'
# Redis configuration for YADS
bind 127.0.0.1
port 6379
timeout 0
tcp-keepalive 300
daemonize yes
supervised systemd
pidfile /var/run/redis/redis-server.pid
logfile /var/log/redis/redis-server.log
databases 16
save 900 1
save 300 10
save 60 10000
EOF
    
    # Start and enable Redis
    systemctl start redis
    systemctl enable redis
    
    success "Redis installed and configured"
}

# Show database status
show_status() {
    info "🗄️  Database Status:"
    
    if systemctl is-active --quiet mysql; then
        success "MySQL: Running"
    else
        info "MySQL: Stopped"
    fi
    
    if systemctl is-active --quiet postgresql; then
        success "PostgreSQL: Running"
    else
        info "PostgreSQL: Stopped"
    fi
    
    if systemctl is-active --quiet redis; then
        success "Redis: Running"
    else
        info "Redis: Stopped"
    fi
}

# Create database for project
create_project_database() {
    local project_name="$1"
    local db_type="$2"
    
    info "📊 Creating database for project: $project_name"
    
    case "$db_type" in
        mysql)
            mysql -u root -pyads123 -e "CREATE DATABASE IF NOT EXISTS ${project_name}_dev;"
            mysql -u root -pyads123 -e "CREATE USER IF NOT EXISTS '${project_name}'@'localhost' IDENTIFIED BY '${project_name}_pass';"
            mysql -u root -pyads123 -e "GRANT ALL PRIVILEGES ON ${project_name}_dev.* TO '${project_name}'@'localhost';"
            mysql -u root -pyads123 -e "FLUSH PRIVILEGES;"
            success "MySQL database created: ${project_name}_dev"
            success "MySQL user created: ${project_name} / ${project_name}_pass"
            ;;
        postgresql)
            sudo -u postgres psql -c "CREATE DATABASE ${project_name}_dev;"
            sudo -u postgres psql -c "CREATE USER ${project_name} WITH PASSWORD '${project_name}_pass';"
            sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${project_name}_dev TO ${project_name};"
            success "PostgreSQL database created: ${project_name}_dev"
            success "PostgreSQL user created: ${project_name} / ${project_name}_pass"
            ;;
        *)
            error_exit "Unknown database type: $db_type"
            ;;
    esac
}

# Main database function
database_main() {
    setup_colors
    detect_os
    
    case "${1:-}" in
        "")
            show_status
            info "Use 'yads database <mysql|postgresql|redis>' to install database"
            ;;
        mysql)
            install_mysql
            ;;
        postgresql)
            install_postgresql
            ;;
        redis)
            install_redis
            ;;
        status)
            show_status
            ;;
        create)
            if [[ -z "${2:-}" ]] || [[ -z "${3:-}" ]]; then
                error_exit "Usage: yads database create <project_name> <mysql|postgresql>"
            fi
            create_project_database "$2" "$3"
            ;;
        *)
            error_exit "Unknown database option: $1"
            ;;
    esac
}
