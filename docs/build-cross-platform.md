# CrossAgnetCoding 跨平台构建指南

## 概述

CrossAgnetCoding 在不同平台上以**不同的实现与分发方式**分开打包：

| 平台 | 实现 | 分发方式 | 说明 |
|------|------|---------|------|
| **Windows** | PowerShell + WinForms (`src/AgentMemoryManager.ps1`) | `.exe` (IExpress) | 使用 `scripts/build.ps1` 打包 |
| **macOS** | 纯 Node.js (`macos/`) | `.app` + `.dmg` | 使用 `scripts/build-macos.sh` 打包，**不依赖 PowerShell** |
| **Linux** | Shell 启动脚本 | Shell 启动脚本 | 使用 `scripts/build-linux.sh` 打包 |

> macOS 版是独立的 Node.js 实现（零 npm 依赖），因为 Node 本就是 AgentMemory 的固有运行时依赖。这样用户无需安装 PowerShell。

## macOS 构建

### 前置依赖

```bash
# Node.js 仅为运行时依赖（用户首次启动若缺失会被引导安装）。
# 构建机本身不需要 Node 或 PowerShell——只用到系统自带的 sips / iconutil / hdiutil。
brew install node@20   # 可选（建议，用于本地测试 CLI）
```

### 构建步骤

```bash
cd CrossAgnetCoding
bash scripts/build-macos.sh
```

构建产物：
- `release/CrossAgnetCoding-0.0.1.dmg` — 拖入 Applications 即用的磁盘映像

### 安装到系统

```bash
open release/CrossAgnetCoding-0.0.1.dmg   # 挂载后把 CrossAgnetCoding.app 拖入 Applications
```

双击 .app：若无终端（Finder 启动）会自动用 Terminal.app 打开 TUI 菜单；若缺少 Node.js 则弹窗引导安装。

### 使用方式

```bash
# 直接双击 /Applications/CrossAgnetCoding.app  → TUI 菜单

# 或当作 CLI（同一份 Node 代码）：
node /Applications/CrossAgnetCoding.app/Contents/Resources/app/cac.mjs env tools
node .../cac.mjs agents scan
node .../cac.mjs agents configure
node .../cac.mjs start            # 启动 AgentMemory 服务
node .../cac.mjs --lang en mcp    # 复制 MCP 配置（英文界面）
```

## Linux 构建

### 前置依赖

```bash
# Ubuntu/Debian
sudo apt install powershell nodejs

# Fedora
sudo dnf install powershell nodejs
```

### 构建步骤

```bash
cd CrossAgnetCoding
bash scripts/build-linux.sh
```

构建产物：
- `release/crossagnetcoding` — CLI 启动脚本
- `release/CrossAgnetCoding.desktop` — 桌面入口文件

### 安装

```bash
sudo ln -sf "$(pwd)/release/crossagnetcoding" /usr/local/bin/crossagnetcoding
cp release/CrossAgnetCoding.desktop ~/.local/share/applications/
```

## 构建脚本说明

### `scripts/build.ps1` (Windows)
- 使用 Windows 内置 IExpress 工具将 PowerShell 脚本打包为 `.exe`
- 包含 `launch.vbs` 隐藏启动器，避免弹出命令行窗口
- 输出：`release/CrossAgnetCoding.exe`

### `scripts/build-macos.sh` (macOS)
- 创建标准 `.app` bundle 结构（Contents/MacOS/、Contents/Resources/、Info.plist）
- 把 `macos/`（`cac.mjs` + `lib/`）复制进 `Contents/Resources/app/`
- 生成 `launcher.sh`（CFBundleExecutable）与 `run-tui.command`：双击时用 Terminal.app 打开 TUI，缺 Node 时引导安装
- 用 `sips` + `iconutil` 从 `icon/_preview.png` 生成真实 `AppIcon.icns`
- 用 `hdiutil`（缺失时回退到 `scripts/mkdmgtool.py`）打包为 `.dmg`
- **不依赖 PowerShell**

### `scripts/build-linux.sh` (Linux)
- 创建 CLI 启动脚本
- 生成 `.desktop` 文件用于桌面集成

## 注意事项

1. **GUI 仅限 Windows**：WinForms GUI 仅在 Windows 上可用。macOS 使用 Node.js TUI；Linux 使用 PowerShell TUI。
2. **PowerShell**：仅 Windows / Linux 实现需要；**macOS 版为纯 Node.js，无需 PowerShell**。
3. **Node.js**：所有平台的运行时依赖（AgentMemory / iii-engine），macOS 版同时用它实现管理器本身。
4. **架构支持**：x64 和 ARM64（Apple Silicon）均支持；iii-engine 按架构下载对应的 `*-apple-darwin` 发行包。
