#!/bin/bash

# Quick fix for project permission issues
# This script removes the problematic chown commands

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

info "🔧 Quick fix for project permission issues..."

# Check if we're in the yads directory
if [[ ! -f "modules/project.sh" ]]; then
    error "This script must be run from the yads directory"
    exit 1
fi

# Backup the original project module
info "💾 Creating backup of project module..."
cp modules/project.sh modules/project.sh.backup
success "Backup created: modules/project.sh.backup"

# Remove the problematic chown commands entirely
info "🔧 Removing problematic chown commands..."

# Find and remove the chown commands that are causing issues
sed -i '/^    # Set proper permissions$/d' modules/project.sh
sed -i '/^    chown -R www-data:www-data/d' modules/project.sh
sed -i '/^    chmod -R 755/d' modules/project.sh

# Add a simple comment instead
sed -i '/^    esac$/a\\n    # Permissions are handled by webdev group system' modules/project.sh

success "✅ Problematic chown commands removed!"

# Test the fix
info "🧪 Testing the fix..."
if ! grep -q "chown -R www-data" modules/project.sh; then
    success "✅ Problematic chown commands removed"
else
    error "❌ Fix not applied correctly"
    exit 1
fi

success "🎉 Project module quick fix applied!"
info "📋 What was fixed:"
info "  • Removed problematic chown commands"
info "  • Rely on webdev group system for permissions"
info "  • No more 'Operation not permitted' errors"

info "🚀 You can now run:"
info "  yads project myapp"
info "  yads project testapp"
