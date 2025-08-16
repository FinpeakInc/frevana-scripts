#!/bin/bash

# Frevana UV Installation Script
# This script installs UV (Python package installer) into the FREVANA_HOME directory

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
fi

# Ensure FREVANA_HOME/bin exists
mkdir -p "$FREVANA_HOME/bin"

echo "Installing UV to $FREVANA_HOME/bin..."

# Download and install UV using the official installer
curl -LsSf https://astral.sh/uv/install.sh | env CARGO_HOME="$FREVANA_HOME" RUSTUP_HOME="$FREVANA_HOME" sh

# Move uv binary to the expected location
if [ -f "$FREVANA_HOME/bin/uv" ]; then
    echo "✓ UV installed successfully to $FREVANA_HOME/bin/uv"
    
    # Test the installation
    if "$FREVANA_HOME/bin/uv" --version > /dev/null 2>&1; then
        echo "✓ UV installation verified"
        "$FREVANA_HOME/bin/uv" --version
    else
        echo "✗ UV installation verification failed"
        exit 1
    fi
else
    echo "✗ UV installation failed - binary not found at expected location"
    exit 1
fi

echo "UV installation completed successfully!"