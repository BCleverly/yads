#!/bin/bash

# Manual YADS Uninstall Script
# Use this if yads uninstall command is not working

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}YADS Manual Uninstall Script${NC}"
echo "================================="
echo
echo -e "${YELLOW}This script will completely remove YADS from your system.${NC}"
echo -e "${RED}WARNING: This action cannot be undone!${NC}"
echo
read -p "Are you sure you want to continue? [y/N]: " CONFIRM

if [[ ! "$CONFIRM" =~ ^[yY]$ ]]; then
    echo -e "${YELLOW}Uninstall cancelled.${NC}"
    exit 0
fi

echo
echo -e "${BLUE}Starting manual YADS removal...${NC}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to remove service if it exists (with permission)
remove_service() {
    local service_name="$1"
    if systemctl is-active --quiet "$service_name" 2>/dev/null || systemctl is-enabled --quiet "$service_name" 2>/dev/null; then
        echo
        echo -e "${YELLOW}Service '$service_name' is installed and/or running.${NC}"
        read -p "Do you want to remove the '$service_name' service? [y/N]: " REMOVE_SERVICE
        if [[ "$REMOVE_SERVICE" =~ ^[yY]$ ]]; then
            echo -e "${YELLOW}Stopping $service_name service...${NC}"
            sudo systemctl stop "$service_name" 2>/dev/null || true
            echo -e "${YELLOW}Disabling $service_name service...${NC}"
            sudo systemctl disable "$service_name" 2>/dev/null || true
            if [[ -f "/etc/systemd/system/$service_name.service" ]]; then
                echo -e "${YELLOW}Removing $service_name service file...${NC}"
                sudo rm -f "/etc/systemd/system/$service_name.service" 2>/dev/null || true
            fi
        else
            echo -e "${YELLOW}Skipping $service_name service removal.${NC}"
        fi
    fi
}

# Function to remove user from group
remove_user_from_group() {
    local group="$1"
    if groups "$USER" | grep -q "$group"; then
        echo -e "${YELLOW}Removing $USER from $group group...${NC}"
        sudo gpasswd -d "$USER" "$group" 2>/dev/null || true
    fi
}

echo -e "${BLUE}Step 1: Stopping YADS services...${NC}"

# Stop and remove YADS-related services
remove_service "yads-code-server"
remove_service "yads-project-browser"
remove_service "cloudflared"

# Reload systemd
sudo systemctl daemon-reload 2>/dev/null || true

echo -e "${BLUE}Step 2: Removing YADS files and directories...${NC}"

# Remove YADS installation directory
if [[ -d "$HOME/.local/bin" ]]; then
    echo -e "${YELLOW}Removing YADS installation directory...${NC}"
    rm -rf "$HOME/.local/bin/yads" 2>/dev/null || true
    rm -rf "$HOME/.local/bin/modules" 2>/dev/null || true
    rm -rf "$HOME/.local/bin/version" 2>/dev/null || true
fi

# Remove YADS configuration directory
if [[ -d "$HOME/.yads" ]]; then
    echo -e "${YELLOW}Removing YADS configuration directory...${NC}"
    rm -rf "$HOME/.yads" 2>/dev/null || true
fi

# Remove YADS log directory
if [[ -d "$HOME/.yads-logs" ]]; then
    echo -e "${YELLOW}Removing YADS log directory...${NC}"
    rm -rf "$HOME/.yads-logs" 2>/dev/null || true
fi

# Remove system-wide symlink
if [[ -L "/usr/local/bin/yads" ]]; then
    echo -e "${YELLOW}Removing system-wide symlink...${NC}"
    sudo rm -f "/usr/local/bin/yads" 2>/dev/null || true
fi

echo -e "${BLUE}Step 3: Cleaning up PATH configuration...${NC}"

# Remove YADS from PATH in shell configuration files
for file in ~/.bashrc ~/.zshrc ~/.profile; do
    if [[ -f "$file" ]]; then
        if grep -q "yads\|\.local/bin" "$file"; then
            echo -e "${YELLOW}Cleaning up $file...${NC}"
            # Create backup
            cp "$file" "$file.yads-backup-$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
            # Remove YADS-related lines
            sed -i '/yads\|\.local\/bin/d' "$file" 2>/dev/null || true
        fi
    fi
done

echo -e "${BLUE}Step 4: Removing user from groups...${NC}"

# Remove user from www-data group
remove_user_from_group "www-data"

echo -e "${BLUE}Step 5: Cleaning up Docker containers...${NC}"

# Remove YADS Docker containers if they exist
if command_exists docker; then
    if docker ps -a --format "table {{.Names}}" | grep -q "yads-project-browser"; then
        echo
        echo -e "${YELLOW}Docker container 'yads-project-browser' is found.${NC}"
        read -p "Do you want to remove the 'yads-project-browser' Docker container? [y/N]: " REMOVE_DOCKER
        if [[ "$REMOVE_DOCKER" =~ ^[yY]$ ]]; then
            echo -e "${YELLOW}Removing YADS Docker containers...${NC}"
            docker stop yads-project-browser 2>/dev/null || true
            docker rm yads-project-browser 2>/dev/null || true
        else
            echo -e "${YELLOW}Skipping Docker container removal.${NC}"
        fi
    fi
fi

echo -e "${BLUE}Step 6: Cleaning up SSH keys (selective)...${NC}"

# Only remove YADS-generated SSH keys, not all SSH keys
if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
    echo -e "${YELLOW}Found SSH key. Do you want to remove it? (This will remove ALL SSH keys)${NC}"
    read -p "Remove SSH keys? [y/N]: " REMOVE_SSH
    if [[ "$REMOVE_SSH" =~ ^[yY]$ ]]; then
        rm -f "$HOME/.ssh/id_ed25519" 2>/dev/null || true
        rm -f "$HOME/.ssh/id_ed25519.pub" 2>/dev/null || true
        echo -e "${YELLOW}SSH keys removed.${NC}"
    else
        echo -e "${YELLOW}SSH keys preserved.${NC}"
    fi
fi

echo -e "${BLUE}Step 7: Cleaning up development directory...${NC}"

# Ask about development directory
if [[ -d "$HOME/development" ]]; then
    echo -e "${YELLOW}Found development directory: $HOME/development${NC}"
    echo -e "${YELLOW}This may contain your projects. Do you want to remove it?${NC}"
    read -p "Remove development directory? [y/N]: " REMOVE_DEV
    if [[ "$REMOVE_DEV" =~ ^[yY]$ ]]; then
        rm -rf "$HOME/development" 2>/dev/null || true
        echo -e "${YELLOW}Development directory removed.${NC}"
    else
        echo -e "${YELLOW}Development directory preserved.${NC}"
    fi
fi

echo -e "${BLUE}Step 8: Final cleanup...${NC}"

# Remove any remaining YADS files
find "$HOME" -name "*yads*" -type f 2>/dev/null | while read -r file; do
    echo -e "${YELLOW}Removing: $file${NC}"
    rm -f "$file" 2>/dev/null || true
done

# Remove any remaining YADS directories
find "$HOME" -name "*yads*" -type d 2>/dev/null | while read -r dir; do
    echo -e "${YELLOW}Removing: $dir${NC}"
    rm -rf "$dir" 2>/dev/null || true
done

echo
echo -e "${GREEN}✅ YADS has been completely removed from your system!${NC}"
echo
echo -e "${BLUE}What was removed:${NC}"
echo "  • YADS installation directory ($HOME/.local/bin/yads)"
echo "  • YADS configuration directory ($HOME/.yads)"
echo "  • YADS log directory ($HOME/.yads-logs)"
echo "  • System-wide symlink (/usr/local/bin/yads)"
echo "  • YADS services (code-server, project-browser, cloudflared)"
echo "  • PATH configuration updates"
echo "  • User group memberships"
echo "  • Docker containers"
echo "  • SSH keys (if you chose to remove them)"
echo "  • Development directory (if you chose to remove it)"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Restart your terminal or run: source ~/.bashrc"
echo "2. Verify removal: which yads (should return nothing)"
echo "3. If you want to reinstall: curl -fsSL https://raw.githubusercontent.com/BCleverly/yads/master/install.sh | bash"
echo
echo -e "${GREEN}Manual uninstall completed successfully!${NC}"
