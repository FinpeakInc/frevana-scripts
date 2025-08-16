#!/bin/bash

# Universal Python Installer via Homebrew
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

# Install Python via Homebrew
install_python_homebrew() {
    local brew_cmd="$1"
    local min_version="$2"
    
    # Set up isolated Homebrew environment
    export HOMEBREW_PREFIX="$FREVANA_HOME"
    export HOMEBREW_CELLAR="$FREVANA_HOME/Cellar"
    export HOMEBREW_REPOSITORY="$FREVANA_HOME/homebrew"
    export HOMEBREW_CACHE="$FREVANA_HOME/Cache"
    export HOMEBREW_LOGS="$FREVANA_HOME/Logs"
    
    # Determine Python formula
    local python_formula="python@3.12"
    if [ -n "$min_version" ]; then
        echo "🎯 Installing Python >= $min_version (using $python_formula)"
    else
        echo "🎯 Installing latest Python ($python_formula)"
    fi
    
    # Install Python using Homebrew
    echo "📦 Installing Python..."
    if "$brew_cmd" install "$python_formula"; then
        echo "✅ Python installed successfully!"
    else
        echo "❌ Error: Python installation failed" >&2
        exit 1
    fi
    
    return 0
}

# Create symbolic links for Python
create_python_links() {
    echo "🔗 Creating symbolic links..."
    
    # Find Python binaries in Homebrew installation
    local python_bin="$FREVANA_HOME/bin/python3.12"
    local pip_bin="$FREVANA_HOME/bin/pip3.12"
    
    if [ -f "$python_bin" ]; then
        ln -sf "$python_bin" "$FREVANA_HOME/bin/python3"
        ln -sf "$python_bin" "$FREVANA_HOME/bin/python"
        echo "   → Python: $FREVANA_HOME/bin/python3"
        echo "   → Python: $FREVANA_HOME/bin/python"
    else
        echo "⚠️ Warning: Python3.12 binary not found at $python_bin"
    fi
    
    if [ -f "$pip_bin" ]; then
        ln -sf "$pip_bin" "$FREVANA_HOME/bin/pip3"
        ln -sf "$pip_bin" "$FREVANA_HOME/bin/pip"
        echo "   → pip: $FREVANA_HOME/bin/pip3"
        echo "   → pip: $FREVANA_HOME/bin/pip"
    else
        echo "⚠️ Warning: pip3.12 binary not found at $pip_bin"
    fi
}

# Verify installation
verify_installation() {
    echo "✅ Verifying Python installation..."
    
    local python_cmd="python3"
    local pip_cmd="pip3"
    
    # Use FREVANA_HOME versions if available
    if [ -f "$FREVANA_HOME/bin/python3" ]; then
        python_cmd="$FREVANA_HOME/bin/python3"
    elif [ -f "$FREVANA_HOME/bin/python3.exe" ]; then
        python_cmd="$FREVANA_HOME/bin/python3.exe"
    fi
    
    if [ -f "$FREVANA_HOME/bin/pip3" ]; then
        pip_cmd="$FREVANA_HOME/bin/pip3"
    elif [ -f "$FREVANA_HOME/bin/pip3.exe" ]; then
        pip_cmd="$FREVANA_HOME/bin/pip3.exe"
    fi
    
    local python_version=$($python_cmd --version 2>/dev/null | cut -d' ' -f2 || echo "unknown")
    local pip_version=$($pip_cmd --version 2>/dev/null | cut -d' ' -f2 || echo "unknown")
    
    echo "   → Python version: $python_version"
    echo "   → pip version: $pip_version"
    echo "   → Python location: $python_cmd"
    echo "   → pip location: $pip_cmd"
}

# Main execution
main() {
    echo "🐍 Starting Python installation via Homebrew..."
    if [ -n "$min_version" ]; then
        echo "📋 Minimum version required: $min_version"
    fi
    echo ""
    
    # Check for Homebrew
    local brew_cmd=$(check_homebrew)
    echo "🍺 Using Homebrew: $brew_cmd"
    echo ""
    
    # Install Python via Homebrew
    install_python_homebrew "$brew_cmd" "$min_version"
    echo ""
    
    # Create symbolic links
    create_python_links
    echo ""
    
    # Verify installation
    verify_installation
    echo ""
    
    echo "✅ Python installation completed successfully!"
    echo "🎉 You can now use 'python3' and 'pip3' commands"
    echo ""
    echo "To get started:"
    echo "  python3 --version"
    echo "  pip3 --version"
}

# Run main function
main "$@"