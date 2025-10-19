#!/bin/bash

# YADS Update Script
# Updates YADS from GitHub and reinstalls to CLI path

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

error_exit() {
    log "${RED}❌ Error: $1${NC}"
    exit 1
}

# Check if we're in a git repository
check_git_repo() {
    if [[ ! -d ".git" ]]; then
        error_exit "Not in a git repository. Please run from the YADS directory."
    fi
}

# Update from GitHub
update_from_github() {
    info "🔄 Updating YADS from GitHub..."
    
    # Check if we have a remote origin
    if ! git remote get-url origin >/dev/null 2>&1; then
        error_exit "No remote origin found. Please add the YADS repository as origin."
    fi
    
    # Fetch latest changes
    git fetch origin
    
    # Check if there are updates
    local current_branch
    current_branch=$(git branch --show-current)
    local behind_count
    behind_count=$(git rev-list --count HEAD..origin/$current_branch 2>/dev/null || echo "0")
    
    if [[ "$behind_count" -eq 0 ]]; then
        info "YADS is already up to date"
        return 0
    fi
    
    info "Found $behind_count new commits. Updating..."
    
    # Stash any local changes
    if ! git diff --quiet; then
        warning "You have uncommitted changes. Stashing them..."
        git stash push -m "Auto-stash before YADS update $(date)"
    fi
    
    # Pull latest changes
    git pull origin "$current_branch"
    
    success "YADS updated successfully"
    return 1
}

# Fix line endings
fix_line_endings() {
    info "🔧 Fixing line endings..."
    
    if command -v dos2unix >/dev/null 2>&1; then
        find . -name "*.sh" -o -name "yads" | xargs dos2unix
    else
        # Fallback to sed
        find . -name "*.sh" -o -name "yads" | while read -r file; do
            sed -i 's/\r$//' "$file"
        done
    fi
    
    success "Line endings fixed"
}

# Make scripts executable
make_executable() {
    info "🔧 Making scripts executable..."
    
    chmod +x yads
    chmod +x install.sh
    chmod +x manual-uninstall.sh
    chmod +x local-setup.sh
    chmod +x update-yads.sh
    chmod +x fix-line-endings.sh
    chmod +x modules/*.sh 2>/dev/null || true
    chmod +x tests/unit/*.bats 2>/dev/null || true
    
    success "Scripts made executable"
}

# Reinstall to CLI path
reinstall_cli() {
    info "🔗 Reinstalling YADS to CLI path..."
    
    # Remove old symlink if it exists
    if [[ -L ~/.local/bin/yads ]]; then
        rm ~/.local/bin/yads
    fi
    
    # Create new symlink
    local script_dir
    script_dir="$(pwd)"
    
    # Ensure ~/.local/bin exists
    mkdir -p ~/.local/bin
    
    # Create symlink
    ln -sf "$script_dir/yads" ~/.local/bin/yads
    
    # Verify symlink
    if [[ -L ~/.local/bin/yads ]] && [[ -x ~/.local/bin/yads ]]; then
        success "YADS symlink created successfully"
    else
        error_exit "Failed to create YADS symlink"
    fi
}

# Update PATH in shell config
update_shell_config() {
    info "🔧 Updating shell configuration..."
    
    local shell_config=""
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        shell_config="$HOME/.zshrc"
    else
        shell_config="$HOME/.bashrc"
    fi
    
    # Check if PATH is already configured
    if grep -q "~/.local/bin" "$shell_config" 2>/dev/null; then
        info "PATH already configured in $shell_config"
        return
    fi
    
    # Add to PATH
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_config"
    success "Added ~/.local/bin to PATH in $shell_config"
    
    # Source the config for current session
    export PATH="$HOME/.local/bin:$PATH"
    info "PATH updated for current session"
}

# Show update summary
show_summary() {
    info "📋 Update Summary:"
    echo
    info "✅ YADS updated from GitHub"
    info "✅ Line endings fixed"
    info "✅ Scripts made executable"
    info "✅ CLI symlink updated"
    info "✅ Shell configuration updated"
    echo
    success "🎉 YADS update completed successfully!"
    echo
    info "Next steps:"
    info "  1. Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
    info "  2. Test the update: yads --version"
    info "  3. Check status: yads status"
}

# Main update function
main() {
    setup_colors
    
    info "🚀 YADS Update Script"
    echo
    
    # Check if we're in the right directory
    check_git_repo
    
    # Update from GitHub
    local has_updates
    if update_from_github; then
        info "No updates available"
        exit 0
    fi
    
    # Fix line endings
    fix_line_endings
    
    # Make scripts executable
    make_executable
    
    # Reinstall to CLI path
    reinstall_cli
    
    # Update shell configuration
    update_shell_config
    
    # Show summary
    show_summary
}

# Run main function
main "$@"
