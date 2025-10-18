# YADS Makefile
# Provides easy commands for development and testing

.PHONY: help install test test-all test-ubuntu test-debian test-integration test-security test-performance clean install-bats

# Default target
help:
	@echo "YADS - Yet Another Development Server"
	@echo ""
	@echo "Available targets:"
	@echo "  install          Install YADS"
	@echo "  test             Run all tests"
	@echo "  test-all         Run all tests with reports"
	@echo "  test-ubuntu      Run Ubuntu-specific tests"
	@echo "  test-debian      Run Debian-specific tests"
	@echo "  test-integration Run integration tests"
	@echo "  test-security    Run security tests"
	@echo "  test-performance Run performance tests"
	@echo "  install-bats     Install Bats testing framework"
	@echo "  clean            Clean up test artifacts"
	@echo "  lint             Run linting checks"
	@echo "  format           Format code"
	@echo "  docs             Generate documentation"

# Install YADS
install:
	@echo "Installing YADS..."
	@chmod +x yads
	@chmod +x modules/*.sh
	@chmod +x install.sh
	@echo "YADS installed successfully!"

# Install Bats testing framework
install-bats:
	@echo "Installing Bats testing framework..."
	@if command -v npm >/dev/null 2>&1; then \
		npm install -g bats; \
	elif command -v brew >/dev/null 2>&1; then \
		brew install bats-core; \
	elif command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y bats; \
	elif command -v yum >/dev/null 2>&1; then \
		sudo yum install -y bats; \
	elif command -v dnf >/dev/null 2>&1; then \
		sudo dnf install -y bats; \
	elif command -v pacman >/dev/null 2>&1; then \
		sudo pacman -S --noconfirm bats-core; \
	else \
		echo "Could not install Bats automatically. Please install it manually."; \
		echo "Visit: https://github.com/bats-core/bats-core"; \
		exit 1; \
	fi
	@echo "Bats installed successfully!"

# Run all tests
test: install-bats
	@echo "Running all YADS tests..."
	@cd tests && ./run-tests.sh --all

# Run all tests with detailed reports
test-all: install-bats
	@echo "Running all YADS tests with detailed reports..."
	@cd tests && ./run-tests.sh --all --verbose

# Run Ubuntu-specific tests
test-ubuntu: install-bats
	@echo "Running Ubuntu-specific tests..."
	@cd tests && ./run-tests.sh debian-ubuntu.bats

# Run Debian-specific tests
test-debian: install-bats
	@echo "Running Debian-specific tests..."
	@cd tests && ./run-tests.sh debian-ubuntu.bats

# Run integration tests
test-integration: install-bats
	@echo "Running integration tests..."
	@cd tests && ./run-tests.sh yads.bats install.bats

# Run security tests
test-security:
	@echo "Running security tests..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck yads modules/*.sh tests/*.sh install.sh; \
	else \
		echo "ShellCheck not installed. Installing..."; \
		sudo apt-get update && sudo apt-get install -y shellcheck; \
		shellcheck yads modules/*.sh tests/*.sh install.sh; \
	fi

# Run performance tests
test-performance: install-bats
	@echo "Running performance tests..."
	@cd tests && ./run-tests.sh --all
	@echo "Performance test completed!"

# Clean up test artifacts
clean:
	@echo "Cleaning up test artifacts..."
	@rm -rf tests/reports/*
	@rm -rf /tmp/yads-test-*
	@rm -rf ~/.yads.backup.*
	@echo "Cleanup completed!"

# Run linting checks
lint:
	@echo "Running linting checks..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck yads modules/*.sh tests/*.sh install.sh; \
	else \
		echo "ShellCheck not installed. Installing..."; \
		sudo apt-get update && sudo apt-get install -y shellcheck; \
		shellcheck yads modules/*.sh tests/*.sh install.sh; \
	fi
	@echo "Linting completed!"

# Format code
format:
	@echo "Formatting code..."
	@if command -v shfmt >/dev/null 2>&1; then \
		shfmt -i 4 -w yads modules/*.sh tests/*.sh install.sh; \
	else \
		echo "shfmt not installed. Installing..."; \
		go install mvdan.cc/sh/v3/cmd/shfmt@latest; \
		shfmt -i 4 -w yads modules/*.sh tests/*.sh install.sh; \
	fi
	@echo "Code formatting completed!"

# Generate documentation
docs:
	@echo "Generating documentation..."
	@if command -v pandoc >/dev/null 2>&1; then \
		pandoc README.md -o README.html; \
	else \
		echo "Pandoc not installed. Installing..."; \
		sudo apt-get update && sudo apt-get install -y pandoc; \
		pandoc README.md -o README.html; \
	fi
	@echo "Documentation generated!"

# Development setup
dev-setup: install-bats
	@echo "Setting up development environment..."
	@chmod +x yads modules/*.sh tests/*.sh install.sh
	@mkdir -p tests/reports
	@echo "Development environment ready!"

# Quick test (fastest)
quick-test: install-bats
	@echo "Running quick tests..."
	@cd tests && ./run-tests.sh yads.bats

# Full test suite
full-test: install-bats
	@echo "Running full test suite..."
	@cd tests && ./run-tests.sh --all --coverage

# Test specific functionality
test-help:
	@echo "Testing help functionality..."
	@./yads help
	@./yads --help

test-status:
	@echo "Testing status functionality..."
	@./yads status

test-create:
	@echo "Testing project creation..."
	@./yads create test-project || true

# CI/CD helpers
ci-test: install-bats
	@echo "Running CI tests..."
	@cd tests && ./run-tests.sh --all
	@echo "CI tests completed!"

ci-security:
	@echo "Running CI security tests..."
	@shellcheck yads modules/*.sh tests/*.sh install.sh
	@echo "CI security tests completed!"

ci-performance:
	@echo "Running CI performance tests..."
	@time ./yads help
	@time ./yads status
	@echo "CI performance tests completed!"

# Docker testing
docker-test:
	@echo "Running tests in Docker..."
	@docker run --rm -v "$(pwd):/yads" -w /yads ubuntu:22.04 bash -c "apt-get update && apt-get install -y bats && cd tests && ./run-tests.sh --all"

# Show test results
show-results:
	@echo "Showing latest test results..."
	@cd tests && ./run-tests.sh --report

# List available tests
list-tests:
	@echo "Available test files:"
	@cd tests && ./run-tests.sh --list

# Run tests with verbose output
verbose-test: install-bats
	@echo "Running tests with verbose output..."
	@cd tests && ./run-tests.sh --all --verbose

# Test coverage
coverage: install-bats
	@echo "Running tests with coverage..."
	@cd tests && ./run-tests.sh --coverage

# Benchmark tests
benchmark: install-bats
	@echo "Running benchmark tests..."
	@cd tests && ./run-tests.sh --all
	@echo "Benchmark completed!"

# All-in-one test
all: install test-all test-security test-performance
	@echo "All tests completed!"

# Default target
.DEFAULT_GOAL := help

