#!/bin/bash

# Universal Python Installer
# Handles environment setup, installation, and linking

set -e

BASE_URL="https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master"

# ================================
# FREVANA ENVIRONMENT SETUP
# ================================
get_default_frevana_home() {
    local app_name="Frevana"
    case "$OSTYPE" in
        "darwin"*)
            echo "$HOME/Library/Application Support/$app_name/tools"
            ;;
        "msys" | "cygwin" | "win32")
            echo "$HOME/AppData/Roaming/$app_name/tools"
            ;;
        *)
            echo "$HOME/.config/$app_name/tools"
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
mkdir -p "$FREVANA_HOME"/{bin,python,tmp}

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

# Detect OS and architecture
detect_platform() {
    local os_type=""
    local arch=""
    
    # Detect OS
    case "$OSTYPE" in
        "darwin"*)
            os_type="macos"
            ;;
        "linux-gnu"*)
            os_type="linux"
            ;;
        "msys" | "cygwin" | "win32")
            os_type="windows"
            ;;
        *)
            echo "Error: Unsupported OS type: $OSTYPE" >&2
            exit 1
            ;;
    esac
    
    # Detect architecture
    arch=$(uname -m 2>/dev/null || echo "unknown")
    case "$arch" in
        "x86_64" | "amd64")
            arch="x64"
            ;;
        "arm64" | "aarch64")
            arch="arm64"
            ;;
        "i386" | "i686")
            arch="x32"
            ;;
        *)
            echo "Error: Unsupported architecture: $arch" >&2
            exit 1
            ;;
    esac
    
    echo "${os_type}/${arch}"
}

# Download platform-specific Python package
download_python() {
    local platform="$1"
    local download_script_url="$BASE_URL/installers/$platform/install-python.sh"
    
    echo "📥 Downloading Python package via platform-specific script..."
    echo "🔗 Download script: $download_script_url"
    
    # Create a temporary script to handle the download
    local temp_script="$FREVANA_HOME/tmp/download-python.sh"
    
    if command -v curl &> /dev/null; then
        curl -fsSL "$download_script_url" > "$temp_script"
    elif command -v wget &> /dev/null; then
        wget -qO "$temp_script" "$download_script_url"
    else
        echo "❌ Error: Neither curl nor wget found" >&2
        exit 1
    fi
    
    chmod +x "$temp_script"
    
    # Execute the download script, passing our arguments and FREVANA_HOME
    export FREVANA_HOME
    if [ -n "$min_version" ]; then
        "$temp_script" --min-version="$min_version"
    else
        "$temp_script"
    fi
    
    # Clean up
    rm -f "$temp_script"
}

# Extract and install Python
install_python() {
    local platform="$1"
    local target_version="$2"
    
    echo "📦 Installing Python v$target_version..."
    
    case "$platform" in
        "macos/"* | "linux/"*)
            # Extract tar.gz or zip archive
            local archive_pattern="$FREVANA_HOME/tmp/python-$target_version-*"
            local archive_file=$(ls $archive_pattern 2>/dev/null | head -n1)
            
            if [ -f "$archive_file" ]; then
                echo "📦 Extracting Python archive..."
                local install_dir="$FREVANA_HOME/python/v$target_version"
                mkdir -p "$install_dir"
                
                if [[ "$archive_file" == *.tar.gz ]]; then
                    tar -xzf "$archive_file" -C "$install_dir" --strip-components=1
                elif [[ "$archive_file" == *.tar.xz ]]; then
                    tar -xJf "$archive_file" -C "$install_dir" --strip-components=1
                elif [[ "$archive_file" == *.zip ]]; then
                    unzip -q "$archive_file" -d "$install_dir"
                    # Move contents up one level if needed
                    if [ -d "$install_dir/Python-$target_version" ]; then
                        mv "$install_dir/Python-$target_version"/* "$install_dir/"
                        rmdir "$install_dir/Python-$target_version"
                    fi
                fi
                
                echo "🔗 Creating symbolic links..."
                case "$platform" in
                    "windows/"*)
                        ln -sf "$install_dir/python.exe" "$FREVANA_HOME/bin/python.exe"
                        ln -sf "$install_dir/python.exe" "$FREVANA_HOME/bin/python3.exe"
                        ln -sf "$install_dir/Scripts/pip.exe" "$FREVANA_HOME/bin/pip.exe"
                        ln -sf "$install_dir/Scripts/pip.exe" "$FREVANA_HOME/bin/pip3.exe"
                        ;;
                    *)
                        ln -sf "$install_dir/bin/python3" "$FREVANA_HOME/bin/python3"
                        ln -sf "$install_dir/bin/python3" "$FREVANA_HOME/bin/python"
                        ln -sf "$install_dir/bin/pip3" "$FREVANA_HOME/bin/pip3"
                        ln -sf "$install_dir/bin/pip3" "$FREVANA_HOME/bin/pip"
                        ;;
                esac
            else
                echo "❌ Error: Archive file not found matching: $archive_pattern" >&2
                exit 1
            fi
            ;;
    esac
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
    echo "🐍 Starting Python installation..."
    if [ -n "$min_version" ]; then
        echo "📋 Minimum version required: $min_version"
    fi
    echo ""
    
    local platform=$(detect_platform)
    echo "📱 Detected platform: $platform"
    echo ""
    
    # Determine target version
    local target_version="3.12.2"
    if [ -n "$min_version" ]; then
        echo "🎯 Target version: $target_version (latest stable >= $min_version)"
    else
        echo "🎯 Using latest stable version: $target_version"
    fi
    echo ""
    
    # Download Python package
    download_python "$platform"
    echo ""
    
    # Install Python
    install_python "$platform" "$target_version"
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