#!/bin/bash

# Test YADS Commands Without Sudo
# Comprehensive test to verify all commands work without elevated privileges

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

# Test function
test_command() {
    local cmd="$1"
    local description="$2"
    local expected_exit_code="${3:-0}"
    
    info "Testing: $description"
    info "Command: $cmd"
    
    if eval "$cmd" >/dev/null 2>&1; then
        local exit_code=$?
        if [[ $exit_code -eq $expected_exit_code ]]; then
            success "✅ $description - PASSED (exit code: $exit_code)"
            return 0
        else
            warning "⚠️  $description - UNEXPECTED EXIT CODE (got: $exit_code, expected: $expected_exit_code)"
            return 1
        fi
    else
        local exit_code=$?
        if [[ $exit_code -eq $expected_exit_code ]]; then
            success "✅ $description - PASSED (exit code: $exit_code)"
            return 0
        else
            error "❌ $description - FAILED (exit code: $exit_code)"
            return 1
        fi
    fi
}

# Test YADS basic commands
test_yads_basic() {
    info "🧪 Testing YADS Basic Commands"
    echo "================================="
    
    local tests_passed=0
    local tests_total=0
    
    # Test yads help
    ((tests_total++))
    if test_command "yads help" "yads help command"; then
        ((tests_passed++))
    fi
    
    # Test yads version
    ((tests_total++))
    if test_command "yads version" "yads version command"; then
        ((tests_passed++))
    fi
    
    # Test yads status
    ((tests_total++))
    if test_command "yads status" "yads status command"; then
        ((tests_passed++))
    fi
    
    echo
    info "Basic Commands: $tests_passed/$tests_total passed"
    echo
}

# Test YADS service commands
test_yads_services() {
    info "🧪 Testing YADS Service Commands"
    echo "=================================="
    
    local tests_passed=0
    local tests_total=0
    
    # Test yads start
    ((tests_total++))
    if test_command "yads start" "yads start command"; then
        ((tests_passed++))
    fi
    
    # Test yads stop
    ((tests_total++))
    if test_command "yads stop" "yads stop command"; then
        ((tests_passed++))
    fi
    
    # Test yads restart
    ((tests_total++))
    if test_command "yads restart" "yads restart command"; then
        ((tests_passed++))
    fi
    
    echo
    info "Service Commands: $tests_passed/$tests_total passed"
    echo
}

# Test YADS configuration commands
test_yads_configuration() {
    info "🧪 Testing YADS Configuration Commands"
    echo "======================================="
    
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
    
    echo
    info "Configuration Commands: $tests_passed/$tests_total passed"
    echo
}

# Test YADS module commands
test_yads_modules() {
    info "🧪 Testing YADS Module Commands"
    echo "================================="
    
    local tests_passed=0
    local tests_total=0
    
    # Test yads php
    ((tests_total++))
    if test_command "yads php 8.4" "yads php command"; then
        ((tests_passed++))
    fi
    
    # Test yads server
    ((tests_total++))
    if test_command "yads server apache" "yads server command"; then
        ((tests_passed++))
    fi
    
    # Test yads database
    ((tests_total++))
    if test_command "yads database mysql" "yads database command"; then
        ((tests_passed++))
    fi
    
    echo
    info "Module Commands: $tests_passed/$tests_total passed"
    echo
}

# Test command availability
test_command_availability() {
    info "🧪 Testing Command Availability"
    echo "================================="
    
    local tests_passed=0
    local tests_total=0
    
    # Test yads command
    ((tests_total++))
    if test_command "command -v yads" "yads command availability"; then
        ((tests_passed++))
    fi
    
    # Test cursor-agent command
    ((tests_total++))
    if test_command "command -v cursor-agent" "cursor-agent command availability"; then
        ((tests_passed++))
    fi
    
    # Test composer command
    ((tests_total++))
    if test_command "command -v composer" "composer command availability"; then
        ((tests_passed++))
    fi
    
    # Test php command
    ((tests_total++))
    if test_command "command -v php" "php command availability"; then
        ((tests_passed++))
    fi
    
    # Test git command
    ((tests_total++))
    if test_command "command -v git" "git command availability"; then
        ((tests_passed++))
    fi
    
    echo
    info "Command Availability: $tests_passed/$tests_total passed"
    echo
}

# Test permission-sensitive operations
test_permissions() {
    info "🧪 Testing Permission-Sensitive Operations"
    echo "==========================================="
    
    local tests_passed=0
    local tests_total=0
    
    # Test if we can create directories in /tmp (should work)
    ((tests_total++))
    if test_command "mkdir -p /tmp/yads-test && rmdir /tmp/yads-test" "Directory creation in /tmp"; then
        ((tests_passed++))
    fi
    
    # Test if we can write to /tmp (should work)
    ((tests_total++))
    if test_command "echo 'test' > /tmp/yads-test.txt && rm /tmp/yads-test.txt" "File creation in /tmp"; then
        ((tests_passed++))
    fi
    
    # Test if we can read from /etc (should work)
    ((tests_total++))
    if test_command "ls /etc > /dev/null" "Reading from /etc"; then
        ((tests_passed++))
    fi
    
    echo
    info "Permission Tests: $tests_passed/$tests_total passed"
    echo
}

# Test specific YADS functionality
test_yads_functionality() {
    info "🧪 Testing YADS Functionality"
    echo "==============================="
    
    local tests_passed=0
    local tests_total=0
    
    # Test yads help output
    ((tests_total++))
    if test_command "yads help | grep -q 'YADS - Yet Another Development Server'" "yads help output"; then
        ((tests_passed++))
    fi
    
    # Test yads version output
    ((tests_total++))
    if test_command "yads version | grep -q 'Version:'" "yads version output"; then
        ((tests_passed++))
    fi
    
    # Test yads status output
    ((tests_total++))
    if test_command "yads status | grep -q 'YADS Status'" "yads status output"; then
        ((tests_passed++))
    fi
    
    echo
    info "Functionality Tests: $tests_passed/$tests_total passed"
    echo
}

# Main test function
main() {
    setup_colors
    
    log "${CYAN}🧪 YADS No-Sudo Test Suite${NC}"
    log "${BLUE}============================${NC}"
    echo
    
    # Check if we're in the right directory
    if [[ ! -f "yads" ]] || [[ ! -d "modules" ]]; then
        error "Please run this script from the YADS repository directory"
        exit 1
    fi
    
    # Check if yads is available
    if ! command -v yads >/dev/null 2>&1; then
        error "yads command not found. Please run 'sudo ./install.sh' first"
        exit 1
    fi
    
    info "Starting comprehensive no-sudo tests..."
    echo
    
    # Run all tests
    test_command_availability
    test_permissions
    test_yads_basic
    test_yads_functionality
    test_yads_services
    test_yads_configuration
    test_yads_modules
    
    # Summary
    echo
    log "${CYAN}📊 Test Summary${NC}"
    log "${BLUE}===============${NC}"
    info "All tests completed!"
    info "Check the results above for any failures."
    echo
    info "💡 If any tests failed, it means the permission fixes need more work."
    info "💡 If all tests passed, YADS is working correctly without sudo!"
    echo
}

# Run main function
main "$@"
