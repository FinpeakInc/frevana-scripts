#!/bin/bash

# Python Standalone Binary Installer
# Uses python-build-standalone for dependency-free installation

set -e

# ================================
# DEFAULT PYTHON VERSION
# ================================
# Default to latest stable version if not specified
DEFAULT_PYTHON_VERSION="3.12.11"  # Latest stable as of 2024
DEFAULT_BUILD_DATE="20250818"  # Latest build date from python-build-standalone
FREVANA_PYTHON_MIRROR="${FREVANA_PYTHON_MIRROR:-https://static.frevana.com/installer/python}"
PYTHON_MIRROR="${PYTHON_MIRROR:-https://static.frevana.com/installer/python}"

# ================================
# GLOBAL VARIABLES
# ================================
VERBOSE=false
PYTHON_VERSION=""
PIP_VERSION=""
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
    local python_version="${3:-}"
    local pip_version="${4:-}"
    local install_path="${5:-}"
    
    cat <<EOF
{
  "success": $success,
  "message": "$message",
  "python_version": "$python_version",
  "pip_version": "$pip_version",
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

# Detect system architecture and platform
detect_system() {
    local os=""
    local arch=""
    
    # Detect OS
    case "$(uname -s)" in
        Darwin*)
            os="apple-darwin"
            ;;
        Linux*)
            # Check for musl vs glibc
            if ldd --version 2>&1 | grep -q musl; then
                os="unknown-linux-musl"
            else
                os="unknown-linux-gnu"
            fi
            ;;
        MINGW* | MSYS* | CYGWIN*)
            os="pc-windows-msvc-shared"
            ;;
        *)
            output_json "false" "Unsupported operating system"
            exit 1
            ;;
    esac
    
    # Detect architecture
    case "$(uname -m)" in
        x86_64 | amd64)
            arch="x86_64"
            ;;
        arm64 | aarch64)
            arch="aarch64"
            ;;
        *)
            output_json "false" "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac
    
    echo "${arch}-${os}"
}

# Get appropriate Python version based on requirement
get_python_version() {
    local min_version="$1"
    
    if [ -z "$min_version" ]; then
        echo "$DEFAULT_PYTHON_VERSION"
        return
    fi
    
    # Parse major.minor from min_version
    local major_minor=$(echo "$min_version" | grep -oE '^[0-9]+\.[0-9]+')
    
    case "$major_minor" in
        "3.13")
            echo "3.13.1"  # Latest 3.13
            ;;
        "3.12")
            echo "3.12.11"  # Latest 3.12
            ;;
        "3.11")
            echo "3.11.13"  # Latest 3.11
            ;;
        "3.10")
            echo "3.10.17"  # Latest 3.10
            ;;
        "3.9")
            echo "3.9.21"  # Latest 3.9
            ;;
        *)
            echo "$DEFAULT_PYTHON_VERSION"
            ;;
    esac
}

# Download Python from python-build-standalone
download_python() {
    local version="$1"
    local platform="$2"
    local target_dir="$3"
    
    # Construct download URL for python-build-standalone
    local base_url="https://github.com/astral-sh/python-build-standalone/releases/download"
    local date_tag="$DEFAULT_BUILD_DATE"
    
    # Use install_only variant for simplicity (no zstd required)
    local variant="install_only"
    local file_ext="tar.gz"
    
    # Adjust platform string for python-build-standalone naming convention
    local download_platform="$platform"
    if [[ "$platform" == "x86_64-unknown-linux-gnu" ]]; then
        download_platform="x86_64_v3-unknown-linux-gnu"  # Use v3 for better compatibility
    fi
    
    # Build filename
    local filename="cpython-${version}+${date_tag}-${download_platform}-${variant}.${file_ext}"
    # Mirror paths sometimes require '+' to be percent-encoded as %2B — encode only for mirror URLs
    local encoded_filename="${filename//+/%2B}"
    local primary_url="${base_url}/${date_tag}/${filename}"
    local mirror_base="${FREVANA_PYTHON_MIRROR:-${PYTHON_MIRROR:-}}"

    # Prepare candidate URLs: primary first, then mirror
    local urls=()
    urls+=("$primary_url")
    if [ -n "$mirror_base" ]; then
        mirror_base="${mirror_base%/}"
        # use percent-encoded filename for mirror to avoid + -> space or other transformations
        urls+=("${mirror_base}/${date_tag}/${encoded_filename}")
    fi

    log_verbose "📥 Downloading Python ${version} for ${platform}..."
    log_verbose "   → Candidates: ${urls[*]}"

    # Create temp directory
    local temp_dir="$(mktemp -d)"
    local download_file="${temp_dir}/python.tar.gz"

    # Download with retries per candidate URL
    local max_retries=3
    local downloaded=false

    for url in "${urls[@]}"; do
        local attempt=0
        while [ $attempt -lt $max_retries ]; do
            log_verbose "   → Trying $url (attempt $((attempt + 1))/$max_retries)"
            if command -v curl &> /dev/null; then
                if curl -fSL -o "$download_file" "$url" 2>/dev/null; then
                    downloaded=true
                    break
                fi
            elif command -v wget &> /dev/null; then
                if wget -O "$download_file" "$url" 2>/dev/null; then
                    downloaded=true
                    break
                fi
            else
                rm -rf "$temp_dir"
                return 1
            fi

            attempt=$((attempt + 1))
            if [ $attempt -lt $max_retries ]; then
                log_verbose "   ⚠️ Download failed from $url, retrying..."
                sleep 2
            fi
        done

        if [ "$downloaded" = true ] && [ -s "$download_file" ]; then
            log_verbose "   → Download succeeded from: $url"
            break
        else
            log_verbose "   → Download failed from: $url"
            # clear and try next candidate
            rm -f "$download_file" 2>/dev/null || true
        fi
    done

    if [ "$downloaded" != true ] || [ ! -s "$download_file" ]; then
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Extract
    log_verbose "📦 Extracting Python..."
    tar -xzf "$download_file" -C "$temp_dir" || {
        rm -rf "$temp_dir"
        return 1
    }
    
    # Find the extracted directory (should be 'python')
    local extracted_dir="${temp_dir}/python"
    
    if [ ! -d "$extracted_dir" ]; then
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Move to target directory
    if [ -d "$target_dir" ]; then
        log_verbose "🗑️  Removing old Python installation..."
        rm -rf "$target_dir"
    fi
    
    mkdir -p "$(dirname "$target_dir")"
    mv "$extracted_dir" "$target_dir"
    
    # Cleanup
    rm -rf "$temp_dir"
    
    log_verbose "✅ Python downloaded and extracted successfully!"
    return 0
}

# Create symbolic links for Python
create_python_links() {
    local python_dir="$1"
    
    log_verbose "🔗 Creating symbolic links..."
    
    # Find the actual Python binary (e.g., python3.12)
    local python_bin=""
    for py in "$python_dir"/bin/python3.*; do
        if [ -f "$py" ] && [ ! -L "$py" ]; then
            python_bin="$py"
            break
        fi
    done
    
    if [ -z "$python_bin" ]; then
        return 1
    fi
    
    local python_version=$(basename "$python_bin")
    
    # Create links in FREVANA_HOME/bin
    # Link the specific version
    ln -sf "$python_bin" "$FREVANA_HOME/bin/$python_version"
    log_verbose "   → $python_version"
    
    # Create python3 link
    ln -sf "$python_bin" "$FREVANA_HOME/bin/python3"
    log_verbose "   → python3 → $python_version"
    
    # Create python link
    ln -sf "$python_bin" "$FREVANA_HOME/bin/python"
    log_verbose "   → python → $python_version"
    
    # Link pip if it exists
    if [ -f "$python_dir/bin/pip3" ]; then
        ln -sf "$python_dir/bin/pip3" "$FREVANA_HOME/bin/pip3"
        ln -sf "$python_dir/bin/pip3" "$FREVANA_HOME/bin/pip"
        log_verbose "   → pip3"
        log_verbose "   → pip → pip3"
    fi
    
    # Link pip with version if it exists (e.g., pip3.12)
    for pip in "$python_dir"/bin/pip3.*; do
        if [ -f "$pip" ]; then
            local pip_name=$(basename "$pip")
            ln -sf "$pip" "$FREVANA_HOME/bin/$pip_name"
            log_verbose "   → $pip_name"
        fi
    done
    
    return 0
}

# Ensure pip is installed
ensure_pip() {
    local python_cmd="$1"
    
    log_verbose "📦 Ensuring pip is installed..."
    
    # Check if pip already exists
    if "$python_cmd" -m pip --version >/dev/null 2>&1; then
        log_verbose "   → pip is already installed"
        return 0
    fi
    
    # Download and install pip
    log_verbose "   → Installing pip..."
    local temp_file="$(mktemp)"
    
    if command -v curl &> /dev/null; then
        curl -s https://bootstrap.pypa.io/get-pip.py -o "$temp_file"
    elif command -v wget &> /dev/null; then
        wget -q https://bootstrap.pypa.io/get-pip.py -O "$temp_file"
    else
        rm -f "$temp_file"
        return 1
    fi
    
    if "$python_cmd" "$temp_file" --user >/dev/null 2>&1; then
        log_verbose "   → pip installed successfully"
        rm -f "$temp_file"
        return 0
    else
        rm -f "$temp_file"
        return 1
    fi
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
    
    log_verbose "🐍 Installing Python Standalone Binary..."
    if [ -n "$min_version" ]; then
        log_verbose "📋 Minimum version required: $min_version"
    fi
    log_verbose ""
    
    # Setup environment
    setup_environment
    
    # Detect system
    local platform=$(detect_system)
    log_verbose "🖥️  Detected platform: $platform"
    
    # Get Python version
    local python_version=$(get_python_version "$min_version")
    log_verbose "🎯 Installing Python $python_version"
    log_verbose ""
    
    # Download and install Python
    local python_dir="$FREVANA_HOME/python"
    if download_python "$python_version" "$platform" "$python_dir"; then
        log_verbose ""
    else
        output_json "false" "Failed to download Python after multiple attempts"
        exit 1
    fi
    
    # Create symbolic links
    if ! create_python_links "$python_dir"; then
        output_json "false" "Python binary not found in $python_dir/bin"
        exit 1
    fi
    log_verbose ""
    
    # Ensure pip is installed
    ensure_pip "$FREVANA_HOME/bin/python"
    log_verbose ""
    
    # Verify installation
    log_verbose "✅ Verifying Python installation..."
    local python_path="$FREVANA_HOME/bin/python"
    local pip_path="$FREVANA_HOME/bin/pip"
    
    if [ -x "$python_path" ] && "$python_path" --version >/dev/null 2>&1; then
        PYTHON_VERSION=$("$python_path" --version 2>&1)
        log_verbose "   → Python version: $PYTHON_VERSION"
        log_verbose "   → Python location: $python_path"
        
        if [ -x "$pip_path" ] || "$python_path" -m pip --version >/dev/null 2>&1; then
            PIP_VERSION=$("$python_path" -m pip --version 2>/dev/null | cut -d' ' -f2 || echo "unknown")
            log_verbose "   → pip version: $PIP_VERSION"
        fi
    else
        output_json "false" "Python verification failed"
        exit 1
    fi
    
    log_verbose ""
    log_verbose "✅ Python installation completed successfully!"
    log_verbose "🎉 You can now use 'python', 'python3', 'pip', and 'pip3' commands"
    log_verbose ""
    log_verbose "To get started:"
    log_verbose "  python --version"
    log_verbose "  pip --version"
    log_verbose "  python -m pip install <package>"
    
    # Output JSON result
    output_json "true" "Python installation completed successfully" "$PYTHON_VERSION" "$PIP_VERSION" "$INSTALL_PATH"
}

# Run main function
main "$@"