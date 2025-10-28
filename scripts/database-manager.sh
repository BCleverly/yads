#!/bin/bash

# YADS Database Manager
# Handles database creation, management, and operations

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

# Get database credentials from .env
get_mysql_credentials() {
    local mysql_root_password
    mysql_root_password=$(grep "^MYSQL_ROOT_PASSWORD=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "yads123")
    echo "$mysql_root_password"
}

get_postgres_credentials() {
    local postgres_password
    postgres_password=$(grep "^POSTGRES_PASSWORD=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "yads123")
    echo "$postgres_password"
}

# MySQL Database Operations

# Create MySQL database
create_mysql_database() {
    local db_name="$1"
    local mysql_root_password
    mysql_root_password=$(get_mysql_credentials)
    
    info "🗄️  Creating MySQL database: $db_name"
    
    # Create database
    docker exec yads-mysql mysql -u root -p"$mysql_root_password" -e "CREATE DATABASE IF NOT EXISTS $db_name;"
    
    # Create user for the database
    local db_user="${db_name}_user"
    local db_password="${db_name}_pass"
    
    docker exec yads-mysql mysql -u root -p"$mysql_root_password" -e "CREATE USER IF NOT EXISTS '$db_user'@'%' IDENTIFIED BY '$db_password';"
    docker exec yads-mysql mysql -u root -p"$mysql_root_password" -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'%';"
    docker exec yads-mysql mysql -u root -p"$mysql_root_password" -e "FLUSH PRIVILEGES;"
    
    success "MySQL database '$db_name' created"
    info "Database: $db_name"
    info "User: $db_user"
    info "Password: $db_password"
    info "Host: mysql"
    info "Port: 3306"
}

# Drop MySQL database
drop_mysql_database() {
    local db_name="$1"
    local mysql_root_password
    mysql_root_password=$(get_mysql_credentials)
    
    warning "This will permanently delete the MySQL database: $db_name"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "🗑️  Dropping MySQL database: $db_name"
        
        # Drop database
        docker exec yads-mysql mysql -u root -p"$mysql_root_password" -e "DROP DATABASE IF EXISTS $db_name;"
        
        # Drop user
        local db_user="${db_name}_user"
        docker exec yads-mysql mysql -u root -p"$mysql_root_password" -e "DROP USER IF EXISTS '$db_user'@'%';"
        
        success "MySQL database '$db_name' dropped"
    else
        info "Operation cancelled"
    fi
}

# List MySQL databases
list_mysql_databases() {
    local mysql_root_password
    mysql_root_password=$(get_mysql_credentials)
    
    info "🗄️  MySQL databases:"
    
    docker exec yads-mysql mysql -u root -p"$mysql_root_password" -e "SHOW DATABASES;" 2>/dev/null | grep -v "Database\|information_schema\|performance_schema\|mysql\|sys" | while read -r db; do
        if [[ -n "$db" ]]; then
            info "  - $db"
        fi
    done
}

# MySQL database info
mysql_database_info() {
    local db_name="$1"
    local mysql_root_password
    mysql_root_password=$(get_mysql_credentials)
    
    info "📊 MySQL database info: $db_name"
    
    # Show database size
    local size
    size=$(docker exec yads-mysql mysql -u root -p"$mysql_root_password" -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'DB Size in MB' FROM information_schema.tables WHERE table_schema='$db_name';" 2>/dev/null | tail -1)
    info "Size: ${size}MB"
    
    # Show tables
    info "Tables:"
    docker exec yads-mysql mysql -u root -p"$mysql_root_password" -e "USE $db_name; SHOW TABLES;" 2>/dev/null | grep -v "Tables_in" | while read -r table; do
        if [[ -n "$table" ]]; then
            info "  - $table"
        fi
    done
}

# PostgreSQL Database Operations

# Create PostgreSQL database
create_postgres_database() {
    local db_name="$1"
    local postgres_password
    postgres_password=$(get_postgres_credentials)
    
    info "🗄️  Creating PostgreSQL database: $db_name"
    
    # Create database
    docker exec yads-postgres psql -U yads -d postgres -c "CREATE DATABASE $db_name;"
    
    # Create user for the database
    local db_user="${db_name}_user"
    local db_password="${db_name}_pass"
    
    docker exec yads-postgres psql -U yads -d postgres -c "CREATE USER $db_user WITH PASSWORD '$db_password';"
    docker exec yads-postgres psql -U yads -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE $db_name TO $db_user;"
    
    success "PostgreSQL database '$db_name' created"
    info "Database: $db_name"
    info "User: $db_user"
    info "Password: $db_password"
    info "Host: postgres"
    info "Port: 5432"
}

# Drop PostgreSQL database
drop_postgres_database() {
    local db_name="$1"
    local postgres_password
    postgres_password=$(get_postgres_credentials)
    
    warning "This will permanently delete the PostgreSQL database: $db_name"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "🗑️  Dropping PostgreSQL database: $db_name"
        
        # Drop database
        docker exec yads-postgres psql -U yads -d postgres -c "DROP DATABASE IF EXISTS $db_name;"
        
        # Drop user
        local db_user="${db_name}_user"
        docker exec yads-postgres psql -U yads -d postgres -c "DROP USER IF EXISTS $db_user;"
        
        success "PostgreSQL database '$db_name' dropped"
    else
        info "Operation cancelled"
    fi
}

# List PostgreSQL databases
list_postgres_databases() {
    local postgres_password
    postgres_password=$(get_postgres_credentials)
    
    info "🗄️  PostgreSQL databases:"
    
    docker exec yads-postgres psql -U yads -d postgres -c "\l" 2>/dev/null | grep -v "template\|postgres" | while read -r line; do
        if [[ -n "$line" ]] && [[ ! "$line" =~ "List of databases" ]] && [[ ! "$line" =~ "Name" ]] && [[ ! "$line" =~ "Owner" ]]; then
            local db_name
            db_name=$(echo "$line" | awk '{print $1}')
            if [[ -n "$db_name" ]] && [[ "$db_name" != "yads" ]]; then
                info "  - $db_name"
            fi
        fi
    done
}

# PostgreSQL database info
postgres_database_info() {
    local db_name="$1"
    local postgres_password
    postgres_password=$(get_postgres_credentials)
    
    info "📊 PostgreSQL database info: $db_name"
    
    # Show database size
    local size
    size=$(docker exec yads-postgres psql -U yads -d "$db_name" -c "SELECT pg_size_pretty(pg_database_size('$db_name'));" 2>/dev/null | tail -1)
    info "Size: $size"
    
    # Show tables
    info "Tables:"
    docker exec yads-postgres psql -U yads -d "$db_name" -c "\dt" 2>/dev/null | grep -v "List of relations" | grep -v "Schema" | grep -v "Name" | while read -r line; do
        if [[ -n "$line" ]] && [[ ! "$line" =~ "Type" ]]; then
            local table
            table=$(echo "$line" | awk '{print $1}')
            if [[ -n "$table" ]]; then
                info "  - $table"
            fi
        fi
    done
}

# Database Backup Operations

# Backup MySQL database
backup_mysql_database() {
    local db_name="$1"
    local backup_file="$2"
    local mysql_root_password
    mysql_root_password=$(get_mysql_credentials)
    
    info "💾 Backing up MySQL database: $db_name"
    
    # Create backup directory
    mkdir -p "$(dirname "$backup_file")"
    
    # Create backup
    docker exec yads-mysql mysqldump -u root -p"$mysql_root_password" "$db_name" > "$backup_file"
    
    success "MySQL database '$db_name' backed up to: $backup_file"
}

# Backup PostgreSQL database
backup_postgres_database() {
    local db_name="$1"
    local backup_file="$2"
    local postgres_password
    postgres_password=$(get_postgres_credentials)
    
    info "💾 Backing up PostgreSQL database: $db_name"
    
    # Create backup directory
    mkdir -p "$(dirname "$backup_file")"
    
    # Create backup
    docker exec yads-postgres pg_dump -U yads "$db_name" > "$backup_file"
    
    success "PostgreSQL database '$db_name' backed up to: $backup_file"
}

# Restore MySQL database
restore_mysql_database() {
    local db_name="$1"
    local backup_file="$2"
    local mysql_root_password
    mysql_root_password=$(get_mysql_credentials)
    
    if [[ ! -f "$backup_file" ]]; then
        error_exit "Backup file not found: $backup_file"
    fi
    
    info "🔄 Restoring MySQL database: $db_name"
    
    # Create database if it doesn't exist
    docker exec yads-mysql mysql -u root -p"$mysql_root_password" -e "CREATE DATABASE IF NOT EXISTS $db_name;"
    
    # Restore from backup
    docker exec -i yads-mysql mysql -u root -p"$mysql_root_password" "$db_name" < "$backup_file"
    
    success "MySQL database '$db_name' restored from: $backup_file"
}

# Restore PostgreSQL database
restore_postgres_database() {
    local db_name="$1"
    local backup_file="$2"
    local postgres_password
    postgres_password=$(get_postgres_credentials)
    
    if [[ ! -f "$backup_file" ]]; then
        error_exit "Backup file not found: $backup_file"
    fi
    
    info "🔄 Restoring PostgreSQL database: $db_name"
    
    # Create database if it doesn't exist
    docker exec yads-postgres psql -U yads -d postgres -c "CREATE DATABASE $db_name;"
    
    # Restore from backup
    docker exec -i yads-postgres psql -U yads "$db_name" < "$backup_file"
    
    success "PostgreSQL database '$db_name' restored from: $backup_file"
}

# Show help
show_help() {
    echo -e "${CYAN}YADS Database Manager${NC}"
    echo -e "${BLUE}Handles database creation, management, and operations${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "${WHITE}  database-manager.sh <command> [options]${NC}"
    echo
    echo -e "${YELLOW}Commands:${NC}"
    echo -e "${WHITE}  create <name> [type]    Create database (mysql, postgres)${NC}"
    echo -e "${WHITE}  drop <name> [type]      Drop database${NC}"
    echo -e "${WHITE}  list [type]             List databases${NC}"
    echo -e "${WHITE}  info <name> [type]      Show database info${NC}"
    echo -e "${WHITE}  backup <name> <file> [type]  Backup database${NC}"
    echo -e "${WHITE}  restore <name> <file> [type]  Restore database${NC}"
    echo
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "${GRAY}  database-manager.sh create myapp mysql     # Create MySQL database${NC}"
    echo -e "${GRAY}  database-manager.sh list mysql            # List MySQL databases${NC}"
    echo -e "${GRAY}  database-manager.sh backup myapp backup.sql mysql  # Backup MySQL database${NC}"
    echo -e "${GRAY}  database-manager.sh info myapp mysql      # Show database info${NC}"
}

# Main function
main() {
    setup_colors
    
    local command="${1:-}"
    shift 2>/dev/null || true
    
    case "$command" in
        create)
            if [[ -z "${1:-}" ]]; then
                error_exit "Database name required. Use: $0 create <name> [type]"
            fi
            case "${2:-mysql}" in
                mysql)
                    create_mysql_database "$1"
                    ;;
                postgres)
                    create_postgres_database "$1"
                    ;;
                *)
                    error_exit "Unknown database type: $2"
                    ;;
            esac
            ;;
        drop)
            if [[ -z "${1:-}" ]]; then
                error_exit "Database name required. Use: $0 drop <name> [type]"
            fi
            case "${2:-mysql}" in
                mysql)
                    drop_mysql_database "$1"
                    ;;
                postgres)
                    drop_postgres_database "$1"
                    ;;
                *)
                    error_exit "Unknown database type: $2"
                    ;;
            esac
            ;;
        list)
            case "${1:-all}" in
                mysql)
                    list_mysql_databases
                    ;;
                postgres)
                    list_postgres_databases
                    ;;
                all)
                    list_mysql_databases
                    echo
                    list_postgres_databases
                    ;;
                *)
                    error_exit "Unknown database type: $1"
                    ;;
            esac
            ;;
        info)
            if [[ -z "${1:-}" ]]; then
                error_exit "Database name required. Use: $0 info <name> [type]"
            fi
            case "${2:-mysql}" in
                mysql)
                    mysql_database_info "$1"
                    ;;
                postgres)
                    postgres_database_info "$1"
                    ;;
                *)
                    error_exit "Unknown database type: $2"
                    ;;
            esac
            ;;
        backup)
            if [[ -z "${1:-}" ]] || [[ -z "${2:-}" ]]; then
                error_exit "Database name and backup file required. Use: $0 backup <name> <file> [type]"
            fi
            case "${3:-mysql}" in
                mysql)
                    backup_mysql_database "$1" "$2"
                    ;;
                postgres)
                    backup_postgres_database "$1" "$2"
                    ;;
                *)
                    error_exit "Unknown database type: $3"
                    ;;
            esac
            ;;
        restore)
            if [[ -z "${1:-}" ]] || [[ -z "${2:-}" ]]; then
                error_exit "Database name and backup file required. Use: $0 restore <name> <file> [type]"
            fi
            case "${3:-mysql}" in
                mysql)
                    restore_mysql_database "$1" "$2"
                    ;;
                postgres)
                    restore_postgres_database "$1" "$2"
                    ;;
                *)
                    error_exit "Unknown database type: $3"
                    ;;
            esac
            ;;
        *)
            show_help
            ;;
    esac
}

# Run main function
main "$@"
