<p align="center">
  <img src="https://img.shields.io/badge/version-0.0.1-blue" alt="version">
  <img src="https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-0078D6" alt="platform">
  <img src="https://img.shields.io/badge/arch-x64%20%7C%20ARM64-orange" alt="arch">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="license">
  <img src="https://img.shields.io/badge/powershell-5.1%2B-5391FE" alt="powershell">
  <img src="https://img.shields.io/badge/MCP-compatible-purple" alt="MCP">
</p>

<h1 align="center">CrossAgentCoding</h1>

<p align="center">
  <a href="README.md">English</a> | <b>简体中文</b> | <a href="README.zh-TW.md">繁體中文</a>
</p>

<p align="center">
  <b>一份记忆，连接你所有的 AI 编码助手。</b><br>
  一键将持久化上下文共享给 Codex、TRAE、Claude、Gemini、OpenCode、OpenClaw、Hermes 等工具。
</p>

<p align="center">
  <a href="#快速开始">快速开始</a> &bull;
  <a href="#支持的编码工具">支持的编码工具</a> &bull;
  <a href="#工作原理">工作原理</a> &bull;
  <a href="#核心功能">核心功能</a> &bull;
  <a href="#构建">构建</a> &bull;
  <a href="#路线图">路线图</a>
</p>

---

## 它解决什么问题？

你可能同时使用多个 AI 编码工具（Codex、TRAE、Claude、Gemini 等）。每个工具的对话记忆互相隔离，换工具、换账号、重启后就丢失了之前讨论的目标、决策和约定。

**CrossAgentCoding 的做法：** 在本地启动一个 AgentMemory 服务（`http://localhost:3111`），通过 MCP（模型上下文协议）一键接入所有编码工具，让它们共享同一份持久化记忆——上下文在切换工具、切换账号、重启后依然保留。

> 灵感来源：[rohitg00/agentmemory](https://github.com/rohitg00/agentmemory)（持久化记忆）和 [farion1231/cc-switch](https://github.com/farion1231/cc-switch/)（多工具配置）。

---

## 快速开始

### Windows（预构建 EXE）

1. 从 [Releases](https://github.com/zhibuyu/CrossAgentCoding/releases) 下载 `CrossAgentCoding.exe`
2. 运行，点击 **安装全部** 安装 Node.js、AgentMemory 和 iii-engine
3. 点击 **启动服务**，等待显示 `运行中 (localhost:3111)`
4. 点击 **全部配置** 写入各工具的 MCP 配置
5. 重启你的编码工具，它们现在共享同一份记忆

### macOS / Linux（从源码运行）

```bash
# 先安装 PowerShell 7+ 和 Node.js
# macOS: brew install powershell node@20
# Linux: sudo apt install powershell nodejs

# 克隆并运行
git clone https://github.com/zhibuyu/CrossAgentCoding.git
cd CrossAgentCoding
pwsh ./src/AgentMemoryManager.ps1

# 或使用 CLI 模式
pwsh ./src/AgentMemoryManager.ps1 -Cli env tools
pwsh ./src/AgentMemoryManager.ps1 -Cli agents configure
```

> **注意：** macOS/Linux 下不支持 GUI，程序会自动以 CLI/TUI 模式运行。所有核心功能（安装、配置、桥接、记忆设置）均可通过命令行完成。

### Windows（从源码运行）

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\src\AgentMemoryManager.ps1
```

---

## 支持的编码工具

| 工具 | 配置路径 | 自动检测 | 一键配置 |
|-------|-------------|:-----------:|:----------------:|
| **Codex** | `~\.codex\config.toml` | ✅ | ✅ |
| **TRAE SOLO CN** | `%APPDATA%\TRAE SOLO CN\User\mcp.json` | ✅ | ✅ |
| **TRAE SOLO** | `%APPDATA%\TRAE SOLO\User\mcp.json` | ✅ | ✅ |
| **Qoder CN** | `%APPDATA%\QoderCN\SharedClientCache\mcp.json` | ✅ | ✅ |
| **Claude Code** | `~\.claude\mcp.json` | ✅ | ✅ |
| **Claude Desktop** | `%APPDATA%\Claude\claude_desktop_config.json` | ✅ | ✅ |
| **Gemini CLI** | `~\.gemini\settings.json` | ✅ | ✅ |
| **OpenCode** | `~\.config\opencode\opencode.json` | ✅ | ✅ |
| **OpenClaw** | `~\.openclaw\openclaw.json` | ✅ | ✅ |
| **Hermes Agent** | `~\.hermes\config.yaml` | ✅ | ✅ |

写入配置前会自动创建带时间戳的备份（`.bak-YYYYMMDDHHMMSS`）。

---

## 工作原理

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  Codex   │   │  TRAE    │   │  Claude  │   │  Gemini  │  ... 10 个工具
└────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘
     │              │              │              │
     └──────────────┼──────────────┼──────────────┘
                    │   MCP（模型上下文协议）
                    ▼
          ┌─────────────────────┐
          │  AgentMemory 服务    │  ← localhost:3111
          │  (REST + Streams)   │
          └──────────┬──────────┘
                     │
          ┌──────────▼──────────┐
          │    iii-engine        │  ← state_store + stream_store
          │  （嵌入式数据库）     │
          └─────────────────────┘
```

1. **iii-engine** — 嵌入式键值 + 事件流数据库（无需 Docker，无需外部数据库）
2. **AgentMemory** — REST API，支持混合检索（BM25 关键词 + 语义向量）
3. **MCP 层** — 所有工具连接到同一个 `localhost:3111` 端点

---

## 核心功能

### 🧠 共享记忆
所有工具读写同一份持久记忆。关键词 + 语义混合检索。零配置 BM25 模式开箱即用；可选本地 MiniLM 向量模型（约 90MB，纯 CPU）以获得更好的语义匹配效果。

### 🔌 一键 MCP 配置
自动检测已安装的编码工具并写入 MCP 配置。支持单个工具配置/重配置。提供可复制的 MCP JSON 和 CLI 命令用于手动设置。

### 📋 共享 Prompt 文件
生成 `AGENTS.md`、`CLAUDE.md`、`TRAE.md`、`GEMINI.md`、`OPENCODE.md`、`OPENCLAW.md`、`HERMES.md`——每个文件告诉对应工具如何使用共享记忆。

### 🌉 工作区桥接
将项目目录绑定到稳定的工作区 ID（路径 + Git 远程的 SHA256）。导入 Codex 和 TRAE 的有界会话片段。生成 `handoff.md` 交接摘要，确保上下文在切换工具/账号后依然保留。

### ⚙️ 记忆设置
- **向量检索**：BM25 纯关键词（默认）/ 本地 MiniLM / OpenAI 兼容 / Gemini / Voyage / Cohere
- **LLM**：OpenAI 兼容 / Anthropic / Gemini / OpenRouter / MiniMax（可选，用于更智能的压缩）
- **MCP 工具集**：核心（7 个工具）或全部（51 个工具）

### 📦 存储迁移
三类目录可独立迁移：CrossAgentCoding 数据目录、AgentMemory 记忆存储目录、模型缓存目录。支持 GUI 文件夹选择器或 CLI。

### 🖥️ GUI + CLI + TUI
完整的 WinForms 图形界面、PowerShell 命令行、文本界面三种模式。

### 🌐 记忆查看器
内置 Web 查看器（`http://localhost:3113`），用于浏览和管理记忆。

---

## 截图

<!-- TODO: 添加截图 -->
<p align="center">
  <i>截图即将上线——欢迎 PR！</i>
</p>

---

## 构建

### Windows（IExpress EXE）

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

使用 Windows 内置 IExpress 打包。输出：`release\CrossAgentCoding.exe`

### macOS / Linux

无需构建——直接从源码运行。如需创建启动脚本：

```bash
# 创建便捷启动器
cat > crossagentcoding << 'EOF'
#!/bin/bash
pwsh "$(dirname "$0")/src/AgentMemoryManager.ps1" "$@"
EOF
chmod +x crossagentcoding
./crossagentcoding -Cli env tools
```

## 测试

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\selftest.ps1
```

自测使用临时用户配置——不会触碰你的真实配置文件。

---

## 安全 —— 密钥只留本地

你在**记忆设置**里填的 API Key **只**保存在本机 `settings.json`（位于数据目录，如 `%USERPROFILE%\.CrossAgentCoding`，在仓库之外）。在 Windows 上它**加密存储**（DPAPI，绑定你的用户账户），仅在服务启动时于内存中解密使用。它**只**会发送给你配置的 LLM/Embedding 端点，**绝不**提交到 git。（旧的明文 Key 可用 `... -Cli memory encrypt` 迁移，或在记忆设置里重新保存一次即可。）

两道防线确保密钥不入库：

- **`.gitignore`** 屏蔽 `settings.json`、`.env*`、`*.local.json`、`*.key`、`*.secret` 等；
- **pre-commit 钩子**（`scripts/git-hooks/pre-commit`）在每次提交前扫描，拦截疑似 API Key（OpenAI / Anthropic / 智谱 …）。

克隆后启用钩子：

```bash
git config core.hooksPath scripts/git-hooks
```

确属误报时可用 `git commit --no-verify` 跳过。

---

## 项目结构

```
CrossAgentCoding/
├── src/
│   ├── AgentMemoryManager.ps1   # 主程序（GUI + 全部逻辑）
│   └── launch.vbs               # 隐藏启动器（无命令行窗口）
├── scripts/
│   └── build.ps1                # IExpress 构建脚本
├── tests/
│   └── selftest.ps1             # 无 UI 自测
├── docs/
│   ├── FUNCTIONS.md             # 开发者函数参考
│   └── superpowers/plans/       # 功能规划
├── release/                     # 构建产物（gitignored）
├── trae-mcp-config.json         # 独立 TRAE MCP 配置片段
└── README.md
```

---

## 路线图

- [x] 10 工具 MCP 配置（Codex、TRAE、Qoder、Claude、Gemini、OpenCode、OpenClaw、Hermes）
- [x] 共享 Prompt 文件生成
- [x] 工作区会话桥接（Codex + TRAE）
- [x] 记忆设置（向量检索、LLM、工具集）
- [x] 存储迁移（GUI + CLI）
- [x] CLI / TUI 模式
- [x] 启动诊断和端口冲突检测
- [ ] 截图和演示 GIF
- [ ] 服务商切换面板
- [ ] 用量 / 成本分析
- [ ] WebDAV / 云同步记忆备份
- [x] Linux 和 macOS 支持（CLI/TUI 模式）

---

## 参与贡献

欢迎提交 PR、Issue 和功能建议！详见 [CONTRIBUTING.md](CONTRIBUTING.md)（即将上线）。

## 许可证

MIT — 详见 [LICENSE](LICENSE)。

---

<p align="center">
  ⭐ 如果这个项目对你有帮助，请给个 Star！
</p>
