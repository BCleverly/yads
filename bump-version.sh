#!/bin/bash

# YADS Version Bump Script
# This script bumps the version number and creates a git tag

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get current version
get_current_version() {
    # Get the latest tag
    local latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    echo "${latest_tag#v}"  # Remove 'v' prefix
}

# Bump version
bump_version() {
    local current_version="$1"
    local bump_type="${2:-patch}"
    
    # Split version into parts
    IFS='.' read -r major minor patch <<< "$current_version"
    
    case "$bump_type" in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch"|*)
            patch=$((patch + 1))
            ;;
    esac
    
    echo "$major.$minor.$patch"
}

# Main function
main() {
    local bump_type="${1:-patch}"
    
    # Validate bump type
    if [[ ! "$bump_type" =~ ^(major|minor|patch)$ ]]; then
        echo -e "${RED}Error: Invalid bump type. Use: major, minor, or patch${NC}"
        echo "Usage: $0 [major|minor|patch]"
        exit 1
    fi
    
    # Get current version
    local current_version=$(get_current_version)
    local new_version=$(bump_version "$current_version" "$bump_type")
    
    echo -e "${BLUE}Bumping YADS version...${NC}"
    echo -e "Current version: ${YELLOW}v$current_version${NC}"
    echo -e "New version: ${GREEN}v$new_version${NC}"
    echo
    
    # Update version in yads script (if it has a hardcoded version)
    if grep -q "echo \"1.0.0\"" yads; then
        sed -i "s/echo \"1.0.0\"/echo \"$new_version\"/" yads
    fi
    
    # Create version file for fallback (Git tags are primary)
    echo "$new_version" > version
    
    # Add files to git
    git add version yads
    
    # Create commit
    git commit -m "Bump version to v$new_version"
    
    # Create tag
    git tag -a "v$new_version" -m "Release v$new_version"
    
    echo -e "${GREEN}✓ Version bumped to v$new_version${NC}"
    echo -e "${BLUE}Next steps:${NC}"
    echo "  git push origin master"
    echo "  git push origin v$new_version"
    echo
    echo -e "${YELLOW}Note: Run the push commands above to make the new version available for upgrades${NC}"
}

# Run main function
main "$@"
