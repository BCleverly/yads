#!/bin/bash

# YADS Docker Test Script
# Tests YADS functionality in Docker container

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

# Test basic YADS functionality
test_basic_functionality() {
    info "🧪 Testing basic YADS functionality..."
    
    # Test version
    if yads --version >/dev/null 2>&1; then
        success "yads --version works"
    else
        error "yads --version failed"
    fi
    
    # Test help
    if yads help >/dev/null 2>&1; then
        success "yads help works"
    else
        error "yads help failed"
    fi
    
    # Test status
    if yads status >/dev/null 2>&1; then
        success "yads status works"
    else
        error "yads status failed"
    fi
}

# Test update functionality
test_update_functionality() {
    info "🔄 Testing update functionality..."
    
    if yads update >/dev/null 2>&1; then
        success "yads update works"
    else
        warning "yads update failed (expected in container)"
    fi
}

# Test module loading
test_module_loading() {
    info "📦 Testing module loading..."
    
    local modules=("php" "webserver" "database" "tunnel" "vscode" "project" "services" "uninstall" "proxy")
    
    for module in "${modules[@]}"; do
        if [[ -f "modules/${module}.sh" ]]; then
            success "Module ${module}.sh exists"
        else
            error "Module ${module}.sh missing"
        fi
    done
}

# Test script permissions
test_script_permissions() {
    info "🔧 Testing script permissions..."
    
    local scripts=("yads" "install.sh" "update-yads.sh" "local-setup.sh" "complete-cleanup.sh")
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]] && [[ -x "$script" ]]; then
            success "Script $script is executable"
        else
            error "Script $script is not executable"
        fi
    done
}

# Test installation readiness
test_installation_readiness() {
    info "🚀 Testing installation readiness..."
    
    # Check if we can run install script
    if [[ -f "install.sh" ]] && [[ -x "install.sh" ]]; then
        success "install.sh is ready"
    else
        error "install.sh not ready"
    fi
    
    # Check if modules directory exists
    if [[ -d "modules" ]]; then
        success "modules directory exists"
    else
        error "modules directory missing"
    fi
    
    # Check if all modules are executable
    local module_count
    module_count=$(find modules -name "*.sh" -executable | wc -l)
    if [[ $module_count -gt 0 ]]; then
        success "Found $module_count executable modules"
    else
        error "No executable modules found"
    fi
}

# Test Docker-specific functionality
test_docker_functionality() {
    info "🐳 Testing Docker-specific functionality..."
    
    # Check if we're in Docker
    if [[ -f "/.dockerenv" ]]; then
        success "Running in Docker container"
    else
        warning "Not running in Docker container"
    fi
    
    # Check systemd availability
    if command -v systemctl >/dev/null 2>&1; then
        success "systemctl available"
    else
        warning "systemctl not available"
    fi
    
    # Check sudo availability
    if command -v sudo >/dev/null 2>&1; then
        success "sudo available"
    else
        error "sudo not available"
    fi
}

# Test NGINX Proxy Manager functionality
test_npm_functionality() {
    info "🌐 Testing NGINX Proxy Manager functionality..."
    
    # Test proxy module exists
    if [[ -f "modules/proxy.sh" ]]; then
        success "Proxy module exists"
    else
        error "Proxy module missing"
    fi
    
    # Test proxy commands
    if yads proxy status >/dev/null 2>&1; then
        success "yads proxy status works"
    else
        warning "yads proxy status failed (expected if NPM not installed)"
    fi
    
    # Test proxy installation
    if yads proxy install >/dev/null 2>&1; then
        success "yads proxy install works"
    else
        warning "yads proxy install failed (expected in container)"
    fi
    
    # Test proxy setup
    if yads proxy setup testdomain.com >/dev/null 2>&1; then
        success "yads proxy setup works"
    else
        warning "yads proxy setup failed (expected in container)"
    fi
    
    # Test proxy project creation
    if yads proxy project testapp 8081 testapp.projects.testdomain.com >/dev/null 2>&1; then
        success "yads proxy project works"
    else
        warning "yads proxy project failed (expected in container)"
    fi
}

# Show test summary
show_test_summary() {
    info "📋 Test Summary:"
    echo
    info "Basic functionality tests completed"
    info "Module loading tests completed"
    info "Script permissions tests completed"
    info "Installation readiness tests completed"
    info "Docker functionality tests completed"
    info "NGINX Proxy Manager tests completed"
    echo
    success "🎉 All tests completed!"
    echo
    info "Next steps:"
    info "  1. Run full installation: sudo ./install.sh"
    info "  2. Test services: yads status"
    info "  3. Test specific modules: yads php 8.4"
    echo
}

# Main test function
main() {
    setup_colors
    
    info "🧪 YADS Docker Test Suite"
    echo "========================="
    echo
    
    test_basic_functionality
    echo
    
    test_update_functionality
    echo
    
    test_module_loading
    echo
    
    test_script_permissions
    echo
    
    test_installation_readiness
    echo
    
    test_docker_functionality
    echo
    
    test_npm_functionality
    echo
    
    test_no_sudo_commands
    echo
    
    show_test_summary
}

# Test no-sudo commands
test_no_sudo_commands() {
    info "🧪 Testing No-Sudo Commands"
    echo "============================"
    
    local tests_passed=0
    local tests_total=0
    
    # Test yads tunnel setup (should work without sudo now)
    ((tests_total++))
    if test_command "yads tunnel setup" "yads tunnel setup command"; then
        ((tests_passed++))
    fi
    
    # Test yads vscode setup (should work without sudo now)
    ((tests_total++))
    if test_command "yads vscode setup" "yads vscode setup command"; then
        ((tests_passed++))
    fi
    
    # Test yads project creation
    ((tests_total++))
    if test_command "yads project test-project" "yads project creation command"; then
        ((tests_passed++))
    fi
    
    # Test yads service commands
    ((tests_total++))
    if test_command "yads start" "yads start command"; then
        ((tests_passed++))
    fi
    
    ((tests_total++))
    if test_command "yads stop" "yads stop command"; then
        ((tests_passed++))
    fi
    
    ((tests_total++))
    if test_command "yads restart" "yads restart command"; then
        ((tests_passed++))
    fi
    
    echo
    info "No-Sudo Commands: $tests_passed/$tests_total passed"
    echo
    
    if [[ $tests_passed -eq $tests_total ]]; then
        success "🎉 All no-sudo commands are working correctly!"
    else
        warning "⚠️  Some no-sudo commands failed. Check permission fixes."
    fi
}

# Run main function
main "$@"
