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

# Select appropriate Python version based on minimum requirement
select_python_version() {
    local min_version="$1"
    
    if [ -z "$min_version" ]; then
        echo "python@3.12"  # Default to stable version
        return
    fi
    
    # Parse major.minor from min_version
    local major_minor=$(echo "$min_version" | cut -d'.' -f1-2)
    
    case "$major_minor" in
        "3.13"*|"3.14"*|"3.15"*)
            # Try 3.13 first, fallback to 3.12
            echo "python@3.13"
            ;;
        "3.12"*)
            echo "python@3.12"
            ;;
        "3.11"*)
            echo "python@3.11"
            ;;
        *)
            # For other versions, use latest stable
            echo "python@3.12"
            ;;
    esac
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
    
    # Determine Python formula based on version requirement
    local python_formula=$(select_python_version "$min_version")
    if [ -n "$min_version" ]; then
        echo "🎯 Installing Python >= $min_version (using $python_formula)"
    else
        echo "🎯 Installing latest Python ($python_formula)"
    fi
    
    # Install Python using Homebrew with fallback
    echo "📦 Installing Python..."
    if "$brew_cmd" install "$python_formula"; then
        echo "✅ Python installed successfully!"
    else
        echo "⚠️ Failed to install $python_formula, trying fallback version..."
        # Fallback to python@3.12 if the requested version fails
        if [ "$python_formula" != "python@3.12" ]; then
            python_formula="python@3.12"
            echo "📦 Installing fallback Python ($python_formula)..."
            if "$brew_cmd" install "$python_formula"; then
                echo "✅ Fallback Python installed successfully!"
            else
                echo "❌ Error: Python installation failed even with fallback" >&2
                exit 1
            fi
        else
            echo "❌ Error: Python installation failed" >&2
            exit 1
        fi
    fi
    
    return 0
}

# Create symbolic links for Python
create_python_links() {
    local python_formula="$1"
    echo "🔗 Creating symbolic links..."
    
    # Extract version from formula (e.g., python@3.12 -> 3.12)
    local version_suffix=$(echo "$python_formula" | sed 's/python@//')
    
    # Find Python binaries in Homebrew installation
    local python_bin="$FREVANA_HOME/bin/python$version_suffix"
    local pip_bin="$FREVANA_HOME/bin/pip$version_suffix"
    
    # Also check without version suffix for latest python
    if [ ! -f "$python_bin" ] && [ "$python_formula" = "python" ]; then
        python_bin="$FREVANA_HOME/bin/python3"
        pip_bin="$FREVANA_HOME/bin/pip3"
    fi
    
    # Create python/python3 links
    if [ -f "$python_bin" ]; then
        ln -sf "$python_bin" "$FREVANA_HOME/bin/python3"
        ln -sf "$python_bin" "$FREVANA_HOME/bin/python"
        echo "   → Python: $FREVANA_HOME/bin/python3 → $python_bin"
        echo "   → Python: $FREVANA_HOME/bin/python → $python_bin"
    else
        echo "⚠️ Warning: Python binary not found at $python_bin"
        # Try to find any python3.x binary
        local found_python=$(find "$FREVANA_HOME/bin" -name "python3.*" | head -n1)
        if [ -n "$found_python" ]; then
            echo "🔍 Found alternative: $found_python"
            ln -sf "$found_python" "$FREVANA_HOME/bin/python3"
            ln -sf "$found_python" "$FREVANA_HOME/bin/python"
            echo "   → Python: $FREVANA_HOME/bin/python3 → $found_python"
            echo "   → Python: $FREVANA_HOME/bin/python → $found_python"
        fi
    fi
    
    # Create pip/pip3 links
    if [ -f "$pip_bin" ]; then
        ln -sf "$pip_bin" "$FREVANA_HOME/bin/pip3"
        ln -sf "$pip_bin" "$FREVANA_HOME/bin/pip"
        echo "   → pip: $FREVANA_HOME/bin/pip3 → $pip_bin"
        echo "   → pip: $FREVANA_HOME/bin/pip → $pip_bin"
    else
        echo "⚠️ Warning: pip binary not found at $pip_bin"
        # Try to find any pip3.x binary
        local found_pip=$(find "$FREVANA_HOME/bin" -name "pip3.*" | head -n1)
        if [ -n "$found_pip" ]; then
            echo "🔍 Found alternative: $found_pip"
            ln -sf "$found_pip" "$FREVANA_HOME/bin/pip3"
            ln -sf "$found_pip" "$FREVANA_HOME/bin/pip"
            echo "   → pip: $FREVANA_HOME/bin/pip3 → $found_pip"
            echo "   → pip: $FREVANA_HOME/bin/pip → $found_pip"
        fi
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
    local python_formula=$(select_python_version "$min_version")
    install_python_homebrew "$brew_cmd" "$min_version"
    echo ""
    
    # Create symbolic links
    create_python_links "$python_formula"
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