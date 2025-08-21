#!/bin/bash

# UV Standalone Binary Installer
# Direct installation from UV official installer

set -e

# ================================
# GLOBAL VARIABLES
# ================================
VERBOSE=false
UV_VERSION=""
INSTALL_PATH=""

# ================================
# LOGGING FUNCTIONS
# ================================
log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo "$@" >&2
    fi
}

log_error() {
    echo "❌ Error: $@" >&2
}

output_json() {
    local success="$1"
    local message="$2"
    local uv_version="${3:-}"
    local install_path="${4:-}"
    
    cat <<EOF
{
  "success": $success,
  "message": "$message",
  "uv_version": "$uv_version",
  "install_path": "$install_path"
}
EOF
}

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

setup_environment() {
    if [ -z "$FREVANA_HOME" ]; then
        FREVANA_HOME=$(get_default_frevana_home)
        log_verbose "📂 FREVANA_HOME not set, using default: $FREVANA_HOME"
    else
        log_verbose "📂 Using provided FREVANA_HOME: $FREVANA_HOME"
    fi
    
    # Ensure directory structure exists
    mkdir -p "$FREVANA_HOME"/bin
    INSTALL_PATH="$FREVANA_HOME/bin"
}

# Main execution
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            *)
                output_json "false" "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    log_verbose "🚀 Installing UV..."
    
    # Setup environment
    setup_environment
    
    log_verbose "📥 Downloading and installing UV..."
    
    # Download and install UV using the official installer
    if curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1; then
        log_verbose "✅ UV downloaded successfully"
    else
        output_json "false" "Failed to download UV"
        exit 1
    fi
    
    # Move uv binaries from default location to FREVANA_HOME/bin
    if [ -f "$HOME/.local/bin/uv" ]; then
        log_verbose "📦 Moving UV to $FREVANA_HOME/bin..."
        mv "$HOME/.local/bin/uv" "$FREVANA_HOME/bin/uv"
        if [ -f "$HOME/.local/bin/uvx" ]; then
            mv "$HOME/.local/bin/uvx" "$FREVANA_HOME/bin/uvx"
            log_verbose "   → uvx moved to $FREVANA_HOME/bin/"
        fi
        log_verbose "   → UV moved successfully to $FREVANA_HOME/bin/"
    else
        output_json "false" "UV installation failed - binary not found at $HOME/.local/bin/uv"
        exit 1
    fi
    
    # Verify installation
    log_verbose "✅ Verifying UV installation..."
    if "$FREVANA_HOME/bin/uv" --version >/dev/null 2>&1; then
        UV_VERSION=$("$FREVANA_HOME/bin/uv" --version 2>/dev/null | cut -d' ' -f2 || echo "unknown")
        log_verbose "   → UV version: $UV_VERSION"
        log_verbose "   → UV location: $FREVANA_HOME/bin/uv"
    else
        output_json "false" "UV installation verification failed"
        exit 1
    fi
    
    log_verbose "✅ UV installation completed successfully!"
    log_verbose "🎉 You can now use 'uv' and 'uvx' commands"
    log_verbose ""
    log_verbose "To get started:"
    log_verbose "  uv --version"
    log_verbose "  uv pip install <package>"
    
    # Output JSON result
    output_json "true" "UV installation completed successfully" "$UV_VERSION" "$INSTALL_PATH"
}

# Run main function
main "$@"