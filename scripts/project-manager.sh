#!/bin/bash

# YADS Project Manager
# Handles project creation, management, and deployment

set -euo pipefail

# Color setup
setup_colors() {
    if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;94m'
        CYAN='\033[0;96m'
        WHITE='\033[1;37m'
        GRAY='\033[0;37m'
        NC='\033[0m'
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

# Get project directory
get_project_dir() {
    local project_name="$1"
    echo "projects/$project_name"
}

# Create project structure
create_project_structure() {
    local project_name="$1"
    local project_type="$2"
    local project_dir
    project_dir=$(get_project_dir "$project_name")
    
    info "📁 Creating project structure for $project_name ($project_type)..."
    
    # Create project directory
    mkdir -p "$project_dir"
    
    # Copy template files
    if [[ -d "templates/$project_type" ]]; then
        cp -r "templates/$project_type"/* "$project_dir/"
        success "Template files copied"
    else
        warning "No template found for $project_type, creating basic structure"
        create_basic_structure "$project_dir" "$project_type"
    fi
    
    # Create environment file
    create_project_env "$project_name" "$project_type" "$project_dir"
    
    # Set proper permissions
    chmod -R 755 "$project_dir"
    
    success "Project structure created"
    info "Project will be accessible at: https://$project_name.\${DOMAIN:-localhost}"
    info "VS Code Server can access the project at: ./projects/$project_name"
}

# Create basic project structure
create_basic_structure() {
    local project_dir="$1"
    local project_type="$2"
    
    case "$project_type" in
        php)
            create_php_structure "$project_dir"
            ;;
        node)
            create_node_structure "$project_dir"
            ;;
        python)
            create_python_structure "$project_dir"
            ;;
        *)
            create_generic_structure "$project_dir"
            ;;
    esac
}

# Create PHP project structure
create_php_structure() {
    local project_dir="$1"
    
    cat > "$project_dir/index.php" << 'EOF'
<?php
echo "<h1>Welcome to " . $_SERVER['HTTP_HOST'] . "</h1>";
echo "<p>PHP Version: " . phpversion() . "</p>";
echo "<p>Server: " . $_SERVER['SERVER_SOFTWARE'] . "</p>";
echo "<p>Document Root: " . $_SERVER['DOCUMENT_ROOT'] . "</p>";
echo "<p>✅ YADS Docker is working correctly!</p>";

if (isset($_GET['info'])) {
    phpinfo();
}
?>
EOF
    
    cat > "$project_dir/composer.json" << 'EOF'
{
    "name": "yads/project",
    "description": "YADS Docker project",
    "type": "project",
    "require": {
        "php": ">=8.0"
    },
    "autoload": {
        "psr-4": {
            "App\\": "src/"
        }
    }
}
EOF
}

# Create Node.js project structure
create_node_structure() {
    local project_dir="$1"
    
    cat > "$project_dir/package.json" << 'EOF'
{
    "name": "yads-project",
    "version": "1.0.0",
    "description": "YADS Docker project",
    "main": "index.js",
    "scripts": {
        "start": "node index.js",
        "dev": "nodemon index.js"
    },
    "dependencies": {
        "express": "^4.18.2"
    },
    "devDependencies": {
        "nodemon": "^3.0.1"
    }
}
EOF
    
    cat > "$project_dir/index.js" << 'EOF'
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
    res.send(`
        <h1>Welcome to ${req.get('host')}</h1>
        <p>Node.js Version: ${process.version}</p>
        <p>Express Server Running</p>
        <p>✅ YADS Docker is working correctly!</p>
    `);
});

app.listen(port, () => {
    console.log(`Server running on port ${port}`);
});
EOF
}

# Create Python project structure
create_python_structure() {
    local project_dir="$1"
    
    cat > "$project_dir/requirements.txt" << 'EOF'
Flask==2.3.3
gunicorn==21.2.0
EOF
    
    cat > "$project_dir/app.py" << 'EOF'
from flask import Flask, request
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return f'''
    <h1>Welcome to {request.host}</h1>
    <p>Python Version: {os.sys.version}</p>
    <p>Flask Server Running</p>
    <p>✅ YADS Docker is working correctly!</p>
    '''

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF
}

# Create generic project structure
create_generic_structure() {
    local project_dir="$1"
    
    cat > "$project_dir/README.md" << 'EOF'
# YADS Docker Project

This is a YADS Docker project.

## Getting Started

1. Edit this README
2. Add your application code
3. Configure your Dockerfile
4. Deploy with YADS Docker

## Development

- Access via subdomain: `https://project-name.yourdomain.com`
- VS Code Server: `https://code.yourdomain.com`
- Database: `https://phpmyadmin.yourdomain.com` or `https://pgadmin.yourdomain.com`
EOF
}

# Enable project (restore from disabled state)
enable_project() {
    local project_name="$1"
    local project_dir
    project_dir=$(get_project_dir "$project_name")
    
    if [[ -d "${project_dir}.disabled" ]]; then
        mv "${project_dir}.disabled" "$project_dir"
        success "Project '$project_name' enabled"
    else
        error_exit "Project '$project_name' not found in disabled state"
    fi
}

# Create project environment file
create_project_env() {
    local project_name="$1"
    local project_type="$2"
    local project_dir="$3"
    
    cat > "$project_dir/.env" << EOF
# Project: $project_name
# Type: $project_type

# Database Configuration
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=${project_name}_dev
DB_USERNAME=yads
DB_PASSWORD=yads123

# PostgreSQL Configuration
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DATABASE=${project_name}_dev
POSTGRES_USERNAME=yads
POSTGRES_PASSWORD=yads123

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=yads123

# Application Configuration
APP_NAME="$project_name"
APP_ENV=development
APP_DEBUG=true
APP_URL=https://$project_name.\${DOMAIN:-localhost}

# Security
APP_KEY=base64:$(openssl rand -base64 32)
EOF
}

# Deploy project
deploy_project() {
    local project_name="$1"
    local project_dir
    project_dir=$(get_project_dir "$project_name")
    
    if [[ ! -d "$project_dir" ]]; then
        error_exit "Project '$project_name' not found"
    fi
    
    info "🚀 Deploying project: $project_name"
    
    # For shared web server, we just need to ensure the project directory exists
    # and the web server is running. No separate container needed.
    
    # Check if web server is running
    if ! docker ps --format "table {{.Names}}" | grep -q "yads-nginx"; then
        warning "Web server not running. Starting YADS services..."
        docker-compose up -d nginx php-fpm
    fi
    
    # Install dependencies if needed
    if [[ -f "$project_dir/composer.json" ]]; then
        info "Installing PHP dependencies..."
        docker exec yads-php-fpm composer install --working-dir="/var/www/html/$project_name" --no-dev --optimize-autoloader
    fi
    
    if [[ -f "$project_dir/package.json" ]]; then
        info "Installing Node.js dependencies..."
        docker exec yads-php-fpm npm install --prefix="/var/www/html/$project_name"
    fi
    
    success "Project '$project_name' deployed"
    info "Access at: https://$project_name.\${DOMAIN:-localhost}"
    info "VS Code Server: https://code.\${DOMAIN:-localhost}"
}

# Stop project
stop_project() {
    local project_name="$1"
    local project_dir
    project_dir=$(get_project_dir "$project_name")
    
    if [[ ! -d "$project_dir" ]]; then
        error_exit "Project '$project_name' not found"
    fi
    
    info "🛑 Stopping project: $project_name"
    
    # For shared web server, we just remove the project directory
    # or move it to a disabled state
    if [[ -d "$project_dir" ]]; then
        mv "$project_dir" "${project_dir}.disabled"
        success "Project '$project_name' stopped (moved to .disabled)"
    else
        warning "Project directory not found"
    fi
}

# List projects
list_projects() {
    info "📁 Available projects:"
    
    if [[ ! -d "projects" ]]; then
        info "No projects directory found"
        return
    fi
    
    for project in projects/*; do
        if [[ -d "$project" ]]; then
            local project_name
            project_name=$(basename "$project")
            local status="Active"
            info "  - $project_name ($status) - https://$project_name.\${DOMAIN:-localhost}"
        fi
    done
    
    # Also show disabled projects
    for project in projects/*.disabled; do
        if [[ -d "$project" ]]; then
            local project_name
            project_name=$(basename "$project" .disabled)
            local status="Disabled"
            info "  - $project_name ($status)"
        fi
    done
}

# Show project status
show_project_status() {
    local project_name="$1"
    local project_dir
    project_dir=$(get_project_dir "$project_name")
    
    if [[ ! -d "$project_dir" ]]; then
        error_exit "Project '$project_name' not found"
    fi
    
    info "📊 Project Status: $project_name"
    
    # Check if container is running
    if docker ps --format "table {{.Names}}" | grep -q "yads-$project_name"; then
        success "Status: Running"
        info "Access: https://$project_name.\${DOMAIN:-localhost}"
    else
        warning "Status: Stopped"
    fi
    
    # Show container logs
    info "Recent logs:"
    docker logs "yads-$project_name" --tail 10 2>/dev/null || info "No logs available"
}

# Main function
main() {
    setup_colors
    
    local command="${1:-}"
    shift 2>/dev/null || true
    
    case "$command" in
        create)
            if [[ -z "${1:-}" ]]; then
                error_exit "Project name required. Use: $0 create <name> [type]"
            fi
            create_project_structure "$1" "${2:-php}"
            ;;
        deploy)
            if [[ -z "${1:-}" ]]; then
                error_exit "Project name required. Use: $0 deploy <name>"
            fi
            deploy_project "$1"
            ;;
        stop)
            if [[ -z "${1:-}" ]]; then
                error_exit "Project name required. Use: $0 stop <name>"
            fi
            stop_project "$1"
            ;;
        enable)
            if [[ -z "${1:-}" ]]; then
                error_exit "Project name required. Use: $0 enable <name>"
            fi
            enable_project "$1"
            ;;
        list)
            list_projects
            ;;
        status)
            if [[ -z "${1:-}" ]]; then
                error_exit "Project name required. Use: $0 status <name>"
            fi
            show_project_status "$1"
            ;;
        *)
            echo "Usage: $0 <command> [options]"
            echo
            echo "Commands:"
            echo "  create <name> [type]  Create new project"
            echo "  deploy <name>        Deploy project"
            echo "  stop <name>          Stop project (disable)"
            echo "  enable <name>        Enable project (restore)"
            echo "  list                 List all projects"
            echo "  status <name>        Show project status"
            echo
            echo "Project types: php, node, python, laravel, symfony, wordpress"
            echo
            echo "Note: Projects use shared web server. No separate containers needed."
            ;;
    esac
}

# Run main function
main "$@"
