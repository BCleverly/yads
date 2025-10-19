#!/bin/bash

# Fix Line Endings Script
# Converts Windows line endings (CRLF) to Unix line endings (LF)

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

info() {
    log "${BLUE}ℹ️  $1${NC}"
}

success() {
    log "${GREEN}✅ $1${NC}"
}

warning() {
    log "${YELLOW}⚠️  Warning: $1${NC}"
}

# Main function
main() {
    setup_colors
    
    log "${CYAN}🔧 Fixing Line Endings${NC}"
    log "${BLUE}====================${NC}"
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Fix line endings for all shell scripts
    info "Fixing line endings for shell scripts..."
    
    # List of files to fix
    local files=(
        "yads"
        "install.sh"
        "manual-uninstall.sh"
        "local-setup.sh"
        "setup.sh"
        "modules/install.sh"
        "modules/uninstall.sh"
        "modules/php.sh"
        "modules/webserver.sh"
        "modules/database.sh"
        "modules/tunnel.sh"
        "modules/vscode.sh"
        "modules/project.sh"
        "modules/services.sh"
    )
    
    for file in "${files[@]}"; do
        local full_path="$script_dir/$file"
        if [[ -f "$full_path" ]]; then
            info "Fixing: $file"
            
            # Use dos2unix if available, otherwise use sed
            if command -v dos2unix >/dev/null 2>&1; then
                dos2unix "$full_path"
            else
                sed -i 's/\r$//' "$full_path"
            fi
            
            # Make executable
            chmod +x "$full_path"
        else
            warning "File not found: $file"
        fi
    done
    
    success "Line endings fixed for all shell scripts!"
    
    log "${YELLOW}Next steps:${NC}"
    log "1. Run: ./local-setup.sh"
    log "2. Test: yads help"
}

# Run main function
main "$@"
