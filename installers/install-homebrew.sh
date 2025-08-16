#!/bin/bash

# Universal Homebrew Installer
# Detects OS and architecture, then calls appropriate platform-specific installer

set -e

BASE_URL="https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master"

# ================================
# FREVANA ENVIRONMENT SETUP
# ================================
get_default_frevana_home() {
    case "$OSTYPE" in
        "darwin"*)
            echo "$HOME/.frevana"
            ;;
        "msys" | "cygwin" | "win32")
            echo "$HOME/.frevana"
            ;;
        *)
            echo "$HOME/.frevana"
            ;;
    esac
}

if [ -z "$FREVANA_HOME" ]; then
    FREVANA_HOME=$(get_default_frevana_home)
    echo "📂 FREVANA_HOME not set, using default: $FREVANA_HOME"
else
    echo "📂 Using provided FREVANA_HOME: $FREVANA_HOME"
fi

# Ensure directory structure exists
mkdir -p "$FREVANA_HOME"/bin

# Check Xcode Command Line Tools by downloading and executing check script
check_xcode_tools() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "🔍 Checking Xcode Command Line Tools..."
        
        # Download and execute the Xcode tools check script
        if command -v curl &> /dev/null; then
            bash -c "$(curl -fsSL "$BASE_URL/tools/check-xcode-tools.sh")"
        elif command -v wget &> /dev/null; then
            bash -c "$(wget -qO- "$BASE_URL/tools/check-xcode-tools.sh")"
        else
            echo "❌ Error: Neither curl nor wget found" >&2
            exit 1
        fi
    fi
}

# Detect OS and architecture
detect_platform() {
    local os_type=""
    local arch=""
    
    # Detect OS
    case "$OSTYPE" in
        "darwin"*)
            os_type="macos"
            ;;
        "linux-gnu"*)
            echo "Error: Linux is not currently supported" >&2
            exit 1
            ;;
        "msys" | "cygwin" | "win32")
            echo "Error: Homebrew is not supported on Windows" >&2
            exit 1
            ;;
        *)
            echo "Error: Unsupported OS type: $OSTYPE" >&2
            exit 1
            ;;
    esac
    
    # Detect architecture
    arch=$(uname -m 2>/dev/null || echo "unknown")
    case "$arch" in
        "x86_64" | "amd64")
            arch="x64"
            ;;
        "arm64" | "aarch64")
            arch="arm64"
            ;;
        "i386" | "i686")
            arch="x32"
            ;;
        *)
            echo "Error: Unsupported architecture: $arch" >&2
            exit 1
            ;;
    esac
    
    echo "${os_type}/${arch}"
}

# Main execution
main() {
    echo "🍺 Installing Homebrew..."
    echo ""
    
    # Check Xcode Command Line Tools first (required for Homebrew)
    export NONINTERACTIVE=1  # Enable non-interactive mode for automated installation
    check_xcode_tools
    echo ""
    
    local platform=$(detect_platform)
    local installer_url="$BASE_URL/installers/$platform/install-homebrew.sh"
    
    echo "📱 Detected platform: $platform"
    echo "🔗 Using installer: $installer_url"
    echo ""
    
    # Set environment variables for the platform-specific installer
    export FREVANA_HOME="$FREVANA_HOME"
    
    # Download and execute platform-specific installer
    if command -v curl &> /dev/null; then
        echo "📥 Downloading installer with curl..."
        bash -c "$(curl -fsSL "$installer_url")"
    elif command -v wget &> /dev/null; then
        echo "📥 Downloading installer with wget..."
        bash -c "$(wget -qO- "$installer_url")"
    else
        echo "❌ Error: Neither curl nor wget found" >&2
        exit 1
    fi
    
    echo ""
    echo "✅ Homebrew installation completed!"
}

# Run main function
main "$@"