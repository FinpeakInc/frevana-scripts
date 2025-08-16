#!/bin/bash

# Universal Homebrew Installer
# Detects OS and architecture, then calls appropriate platform-specific installer

set -e

BASE_URL="https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master"

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
            os_type="linux"
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
    
    local platform=$(detect_platform)
    local installer_url="$BASE_URL/installers/$platform/install-homebrew.sh"
    
    echo "📱 Detected platform: $platform"
    echo "🔗 Using installer: $installer_url"
    
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
    
    echo "✅ Homebrew installation completed!"
}

# Run main function
main "$@"