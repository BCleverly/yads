#!/bin/bash

# YADS Setup Script
# Makes all scripts executable and prepares for installation

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

# Main setup function
main() {
    setup_colors
    
    log "${CYAN}🔧 YADS Setup - Making scripts executable${NC}"
    log "${BLUE}========================================${NC}"
    
    # Make all scripts executable
    info "Setting executable permissions..."
    chmod +x yads install.sh manual-uninstall.sh
    chmod +x modules/*.sh
    chmod +x tests/unit/*.bats 2>/dev/null || true
    
    success "All scripts are now executable!"
    
    log "${YELLOW}Next steps:${NC}"
    log "1. Make yads available locally: ./local-setup.sh"
    log "2. Run full installation: sudo ./install.sh"
    log "3. Configure: yads tunnel setup"
    log "4. Create project: yads project myapp"
}

# Run main function
main "$@"
