#!/bin/bash

# Test setup and utilities for YADS tests

# Colors for test output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m'

# Test configuration
export TEST_DIR="$(dirname "$BATS_TEST_FILENAME")"
export YADS_DIR="$(dirname "$TEST_DIR")"
export YADS_SCRIPT="$YADS_DIR/yads"
export TEST_TEMP_DIR="/tmp/yads-test-$$"

# Test utilities
setup_test_environment() {
    # Create temporary directory for tests
    mkdir -p "$TEST_TEMP_DIR"
    
    # Backup original YADS directory if it exists
    if [[ -d "$HOME/.yads" ]]; then
        mv "$HOME/.yads" "$HOME/.yads.backup.$$"
    fi
    
    # Create test YADS directory
    mkdir -p "$HOME/.yads"
    
    # Set test configuration
    export YADS_TEST_MODE=true
    export YADS_CONFIG_FILE="$HOME/.yads/config"
}

cleanup_test_environment() {
    # Remove test directory
    rm -rf "$TEST_TEMP_DIR"
    
    # Restore original YADS directory
    if [[ -d "$HOME/.yads.backup.$$" ]]; then
        rm -rf "$HOME/.yads"
        mv "$HOME/.yads.backup.$$" "$HOME/.yads"
    else
        rm -rf "$HOME/.yads"
    fi
    
    # Clean up any test processes
    pkill -f "yads" 2>/dev/null || true
}

# Mock functions for testing
mock_sudo() {
    # Mock sudo to avoid requiring actual sudo privileges
    sudo() {
        if [[ "$1" == "apt-get" ]] || [[ "$1" == "systemctl" ]] || [[ "$1" == "useradd" ]]; then
            echo "Mock sudo: $*"
            return 0
        fi
        return 0
    }
    export -f sudo
}

mock_curl() {
    # Mock curl for downloading packages
    curl() {
        if [[ "$*" == *"getcomposer.org"* ]]; then
            echo "Mock Composer installer"
            return 0
        elif [[ "$*" == *"github.com"* ]]; then
            echo "Mock GitHub download"
            return 0
        fi
        return 0
    }
    export -f curl
}

mock_wget() {
    # Mock wget for downloading packages
    wget() {
        if [[ "$*" == *"cloudflared"* ]]; then
            echo "Mock Cloudflare tunnel download"
            return 0
        fi
        return 0
    }
    export -f wget
}

# Test assertion helpers
assert_file_exists() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "FAIL: File $file does not exist"
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        echo "FAIL: File $file should not exist"
        return 1
    fi
}

assert_file_executable() {
    local file="$1"
    if [[ ! -x "$file" ]]; then
        echo "FAIL: File $file is not executable"
        return 1
    fi
}

assert_contains() {
    local content="$1"
    local file="$2"
    if ! grep -q "$content" "$file"; then
        echo "FAIL: File $file does not contain '$content'"
        return 1
    fi
}

assert_success() {
    if [[ $status -ne 0 ]]; then
        echo "FAIL: Command failed with exit code $status"
        echo "Output: $output"
        return 1
    fi
}

assert_failure() {
    if [[ $status -eq 0 ]]; then
        echo "FAIL: Command should have failed but succeeded"
        echo "Output: $output"
        return 1
    fi
}

# OS detection for tests
detect_test_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        export TEST_OS="$ID"
        export TEST_OS_VERSION="$VERSION_ID"
    else
        export TEST_OS="unknown"
        export TEST_OS_VERSION="unknown"
    fi
}

# Skip tests based on OS
skip_if_not_debian() {
    if [[ "$TEST_OS" != "debian" ]] && [[ "$TEST_OS" != "ubuntu" ]]; then
        skip "Test requires Debian/Ubuntu"
    fi
}

skip_if_not_ubuntu() {
    if [[ "$TEST_OS" != "ubuntu" ]]; then
        skip "Test requires Ubuntu"
    fi
}

# Test data generators
create_test_config() {
    cat > "$YADS_CONFIG_FILE" << EOF
WEB_SERVER="nginx"
PHP_VERSION="8.4"
DOMAIN="test.example.com"
CLOUDFLARE_TOKEN="test-token"
GITHUB_TOKEN="test-github-token"
EOF
}

create_test_project() {
    local project_name="$1"
    local project_path="/tmp/yads-test-$$/$project_name"
    
    mkdir -p "$project_path"
    echo "<?php echo 'Test project'; ?>" > "$project_path/index.php"
    
    echo "$project_path"
}

# Load YADS functions for testing
load_yads_functions() {
    # Source the main YADS script to get functions
    source "$YADS_SCRIPT" 2>/dev/null || true
    
    # Source modules
    source "$YADS_DIR/modules/install.sh" 2>/dev/null || true
    source "$YADS_DIR/modules/domains.sh" 2>/dev/null || true
    source "$YADS_DIR/modules/projects.sh" 2>/dev/null || true
}

# Test setup for each test
setup() {
    setup_test_environment
    detect_test_os
    load_yads_functions
}

# Test teardown for each test
teardown() {
    cleanup_test_environment
}

