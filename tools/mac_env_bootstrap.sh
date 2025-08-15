#!/bin/bash

# MCP Client One-Click Installation Script
# For macOS systems

set -e  # Exit on any error

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
        
        # Wait for user to complete installation
        echo "Please complete the Xcode Command Line Tools installation in the popup window"
        echo "Press any key to continue after installation is complete..."
        read -n 1 -s
        
        # Verify installation
        if ! xcode-select -p &> /dev/null; then
            error "Xcode Command Line Tools installation failed"
            exit 1
        fi
    fi
    success "Xcode Command Line Tools installed"
}

# Check and install Homebrew
install_homebrew() {
    log "Checking Homebrew..."
    
    if ! command -v brew &> /dev/null; then
        log "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH (for Apple Silicon Macs)
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        
        # Verify installation
        if ! command -v brew &> /dev/null; then
            error "Homebrew installation failed"
            exit 1
        fi
    fi
    success "Homebrew installed"
}

# Install Node.js using Homebrew
install_nodejs() {
    log "Checking Node.js..."
    
    if ! command -v node &> /dev/null; then
        log "Installing Node.js..."
        brew install node
    else
        log "Node.js already installed, checking version..."
        NODE_VERSION=$(node --version)
        log "Current Node.js version: $NODE_VERSION"
        
        # Update to latest LTS if needed
        warn "Updating Node.js to latest version..."
        brew upgrade node || true
    fi
    
    # Verify installation
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
        NODE_VERSION=$(node --version)
        NPM_VERSION=$(npm --version)
        success "Node.js $NODE_VERSION and npm $NPM_VERSION installed"
    else
        error "Node.js installation verification failed"
        exit 1
    fi
}

# Install Python using Homebrew
install_python() {
    log "Checking Python..."
    
    # Install Python 3 if not available
    if ! command -v python3 &> /dev/null; then
        log "Installing Python 3..."
        brew install python
    else
        PYTHON_VERSION=$(python3 --version)
        log "Python already installed: $PYTHON_VERSION"
        
        # Update if needed
        warn "Updating Python to latest version..."
        brew upgrade python || true
    fi
    
    # Verify installation
    if command -v python3 &> /dev/null && command -v pip3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version)
        PIP_VERSION=$(pip3 --version | cut -d' ' -f2)
        success "Python 3 ($PYTHON_VERSION) and pip ($PIP_VERSION) installed"
    else
        error "Python installation verification failed"
        exit 1
    fi
}

# Install additional tools for MCP development
install_mcp_tools() {
    log "Installing MCP development tools..."
    
    # Install TypeScript globally
    log "Installing TypeScript..."
    npm install -g typescript
    
    # Install common MCP packages
    log "Installing MCP SDK and tools..."
    npm install -g @modelcontextprotocol/sdk
    
    # Install Python MCP package
    log "Installing Python MCP package..."
    pip3 install mcp
    
    # Install development tools
    log "Installing development utilities..."
    brew install git curl wget jq
    
    success "MCP development tools installed"
}

# Setup development environment
setup_dev_environment() {
    log "Setting up development environment..."
    
    # Create MCP projects directory
    MCP_DIR="$HOME/mcp-projects"
    if [ ! -d "$MCP_DIR" ]; then
        mkdir -p "$MCP_DIR"
        log "Created MCP projects directory: $MCP_DIR"
    fi
    
    # Create a sample MCP client project
    log "Creating sample MCP client project..."
    cd "$MCP_DIR"
    
    if [ ! -d "sample-mcp-client" ]; then
        mkdir sample-mcp-client
        cd sample-mcp-client
        
        # Initialize npm project
        npm init -y
        
        # Install MCP dependencies
        npm install @modelcontextprotocol/sdk
        npm install --save-dev typescript @types/node
        
        # Create basic TypeScript config
        cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF
        
        # Create source directory and sample file
        mkdir -p src
        cat > src/client.ts << 'EOF'
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';

// Sample MCP client implementation
class MCPClient {
  private client: Client;
  
  constructor() {
    const transport = new StdioClientTransport({
      command: 'node',
      args: ['path/to/your/server.js']
    });
    
    this.client = new Client({
      name: "sample-client",
      version: "1.0.0"
    }, {
      capabilities: {}
    });
  }
  
  async connect() {
    await this.client.connect(transport);
    console.log('Connected to MCP server');
  }
  
  async listTools() {
    const result = await this.client.listTools();
    console.log('Available tools:', result.tools);
    return result.tools;
  }
}

export default MCPClient;
EOF
        
        success "Sample MCP client project created in $MCP_DIR/sample-mcp-client"
    fi
}

# Print installation summary
print_summary() {
    echo
    echo "=================================================="
    echo -e "${GREEN}🎉 MCP Client Environment Setup Complete!${NC}"
    echo "=================================================="
    echo
    echo "Installed components:"
    echo "✅ Xcode Command Line Tools"
    echo "✅ Homebrew"
    echo "✅ Node.js $(node --version)"
    echo "✅ npm $(npm --version)"
    echo "✅ Python $(python3 --version | cut -d' ' -f2)"
    echo "✅ pip $(pip3 --version | cut -d' ' -f2)"
    echo "✅ TypeScript $(tsc --version | cut -d' ' -f2)"
    echo "✅ MCP SDK and tools"
    echo "✅ Development utilities (git, curl, wget, jq)"
    echo
    echo "Sample project location:"
    echo "📁 $HOME/mcp-projects/sample-mcp-client"
    echo
    echo "Next steps:"
    echo "1. cd ~/mcp-projects/sample-mcp-client"
    echo "2. npm run build (after setting up build script)"
    echo "3. Start developing your MCP client!"
    echo
    echo "For more information, visit:"
    echo "🔗 https://modelcontextprotocol.io"
    echo "=================================================="
}

# Main installation function
main() {
    echo "=================================================="
    echo "🚀 MCP Client Environment Installer"
    echo "=================================================="
    echo "This script will install and configure:"
    echo "• Xcode Command Line Tools"
    echo "• Homebrew"
    echo "• Node.js & npm"
    echo "• Python 3 & pip"
    echo "• MCP SDK and development tools"
    echo "• Sample MCP client project"
    echo
    echo "Press Enter to continue or Ctrl+C to cancel..."
    read
    
    # Run installation steps
    check_macos
    install_xcode_tools
    install_homebrew
    install_nodejs
    install_python
    install_mcp_tools
    setup_dev_environment
    print_summary
}

# Run main function
main "$@"