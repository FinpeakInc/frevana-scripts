# Frevana Environment Scripts

一套用于自动检查和安装开发环境依赖的脚本系统，专为Frevana MCP客户端设计。

## 🚀 快速开始

### 环境检查

检查系统是否有所需的工具和版本：

```bash
# 检查Python环境
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/environment-check.sh)" -- --command="python" --min-version="3.10.0" --verbose

# 检查Node.js环境
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/environment-check.sh)" -- --command="node" --min-version="18.0.0" --verbose

# 检查npm环境
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/environment-check.sh)" -- --command="npm" --min-version="8.0.0"
```

### 自动安装

如果检查发现缺失或版本过低，使用以下命令自动安装：

```bash
# 安装Python（自动安装Homebrew如果需要）
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-python.sh)" -- --min-version="3.12.0"

# 安装Node.js（自动安装Homebrew如果需要）
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-node.sh)" -- --min-version="20.0.0"

# 只安装Homebrew
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-homebrew.sh)"
```

## 📋 详细功能

### 环境检查 (environment-check.sh)

**用途**: 检查开发工具是否安装以及版本是否满足要求

**参数**:
- `--command`: **必需** - 要检查的命令 (`python`, `node`, `npm`, `pip`, `git`, 等)
- `--min-version`: 可选 - 最低版本要求 (例如: `3.10.0`, `18.0.0`)
- `--package-manager`: 可选 - 包管理器类型 (`pip`, `npm`, `direct`)
- `--verbose`: 可选 - 显示详细检查过程

**返回值**: JSON格式的检查结果，包含状态、当前版本、安装URL等信息

**示例**:
```bash
# 基础检查
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/environment-check.sh)" -- --command="python"

# 版本要求检查
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/environment-check.sh)" -- --command="node" --min-version="18.0.0"

# 详细模式
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/environment-check.sh)" -- --command="python" --min-version="3.11.0" --verbose
```

**返回结果示例**:
```json
[{
  "command": "python",
  "status": "missing",
  "current_version": "",
  "required_version": "3.10.0",
  "message": "python not found in FREVANA_HOME (system version exists but not used)",
  "install_url": "https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-python.sh",
  "command_path": ""
}]
```

**如果已安装到FREVANA_HOME**:
```json
[{
  "command": "python",
  "status": "ready",
  "current_version": "3.12.11",
  "required_version": "3.10.0",
  "message": "python 3.12.11 meets requirements (>= 3.10.0)",
  "install_url": "",
  "command_path": "/Users/user/.frevana/bin/python"
}]
```

### Python安装 (install-python.sh)

**用途**: 自动安装Python，支持版本选择和依赖管理

**参数**:
- `--min-version`: 可选 - 最低版本要求，脚本会选择合适的Python版本

**版本选择逻辑**:
- `3.13.x` 或更高 → 安装 `python@3.13` (如果可用，否则回退到3.12)
- `3.12.x` → 安装 `python@3.12`
- `3.11.x` → 安装 `python@3.11`
- 其他或未指定 → 安装 `python@3.12` (默认稳定版)

**示例**:
```bash
# 安装默认版本 (3.12)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-python.sh)"

# 安装满足特定版本要求的Python
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-python.sh)" -- --min-version="3.12.0"
```

### Node.js安装 (install-node.sh)

**用途**: 自动安装Node.js，支持版本选择和依赖管理

**参数**:
- `--min-version`: 可选 - 最低版本要求，脚本会选择合适的Node.js版本

**版本选择逻辑**:
- `22.x` 或更高 → 安装 `node@22`
- `20.x-21.x` → 安装 `node@20`
- `18.x-19.x` → 安装 `node@18`
- `16.x-17.x` → 安装 `node@16`
- 其他或未指定 → 安装最新版 `node`

**示例**:
```bash
# 安装最新版本
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-node.sh)"

# 安装满足特定版本要求的Node.js
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-node.sh)" -- --min-version="20.0.0"
```

### Homebrew安装 (install-homebrew.sh)

**用途**: 安装独立的Homebrew实例到Frevana环境中

**特点**:
- 完全隔离的安装，不影响系统Homebrew
- 自动检测平台架构 (ARM64/x64)
- 支持环境变量配置

**示例**:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-homebrew.sh)"
```

## 🛠 开发者集成

### 在应用中使用

#### 1. 环境检查集成

```javascript
// Node.js 示例
const { exec } = require('child_process');

function checkEnvironment(command, minVersion) {
    return new Promise((resolve, reject) => {
        const checkScript = `bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/environment-check.sh)" -- --command="${command}" --min-version="${minVersion}"`;
        
        exec(checkScript, (error, stdout, stderr) => {
            if (error) {
                reject(new Error(`Environment check failed: ${error.message}`));
                return;
            }
            
            try {
                const result = JSON.parse(stdout);
                resolve(result[0]); // 返回主命令的检查结果
            } catch (parseError) {
                reject(new Error(`Failed to parse check result: ${parseError.message}`));
            }
        });
    });
}

// 使用示例
async function ensurePython() {
    try {
        const result = await checkEnvironment('python', '3.10.0');
        
        if (result.status === 'ready') {
            console.log(`✅ Python ${result.current_version} is ready`);
            return result.command_path;
        } else if (result.status === 'missing' || result.status === 'outdated') {
            console.log(`⚠️ ${result.message}`);
            console.log(`Installing Python via: ${result.install_url}`);
            
            // 自动安装
            await installPython('3.10.0');
            return await ensurePython(); // 重新检查
        }
    } catch (error) {
        console.error('Python environment check failed:', error);
        throw error;
    }
}
```

#### 2. 自动安装集成

```javascript
function installPython(minVersion) {
    return new Promise((resolve, reject) => {
        const installScript = `bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-python.sh)" -- --min-version="${minVersion}"`;
        
        exec(installScript, (error, stdout, stderr) => {
            if (error) {
                reject(new Error(`Python installation failed: ${error.message}`));
                return;
            }
            
            console.log('✅ Python installation completed');
            resolve();
        });
    });
}

function installNode(minVersion) {
    return new Promise((resolve, reject) => {
        const installScript = `bash -c "$(curl -fsSL https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/install-node.sh)" -- --min-version="${minVersion}"`;
        
        exec(installScript, (error, stdout, stderr) => {
            if (error) {
                reject(new Error(`Node.js installation failed: ${error.message}`));
                return;
            }
            
            console.log('✅ Node.js installation completed');
            resolve();
        });
    });
}
```

#### 3. 环境隔离配置

```javascript
// 在应用启动时设置PATH，优先使用Frevana工具
const os = require('os');
const path = require('path');

function setupFrevanaEnvironment() {
    const frevanaHome = process.env.FREVANA_HOME || path.join(os.homedir(), '.frevana');
    const frevanaBin = path.join(frevanaHome, 'bin');
    
    // 将Frevana工具路径添加到PATH最前面
    process.env.PATH = `${frevanaBin}:${process.env.PATH}`;
    
    console.log(`🔧 Frevana environment configured: ${frevanaHome}`);
    console.log(`📦 Tools available in: ${frevanaBin}`);
}

// 应用启动时调用
setupFrevanaEnvironment();

// 现在可以直接使用工具
const { exec } = require('child_process');
exec('python --version', (error, stdout) => {
    if (!error) {
        console.log(`Using Python: ${stdout.trim()}`);
    }
});
```

### 支持的依赖包检查

脚本支持检查各种依赖包的安装状态：

```bash
# 检查依赖包 (指定包管理器)
bash -c "$(curl -fsSL .../environment-check.sh)" -- --command="some-package" --package-manager="pip" --min-version="1.0.0"

bash -c "$(curl -fsSL .../environment-check.sh)" -- --command="some-package" --package-manager="npm" --min-version="2.0.0"
```

## 🔧 环境配置

### FREVANA_HOME

**默认路径**: `~/.frevana`

所有工具都会安装到 `$FREVANA_HOME/bin/` 目录下。可以通过环境变量自定义路径：

```bash
export FREVANA_HOME="/custom/path"
```

### 工具路径结构

```
~/.frevana/
├── bin/                    # 所有可执行文件的符号链接
│   ├── python -> python3.12
│   ├── pip -> pip3.12
│   ├── node -> node
│   ├── npm -> npm
│   └── brew -> homebrew/bin/brew
├── homebrew/              # 独立的Homebrew安装
├── Cellar/               # Homebrew包存储
└── Cache/                # 缓存文件
```

## 📦 支持的工具

| 工具 | 环境检查 | 自动安装 | 版本选择 | 自动链接 |
|------|----------|----------|----------|----------|
| Python | ✅ | ✅ | ✅ | ✅ |
| Node.js | ✅ | ✅ | ✅ | ✅ |
| npm | ✅ | ✅ (随Node.js) | ✅ | ✅ |
| pip | ✅ | ✅ (随Python) | ✅ | ✅ |
| Homebrew | ✅ | ✅ | ❌ | ✅ |
| git | ✅ | ❌ (系统工具) | ❌ | ❌ |
| curl | ✅ | ❌ (系统工具) | ❌ | ❌ |

## 🚨 注意事项

### 自动安装行为

- **所有安装脚本都会自动检查并安装Homebrew** (如果需要)
- **不需要用户手动干预** - 脚本会处理所有依赖关系
- **版本冲突处理** - 新安装会覆盖现有符号链接

### 平台支持

- **完全支持**: macOS (ARM64 + x64)
- **计划支持**: Linux, Windows

### 隔离特性

- **独立环境**: 不影响系统已安装的工具
- **可共存**: 与系统Python/Node.js完全隔离
- **纯净检查**: 只检查FREVANA_HOME中的工具，不自动链接系统工具
- **可控制**: 通过PATH设置控制优先级

## 🔍 故障排除

### 常见问题

1. **权限问题**
   ```bash
   # 确保有写入权限
   chmod +w ~/.frevana
   ```

2. **网络问题**
   ```bash
   # 检查网络连接
   curl -I https://raw.githubusercontent.com/FinpeakInc/frevana-scripts/refs/heads/master/tools/environment-check.sh
   ```

3. **路径问题**
   ```bash
   # 检查PATH设置
   echo $PATH | grep -o '[^:]*frevana[^:]*'
   ```

4. **清理环境**
   ```bash
   # 完全重置Frevana环境
   rm -rf ~/.frevana
   ```

### 调试模式

使用 `--verbose` 参数查看详细执行过程：

```bash
bash -c "$(curl -fsSL .../environment-check.sh)" -- --command="python" --verbose
```
