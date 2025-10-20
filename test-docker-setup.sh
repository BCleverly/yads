#!/bin/bash

# Test script to verify Docker setup without actually running Docker
# This script validates the Docker configuration files

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

info "🧪 YADS Docker Setup Validation"
echo "==============================="
echo

# Test counter
tests_passed=0
tests_total=0

# Test function
test_file() {
    local file="$1"
    local description="$2"
    
    ((tests_total++))
    info "Testing: $description"
    
    if [[ -f "$file" ]]; then
        success "$description - PASS"
        ((tests_passed++))
        return 0
    else
        error "$description - FAIL (file not found)"
        return 1
    fi
}

# Test Docker files
info "📋 1. Docker Configuration Files"
echo "================================"

test_file "Dockerfile" "Dockerfile exists"
test_file "docker-compose.yml" "docker-compose.yml exists"
test_file "DOCKER.md" "DOCKER.md documentation exists"

echo

# Test Dockerfile content
info "📋 2. Dockerfile Content Validation"
echo "=================================="

if [[ -f "Dockerfile" ]]; then
    # Check for key components
    if grep -q "FROM ubuntu:24.04" Dockerfile; then
        success "Base image: Ubuntu 24.04"
        ((tests_passed++))
    else
        error "Base image: Not Ubuntu 24.04"
    fi
    ((tests_total++))
    
    if grep -q "groupadd webdev" Dockerfile; then
        success "Webdev group creation"
        ((tests_passed++))
    else
        error "Webdev group creation: Missing"
    fi
    ((tests_total++))
    
    if grep -q "test-yads-comprehensive.sh" Dockerfile; then
        success "Comprehensive test script"
        ((tests_passed++))
    else
        error "Comprehensive test script: Missing"
    fi
    ((tests_total++))
    
    if grep -q "fix-permissions-docker.sh" Dockerfile; then
        success "Permission fix script"
        ((tests_passed++))
    else
        error "Permission fix script: Missing"
    fi
    ((tests_total++))
    
    if grep -q "EXPOSE 80 443 8080" Dockerfile; then
        success "Port exposure"
        ((tests_passed++))
    else
        error "Port exposure: Missing"
    fi
    ((tests_total++))
fi

echo

# Test docker-compose.yml content
info "📋 3. Docker Compose Configuration"
echo "================================="

if [[ -f "docker-compose.yml" ]]; then
    if grep -q "privileged: true" docker-compose.yml; then
        success "Privileged mode enabled"
        ((tests_passed++))
    else
        error "Privileged mode: Not enabled"
    fi
    ((tests_total++))
    
    if grep -q "yads-projects" docker-compose.yml; then
        success "Named volume for projects"
        ((tests_passed++))
    else
        error "Named volume: Missing"
    fi
    ((tests_total++))
    
    if grep -q "YADS_TEST_MODE=true" docker-compose.yml; then
        success "Test mode environment variable"
        ((tests_passed++))
    else
        error "Test mode environment variable: Missing"
    fi
    ((tests_total++))
fi

echo

# Test install.sh improvements
info "📋 4. Install.sh Permission Improvements"
echo "======================================"

if [[ -f "install.sh" ]]; then
    if grep -q "comprehensive permissions" install.sh; then
        success "Comprehensive permission setup"
        ((tests_passed++))
    else
        error "Comprehensive permission setup: Missing"
    fi
    ((tests_total++))
    
    if grep -q "webdev group" install.sh; then
        success "Webdev group setup"
        ((tests_passed++))
    else
        error "Webdev group setup: Missing"
    fi
    ((tests_total++))
    
    if grep -q "VS Code Server permissions" install.sh; then
        success "VS Code Server permission setup"
        ((tests_passed++))
    else
        error "VS Code Server permission setup: Missing"
    fi
    ((tests_total++))
    
    if grep -q "test project to verify permissions" install.sh; then
        success "Permission verification test"
        ((tests_passed++))
    else
        error "Permission verification test: Missing"
    fi
    ((tests_total++))
fi

echo

# Test YADS modules for permission handling
info "📋 5. YADS Modules Permission Handling"
echo "====================================="

local modules=("vscode.sh" "webserver.sh" "project.sh")
for module in "${modules[@]}"; do
    if [[ -f "modules/$module" ]]; then
        if grep -q "webdev" "modules/$module"; then
            success "Module $module: Uses webdev group"
            ((tests_passed++))
        else
            warning "Module $module: May not use webdev group"
        fi
        ((tests_total++))
    fi
done

echo

# Show test summary
info "📊 Test Summary"
echo "==============="
echo
info "Tests passed: $tests_passed/$tests_total"

if [[ $tests_passed -eq $tests_total ]]; then
    success "🎉 All Docker setup tests passed! YADS is ready for comprehensive testing."
else
    warning "⚠️  Some tests failed. Check the output above for details."
fi

echo
info "Docker Testing Commands:"
info "  docker build -t yads-test ."
info "  docker-compose up --build"
info "  docker exec -it yads-test-container ./test-yads-comprehensive.sh"
echo
info "Permission Fix Commands:"
info "  sudo ./install.sh  # Now includes comprehensive permission setup"
info "  yads project myapp # Should work without permission issues"
info "  yads vscode setup  # Should work without permission issues"
echo