# Frevana Environment Scripts

一套用于自动检查和安装开发环境依赖的脚本系统。

## 🚀 环境检查

检查系统是否有所需的工具：

```bash
# 检查Python
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/environment-check.sh)" -- --command="python3"

# 检查Node.js  
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/environment-check.sh)" -- --command="node"

# 检查Homebrew
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/environment-check.sh)" -- --command="brew"

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

```bash
# 安装Python
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-python.sh)"

# 安装Node.js
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-node.sh)"

# 安装Homebrew
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-homebrew.sh)"

# 安装UV
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-uv.sh)"
```