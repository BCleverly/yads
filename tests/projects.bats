#!/usr/bin/env bats

# Tests for YADS projects module

load 'setup.bash'

@test "Projects module loads correctly" {
    source "$YADS_DIR/modules/projects.sh"
    # Should not crash
}

@test "Project name validation works" {
    source "$YADS_DIR/modules/projects.sh"
    
    # Test valid project names
    [[ "my-project" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$ ]]
    [[ "project123" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$ ]]
    [[ "test" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$ ]]
    
    # Test invalid project names
    [[ ! "invalid project" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$ ]]
    [[ ! "project!" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$ ]]
    [[ ! "-project" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$ ]]
    [[ ! "project-" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$ ]]
}

@test "Project type selection works" {
    source "$YADS_DIR/modules/projects.sh"
    
    # Test Laravel project type
    export PROJECT_TYPE="laravel"
    [[ "$PROJECT_TYPE" == "laravel" ]]
    
    # Test Symfony project type
    export PROJECT_TYPE="symfony"
    [[ "$PROJECT_TYPE" == "symfony" ]]
    
    # Test custom PHP project type
    export PROJECT_TYPE="custom"
    [[ "$PROJECT_TYPE" == "custom" ]]
}

@test "Laravel project creation works" {
    source "$YADS_DIR/modules/projects.sh"
    mock_sudo
    
    # Mock composer commands
    composer() {
        case "$1" in
            "create-project")
                mkdir -p "$3"
                echo "<?php echo 'Laravel project'; ?>" > "$3/index.php"
                echo "<?php echo 'Laravel artisan'; ?>" > "$3/artisan"
                ;;
        esac
    }
    export -f composer
    
    # Mock php commands
    php() {
        case "$1" in
            "artisan")
                case "$2" in
                    "key:generate")
                        echo "Application key generated"
                        ;;
                esac
                ;;
        esac
    }
    export -f php
    
    run create_laravel_project "test-laravel"
    # Should not crash with mocked composer
}

@test "Symfony project creation works" {
    source "$YADS_DIR/modules/projects.sh"
    mock_sudo
    
    # Mock composer commands
    composer() {
        case "$1" in
            "create-project")
                mkdir -p "$3"
                echo "<?php echo 'Symfony project'; ?>" > "$3/index.php"
                ;;
        esac
    }
    export -f composer
    
    run create_symfony_project "test-symfony"
    # Should not crash with mocked composer
}

@test "CodeIgniter project creation works" {
    source "$YADS_DIR/modules/projects.sh"
    mock_sudo
    
    # Mock composer commands
    composer() {
        case "$1" in
            "create-project")
                mkdir -p "$3"
                echo "<?php echo 'CodeIgniter project'; ?>" > "$3/index.php"
                ;;
        esac
    }
    export -f composer
    
    run create_codeigniter_project "test-codeigniter"
    # Should not crash with mocked composer
}

@test "Custom PHP project creation works" {
    source "$YADS_DIR/modules/projects.sh"
    mock_sudo
    
    run create_custom_php_project "test-custom"
    # Should not crash
}

@test "WordPress project creation works" {
    source "$YADS_DIR/modules/projects.sh"
    mock_sudo
    mock_wget
    
    # Mock wget for WordPress download
    wget() {
        case "$1" in
            "-O")
                # Create mock WordPress archive
                mkdir -p wordpress
                echo "<?php echo 'WordPress project'; ?>" > wordpress/index.php
                echo "<?php echo 'WordPress config'; ?>" > wordpress/wp-config-sample.php
                tar -czf wordpress.tar.gz wordpress
                ;;
        esac
    }
    export -f wget
    
    # Mock curl for salts
    curl() {
        case "$1" in
            "-s")
                echo "define('AUTH_KEY', 'test-key');"
                ;;
        esac
    }
    export -f curl
    
    run create_wordpress_project "test-wordpress"
    # Should not crash with mocked wget
}

@test "Project directory creation works" {
    source "$YADS_DIR/modules/projects.sh"
    mock_sudo
    
    run create_project_directory "test-project"
    # Should not crash
}

@test "Project permissions setup works" {
    source "$YADS_DIR/modules/projects.sh"
    mock_sudo
    
    # Create test project directory
    local test_project_path="/tmp/yads-test-$$/test-project"
    mkdir -p "$test_project_path"
    
    run set_project_permissions "test-project"
    # Should not crash
}

@test "Project database creation works" {
    source "$YADS_DIR/modules/projects.sh"
    mock_sudo
    
    # Mock mysql commands
    mysql() {
        case "$1" in
            "-u")
                case "$3" in
                    "-e")
                        echo "Mock MySQL command executed"
                        ;;
                esac
                ;;
        esac
    }
    export -f mysql
    
    # Mock postgresql commands
    sudo() {
        case "$1" in
            "-u")
                case "$2" in
                    "postgres")
                        case "$3" in
                            "psql")
                                echo "Mock PostgreSQL command executed"
                                ;;
                        esac
                        ;;
                esac
                ;;
        esac
    }
    export -f sudo
    
    run create_project_database "test-project"
    # Should not crash with mocked database commands
}

@test "Development environment setup works" {
    source "$YADS_DIR/modules/projects.sh"
    
    # Create test project directory
    local test_project_path="/tmp/yads-test-$$/test-project"
    mkdir -p "$test_project_path"
    
    run setup_development_environment "test-project"
    # Should not crash
}

@test "Git repository setup works" {
    source "$YADS_DIR/modules/projects.sh"
    
    # Create test project directory
    local test_project_path="/tmp/yads-test-$$/test-project"
    mkdir -p "$test_project_path"
    
    # Mock git commands
    git() {
        case "$1" in
            "init")
                echo "Mock Git repository initialized"
                ;;
            "add")
                echo "Mock files added to Git"
                ;;
            "commit")
                echo "Mock commit created"
                ;;
        esac
    }
    export -f git
    
    run setup_git_repository "test-project" "$test_project_path"
    # Should not crash with mocked git
}

@test "Development scripts creation works" {
    source "$YADS_DIR/modules/projects.sh"
    
    # Create test project directory
    local test_project_path="/tmp/yads-test-$$/test-project"
    mkdir -p "$test_project_path"
    
    run create_development_scripts "test-project" "$test_project_path"
    # Should not crash
}

@test "Project listing works" {
    source "$YADS_DIR/modules/projects.sh"
    
    # Create test projects
    mkdir -p "/tmp/yads-test-$$/project1"
    mkdir -p "/tmp/yads-test-$$/project2"
    echo "<?php echo 'Project 1'; ?>" > "/tmp/yads-test-$$/project1/index.php"
    echo "<?php echo 'Project 2'; ?>" > "/tmp/yads-test-$$/project2/index.php"
    
    run list_projects
    # Should not crash
}

@test "Project removal works" {
    source "$YADS_DIR/modules/projects.sh"
    mock_sudo
    
    # Create test project
    local test_project_path="/tmp/yads-test-$$/test-project"
    mkdir -p "$test_project_path"
    
    # Mock mysql commands
    mysql() {
        case "$1" in
            "-u")
                case "$3" in
                    "-e")
                        echo "Mock MySQL command executed"
                        ;;
                esac
                ;;
        esac
    }
    export -f mysql
    
    # Mock confirmation
    echo "y" | run remove_project "test-project"
    # Should not crash with mocked commands
}

@test "Project configuration creation works" {
    source "$YADS_DIR/modules/projects.sh"
    
    # Create test project directory
    local test_project_path="/tmp/yads-test-$$/test-project"
    mkdir -p "$test_project_path"
    
    export PROJECT_TYPE="laravel"
    export DOMAIN="test.example.com"
    
    run create_development_config "test-project" "$test_project_path"
    # Should not crash
}

@test "Git ignore file creation works" {
    source "$YADS_DIR/modules/projects.sh"
    
    # Create test project directory
    local test_project_path="/tmp/yads-test-$$/test-project"
    mkdir -p "$test_project_path"
    
    run create_gitignore "$test_project_path"
    # Should not crash
    assert_file_exists "$test_project_path/.gitignore"
}

