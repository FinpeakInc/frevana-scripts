#!/bin/bash

# Xcode Command Line Tools Setup Script for macOS
# Prepares development environment for Frevana MCP plugins

set -e  # Exit on any error

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        error "This script only supports macOS systems"
        exit 1
    fi
    success "Detected macOS system"
}

# Check and install Xcode Command Line Tools
install_xcode_tools() {
    log "Checking Xcode Command Line Tools..."
    
    if ! xcode-select -p &> /dev/null; then
        log "Installing Xcode Command Line Tools..."
        xcode-select --install
        
        echo "Please complete the Xcode Command Line Tools installation in the popup window"
        echo "Installation will continue automatically once completed..."
        
        # Wait for installation to complete with timeout
        local timeout=1800  # 30 minutes in seconds
        local elapsed=0
        local check_interval=5
        
        while ! xcode-select -p &> /dev/null; do
            if [ $elapsed -ge $timeout ]; then
                error "Xcode Command Line Tools installation timed out after 30 minutes"
                echo "This could happen if:"
                echo "• The installation dialog was cancelled or dismissed"
                echo "• Network connection is slow or interrupted"
                echo "• System is busy with other tasks"
                echo
                echo "Please try one of these solutions:"
                echo "1. Run this script again"
                echo "2. Manually install: xcode-select --install"
                echo "3. Install Xcode from the App Store"
                exit 1
            fi
            
            sleep $check_interval
            elapsed=$((elapsed + check_interval))
            
            # Show progress every minute
            if [ $((elapsed % 60)) -eq 0 ] && [ $elapsed -gt 0 ]; then
                local minutes=$((elapsed / 60))
                log "Still waiting for installation... ($minutes minutes elapsed)"
            fi
        done
        
        success "Xcode Command Line Tools installation completed"
    else
        success "Xcode Command Line Tools already installed"
    fi
}

# Print completion summary
print_summary() {
    echo
    echo "=================================================="
    echo -e "${GREEN}🎉 System Environment Ready!${NC}"
    echo "=================================================="
    echo
    echo "✅ Xcode Command Line Tools installed"
    echo "=================================================="
}

# Main function
main() {
    echo "=================================================="
    echo "🔧 Frevana System Environment Setup"
    echo "=================================================="
    echo "Preparing development tools for MCP plugins..."
    echo
    
    # Run installation steps
    check_macos
    install_xcode_tools
    print_summary
}

# Run main function
main "$@"