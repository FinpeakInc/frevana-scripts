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
            echo "$HOME/.frevana"
            ;;
        "msys" | "cygwin" | "win32")
            echo "$HOME/.frevana"
            ;;
        *)
            echo "$HOME/.frevana"
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

# Check if Homebrew is available, install if missing
check_homebrew() {
    local brew_cmd="$FREVANA_HOME/bin/brew"
    
    if [ -x "$brew_cmd" ]; then
        return 0
    fi
    
    echo "🔍 Homebrew not found, installing automatically..." >&2
    
    # Install Homebrew using the install script with non-interactive mode
    BASE_URL="https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master"
    export FREVANA_HOME="$FREVANA_HOME"
    export NONINTERACTIVE=1
    export HOMEBREW_NO_INSTALL_CLEANUP=1
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_NO_ENV_HINTS=1
    
    if command -v curl &> /dev/null; then
        if bash -c "$(curl -fsSL "$BASE_URL/installers/install-homebrew.sh")" >/dev/null 2>&1; then
            echo "✅ Homebrew installed successfully!" >&2
        else
            echo "❌ Error: Failed to install Homebrew" >&2
            return 1
        fi
    elif command -v wget &> /dev/null; then
        if bash -c "$(wget -qO- "$BASE_URL/installers/install-homebrew.sh")" >/dev/null 2>&1; then
            echo "✅ Homebrew installed successfully!" >&2
        else
            echo "❌ Error: Failed to install Homebrew" >&2
            return 1
        fi
    else
        echo "❌ Error: Neither curl nor wget found" >&2
        return 1
    fi
    
    # Verify Homebrew is now available
    if [ -x "$brew_cmd" ]; then
        return 0
    else
        echo "❌ Error: Homebrew installation failed" >&2
        return 1
    fi
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
    
    # Set up isolated Homebrew environment with non-interactive mode
    export HOMEBREW_PREFIX="$FREVANA_HOME"
    export HOMEBREW_CELLAR="$FREVANA_HOME/Cellar"
    export HOMEBREW_REPOSITORY="$FREVANA_HOME/homebrew"
    export HOMEBREW_CACHE="$FREVANA_HOME/Cache"
    export HOMEBREW_LOGS="$FREVANA_HOME/Logs"
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_NO_ENV_HINTS=1
    export HOMEBREW_NO_INSTALL_CLEANUP=1
    export NONINTERACTIVE=1
    
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
    echo "🔗 Creating symbolic links..."
    
    # Create python and pip links pointing to python3 and pip3
    # (python3 and pip3 should already be created by Homebrew)
    
    # Create python -> python3 link
    if [ -f "$FREVANA_HOME/bin/python3" ]; then
        ln -sf python3 "$FREVANA_HOME/bin/python"
        echo "   → python → python3"
    else
        echo "⚠️ Warning: python3 not found in $FREVANA_HOME/bin"
    fi
    
    # Create pip -> pip3 link  
    if [ -f "$FREVANA_HOME/bin/pip3" ]; then
        ln -sf pip3 "$FREVANA_HOME/bin/pip"
        echo "   → pip → pip3"
    else
        echo "⚠️ Warning: pip3 not found in $FREVANA_HOME/bin"
    fi
}

# Verify installation
verify_installation() {
    echo "✅ Verifying Python installation..."
    
    # Test both python3/python and pip3/pip
    local python3_cmd="$FREVANA_HOME/bin/python3"
    local python_cmd="$FREVANA_HOME/bin/python"
    local pip3_cmd="$FREVANA_HOME/bin/pip3"
    local pip_cmd="$FREVANA_HOME/bin/pip"
    
    # Check python3 and python
    if [ -x "$python3_cmd" ]; then
        local python3_version=$($python3_cmd --version 2>/dev/null | cut -d' ' -f2 || echo "unknown")
        echo "   → python3 version: $python3_version"
        echo "   → python3 location: $python3_cmd"
    else
        echo "   ⚠️ python3 not found at $python3_cmd"
    fi
    
    if [ -x "$python_cmd" ]; then
        local python_version=$($python_cmd --version 2>/dev/null | cut -d' ' -f2 || echo "unknown")
        echo "   → python version: $python_version"
        echo "   → python location: $python_cmd"
    else
        echo "   ⚠️ python not found at $python_cmd"
    fi
    
    # Check pip3 and pip
    if [ -x "$pip3_cmd" ]; then
        local pip3_version=$($pip3_cmd --version 2>/dev/null | cut -d' ' -f2 || echo "unknown")
        echo "   → pip3 version: $pip3_version"
        echo "   → pip3 location: $pip3_cmd"
    else
        echo "   ⚠️ pip3 not found at $pip3_cmd"
    fi
    
    if [ -x "$pip_cmd" ]; then
        local pip_version=$($pip_cmd --version 2>/dev/null | cut -d' ' -f2 || echo "unknown")
        echo "   → pip version: $pip_version"
        echo "   → pip location: $pip_cmd"
    else
        echo "   ⚠️ pip not found at $pip_cmd"
    fi
}

# Main execution
main() {
    echo "🐍 Starting Python installation via Homebrew..."
    if [ -n "$min_version" ]; then
        echo "📋 Minimum version required: $min_version"
    fi
    echo ""
    
    # Check for Homebrew
    if check_homebrew; then
        local brew_cmd="$FREVANA_HOME/bin/brew"
        echo "🍺 Using Homebrew: $brew_cmd"
    else
        echo "❌ Error: Could not install or find Homebrew" >&2
        exit 1
    fi
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
    echo "🎉 You can now use 'python', 'python3', 'pip', and 'pip3' commands"
}

# Run main function
main "$@"