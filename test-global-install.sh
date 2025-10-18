#!/bin/bash

# Test script to verify YADS global installation

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

# Test function
test_global_availability() {
    log "${CYAN}Testing YADS Global Availability${NC}"
    echo
    
    # Test 1: Check if yads command is available
    log "${BLUE}Test 1: Command availability${NC}"
    if command -v yads &> /dev/null; then
        log "${GREEN}✓ YADS command is available globally${NC}"
    else
        log "${RED}✗ YADS command is not available globally${NC}"
        return 1
    fi
    
    # Test 2: Check if yads works from different directories
    log "${BLUE}Test 2: Working from different directories${NC}"
    
    # Test from home directory
    cd "$HOME"
    if yads help &> /dev/null; then
        log "${GREEN}✓ YADS works from home directory${NC}"
    else
        log "${RED}✗ YADS does not work from home directory${NC}"
        return 1
    fi
    
    # Test from /tmp
    cd /tmp
    if yads help &> /dev/null; then
        log "${GREEN}✓ YADS works from /tmp directory${NC}"
    else
        log "${RED}✗ YADS does not work from /tmp directory${NC}"
        return 1
    fi
    
    # Test from a random directory
    cd /var/log 2>/dev/null || cd /tmp
    if yads help &> /dev/null; then
        log "${GREEN}✓ YADS works from system directories${NC}"
    else
        log "${RED}✗ YADS does not work from system directories${NC}"
        return 1
    fi
    
    # Test 3: Check PATH configuration
    log "${BLUE}Test 3: PATH configuration${NC}"
    if echo "$PATH" | grep -q "$HOME/.local/bin"; then
        log "${GREEN}✓ $HOME/.local/bin is in PATH${NC}"
    else
        log "${YELLOW}⚠ $HOME/.local/bin is not in PATH${NC}"
        log "${YELLOW}  You may need to restart your terminal or run 'source ~/.bashrc'${NC}"
    fi
    
    # Test 4: Check for system-wide symlink
    log "${BLUE}Test 4: System-wide symlink${NC}"
    if [[ -L /usr/local/bin/yads ]]; then
        log "${GREEN}✓ System-wide symlink exists${NC}"
    else
        log "${YELLOW}⚠ No system-wide symlink found${NC}"
        log "${YELLOW}  YADS is available via PATH instead${NC}"
    fi
    
    # Test 5: Check YADS functionality
    log "${BLUE}Test 5: YADS functionality${NC}"
    if yads status &> /dev/null; then
        log "${GREEN}✓ YADS status command works${NC}"
    else
        log "${RED}✗ YADS status command failed${NC}"
        return 1
    fi
    
    if yads prerequisites &> /dev/null; then
        log "${GREEN}✓ YADS prerequisites command works${NC}"
    else
        log "${RED}✗ YADS prerequisites command failed${NC}"
        return 1
    fi
    
    log "${GREEN}✓ All tests passed! YADS is globally available.${NC}"
    return 0
}

# Main function
main() {
    log "${CYAN}YADS Global Availability Test${NC}"
    echo
    
    if test_global_availability; then
        log "${GREEN}YADS is properly installed and globally available!${NC}"
        echo
        log "${BLUE}You can now use YADS from anywhere:${NC}"
        echo "  • From any directory: yads help"
        echo "  • From scripts: yads status"
        echo "  • From automation: yads install"
        echo
        log "${YELLOW}Next steps:${NC}"
        echo "1. Run 'yads prerequisites' to check your system"
        echo "2. Run 'yads install' to set up your development server"
        exit 0
    else
        log "${RED}YADS is not properly installed or not globally available.${NC}"
        echo
        log "${YELLOW}Troubleshooting:${NC}"
        echo "1. Restart your terminal"
        echo "2. Run 'source ~/.bashrc'"
        echo "3. Check if $HOME/.local/bin is in your PATH"
        echo "4. Reinstall YADS if necessary"
        exit 1
    fi
}

# Run main function
main "$@"
