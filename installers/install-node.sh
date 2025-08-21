#!/bin/bash

# Node.js Standalone Binary Installer
# Direct installation from Node.js official binaries without dependencies

set -e

# ================================
# DEFAULT NODE.JS VERSION
# ================================
# Default to latest stable LTS version if not specified
DEFAULT_NODE_VERSION="v22.18.0"  # Latest LTS as of 2024

# ================================
# GLOBAL VARIABLES
# ================================
VERBOSE=false
NODE_VERSION=""
NPM_VERSION=""
PNPM_VERSION=""
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
    local node_version="${3:-}"
    local npm_version="${4:-}"
    local pnpm_version="${5:-}"
    local install_path="${6:-}"
    
    cat <<EOF
{
  "success": $success,
  "message": "$message",
  "node_version": "$node_version",
  "npm_version": "$npm_version",
  "pnpm_version": "$pnpm_version",
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
            os="darwin"
            ;;
        Linux*)
            os="linux"
            ;;
        MINGW* | MSYS* | CYGWIN*)
            os="win"
            ;;
        *)
            output_json "false" "Unsupported operating system"
            exit 1
            ;;
    esac
    
    # Detect architecture
    case "$(uname -m)" in
        x86_64 | amd64)
            arch="x64"
            ;;
        arm64 | aarch64)
            arch="arm64"
            ;;
        armv7l)
            arch="armv7l"
            ;;
        *)
            output_json "false" "Unsupported architecture"
            exit 1
            ;;
    esac
    
    echo "${os}-${arch}"
}

# Download Node.js binary
download_node() {
    local version="$1"
    local platform="$2"
    local target_dir="$3"
    
    # If no version specified, use default
    if [ -z "$version" ]; then
        version="$DEFAULT_NODE_VERSION"
        log_verbose "   → Using default Node.js version: $version"
    fi
    
    # Construct download URL
    local filename="node-${version}-${platform}.tar.gz"
    if [[ "$platform" == "win-"* ]]; then
        filename="node-${version}-${platform}.zip"
    fi
    local url="https://nodejs.org/dist/${version}/${filename}"
    
    log_verbose "📥 Downloading Node.js ${version} for ${platform}..."
    log_verbose "   → URL: $url"
    
    # Create temp directory
    local temp_dir="$(mktemp -d)"
    local download_file="${temp_dir}/${filename}"
    
    # Download
    if command -v curl &> /dev/null; then
        curl -L -o "$download_file" "$url" 2>/dev/null || {
            rm -rf "$temp_dir"
            return 1
        }
    elif command -v wget &> /dev/null; then
        wget -O "$download_file" "$url" 2>/dev/null || {
            rm -rf "$temp_dir"
            return 1
        }
    else
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Extract
    log_verbose "📦 Extracting Node.js..."
    if [[ "$filename" == *.zip ]]; then
        unzip -q "$download_file" -d "$temp_dir"
    else
        tar -xzf "$download_file" -C "$temp_dir"
    fi
    
    # Move to target directory
    local extracted_dir="${temp_dir}/node-${version}-${platform}"
    if [ -d "$target_dir" ]; then
        log_verbose "🗑️  Removing old Node.js installation..."
        rm -rf "$target_dir"
    fi
    
    mkdir -p "$(dirname "$target_dir")"
    mv "$extracted_dir" "$target_dir"
    
    # Cleanup
    rm -rf "$temp_dir"
    
    log_verbose "✅ Node.js downloaded and extracted successfully!"
    return 0
}

# Get appropriate Node.js version
get_node_version() {
    local min_version="$1"
    
    if [ -z "$min_version" ]; then
        # Return empty to use latest LTS
        echo ""
        return
    fi
    
    # Parse major version from min_version
    local major_version=$(echo "$min_version" | cut -d'.' -f1 | sed 's/[^0-9]//g')
    
    # Map to specific versions
    case "$major_version" in
        "22" | "23" | "24")
            echo "v22.18.0"  # Latest v22 LTS
            ;;
        "20" | "21")
            echo "v20.18.1"  # Latest v20 LTS
            ;;
        "18" | "19")
            echo "v18.20.5"  # Latest v18 LTS
            ;;
        "16" | "17")
            echo "v16.20.2"  # Final v16 LTS
            ;;
        *)
            # For other versions, use default LTS
            echo "$DEFAULT_NODE_VERSION"
            ;;
    esac
}

# Create symbolic links for Node.js
create_node_links() {
    log_verbose "🔗 Creating symbolic links..."
    
    local node_bin_dir="$FREVANA_HOME/node/bin"
    
    if [ -d "$node_bin_dir" ]; then
        # Create symbolic links for all Node.js binaries
        for binary in node npm npx corepack; do
            local source_binary="$node_bin_dir/$binary"
            local target_link="$FREVANA_HOME/bin/$binary"
            
            if [ -f "$source_binary" ] || [ -L "$source_binary" ]; then
                # Remove existing link if present
                [ -e "$target_link" ] && rm -f "$target_link"
                
                # Create new symbolic link
                ln -s "$source_binary" "$target_link"
                chmod +x "$target_link"
                log_verbose "   → $binary: $target_link"
            fi
        done
    else
        return 1
    fi
}

# Install pnpm
install_pnpm() {
    local npm_path="$FREVANA_HOME/bin/npm"
    
    log_verbose "📦 Installing pnpm..."
    if "$npm_path" install -g pnpm >/dev/null 2>&1; then
        log_verbose "✅ pnpm installed successfully!"
        
        # Create symbolic link for pnpm
        local pnpm_source="$FREVANA_HOME/lib/node_modules/pnpm/bin/pnpm.cjs"
        local pnpm_target="$FREVANA_HOME/bin/pnpm"
        
        if [ -f "$pnpm_source" ]; then
            [ -L "$pnpm_target" ] && rm "$pnpm_target"
            ln -s "$pnpm_source" "$pnpm_target"
            chmod +x "$pnpm_target"
            log_verbose "   → pnpm link created: $pnpm_target"
            
            # Get pnpm version
            if [ -x "$pnpm_target" ] && "$pnpm_target" --version >/dev/null 2>&1; then
                PNPM_VERSION=$("$pnpm_target" --version 2>/dev/null)
                log_verbose "   → pnpm version: $PNPM_VERSION"
            fi
        else
            log_verbose "⚠️ Warning: pnpm binary not found at expected location"
        fi
    else
        log_verbose "⚠️ Warning: pnpm installation failed, but Node.js is installed successfully"
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
    
    log_verbose "🚀 Installing Node.js Standalone Binary..."
    if [ -n "$min_version" ]; then
        log_verbose "📋 Minimum version required: $min_version"
    fi
    log_verbose ""
    
    # Setup environment
    setup_environment
    
    # Detect system
    local platform=$(detect_system)
    log_verbose "🖥️  Detected platform: $platform"
    
    # Get Node.js version
    local node_version=$(get_node_version "$min_version")
    if [ -n "$node_version" ]; then
        log_verbose "🎯 Installing Node.js $node_version"
    else
        log_verbose "🎯 Installing latest LTS Node.js"
    fi
    
    # Download and install Node.js
    local node_dir="$FREVANA_HOME/node"
    if download_node "$node_version" "$platform" "$node_dir"; then
        log_verbose "✅ Node.js downloaded successfully!"
    else
        output_json "false" "Failed to download Node.js"
        exit 1
    fi
    
    # Create symbolic links for Node.js tools
    if ! create_node_links; then
        output_json "false" "Node.js bin directory not found at $node_dir/bin"
        exit 1
    fi
    
    # Verify installation
    log_verbose ""
    log_verbose "✅ Verifying Node.js installation..."
    local node_path="$FREVANA_HOME/bin/node"
    local npm_path="$FREVANA_HOME/bin/npm"
    
    if [ -x "$node_path" ] && "$node_path" --version >/dev/null 2>&1; then
        NODE_VERSION=$("$node_path" --version)
        NPM_VERSION=$("$npm_path" --version 2>/dev/null || echo "unknown")
        log_verbose "   → Node.js version: $NODE_VERSION"
        log_verbose "   → npm version: $NPM_VERSION"
        log_verbose "   → Node.js location: $node_path"
        log_verbose "   → npm location: $npm_path"
    else
        output_json "false" "Node.js verification failed"
        exit 1
    fi
    
    # Install pnpm
    log_verbose ""
    install_pnpm
    
    log_verbose ""
    log_verbose "✅ Node.js installation completed successfully!"
    log_verbose "🎉 You can now use 'node', 'npm', 'npx', and 'pnpm' commands"
    log_verbose ""
    log_verbose "To get started:"
    log_verbose "  node --version"
    log_verbose "  npm --version"
    log_verbose "  npx --version"
    log_verbose "  pnpm --version"
    
    # Output JSON result
    output_json "true" "Node.js installation completed successfully" "$NODE_VERSION" "$NPM_VERSION" "$PNPM_VERSION" "$INSTALL_PATH"
}

# Run main function
main "$@"