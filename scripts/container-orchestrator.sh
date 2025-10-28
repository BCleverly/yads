#!/bin/bash

# YADS Container Orchestrator
# Handles container lifecycle, scaling, and orchestration

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

# Get YADS directory
get_yads_dir() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "$(dirname "$script_dir")"
}

YADS_DIR="$(get_yads_dir)"

# Container Health Monitoring

# Check container health
check_container_health() {
    local container_name="$1"
    
    if ! docker ps --format "table {{.Names}}" | grep -q "$container_name"; then
        echo "stopped"
        return
    fi
    
    local health_status
    health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "unknown")
    
    case "$health_status" in
        "healthy")
            echo "healthy"
            ;;
        "unhealthy")
            echo "unhealthy"
            ;;
        "starting")
            echo "starting"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Monitor all containers
monitor_containers() {
    info "🔍 Monitoring YADS containers..."
    
    local containers=(
        "yads-traefik"
        "yads-cloudflared"
        "yads-vscode-server"
        "yads-mysql"
        "yads-postgres"
        "yads-redis"
        "yads-nginx"
        "yads-php-fpm"
        "yads-phpmyadmin"
        "yads-pgadmin"
        "yads-portainer"
    )
    
    for container in "${containers[@]}"; do
        local health
        health=$(check_container_health "$container")
        
        case "$health" in
            "healthy")
                success "$container: Healthy"
                ;;
            "unhealthy")
                warning "$container: Unhealthy"
                ;;
            "starting")
                info "$container: Starting"
                ;;
            "stopped")
                warning "$container: Stopped"
                ;;
            *)
                info "$container: Unknown status"
                ;;
        esac
    done
}

# Container Scaling

# Scale service
scale_service() {
    local service_name="$1"
    local replicas="$2"
    
    info "📈 Scaling service: $service_name to $replicas replicas"
    
    # Scale the service
    docker-compose up -d --scale "$service_name=$replicas"
    
    success "Service '$service_name' scaled to $replicas replicas"
}

# Auto-scale based on load
auto_scale() {
    local service_name="$1"
    local max_replicas="${2:-5}"
    local min_replicas="${3:-1}"
    
    info "🤖 Auto-scaling service: $service_name (min: $min_replicas, max: $max_replicas)"
    
    # Get current CPU usage
    local cpu_usage
    cpu_usage=$(docker stats --no-stream --format "table {{.CPUPerc}}" "$service_name" 2>/dev/null | tail -1 | sed 's/%//' || echo "0")
    
    # Get current replica count
    local current_replicas
    current_replicas=$(docker-compose ps --services | grep -c "$service_name" || echo "1")
    
    info "Current CPU usage: ${cpu_usage}%"
    info "Current replicas: $current_replicas"
    
    # Scale up if CPU usage is high
    if (( $(echo "$cpu_usage > 70" | bc -l) )); then
        if (( current_replicas < max_replicas )); then
            local new_replicas=$((current_replicas + 1))
            scale_service "$service_name" "$new_replicas"
            info "Scaled up to $new_replicas replicas due to high CPU usage"
        fi
    # Scale down if CPU usage is low
    elif (( $(echo "$cpu_usage < 30" | bc -l) )); then
        if (( current_replicas > min_replicas )); then
            local new_replicas=$((current_replicas - 1))
            scale_service "$service_name" "$new_replicas"
            info "Scaled down to $new_replicas replicas due to low CPU usage"
        fi
    else
        info "No scaling needed (CPU usage: ${cpu_usage}%)"
    fi
}

# Container Lifecycle Management

# Start service with dependencies
start_service_with_deps() {
    local service_name="$1"
    
    info "🚀 Starting service with dependencies: $service_name"
    
    # Define service dependencies
    local dependencies=()
    case "$service_name" in
        "php-fpm")
            dependencies=("mysql" "postgres" "redis")
            ;;
        "nginx")
            dependencies=("php-fpm")
            ;;
        "phpmyadmin")
            dependencies=("mysql")
            ;;
        "pgadmin")
            dependencies=("postgres")
            ;;
    esac
    
    # Start dependencies first
    for dep in "${dependencies[@]}"; do
        if ! docker-compose ps --services | grep -q "$dep"; then
            info "Starting dependency: $dep"
            docker-compose up -d "$dep"
        fi
    done
    
    # Start the service
    docker-compose up -d "$service_name"
    
    success "Service '$service_name' started with dependencies"
}

# Stop service and dependents
stop_service_with_deps() {
    local service_name="$1"
    
    info "🛑 Stopping service and dependents: $service_name"
    
    # Find services that depend on this one
    local dependents=()
    case "$service_name" in
        "mysql")
            dependents=("php-fpm" "phpmyadmin")
            ;;
        "postgres")
            dependents=("php-fpm" "pgadmin")
            ;;
        "php-fpm")
            dependents=("nginx")
            ;;
    esac
    
    # Stop dependents first
    for dep in "${dependents[@]}"; do
        if docker-compose ps --services | grep -q "$dep"; then
            info "Stopping dependent: $dep"
            docker-compose stop "$dep"
        fi
    done
    
    # Stop the service
    docker-compose stop "$service_name"
    
    success "Service '$service_name' stopped with dependents"
}

# Container Resource Management

# Set resource limits
set_resource_limits() {
    local service_name="$1"
    local cpu_limit="$2"
    local memory_limit="$3"
    
    info "⚙️  Setting resource limits for $service_name"
    info "CPU: $cpu_limit, Memory: $memory_limit"
    
    # Update docker-compose.yml with resource limits
    local compose_file="$YADS_DIR/docker-compose.yml"
    
    # Create backup
    cp "$compose_file" "$compose_file.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Add resource limits to service
    sed -i "/services:/,/^[a-zA-Z]/ {
        /$service_name:/,/^[a-zA-Z]/ {
            /deploy:/! {
                a\\
    deploy:\\
      resources:\\
        limits:\\
          cpus: '$cpu_limit'\\
          memory: '$memory_limit'\\
        reservations:\\
          cpus: '0.1'\\
          memory: '128M'
            }
        }
    }" "$compose_file"
    
    # Restart service with new limits
    docker-compose up -d "$service_name"
    
    success "Resource limits set for '$service_name'"
}

# Get resource usage
get_resource_usage() {
    local service_name="${1:-}"
    
    if [[ -n "$service_name" ]]; then
        info "📊 Resource usage for $service_name:"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" "$service_name"
    else
        info "📊 Resource usage for all YADS containers:"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" $(docker-compose ps -q)
    fi
}

# Container Networking

# Create network
create_network() {
    local network_name="$1"
    local driver="${2:-bridge}"
    
    info "🌐 Creating network: $network_name"
    
    if docker network ls --format "table {{.Name}}" | grep -q "$network_name"; then
        info "Network '$network_name' already exists"
    else
        docker network create --driver "$driver" "$network_name"
        success "Network '$network_name' created"
    fi
}

# Connect container to network
connect_to_network() {
    local container_name="$1"
    local network_name="$2"
    
    info "🔗 Connecting $container_name to network $network_name"
    
    docker network connect "$network_name" "$container_name"
    
    success "Container '$container_name' connected to network '$network_name'"
}

# Container Logging

# Get container logs
get_container_logs() {
    local container_name="$1"
    local lines="${2:-100}"
    
    info "📋 Logs for $container_name (last $lines lines):"
    docker logs --tail "$lines" "$container_name"
}

# Follow container logs
follow_container_logs() {
    local container_name="$1"
    
    info "📋 Following logs for $container_name:"
    docker logs -f "$container_name"
}

# Container Backup and Restore

# Backup container data
backup_container_data() {
    local container_name="$1"
    local backup_dir="$2"
    
    info "💾 Backing up container data: $container_name"
    
    # Create backup directory
    mkdir -p "$backup_dir"
    
    # Get container volumes
    local volumes
    volumes=$(docker inspect --format='{{range .Mounts}}{{.Source}} {{end}}' "$container_name")
    
    # Backup each volume
    for volume in $volumes; do
        if [[ -d "$volume" ]]; then
            local volume_name
            volume_name=$(basename "$volume")
            info "Backing up volume: $volume_name"
            tar -czf "$backup_dir/${volume_name}.tar.gz" -C "$(dirname "$volume")" "$volume_name"
        fi
    done
    
    success "Container data backed up to: $backup_dir"
}

# Restore container data
restore_container_data() {
    local container_name="$1"
    local backup_dir="$2"
    
    info "🔄 Restoring container data: $container_name"
    
    if [[ ! -d "$backup_dir" ]]; then
        error_exit "Backup directory not found: $backup_dir"
    fi
    
    # Get container volumes
    local volumes
    volumes=$(docker inspect --format='{{range .Mounts}}{{.Source}} {{end}}' "$container_name")
    
    # Restore each volume
    for volume in $volumes; do
        if [[ -d "$volume" ]]; then
            local volume_name
            volume_name=$(basename "$volume")
            local backup_file="$backup_dir/${volume_name}.tar.gz"
            
            if [[ -f "$backup_file" ]]; then
                info "Restoring volume: $volume_name"
                tar -xzf "$backup_file" -C "$(dirname "$volume")"
            fi
        fi
    done
    
    success "Container data restored from: $backup_dir"
}

# Show help
show_help() {
    echo -e "${CYAN}YADS Container Orchestrator${NC}"
    echo -e "${BLUE}Handles container lifecycle, scaling, and orchestration${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "${WHITE}  container-orchestrator.sh <command> [options]${NC}"
    echo
    echo -e "${YELLOW}Commands:${NC}"
    echo -e "${WHITE}  monitor                 Monitor container health${NC}"
    echo -e "${WHITE}  scale <service> <replicas>  Scale service${NC}"
    echo -e "${WHITE}  auto-scale <service> [max] [min]  Auto-scale service${NC}"
    echo -e "${WHITE}  start-with-deps <service>  Start service with dependencies${NC}"
    echo -e "${WHITE}  stop-with-deps <service>   Stop service with dependents${NC}"
    echo -e "${WHITE}  set-limits <service> <cpu> <memory>  Set resource limits${NC}"
    echo -e "${WHITE}  resources [service]       Show resource usage${NC}"
    echo -e "${WHITE}  logs <container> [lines]  Show container logs${NC}"
    echo -e "${WHITE}  follow-logs <container>   Follow container logs${NC}"
    echo -e "${WHITE}  backup <container> <dir>  Backup container data${NC}"
    echo -e "${WHITE}  restore <container> <dir>  Restore container data${NC}"
    echo
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "${GRAY}  container-orchestrator.sh monitor                    # Monitor all containers${NC}"
    echo -e "${GRAY}  container-orchestrator.sh scale php-fpm 3           # Scale PHP-FPM to 3 replicas${NC}"
    echo -e "${GRAY}  container-orchestrator.sh auto-scale nginx 5 1       # Auto-scale Nginx${NC}"
    echo -e "${GRAY}  container-orchestrator.sh resources php-fpm        # Show PHP-FPM resource usage${NC}"
    echo -e "${GRAY}  container-orchestrator.sh logs yads-mysql 50         # Show MySQL logs${NC}"
}

# Main function
main() {
    setup_colors
    
    local command="${1:-}"
    shift 2>/dev/null || true
    
    case "$command" in
        monitor)
            monitor_containers
            ;;
        scale)
            if [[ -z "${1:-}" ]] || [[ -z "${2:-}" ]]; then
                error_exit "Service name and replicas required. Use: $0 scale <service> <replicas>"
            fi
            scale_service "$1" "$2"
            ;;
        auto-scale)
            if [[ -z "${1:-}" ]]; then
                error_exit "Service name required. Use: $0 auto-scale <service> [max] [min]"
            fi
            auto_scale "$1" "${2:-5}" "${3:-1}"
            ;;
        start-with-deps)
            if [[ -z "${1:-}" ]]; then
                error_exit "Service name required. Use: $0 start-with-deps <service>"
            fi
            start_service_with_deps "$1"
            ;;
        stop-with-deps)
            if [[ -z "${1:-}" ]]; then
                error_exit "Service name required. Use: $0 stop-with-deps <service>"
            fi
            stop_service_with_deps "$1"
            ;;
        set-limits)
            if [[ -z "${1:-}" ]] || [[ -z "${2:-}" ]] || [[ -z "${3:-}" ]]; then
                error_exit "Service name, CPU limit, and memory limit required. Use: $0 set-limits <service> <cpu> <memory>"
            fi
            set_resource_limits "$1" "$2" "$3"
            ;;
        resources)
            get_resource_usage "${1:-}"
            ;;
        logs)
            if [[ -z "${1:-}" ]]; then
                error_exit "Container name required. Use: $0 logs <container> [lines]"
            fi
            get_container_logs "$1" "${2:-100}"
            ;;
        follow-logs)
            if [[ -z "${1:-}" ]]; then
                error_exit "Container name required. Use: $0 follow-logs <container>"
            fi
            follow_container_logs "$1"
            ;;
        backup)
            if [[ -z "${1:-}" ]] || [[ -z "${2:-}" ]]; then
                error_exit "Container name and backup directory required. Use: $0 backup <container> <dir>"
            fi
            backup_container_data "$1" "$2"
            ;;
        restore)
            if [[ -z "${1:-}" ]] || [[ -z "${2:-}" ]]; then
                error_exit "Container name and backup directory required. Use: $0 restore <container> <dir>"
            fi
            restore_container_data "$1" "$2"
            ;;
        *)
            show_help
            ;;
    esac
}

# Run main function
main "$@"
