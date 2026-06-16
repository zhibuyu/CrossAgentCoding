# CrossAgnetCoding 跨平台构建指南

## 概述

CrossAgnetCoding 是一个 PowerShell 脚本项目，在不同平台上以不同方式分发：

| 平台 | 分发方式 | 说明 |
|------|---------|------|
| **Windows** | `.exe` (IExpress) | 使用 `scripts/build.ps1` 打包 |
| **macOS** | `.app` bundle | 使用 `scripts/build-macos.sh` 打包 |
| **Linux** | Shell 启动脚本 | 使用 `scripts/build-linux.sh` 打包 |

## macOS 构建

### 前置依赖

```bash
# 安装 PowerShell 7+
brew install powershell

# 安装 Node.js（运行时依赖）
brew install node@20
```

### 构建步骤

```bash
cd CrossAgnetCoding
bash scripts/build-macos.sh
```

构建产物：
- `release/CrossAgnetCoding.app` — macOS 应用程序包（双击启动 TUI 模式）
- `release/crossagnetcoding` — CLI 启动脚本

### 安装到系统

```bash
# 安装 .app 到 Applications
cp -R release/CrossAgnetCoding.app /Applications/

# 安装 CLI 命令（可选）
sudo ln -sf "$(pwd)/release/crossagnetcoding" /usr/local/bin/crossagnetcoding
```

### 使用方式

```bash
# CLI 模式
crossagnetcoding -Cli env tools
crossagnetcoding -Cli agents scan
crossagnetcoding -Cli agents configure

# TUI 模式（文本界面）
crossagnetcoding -Tui

# 自检
crossagnetcoding -SelfTest

# 或直接双击 /Applications/CrossAgnetCoding.app
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
- 生成启动脚本 `launcher.sh` 作为 CFBundleExecutable
- 生成 CLI 启动器 `crossagnetcoding`
- 自动生成应用图标（紫色圆形渐变）

### `scripts/build-linux.sh` (Linux)
- 创建 CLI 启动脚本
- 生成 `.desktop` 文件用于桌面集成

## 注意事项

1. **GUI 仅限 Windows**：WinForms GUI 仅在 Windows 上可用。macOS/Linux 下自动使用 TUI 模式。
2. **PowerShell 版本**：需要 PowerShell 7+（`pwsh`），Windows 上也可使用内置的 PowerShell 5.1。
3. **Node.js**：运行时依赖，用于 AgentMemory 和 iii-engine。
4. **架构支持**：x64 和 ARM64（Apple Silicon）均支持。
