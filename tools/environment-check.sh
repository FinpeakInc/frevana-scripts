#!/bin/bash

# Frevana MCP Client Environment Check Script
# Usage: bash -c "$(curl -fsSL https://somelink.com/check-env.sh)" --command="node" --min-version="18.0.0"

set -e

# ================================
# INSTALLATION URLS
# ================================
BASE_URL="https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master"
URL_NODE="$BASE_URL/installers/install-node.sh"
URL_PYTHON="$BASE_URL/installers/install-python.sh"
URL_HOMEBREW="$BASE_URL/installers/install-homebrew.sh"
URL_UV="$BASE_URL/installers/install-uv.sh"

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

# Default values
COMMAND=""
MIN_VERSION=""
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --command=*)
            COMMAND="${1#*=}"
            shift
            ;;
        --min-version=*)
            MIN_VERSION="${1#*=}"
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: $0 --command=COMMAND [--min-version=VERSION] [--verbose]" >&2
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$COMMAND" ]; then
    echo "Error: --command parameter is required" >&2
    exit 1
fi

# Logging function (only output in verbose mode)
log() {
    if [ "$VERBOSE" = true ]; then
        echo "[CHECK] $1" >&2
    fi
}

# Version comparison function
version_ge() {
    printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

# Get current version of a command
get_version() {
    local cmd="$1"
    local cmd_path=""
    
    # Determine command path
    if [ -n "$FREVANA_HOME" ] && [ -x "$FREVANA_HOME/bin/$cmd" ]; then
        cmd_path="$FREVANA_HOME/bin/$cmd"
    else
        cmd_path="$cmd"
    fi
    
    case "$cmd" in
        "node")
            "$cmd_path" --version 2>/dev/null | sed 's/v//' || echo ""
            ;;
        "npm")
            "$cmd_path" --version 2>/dev/null || echo ""
            ;;
        "python3"|"python")
            "$cmd_path" --version 2>/dev/null | cut -d' ' -f2 || echo ""
            ;;
        "pip"|"pip3")
            "$cmd_path" --version 2>/dev/null | cut -d' ' -f2 || echo ""
            ;;
        "brew")
            "$cmd_path" --version 2>/dev/null | head -n1 | sed 's/Homebrew //' || echo ""
            ;;
        "uv")
            "$cmd_path" --version 2>/dev/null | cut -d' ' -f2 || echo ""
            ;;
        "git")
            "$cmd_path" --version 2>/dev/null | cut -d' ' -f3 || echo ""
            ;;
        "curl")
            "$cmd_path" --version 2>/dev/null | head -n1 | cut -d' ' -f2 || echo ""
            ;;
        *)
            echo ""
            ;;
    esac
}


# Check a single component
check_component() {
    local cmd="$1"
    local required_version="$2"
    local current_version
    local status="ready"
    local message=""
    local install_url=""
    
    log "Checking component: $cmd"
    
    # Special handling for Xcode Command Line Tools
    if [ "$cmd" = "xcode-tools" ]; then
        if xcode-select -p &> /dev/null; then
            status="ready"
            current_version="installed"
            message="Xcode Command Line Tools are installed"
            log "✓ Xcode Command Line Tools found"
        else
            status="missing"
            current_version=""
            message="Xcode Command Line Tools not found"
            install_url="$URL_XCODE_TOOLS"
            log "✗ Xcode Command Line Tools missing"
        fi
    else
        # Check if command exists and handle auto-linking
        local found_in_frevana=false
        local found_in_system=false
        local system_cmd_path=""
        
        # Check FREVANA_HOME first
        if [ -n "$FREVANA_HOME" ] && [ -x "$FREVANA_HOME/bin/$cmd" ]; then
            found_in_frevana=true
            log "✓ Found $cmd in FREVANA_HOME: $FREVANA_HOME/bin/$cmd"
        fi
        
        # Check system PATH (for informational purposes only)
        if command -v "$cmd" &> /dev/null; then
            found_in_system=true
            system_cmd_path=$(command -v "$cmd")
            log "✓ Found $cmd in system PATH: $system_cmd_path (not auto-linking)"
        fi
        
        # Only use FREVANA_HOME version for checks
        if [ "$found_in_frevana" = true ]; then
            current_version=$(get_version "$cmd")
            log "✓ Found $cmd version: $current_version"
            
            # Check version if required
            if [ -n "$required_version" ] && [ -n "$current_version" ]; then
                if version_ge "$current_version" "$required_version"; then
                    status="ready"
                    message="$cmd $current_version meets requirements (>= $required_version)"
                    log "✓ Version requirement satisfied"
                else
                    status="outdated"
                    message="$cmd $current_version is below required version $required_version"
                    
                    # Set specific install URLs for direct download (same as missing)
                    case "$cmd" in
                        "node")
                            install_url="$URL_NODE"
                            ;;
                        "npm")
                            install_url="$URL_NODE"  # npm comes with node
                            ;;
                        "python3"|"python")
                            install_url="$URL_PYTHON"
                            ;;
                        "pip"|"pip3")
                            install_url="$URL_PYTHON"  # pip comes with python
                            ;;
                        "git"|"curl"|"wget"|"jq")
                            install_url=""  # System tools, no install URL needed
                            ;;
                        "brew")
                            install_url="$URL_HOMEBREW"  # fallback for homebrew
                            ;;
                        # UV tool - direct install
                        "uv")
                            install_url="$URL_UV"
                            ;;
                        *)
                            install_url=""  # Unknown tool, no install URL
                            ;;
                    esac
                    
                    log "! Version too old, needs update"
                fi
            else
                status="ready"
                message="$cmd is available"
                if [ -n "$current_version" ]; then
                    message="$cmd $current_version is available"
                fi
            fi
        else
            if [ "$found_in_system" = true ]; then
                status="missing"
                current_version=""
                message="$cmd not found in FREVANA_HOME"
            else
                status="missing"
                current_version=""
                # Provide helpful installation guidance
                case "$cmd" in
                    "uv")
                        message="$cmd not found"
                        ;;
                    *)
                        message="$cmd not found"
                        ;;
                esac
            fi
            
            # Set specific install URLs for direct download
            case "$cmd" in
                "node")
                    install_url="$URL_NODE"
                    ;;
                "npm")
                    install_url="$URL_NODE"  # npm comes with node
                    ;;
                "python3"|"python")
                    install_url="$URL_PYTHON"
                    ;;
                "pip"|"pip3")
                    install_url="$URL_PYTHON"  # pip comes with python
                    ;;
                "git"|"curl"|"wget"|"jq")
                    install_url=""  # System tools, no install URL needed
                    ;;
                "brew")
                    install_url="$URL_HOMEBREW"  # fallback for homebrew
                    ;;
                "uv")
                    install_url="$URL_UV"
                    ;;
                *)
                    install_url=""  # Unknown tool, no install URL
                    ;;
            esac
            
            log "✗ $cmd not found"
        fi
    fi
    
    # Get command path if it exists
    local command_path=""
    if [ "$status" = "ready" ] || [ "$status" = "outdated" ]; then
        if [ "$cmd" = "xcode-tools" ]; then
            command_path=$(xcode-select -p 2>/dev/null || echo "")
        elif [ -n "$FREVANA_HOME" ] && [ -x "$FREVANA_HOME/bin/$cmd" ]; then
            command_path="$FREVANA_HOME/bin/$cmd"
        else
            command_path=$(command -v "$cmd" 2>/dev/null || echo "")
        fi
    fi
    
    # Generate JSON for this component
    cat << EOF
{
  "command": "$cmd",
  "status": "$status",
  "current_version": "$current_version",
  "required_version": "${required_version:-""}",
  "message": "$message",
  "install_url": "$install_url",
  "command_path": "$command_path"
}
EOF
}

# Main execution
main() {
    log "Starting environment check for command: $COMMAND"
    if [ -n "$MIN_VERSION" ]; then
        log "Minimum version required: $MIN_VERSION"
    fi
    
    # Check only the requested command
    local component_json=$(check_component "$COMMAND" "$MIN_VERSION")
    
    log "Environment check completed"
    
    # Output the result (single JSON object)
    echo "$component_json"
    
    # Exit with appropriate code based on status
    if echo "$component_json" | grep -q '"status": "ready"'; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"