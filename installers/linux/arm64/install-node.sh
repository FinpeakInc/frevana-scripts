#!/bin/bash

# Node.js Installer for Linux ARM64
# This script simulates the actual installation process with echo

set -e

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

echo "🚀 Starting Node.js installation for Linux ARM64..."
if [ -n "$min_version" ]; then
    echo "📋 Minimum version required: $min_version"
fi
echo ""

echo "📋 Installation Steps:"
echo "1. 🔍 Checking for existing Node.js installation..."
echo "   → Existing version found: $(node --version 2>/dev/null || echo 'None')"

# Determine target version based on requirement
target_version="20.12.2"
if [ -n "$min_version" ]; then
    echo "2. 🎯 Determining target version..."
    echo "   → Required: $min_version"
    echo "   → Target: $target_version (latest LTS >= $min_version)"
else
    echo "2. 🎯 Using latest LTS version: $target_version"
fi

echo "3. 📥 Downloading Node.js v$target_version for Linux ARM64..."
echo "   → URL: https://nodejs.org/dist/v$target_version/node-v$target_version-linux-arm64.tar.gz"

echo "4. 📦 Extracting Node.js archive..."
echo "   → Extracting to /usr/local/..."

echo "5. 🔗 Creating symbolic links..."
echo "   → ln -sf /usr/local/node-v$target_version-linux-arm64/bin/node /usr/local/bin/node"
echo "   → ln -sf /usr/local/node-v$target_version-linux-arm64/bin/npm /usr/local/bin/npm"

echo "6. ✅ Verifying installation..."
echo "   → Node.js version: v$target_version"
echo "   → npm version: 10.5.0"

echo "7. 🔧 Setting up PATH..."
echo "   → Adding /usr/local/bin to PATH"

echo ""
echo "✅ Node.js installation completed successfully!"
echo "🎉 You can now use 'node' and 'npm' commands"
echo ""
echo "To get started:"
echo "  node --version"
echo "  npm --version"
