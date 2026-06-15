<p align="center">
  <img src="https://img.shields.io/badge/version-0.0.1-blue" alt="version">
  <img src="https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-0078D6" alt="platform">
  <img src="https://img.shields.io/badge/arch-x64%20%7C%20ARM64-orange" alt="arch">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="license">
  <img src="https://img.shields.io/badge/powershell-5.1%2B-5391FE" alt="powershell">
  <img src="https://img.shields.io/badge/MCP-compatible-purple" alt="MCP">
</p>

<h1 align="center">CrossAgnetCoding</h1>

<p align="center">
  <b>English</b> | <a href="#简体中文">简体中文</a> | <a href="#繁體中文">繁體中文</a>
</p>

<p align="center">
  <b>One Memory. All Your AI Coding Agents.</b><br>
  Share persistent context across Codex, TRAE, Claude, Gemini, OpenCode, OpenClaw, Hermes &mdash; with one click.
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> &bull;
  <a href="#supported-agents">Supported Agents</a> &bull;
  <a href="#how-it-works">How It Works</a> &bull;
  <a href="#features">Features</a> &bull;
  <a href="#build">Build</a> &bull;
  <a href="#roadmap">Roadmap</a>
</p>

---

## What Problem Does This Solve?

You use multiple AI coding tools. Each tool has its own isolated memory. Switch tools, switch accounts, or restart &mdash; and all your project goals, decisions, and conventions are gone.

**CrossAgnetCoding fixes this.** It runs a local AgentMemory service (`http://localhost:3111`) and wires it into every coding agent you use via MCP (Model Context Protocol). All agents read and write to the **same persistent memory** &mdash; so context survives tool switches, account changes, and restarts.

> Inspired by [rohitg00/agentmemory](https://github.com/rohitg00/agentmemory) (persistent memory) and [farion1231/cc-switch](https://github.com/farion1231/cc-switch/) (multi-agent configuration).

---

## Quick Start

### Windows (Pre-built EXE)

1. **Download** `CrossAgnetCoding.exe` from [Releases](https://github.com/zhibuyu/CrossAgnetCoding/releases).
2. Run it. Click **Install All** to set up Node.js, AgentMemory, and iii-engine.
3. Click **Start Service** &mdash; wait for `Running (localhost:3111)`.
4. Click **Configure All** to write MCP configs to every detected agent.
5. Restart your coding tools. They now share memory.

### macOS / Linux (Run from Source)

```bash
# Install PowerShell 7+ and Node.js first
# macOS: brew install powershell node@20
# Linux: sudo apt install powershell nodejs

# Clone and run
git clone https://github.com/zhibuyu/CrossAgnetCoding.git
cd CrossAgnetCoding
pwsh ./src/AgentMemoryManager.ps1

# Or CLI mode
pwsh ./src/AgentMemoryManager.ps1 -Cli env tools
pwsh ./src/AgentMemoryManager.ps1 -Cli agents configure
```

> **Note:** On macOS/Linux, the GUI is not available &mdash; the app automatically runs in CLI/TUI mode. All core features (install, configure, bridge, memory settings) work via command line.

### Run from Source (Windows)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\src\AgentMemoryManager.ps1
```

---

## Supported Agents

| Agent | Config Path | Auto-Detect | One-Click Config |
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

All config writes create timestamped backups (`.bak-YYYYMMDDHHMMSS`) before modifying.

---

## How It Works

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  Codex   │   │  TRAE    │   │  Claude  │   │  Gemini  │  ... 10 agents
└────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘
     │              │              │              │
     └──────────────┼──────────────┼──────────────┘
                    │   MCP (Model Context Protocol)
                    ▼
          ┌─────────────────────┐
          │  AgentMemory Service │  ← localhost:3111
          │  (REST + Streams)    │
          └──────────┬──────────┘
                     │
          ┌──────────▼──────────┐
          │    iii-engine        │  ← state_store + stream_store
          │  (embedded database) │
          └─────────────────────┘
```

1. **iii-engine** &mdash; embedded key-value + event-stream database (no Docker, no external DB).
2. **AgentMemory** &mdash; REST API with hybrid search (BM25 keyword + semantic vector).
3. **MCP layer** &mdash; every agent connects to the same `localhost:3111` endpoint.

---

## Features

### 🧠 Shared Memory
All agents read/write to one persistent memory. Keyword + semantic hybrid search. Zero-config BM25 mode works out of the box; optional local MiniLM embedding (~90MB, CPU-only) for better semantic matching.

### 🔌 One-Click MCP Configuration
Detects installed agents and writes MCP configs automatically. Per-agent configure/reconfigure buttons. Copyable MCP JSON and CLI commands for manual setup.

### 📋 Shared Agent Prompts
Generates `AGENTS.md`, `CLAUDE.md`, `TRAE.md`, `GEMINI.md`, `OPENCODE.md`, `OPENCLAW.md`, `HERMES.md` &mdash; each telling its agent how to use the shared memory.

### 🌉 Workspace Bridge
Bind a project folder to a stable workspace ID (SHA256 of path + Git remote). Import bounded session snippets from Codex and TRAE. Generate `handoff.md` summaries so context survives tool/account switches.

### ⚙️ Memory Settings
- **Embedding**: BM25-only (default) / local MiniLM / OpenAI-compatible / Gemini / Voyage / Cohere
- **LLM**: OpenAI-compatible / Anthropic / Gemini / OpenRouter / MiniMax (optional, for smarter compression)
- **MCP tools**: core (7 tools) or all (51 tools)

### 📦 Storage Migration
Three independently migratable directories: CrossAgnetCoding data, AgentMemory memory store, and model cache. GUI folder picker or CLI.

### 🖥️ GUI + CLI + TUI
Full WinForms GUI, PowerShell CLI, and text-based TUI mode.

### 🌐 Memory Viewer
Built-in web viewer at `http://localhost:3113` for browsing and managing memories.

---

## Screenshots

<!-- TODO: add screenshots -->
<p align="center">
  <i>Screenshots coming soon &mdash; PRs welcome!</i>
</p>

---

## Build

### Windows (IExpress EXE)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

Uses Windows built-in IExpress. Output: `release\CrossAgnetCoding.exe`

### macOS / Linux

No build step needed &mdash; run directly from source. To create a wrapper script:

```bash
# Create a convenient launcher
cat > crossagnetcoding << 'EOF'
#!/bin/bash
pwsh "$(dirname "$0")/src/AgentMemoryManager.ps1" "$@"
EOF
chmod +x crossagnetcoding
./crossagnetcoding -Cli env tools
```

## Test

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\selftest.ps1
```

Self-test uses a temporary user profile &mdash; your real configs are never touched.

---

## Project Structure

```
CrossAgnetCoding/
├── src/
│   ├── AgentMemoryManager.ps1   # Main program (GUI + all logic)
│   └── launch.vbs               # Hidden launcher (no cmd window)
├── scripts/
│   └── build.ps1                # IExpress build script
├── tests/
│   └── selftest.ps1             # Non-UI self-test
├── docs/
│   ├── FUNCTIONS.md             # Developer function reference
│   └── superpowers/plans/       # Feature planning
├── release/                     # Build output (gitignored)
├── trae-mcp-config.json         # Standalone TRAE MCP snippet
└── README.md
```

---

## Roadmap

- [x] 10-agent MCP configuration (Codex, TRAE, Qoder, Claude, Gemini, OpenCode, OpenClaw, Hermes)
- [x] Shared prompt file generation
- [x] Workspace session bridge (Codex + TRAE)
- [x] Memory settings (embedding, LLM, tools)
- [x] Storage migration (GUI + CLI)
- [x] CLI / TUI modes
- [x] Startup diagnostics & port conflict detection
- [ ] Screenshots & demo GIF
- [ ] Provider switching dashboard
- [ ] Usage / cost analytics
- [ ] WebDAV / cloud sync for memory backup
- [x] Linux & macOS support (CLI/TUI mode)

---

## Contributing

PRs, issues, and feature requests are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) (coming soon).

## License

MIT &mdash; see [LICENSE](LICENSE) for details.

---

<p align="center">
  ⭐ If this project helps you, please consider starring it!
</p>

---

<h2 id="简体中文">简体中文</h2>

<h3 align="center">CrossAgnetCoding — 跨 AI 编码工具的共享记忆管理器</h3>

### 它解决什么问题？

你可能同时使用多个 AI 编码工具（Codex、TRAE、Claude、Gemini 等）。每个工具的对话记忆互相隔离，换工具、换账号、重启后就丢失了之前讨论的目标、决策和约定。

**CrossAgnetCoding 的做法：** 在本地启动一个 AgentMemory 服务，通过 MCP 协议一键接入所有编码工具，让它们共享同一份持久化记忆。

### 快速开始

1. 从 [Releases](https://github.com/zhibuyu/CrossAgnetCoding/releases) 下载 `CrossAgnetCoding.exe`
2. 运行，点击 **安装全部**
3. 点击 **启动服务**
4. 点击 **全部配置** 写入各工具的 MCP 配置
5. 重启你的编码工具

### 支持的编码工具

自动检测安装状态，一键写入 MCP 配置：Codex、TRAE SOLO CN、TRAE SOLO、Qoder CN、Claude Code、Claude Desktop、Gemini CLI、OpenCode、OpenClaw、Hermes Agent。

### 核心功能

- **共享记忆** — 所有工具读写同一份持久记忆，支持关键词+语义混合检索
- **一键 MCP 配置** — 自动检测并写入各工具配置，写入前自动备份
- **共享 Prompt** — 生成 7 种 Agent 提示文件，统一记忆使用方式
- **工作区桥接** — 绑定项目目录，导入 Codex/TRAE 会话片段，生成交接摘要
- **记忆设置** — 语义检索（BM25/本地MiniLM/云端API）、LLM 智能压缩、MCP 工具集
- **存储迁移** — 三类目录可独立迁移到其他磁盘
- **GUI + CLI + TUI** — 图形界面、命令行、文本界面三种模式

### 构建与测试

```powershell
# 构建
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1

# 测试
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\selftest.ps1
```

---

<h2 id="繁體中文">繁體中文</h2>

<h3 align="center">CrossAgnetCoding — 跨 AI 編碼工具的共享記憶管理器</h3>

### 它解決什麼問題？

你可能同時使用多個 AI 編碼工具（Codex、TRAE、Claude、Gemini 等）。每個工具的對話記憶互相隔離，換工具、換帳號、重啟後就丟失了之前討論的目標、決策和約定。

**CrossAgnetCoding 的做法：** 在本地啟動一個 AgentMemory 服務，透過 MCP 協定一鍵接入所有編碼工具，讓它們共享同一份持久化記憶。

### 快速開始

1. 從 [Releases](https://github.com/zhibuyu/CrossAgnetCoding/releases) 下載 `CrossAgnetCoding.exe`
2. 執行，點選 **安裝全部**
3. 點選 **啟動服務**
4. 點選 **全部配置** 寫入各工具的 MCP 配置
5. 重啟你的編碼工具

### 支援的編碼工具

自動檢測安裝狀態，一鍵寫入 MCP 配置：Codex、TRAE SOLO CN、TRAE SOLO、Qoder CN、Claude Code、Claude Desktop、Gemini CLI、OpenCode、OpenClaw、Hermes Agent。

### 核心功能

- **共享記憶** — 所有工具讀寫同一份持久記憶，支援關鍵詞+語義混合檢索
- **一鍵 MCP 配置** — 自動檢測並寫入各工具配置，寫入前自動備份
- **共享 Prompt** — 生成 7 種 Agent 提示檔案，統一記憶使用方式
- **工作區橋接** — 綁定專案目錄，匯入 Codex/TRAE 會話片段，生成交接摘要
- **記憶設定** — 語義檢索（BM25/本地MiniLM/雲端API）、LLM 智能壓縮、MCP 工具集
- **儲存遷移** — 三類目錄可獨立遷移到其他磁碟
- **GUI + CLI + TUI** — 圖形介面、命令列、文字介面三種模式

### 構建與測試

```powershell
# 構建
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1

# 測試
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\selftest.ps1
```
