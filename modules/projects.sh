#!/bin/bash

# Project creation module for YADS

# Create a new project
create_project() {
    local project_name="$1"
    local git_repo="$2"
    
    # Validate project name
    if [[ ! "$project_name" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$ ]]; then
        error_exit "Invalid project name. Use only letters, numbers, and hyphens."
    fi
    
    log "${CYAN}Creating project: $project_name${NC}"
    
    # Check if project already exists
    if [[ -d "/var/www/html/$project_name" ]]; then
        error_exit "Project '$project_name' already exists"
    fi
    
    # Create development folder structure
    create_development_folder_structure "$project_name"
    
    # Handle Git repository if provided
    if [[ -n "$git_repo" ]]; then
        clone_git_repository "$project_name" "$git_repo"
    else
        # Choose project type for default setup
        choose_project_type "$project_name"
    fi
    
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
    info "Development folder: $HOME/development/$project_name"
}

# Create development folder structure
create_development_folder_structure() {
    local project_name="$1"
    local dev_folder="$HOME/development/$project_name"
    
    info "Creating development folder structure..."
    
    # Create development folder
    mkdir -p "$dev_folder"
    
    # Create public folder
    mkdir -p "$dev_folder/public"
    
    # Create status page
    create_status_page "$dev_folder/public"
    
    success "Development folder structure created at: $dev_folder"
}

# Create status page
create_status_page() {
    local public_dir="$1"
    
    info "Creating status page..."
    
    # Create index.html with status information
    cat > "$public_dir/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>YADS Development Server</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
        }
        
        .container {
            text-align: center;
            background: rgba(255, 255, 255, 0.1);
            padding: 3rem;
            border-radius: 20px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
            border: 1px solid rgba(255, 255, 255, 0.18);
            max-width: 600px;
            width: 90%;
        }
        
        .logo {
            font-size: 3rem;
            font-weight: bold;
            margin-bottom: 1rem;
            background: linear-gradient(45deg, #ff6b6b, #4ecdc4);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        
        .status {
            font-size: 1.2rem;
            margin-bottom: 2rem;
            opacity: 0.9;
        }
        
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            margin: 2rem 0;
        }
        
        .info-card {
            background: rgba(255, 255, 255, 0.1);
            padding: 1.5rem;
            border-radius: 10px;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        
        .info-card h3 {
            margin-bottom: 0.5rem;
            color: #4ecdc4;
        }
        
        .info-card p {
            opacity: 0.8;
        }
        
        .server-info {
            margin-top: 2rem;
            padding: 1rem;
            background: rgba(0, 0, 0, 0.2);
            border-radius: 10px;
            font-family: 'Courier New', monospace;
            font-size: 0.9rem;
        }
        
        .status-indicator {
            display: inline-block;
            width: 12px;
            height: 12px;
            background: #4ecdc4;
            border-radius: 50%;
            margin-right: 8px;
            animation: pulse 2s infinite;
        }
        
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.5; }
            100% { opacity: 1; }
        }
        
        .footer {
            margin-top: 2rem;
            opacity: 0.7;
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">YADS</div>
        <div class="status">
            <span class="status-indicator"></span>
            Development Server Running
        </div>
        
        <div class="info-grid">
            <div class="info-card">
                <h3>Server Status</h3>
                <p>Online and Ready</p>
            </div>
            <div class="info-card">
                <h3>PHP Version</h3>
                <p id="php-version">Loading...</p>
            </div>
            <div class="info-card">
                <h3>Server Software</h3>
                <p id="server-software">Loading...</p>
            </div>
            <div class="info-card">
                <h3>Document Root</h3>
                <p id="document-root">Loading...</p>
            </div>
        </div>
        
        <div class="server-info">
            <div><strong>Server:</strong> <span id="server-name">YADS Development Server</span></div>
            <div><strong>Document Root:</strong> <span id="doc-root">/var/www/html</span></div>
            <div><strong>Request Time:</strong> <span id="request-time"></span></div>
            <div><strong>User Agent:</strong> <span id="user-agent"></span></div>
        </div>
        
        <div class="footer">
            <p>Yet Another Development Server - Powered by YADS</p>
            <p>Ready for PHP development with modern tooling</p>
        </div>
    </div>
    
    <script>
        // Update dynamic content
        document.getElementById('request-time').textContent = new Date().toLocaleString();
        document.getElementById('user-agent').textContent = navigator.userAgent;
        
        // Try to get PHP info via AJAX
        fetch('phpinfo.php')
            .then(response => response.text())
            .then(data => {
                // Extract PHP version from response
                const phpMatch = data.match(/PHP Version (\d+\.\d+\.\d+)/);
                if (phpMatch) {
                    document.getElementById('php-version').textContent = phpMatch[1];
                }
            })
            .catch(() => {
                document.getElementById('php-version').textContent = 'PHP 8.4+';
            });
        
        // Detect server software
        const serverSoftware = navigator.userAgent.includes('nginx') ? 'NGINX' : 
                              navigator.userAgent.includes('apache') ? 'Apache' : 'YADS Server';
        document.getElementById('server-software').textContent = serverSoftware;
        
        // Set document root
        document.getElementById('doc-root').textContent = window.location.pathname;
    </script>
</body>
</html>
EOF
    
    # Create phpinfo.php for dynamic content
    cat > "$public_dir/phpinfo.php" << 'EOF'
<?php
// Simple PHP info for YADS status page
header('Content-Type: text/html; charset=utf-8');

$phpInfo = [
    'version' => PHP_VERSION,
    'server' => $_SERVER['SERVER_SOFTWARE'] ?? 'YADS Development Server',
    'document_root' => $_SERVER['DOCUMENT_ROOT'] ?? '/var/www/html',
    'request_time' => date('Y-m-d H:i:s'),
    'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown'
];

// Return JSON for AJAX requests
if (isset($_GET['ajax'])) {
    header('Content-Type: application/json');
    echo json_encode($phpInfo);
    exit;
}

// Return HTML for direct access
echo "<!DOCTYPE html><html><head><title>PHP Info - YADS</title></head><body>";
echo "<h1>YADS PHP Information</h1>";
echo "<p><strong>PHP Version:</strong> " . $phpInfo['version'] . "</p>";
echo "<p><strong>Server:</strong> " . $phpInfo['server'] . "</p>";
echo "<p><strong>Document Root:</strong> " . $phpInfo['document_root'] . "</p>";
echo "<p><strong>Request Time:</strong> " . $phpInfo['request_time'] . "</p>";
echo "<p><strong>User Agent:</strong> " . $phpInfo['user_agent'] . "</p>";
echo "<p><a href='index.html'>← Back to Status Page</a></p>";
echo "</body></html>";
?>
EOF
    
    success "Status page created"
}

# Clone Git repository
clone_git_repository() {
    local project_name="$1"
    local git_repo="$2"
    local dev_folder="$HOME/development/$project_name"
    
    info "Cloning Git repository: $git_repo"
    
    # Validate Git repository URL
    if [[ ! "$git_repo" =~ ^https?://.*\.git$ ]] && [[ ! "$git_repo" =~ ^git@.*:.*\.git$ ]]; then
        # Try to construct GitHub URL if it's just a repo name
        if [[ ! "$git_repo" =~ / ]]; then
            git_repo="https://github.com/$git_repo.git"
            info "Assuming GitHub repository: $git_repo"
        else
            error_exit "Invalid Git repository URL: $git_repo"
        fi
    fi
    
    # Clone repository
    if git clone "$git_repo" "$dev_folder"; then
        success "Repository cloned successfully"
        
        # Check if there's a public folder in the repo
        if [[ -d "$dev_folder/public" ]]; then
            info "Found public folder in repository"
        else
            # Create public folder and move files
            mkdir -p "$dev_folder/public"
            # Move root files to public folder
            find "$dev_folder" -maxdepth 1 -type f -not -name ".*" -exec mv {} "$dev_folder/public/" \; 2>/dev/null || true
            info "Created public folder and moved files"
        fi
        
        # Create .htaccess for public folder
        cat > "$dev_folder/public/.htaccess" << 'EOF'
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ index.php [QSA,L]
EOF
        
        success "Git repository setup completed"
    else
        error_exit "Failed to clone repository: $git_repo"
    fi
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
    local dev_folder="$HOME/development/$project_name"
    
    info "Creating project directory..."
    
    # Create symlink from web root to development folder
    sudo ln -sf "$dev_folder/public" "$project_path"
    
    # Set proper permissions
    sudo chown -R www-data:www-data "$dev_folder"
    sudo chmod -R 755 "$dev_folder"
    
    success "Project directory linked to development folder"
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

