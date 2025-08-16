#!/bin/bash

# Homebrew Installer for macOS x64
# Auto-detects system Homebrew and links it, or installs to FREVANA_HOME

set -e

# FREVANA_HOME should be set by the calling script
if [ -z "$FREVANA_HOME" ]; then
    echo "❌ Error: FREVANA_HOME not set" >&2
    exit 1
fi

echo "🍺 Setting up Homebrew for macOS x64..."
echo ""

# Common Homebrew locations on macOS
brew_locations=(
    "/usr/local"         # Intel Mac default
    "/opt/homebrew"      # Apple Silicon default (may exist on Intel via Rosetta)
    "$HOME/.homebrew"    # Custom user install
    "/home/linuxbrew/.linuxbrew"  # Linux (just in case)
)

# Check if system already has Homebrew
system_brew_path=""
for location in "${brew_locations[@]}"; do
    if [ -x "$location/bin/brew" ]; then
        system_brew_path="$location"
        echo "✅ Found existing Homebrew at: $system_brew_path"
        break
    fi
done

frevana_brew_path="$FREVANA_HOME/homebrew"

if [ -n "$system_brew_path" ]; then
    echo "🔗 Linking existing Homebrew to FREVANA_HOME..."
    
    # Create symbolic link to the entire Homebrew installation
    if [ -L "$frevana_brew_path" ] || [ -d "$frevana_brew_path" ]; then
        echo "   → Removing existing $frevana_brew_path"
        rm -rf "$frevana_brew_path"
    fi
    
    ln -sf "$system_brew_path" "$frevana_brew_path"
    echo "   → Linked $system_brew_path → $frevana_brew_path"
    
    # Also create direct links in FREVANA_HOME/bin for convenience
    mkdir -p "$FREVANA_HOME/bin"
    ln -sf "$frevana_brew_path/bin/brew" "$FREVANA_HOME/bin/brew"
    
    # Verify the link works
    if "$frevana_brew_path/bin/brew" --version >/dev/null 2>&1; then
        brew_version=$("$frevana_brew_path/bin/brew" --version | head -n1)
        echo "✅ Successfully linked Homebrew: $brew_version"
    else
        echo "❌ Error: Linked Homebrew is not working" >&2
        exit 1
    fi
    
else
    echo "📥 No existing Homebrew found, installing to FREVANA_HOME..."
    
    # Clone Homebrew directly to FREVANA_HOME
    if [ -d "$frevana_brew_path" ]; then
        echo "   → Removing existing $frevana_brew_path"
        rm -rf "$frevana_brew_path"
    fi
    
    echo "   → Cloning Homebrew repository..."
    git clone https://github.com/Homebrew/brew.git "$frevana_brew_path"
    
    # Create direct link in FREVANA_HOME/bin
    mkdir -p "$FREVANA_HOME/bin"
    ln -sf "$frevana_brew_path/bin/brew" "$FREVANA_HOME/bin/brew"
    
    # Verify installation
    if "$frevana_brew_path/bin/brew" --version >/dev/null 2>&1; then
        brew_version=$("$frevana_brew_path/bin/brew" --version | head -n1)
        echo "✅ Successfully installed Homebrew: $brew_version"
    else
        echo "❌ Error: Homebrew installation failed" >&2
        exit 1
    fi
fi

echo ""
echo "🔧 Setting up Homebrew environment..."
echo "   → Homebrew location: $frevana_brew_path"
echo "   → Homebrew command: $FREVANA_HOME/bin/brew"

# Test basic functionality
echo ""
echo "🧪 Testing Homebrew functionality..."
if "$FREVANA_HOME/bin/brew" --version >/dev/null 2>&1; then
    version_info=$("$FREVANA_HOME/bin/brew" --version | head -n1)
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
echo "  $FREVANA_HOME/bin/brew --version"
echo "  $FREVANA_HOME/bin/brew install python@3.12"