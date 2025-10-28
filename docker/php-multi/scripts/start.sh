#!/bin/bash

# YADS PHP Multi-Container Startup Script
# Handles multiple services in a single container

set -euo pipefail

# Create necessary directories
mkdir -p /var/log/supervisor
mkdir -p /var/run/supervisor

# Start supervisor
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
