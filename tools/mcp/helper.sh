#!/bin/bash

# MCP Helper Script - Router for MCP installations
# This script routes to appropriate MCP installation scripts based on mcp-id

# Define base URLs
BASE_URL="https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master"
MCP_MARKETPLACE_CONFIG="$BASE_URL/marketplace/mcp-config.json"

# Define dependency installer URLs
URL_NODE="$BASE_URL/installers/install-node.sh"
URL_PYTHON="$BASE_URL/installers/install-python.sh"
URL_HOMEBREW="$BASE_URL/installers/install-homebrew.sh"
URL_UV="$BASE_URL/installers/install-uv.sh"

# Global variables
VERBOSE=false
MCP_ID=""
INSTALL_FLAG=false
MCP_NAME=""
MCP_DESCRIPTION=""
MCP_AUTHOR=""
MCP_PACKAGER=""
MCP_PACKAGE=""
MCP_PREREQUISITES=""
INSTALLED_DEPENDENCIES=""
FREVANA_HOME=""

# JSON output function
output_json() {
    local success="$1"
    local message="$2"
    local mcp_id="${3:-$MCP_ID}"
    local mcp_name="${4:-$MCP_NAME}"
    local dependencies="${5:-$INSTALLED_DEPENDENCIES}"
    local install_path="${6:-$FREVANA_HOME}"
    
    cat <<EOF
{
  "success": $success,
  "message": "$message",
  "mcp_id": "$mcp_id",
  "mcp_name": "$mcp_name",
  "dependencies_installed": "$dependencies",
  "install_path": "$install_path"
}
EOF
}

# Verbose logging (only when --verbose is enabled)
log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo "[VERBOSE] $1" >&2
    fi
}

# Function to display usage and exit with JSON
usage() {
    output_json "false" "Usage: $0 --mcp-id=<MCP_ID> [--install] [--verbose]"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --mcp-id=*)
            MCP_ID="${1#*=}"
            shift
            ;;
        --install)
            INSTALL_FLAG=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            usage
            ;;
        *)
            output_json "false" "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if MCP_ID is provided
if [ -z "$MCP_ID" ]; then
    output_json "false" "MCP ID is required"
    exit 1
fi

# Get default FREVANA_HOME based on OS
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

# Set FREVANA_HOME if not already set
if [ -z "$FREVANA_HOME" ]; then
    FREVANA_HOME=$(get_default_frevana_home)
    log_verbose "FREVANA_HOME not set, using default: $FREVANA_HOME"
fi

# Export FREVANA_HOME so child processes can use it
export FREVANA_HOME

# Ensure FREVANA_HOME directories exist
mkdir -p "$FREVANA_HOME"/bin

log_verbose "Processing MCP: $MCP_ID"
log_verbose "FREVANA_HOME: $FREVANA_HOME"
log_verbose "Install flag: $INSTALL_FLAG"
log_verbose "Verbose mode: $VERBOSE"

# Function to fetch MCP configuration from marketplace
fetch_mcp_config() {
    local mcp_id="$1"
    local config_json=""
    
    log_verbose "Fetching MCP configuration from marketplace..."
    
    # Download the marketplace config
    if command -v curl &> /dev/null; then
        config_json=$(curl -fsSL "$MCP_MARKETPLACE_CONFIG" 2>/dev/null)
    elif command -v wget &> /dev/null; then
        config_json=$(wget -qO- "$MCP_MARKETPLACE_CONFIG" 2>/dev/null)
    else
        return 1
    fi
    
    if [ -z "$config_json" ]; then
        return 1
    fi
    
    # Extract configuration for specific MCP ID using jq if available, otherwise use grep/sed
    if command -v jq &> /dev/null; then
        local mcp_config=$(echo "$config_json" | jq ".[] | select(.id == \"$mcp_id\")")
        if [ -z "$mcp_config" ]; then
            return 1
        fi
        
        # Extract useful information
        MCP_NAME=$(echo "$mcp_config" | jq -r '.name // ""')
        MCP_DESCRIPTION=$(echo "$mcp_config" | jq -r '.description // ""')
        MCP_AUTHOR=$(echo "$mcp_config" | jq -r '.author // ""')
        MCP_PACKAGER=$(echo "$mcp_config" | jq -r '.packager // ""')
        MCP_PACKAGE=$(echo "$mcp_config" | jq -r '.package_name // ""')
        MCP_PREREQUISITES=$(echo "$mcp_config" | jq -r '.prerequisites[]' 2>/dev/null | tr '\n' ',' | sed 's/,$//')
        
        log_verbose "Found MCP: $MCP_NAME by $MCP_AUTHOR"
    else
        log_verbose "jq not found, using basic parsing"
        # Basic parsing without jq (less reliable but works for simple cases)
        MCP_NAME=$(echo "$config_json" | grep -A10 "\"id\".*\"$mcp_id\"" | grep '"name"' | head -1 | sed 's/.*"name".*:.*"\([^"]*\)".*/\1/')
        MCP_PACKAGER=$(echo "$config_json" | grep -A10 "\"id\".*\"$mcp_id\"" | grep '"packager"' | head -1 | sed 's/.*"packager".*:.*"\([^"]*\)".*/\1/')
        MCP_PACKAGE=$(echo "$config_json" | grep -A10 "\"id\".*\"$mcp_id\"" | grep '"package_name"' | head -1 | sed 's/.*"package_name".*:.*"\([^"]*\)".*/\1/')
        MCP_PREREQUISITES=$(echo "$config_json" | grep -A20 "\"id\".*\"$mcp_id\"" | grep '"prerequisites"' -A5 | grep '"' | grep -v 'prerequisites' | sed 's/.*"\([^"]*\)".*/\1/' | tr '\n' ',' | sed 's/,$//')
        
        if [ -z "$MCP_NAME" ]; then
            return 1
        fi
        
        log_verbose "Found MCP: $MCP_NAME"
    fi
    
    return 0
}

# Try to fetch MCP config from marketplace (optional - continue even if it fails)
if fetch_mcp_config "$MCP_ID"; then
    log_verbose "Using marketplace configuration for $MCP_NAME"
else
    log_verbose "Continuing with local script configuration"
fi

# Path to specific MCP script
MCP_SCRIPT="$BASE_URL/tools/mcp/$MCP_ID.sh"

# Extract prerequisites - prefer marketplace config, fallback to script
if [ -n "$MCP_PREREQUISITES" ]; then
    PREREQS="$MCP_PREREQUISITES"
    log_verbose "Using prerequisites from marketplace: $PREREQS"
else
    PREREQS=$(curl -fsSL "$MCP_SCRIPT" 2>/dev/null | grep "^# command_preq:" | sed 's/# command_preq: //')
    log_verbose "Using prerequisites from script: $PREREQS"
fi

if [ -z "$PREREQS" ]; then
    output_json "false" "No prerequisites found for $MCP_ID"
    exit 1
fi

log_verbose "Prerequisites for $MCP_ID: $PREREQS"

# Environment check script URL
ENV_CHECK_URL="$BASE_URL/tools/environment-check.sh"

# Function to check if a command exists using environment-check.sh
check_command() {
    local cmd="$1"
    local min_version="${2:-}"  # Optional minimum version
    local check_result=""
    
    log_verbose "Checking $cmd with environment-check.sh..."
    
    # Use environment-check.sh to check the command
    if [ -n "$min_version" ]; then
        check_result=$(bash -c "$(curl -fsSL "$ENV_CHECK_URL")" -- --command="$cmd" --min-version="$min_version" 2>/dev/null)
    else
        check_result=$(bash -c "$(curl -fsSL "$ENV_CHECK_URL")" -- --command="$cmd" 2>/dev/null)
    fi
    
    # Check if the command returned success (exit code 0)
    if [ $? -eq 0 ]; then
        # Parse the JSON result if we have jq
        if command -v jq &> /dev/null && [ -n "$check_result" ]; then
            local status=$(echo "$check_result" | jq -r '.status // "unknown"')
            local version=$(echo "$check_result" | jq -r '.current_version // "unknown"')
            local message=$(echo "$check_result" | jq -r '.message // ""')
            
            if [ "$status" = "ready" ]; then
                log_verbose "$cmd is ready (version: $version)"
                return 0
            else
                log_verbose "Status: $message"
                return 1
            fi
        else
            # Fallback: just check exit code
            return 0
        fi
    else
        return 1
    fi
}

# Function to install dependency
install_dependency() {
    local dep="$1"
    local url=""
    
    case "$dep" in
        node)
            url="$URL_NODE"
            log_verbose "Installing Node.js..."
            ;;
        python)
            url="$URL_PYTHON"
            log_verbose "Installing Python..."
            ;;
        uv)
            url="$URL_UV"
            log_verbose "Installing uv..."
            ;;
        *)
            return 1
            ;;
    esac
    
    # Download and execute installer (FREVANA_HOME already exported)
    local install_result=""
    if command -v curl &> /dev/null; then
        install_result=$(bash -c "$(curl -fsSL "$url")" 2>/dev/null)
    elif command -v wget &> /dev/null; then
        install_result=$(bash -c "$(wget -qO- "$url")" 2>/dev/null)
    else
        return 1
    fi
    
    # Check if installation was successful
    local exit_code=$?
    
    # Try to parse JSON result if available and valid
    if command -v jq &> /dev/null && [ -n "$install_result" ]; then
        # Check if the result is valid JSON
        if echo "$install_result" | jq empty >/dev/null 2>&1; then
            local success=$(echo "$install_result" | jq -r '.success // false' 2>/dev/null)
            if [ "$success" = "true" ]; then
                # Add to installed dependencies list
                if [ -z "$INSTALLED_DEPENDENCIES" ]; then
                    INSTALLED_DEPENDENCIES="$dep"
                else
                    INSTALLED_DEPENDENCIES="$INSTALLED_DEPENDENCIES,$dep"
                fi
                return 0
            else
                return 1
            fi
        else
            # Not valid JSON, fallback to exit code
            log_verbose "Non-JSON output from $dep installer, using exit code"
            if [ $exit_code -eq 0 ]; then
                if [ -z "$INSTALLED_DEPENDENCIES" ]; then
                    INSTALLED_DEPENDENCIES="$dep"
                else
                    INSTALLED_DEPENDENCIES="$INSTALLED_DEPENDENCIES,$dep"
                fi
                return 0
            else
                return 1
            fi
        fi
    else
        # Fallback: check exit code
        if [ $exit_code -eq 0 ]; then
            if [ -z "$INSTALLED_DEPENDENCIES" ]; then
                INSTALLED_DEPENDENCIES="$dep"
            else
                INSTALLED_DEPENDENCIES="$INSTALLED_DEPENDENCIES,$dep"
            fi
            return 0
        else
            return 1
        fi
    fi
}

# Check and install prerequisites
FAILED_DEPENDENCIES=""
IFS=',' read -ra PREREQ_ARRAY <<< "$PREREQS"
for prereq in "${PREREQ_ARRAY[@]}"; do
    # Trim whitespace
    prereq=$(echo "$prereq" | xargs)
    
    log_verbose "Checking for $prereq..."
    
    # Map prerequisite to actual command and minimum version to check
    check_cmd=""
    min_version=""
    
    case "$prereq" in
        node)
            check_cmd="node"
            min_version="18.0.0"
            ;;
        python)
            check_cmd="python3"
            min_version=""
            ;;
        uv)
            check_cmd="uv"
            min_version=""
            ;;
        *)
            FAILED_DEPENDENCIES="$FAILED_DEPENDENCIES,unknown:$prereq"
            continue
            ;;
    esac
    
    # Check command with minimum version if specified
    if [ -n "$min_version" ]; then
        if check_command "$check_cmd" "$min_version"; then
            log_verbose "$prereq is installed"
        else
            log_verbose "$prereq is not installed or version requirement not met"
            
            if [ "$INSTALL_FLAG" = true ]; then
                log_verbose "Installing $prereq..."
                if install_dependency "$prereq"; then
                    log_verbose "$prereq installed successfully"
                else
                    if [ -z "$FAILED_DEPENDENCIES" ]; then
                        FAILED_DEPENDENCIES="$prereq"
                    else
                        FAILED_DEPENDENCIES="$FAILED_DEPENDENCIES,$prereq"
                    fi
                fi
            else
                if [ -z "$FAILED_DEPENDENCIES" ]; then
                    FAILED_DEPENDENCIES="$prereq"
                else
                    FAILED_DEPENDENCIES="$FAILED_DEPENDENCIES,$prereq"
                fi
            fi
        fi
    else
        if check_command "$check_cmd"; then
            log_verbose "$prereq is installed"
        else
            log_verbose "$prereq is not installed"
            
            if [ "$INSTALL_FLAG" = true ]; then
                log_verbose "Installing $prereq..."
                if install_dependency "$prereq"; then
                    log_verbose "$prereq installed successfully"
                else
                    if [ -z "$FAILED_DEPENDENCIES" ]; then
                        FAILED_DEPENDENCIES="$prereq"
                    else
                        FAILED_DEPENDENCIES="$FAILED_DEPENDENCIES,$prereq"
                    fi
                fi
            else
                if [ -z "$FAILED_DEPENDENCIES" ]; then
                    FAILED_DEPENDENCIES="$prereq"
                else
                    FAILED_DEPENDENCIES="$FAILED_DEPENDENCIES,$prereq"
                fi
            fi
        fi
    fi
done

# Check if any dependencies failed
if [ -n "$FAILED_DEPENDENCIES" ]; then
    if [ "$INSTALL_FLAG" = true ]; then
        output_json "false" "Failed to install dependencies: $FAILED_DEPENDENCIES"
    else
        output_json "false" "Missing dependencies: $FAILED_DEPENDENCIES. Use --install flag to install automatically"
    fi
    exit 1
fi

log_verbose "All prerequisites satisfied."

# Execute the MCP script only if --install flag is provided
if [ "$INSTALL_FLAG" = true ]; then
    log_verbose "Running MCP installation script..."
    mcp_install_result=""
    if command -v curl &> /dev/null; then
        mcp_install_result=$(bash -c "$(curl -fsSL "$MCP_SCRIPT")" 2>/dev/null)
    elif command -v wget &> /dev/null; then
        mcp_install_result=$(bash -c "$(wget -qO- "$MCP_SCRIPT")" 2>/dev/null)
    else
        output_json "false" "Neither curl nor wget found. Cannot download MCP script"
        exit 1
    fi
    
    # Check if MCP installation was successful
    if [ $? -eq 0 ]; then
        output_json "true" "MCP $MCP_ID installed successfully" "$MCP_ID" "$MCP_NAME" "$INSTALLED_DEPENDENCIES" "$FREVANA_HOME"
    else
        output_json "false" "Failed to install MCP $MCP_ID"
        exit 1
    fi
else
    output_json "true" "Prerequisites check completed. Use --install to run MCP installation" "$MCP_ID" "$MCP_NAME" "" "$FREVANA_HOME"
fi