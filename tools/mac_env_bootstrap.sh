#!/bin/bash

# MCP Client One-Click Installation Script
# For macOS systems

set -e  # Exit on any error

# ================================
# MINIMUM VERSION REQUIREMENTS
# ================================
MIN_NODE_VERSION="18.0.0"
MIN_PYTHON_VERSION="3.8.0"
MIN_HOMEBREW_VERSION="3.0.0"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Version comparison function
version_ge() {
    printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        error "This script only supports macOS systems"
        exit 1
    fi
    success "Detected macOS system"
}

# Check and install Xcode Command Line Tools
install_xcode_tools() {
    log "Checking Xcode Command Line Tools..."
    
    if ! xcode-select -p &> /dev/null; then
        log "Installing Xcode Command Line Tools..."
        xcode-select --install
        
        echo "Please complete the Xcode Command Line Tools installation in the popup window"
        echo "Press any key to continue after installation is complete..."
        read -n 1 -s
        
        if ! xcode-select -p &> /dev/null; then
            error "Xcode Command Line Tools installation failed"
            exit 1
        fi
    fi
    success "Xcode Command Line Tools ready"
}

# Check and install Homebrew
install_homebrew() {
    log "Checking Homebrew..."
    
    if command -v brew &> /dev/null; then
        CURRENT_BREW_VERSION=$(brew --version | head -n1 | sed 's/Homebrew //')
        if version_ge "$CURRENT_BREW_VERSION" "$MIN_HOMEBREW_VERSION"; then
            success "Homebrew $CURRENT_BREW_VERSION meets requirements (>= $MIN_HOMEBREW_VERSION)"
            return
        else
            warn "Homebrew $CURRENT_BREW_VERSION is below minimum required version $MIN_HOMEBREW_VERSION"
            log "Updating Homebrew..."
            brew update
        fi
    else
        log "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH (for Apple Silicon Macs)
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zprofile
            export PATH="/usr/local/bin:$PATH"
        fi
        
        if ! command -v brew &> /dev/null; then
            error "Homebrew installation failed"
            exit 1
        fi
    fi
    success "Homebrew ready"
}

# Install Node.js using Homebrew
install_nodejs() {
    log "Checking Node.js..."
    
    if command -v node &> /dev/null; then
        CURRENT_NODE_VERSION=$(node --version | sed 's/v//')
        if version_ge "$CURRENT_NODE_VERSION" "$MIN_NODE_VERSION"; then
            success "Node.js $CURRENT_NODE_VERSION meets requirements (>= $MIN_NODE_VERSION)"
            return
        else
            warn "Node.js $CURRENT_NODE_VERSION is below minimum required version $MIN_NODE_VERSION"
        fi
    fi
    
    log "Installing/updating Node.js..."
    if brew list node &> /dev/null; then
        brew upgrade node
    else
        brew install node
    fi
    
    # Verify installation
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
        NODE_VERSION=$(node --version)
        NPM_VERSION=$(npm --version)
        success "Node.js $NODE_VERSION and npm $NPM_VERSION ready"
    else
        error "Node.js installation verification failed"
        exit 1
    fi
}

# Install Python using Homebrew
install_python() {
    log "Checking Python..."
    
    if command -v python3 &> /dev/null; then
        CURRENT_PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        if version_ge "$CURRENT_PYTHON_VERSION" "$MIN_PYTHON_VERSION"; then
            success "Python $CURRENT_PYTHON_VERSION meets requirements (>= $MIN_PYTHON_VERSION)"
            return
        else
            warn "Python $CURRENT_PYTHON_VERSION is below minimum required version $MIN_PYTHON_VERSION"
        fi
    fi
    
    log "Installing/updating Python..."
    if brew list python@3.12 &> /dev/null || brew list python &> /dev/null; then
        brew upgrade python || true
    else
        brew install python
    fi
    
    # Verify installation
    if command -v python3 &> /dev/null && command -v pip3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version)
        PIP_VERSION=$(pip3 --version | cut -d' ' -f2)
        success "Python ($PYTHON_VERSION) and pip ($PIP_VERSION) ready"
    else
        error "Python installation verification failed"
        exit 1
    fi
}

# Check if a command exists and is accessible
command_exists() {
    command -v "$1" &> /dev/null
}

# Install development tools (only if not present)
install_dev_tools() {
    log "Checking development tools..."
    
    TOOLS_TO_INSTALL=()
    
    # Check each tool individually
    if ! command_exists git; then
        TOOLS_TO_INSTALL+=("git")
    else
        log "git already installed: $(git --version | cut -d' ' -f3)"
    fi
    
    if ! command_exists curl; then
        TOOLS_TO_INSTALL+=("curl")
    else
        log "curl already installed: $(curl --version | head -n1 | cut -d' ' -f2)"
    fi
    
    if ! command_exists wget; then
        TOOLS_TO_INSTALL+=("wget")
    else
        log "wget already installed: $(wget --version | head -n1 | cut -d' ' -f3)"
    fi
    
    if ! command_exists jq; then
        TOOLS_TO_INSTALL+=("jq")
    else
        log "jq already installed: $(jq --version | sed 's/jq-//')"
    fi
    
    # Install only missing tools
    if [ ${#TOOLS_TO_INSTALL[@]} -gt 0 ]; then
        log "Installing missing tools: ${TOOLS_TO_INSTALL[*]}"
        brew install "${TOOLS_TO_INSTALL[@]}"
        success "Development tools installed"
    else
        success "All development tools already available"
    fi
}

# Install MCP-specific packages
install_mcp_packages() {
    log "Installing MCP packages..."
    
    # Check TypeScript
    if ! command_exists tsc; then
        log "Installing TypeScript globally..."
        npm install -g typescript
    else
        log "TypeScript already installed: $(tsc --version | cut -d' ' -f2)"
    fi
    
    # Check MCP SDK
    if ! npm list -g @modelcontextprotocol/sdk &> /dev/null; then
        log "Installing MCP SDK..."
        npm install -g @modelcontextprotocol/sdk
    else
        log "MCP SDK already installed"
    fi
    
    # Check Python MCP package
    if ! pip3 show mcp &> /dev/null; then
        log "Installing Python MCP package..."
        pip3 install mcp
    else
        log "Python MCP package already installed"
    fi
    
    success "MCP packages ready"
}

# Print installation summary
print_summary() {
    echo
    echo "=================================================="
    echo -e "${GREEN}🎉 MCP Client Environment Ready!${NC}"
    echo "=================================================="
    echo
    echo "Environment components:"
    if command_exists node; then
        echo "✅ Node.js $(node --version)"
        echo "✅ npm $(npm --version)"
    fi
    if command_exists python3; then
        echo "✅ Python $(python3 --version | cut -d' ' -f2)"
        echo "✅ pip $(pip3 --version | cut -d' ' -f2)"
    fi
    if command_exists tsc; then
        echo "✅ TypeScript $(tsc --version | cut -d' ' -f2)"
    fi
    echo "✅ MCP SDK installed"
    echo "✅ Development tools ready"
    echo
    echo "You can now start developing your MCP client!"
    echo
    echo "Quick start:"
    echo "1. mkdir my-mcp-client && cd my-mcp-client"
    echo "2. npm init -y"
    echo "3. npm install @modelcontextprotocol/sdk"
    echo
    echo "For more information:"
    echo "🔗 https://modelcontextprotocol.io"
    echo "=================================================="
}

# Main installation function
main() {
    echo "=================================================="
    echo "🚀 MCP Client Environment Installer"
    echo "=================================================="
    echo "Minimum requirements:"
    echo "• Node.js >= $MIN_NODE_VERSION"
    echo "• Python >= $MIN_PYTHON_VERSION"
    echo "• Homebrew >= $MIN_HOMEBREW_VERSION"
    echo
    echo "This installer will check existing installations"
    echo "and only install/upgrade what's necessary."
    echo
    echo "Press Enter to continue or Ctrl+C to cancel..."
    read
    
    # Run installation steps
    check_macos
    install_xcode_tools
    install_homebrew
    install_nodejs
    install_python
    install_dev_tools
    install_mcp_packages
    print_summary
}

# Run main function
main "$@"