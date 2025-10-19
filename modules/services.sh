#!/bin/bash

# YADS Services Module
# Handles service management (start, stop, restart, status)

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

# List of YADS services
YADS_SERVICES=(
    "vscode-server"
    "cloudflared"
    "mysql"
    "postgresql"
    "redis-server"
    "apache2"
    "nginx"
    "frankenphp"
)

# Start services
start_services() {
    info "🚀 Starting YADS services..."
    
    for service in "${YADS_SERVICES[@]}"; do
        if systemctl list-unit-files | grep -q "^$service.service"; then
            if ! systemctl is-active --quiet "$service"; then
                info "Starting $service..."
                systemctl start "$service"
                systemctl enable "$service"
            else
                info "$service is already running"
            fi
        fi
    done
    
    success "Services started"
}

# Stop services
stop_services() {
    info "🛑 Stopping YADS services..."
    
    for service in "${YADS_SERVICES[@]}"; do
        if systemctl list-unit-files | grep -q "^$service.service"; then
            if systemctl is-active --quiet "$service"; then
                info "Stopping $service..."
                systemctl stop "$service"
            else
                info "$service is already stopped"
            fi
        fi
    done
    
    success "Services stopped"
}

# Restart services
restart_services() {
    info "🔄 Restarting YADS services..."
    
    for service in "${YADS_SERVICES[@]}"; do
        if systemctl list-unit-files | grep -q "^$service.service"; then
            if systemctl is-active --quiet "$service"; then
                info "Restarting $service..."
                systemctl restart "$service"
            else
                info "Starting $service..."
                systemctl start "$service"
                systemctl enable "$service"
            fi
        fi
    done
    
    success "Services restarted"
}

# Show service status
show_status() {
    info "📊 YADS Service Status:"
    echo
    
    # Core services
    log "${WHITE}Core Services:${NC}"
    show_service_status "vscode-server" "VS Code Server"
    show_service_status "cloudflared" "Cloudflared Tunnel"
    show_cursor_cli_status
    echo
    
    # Web servers
    log "${WHITE}Web Servers:${NC}"
    show_service_status "apache2" "Apache2"
    show_service_status "nginx" "Nginx"
    show_service_status "frankenphp" "FrankenPHP"
    echo
    
    # Databases
    log "${WHITE}Databases:${NC}"
    show_service_status "mysql" "MySQL"
    show_service_status "postgresql" "PostgreSQL"
    show_service_status "redis-server" "Redis"
    echo
    
    # Show access information
    show_access_info
}

# Show individual service status
show_service_status() {
    local service="$1"
    local display_name="$2"
    
    # Check if service exists (handle different service names)
    local service_exists=false
    local actual_service=""
    
    # Check for exact service name first
    if systemctl list-unit-files | grep -q "^$service.service"; then
        service_exists=true
        actual_service="$service"
    # Check for alternative service names
    elif [[ "$service" == "apache2" ]] && systemctl list-unit-files | grep -q "^apache2.service"; then
        service_exists=true
        actual_service="apache2"
    elif [[ "$service" == "apache2" ]] && systemctl list-unit-files | grep -q "^httpd.service"; then
        service_exists=true
        actual_service="httpd"
    elif [[ "$service" == "mysql" ]] && systemctl list-unit-files | grep -q "^mysqld.service"; then
        service_exists=true
        actual_service="mysqld"
    fi
    
    if [[ "$service_exists" == true ]]; then
        if systemctl is-active --quiet "$actual_service"; then
            success "$display_name: Running"
        else
            warning "$display_name: Stopped"
        fi
    else
        info "$display_name: Not installed"
    fi
}

# Show Cursor CLI status
show_cursor_cli_status() {
    if command -v cursor-agent >/dev/null 2>&1; then
        success "Cursor CLI: Installed"
    else
        info "Cursor CLI: Not installed"
    fi
}

# Show access information
show_access_info() {
    log "${WHITE}Access Information:${NC}"
    
    # VS Code Server
    if systemctl is-active --quiet vscode-server; then
        info "VS Code Server: http://localhost:8080"
        if [[ -f "/opt/vscode-server/.password" ]]; then
            local password
            password=$(cat /opt/vscode-server/.password)
            info "Password: $password"
        fi
    fi
    
    # Web server - check which one is actually running
    if systemctl is-active --quiet apache2 || systemctl is-active --quiet httpd; then
        info "Web Server: Apache2 running on port 80"
    elif systemctl is-active --quiet nginx; then
        info "Web Server: Nginx running on port 80"
    elif systemctl is-active --quiet frankenphp; then
        info "Web Server: FrankenPHP running on port 80"
    else
        info "Web Server: No web server detected as running"
    fi
    
    # Projects
    info "Projects: /var/www/projects"
    info "Remote access: https://*.remote.domain.tld (when tunnel is configured)"
}

# Start specific service
start_service() {
    local service="$1"
    
    if [[ -z "$service" ]]; then
        error_exit "Service name required"
    fi
    
    if ! systemctl list-unit-files | grep -q "^$service.service"; then
        error_exit "Service '$service' not found"
    fi
    
    info "Starting $service..."
    systemctl start "$service"
    systemctl enable "$service"
    
    success "$service started"
}

# Stop specific service
stop_service() {
    local service="$1"
    
    if [[ -z "$service" ]]; then
        error_exit "Service name required"
    fi
    
    if ! systemctl list-unit-files | grep -q "^$service.service"; then
        error_exit "Service '$service' not found"
    fi
    
    info "Stopping $service..."
    systemctl stop "$service"
    
    success "$service stopped"
}

# Restart specific service
restart_service() {
    local service="$1"
    
    if [[ -z "$service" ]]; then
        error_exit "Service name required"
    fi
    
    if ! systemctl list-unit-files | grep -q "^$service.service"; then
        error_exit "Service '$service' not found"
    fi
    
    info "Restarting $service..."
    systemctl restart "$service"
    
    success "$service restarted"
}

# Main services function
services_main() {
    setup_colors
    
    local command="$1"
    shift 2>/dev/null || true
    
    case "$command" in
        start)
            if [[ -n "${1:-}" ]]; then
                start_service "$1"
            else
                start_services
            fi
            ;;
        stop)
            if [[ -n "${1:-}" ]]; then
                stop_service "$1"
            else
                stop_services
            fi
            ;;
        restart)
            if [[ -n "${1:-}" ]]; then
                restart_service "$1"
            else
                restart_services
            fi
            ;;
        status)
            show_status
            ;;
        *)
            error_exit "Unknown service command: $command"
            ;;
    esac
}
