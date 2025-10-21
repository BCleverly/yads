#!/bin/bash

# YADS Project Module
# Handles project creation and management

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

# Create new project
create_project() {
    local project_name="$1"
    local project_type="${2:-php}"
    local proxy_enabled="${3:-false}"
    local projects_dir="/var/www/projects"
    local project_dir="$projects_dir/$project_name"
    
    info "📁 Creating project: $project_name"
    
    # Validate project name
    if [[ ! "$project_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error_exit "Project name can only contain letters, numbers, hyphens, and underscores"
    fi
    
    # Check if project already exists
    if [[ -d "$project_dir" ]]; then
        error_exit "Project '$project_name' already exists"
    fi
    
    # Create project directory with proper permissions
    if [[ $EUID -eq 0 ]]; then
        # Running as root
        mkdir -p "$project_dir"
        chown "$SUDO_USER:webdev" "$project_dir"
        chmod 775 "$project_dir"
        cd "$project_dir"
    else
        # Running as regular user, use sudo
        sudo mkdir -p "$project_dir"
        sudo chown "$USER:webdev" "$project_dir"
        sudo chmod 775 "$project_dir"
        cd "$project_dir"
    fi
    
    case "$project_type" in
        php)
            create_php_project "$project_name"
            ;;
        laravel)
            create_laravel_project "$project_name"
            ;;
        symfony)
            create_symfony_project "$project_name"
            ;;
        wordpress)
            create_wordpress_project "$project_name"
            ;;
        *)
            error_exit "Unknown project type: $project_type"
            ;;
    esac
    
    # Set proper permissions (keep webdev group ownership)
    if [[ $EUID -eq 0 ]]; then
        # Running as root
        chown -R "$SUDO_USER:webdev" "$project_dir"
        chmod -R 775 "$project_dir"
    else
        # Running as regular user, use sudo
        sudo chown -R "$USER:webdev" "$project_dir"
        sudo chmod -R 775 "$project_dir"
    fi
    
    success "Project '$project_name' created at: $project_dir"
    
    # Configure proxy if enabled
    if [[ "$proxy_enabled" == "true" ]]; then
        info "🔧 Configuring NPM proxy for project..."
        
        # Get next available port
        local port=$(get_next_available_port)
        
        # Start project on specific port
        start_project_on_port "$project_name" "$port"
        
        # Add to NPM
        if command -v yads >/dev/null 2>&1; then
            yads proxy project "$project_name" "$port" "$project_name.projects.code-server.yourdomain.com"
            success "Project proxy configured: https://$project_name.projects.code-server.yourdomain.com"
        else
            warning "YADS not found in PATH, skipping proxy configuration"
            info "Run 'yads proxy project $project_name $port' to configure proxy"
        fi
    else
        info "Access: http://$project_name.remote.domain.tld"
    fi
}

# Create PHP project
create_php_project() {
    local project_name="$1"
    
    info "Creating PHP project structure..."
    
    # Create basic PHP files
    cat > index.php << 'EOF'
<?php
echo "<h1>Welcome to " . $_SERVER['HTTP_HOST'] . "</h1>";
echo "<p>PHP Version: " . phpversion() . "</p>";
echo "<p>Server: " . $_SERVER['SERVER_SOFTWARE'] . "</p>";
echo "<p>Document Root: " . $_SERVER['DOCUMENT_ROOT'] . "</p>";

// Show PHP info
if (isset($_GET['info'])) {
    phpinfo();
}
?>
EOF
    
    cat > .htaccess << 'EOF'
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ index.php [QSA,L]
EOF
    
    # Create composer.json
    cat > composer.json << EOF
{
    "name": "$project_name/php-project",
    "description": "PHP project created with YADS",
    "type": "project",
    "require": {
        "php": ">=7.4"
    },
    "autoload": {
        "psr-4": {
            "App\\\\": "src/"
        }
    }
}
EOF
    
    # Install dependencies
    composer install --no-dev --optimize-autoloader
    
    success "PHP project structure created"
}

# Create Laravel project
create_laravel_project() {
    local project_name="$1"
    
    info "Creating Laravel project..."
    
    # Check if Laravel installer is available
    if ! command -v laravel >/dev/null 2>&1; then
        error_exit "Laravel installer not found. Run 'yads php composer' first."
    fi
    
    # Create Laravel project
    composer create-project laravel/laravel . --prefer-dist
    
    # Configure environment
    cp .env.example .env
    php artisan key:generate
    
    # Create database if MySQL is available
    if systemctl is-active --quiet mysql; then
        info "Creating database for Laravel project..."
        mysql -u root -pyads123 -e "CREATE DATABASE IF NOT EXISTS ${project_name}_dev;"
        
        # Update .env file
        sed -i "s/DB_DATABASE=laravel/DB_DATABASE=${project_name}_dev/" .env
        sed -i "s/DB_USERNAME=root/DB_USERNAME=${project_name}/" .env
        sed -i "s/DB_PASSWORD=/DB_PASSWORD=${project_name}_pass/" .env
        
        # Create database user
        mysql -u root -pyads123 -e "CREATE USER IF NOT EXISTS '${project_name}'@'localhost' IDENTIFIED BY '${project_name}_pass';"
        mysql -u root -pyads123 -e "GRANT ALL PRIVILEGES ON ${project_name}_dev.* TO '${project_name}'@'localhost';"
        mysql -u root -pyads123 -e "FLUSH PRIVILEGES;"
    fi
    
    success "Laravel project created"
}

# Create Symfony project
create_symfony_project() {
    local project_name="$1"
    
    info "Creating Symfony project..."
    
    # Check if Symfony CLI is available
    if ! command -v symfony >/dev/null 2>&1; then
        # Install Symfony CLI
        curl -sS https://get.symfony.com/cli/installer | bash
        mv ~/.symfony/bin/symfony /usr/local/bin/
    fi
    
    # Create Symfony project
    symfony new . --version="6.4.*" --no-git
    
    # Install dependencies
    composer install --no-dev --optimize-autoloader
    
    success "Symfony project created"
}

# Create WordPress project
create_wordpress_project() {
    local project_name="$1"
    
    info "Creating WordPress project..."
    
    # Download WordPress
    wget https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz --strip-components=1
    rm latest.tar.gz
    
    # Create wp-config.php
    cp wp-config-sample.php wp-config.php
    
    # Generate salts
    curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> wp-config.php
    
    # Configure database
    if systemctl is-active --quiet mysql; then
        mysql -u root -pyads123 -e "CREATE DATABASE IF NOT EXISTS ${project_name}_dev;"
        mysql -u root -pyads123 -e "CREATE USER IF NOT EXISTS '${project_name}'@'localhost' IDENTIFIED BY '${project_name}_pass';"
        mysql -u root -pyads123 -e "GRANT ALL PRIVILEGES ON ${project_name}_dev.* TO '${project_name}'@'localhost';"
        mysql -u root -pyads123 -e "FLUSH PRIVILEGES;"
        
        # Update wp-config.php
        sed -i "s/database_name_here/${project_name}_dev/" wp-config.php
        sed -i "s/username_here/${project_name}/" wp-config.php
        sed -i "s/password_here/${project_name}_pass/" wp-config.php
    fi
    
    success "WordPress project created"
}

# List projects
list_projects() {
    local projects_dir="/var/www/projects"
    
    info "📁 Available projects:"
    
    if [[ ! -d "$projects_dir" ]]; then
        info "No projects directory found"
        return
    fi
    
    for project in "$projects_dir"/*; do
        if [[ -d "$project" ]]; then
            local project_name
            project_name=$(basename "$project")
            info "  - $project_name ($(basename "$project"))"
        fi
    done
}

# Get next available port
get_next_available_port() {
    local base_port=8081
    local port=$base_port
    
    # Find next available port starting from 8081
    while netstat -tuln 2>/dev/null | grep -q ":$port "; do
        ((port++))
    done
    
    echo $port
}

# Start project on specific port
start_project_on_port() {
    local project_name="$1"
    local port="$2"
    local project_dir="/var/www/projects/$project_name"
    
    info "Starting project on port $port..."
    
    # Create a simple PHP server for the project
    if [[ -f "$project_dir/index.php" ]]; then
        # Start PHP built-in server
        nohup php -S localhost:$port -t "$project_dir" > "/var/log/yads-$project_name.log" 2>&1 &
        echo $! > "/var/run/yads-$project_name.pid"
        success "Project started on port $port"
    else
        warning "No index.php found in project directory"
    fi
}

# Delete project
delete_project() {
    local project_name="$1"
    local projects_dir="/var/www/projects"
    local project_dir="$projects_dir/$project_name"
    
    if [[ ! -d "$project_dir" ]]; then
        error_exit "Project '$project_name' not found"
    fi
    
    warning "This will permanently delete project '$project_name'"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$project_dir"
        success "Project '$project_name' deleted"
    else
        info "Deletion cancelled"
    fi
}

# Main project function
project_main() {
    setup_colors
    
    # Check for --proxy flag
    local proxy_enabled=false
    local args=("$@")
    
    # Remove --proxy flag from arguments
    for i in "${!args[@]}"; do
        if [[ "${args[i]}" == "--proxy" ]]; then
            proxy_enabled=true
            unset 'args[i]'
        fi
    done
    
    case "${args[0]:-}" in
        "")
            list_projects
            info "Use 'yads project <name> [type]' to create a new project"
            info "Types: php, laravel, symfony, wordpress"
            info "Add --proxy flag to automatically configure NPM routes"
            ;;
        list)
            list_projects
            ;;
        delete)
            if [[ -z "${args[1]:-}" ]]; then
                error_exit "Project name required for deletion"
            fi
            delete_project "${args[1]}"
            ;;
        *)
            create_project "${args[0]}" "${args[1]:-php}" "$proxy_enabled"
            ;;
    esac
}
