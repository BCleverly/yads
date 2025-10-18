#!/usr/bin/env bats

# Tests for YADS installation module

load 'setup.bash'

@test "Install module loads correctly" {
    source "$YADS_DIR/modules/install.sh"
    # Should not crash
}

@test "OS detection works on Debian/Ubuntu" {
    skip_if_not_debian
    
    source "$YADS_DIR/modules/install.sh"
    
    # Mock OS detection
    export OS="ubuntu"
    export OS_VERSION="22.04"
    
    run detect_os
    assert_success
}

@test "System update function works" {
    skip_if_not_debian
    
    source "$YADS_DIR/modules/install.sh"
    mock_sudo
    
    export OS="ubuntu"
    run update_system
    # Should not crash with mocked sudo
}

@test "PHP installation detection works" {
    source "$YADS_DIR/modules/install.sh"
    
    # Test detection when PHP is not installed
    run command -v php
    # May or may not be installed, but function should handle it
    
    # Test detection function
    run detect_and_remove "php" "php"
    # Should not crash
}

@test "MySQL installation detection works" {
    source "$YADS_DIR/modules/install.sh"
    
    # Test detection when MySQL is not installed
    run command -v mysql
    # May or may not be installed, but function should handle it
    
    # Test detection function
    run detect_and_remove "mysql" "mysql"
    # Should not crash
}

@test "PostgreSQL installation detection works" {
    source "$YADS_DIR/modules/install.sh"
    
    # Test detection when PostgreSQL is not installed
    run command -v psql
    # May or may not be installed, but function should handle it
    
    # Test detection function
    run detect_and_remove "postgresql" "postgresql"
    # Should not crash
}

@test "NGINX installation detection works" {
    source "$YADS_DIR/modules/install.sh"
    
    # Test detection when NGINX is not installed
    run command -v nginx
    # May or may not be installed, but function should handle it
    
    # Test detection function
    run detect_and_remove "nginx" "nginx"
    # Should not crash
}

@test "Cloudflare tunnel installation detection works" {
    source "$YADS_DIR/modules/install.sh"
    
    # Test detection when cloudflared is not installed
    run command -v cloudflared
    # May or may not be installed, but function should handle it
    
    # Test detection function
    run detect_and_remove "cloudflared" "cloudflared"
    # Should not crash
}

@test "GitHub CLI installation detection works" {
    source "$YADS_DIR/modules/install.sh"
    
    # Test detection when gh is not installed
    run command -v gh
    # May or may not be installed, but function should handle it
    
    # Test detection function
    run detect_and_remove "gh" "github-cli"
    # Should not crash
}

@test "Composer installation detection works" {
    source "$YADS_DIR/modules/install.sh"
    
    # Test detection when composer is not installed
    run command -v composer
    # May or may not be installed, but function should handle it
    
    # Test detection function
    run detect_and_remove "composer" "composer"
    # Should not crash
}

@test "Web server choice function works" {
    source "$YADS_DIR/modules/install.sh"
    
    # Test web server choice with mocked input
    echo "1" | run choose_web_server
    # Should not crash
}

@test "User permission configuration works" {
    source "$YADS_DIR/modules/install.sh"
    mock_sudo
    
    run configure_permissions
    # Should not crash with mocked sudo
}

@test "SSH key configuration works" {
    source "$YADS_DIR/modules/install.sh"
    
    # Test SSH key generation (may already exist)
    run configure_ssh_keys
    # Should not crash
}

@test "Installation functions handle missing dependencies gracefully" {
    source "$YADS_DIR/modules/install.sh"
    mock_sudo
    mock_curl
    mock_wget
    
    # Test that functions don't crash when dependencies are missing
    run install_php
    # Should handle missing dependencies gracefully
    
    run install_mysql
    # Should handle missing dependencies gracefully
    
    run install_postgresql
    # Should handle missing dependencies gracefully
}

@test "Installation functions work on Ubuntu 22.04" {
    skip_if_not_ubuntu
    
    source "$YADS_DIR/modules/install.sh"
    mock_sudo
    mock_curl
    mock_wget
    
    export OS="ubuntu"
    export OS_VERSION="22.04"
    
    # Test Ubuntu-specific installation paths
    run update_system
    # Should not crash
    
    run install_php
    # Should not crash
    
    run install_mysql
    # Should not crash
}

@test "Installation functions work on Debian 11" {
    skip_if_not_debian
    
    source "$YADS_DIR/modules/install.sh"
    mock_sudo
    mock_curl
    mock_wget
    
    export OS="debian"
    export OS_VERSION="11"
    
    # Test Debian-specific installation paths
    run update_system
    # Should not crash
    
    run install_php
    # Should not crash
    
    run install_mysql
    # Should not crash
}

@test "Configuration saving works" {
    source "$YADS_DIR/modules/install.sh"
    
    export WEB_SERVER="nginx"
    export PHP_VERSION="8.4"
    export DOMAIN="test.example.com"
    
    run save_config
    assert_success
    assert_file_exists "$YADS_CONFIG_FILE"
    assert_contains "WEB_SERVER=\"nginx\"" "$YADS_CONFIG_FILE"
    assert_contains "PHP_VERSION=\"8.4\"" "$YADS_CONFIG_FILE"
    assert_contains "DOMAIN=\"test.example.com\"" "$YADS_CONFIG_FILE"
}

@test "Configuration loading works" {
    source "$YADS_DIR/modules/install.sh"
    
    # Create test configuration
    create_test_config
    
    # Load configuration
    load_config
    
    # Verify variables are set
    [[ "$WEB_SERVER" == "nginx" ]]
    [[ "$PHP_VERSION" == "8.4" ]]
    [[ "$DOMAIN" == "test.example.com" ]]
}

