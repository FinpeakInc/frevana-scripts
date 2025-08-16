#!/bin/bash

# Homebrew Installer for macOS ARM64
# Auto-detects system Homebrew and links it, or installs to FREVANA_HOME

set -e

# FREVANA_HOME should be set by the calling script
if [ -z "$FREVANA_HOME" ]; then
    echo "❌ Error: FREVANA_HOME not set" >&2
    exit 1
fi

# ================================
# TEMPORARY SYMLINK HANDLING
# ================================
# Create temporary symlink to handle spaces in path for Homebrew
TEMP_LINK=""
ORIGINAL_FREVANA_HOME="$FREVANA_HOME"

# Check if FREVANA_HOME contains spaces
if [[ "$FREVANA_HOME" == *" "* ]]; then
    echo "⚠️ Path contains spaces, creating temporary symlink for Homebrew compatibility..."
    
    # Create temporary symlink pointing to Application Support
    TEMP_LINK="$HOME/Library/ApplicationSupport-temp-$$"
    ln -sf "$HOME/Library/Application Support" "$TEMP_LINK"
    
    # Update FREVANA_HOME to use the symlink path
    FREVANA_HOME=$(echo "$FREVANA_HOME" | sed "s|$HOME/Library/Application Support|$TEMP_LINK|")
    
    echo "   → Original path: $ORIGINAL_FREVANA_HOME"
    echo "   → Temporary path: $FREVANA_HOME"
fi

# Cleanup function
cleanup() {
    if [ -n "$TEMP_LINK" ] && [ -L "$TEMP_LINK" ]; then
        rm "$TEMP_LINK"
        echo "🧹 Cleaned up temporary symlink: $TEMP_LINK"
    fi
}

# Set up cleanup on script exit
trap cleanup EXIT

echo "🍺 Setting up Homebrew for macOS ARM64..."
echo ""

# Common Homebrew locations on macOS
brew_locations=(
    "/opt/homebrew"      # Apple Silicon default
    "/usr/local"         # Intel Mac default  
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

frevana_brew_path="$FREVANA_HOME/homebrew"

if [ -n "$system_brew_path" ]; then
    echo "ℹ️ Found existing Homebrew at: $system_brew_path"
    echo "⚠️ Installing independent Homebrew to FREVANA_HOME to avoid conflicts..."
    echo ""
fi

# Always install independent Homebrew to FREVANA_HOME for full isolation
echo "📥 Installing independent Homebrew to FREVANA_HOME..."

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

# If we used a temporary link, create correct links using original path
if [ -n "$TEMP_LINK" ]; then
    echo "🔗 Creating final links using original path..."
    original_brew_path="${frevana_brew_path/$TEMP_LINK/$HOME/Library/Application Support}"
    mkdir -p "$(dirname "$ORIGINAL_FREVANA_HOME/bin/brew")"
    ln -sf "$original_brew_path/bin/brew" "$ORIGINAL_FREVANA_HOME/bin/brew"
    echo "   → Final brew link: $ORIGINAL_FREVANA_HOME/bin/brew"
fi

# Verify installation
if "$frevana_brew_path/bin/brew" --version >/dev/null 2>&1; then
    brew_version=$("$frevana_brew_path/bin/brew" --version | head -n1)
    echo "✅ Successfully installed Homebrew: $brew_version"
else
    echo "❌ Error: Homebrew installation failed" >&2
    exit 1
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