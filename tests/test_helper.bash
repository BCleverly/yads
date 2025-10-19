#!/usr/bin/env bash

# Test helper functions for YADS tests

# Setup test environment
setup() {
    # Create temporary directory for tests
    TEST_DIR=$(mktemp -d)
    export TEST_DIR
    
    # Set up test environment variables
    export NO_COLOR=1
    export YADS_TEST_MODE=1
}

# Cleanup test environment
teardown() {
    # Remove temporary directory
    if [[ -n "${TEST_DIR:-}" ]] && [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# Mock systemctl for testing
mock_systemctl() {
    local service="$1"
    local action="$2"
    
    case "$action" in
        is-active)
            if [[ "$service" == "vscode-server" ]] || [[ "$service" == "cloudflared" ]]; then
                return 0
            fi
            return 1
            ;;
        start|stop|restart)
            echo "Mock: systemctl $action $service"
            return 0
            ;;
    esac
}

# Mock command existence
mock_command() {
    local cmd="$1"
    local exists="${2:-true}"
    
    if [[ "$exists" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Assert file exists
assert_file_exists() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "File does not exist: $file"
        return 1
    fi
}

# Assert file contains text
assert_file_contains() {
    local file="$1"
    local text="$2"
    
    if ! grep -q "$text" "$file"; then
        echo "File does not contain '$text': $file"
        return 1
    fi
}

# Assert service is running
assert_service_running() {
    local service="$1"
    
    if ! systemctl is-active --quiet "$service"; then
        echo "Service is not running: $service"
        return 1
    fi
}

# Assert service is stopped
assert_service_stopped() {
    local service="$1"
    
    if systemctl is-active --quiet "$service"; then
        echo "Service is running (should be stopped): $service"
        return 1
    fi
}
