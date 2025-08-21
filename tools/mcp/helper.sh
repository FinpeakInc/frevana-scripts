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

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_info() {
    echo -e "${YELLOW}$1${NC}"
}

# Function to display usage
usage() {
    echo "Usage: $0 --mcp-id=<MCP_ID> [--install]"
    echo ""
    echo "Options:"
    echo "  --mcp-id=<MCP_ID>   Required. The MCP ID to install/configure"
    echo "  --install           Optional. Install missing dependencies automatically"
    echo ""
    exit 1
}

# Parse command line arguments
MCP_ID=""
INSTALL_FLAG=false

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
        --help|-h)
            usage
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Check if MCP_ID is provided
if [ -z "$MCP_ID" ]; then
    print_error "MCP ID is required"
    usage
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
    print_info "FREVANA_HOME not set, using default: $FREVANA_HOME"
fi

# Export FREVANA_HOME so child processes can use it
export FREVANA_HOME

# Ensure FREVANA_HOME directories exist
mkdir -p "$FREVANA_HOME"/bin

print_info "Processing MCP: $MCP_ID"
print_info "FREVANA_HOME: $FREVANA_HOME"
print_info "Install flag: $INSTALL_FLAG"

# Function to fetch MCP configuration from marketplace
fetch_mcp_config() {
    local mcp_id="$1"
    local config_json=""
    
    print_info "Fetching MCP configuration from marketplace..."
    
    # Download the marketplace config
    if command -v curl &> /dev/null; then
        config_json=$(curl -fsSL "$MCP_MARKETPLACE_CONFIG" 2>/dev/null)
    elif command -v wget &> /dev/null; then
        config_json=$(wget -qO- "$MCP_MARKETPLACE_CONFIG" 2>/dev/null)
    else
        print_error "Neither curl nor wget found. Cannot fetch configuration."
        return 1
    fi
    
    if [ -z "$config_json" ]; then
        print_error "Failed to fetch marketplace configuration"
        return 1
    fi
    
    # Extract configuration for specific MCP ID using jq if available, otherwise use grep/sed
    if command -v jq &> /dev/null; then
        MCP_CONFIG=$(echo "$config_json" | jq ".[] | select(.id == \"$mcp_id\")")
        if [ -z "$MCP_CONFIG" ]; then
            print_error "MCP ID not found in marketplace: $mcp_id"
            return 1
        fi
        
        # Extract useful information
        MCP_NAME=$(echo "$MCP_CONFIG" | jq -r '.name // ""')
        MCP_DESCRIPTION=$(echo "$MCP_CONFIG" | jq -r '.description // ""')
        MCP_AUTHOR=$(echo "$MCP_CONFIG" | jq -r '.author // ""')
        MCP_PACKAGER=$(echo "$MCP_CONFIG" | jq -r '.packager // ""')
        MCP_PACKAGE=$(echo "$MCP_CONFIG" | jq -r '.package_name // ""')
        MCP_PREREQUISITES=$(echo "$MCP_CONFIG" | jq -r '.prerequisites[]' 2>/dev/null | tr '\n' ',' | sed 's/,$//')
        
        print_success "Found MCP: $MCP_NAME by $MCP_AUTHOR"
    else
        print_info "jq not found, using basic parsing"
        # Basic parsing without jq (less reliable but works for simple cases)
        MCP_NAME=$(echo "$config_json" | grep -A10 "\"id\".*\"$mcp_id\"" | grep '"name"' | head -1 | sed 's/.*"name".*:.*"\([^"]*\)".*/\1/')
        MCP_PACKAGER=$(echo "$config_json" | grep -A10 "\"id\".*\"$mcp_id\"" | grep '"packager"' | head -1 | sed 's/.*"packager".*:.*"\([^"]*\)".*/\1/')
        MCP_PACKAGE=$(echo "$config_json" | grep -A10 "\"id\".*\"$mcp_id\"" | grep '"package_name"' | head -1 | sed 's/.*"package_name".*:.*"\([^"]*\)".*/\1/')
        MCP_PREREQUISITES=$(echo "$config_json" | grep -A20 "\"id\".*\"$mcp_id\"" | grep '"prerequisites"' -A5 | grep '"' | grep -v 'prerequisites' | sed 's/.*"\([^"]*\)".*/\1/' | tr '\n' ',' | sed 's/,$//')
        
        if [ -z "$MCP_NAME" ]; then
            print_error "MCP ID not found in marketplace: $mcp_id"
            return 1
        fi
        
        print_success "Found MCP: $MCP_NAME"
    fi
    
    return 0
}

# Try to fetch MCP config from marketplace (optional - continue even if it fails)
if fetch_mcp_config "$MCP_ID"; then
    print_info "Using marketplace configuration for $MCP_NAME"
else
    print_info "Continuing with local script configuration"
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Path to specific MCP script
MCP_SCRIPT="$SCRIPT_DIR/$MCP_ID.sh"

# Check if MCP script exists
if [ ! -f "$MCP_SCRIPT" ]; then
    print_error "MCP script not found: $MCP_SCRIPT"
    print_error "Invalid MCP ID: $MCP_ID"
    exit 1
fi

# Extract prerequisites - prefer marketplace config, fallback to script
if [ -n "$MCP_PREREQUISITES" ]; then
    PREREQS="$MCP_PREREQUISITES"
    print_info "Using prerequisites from marketplace: $PREREQS"
else
    PREREQS=$(grep "^# command_preq:" "$MCP_SCRIPT" | sed 's/# command_preq: //')
    print_info "Using prerequisites from script: $PREREQS"
fi

if [ -z "$PREREQS" ]; then
    print_error "No prerequisites found for $MCP_ID"
    exit 1
fi

print_info "Prerequisites for $MCP_ID: $PREREQS"

# Environment check script URL
ENV_CHECK_URL="$BASE_URL/tools/environment-check.sh"

# Function to check if a command exists using environment-check.sh
check_command() {
    local cmd="$1"
    local min_version="${2:-}"  # Optional minimum version
    local check_result=""
    
    print_info "Checking $cmd with environment-check.sh..."
    
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
                print_success "✓ $cmd is ready (version: $version)"
                return 0
            else
                print_info "Status: $message"
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
            print_info "Installing Node.js..."
            ;;
        python)
            url="$URL_PYTHON"
            print_info "Installing Python..."
            ;;
        uv)
            url="$URL_UV"
            print_info "Installing uv..."
            ;;
        *)
            print_error "Unknown dependency: $dep"
            return 1
            ;;
    esac
    
    # Download and execute installer (FREVANA_HOME already exported)
    if command -v curl &> /dev/null; then
        bash -c "$(curl -fsSL "$url")"
    elif command -v wget &> /dev/null; then
        bash -c "$(wget -qO- "$url")"
    else
        print_error "Neither curl nor wget found. Cannot download installer."
        return 1
    fi
    
    return $?
}

# Check and install prerequisites
IFS=',' read -ra PREREQ_ARRAY <<< "$PREREQS"
for prereq in "${PREREQ_ARRAY[@]}"; do
    # Trim whitespace
    prereq=$(echo "$prereq" | xargs)
    
    print_info "Checking for $prereq..."
    
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
            print_error "Unknown prerequisite: $prereq"
            continue
            ;;
    esac
    
    # Check command with minimum version if specified
    if [ -n "$min_version" ]; then
        if check_command "$check_cmd" "$min_version"; then
            print_success "✓ $prereq is installed"
        else
            print_error "✗ $prereq is not installed or version requirement not met"
            
            if [ "$INSTALL_FLAG" = true ]; then
                print_info "Installing $prereq..."
                if install_dependency "$prereq"; then
                    print_success "✓ $prereq installed successfully"
                else
                    print_error "Failed to install $prereq"
                    exit 1
                fi
            else
                print_error "Please install $prereq or run with --install flag"
                exit 1
            fi
        fi
    else
        if check_command "$check_cmd"; then
            print_success "✓ $prereq is installed"
        else
            print_error "✗ $prereq is not installed"
            
            if [ "$INSTALL_FLAG" = true ]; then
                print_info "Installing $prereq..."
                if install_dependency "$prereq"; then
                    print_success "✓ $prereq installed successfully"
                else
                    print_error "Failed to install $prereq"
                    exit 1
                fi
            else
                print_error "Please install $prereq or run with --install flag"
                exit 1
            fi
        fi
    fi
done

print_info "All prerequisites satisfied. Running MCP script..."

# Execute the MCP script
if bash "$MCP_SCRIPT"; then
    print_success "✓ MCP $MCP_ID installed successfully!"
else
    print_error "Failed to install MCP $MCP_ID"
    exit 1
fi

print_success "Done!"