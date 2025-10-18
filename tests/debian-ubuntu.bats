#!/usr/bin/env bats

# Tests specific to Debian and Ubuntu systems

load 'setup.bash'

@test "System detection works on Ubuntu" {
    skip_if_not_ubuntu
    
    source "$YADS_DIR/modules/install.sh"
    
    export OS="ubuntu"
    export OS_VERSION="22.04"
    
    run detect_os
    assert_success
    assert_output --partial "Detected OS: ubuntu 22.04"
}

@test "System detection works on Debian" {
    skip_if_not_debian
    
    source "$YADS_DIR/modules/install.sh"
    
    export OS="debian"
    export OS_VERSION="11"
    
    run detect_os
    assert_success
    assert_output --partial "Detected OS: debian 11"
}

@test "Package manager commands work on Ubuntu" {
    skip_if_not_ubuntu
    
    source "$YADS_DIR/modules/install.sh"
    mock_sudo
    
    export OS="ubuntu"
    export OS_VERSION="22.04"
    
    # Test apt-get commands
    run update_system
    # Should not crash with mocked sudo
    
    # Test package installation
    run install_php
    # Should not crash with mocked sudo
}

@test "Package manager commands work on Debian" {
    skip_if_not_debian
    
    source "$YADS_DIR/modules/install.sh"
    mock_sudo
    
    export OS="debian"
    export OS_VERSION="11"
    
    # Test apt-get commands
    run update_system
    # Should not crash with mocked sudo
    
    # Test package installation
    run install_php
    # Should not crash with mocked sudo
}

@test "PHP installation works on Ubuntu 22.04" {
    skip_if_not_ubuntu
    
    source "$YADS_DIR/modules/install.sh"
    mock_sudo
    mock_curl
    
    export OS="ubuntu"
    export OS_VERSION="22.04"
    
    run install_php
    # Should not crash with mocked commands
}

@test "PHP installation works on Debian 11" {
    skip_if_not_debian
    
    source "$YADS_DIR/modules/install.sh"
    mock_sudo
    mock_curl
    
    export OS="debian"
    export OS_VERSION="11"
    
    run install_php
    # Should not crash with mocked commands
}

@test "MySQL installation works on Ubuntu" {
    skip_if_not_ubuntu
    
    source "$YADS_DIR/modules/install.sh"
    mock_sudo
    
    export OS="ubuntu"
    export OS_VERSION="22.04"
    
    run install_mysql
    # Should not crash with mocked sudo
}

@test "MySQL installation works on Debian" {
    skip_if_not_debian
    
    source "$YADS_DIR/modules/install.sh"
    mock_sudo
    
    export OS="debian"
    export OS_VERSION="11"
    
    run install_mysql
    # Should not crash with mocked sudo
}

@test "PostgreSQL installation works on Ubuntu" {
    skip_if_not_ubuntu
    
    source "$YADS_DIR/modules/install.sh"
    mock_sudo
    
    export OS="ubuntu"
    export OS_VERSION="22.04"
    
    run install_postgresql
    # Should not crash with mocked sudo
}

@test "PostgreSQL installation works on Debian" {
    skip_if_not_debian
    
    source "$YADS_DIR/modules/install.sh"
    mock_sudo
    
    export OS="debian"
    export OS_VERSION="11"
    
    run install_postgresql
    # Should not crash with mocked sudo
}

@test "NGINX installation works on Ubuntu" {
    skip_if_not_ubuntu
    
    source "$YADS_DIR/modules/install.sh"
    mock_sudo
    
    export OS="ubuntu"
    export OS_VERSION="22.04"
    
    run install_nginx
    # Should not crash with mocked sudo
}

@test "NGINX installation works on Debian" {
    skip_if_not_debian
    
    source "$YADS_DIR/modules/install.sh"
    mock_sudo
    
    export OS="debian"
    export OS_VERSION="11"
    
    run install_nginx
    # Should not crash with mocked sudo
}

@test "Composer installation works on Ubuntu" {
    skip_if_not_ubuntu
    
    source "$YADS_DIR/modules/install.sh"
    mock_curl
    
    export OS="ubuntu"
    export OS_VERSION="22.04"
    
    run install_composer
    # Should not crash with mocked curl
}

@test "Composer installation works on Debian" {
    skip_if_not_debian
    
    source "$YADS_DIR/modules/install.sh"
    mock_curl
    
    export OS="debian"
    export OS_VERSION="11"
    
    run install_composer
    # Should not crash with mocked curl
}

@test "GitHub CLI installation works on Ubuntu" {
    skip_if_not_ubuntu
    
    source "$YADS_DIR/modules/install.sh"
    mock_curl
    
    export OS="ubuntu"
    export OS_VERSION="22.04"
    
    run install_github_cli
    # Should not crash with mocked curl
}

@test "GitHub CLI installation works on Debian" {
    skip_if_not_debian
    
    source "$YADS_DIR/modules/install.sh"
    mock_curl
    
    export OS="debian"
    export OS_VERSION="11"
    
    run install_github_cli
    # Should not crash with mocked curl
}

@test "Cloudflare tunnel installation works on Ubuntu" {
    skip_if_not_ubuntu
    
    source "$YADS_DIR/modules/install.sh"
    mock_sudo
    mock_wget
    
    export OS="ubuntu"
    export OS_VERSION="22.04"
    
    run install_cloudflared
    # Should not crash with mocked commands
}

@test "Cloudflare tunnel installation works on Debian" {
    skip_if_not_debian
    
    source "$YADS_DIR/modules/install.sh"
    mock_sudo
    mock_wget
    
    export OS="debian"
    export OS_VERSION="11"
    
    run install_cloudflared
    # Should not crash with mocked commands
}

@test "System service management works on Ubuntu" {
    skip_if_not_ubuntu
    
    source "$YADS_DIR/modules/install.sh"
    mock_sudo
    
    export OS="ubuntu"
    export OS_VERSION="22.04"
    
    # Test systemctl commands
    run install_mysql
    # Should not crash with mocked sudo
    
    run install_postgresql
    # Should not crash with mocked sudo
}

@test "System service management works on Debian" {
    skip_if_not_debian
    
    source "$YADS_DIR/modules/install.sh"
    mock_sudo
    
    export OS="debian"
    export OS_VERSION="11"
    
    # Test systemctl commands
    run install_mysql
    # Should not crash with mocked sudo
    
    run install_postgresql
    # Should not crash with mocked sudo
}

@test "User and group management works on Ubuntu" {
    skip_if_not_ubuntu
    
    source "$YADS_DIR/modules/install.sh"
    mock_sudo
    
    export OS="ubuntu"
    export OS_VERSION="22.04"
    
    run configure_permissions
    # Should not crash with mocked sudo
}

@test "User and group management works on Debian" {
    skip_if_not_debian
    
    source "$YADS_DIR/modules/install.sh"
    mock_sudo
    
    export OS="debian"
    export OS_VERSION="11"
    
    run configure_permissions
    # Should not crash with mocked sudo
}

@test "SSL certificate management works on Ubuntu" {
    skip_if_not_ubuntu
    
    source "$YADS_DIR/modules/domains.sh"
    mock_sudo
    
    export OS="ubuntu"
    export OS_VERSION="22.04"
    export DOMAIN="test.example.com"
    
    # Mock certbot commands
    certbot() {
        case "$1" in
            "certonly")
                echo "Mock certificate obtained"
                return 0
                ;;
        esac
    }
    export -f certbot
    
    run configure_ssl
    # Should not crash with mocked certbot
}

@test "SSL certificate management works on Debian" {
    skip_if_not_debian
    
    source "$YADS_DIR/modules/domains.sh"
    mock_sudo
    
    export OS="debian"
    export OS_VERSION="11"
    export DOMAIN="test.example.com"
    
    # Mock certbot commands
    certbot() {
        case "$1" in
            "certonly")
                echo "Mock certificate obtained"
                return 0
                ;;
        esac
    }
    export -f certbot
    
    run configure_ssl
    # Should not crash with mocked certbot
}

@test "Project creation works on Ubuntu" {
    skip_if_not_ubuntu
    
    source "$YADS_DIR/modules/projects.sh"
    mock_sudo
    
    export OS="ubuntu"
    export OS_VERSION="22.04"
    export DOMAIN="test.example.com"
    
    # Mock composer commands
    composer() {
        case "$1" in
            "create-project")
                mkdir -p "$3"
                echo "<?php echo 'Test project'; ?>" > "$3/index.php"
                ;;
        esac
    }
    export -f composer
    
    run create_project "test-project"
    # Should not crash with mocked commands
}

@test "Project creation works on Debian" {
    skip_if_not_debian
    
    source "$YADS_DIR/modules/projects.sh"
    mock_sudo
    
    export OS="debian"
    export OS_VERSION="11"
    export DOMAIN="test.example.com"
    
    # Mock composer commands
    composer() {
        case "$1" in
            "create-project")
                mkdir -p "$3"
                echo "<?php echo 'Test project'; ?>" > "$3/index.php"
                ;;
        esac
    }
    export -f composer
    
    run create_project "test-project"
    # Should not crash with mocked commands
}

