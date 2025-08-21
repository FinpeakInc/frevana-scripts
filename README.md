# Frevana Scripts

🚀 自动化开发环境配置和 MCP (Model Context Protocol) 服务器安装管理系统。

## 📦 核心功能

### MCP Helper - 主入口脚本

MCP Helper 是管理和安装 MCP 服务器的统一入口，支持自动解析依赖并安装。

```bash
# 检查并安装 MCP 服务器（仅检查依赖）
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/mcp/helper.sh)" -- --mcp-id=mcp_frevana_server-filesystem

# 检查并自动安装依赖和 MCP 服务器
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/mcp/helper.sh)" -- --mcp-id=mcp_frevana_server-filesystem --install

# 详细模式
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/mcp/helper.sh)" -- --mcp-id=mcp_frevana_slack-mcp-server --install --verbose

# 显示帮助信息
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/mcp/helper.sh)" -- --help
```

### 支持的 MCP 服务器

- **mcp_frevana_calendly-mcp** - Calendly 日历集成
- **mcp_frevana_chrome-automation** - Chrome 浏览器自动化
- **mcp_frevana_figma-developer-mcp** - Figma 设计工具 API
- **mcp_frevana_ga4-mcp-server** - Google Analytics 4 数据分析
- **mcp_frevana_google-workspace** - Google Workspace 工具套件
- **mcp_frevana_netlify-mcp** - Netlify 部署和管理
- **mcp_frevana_notion-api** - Notion 笔记和数据库
- **mcp_frevana_sentry-mcp** - Sentry 错误监控和追踪
- **mcp_frevana_server-filesystem** - 文件系统操作
- **mcp_frevana_slack-mcp-server** - Slack 消息和工作流
- **mcp_frevana_zoom-mcp-server** - Zoom 会议管理

## 🔧 环境依赖安装

所有安装脚本默认返回 JSON 格式，使用 `--verbose` 参数显示详细日志。

### Node.js 安装

使用 Node.js 官方独立二进制文件，无需系统包管理器。

```bash
# 默认安装（返回 JSON）
bash installers/install-node.sh

# 详细日志模式
bash installers/install-node.sh --verbose

# 指定最低版本
bash installers/install-node.sh --min-version=20.0.0

# 返回格式
{
  "success": true,
  "message": "Node.js installation completed successfully",
  "node_version": "v22.18.0",
  "npm_version": "10.9.3",
  "pnpm_version": "10.15.0",
  "install_path": "/Users/username/.frevana/bin"
}
```

### Python 安装

使用 python-build-standalone 提供的预编译二进制文件。

```bash
# 默认安装（返回 JSON）
bash installers/install-python.sh

# 详细日志模式
bash installers/install-python.sh --verbose

# 指定最低版本
bash installers/install-python.sh --min-version=3.11

# 返回格式
{
  "success": true,
  "message": "Python installation completed successfully",
  "python_version": "Python 3.12.11",
  "pip_version": "24.3.1",
  "install_path": "/Users/username/.frevana/bin"
}
```

### UV (Python 包管理器) 安装

```bash
# 安装 UV
bash installers/install-uv.sh
```

### Homebrew 安装

```bash
# 安装 Homebrew（隔离环境）
bash installers/install-homebrew.sh
```

## 🔍 环境检查工具

检查指定工具是否已安装并满足版本要求：

```bash
# 检查 Python
bash tools/environment-check.sh --command=python3

# 检查 Node.js 并要求最低版本
bash tools/environment-check.sh --command=node --min-version=18.0.0

# 详细模式
bash tools/environment-check.sh --command=brew --verbose

# 返回格式
{
  "command": "python3",
  "status": "missing",
  "current_version": "",
  "required_version": "",
  "message": "python3 not found in FREVANA_HOME",
  "install_url": "https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/installers/install-python.sh",
  "command_path": ""
}
```

## 📁 项目结构

```
frevana-scripts/
├── tools/
│   ├── mcp/
│   │   ├── helper.sh           # MCP 主入口脚本
│   │   └── scripts/            # MCP 服务器安装脚本
│   │       ├── filesystem.sh
│   │       ├── github.sh
│   │       └── ...
│   └── environment-check.sh    # 环境检查工具
├── installers/
│   ├── install-node.sh         # Node.js 独立安装
│   ├── install-python.sh       # Python 独立安装
│   ├── install-uv.sh          # UV 安装
│   └── install-homebrew.sh    # Homebrew 安装
└── README.md
```

## 🌍 环境变量

- `FREVANA_HOME` - Frevana 安装目录（默认：`~/.frevana`）
- 所有工具安装到 `$FREVANA_HOME/bin`
- 配置文件位于 `$FREVANA_HOME/config`

## 💡 特性

- **零依赖安装** - Node.js 和 Python 使用独立二进制文件
- **自动依赖解析** - MCP 服务器自动检测并安装所需依赖
- **统一 JSON 输出** - 所有脚本默认返回标准 JSON 格式
- **隔离环境** - 不影响系统全局配置
- **跨平台支持** - macOS、Linux、Windows (WSL)

## 🚀 快速开始

1. 安装 MCP 服务器：
```bash
curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/mcp/helper.sh | bash -s -- --mcp-id=mcp_frevana_server-filesystem --install
```

2. 检查环境：
```bash
curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/environment-check.sh | bash -s -- --command=node
```

3. 安装缺失依赖：
```bash
# 根据环境检查结果安装
curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/installers/install-node.sh | bash
```

## 📄 许可证

MIT License