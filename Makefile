# YADS Makefile
# Development and testing utilities

.PHONY: help install test clean lint format

# Default target
help:
	@echo "YADS - Yet Another Development Server"
	@echo "====================================="
	@echo ""
	@echo "Available targets:"
	@echo "  install     - Install YADS locally"
	@echo "  test        - Run all tests"
	@echo "  test-unit   - Run unit tests"
	@echo "  test-integration - Run integration tests"
	@echo "  clean       - Clean up test artifacts"
	@echo "  lint        - Run shellcheck on scripts"
	@echo "  format      - Format shell scripts"
	@echo "  help        - Show this help message"
	@echo ""

# Install YADS locally
install:
	@echo "Installing YADS locally..."
	chmod +x yads install.sh manual-uninstall.sh
	chmod +x modules/*.sh
	@echo "✅ YADS installed locally"

# Run all tests
test: test-unit test-integration
	@echo "✅ All tests completed"

# Run unit tests
test-unit:
	@echo "Running unit tests..."
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/unit/; \
	else \
		echo "⚠️  Bats not installed, skipping unit tests"; \
	fi

# Run integration tests
test-integration:
	@echo "Running integration tests..."
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/integration/; \
	else \
		echo "⚠️  Bats not installed, skipping integration tests"; \
	fi

# Clean up test artifacts
clean:
	@echo "Cleaning up test artifacts..."
	rm -rf /tmp/yads-test-*
	rm -rf /tmp/yads-backup-*
	@echo "✅ Cleanup completed"

# Run shellcheck on scripts
lint:
	@echo "Running shellcheck..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck yads install.sh manual-uninstall.sh; \
		shellcheck modules/*.sh; \
		echo "✅ Shellcheck completed"; \
	else \
		echo "⚠️  Shellcheck not installed, skipping linting"; \
	fi

# Format shell scripts
format:
	@echo "Formatting shell scripts..."
	@if command -v shfmt >/dev/null 2>&1; then \
		shfmt -w -i 4 -ci yads install.sh manual-uninstall.sh; \
		shfmt -w -i 4 -ci modules/*.sh; \
		echo "✅ Formatting completed"; \
	else \
		echo "⚠️  shfmt not installed, skipping formatting"; \
	fi

# Install development dependencies
dev-deps:
	@echo "Installing development dependencies..."
	@if command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y bats shellcheck shfmt; \
	elif command -v dnf >/dev/null 2>&1; then \
		sudo dnf install -y bats ShellCheck shfmt; \
	elif command -v yum >/dev/null 2>&1; then \
		sudo yum install -y bats ShellCheck; \
	elif command -v pacman >/dev/null 2>&1; then \
		sudo pacman -S --noconfirm bats shellcheck shfmt; \
	else \
		echo "⚠️  Package manager not supported for dev dependencies"; \
	fi

# Create test environment
test-env:
	@echo "Creating test environment..."
	@mkdir -p tests/unit tests/integration
	@echo "✅ Test environment created"

# Run specific test file
test-file:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make test-file FILE=tests/unit/test.bats"; \
		exit 1; \
	fi
	@if command -v bats >/dev/null 2>&1; then \
		bats "$(FILE)"; \
	else \
		echo "⚠️  Bats not installed"; \
	fi

# Show version
version:
	@echo "YADS version: $$(cat version)"

# Show system info
info:
	@echo "System Information:"
	@echo "OS: $$(uname -s)"
	@echo "Architecture: $$(uname -m)"
	@echo "Shell: $$(basename $$SHELL)"
	@echo "User: $$(whoami)"
	@echo "Home: $$HOME"
