#!/bin/bash

# Xcode Command Line Tools Check Script
# Checks if Xcode Command Line Tools are installed and offers installation if missing

set -e

# Check if Xcode Command Line Tools are installed
check_xcode_tools() {
    if xcode-select -p &> /dev/null; then
        local xcode_path=$(xcode-select -p)
        echo "✅ Xcode Command Line Tools found at: $xcode_path"
        return 0
    else
        echo "❌ Xcode Command Line Tools not found"
        return 1
    fi
}

# Install Xcode Command Line Tools
install_xcode_tools() {
    echo "🔧 Installing Xcode Command Line Tools..."
    echo "📋 This will open a system dialog. Please follow the installation prompts."
    
    # Trigger the installation dialog
    if xcode-select --install 2>&1 | grep -q "already installed"; then
        echo "ℹ️  Xcode Command Line Tools are already installed"
        return 0
    fi
    
    echo "⏳ Waiting for Xcode Command Line Tools installation to complete..."
    echo "   A system dialog should have appeared. Please complete the installation."
    echo "   This script will continue automatically when installation is complete..."
    
    # Wait for installation to complete (check every 5 seconds)
    local timeout=300  # 5 minutes timeout
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        if xcode-select -p &> /dev/null; then
            echo "✅ Xcode Command Line Tools installation detected"
            return 0
        fi
        
        sleep 5
        elapsed=$((elapsed + 5))
        echo "   Still waiting... ($elapsed/${timeout}s)"
    done
    
    echo "❌ Installation timeout. Please complete the installation and re-run this script."
    return 1
}

# Main execution
main() {
    # Only run on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo "ℹ️  Xcode Command Line Tools check skipped (not macOS)"
        exit 0
    fi
    
    echo "🔍 Checking Xcode Command Line Tools..."
    
    if check_xcode_tools; then
        echo "🎉 Xcode Command Line Tools are ready"
        exit 0
    else
        echo ""
        echo "⚠️  Xcode Command Line Tools are required for:"
        echo "   • Homebrew installation and package compilation"
        echo "   • Building software from source code"
        echo "   • Development tools (git, make, gcc, etc.)"
        echo ""
        
        # Check if running non-interactively (e.g., called from another script)
        if [ -n "$NONINTERACTIVE" ] || [ -n "$CI" ]; then
            echo "🔧 Non-interactive mode detected. Installing Xcode Command Line Tools automatically..."
            if install_xcode_tools; then
                echo "🎉 Setup complete! Xcode Command Line Tools are now available."
                exit 0
            else
                echo "❌ Automatic installation failed. Please install manually using: xcode-select --install"
                exit 1
            fi
        else
            # Interactive mode - ask user
            read -p "📥 Would you like to install Xcode Command Line Tools now? (y/N): " -n 1 -r
            echo
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                if install_xcode_tools; then
                    echo "🎉 Setup complete! Xcode Command Line Tools are now available."
                    exit 0
                else
                    echo "❌ Installation failed. Please install manually using: xcode-select --install"
                    exit 1
                fi
            else
                echo "⚠️  Skipping installation. You can install later using: xcode-select --install"
                exit 1
            fi
        fi
    fi
}

# Run main function
main "$@"