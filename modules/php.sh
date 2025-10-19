#!/bin/bash

# YADS PHP Module
# Handles PHP installation and version management

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

# Install specific PHP version
install_php_version() {
    local version="$1"
    
    info "🐘 Installing PHP $version..."
    
    # Validate version
    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then
        error_exit "Invalid PHP version format. Use format like 8.2, 7.4, etc."
    fi
    
    # Check if version is supported
    local major_version
    major_version=$(echo "$version" | cut -d. -f1)
    if [[ $major_version -lt 5 ]] || [[ $major_version -gt 8 ]]; then
        error_exit "PHP version $version is not supported. Supported versions: 5.6-8.5"
    fi
    
    detect_os
    
    case "$OS" in
        ubuntu|debian)
            # Add Ondřej Surý's PPA
            add-apt-repository ppa:ondrej/php -y
            apt-get update
            
            # Install PHP version
            apt-get install -y "php${version}" "php${version}-cli" "php${version}-fpm" \
                "php${version}-mysql" "php${version}-pgsql" "php${version}-curl" \
                "php${version}-gd" "php${version}-mbstring" "php${version}-xml" \
                "php${version}-zip" "php${version}-bcmath" "php${version}-intl" \
                "php${version}-redis" "php${version}-sqlite3"
            
            # Set as default PHP version
            update-alternatives --install /usr/bin/php php /usr/bin/php${version} 100
            update-alternatives --install /usr/bin/php-fpm php-fpm /usr/bin/php-fpm${version} 100
            ;;
        centos|rhel|fedora)
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y "php${version}" "php${version}-cli" "php${version}-fpm" \
                    "php${version}-mysqlnd" "php${version}-pgsql" "php${version}-curl" \
                    "php${version}-gd" "php${version}-mbstring" "php${version}-xml" \
                    "php${version}-zip" "php${version}-bcmath" "php${version}-intl" \
                    "php${version}-redis" "php${version}-sqlite3"
            else
                yum install -y "php${version}" "php${version}-cli" "php${version}-fpm" \
                    "php${version}-mysqlnd" "php${version}-pgsql" "php${version}-curl" \
                    "php${version}-gd" "php${version}-mbstring" "php${version}-xml" \
                    "php${version}-zip" "php${version}-bcmath" "php${version}-intl" \
                    "php${version}-redis" "php${version}-sqlite3"
            fi
            ;;
        arch)
            # Arch Linux typically has latest PHP version
            pacman -S --noconfirm php php-fpm php-gd php-intl php-redis php-sqlite
            ;;
        *)
            error_exit "Unsupported OS: $OS"
            ;;
    esac
    
    success "PHP $version installed"
}

# List available PHP versions
list_php_versions() {
    info "📋 Available PHP versions:"
    
    case "$OS" in
        ubuntu|debian)
            apt-cache search php | grep -E '^php[0-9]+\.[0-9]+ ' | sort -V
            ;;
        centos|rhel|fedora)
            if command -v dnf >/dev/null 2>&1; then
                dnf search php | grep -E 'php[0-9]+\.[0-9]+' | sort -V
            else
                yum search php | grep -E 'php[0-9]+\.[0-9]+' | sort -V
            fi
            ;;
        arch)
            pacman -Ss php | grep -E 'php[0-9]+\.[0-9]+' | sort -V
            ;;
    esac
}

# Show current PHP version
show_current_version() {
    if command -v php >/dev/null 2>&1; then
        local current_version
        current_version=$(php -v | head -1 | cut -d' ' -f2 | cut -d'.' -f1-2)
        info "Current PHP version: $current_version"
    else
        warning "PHP is not installed"
    fi
}

# Install Composer
install_composer() {
    info "🎼 Installing Composer..."
    
    if command -v composer >/dev/null 2>&1; then
        info "Composer already installed"
        return
    fi
    
    # Download and install Composer
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
    
    # Install Laravel installer globally
    composer global require laravel/installer
    
    success "Composer and Laravel installer installed"
}

# Main PHP function
php_main() {
    setup_colors
    detect_os
    
    case "${1:-}" in
        "")
            show_current_version
            info "Use 'yads php <version>' to install a specific PHP version"
            info "Use 'yads php list' to see available versions"
            ;;
        list)
            list_php_versions
            ;;
        [0-9]*\.[0-9]*)
            install_php_version "$1"
            ;;
        composer)
            install_composer
            ;;
        *)
            error_exit "Unknown PHP option: $1"
            ;;
    esac
}
