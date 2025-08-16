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

# Check if Homebrew is available, install if missing
check_homebrew() {
    local brew_cmd="$FREVANA_HOME/bin/brew"
    
    if [ -x "$brew_cmd" ]; then
        echo "$brew_cmd"
        return 0
    fi
    
    echo "🔍 Homebrew not found, installing automatically..."
    
    # Install Homebrew using the install script
    BASE_URL="https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master"
    export FREVANA_HOME="$FREVANA_HOME"
    
    if command -v curl &> /dev/null; then
        if bash -c "$(curl -fsSL "$BASE_URL/tools/install-homebrew.sh")" >/dev/null 2>&1; then
            echo "✅ Homebrew installed successfully!"
        else
            echo "❌ Error: Failed to install Homebrew" >&2
            exit 1
        fi
    elif command -v wget &> /dev/null; then
        if bash -c "$(wget -qO- "$BASE_URL/tools/install-homebrew.sh")" >/dev/null 2>&1; then
            echo "✅ Homebrew installed successfully!"
        else
            echo "❌ Error: Failed to install Homebrew" >&2
            exit 1
        fi
    else
        echo "❌ Error: Neither curl nor wget found" >&2
        exit 1
    fi
    
    # Verify Homebrew is now available
    if [ -x "$brew_cmd" ]; then
        echo "$brew_cmd"
        return 0
    else
        echo "❌ Error: Homebrew installation failed" >&2
        exit 1
    fi
}

# Select appropriate Node.js version based on minimum requirement
select_node_version() {
    local min_version="$1"
    
    if [ -z "$min_version" ]; then
        echo "node"  # Latest version
        return
    fi
    
    # Parse major version from min_version
    local major_version=$(echo "$min_version" | cut -d'.' -f1)
    
    case "$major_version" in
        "22"*|"23"*|"24"*)
            echo "node@22"
            ;;
        "20"*|"21"*)
            echo "node@20"
            ;;
        "18"*|"19"*)
            echo "node@18"
            ;;
        "16"*|"17"*)
            echo "node@16"
            ;;
        *)
            # For other versions, use latest
            echo "node"
            ;;
    esac
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
    
    # Determine Node.js formula based on version requirement
    local node_formula=$(select_node_version "$min_version")
    if [ -n "$min_version" ]; then
        echo "🎯 Installing Node.js >= $min_version (using $node_formula)"
    else
        echo "🎯 Installing latest Node.js ($node_formula)"
    fi
    
    # Install Node.js using Homebrew with fallback
    echo "📦 Installing Node.js..."
    if "$brew_cmd" install "$node_formula"; then
        echo "✅ Node.js installed successfully!"
    else
        echo "⚠️ Failed to install $node_formula, trying fallback version..."
        # Fallback to latest node if the requested version fails
        if [ "$node_formula" != "node" ]; then
            node_formula="node"
            echo "📦 Installing fallback Node.js ($node_formula)..."
            if "$brew_cmd" install "$node_formula"; then
                echo "✅ Fallback Node.js installed successfully!"
            else
                echo "❌ Error: Node.js installation failed even with fallback" >&2
                exit 1
            fi
        else
            echo "❌ Error: Node.js installation failed" >&2
            exit 1
        fi
    fi
    
    # Create symbolic links for Node.js tools
    create_node_links "$node_formula"
    
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
    echo "🎉 You can now use 'node', 'npm', and 'npx' commands"
    echo ""
    echo "To get started:"
    echo "  node --version"
    echo "  npm --version"
    echo "  npx --version"
}

# Create symbolic links for Node.js
create_node_links() {
    local node_formula="$1"
    echo "🔗 Creating symbolic links..."
    
    # Node.js binaries should be available in FREVANA_HOME/bin after Homebrew install
    local node_path="$FREVANA_HOME/bin/node"
    local npm_path="$FREVANA_HOME/bin/npm"
    local npx_path="$FREVANA_HOME/bin/npx"
    
    if [ -f "$node_path" ]; then
        echo "   → Node.js: $node_path"
    else
        echo "⚠️ Warning: Node.js binary not found at $node_path"
    fi
    
    if [ -f "$npm_path" ]; then
        echo "   → npm: $npm_path"
    else
        echo "⚠️ Warning: npm binary not found at $npm_path"
    fi
    
    if [ -f "$npx_path" ]; then
        echo "   → npx: $npx_path"
    else
        echo "⚠️ Warning: npx binary not found at $npx_path"
    fi
}

# Run main function
main "$@"