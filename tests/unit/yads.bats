#!/usr/bin/env bats

# YADS Unit Tests
# Test the main YADS functionality

load 'test_helper'

@test "yads help shows usage information" {
    run ./yads help
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "YADS - Yet Another Development Server" ]
}

@test "yads version shows version information" {
    run ./yads version
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "YADS 1.0.0" ]
}

@test "yads without arguments shows help" {
    run ./yads
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "YADS - Yet Another Development Server" ]
}

@test "yads unknown command shows error" {
    run ./yads unknown-command
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "❌ Error: Unknown command: unknown-command. Use 'yads help' for available commands." ]
}
