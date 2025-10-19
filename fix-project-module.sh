#!/bin/bash

# Fix project module directly on the server
# This script updates the project module to fix permission issues

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

info "🔧 Fixing project module permission issues..."

# Check if we're in the yads directory
if [[ ! -f "modules/project.sh" ]]; then
    error "This script must be run from the yads directory"
    exit 1
fi

# Backup the original project module
info "💾 Creating backup of project module..."
cp modules/project.sh modules/project.sh.backup
success "Backup created: modules/project.sh.backup"

# Fix the permission issue in the project module
info "🔧 Applying permission fix to project module..."

# Find the problematic chown line and replace it
sed -i 's/^    # Set proper permissions$/    # Set proper permissions (keep webdev group ownership)/' modules/project.sh

# Replace the chown commands with sudo-aware versions
sed -i '/^    chown -R www-data:www-data/d' modules/project.sh
sed -i '/^    chmod -R 755/d' modules/project.sh

# Add the new permission handling
cat >> modules/project.sh << 'EOF'
    # Set proper permissions (keep webdev group ownership)
    if [[ $EUID -eq 0 ]]; then
        # Running as root
        chown -R "$SUDO_USER:webdev" "$project_dir"
        chmod -R 775 "$project_dir"
    else
        # Running as regular user, use sudo
        sudo chown -R "$USER:webdev" "$project_dir"
        sudo chmod -R 775 "$project_dir"
    fi
EOF

success "✅ Project module fixed!"

# Test the fix
info "🧪 Testing the fix..."
if grep -q "sudo chown -R" modules/project.sh; then
    success "✅ Sudo-aware chown commands added"
else
    error "❌ Fix not applied correctly"
    exit 1
fi

success "🎉 Project module permission fix applied!"
info "📋 What was fixed:"
info "  • Added sudo support for chown commands"
info "  • Keep webdev group ownership instead of www-data"
info "  • Set permissions to 775 for group access"
info "  • Works for both root and regular users"

info "🚀 You can now run:"
info "  yads project myapp"
info "  yads project testapp"
