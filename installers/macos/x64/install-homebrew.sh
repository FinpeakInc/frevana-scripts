#!/bin/bash

# Homebrew Installer for macOS x64
# Creates completely isolated Homebrew installation

set -e

# FREVANA_HOME should be set by the calling script
if [ -z "$FREVANA_HOME" ]; then
    echo "❌ Error: FREVANA_HOME not set" >&2
    exit 1
fi

# ================================
# HOMEBREW ENVIRONMENT SETUP
# ================================
# Set Homebrew environment variables to point to FREVANA_HOME
# This creates a completely isolated Homebrew installation
echo "🔧 Setting up isolated Homebrew environment..."

export HOMEBREW_PREFIX="$FREVANA_HOME"
export HOMEBREW_CELLAR="$FREVANA_HOME/Cellar"
export HOMEBREW_REPOSITORY="$FREVANA_HOME/homebrew"
export HOMEBREW_CACHE="$FREVANA_HOME/Cache"
export HOMEBREW_LOGS="$FREVANA_HOME/Logs"

echo "   → HOMEBREW_PREFIX: $HOMEBREW_PREFIX"
echo "   → HOMEBREW_REPOSITORY: $HOMEBREW_REPOSITORY"
echo "   → HOMEBREW_CELLAR: $HOMEBREW_CELLAR"

echo "🍺 Setting up Homebrew for macOS x64..."
echo ""

# Common Homebrew locations on macOS
brew_locations=(
    "/usr/local"         # Intel Mac default
    "/opt/homebrew"      # Apple Silicon default (may exist on Intel via Rosetta)
    "$HOME/.homebrew"    # Custom user install
    "/home/linuxbrew/.linuxbrew"  # Linux (just in case)
)

# Note: We always install independent Homebrew to avoid path issues

# Check if system already has Homebrew
system_brew_path=""
for location in "${brew_locations[@]}"; do
    if [ -x "$location/bin/brew" ]; then
        system_brew_path="$location"
        echo "✅ Found existing Homebrew at: $system_brew_path"
        break
    fi
done

if [ -n "$system_brew_path" ]; then
    echo "ℹ️ Found existing Homebrew at: $system_brew_path"
    echo "⚠️ Installing independent Homebrew to FREVANA_HOME to avoid conflicts..."
    echo ""
fi

# Install Homebrew to the repository location
echo "📥 Installing Homebrew to isolated environment..."

# Remove existing installation if it exists
if [ -d "$HOMEBREW_REPOSITORY" ]; then
    echo "   → Removing existing Homebrew installation"
    rm -rf "$HOMEBREW_REPOSITORY"
fi

echo "   → Cloning Homebrew repository to: $HOMEBREW_REPOSITORY"
git clone https://github.com/Homebrew/brew.git "$HOMEBREW_REPOSITORY"

# Create bin directory and link
mkdir -p "$HOMEBREW_PREFIX/bin"
ln -sf "$HOMEBREW_REPOSITORY/bin/brew" "$HOMEBREW_PREFIX/bin/brew"

# Verify installation
if "$HOMEBREW_PREFIX/bin/brew" --version >/dev/null 2>&1; then
    brew_version=$("$HOMEBREW_PREFIX/bin/brew" --version | head -n1)
    echo "✅ Successfully installed Homebrew: $brew_version"
else
    echo "❌ Error: Homebrew installation failed" >&2
    exit 1
fi

echo ""
echo "🔧 Homebrew environment configured:"
echo "   → Installation: $HOMEBREW_REPOSITORY"
echo "   → Command: $HOMEBREW_PREFIX/bin/brew"
echo "   → Cellar: $HOMEBREW_CELLAR"

# Test basic functionality
echo ""
echo "🧪 Testing Homebrew functionality..."
if "$HOMEBREW_PREFIX/bin/brew" --version >/dev/null 2>&1; then
    version_info=$("$HOMEBREW_PREFIX/bin/brew" --version | head -n1)
    echo "   → $version_info"
    echo "   → Homebrew is ready to use!"
else
    echo "❌ Error: Homebrew test failed" >&2
    exit 1
fi

echo ""
echo "✅ Homebrew setup completed successfully!"
echo "🎉 You can now use Homebrew to install packages"
echo ""
echo "To get started:"
echo "  $HOMEBREW_PREFIX/bin/brew --version"
echo "  $HOMEBREW_PREFIX/bin/brew install python@3.12"