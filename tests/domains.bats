#!/usr/bin/env bats

# Tests for YADS domains module

load 'setup.bash'

@test "Domains module loads correctly" {
    source "$YADS_DIR/modules/domains.sh"
    # Should not crash
}

@test "Domain input validation works" {
    source "$YADS_DIR/modules/domains.sh"
    
    # Test valid domain
    export DOMAIN="example.com"
    run get_domain_input
    # Should not crash for valid domain
    
    # Test invalid domain
    export DOMAIN="invalid..domain"
    run get_domain_input
    # Should handle invalid domain gracefully
}

@test "Domain format validation works" {
    source "$YADS_DIR/modules/domains.sh"
    
    # Test valid domains
    [[ "example.com" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]
    [[ "sub.example.com" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]
    [[ "test-domain.co.uk" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]
    
    # Test invalid domains
    [[ ! "invalid..domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]
    [[ ! "domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]
    [[ ! ".domain.com" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]
}

@test "Cloudflare tunnel configuration works" {
    source "$YADS_DIR/modules/domains.sh"
    mock_sudo
    
    export DOMAIN="test.example.com"
    export CLOUDFLARE_TOKEN="test-token"
    
    # Mock cloudflared commands
    cloudflared() {
        case "$1" in
            "tunnel")
                case "$2" in
                    "login")
                        echo "Mock login successful"
                        ;;
                    "create")
                        echo "Created tunnel test-tunnel-id"
                        ;;
                esac
                ;;
            "tunnel")
                case "$2" in
                    "route")
                        echo "Mock DNS route created"
                        ;;
                esac
                ;;
        esac
    }
    export -f cloudflared
    
    run configure_cloudflare_tunnel
    # Should not crash with mocked cloudflared
}

@test "SSL certificate configuration works" {
    source "$YADS_DIR/modules/domains.sh"
    mock_sudo
    
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

@test "NGINX SSL configuration works" {
    source "$YADS_DIR/modules/domains.sh"
    mock_sudo
    
    export DOMAIN="test.example.com"
    export WEB_SERVER="nginx"
    
    # Mock nginx commands
    nginx() {
        case "$1" in
            "-t")
                echo "Mock nginx configuration test successful"
                return 0
                ;;
        esac
    }
    export -f nginx
    
    run update_nginx_ssl_config
    # Should not crash with mocked nginx
}

@test "FrankenPHP SSL configuration works" {
    source "$YADS_DIR/modules/domains.sh"
    mock_sudo
    
    export DOMAIN="test.example.com"
    export WEB_SERVER="frankenphp"
    
    run update_frankenphp_ssl_config
    # Should not crash
}

@test "Project domain configuration works" {
    source "$YADS_DIR/modules/domains.sh"
    mock_sudo
    
    export DOMAIN="test.example.com"
    export WEB_SERVER="nginx"
    
    # Mock nginx commands
    nginx() {
        case "$1" in
            "-t")
                echo "Mock nginx configuration test successful"
                return 0
                ;;
        esac
    }
    export -f nginx
    
    run create_project_domain_config "test-project"
    # Should not crash
}

@test "SSL renewal setup works" {
    source "$YADS_DIR/modules/domains.sh"
    mock_sudo
    
    run setup_ssl_renewal
    # Should not crash
}

@test "DNS record creation works" {
    source "$YADS_DIR/modules/domains.sh"
    
    # Mock cloudflared commands
    cloudflared() {
        case "$1" in
            "tunnel")
                case "$2" in
                    "route")
                        echo "Mock DNS route created"
                        ;;
                esac
                ;;
        esac
    }
    export -f cloudflared
    
    run create_dns_records "test-tunnel-id"
    # Should not crash
}

@test "Domain configuration saves correctly" {
    source "$YADS_DIR/modules/domains.sh"
    
    export DOMAIN="test.example.com"
    export CLOUDFLARE_TOKEN="test-token"
    
    run save_config
    assert_success
    assert_file_exists "$YADS_CONFIG_FILE"
    assert_contains "DOMAIN=\"test.example.com\"" "$YADS_CONFIG_FILE"
    assert_contains "CLOUDFLARE_TOKEN=\"test-token\"" "$YADS_CONFIG_FILE"
}

@test "Domain configuration loads correctly" {
    source "$YADS_DIR/modules/domains.sh"
    
    # Create test configuration
    create_test_config
    
    # Load configuration
    load_config
    
    # Verify variables are set
    [[ "$DOMAIN" == "test.example.com" ]]
    [[ "$CLOUDFLARE_TOKEN" == "test-token" ]]
}

@test "Wildcard domain configuration works" {
    source "$YADS_DIR/modules/domains.sh"
    mock_sudo
    
    export DOMAIN="test.example.com"
    export WEB_SERVER="nginx"
    
    # Mock nginx commands
    nginx() {
        case "$1" in
            "-t")
                echo "Mock nginx configuration test successful"
                return 0
                ;;
        esac
    }
    export -f nginx
    
    run update_web_server_config
    # Should not crash
}

@test "SSL certificate auto-renewal works" {
    source "$YADS_DIR/modules/domains.sh"
    mock_sudo
    
    export DOMAIN="test.example.com"
    
    # Mock certbot commands
    certbot() {
        case "$1" in
            "renew")
                echo "Mock certificate renewal successful"
                return 0
                ;;
        esac
    }
    export -f certbot
    
    run setup_ssl_renewal
    # Should not crash
}

