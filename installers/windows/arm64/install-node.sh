#!/bin/bash

# Node.js Installer for Windows ARM64
# This script simulates the actual installation process with echo

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

if [ -z "$FREVANA_HOME" ]; then
    FREVANA_HOME=$(get_default_frevana_home)
    echo "📂 FREVANA_HOME not set, using default: $FREVANA_HOME"
else
    echo "📂 Using provided FREVANA_HOME: $FREVANA_HOME"
fi

# Ensure directory structure exists
mkdir -p "$FREVANA_HOME"/{bin,node,tmp}

# Parse command line arguments
min_version=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --min-version=*)
            min_version="${1#*=}"
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

echo "🚀 Starting Node.js installation for Windows ARM64..."
echo "📂 Installing to: $FREVANA_HOME"
if [ -n "$min_version" ]; then
    echo "📋 Minimum version required: $min_version"
fi
echo ""

echo "📋 Installation Steps:"
echo "1. 🔍 Checking for existing Node.js installation..."
echo "   → System version: $(node --version 2>/dev/null || echo 'None')"
echo "   → Frevana version: $($FREVANA_HOME/bin/node.exe --version 2>/dev/null || echo 'None')"

# Determine target version based on requirement
target_version="20.12.2"
if [ -n "$min_version" ]; then
    echo "2. 🎯 Determining target version..."
    echo "   → Required: $min_version"
    echo "   → Target: $target_version (latest LTS >= $min_version)"
else
    echo "2. 🎯 Using latest LTS version: $target_version"
fi

echo "3. 📥 Downloading Node.js v$target_version for Windows ARM64..."
echo "   → URL: https://nodejs.org/dist/v$target_version/node-v$target_version-win-arm64.zip"
echo "   → Downloading to: $FREVANA_HOME/tmp/"

echo "4. 📦 Extracting Node.js archive..."
echo "   → Extracting to: $FREVANA_HOME/node/v$target_version/"

echo "5. 🔗 Creating symbolic links in Frevana bin directory..."
echo "   → ln -sf $FREVANA_HOME/node/v$target_version/node.exe $FREVANA_HOME/bin/node.exe"
echo "   → ln -sf $FREVANA_HOME/node/v$target_version/npm.cmd $FREVANA_HOME/bin/npm.cmd"

echo "6. ✅ Verifying installation..."
echo "   → Node.js version: v$target_version"
echo "   → npm version: 10.5.0"
echo "   → Install location: $FREVANA_HOME/node/v$target_version/"

echo "7. 🔧 Environment setup..."
echo "   → Node.js available at: $FREVANA_HOME/bin/node.exe"
echo "   → npm available at: $FREVANA_HOME/bin/npm.cmd"

echo ""
echo "✅ Node.js installation completed successfully!"
echo "🎉 You can now use 'node' and 'npm' commands"
echo ""
echo "To get started:"
echo "  node --version"
echo "  npm --version"