#!/bin/bash

# Comprehensive Line Ending Fix Script
# Fixes all line ending issues in YADS scripts

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

info() {
    log "${BLUE}ℹ️  $1${NC}"
}

success() {
    log "${GREEN}✅ $1${NC}"
}

warning() {
    log "${YELLOW}⚠️  $1${NC}"
}

error() {
    log "${RED}❌ $1${NC}"
}

# Fix line endings for a file
fix_file_line_endings() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        warning "File not found: $file"
        return 1
    fi
    
    info "Fixing line endings for: $file"
    
    # Check if file has CRLF line endings
    if file "$file" | grep -q "CRLF"; then
        info "  Detected CRLF line endings"
        
        # Use dos2unix if available
        if command -v dos2unix >/dev/null 2>&1; then
            dos2unix "$file" 2>/dev/null || true
            success "  Fixed with dos2unix"
        else
            # Fallback: use sed to convert CRLF to LF
            sed -i 's/\r$//' "$file" 2>/dev/null || true
            success "  Fixed with sed"
        fi
    else
        info "  Line endings already correct"
    fi
    
    # Ensure file is executable if it's a script
    if [[ "$file" == *.sh ]] || [[ "$file" == "yads" ]]; then
        chmod +x "$file"
        info "  Made executable"
    fi
}

# Fix all YADS scripts
fix_all_scripts() {
    info "🔧 Fixing all YADS scripts..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # List of all scripts to fix
    local scripts=(
        "yads"
        "install.sh"
        "post-install.sh"
        "diagnose-installation.sh"
        "complete-cleanup.sh"
        "update-yads.sh"
        "local-setup.sh"
        "fix-line-endings.sh"
        "manual-uninstall.sh"
        "setup.sh"
        "test-docker.sh"
    )
    
    # Fix main scripts
    for script in "${scripts[@]}"; do
        if [[ -f "$script_dir/$script" ]]; then
            fix_file_line_endings "$script_dir/$script"
        fi
    done
    
    # Fix modules
    if [[ -d "$script_dir/modules" ]]; then
        info "Fixing module scripts..."
        for module in "$script_dir/modules"/*.sh; do
            if [[ -f "$module" ]]; then
                fix_file_line_endings "$module"
            fi
        done
    fi
    
    # Fix test scripts
    if [[ -d "$script_dir/tests" ]]; then
        info "Fixing test scripts..."
        for test_script in "$script_dir/tests"/*.sh; do
            if [[ -f "$test_script" ]]; then
                fix_file_line_endings "$test_script"
            fi
        done
        for test_script in "$script_dir/tests"/*.bats; do
            if [[ -f "$test_script" ]]; then
                fix_file_line_endings "$test_script"
            fi
        done
    fi
    
    success "All scripts fixed!"
}

# Verify fixes
verify_fixes() {
    info "🔍 Verifying fixes..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Check main yads script
    if [[ -f "$script_dir/yads" ]]; then
        info "Checking yads script..."
        
        # Check if it's executable
        if [[ -x "$script_dir/yads" ]]; then
            success "yads is executable"
        else
            warning "yads is not executable"
            chmod +x "$script_dir/yads"
            success "Made yads executable"
        fi
        
        # Check shebang line
        local first_line=$(head -n1 "$script_dir/yads")
        if [[ "$first_line" == "#!/bin/bash" ]]; then
            success "yads shebang is correct"
        else
            warning "yads shebang issue: $first_line"
        fi
        
        # Test if script can be executed
        if bash -n "$script_dir/yads" 2>/dev/null; then
            success "yads script syntax is valid"
        else
            error "yads script has syntax errors"
        fi
    fi
    
    # Check install script
    if [[ -f "$script_dir/install.sh" ]]; then
        info "Checking install.sh script..."
        
        if [[ -x "$script_dir/install.sh" ]]; then
            success "install.sh is executable"
        else
            warning "install.sh is not executable"
            chmod +x "$script_dir/install.sh"
            success "Made install.sh executable"
        fi
    fi
}

# Main function
main() {
    setup_colors
    
    log "${CYAN}🔧 YADS Line Ending Fix Script${NC}"
    log "${BLUE}================================${NC}"
    echo
    
    # Check if we're in the right directory
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ ! -f "$script_dir/yads" ]] || [[ ! -d "$script_dir/modules" ]]; then
        error "Please run this script from the YADS repository directory"
        exit 1
    fi
    
    # Fix all scripts
    fix_all_scripts
    echo
    
    # Verify fixes
    verify_fixes
    echo
    
    success "🎉 Line ending fixes completed!"
    
    log "${YELLOW}Next steps:${NC}"
    log "1. Test the yads command: yads --version"
    log "2. If still having issues, run: ./diagnose-installation.sh"
    log "3. For fresh installation: sudo ./install.sh"
    echo
}

# Run main function
main "$@"
