# YADS Test Environment Dockerfile
# Ubuntu 24.04 LTS with YADS development server

FROM ubuntu:24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    sudo \
    systemd \
    systemd-sysv \
    dbus \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for testing
RUN useradd -m -s /bin/bash yadsuser && \
    echo "yadsuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up systemd (required for services)
RUN systemctl set-default multi-user.target

# Copy YADS repository
COPY . /home/yadsuser/yads
WORKDIR /home/yadsuser/yads

# Fix line endings and make scripts executable
RUN find . -name "*.sh" -o -name "yads" | xargs dos2unix 2>/dev/null || true && \
    chmod +x *.sh && \
    chmod +x modules/*.sh && \
    chmod +x tests/unit/*.bats 2>/dev/null || true

# Set up local development environment
RUN ./local-setup.sh

# Create a test script
RUN cat > /home/yadsuser/test-yads.sh << 'EOF'
#!/bin/bash

echo "🧪 YADS Docker Test Environment"
echo "================================"
echo

# Test basic YADS functionality
echo "Testing YADS commands:"
echo "1. yads --version"
yads --version
echo

echo "2. yads help"
yads help
echo

echo "3. yads status"
yads status
echo

echo "4. Testing update functionality"
yads update
echo

echo "5. Testing service detection"
yads status
echo

echo "✅ YADS test completed!"
echo
echo "To run the full installation:"
echo "  sudo ./install.sh"
echo
echo "To test specific components:"
echo "  yads php 8.4"
echo "  yads server nginx"
echo "  yads database mysql"
echo
EOF

RUN chmod +x /home/yadsuser/test-yads.sh

# Switch to non-root user
USER yadsuser

# Set up environment
ENV PATH="/home/yadsuser/.local/bin:$PATH"
ENV HOME="/home/yadsuser"

# Expose ports for services
EXPOSE 80 443 8080 3306 5432 6379

# Create entrypoint script
RUN cat > /home/yadsuser/entrypoint.sh << 'EOF'
#!/bin/bash

echo "🐳 YADS Docker Container Started"
echo "================================="
echo
echo "Container Information:"
echo "  OS: $(lsb_release -d | cut -f2)"
echo "  User: $(whoami)"
echo "  Home: $HOME"
echo "  Working Directory: $(pwd)"
echo
echo "YADS Status:"
yads status
echo
echo "Available Commands:"
echo "  ./test-yads.sh     - Run YADS tests"
echo "  sudo ./install.sh  - Install YADS system-wide"
echo "  yads help          - Show YADS help"
echo "  yads status         - Check YADS status"
echo
echo "To start interactive shell:"
echo "  docker exec -it <container_name> bash"
echo
echo "To run tests:"
echo "  docker exec -it <container_name> ./test-yads.sh"
echo

# Keep container running
tail -f /dev/null
EOF

RUN chmod +x /home/yadsuser/entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/home/yadsuser/entrypoint.sh"]
