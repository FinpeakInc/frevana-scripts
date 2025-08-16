#!/bin/bash

# Universal Node.js Installer via Homebrew
# Simplified installer using Homebrew for package management

set -e

# ================================
# FREVANA ENVIRONMENT SETUP
# ================================
get_default_frevana_home() {
    case "$OSTYPE" in
        "darwin"*)
            echo "$HOME/.frevana/mcp-tools"
            ;;
        "msys" | "cygwin" | "win32")
            echo "$HOME/.frevana/mcp-tools"
            ;;
        *)
            echo "$HOME/.frevana/mcp-tools"
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

# Check if Homebrew is available
check_homebrew() {
    local brew_cmd="$FREVANA_HOME/bin/brew"
    
    if [ -x "$brew_cmd" ]; then
        echo "$brew_cmd"
        return 0
    fi
    
    echo "❌ Error: Homebrew not found at $brew_cmd" >&2
    echo "Please install Homebrew first using: bash tools/install-homebrew.sh" >&2
    exit 1
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
    
    echo "🚀 Installing Node.js via Homebrew..."
    if [ -n "$min_version" ]; then
        echo "📋 Minimum version required: $min_version"
    fi
    echo ""
    
    # Check for Homebrew
    local brew_cmd=$(check_homebrew)
    echo "🍺 Using Homebrew: $brew_cmd"
    
    # Set up isolated Homebrew environment
    export HOMEBREW_PREFIX="$FREVANA_HOME"
    export HOMEBREW_CELLAR="$FREVANA_HOME/Cellar"
    export HOMEBREW_REPOSITORY="$FREVANA_HOME/homebrew"
    export HOMEBREW_CACHE="$FREVANA_HOME/Cache"
    export HOMEBREW_LOGS="$FREVANA_HOME/Logs"
    
    # Install Node.js using Homebrew
    echo "📦 Installing Node.js..."
    if "$brew_cmd" install node; then
        echo "✅ Node.js installed successfully!"
    else
        echo "❌ Error: Node.js installation failed" >&2
        exit 1
    fi
    
    # Create symbolic links in FREVANA_HOME/bin
    echo "🔗 Creating symbolic links..."
    local node_path="$FREVANA_HOME/bin/node"
    local npm_path="$FREVANA_HOME/bin/npm"
    local npx_path="$FREVANA_HOME/bin/npx"
    
    if [ -f "$node_path" ]; then
        echo "   → Node.js: $node_path"
    fi
    if [ -f "$npm_path" ]; then
        echo "   → npm: $npm_path"
    fi
    if [ -f "$npx_path" ]; then
        echo "   → npx: $npx_path"
    fi
    
    # Verify installation
    echo ""
    echo "✅ Verifying Node.js installation..."
    if "$node_path" --version >/dev/null 2>&1; then
        local node_version=$("$node_path" --version)
        local npm_version=$("$npm_path" --version 2>/dev/null || echo "unknown")
        echo "   → Node.js version: $node_version"
        echo "   → npm version: $npm_version"
        echo "   → Node.js location: $node_path"
        echo "   → npm location: $npm_path"
    else
        echo "❌ Error: Node.js verification failed" >&2
        exit 1
    fi
    
    echo ""
    echo "✅ Node.js installation completed successfully!"
    echo "🎉 You can now use 'node' and 'npm' commands"
    echo ""
    echo "To get started:"
    echo "  $node_path --version"
    echo "  $npm_path --version"
}

# Run main function
main "$@"