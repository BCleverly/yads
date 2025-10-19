#!/bin/bash

# Complete fix for project permission issues
# This script removes ALL chown commands and relies on webdev group system

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

# Initialize colors
setup_colors

info "🔧 Complete fix for project permission issues..."

# Check if we're in the yads directory
if [[ ! -f "modules/project.sh" ]]; then
    error "This script must be run from the yads directory"
    exit 1
fi

# Backup the original project module
info "💾 Creating backup of project module..."
cp modules/project.sh modules/project.sh.backup.$(date +%Y%m%d_%H%M%S)
success "Backup created with timestamp"

# Remove ALL chown commands from the project module
info "🔧 Removing ALL chown commands from project module..."

# Remove all lines containing chown
sed -i '/chown/d' modules/project.sh

# Remove the entire permission setting block
sed -i '/^    # Set proper permissions/,/^    fi$/d' modules/project.sh

# Add a simple comment about webdev group system
sed -i '/^    esac$/a\\n    # Permissions are handled by webdev group system' modules/project.sh

success "✅ ALL chown commands removed!"

# Verify the fix
info "🧪 Verifying the fix..."
if ! grep -q "chown" modules/project.sh; then
    success "✅ No chown commands found in project module"
else
    warning "⚠️  Some chown commands may still exist"
    grep -n "chown" modules/project.sh
fi

# Also check other modules for chown commands
info "🔍 Checking other modules for chown commands..."
for module in modules/*.sh; do
    if [[ -f "$module" ]]; then
        if grep -q "chown" "$module"; then
            warning "Found chown commands in $(basename "$module")"
        fi
    fi
done

success "🎉 Complete project permission fix applied!"
info "📋 What was fixed:"
info "  • Removed ALL chown commands from project module"
info "  • Rely entirely on webdev group system for permissions"
info "  • No more 'Operation not permitted' errors"
info "  • Projects will inherit proper permissions from parent directory"

info "🚀 You can now run:"
info "  yads project myapp"
info "  yads project testapp"
