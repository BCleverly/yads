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
        BLUE='\033[0;34m'
        CYAN='\033[0;36m'
        NC='\033[0m' # No Color
    else
        RED=''
        GREEN=''
        YELLOW=''
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
    
    # Create project directory
    mkdir -p "$project_dir"
    cd "$project_dir"
    
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
    
    # Set proper permissions
    chown -R www-data:www-data "$project_dir"
    chmod -R 755 "$project_dir"
    
    success "Project '$project_name' created at: $project_dir"
    info "Access: http://$project_name.remote.domain.tld"
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
    
    case "${1:-}" in
        "")
            list_projects
            info "Use 'yads project <name> [type]' to create a new project"
            info "Types: php, laravel, symfony, wordpress"
            ;;
        list)
            list_projects
            ;;
        delete)
            if [[ -z "${2:-}" ]]; then
                error_exit "Project name required for deletion"
            fi
            delete_project "$2"
            ;;
        *)
            create_project "$1" "${2:-php}"
            ;;
    esac
}
