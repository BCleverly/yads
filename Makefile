# YADS Docker Makefile
# Docker-based development environment management

.PHONY: help setup start stop restart status logs clean build pull update

# Default target
help:
	@echo "YADS Docker - Container Management"
	@echo "=================================="
	@echo ""
	@echo "Available targets:"
	@echo "  setup       - Setup YADS Docker environment"
	@echo "  start       - Start all YADS services"
	@echo "  stop        - Stop all YADS services"
	@echo "  restart     - Restart all YADS services"
	@echo "  status      - Show service status"
	@echo "  logs        - Show logs for all services"
	@echo "  clean       - Clean up containers and volumes"
	@echo "  build       - Build all containers"
	@echo "  pull        - Pull latest images"
	@echo "  update      - Update and restart services"
	@echo "  lint        - Run shellcheck on scripts"
	@echo "  help        - Show this help message"
	@echo ""

# Setup YADS Docker environment
setup:
	@echo "Setting up YADS Docker environment..."
	@chmod +x setup-docker.sh
	@./setup-docker.sh
	@echo "✅ YADS Docker setup completed"

# Start all services
start:
	@echo "Starting YADS services..."
	@./yads start
	@echo "✅ YADS services started"

# Stop all services
stop:
	@echo "Stopping YADS services..."
	@./yads stop
	@echo "✅ YADS services stopped"

# Restart all services
restart:
	@echo "Restarting YADS services..."
	@./yads restart
	@echo "✅ YADS services restarted"

# Show service status
status:
	@./yads status

# Show logs for all services
logs:
	@./yads logs

# Clean up containers and volumes
clean:
	@echo "Cleaning up YADS Docker environment..."
	@docker-compose down -v
	@docker system prune -f
	@echo "✅ Cleanup completed"

# Build all containers
build:
	@echo "Building YADS containers..."
	@docker-compose build
	@echo "✅ Containers built"

# Pull latest images
pull:
	@echo "Pulling latest images..."
	@docker-compose pull
	@echo "✅ Images pulled"

# Update and restart services
update:
	@echo "Updating YADS services..."
	@./yads update
	@echo "✅ Services updated"

# Run shellcheck on scripts
lint:
	@echo "Running shellcheck..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck yads setup-docker.sh; \
		shellcheck scripts/*.sh; \
		echo "✅ Shellcheck completed"; \
	else \
		echo "⚠️  Shellcheck not installed, skipping linting"; \
	fi

# Format shell scripts
format:
	@echo "Formatting shell scripts..."
	@if command -v shfmt >/dev/null 2>&1; then \
		shfmt -w -i 4 -ci yads setup-docker.sh; \
		shfmt -w -i 4 -ci scripts/*.sh; \
		echo "✅ Formatting completed"; \
	else \
		echo "⚠️  shfmt not installed, skipping formatting"; \
	fi

# Install development dependencies
dev-deps:
	@echo "Installing development dependencies..."
	@if command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y shellcheck shfmt; \
	elif command -v dnf >/dev/null 2>&1; then \
		sudo dnf install -y ShellCheck shfmt; \
	elif command -v yum >/dev/null 2>&1; then \
		sudo yum install -y ShellCheck; \
	elif command -v pacman >/dev/null 2>&1; then \
		sudo pacman -S --noconfirm shellcheck shfmt; \
	else \
		echo "⚠️  Package manager not supported for dev dependencies"; \
	fi

# Show version
version:
	@echo "YADS Docker version: $$(cat version)"

# Show system info
info:
	@echo "System Information:"
	@echo "OS: $$(uname -s)"
	@echo "Architecture: $$(uname -m)"
	@echo "Shell: $$(basename $$SHELL)"
	@echo "User: $$(whoami)"
	@echo "Home: $$HOME"
	@echo "Docker: $$(docker --version)"
	@echo "Docker Compose: $$(docker-compose --version)"
