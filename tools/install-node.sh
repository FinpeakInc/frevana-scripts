#!/bin/bash

# Universal Node.js Installer
# Detects OS and architecture, then calls appropriate platform-specific installer

set -e

# ================================
# FREVANA ENVIRONMENT SETUP
# ================================
# Set FREVANA_HOME with platform-specific defaults if not already set
get_default_frevana_home() {
    local app_name="Frevana"
    case "$OSTYPE" in
        "darwin"*)
            echo "$HOME/Library/Application Support/$app_name/tools"
            ;;
        "msys" | "cygwin" | "win32")
            echo "$HOME/AppData/Roaming/$app_name/tools"
            ;;
        *)
            echo "$HOME/.config/$app_name/tools"
            ;;
    esac
}

FREVANA_HOME=${FREVANA_HOME:-$(get_default_frevana_home)}

# Create FREVANA_HOME directory structure
mkdir -p "$FREVANA_HOME"/{bin,node,tmp}

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
            os_type="windows"
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
    local min_version=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --min-version=*)
                min_version="${1#*=}"
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                echo "Usage: $0 [--min-version=VERSION]" >&2
                exit 1
                ;;
        esac
    done
    
    echo "🚀 Installing Node.js..."
    echo "📂 FREVANA_HOME: $FREVANA_HOME"
    if [ -n "$min_version" ]; then
        echo "📋 Minimum version required: $min_version"
    fi
    
    local platform=$(detect_platform)
    local installer_url="$BASE_URL/installers/$platform/install-node.sh"
    
    echo "📱 Detected platform: $platform"
    echo "🔗 Using installer: $installer_url"
    
    # Prepare environment and parameters for platform-specific installer
    local version_param=""
    if [ -n "$min_version" ]; then
        version_param="--min-version=$min_version"
    fi
    
    # Set environment variables for the platform-specific installer
    export FREVANA_HOME="$FREVANA_HOME"
    
    if command -v curl &> /dev/null; then
        echo "📥 Downloading installer with curl..."
        bash -c "$(curl -fsSL "$installer_url")" -- $version_param
    elif command -v wget &> /dev/null; then
        echo "📥 Downloading installer with wget..."
        bash -c "$(wget -qO- "$installer_url")" -- $version_param
    else
        echo "❌ Error: Neither curl nor wget found" >&2
        exit 1
    fi
    
    echo "✅ Node.js installation completed!"
}

# Run main function
main "$@"