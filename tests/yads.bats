#!/usr/bin/env bats

# Tests for main YADS script

load 'setup.bash'

@test "YADS script exists and is executable" {
    assert_file_exists "$YADS_SCRIPT"
    assert_file_executable "$YADS_SCRIPT"
}

@test "YADS help command works" {
    run "$YADS_SCRIPT" help
    assert_success
    assert_output --partial "YADS - Yet Another Development Server"
    assert_output --partial "Usage:"
    assert_output --partial "Commands:"
}

@test "YADS status command works" {
    run "$YADS_SCRIPT" status
    assert_success
    assert_output --partial "YADS Installation Status"
}

@test "YADS shows error for unknown command" {
    run "$YADS_SCRIPT" unknown-command
    assert_failure
    assert_output --partial "Unknown command: unknown-command"
}

@test "YADS requires project name for create command" {
    run "$YADS_SCRIPT" create
    assert_failure
    assert_output --partial "Project name is required"
}

@test "YADS validates project name format" {
    run "$YADS_SCRIPT" create "invalid project name!"
    assert_failure
    assert_output --partial "Invalid project name"
}

@test "YADS creates configuration directory" {
    run "$YADS_SCRIPT" help
    assert_success
    assert_file_exists "$HOME/.yads"
}

@test "YADS loads configuration correctly" {
    create_test_config
    run "$YADS_SCRIPT" status
    assert_success
}

@test "YADS detects OS correctly" {
    run "$YADS_SCRIPT" status
    assert_success
    # Should detect some OS
    assert_output --partial "Detected OS:"
}

@test "YADS handles missing modules gracefully" {
    # Temporarily move modules
    mv "$YADS_DIR/modules" "$YADS_DIR/modules.backup"
    mkdir -p "$YADS_DIR/modules"
    
    run "$YADS_SCRIPT" install
    # Should not crash, but may show warnings
    
    # Restore modules
    rm -rf "$YADS_DIR/modules"
    mv "$YADS_DIR/modules.backup" "$YADS_DIR/modules"
}

@test "YADS script has proper shebang" {
    run head -n1 "$YADS_SCRIPT"
    assert_success
    assert_output --partial "#!/bin/bash"
}

@test "YADS script syntax is valid" {
    # Check for basic syntax errors
    run bash -n "$YADS_SCRIPT"
    assert_success
}

@test "YADS modules are executable" {
    assert_file_executable "$YADS_DIR/modules/install.sh"
    assert_file_executable "$YADS_DIR/modules/domains.sh"
    assert_file_executable "$YADS_DIR/modules/projects.sh"
}

@test "YADS modules have valid syntax" {
    run bash -n "$YADS_DIR/modules/install.sh"
    assert_success
    
    run bash -n "$YADS_DIR/modules/domains.sh"
    assert_success
    
    run bash -n "$YADS_DIR/modules/projects.sh"
    assert_success
}

