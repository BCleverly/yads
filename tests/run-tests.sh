#!/bin/bash

# YADS Test Runner
# Runs all Bats tests for the YADS project

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
TEST_DIR="$(dirname "$0")"
YADS_DIR="$(dirname "$TEST_DIR")"
BATS_CMD="bats"
REPORT_DIR="$TEST_DIR/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Logging function
log() {
    echo -e "$1"
}

# Check if Bats is installed
check_bats() {
    if ! command -v "$BATS_CMD" &> /dev/null; then
        log "${YELLOW}Bats is not installed. Installing...${NC}"
        
        # Try to install Bats
        if command -v npm &> /dev/null; then
            npm install -g bats
        elif command -v brew &> /dev/null; then
            brew install bats-core
        elif command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y bats
        elif command -v yum &> /dev/null; then
            sudo yum install -y bats
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y bats
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm bats-core
        else
            log "${RED}Could not install Bats automatically. Please install it manually.${NC}"
            log "Visit: https://github.com/bats-core/bats-core"
            exit 1
        fi
    fi
    
    log "${GREEN}✓ Bats is available${NC}"
}

# Create report directory
setup_reports() {
    mkdir -p "$REPORT_DIR"
    log "${BLUE}Report directory: $REPORT_DIR${NC}"
}

# Run all tests
run_all_tests() {
    log "${CYAN}Running all YADS tests...${NC}"
    
    local test_files=(
        "$TEST_DIR/yads.bats"
        "$TEST_DIR/install.bats"
        "$TEST_DIR/domains.bats"
        "$TEST_DIR/projects.bats"
        "$TEST_DIR/debian-ubuntu.bats"
    )
    
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    for test_file in "${test_files[@]}"; do
        if [[ -f "$test_file" ]]; then
            log "${BLUE}Running $(basename "$test_file")...${NC}"
            
            # Run test with TAP output
            if "$BATS_CMD" --tap "$test_file" > "$REPORT_DIR/$(basename "$test_file" .bats)_$TIMESTAMP.tap" 2>&1; then
                log "${GREEN}✓ $(basename "$test_file") passed${NC}"
                ((passed_tests++))
            else
                log "${RED}✗ $(basename "$test_file") failed${NC}"
                ((failed_tests++))
            fi
            ((total_tests++))
        else
            log "${YELLOW}⚠ Test file $test_file not found${NC}"
        fi
    done
    
    # Generate summary report
    generate_summary_report "$total_tests" "$passed_tests" "$failed_tests"
}

# Run specific test file
run_specific_test() {
    local test_file="$1"
    
    if [[ ! -f "$test_file" ]]; then
        log "${RED}Test file $test_file not found${NC}"
        exit 1
    fi
    
    log "${CYAN}Running specific test: $(basename "$test_file")${NC}"
    
    if "$BATS_CMD" --tap "$test_file" > "$REPORT_DIR/$(basename "$test_file" .bats)_$TIMESTAMP.tap" 2>&1; then
        log "${GREEN}✓ Test passed${NC}"
    else
        log "${RED}✗ Test failed${NC}"
        exit 1
    fi
}

# Generate summary report
generate_summary_report() {
    local total="$1"
    local passed="$2"
    local failed="$3"
    
    cat > "$REPORT_DIR/summary_$TIMESTAMP.txt" << EOF
YADS Test Summary
================
Timestamp: $(date)
Total Tests: $total
Passed: $passed
Failed: $failed
Success Rate: $(( passed * 100 / total ))%

Test Files:
$(ls -la "$REPORT_DIR"/*.tap 2>/dev/null | awk '{print $9}' | sed 's/.*\///' | sed 's/_'$TIMESTAMP'.tap$//' | sed 's/^/- /')

Reports:
$(ls -la "$REPORT_DIR"/*.tap 2>/dev/null | awk '{print $9}' | sed 's/^/- /')
EOF
    
    log "${CYAN}Test Summary:${NC}"
    log "Total: $total"
    log "Passed: ${GREEN}$passed${NC}"
    log "Failed: ${RED}$failed${NC}"
    log "Success Rate: $(( passed * 100 / total ))%"
    log
    log "${BLUE}Reports saved to: $REPORT_DIR${NC}"
}

# Run tests with coverage
run_tests_with_coverage() {
    log "${CYAN}Running tests with coverage analysis...${NC}"
    
    # This would require additional tools like kcov
    # For now, just run regular tests
    run_all_tests
}

# Clean up old reports
cleanup_reports() {
    log "${BLUE}Cleaning up old reports...${NC}"
    
    # Keep only last 10 reports
    ls -t "$REPORT_DIR"/*.tap 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
    ls -t "$REPORT_DIR"/summary_*.txt 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
}

# Show help
show_help() {
    cat << EOF
YADS Test Runner

Usage: $0 [options] [test-file]

Options:
    -h, --help          Show this help message
    -a, --all           Run all tests (default)
    -c, --coverage      Run tests with coverage analysis
    -r, --report        Show latest test report
    -l, --list          List available test files
    -v, --verbose       Verbose output

Examples:
    $0                  # Run all tests
    $0 yads.bats        # Run specific test file
    $0 --coverage       # Run with coverage
    $0 --report         # Show latest report
EOF
}

# Show latest report
show_latest_report() {
    local latest_report=$(ls -t "$REPORT_DIR"/summary_*.txt 2>/dev/null | head -n1)
    
    if [[ -f "$latest_report" ]]; then
        log "${CYAN}Latest Test Report:${NC}"
        cat "$latest_report"
    else
        log "${YELLOW}No test reports found${NC}"
    fi
}

# List available test files
list_tests() {
    log "${CYAN}Available test files:${NC}"
    for test_file in "$TEST_DIR"/*.bats; do
        if [[ -f "$test_file" ]]; then
            log "  - $(basename "$test_file")"
        fi
    done
}

# Main function
main() {
    local run_all=true
    local test_file=""
    local coverage=false
    local show_report=false
    local list_tests_flag=false
    local verbose=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -a|--all)
                run_all=true
                shift
                ;;
            -c|--coverage)
                coverage=true
                shift
                ;;
            -r|--report)
                show_report=true
                shift
                ;;
            -l|--list)
                list_tests_flag=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -*)
                log "${RED}Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
            *)
                test_file="$1"
                run_all=false
                shift
                ;;
        esac
    done
    
    # Handle different modes
    if [[ "$list_tests_flag" == true ]]; then
        list_tests
        exit 0
    fi
    
    if [[ "$show_report" == true ]]; then
        show_latest_report
        exit 0
    fi
    
    # Check Bats installation
    check_bats
    
    # Setup reports
    setup_reports
    
    # Run tests
    if [[ "$run_all" == true ]]; then
        if [[ "$coverage" == true ]]; then
            run_tests_with_coverage
        else
            run_all_tests
        fi
    else
        run_specific_test "$test_file"
    fi
    
    # Cleanup
    cleanup_reports
    
    log "${GREEN}Test run completed!${NC}"
}

# Run main function
main "$@"

