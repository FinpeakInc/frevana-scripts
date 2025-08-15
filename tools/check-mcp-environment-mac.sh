#!/bin/bash

# MCP Environment Check Script for macOS
# Checks current system status and reports what's missing
# 
# Usage: ./script.sh [--quiet] [--verbose]
#
# Output modes:
# - Default: JSON output only
# - --quiet: Silent mode, only exit code (0=success, 1=failure)
# - --verbose: Detailed logs and human-readable status report

set -e  # Exit on any error

# ================================
# MINIMUM VERSION REQUIREMENTS
# ================================
MIN_NODE_VERSION="18.0.0"
MIN_PYTHON_VERSION="3.8.0"
MIN_HOMEBREW_VERSION="3.0.0"

# Command line options
QUIET_MODE=false
VERBOSE_MODE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --quiet)
            QUIET_MODE=true
            shift
            ;;
        --verbose)
            VERBOSE_MODE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--quiet] [--verbose]"
            exit 1
            ;;
    esac
done

# Color definitions (only used in verbose mode)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Status tracking - using separate variables instead of associative array
MISSING_COMPONENTS=()
OUTDATED_COMPONENTS=()
READY_COMPONENTS=()
NEXT_ACTIONS=()

# Component status storage (compatible with older bash)
MACOS_STATUS=""
XCODE_TOOLS_STATUS=""
HOMEBREW_STATUS=""
NODEJS_STATUS=""
PYTHON_STATUS=""
GIT_STATUS=""
CURL_STATUS=""
WGET_STATUS=""
JQ_STATUS=""
MCP_SDK_STATUS=""
MCP_PYTHON_STATUS=""

# Logging functions (only for verbose mode)
log() {
    if [ "$VERBOSE_MODE" = true ]; then
        echo -e "${BLUE}[CHECK]${NC} $1"
    fi
}

success() {
    if [ "$VERBOSE_MODE" = true ]; then
        echo -e "${GREEN}[✓]${NC} $1"
    fi
}

warn() {
    if [ "$VERBOSE_MODE" = true ]; then
        echo -e "${YELLOW}[!]${NC} $1"
    fi
}

error() {
    if [ "$VERBOSE_MODE" = true ]; then
        echo -e "${RED}[✗]${NC} $1"
    fi
}

info() {
    if [ "$VERBOSE_MODE" = true ]; then
        echo -e "${CYAN}[INFO]${NC} $1"
    fi
}

# Version comparison function
version_ge() {
    printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

# Check if running on macOS
check_macos() {
    log "Checking macOS..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        success "Running on macOS"
        MACOS_STATUS='{"status":"ready","version":"'$(sw_vers -productVersion)'","message":"macOS detected"}'
    else
        error "This script only supports macOS systems"
        MACOS_STATUS='{"status":"missing","version":"","message":"Not running on macOS"}'
        if [ "$QUIET_MODE" = false ]; then
            exit 1
        fi
    fi
}

# Check Xcode Command Line Tools
check_xcode_tools() {
    log "Checking Xcode Command Line Tools..."
    
    if xcode-select -p &> /dev/null; then
        XCODE_PATH=$(xcode-select -p)
        success "Xcode Command Line Tools installed"
        XCODE_TOOLS_STATUS='{"status":"ready","version":"installed","path":"'$XCODE_PATH'","message":"Xcode Command Line Tools available"}'
        READY_COMPONENTS+=("Xcode Command Line Tools")
    else
        error "Xcode Command Line Tools not found"
        XCODE_TOOLS_STATUS='{"status":"missing","version":"","path":"","message":"Xcode Command Line Tools not installed"}'
        MISSING_COMPONENTS+=("Xcode Command Line Tools")
    fi
}

# Check Homebrew
check_homebrew() {
    log "Checking Homebrew..."
    
    if command -v brew &> /dev/null; then
        CURRENT_BREW_VERSION=$(brew --version | head -n1 | sed 's/Homebrew //')
        if version_ge "$CURRENT_BREW_VERSION" "$MIN_HOMEBREW_VERSION"; then
            success "Homebrew $CURRENT_BREW_VERSION"
            HOMEBREW_STATUS='{"status":"ready","version":"'$CURRENT_BREW_VERSION'","required":"'$MIN_HOMEBREW_VERSION'","message":"Homebrew meets requirements"}'
            READY_COMPONENTS+=("Homebrew")
        else
            warn "Homebrew $CURRENT_BREW_VERSION is outdated"
            HOMEBREW_STATUS='{"status":"outdated","version":"'$CURRENT_BREW_VERSION'","required":"'$MIN_HOMEBREW_VERSION'","message":"Homebrew version is below requirements"}'
            OUTDATED_COMPONENTS+=("Homebrew")
        fi
    else
        error "Homebrew not found"
        HOMEBREW_STATUS='{"status":"missing","version":"","required":"'$MIN_HOMEBREW_VERSION'","message":"Homebrew not installed"}'
        MISSING_COMPONENTS+=("Homebrew")
    fi
}

# Check Node.js
check_nodejs() {
    log "Checking Node.js..."
    
    if command -v node &> /dev/null; then
        CURRENT_NODE_VERSION=$(node --version | sed 's/v//')
        NPM_VERSION=""
        if command -v npm &> /dev/null; then
            NPM_VERSION=$(npm --version)
        fi
        
        if version_ge "$CURRENT_NODE_VERSION" "$MIN_NODE_VERSION"; then
            success "Node.js $CURRENT_NODE_VERSION"
            NODEJS_STATUS='{"status":"ready","version":"'$CURRENT_NODE_VERSION'","required":"'$MIN_NODE_VERSION'","npm_version":"'$NPM_VERSION'","message":"Node.js meets requirements"}'
            READY_COMPONENTS+=("Node.js")
        else
            warn "Node.js $CURRENT_NODE_VERSION is outdated"
            NODEJS_STATUS='{"status":"outdated","version":"'$CURRENT_NODE_VERSION'","required":"'$MIN_NODE_VERSION'","npm_version":"'$NPM_VERSION'","message":"Node.js version is below requirements"}'
            OUTDATED_COMPONENTS+=("Node.js")
        fi
    else
        error "Node.js not found"
        NODEJS_STATUS='{"status":"missing","version":"","required":"'$MIN_NODE_VERSION'","npm_version":"","message":"Node.js not installed"}'
        MISSING_COMPONENTS+=("Node.js")
    fi
}

# Check Python
check_python() {
    log "Checking Python..."
    
    if command -v python3 &> /dev/null; then
        CURRENT_PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        PIP_VERSION=""
        if command -v pip3 &> /dev/null; then
            PIP_VERSION=$(pip3 --version | cut -d' ' -f2)
        fi
        
        if version_ge "$CURRENT_PYTHON_VERSION" "$MIN_PYTHON_VERSION"; then
            success "Python $CURRENT_PYTHON_VERSION"
            PYTHON_STATUS='{"status":"ready","version":"'$CURRENT_PYTHON_VERSION'","required":"'$MIN_PYTHON_VERSION'","pip_version":"'$PIP_VERSION'","message":"Python meets requirements"}'
            READY_COMPONENTS+=("Python")
        else
            warn "Python $CURRENT_PYTHON_VERSION is outdated"
            PYTHON_STATUS='{"status":"outdated","version":"'$CURRENT_PYTHON_VERSION'","required":"'$MIN_PYTHON_VERSION'","pip_version":"'$PIP_VERSION'","message":"Python version is below requirements"}'
            OUTDATED_COMPONENTS+=("Python")
        fi
    else
        error "Python 3 not found"
        PYTHON_STATUS='{"status":"missing","version":"","required":"'$MIN_PYTHON_VERSION'","pip_version":"","message":"Python 3 not installed"}'
        MISSING_COMPONENTS+=("Python")
    fi
}

# Check development tools
check_dev_tools() {
    log "Checking development tools..."
    
    # Check git
    if command -v git &> /dev/null; then
        version=$(git --version | cut -d' ' -f3 | tr -d '\n')
        success "git $version"
        GIT_STATUS='{"status":"ready","version":"'$version'","message":"git available"}'
        READY_COMPONENTS+=("git")
    else
        error "git not found"
        GIT_STATUS='{"status":"missing","version":"","message":"git not installed"}'
        MISSING_COMPONENTS+=("git")
    fi
    
    # Check curl
    if command -v curl &> /dev/null; then
        version=$(curl --version | head -n1 | cut -d' ' -f2 | tr -d '\n')
        success "curl $version"
        CURL_STATUS='{"status":"ready","version":"'$version'","message":"curl available"}'
        READY_COMPONENTS+=("curl")
    else
        error "curl not found"
        CURL_STATUS='{"status":"missing","version":"","message":"curl not installed"}'
        MISSING_COMPONENTS+=("curl")
    fi
    
    # Check wget
    if command -v wget &> /dev/null; then
        version=$(wget --version 2>/dev/null | head -n1 | cut -d' ' -f3 | tr -d '\n' 2>/dev/null || echo "unknown")
        success "wget $version"
        WGET_STATUS='{"status":"ready","version":"'$version'","message":"wget available"}'
        READY_COMPONENTS+=("wget")
    else
        error "wget not found"
        WGET_STATUS='{"status":"missing","version":"","message":"wget not installed"}'
        MISSING_COMPONENTS+=("wget")
    fi
    
    # Check jq
    if command -v jq &> /dev/null; then
        version=$(jq --version 2>/dev/null | sed 's/jq-//' | tr -d '\n' 2>/dev/null || echo "unknown")
        success "jq $version"
        JQ_STATUS='{"status":"ready","version":"'$version'","message":"jq available"}'
        READY_COMPONENTS+=("jq")
    else
        error "jq not found"
        JQ_STATUS='{"status":"missing","version":"","message":"jq not installed"}'
        MISSING_COMPONENTS+=("jq")
    fi
}

# Check MCP packages
check_mcp_packages() {
    log "Checking MCP packages..."
    
    # Check MCP SDK
    if command -v npm &> /dev/null && npm list -g @modelcontextprotocol/sdk &> /dev/null; then
        MCP_VERSION=$(npm list -g @modelcontextprotocol/sdk --depth=0 2>/dev/null | grep @modelcontextprotocol/sdk | sed 's/.*@modelcontextprotocol\/sdk@//' | cut -d' ' -f1 | tr -d '\n')
        success "MCP SDK $MCP_VERSION"
        MCP_SDK_STATUS='{"status":"ready","version":"'$MCP_VERSION'","message":"MCP SDK installed"}'
        READY_COMPONENTS+=("MCP SDK")
    else
        error "MCP SDK not found"
        MCP_SDK_STATUS='{"status":"missing","version":"","message":"MCP SDK not installed"}'
        MISSING_COMPONENTS+=("MCP SDK")
    fi
    
    # Check Python MCP package
    if command -v pip3 &> /dev/null && pip3 show mcp &> /dev/null; then
        MCP_PY_VERSION=$(pip3 show mcp | grep Version | cut -d' ' -f2 | tr -d '\n')
        success "Python MCP package $MCP_PY_VERSION"
        MCP_PYTHON_STATUS='{"status":"ready","version":"'$MCP_PY_VERSION'","message":"Python MCP package installed"}'
        READY_COMPONENTS+=("Python MCP")
    else
        error "Python MCP package not found"
        MCP_PYTHON_STATUS='{"status":"missing","version":"","message":"Python MCP package not installed"}'
        MISSING_COMPONENTS+=("Python MCP")
    fi
}

# Determine next actions
determine_next_actions() {
    # Check if system setup is needed
    if [[ "$XCODE_TOOLS_STATUS" == *"missing"* ]]; then
        NEXT_ACTIONS+=("setup_xcode_tools")
    fi
    
    # Check if MCP setup is needed
    if [[ "$HOMEBREW_STATUS" == *"missing"* ]] || [[ "$HOMEBREW_STATUS" == *"outdated"* ]] || \
       [[ "$NODEJS_STATUS" == *"missing"* ]] || [[ "$NODEJS_STATUS" == *"outdated"* ]] || \
       [[ "$PYTHON_STATUS" == *"missing"* ]] || [[ "$PYTHON_STATUS" == *"outdated"* ]] || \
       [[ "$GIT_STATUS" == *"missing"* ]] || [[ "$CURL_STATUS" == *"missing"* ]] || \
       [[ "$WGET_STATUS" == *"missing"* ]] || [[ "$JQ_STATUS" == *"missing"* ]] || \
       [[ "$MCP_SDK_STATUS" == *"missing"* ]] || [[ "$MCP_PYTHON_STATUS" == *"missing"* ]]; then
        NEXT_ACTIONS+=("install_mcp_support")
    fi
}

# Generate JSON output
output_json() {
    local overall_status="ready"
    
    if [ ${#MISSING_COMPONENTS[@]} -gt 0 ]; then
        overall_status="incomplete"
    elif [ ${#OUTDATED_COMPONENTS[@]} -gt 0 ]; then
        overall_status="needs_updates"
    fi
    
    # Build components JSON manually
    local components_json="{"
    components_json+="\"macos\":${MACOS_STATUS:-"{\"status\":\"unknown\",\"version\":\"\",\"message\":\"Not checked\"}"}"
    components_json+=",\"xcode_tools\":${XCODE_TOOLS_STATUS:-"{\"status\":\"unknown\",\"version\":\"\",\"message\":\"Not checked\"}"}"
    components_json+=",\"homebrew\":${HOMEBREW_STATUS:-"{\"status\":\"unknown\",\"version\":\"\",\"message\":\"Not checked\"}"}"
    components_json+=",\"nodejs\":${NODEJS_STATUS:-"{\"status\":\"unknown\",\"version\":\"\",\"message\":\"Not checked\"}"}"
    components_json+=",\"python\":${PYTHON_STATUS:-"{\"status\":\"unknown\",\"version\":\"\",\"message\":\"Not checked\"}"}"
    components_json+=",\"git\":${GIT_STATUS:-"{\"status\":\"unknown\",\"version\":\"\",\"message\":\"Not checked\"}"}"
    components_json+=",\"curl\":${CURL_STATUS:-"{\"status\":\"unknown\",\"version\":\"\",\"message\":\"Not checked\"}"}"
    components_json+=",\"wget\":${WGET_STATUS:-"{\"status\":\"unknown\",\"version\":\"\",\"message\":\"Not checked\"}"}"
    components_json+=",\"jq\":${JQ_STATUS:-"{\"status\":\"unknown\",\"version\":\"\",\"message\":\"Not checked\"}"}"
    components_json+=",\"mcp_sdk\":${MCP_SDK_STATUS:-"{\"status\":\"unknown\",\"version\":\"\",\"message\":\"Not checked\"}"}"
    components_json+=",\"mcp_python\":${MCP_PYTHON_STATUS:-"{\"status\":\"unknown\",\"version\":\"\",\"message\":\"Not checked\"}"}"
    components_json+="}"
    
    # Build next actions JSON
    local actions_json="["
    local first=true
    for action in "${NEXT_ACTIONS[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            actions_json+=","
        fi
        
        case $action in
            "setup_xcode_tools")
                actions_json+="{\"action\":\"setup_xcode_tools\",\"script\":\"setup-xcode-tools-mac.sh\",\"url\":\"https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/setup-xcode-tools-mac.sh\",\"description\":\"Install Xcode Command Line Tools\"}"
                ;;
            "install_mcp_support")
                actions_json+="{\"action\":\"install_mcp_support\",\"script\":\"install-mcp-support-mac.sh\",\"url\":\"https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-mcp-support-mac.sh\",\"description\":\"Install MCP runtime environment\"}"
                ;;
        esac
    done
    actions_json+="]"
    
    # Build summary arrays
    local ready_json="["
    first=true
    for component in "${READY_COMPONENTS[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            ready_json+=","
        fi
        ready_json+="\"$component\""
    done
    ready_json+="]"
    
    local missing_json="["
    first=true
    for component in "${MISSING_COMPONENTS[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            missing_json+=","
        fi
        missing_json+="\"$component\""
    done
    missing_json+="]"
    
    local outdated_json="["
    first=true
    for component in "${OUTDATED_COMPONENTS[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            outdated_json+=","
        fi
        outdated_json+="\"$component\""
    done
    outdated_json+="]"
    
    # Output final JSON
    cat << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "platform": "macos",
  "overall_status": "$overall_status",
  "requirements": {
    "node_version": "$MIN_NODE_VERSION",
    "python_version": "$MIN_PYTHON_VERSION",
    "homebrew_version": "$MIN_HOMEBREW_VERSION"
  },
  "components": $components_json,
  "summary": {
    "ready": $ready_json,
    "missing": $missing_json,
    "outdated": $outdated_json
  },
  "next_actions": $actions_json,
  "is_ready": $([ "$overall_status" = "ready" ] && echo "true" || echo "false")
}
EOF
}

# Print human-readable status report
print_status_report() {
    echo
    echo "=================================================="
    echo -e "${CYAN}📋 MCP Environment Status Report${NC}"
    echo "=================================================="
    echo
    
    # Ready components
    if [ ${#READY_COMPONENTS[@]} -gt 0 ]; then
        echo -e "${GREEN}✅ Ready Components:${NC}"
        for component in "${READY_COMPONENTS[@]}"; do
            echo "   ✓ $component"
        done
        echo
    fi
    
    # Outdated components
    if [ ${#OUTDATED_COMPONENTS[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Outdated Components:${NC}"
        for component in "${OUTDATED_COMPONENTS[@]}"; do
            echo "   ! $component (needs update)"
        done
        echo
    fi
    
    # Missing components
    if [ ${#MISSING_COMPONENTS[@]} -gt 0 ]; then
        echo -e "${RED}❌ Missing Components:${NC}"
        for component in "${MISSING_COMPONENTS[@]}"; do
            echo "   ✗ $component"
        done
        echo
    fi
    
    # Overall status
    if [ ${#MISSING_COMPONENTS[@]} -eq 0 ] && [ ${#OUTDATED_COMPONENTS[@]} -eq 0 ]; then
        echo -e "${GREEN}🎉 Environment Status: READY${NC}"
        echo "Your system is fully configured for MCP plugins!"
    elif [ ${#MISSING_COMPONENTS[@]} -gt 0 ]; then
        echo -e "${RED}⚠️  Environment Status: INCOMPLETE${NC}"
        echo "Some components are missing and need to be installed."
    else
        echo -e "${YELLOW}⚠️  Environment Status: NEEDS UPDATES${NC}"
        echo "Some components are outdated and should be updated."
    fi
    
    echo
    echo "=================================================="
    
    # Installation recommendations
    if [ ${#NEXT_ACTIONS[@]} -gt 0 ]; then
        echo -e "${BLUE}🔧 Recommended Actions:${NC}"
        echo
        
        local step=1
        for action in "${NEXT_ACTIONS[@]}"; do
            case $action in
                "setup_xcode_tools")
                    echo "$step. Run system setup (installs Xcode Command Line Tools):"
                    echo "   bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/setup-xcode-tools-mac.sh)\""
                    ;;
                "install_mcp_support")
                    echo "$step. Run MCP environment setup:"
                    echo "   bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-mcp-support-mac.sh)\""
                    ;;
            esac
            echo
            ((step++))
        done
        
        echo "=================================================="
    fi
}

# Main function
main() {
    if [ "$VERBOSE_MODE" = true ]; then
        echo "=================================================="
        echo "🔍 MCP Environment Check"
        echo "=================================================="
        echo "Scanning your system for MCP plugin requirements..."
        echo
    fi
    
    # Run all checks
    check_macos
    check_xcode_tools
    check_homebrew
    check_nodejs
    check_python
    check_dev_tools
    check_mcp_packages
    
    # Determine what actions are needed
    determine_next_actions
    
    # Output results based on mode
    if [ "$QUIET_MODE" = true ]; then
        # Only exit with appropriate code, no output
        if [ ${#MISSING_COMPONENTS[@]} -gt 0 ] || [ ${#OUTDATED_COMPONENTS[@]} -gt 0 ]; then
            exit 1
        else
            exit 0
        fi
    elif [ "$VERBOSE_MODE" = true ]; then
        print_status_report
    else
        # Default: output JSON
        output_json
    fi
}

# Run main function
main "$@"