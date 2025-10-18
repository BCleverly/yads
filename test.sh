#!/bin/bash

# YADS Test Script
# This script tests the YADS installation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test functions
test_yads_script() {
    echo -e "${BLUE}Testing YADS script...${NC}"
    
    if [[ -f "./yads" ]]; then
        echo -e "${GREEN}✓ YADS script exists${NC}"
    else
        echo -e "${RED}✗ YADS script not found${NC}"
        return 1
    fi
    
    if [[ -x "./yads" ]]; then
        echo -e "${GREEN}✓ YADS script is executable${NC}"
    else
        echo -e "${RED}✗ YADS script is not executable${NC}"
        return 1
    fi
}

test_modules() {
    echo -e "${BLUE}Testing YADS modules...${NC}"
    
    for module in modules/install.sh modules/domains.sh modules/projects.sh; do
        if [[ -f "$module" ]]; then
            echo -e "${GREEN}✓ $module exists${NC}"
        else
            echo -e "${RED}✗ $module not found${NC}"
            return 1
        fi
        
        if [[ -x "$module" ]]; then
            echo -e "${GREEN}✓ $module is executable${NC}"
        else
            echo -e "${RED}✗ $module is not executable${NC}"
            return 1
        fi
    done
}

test_help_command() {
    echo -e "${BLUE}Testing YADS help command...${NC}"
    
    if ./yads help &> /dev/null; then
        echo -e "${GREEN}✓ YADS help command works${NC}"
    else
        echo -e "${RED}✗ YADS help command failed${NC}"
        return 1
    fi
}

test_status_command() {
    echo -e "${BLUE}Testing YADS status command...${NC}"
    
    if ./yads status &> /dev/null; then
        echo -e "${GREEN}✓ YADS status command works${NC}"
    else
        echo -e "${RED}✗ YADS status command failed${NC}"
        return 1
    fi
}

# Main test function
main() {
    echo -e "${CYAN}YADS Test Suite${NC}"
    echo
    
    local tests_passed=0
    local tests_total=4
    
    # Run tests
    if test_yads_script; then
        ((tests_passed++))
    fi
    
    if test_modules; then
        ((tests_passed++))
    fi
    
    if test_help_command; then
        ((tests_passed++))
    fi
    
    if test_status_command; then
        ((tests_passed++))
    fi
    
    echo
    echo -e "${BLUE}Test Results: $tests_passed/$tests_total tests passed${NC}"
    
    if [[ $tests_passed -eq $tests_total ]]; then
        echo -e "${GREEN}✓ All tests passed! YADS is ready to use.${NC}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed. Please check the installation.${NC}"
        return 1
    fi
}

# Run main function
main "$@"

