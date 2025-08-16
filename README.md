# Frevana Environment Scripts

一套用于自动检查和安装开发环境依赖的脚本系统。

## 🚀 环境检查

### environment-check.sh 参数

**必需参数:**
- `--command=COMMAND` - 要检查的工具名称

**可选参数:**
- `--min-version=VERSION` - 最低版本要求
- `--verbose` - 显示详细检查过程

```bash
# 检查Python
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/environment-check.sh)" -- --command="python3"

# 检查Node.js并要求最低版本
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/environment-check.sh)" -- --command="node" --min-version="18.0.0"

# 检查Homebrew（详细模式）
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/environment-check.sh)" -- --command="brew" --verbose

# 检查UV
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/environment-check.sh)" -- --command="uv"
```

## 📋 返回结果示例

```json
{
  "command": "python3",
  "status": "missing",
  "current_version": "",
  "required_version": "",
  "message": "python3 not found in FREVANA_HOME",
  "install_url": "https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-python.sh",
  "command_path": ""
}
```

## 🛠 下一步安装

根据返回的 `install_url`，运行对应的安装脚本：

### install-python.sh 参数

**可选参数:**
- `--min-version=VERSION` - 最低版本要求，用于选择合适的Python版本

```bash
# 安装默认Python版本
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-python.sh)"

# 安装满足特定版本要求的Python
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-python.sh)" -- --min-version="3.12.0"
```

### install-node.sh 参数

**可选参数:**
- `--min-version=VERSION` - 最低版本要求，用于选择合适的Node.js版本

```bash
# 安装最新Node.js版本
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-node.sh)"

# 安装满足特定版本要求的Node.js
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-node.sh)" -- --min-version="20.0.0"
```

### install-homebrew.sh 参数

**无参数** - 直接安装Homebrew

```bash
# 安装Homebrew
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-homebrew.sh)"
```

### install-uv.sh 参数

**无参数** - 直接安装UV

```bash
# 安装UV
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-uv.sh)"
```