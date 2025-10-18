#!/bin/bash

# YADS Setup Verification Script
# Verifies that all components are properly set up and working

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "$1"
}

# Check if file exists and is executable
check_file() {
    local file="$1"
    local description="$2"
    
    if [[ -f "$file" ]]; then
        if [[ -x "$file" ]]; then
            log "${GREEN}✓ $description exists and is executable${NC}"
            return 0
        else
            log "${YELLOW}⚠ $description exists but is not executable${NC}"
            chmod +x "$file"
            log "${GREEN}✓ Made $description executable${NC}"
            return 0
        fi
    else
        log "${RED}✗ $description not found${NC}"
        return 1
    fi
}

# Check if file has valid syntax
check_syntax() {
    local file="$1"
    local description="$2"
    
    if bash -n "$file" 2>/dev/null; then
        log "${GREEN}✓ $description syntax is valid${NC}"
        return 0
    else
        log "${RED}✗ $description has syntax errors${NC}"
        return 1
    fi
}

# Check if command exists
check_command() {
    local cmd="$1"
    local description="$2"
    
    if command -v "$cmd" &> /dev/null; then
        log "${GREEN}✓ $description is available${NC}"
        return 0
    else
        log "${YELLOW}⚠ $description not found${NC}"
        return 1
    fi
}

# Main verification function
main() {
    log "${CYAN}YADS Setup Verification${NC}"
    log "=========================="
    echo
    
    local errors=0
    local warnings=0
    
    # Check main script
    log "${BLUE}Checking main YADS script...${NC}"
    if ! check_file "yads" "Main YADS script"; then
        ((errors++))
    fi
    
    if ! check_syntax "yads" "Main YADS script"; then
        ((errors++))
    fi
    
    # Check modules
    log "${BLUE}Checking YADS modules...${NC}"
    for module in modules/install.sh modules/domains.sh modules/projects.sh; do
        if ! check_file "$module" "Module $(basename "$module")"; then
            ((errors++))
        fi
        
        if ! check_syntax "$module" "Module $(basename "$module")"; then
            ((errors++))
        fi
    done
    
    # Check installation script
    log "${BLUE}Checking installation script...${NC}"
    if ! check_file "install.sh" "Installation script"; then
        ((errors++))
    fi
    
    if ! check_syntax "install.sh" "Installation script"; then
        ((errors++))
    fi
    
    # Check test files
    log "${BLUE}Checking test files...${NC}"
    for test_file in tests/*.bats; do
        if [[ -f "$test_file" ]]; then
            if ! check_file "$test_file" "Test file $(basename "$test_file")"; then
                ((errors++))
            fi
        fi
    done
    
    # Check test runner
    if ! check_file "tests/run-tests.sh" "Test runner script"; then
        ((errors++))
    fi
    
    if ! check_syntax "tests/run-tests.sh" "Test runner script"; then
        ((errors++))
    fi
    
    # Check setup script
    if ! check_file "tests/setup.bash" "Test setup script"; then
        ((errors++))
    fi
    
    if ! check_syntax "tests/setup.bash" "Test setup script"; then
        ((errors++))
    fi
    
    # Check Makefile
    log "${BLUE}Checking Makefile...${NC}"
    if ! check_file "Makefile" "Makefile"; then
        ((errors++))
    fi
    
    # Check documentation
    log "${BLUE}Checking documentation...${NC}"
    if ! check_file "README.md" "README.md"; then
        ((errors++))
    fi
    
    # Check CI/CD files
    log "${BLUE}Checking CI/CD files...${NC}"
    if ! check_file ".github/workflows/test.yml" "GitHub Actions workflow"; then
        ((errors++))
    fi
    
    # Check for required commands
    log "${BLUE}Checking required commands...${NC}"
    if ! check_command "bash" "Bash shell"; then
        ((errors++))
    fi
    
    if ! check_command "curl" "Curl"; then
        ((warnings++))
    fi
    
    if ! check_command "wget" "Wget"; then
        ((warnings++))
    fi
    
    # Check for optional commands
    log "${BLUE}Checking optional commands...${NC}"
    if ! check_command "bats" "Bats testing framework"; then
        ((warnings++))
    fi
    
    if ! check_command "shellcheck" "ShellCheck"; then
        ((warnings++))
    fi
    
    # Test basic functionality
    log "${BLUE}Testing basic functionality...${NC}"
    
    # Test help command
    if ./yads help &> /dev/null; then
        log "${GREEN}✓ YADS help command works${NC}"
    else
        log "${RED}✗ YADS help command failed${NC}"
        ((errors++))
    fi
    
    # Test status command
    if ./yads status &> /dev/null; then
        log "${GREEN}✓ YADS status command works${NC}"
    else
        log "${RED}✗ YADS status command failed${NC}"
        ((errors++))
    fi
    
    # Test test runner
    if tests/run-tests.sh --list &> /dev/null; then
        log "${GREEN}✓ Test runner works${NC}"
    else
        log "${RED}✗ Test runner failed${NC}"
        ((errors++))
    fi
    
    # Summary
    echo
    log "${CYAN}Verification Summary${NC}"
    log "===================="
    
    if [[ $errors -eq 0 ]]; then
        log "${GREEN}✓ All critical checks passed!${NC}"
    else
        log "${RED}✗ $errors critical issues found${NC}"
    fi
    
    if [[ $warnings -gt 0 ]]; then
        log "${YELLOW}⚠ $warnings warnings (non-critical)${NC}"
    fi
    
    echo
    log "${BLUE}Next steps:${NC}"
    log "1. Run 'make test' to run all tests"
    log "2. Run 'make install' to install YADS"
    log "3. Run 'yads help' to see available commands"
    
    if [[ $errors -gt 0 ]]; then
        exit 1
    else
        log "${GREEN}YADS setup verification completed successfully!${NC}"
        exit 0
    fi
}

# Run main function
main "$@"

