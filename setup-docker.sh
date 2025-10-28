#!/bin/bash

# YADS Docker Setup Script
# Sets up the complete Docker-based development environment

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

# Check if Docker is installed
check_docker() {
    info "🔍 Checking Docker installation..."
    
    if ! command -v docker >/dev/null 2>&1; then
        error_exit "Docker is not installed. Please install Docker first."
    fi
    
    if ! command -v docker-compose >/dev/null 2>&1; then
        error_exit "Docker Compose is not installed. Please install Docker Compose first."
    fi
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        error_exit "Docker is not running. Please start Docker first."
    fi
    
    success "Docker and Docker Compose are installed and running"
}

# Create environment file
create_env_file() {
    info "📝 Creating environment configuration..."
    
    if [[ -f ".env" ]]; then
        warning ".env file already exists. Backing up to .env.backup"
        cp .env .env.backup
    fi
    
    if [[ -f "env.example" ]]; then
        cp env.example .env
        success "Environment file created from template"
        info "Please edit .env file with your configuration"
    else
        error_exit "env.example file not found"
    fi
}

# Create necessary directories
create_directories() {
    info "📁 Creating necessary directories..."
    
    local dirs=(
        "data/traefik"
        "data/mysql"
        "data/postgres"
        "data/redis"
        "data/vscode"
        "data/pgadmin"
        "data/portainer"
        "projects"
        "config/traefik"
        "config/nginx"
        "config/php"
        "config/mysql"
        "config/postgres"
        "logs"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done
    
    # Set proper permissions
    chmod 600 "data/traefik/acme.json" 2>/dev/null || true
    
    success "Directories created"
}

# Create Traefik configuration
create_traefik_config() {
    info "🔧 Creating Traefik configuration..."
    
    # Create acme.json with proper permissions
    touch data/traefik/acme.json
    chmod 600 data/traefik/acme.json
    
    # Create dynamic configuration if it doesn't exist
    if [[ ! -f "config/traefik/dynamic.yml" ]]; then
        cat > config/traefik/dynamic.yml << 'EOF'
# Dynamic Traefik Configuration for YADS
http:
  middlewares:
    security-headers:
      headers:
        customRequestHeaders:
          X-Forwarded-Proto: "https"
        customResponseHeaders:
          X-Frame-Options: "SAMEORIGIN"
          X-Content-Type-Options: "nosniff"
          X-XSS-Protection: "1; mode=block"
          Strict-Transport-Security: "max-age=31536000; includeSubDomains"
EOF
    fi
    
    success "Traefik configuration created"
}

# Create sample project
create_sample_project() {
    info "📁 Creating sample project..."
    
    local project_dir="projects/sample"
    mkdir -p "$project_dir"
    
    cat > "$project_dir/index.php" << 'EOF'
<?php
echo "<h1>Welcome to YADS Docker!</h1>";
echo "<p>PHP Version: " . phpversion() . "</p>";
echo "<p>Server: " . $_SERVER['SERVER_SOFTWARE'] . "</p>";
echo "<p>Document Root: " . $_SERVER['DOCUMENT_ROOT'] . "</p>";
echo "<p>✅ YADS Docker is working correctly!</p>";

// Show PHP info
if (isset($_GET['info'])) {
    phpinfo();
}
?>
EOF
    
    cat > "$project_dir/composer.json" << 'EOF'
{
    "name": "yads/sample-project",
    "description": "Sample project created with YADS Docker",
    "type": "project",
    "require": {
        "php": ">=8.0"
    }
}
EOF
    
    success "Sample project created at projects/sample"
}

# Make scripts executable
make_executable() {
    info "🔧 Making scripts executable..."
    
    chmod +x yads-docker
    chmod +x setup-docker.sh
    
    success "Scripts made executable"
}

# Create symlink for easy access
create_symlink() {
    info "🔗 Creating symlink for easy access..."
    
    # Create symlink in /usr/local/bin if possible
    if [[ -w "/usr/local/bin" ]] || sudo -n true 2>/dev/null; then
        if sudo -n true 2>/dev/null; then
            sudo ln -sf "$(pwd)/yads-docker" /usr/local/bin/yads-docker
        else
            ln -sf "$(pwd)/yads-docker" /usr/local/bin/yads-docker
        fi
        success "Symlink created: yads-docker command available globally"
    else
        info "Could not create global symlink. You can run: ./yads-docker"
    fi
}

# Show setup summary
show_summary() {
    info "📋 YADS Docker Setup Summary:"
    echo
    success "✅ Docker environment configured"
    success "✅ Directories created"
    success "✅ Configuration files created"
    success "✅ Sample project created"
    success "✅ Scripts made executable"
    echo
    info "🚀 Next steps:"
    echo "  1. Edit .env file with your configuration"
    echo "  2. Run: yads-docker start"
    echo "  3. Access services via subdomains"
    echo
    info "📝 Important configuration:"
    echo "  - Set DOMAIN in .env file"
    echo "  - Configure Cloudflare tokens"
    echo "  - Set secure passwords"
    echo
    info "🌐 Service URLs (after starting):"
    echo "  - Traefik Dashboard: https://traefik.\$DOMAIN"
    echo "  - VS Code Server: https://code.\$DOMAIN"
    echo "  - phpMyAdmin: https://phpmyadmin.\$DOMAIN"
    echo "  - pgAdmin: https://pgadmin.\$DOMAIN"
    echo "  - Portainer: https://portainer.\$DOMAIN"
    echo "  - Sample Project: https://sample.\$DOMAIN"
}

# Main setup function
main() {
    setup_colors
    
    log "${CYAN}🚀 YADS Docker Setup${NC}"
    log "${BLUE}===================${NC}"
    echo
    
    # Check prerequisites
    check_docker
    
    # Create environment file
    create_env_file
    
    # Create directories
    create_directories
    
    # Create Traefik configuration
    create_traefik_config
    
    # Create sample project
    create_sample_project
    
    # Make scripts executable
    make_executable
    
    # Create symlink
    create_symlink
    
    # Show summary
    show_summary
}

# Run main function
main "$@"
