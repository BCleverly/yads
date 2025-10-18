#!/bin/bash

# Project creation module for YADS

# Create a new project
create_project() {
    local project_name="$1"
    
    # Validate project name
    if [[ ! "$project_name" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$ ]]; then
        error_exit "Invalid project name. Use only letters, numbers, and hyphens."
    fi
    
    log "${CYAN}Creating project: $project_name${NC}"
    
    # Check if project already exists
    if [[ -d "/var/www/html/$project_name" ]]; then
        error_exit "Project '$project_name' already exists"
    fi
    
    # Choose project type
    choose_project_type "$project_name"
    
    # Create project directory
    create_project_directory "$project_name"
    
    # Set up project permissions
    set_project_permissions "$project_name"
    
    # Create database for project
    create_project_database "$project_name"
    
    # Configure domain for project
    create_project_domain_config "$project_name"
    
    # Set up development environment
    setup_development_environment "$project_name"
    
    success "Project '$project_name' created successfully!"
    info "Access your project at: https://${project_name}.${DOMAIN}"
    info "Project directory: /var/www/html/$project_name"
}

# Choose project type
choose_project_type() {
    local project_name="$1"
    
    echo
    info "Choose project type for '$project_name':"
    echo "1) Laravel (recommended)"
    echo "2) Symfony"
    echo "3) CodeIgniter"
    echo "4) Custom PHP"
    echo "5) WordPress"
    echo
    read -p "Enter your choice (1-5): " choice
    
    case $choice in
        1)
            PROJECT_TYPE="laravel"
            create_laravel_project "$project_name"
            ;;
        2)
            PROJECT_TYPE="symfony"
            create_symfony_project "$project_name"
            ;;
        3)
            PROJECT_TYPE="codeigniter"
            create_codeigniter_project "$project_name"
            ;;
        4)
            PROJECT_TYPE="custom"
            create_custom_php_project "$project_name"
            ;;
        5)
            PROJECT_TYPE="wordpress"
            create_wordpress_project "$project_name"
            ;;
        *)
            warning "Invalid choice. Defaulting to Laravel."
            PROJECT_TYPE="laravel"
            create_laravel_project "$project_name"
            ;;
    esac
}

# Create Laravel project
create_laravel_project() {
    local project_name="$1"
    local project_path="/var/www/html/$project_name"
    
    info "Creating Laravel project..."
    
    # Create Laravel project
    composer create-project laravel/laravel "$project_path" --prefer-dist
    
    if [[ $? -ne 0 ]]; then
        error_exit "Failed to create Laravel project"
    fi
    
    # Configure Laravel
    configure_laravel_project "$project_name" "$project_path"
    
    success "Laravel project created"
}

# Configure Laravel project
configure_laravel_project() {
    local project_name="$1"
    local project_path="$2"
    
    info "Configuring Laravel project..."
    
    # Set up environment file
    cp "$project_path/.env.example" "$project_path/.env"
    
    # Generate application key
    cd "$project_path"
    php artisan key:generate
    
    # Configure database
    configure_laravel_database "$project_name" "$project_path"
    
    # Install additional packages
    install_laravel_packages "$project_path"
    
    # Set up Laravel development tools
    setup_laravel_development_tools "$project_path"
}

# Configure Laravel database
configure_laravel_database() {
    local project_name="$1"
    local project_path="$2"
    
    info "Configuring database for Laravel project..."
    
    # Update .env file with database configuration
    sed -i "s/DB_DATABASE=laravel/DB_DATABASE=${project_name}_dev/" "$project_path/.env"
    sed -i "s/DB_USERNAME=root/DB_USERNAME=yads/" "$project_path/.env"
    sed -i "s/DB_PASSWORD=/DB_PASSWORD=yads_dev_$(openssl rand -base64 16)/" "$project_path/.env"
    
    # Run migrations
    cd "$project_path"
    php artisan migrate
    
    success "Database configured for Laravel project"
}

# Install Laravel packages
install_laravel_packages() {
    local project_path="$1"
    
    info "Installing Laravel development packages..."
    
    cd "$project_path"
    
    # Install common development packages
    composer require --dev laravel/telescope
    composer require --dev barryvdh/laravel-debugbar
    composer require --dev spatie/laravel-query-builder
    
    # Install frontend tools
    npm install --save-dev @vitejs/plugin-laravel
    npm install --save-dev vite
    
    success "Laravel packages installed"
}

# Set up Laravel development tools
setup_laravel_development_tools() {
    local project_path="$1"
    
    info "Setting up Laravel development tools..."
    
    cd "$project_path"
    
    # Publish Telescope
    php artisan telescope:install
    php artisan migrate
    
    # Configure debug bar
    php artisan vendor:publish --provider="Barryvdh\Debugbar\ServiceProvider"
    
    success "Laravel development tools configured"
}

# Create Symfony project
create_symfony_project() {
    local project_name="$1"
    local project_path="/var/www/html/$project_name"
    
    info "Creating Symfony project..."
    
    # Create Symfony project
    composer create-project symfony/skeleton "$project_path"
    
    if [[ $? -ne 0 ]]; then
        error_exit "Failed to create Symfony project"
    fi
    
    # Install Symfony web app
    cd "$project_path"
    composer require symfony/webapp-pack
    
    success "Symfony project created"
}

# Create CodeIgniter project
create_codeigniter_project() {
    local project_name="$1"
    local project_path="/var/www/html/$project_name"
    
    info "Creating CodeIgniter project..."
    
    # Create CodeIgniter project
    composer create-project codeigniter4/appstarter "$project_path"
    
    if [[ $? -ne 0 ]]; then
        error_exit "Failed to create CodeIgniter project"
    fi
    
    success "CodeIgniter project created"
}

# Create custom PHP project
create_custom_php_project() {
    local project_name="$1"
    local project_path="/var/www/html/$project_name"
    
    info "Creating custom PHP project..."
    
    # Create project structure
    mkdir -p "$project_path"/{public,src,config,tests}
    
    # Create basic index.php
    cat > "$project_path/public/index.php" << 'EOF'
<?php
// Custom PHP Project
echo "<h1>Welcome to your custom PHP project!</h1>";
echo "<p>Project created with YADS</p>";
phpinfo();
?>
EOF
    
    # Create basic .htaccess
    cat > "$project_path/public/.htaccess" << 'EOF'
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ index.php [QSA,L]
EOF
    
    success "Custom PHP project created"
}

# Create WordPress project
create_wordpress_project() {
    local project_name="$1"
    local project_path="/var/www/html/$project_name"
    
    info "Creating WordPress project..."
    
    # Download WordPress
    wget -O wordpress.tar.gz https://wordpress.org/latest.tar.gz
    tar -xzf wordpress.tar.gz
    mv wordpress "$project_path"
    rm wordpress.tar.gz
    
    # Set up WordPress configuration
    cp "$project_path/wp-config-sample.php" "$project_path/wp-config.php"
    
    # Generate WordPress salts
    local salts=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
    sed -i "/put your unique phrase here/d" "$project_path/wp-config.php"
    sed -i "/AUTH_KEY/a\\$salts" "$project_path/wp-config.php"
    
    # Configure database
    sed -i "s/database_name_here/${project_name}_dev/" "$project_path/wp-config.php"
    sed -i "s/username_here/yads/" "$project_path/wp-config.php"
    sed -i "s/password_here/yads_dev_$(openssl rand -base64 16)/" "$project_path/wp-config.php"
    sed -i "s/localhost/127.0.0.1/" "$project_path/wp-config.php"
    
    success "WordPress project created"
}

# Create project directory
create_project_directory() {
    local project_name="$1"
    local project_path="/var/www/html/$project_name"
    
    info "Creating project directory..."
    
    # Create directory with proper permissions
    sudo mkdir -p "$project_path"
    sudo chown -R www-data:www-data "$project_path"
    sudo chmod -R 755 "$project_path"
    
    success "Project directory created"
}

# Set project permissions
set_project_permissions() {
    local project_name="$1"
    local project_path="/var/www/html/$project_name"
    
    info "Setting up project permissions..."
    
    # Set ownership
    sudo chown -R www-data:www-data "$project_path"
    
    # Set permissions
    sudo find "$project_path" -type d -exec chmod 755 {} \;
    sudo find "$project_path" -type f -exec chmod 644 {} \;
    
    # Make storage writable for Laravel
    if [[ -d "$project_path/storage" ]]; then
        sudo chmod -R 775 "$project_path/storage"
        sudo chmod -R 775 "$project_path/bootstrap/cache"
    fi
    
    # Make uploads writable for WordPress
    if [[ -d "$project_path/wp-content" ]]; then
        sudo chmod -R 775 "$project_path/wp-content"
    fi
    
    success "Project permissions configured"
}

# Create project database
create_project_database() {
    local project_name="$1"
    local db_name="${project_name}_dev"
    local db_user="yads"
    local db_password="yads_dev_$(openssl rand -base64 16)"
    
    info "Creating database for project..."
    
    # Create MySQL database
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS \`$db_name\`;"
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_password';"
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$db_user'@'localhost';"
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"
    
    # Create PostgreSQL database
    sudo -u postgres psql -c "CREATE DATABASE ${db_name}_pg;"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${db_name}_pg TO yads;"
    
    # Save database credentials
    echo "DB_NAME_${project_name^^}='$db_name'" >> "$CONFIG_FILE"
    echo "DB_USER_${project_name^^}='$db_user'" >> "$CONFIG_FILE"
    echo "DB_PASSWORD_${project_name^^}='$db_password'" >> "$CONFIG_FILE"
    
    success "Database created for project"
}

# Set up development environment
setup_development_environment() {
    local project_name="$1"
    local project_path="/var/www/html/$project_name"
    
    info "Setting up development environment..."
    
    # Create development configuration
    create_development_config "$project_name" "$project_path"
    
    # Set up Git repository
    setup_git_repository "$project_name" "$project_path"
    
    # Create development scripts
    create_development_scripts "$project_name" "$project_path"
    
    success "Development environment configured"
}

# Create development configuration
create_development_config() {
    local project_name="$1"
    local project_path="$2"
    
    info "Creating development configuration..."
    
    # Create .yads directory in project
    mkdir -p "$project_path/.yads"
    
    # Create project configuration
    cat > "$project_path/.yads/config" << EOF
PROJECT_NAME="$project_name"
PROJECT_TYPE="$PROJECT_TYPE"
PROJECT_DOMAIN="${project_name}.${DOMAIN}"
PROJECT_PATH="$project_path"
CREATED_DATE="$(date)"
EOF
    
    success "Development configuration created"
}

# Set up Git repository
setup_git_repository() {
    local project_name="$1"
    local project_path="$2"
    
    info "Setting up Git repository..."
    
    cd "$project_path"
    
    # Initialize Git repository
    git init
    
    # Create .gitignore
    create_gitignore "$project_path"
    
    # Initial commit
    git add .
    git commit -m "Initial commit - Project created with YADS"
    
    success "Git repository initialized"
}

# Create .gitignore file
create_gitignore() {
    local project_path="$1"
    
    cat > "$project_path/.gitignore" << 'EOF'
# YADS Development
.yads/
*.log

# Environment files
.env
.env.local
.env.production

# Dependencies
node_modules/
vendor/

# IDE files
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Cache
cache/
storage/logs/
storage/framework/cache/
storage/framework/sessions/
storage/framework/views/

# Uploads
public/uploads/
uploads/

# Database
*.sqlite
*.db

# Temporary files
tmp/
temp/
EOF
}

# Create development scripts
create_development_scripts() {
    local project_name="$1"
    local project_path="$2"
    
    info "Creating development scripts..."
    
    # Create development script
    cat > "$project_path/dev.sh" << 'EOF'
#!/bin/bash
# Development script for YADS project

case "${1:-help}" in
    "start")
        echo "Starting development server..."
        php artisan serve --host=0.0.0.0 --port=8000
        ;;
    "build")
        echo "Building frontend assets..."
        npm run build
        ;;
    "test")
        echo "Running tests..."
        php artisan test
        ;;
    "migrate")
        echo "Running migrations..."
        php artisan migrate
        ;;
    "seed")
        echo "Seeding database..."
        php artisan db:seed
        ;;
    "fresh")
        echo "Fresh migration and seeding..."
        php artisan migrate:fresh --seed
        ;;
    *)
        echo "Available commands:"
        echo "  start   - Start development server"
        echo "  build   - Build frontend assets"
        echo "  test    - Run tests"
        echo "  migrate - Run migrations"
        echo "  seed    - Seed database"
        echo "  fresh   - Fresh migration and seeding"
        ;;
esac
EOF
    
    chmod +x "$project_path/dev.sh"
    
    success "Development scripts created"
}

# List all projects
list_projects() {
    info "Available projects:"
    echo
    
    for project in /var/www/html/*; do
        if [[ -d "$project" && "$(basename "$project")" != "html" ]]; then
            local project_name=$(basename "$project")
            local project_type="Unknown"
            
            if [[ -f "$project/artisan" ]]; then
                project_type="Laravel"
            elif [[ -f "$project/bin/console" ]]; then
                project_type="Symfony"
            elif [[ -f "$project/wp-config.php" ]]; then
                project_type="WordPress"
            elif [[ -f "$project/index.php" ]]; then
                project_type="Custom PHP"
            fi
            
            echo "  ${GREEN}$project_name${NC} - $project_type"
            echo "    Domain: https://${project_name}.${DOMAIN}"
            echo "    Path: $project"
            echo
        fi
    done
}

# Remove project
remove_project() {
    local project_name="$1"
    local project_path="/var/www/html/$project_name"
    
    if [[ ! -d "$project_path" ]]; then
        error_exit "Project '$project_name' does not exist"
    fi
    
    warning "This will permanently delete the project '$project_name' and its database."
    read -p "Are you sure? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        info "Removing project..."
        
        # Remove project directory
        sudo rm -rf "$project_path"
        
        # Remove database
        mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS \`${project_name}_dev\`;"
        
        # Remove web server configuration
        if [[ "$WEB_SERVER" == "nginx" ]]; then
            sudo rm -f "/etc/nginx/sites-enabled/${project_name}"
            sudo rm -f "/etc/nginx/sites-available/${project_name}"
            sudo systemctl reload nginx
        fi
        
        success "Project '$project_name' removed"
    else
        info "Project removal cancelled"
    fi
}

