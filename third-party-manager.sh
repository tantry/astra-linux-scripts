#!/bin/bash
# ~/third-party-manager.sh
# Third-Party Software Manager for Astra Linux SE 1.8
# Original workflow: search → install directly (no extra menu)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to check and populate cache if needed
check_and_populate_cache() {
    if ls /var/lib/apt/lists/*deb.debian.org* 2>/dev/null | grep -q "InRelease"; then
        echo -e "${GREEN}✓ APT cache already populated.${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ APT cache not found. Populating now (first run only)...${NC}"
        echo -e "${YELLOW}  This may take a few minutes. Future runs will be faster.${NC}"
        
        if [ ! -f /opt/apt-sources-backup/debian-bookworm.list ]; then
            echo -e "${RED}✗ Error: Repository files not found in /opt/apt-sources-backup/${NC}"
            echo -e "${YELLOW}  Please run the setup steps in Part Two of the blog post first.${NC}"
            return 1
        fi
        
        echo -e "${YELLOW}  → Copying repository files...${NC}"
        sudo cp /opt/apt-sources-backup/debian-bookworm.list /etc/apt/sources.list.d/ 2>/dev/null
        sudo cp /opt/apt-sources-backup/google-chrome.sources /etc/apt/sources.list.d/ 2>/dev/null
        
        echo -e "${YELLOW}  → Downloading package metadata...${NC}"
        sudo apt update
        
        echo -e "${YELLOW}  → Cleaning up...${NC}"
        sudo rm -f /etc/apt/sources.list.d/debian-bookworm.list
        sudo rm -f /etc/apt/sources.list.d/google-chrome.sources
        
        echo -e "${GREEN}✓ APT cache populated successfully.${NC}"
        return 0
    fi
}

# Function to clear the cache
clear_cache() {
    echo -e "${YELLOW}Clearing third-party APT cache...${NC}"
    CACHE_COUNT=$(ls /var/lib/apt/lists/*deb.debian.org* 2>/dev/null | wc -l)
    
    if [ "$CACHE_COUNT" -eq 0 ]; then
        echo -e "${GREEN}✓ No third-party cache files found. Nothing to clear.${NC}"
        return
    fi
    
    echo -e "${YELLOW}  → Removing $CACHE_COUNT cache files...${NC}"
    sudo rm -f /var/lib/apt/lists/*deb.debian.org* 2>/dev/null
    sudo rm -f /var/lib/apt/lists/dl.google.com* 2>/dev/null
    
    echo -e "${GREEN}✓ Third-party cache cleared. The cache will be rebuilt automatically when needed.${NC}"
}

# Main operations
enable_repos() {
    echo -e "${YELLOW}Enabling third-party repositories...${NC}"
    sudo cp /opt/apt-sources-backup/debian-bookworm.list /etc/apt/sources.list.d/ 2>/dev/null
    sudo cp /opt/apt-sources-backup/google-chrome.sources /etc/apt/sources.list.d/ 2>/dev/null
    sudo apt update -qq
    echo -e "${GREEN}✓ Third-party repositories enabled${NC}"
}

disable_repos() {
    echo -e "${YELLOW}Disabling third-party repositories...${NC}"
    sudo rm -f /etc/apt/sources.list.d/debian-bookworm.list
    sudo rm -f /etc/apt/sources.list.d/google-chrome.sources
    echo -e "${GREEN}✓ Third-party repositories disabled${NC}"
}

# Ensure clean start
disable_repos

# Check and populate cache automatically
check_and_populate_cache

# Main menu
while true; do
    echo ""
    echo "========================================"
    echo "   Third-Party Software Manager"
    echo "========================================"
    echo "1) Update all third-party software"
    echo "2) Install new third-party software"
    echo "3) Search for software"
    echo "4) Update specific package"
    echo "5) List installed third-party packages"
    echo "6) Clear third-party cache (optional)"
    echo "7) Exit"
    echo ""
    read -p "Select option [1-7]: " option

    case $option in
        1)
            enable_repos
            echo -e "${BLUE}Checking for updates...${NC}"
            apt list --upgradable 2>/dev/null | head -20
            read -p "Proceed with upgrade? (y/n): " confirm
            if [[ $confirm == "y" || $confirm == "Y" ]]; then
                sudo apt upgrade --only-upgrade -y
                echo -e "${GREEN}✓ Update complete!${NC}"
            else
                echo -e "${YELLOW}Update cancelled${NC}"
            fi
            disable_repos
            ;;
        2)
            enable_repos
            read -p "Search for package: " search
            echo -e "${BLUE}Search results:${NC}"
            apt search "$search" 2>/dev/null | head -25
            echo ""
            read -p "Exact package name to install (or Enter to skip): " pkg
            if [[ -n "$pkg" ]]; then
                read -p "Install $pkg? (y/n): " confirm
                if [[ $confirm == "y" || $confirm == "Y" ]]; then
                    sudo apt install "$pkg" -y
                    echo -e "${GREEN}✓ Installation complete!${NC}"
                fi
            fi
            disable_repos
            ;;
        3)
            enable_repos
            read -p "Search term: " term
            echo -e "${BLUE}Search results:${NC}"
            apt search "$term" 2>/dev/null | grep -v "Listing..."
            disable_repos
            read -p "Press Enter to continue..."
            ;;
        4)
            enable_repos
            echo -e "${BLUE}Upgradable packages:${NC}"
            apt list --upgradable 2>/dev/null | grep -v "Listing..."
            echo ""
            read -p "Package name to update: " pkg
            if [[ -n "$pkg" ]]; then
                read -p "Update $pkg? (y/n): " confirm
                if [[ $confirm == "y" || $confirm == "Y" ]]; then
                    sudo apt install --only-upgrade "$pkg" -y
                    echo -e "${GREEN}✓ Update complete!${NC}"
                fi
            fi
            disable_repos
            ;;
        5)
            enable_repos
            echo -e "${BLUE}Installed third-party packages:${NC}"
            apt list --installed 2>/dev/null | grep -E "bookworm|google-chrome|debian" | grep -v "Listing..."
            disable_repos
            read -p "Press Enter to continue..."
            ;;
        6)
            clear_cache
            ;;
        7)
            echo -e "${GREEN}Exiting. Third-party repositories disabled.${NC}"
            disable_repos
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
done
