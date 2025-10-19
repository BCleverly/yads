#!/bin/bash

# Fix project creation permission issues
# This script resolves all permission problems for project creation

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

info "🔧 Fixing project creation permission issues..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
    exit 1
fi

# Get the development user
dev_user=""
if [[ -n "${SUDO_USER:-}" ]]; then
    dev_user="$SUDO_USER"
else
    dev_user="$(whoami)"
fi

info "👤 Fixing permissions for user: $dev_user"

# Ensure webdev group exists
info "👥 Ensuring webdev group exists..."
if ! getent group webdev >/dev/null 2>&1; then
    groupadd webdev
    success "Created webdev group"
else
    info "webdev group already exists"
fi

# Add development user to webdev group
info "🔗 Adding $dev_user to webdev group..."
usermod -a -G webdev "$dev_user"
success "Added $dev_user to webdev group"

# Fix existing projects directory permissions
info "📁 Fixing /var/www/projects permissions..."
chown -R "$dev_user:webdev" "/var/www/projects"
chmod -R 775 "/var/www/projects"

# Fix any existing myapp project
if [[ -d "/var/www/projects/myapp" ]]; then
    info "🔧 Fixing existing myapp project permissions..."
    chown -R "$dev_user:webdev" "/var/www/projects/myapp"
    chmod -R 775 "/var/www/projects/myapp"
    success "Fixed myapp project permissions"
fi

# Add web server users to webdev group
info "🌐 Adding web server users to webdev group..."
for user in www-data nginx apache; do
    if id "$user" >/dev/null 2>&1; then
        usermod -a -G webdev "$user"
        success "Added $user to webdev group"
    fi
done

# Add vscode user to webdev group if it exists
if id "vscode" >/dev/null 2>&1; then
    info "🔗 Adding vscode user to webdev group..."
    usermod -a -G webdev "vscode"
    success "Added vscode user to webdev group"
fi

# Test project creation
info "🧪 Testing project creation..."
test_project="/var/www/projects/test-project"
rm -rf "$test_project" 2>/dev/null || true

# Create test project
mkdir -p "$test_project"
chown "$dev_user:webdev" "$test_project"
chmod 775 "$test_project"

# Test write access
if sudo -u "$dev_user" touch "$test_project/test-write" 2>/dev/null; then
    success "Write permissions working for $dev_user"
    rm -f "$test_project/test-write"
else
    error "Write permissions not working for $dev_user"
    exit 1
fi

# Clean up test project
rm -rf "$test_project"

success "🎉 Project permission issues fixed!"
info "📋 Summary:"
info "  • User: $dev_user (member of webdev group)"
info "  • Projects directory: /var/www/projects (owned by $dev_user:webdev)"
info "  • Permissions: 775 (read/write/execute for owner and group)"
info "  • Web server users added to webdev group"

info "🚀 You can now run:"
info "  yads project myapp"
info "  yads project testapp"
