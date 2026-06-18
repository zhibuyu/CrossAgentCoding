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
  <b>English</b> | <a href="README.zh-CN.md">简体中文</a> | <a href="README.zh-TW.md">繁體中文</a>
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

**CrossAgentCoding fixes this.** It runs a local AgentMemory service (`http://localhost:3111`) and wires it into every coding agent you use via MCP (Model Context Protocol). All agents read and write to the **same persistent memory** &mdash; so context survives tool switches, account changes, and restarts.

> Inspired by [rohitg00/agentmemory](https://github.com/rohitg00/agentmemory) (persistent memory) and [farion1231/cc-switch](https://github.com/farion1231/cc-switch/) (multi-agent configuration).

---

## Quick Start

### Windows (Pre-built EXE)

1. **Download** `CrossAgentCoding.exe` from [Releases](https://github.com/zhibuyu/CrossAgentCoding/releases).
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
git clone https://github.com/zhibuyu/CrossAgentCoding.git
cd CrossAgentCoding
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
Three independently migratable directories: CrossAgentCoding data, AgentMemory memory store, and model cache. GUI folder picker or CLI.

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

Uses Windows built-in IExpress. Output: `release\CrossAgentCoding.exe`

### macOS / Linux

No build step needed &mdash; run directly from source. To create a wrapper script:

```bash
# Create a convenient launcher
cat > crossagentcoding << 'EOF'
#!/bin/bash
pwsh "$(dirname "$0")/src/AgentMemoryManager.ps1" "$@"
EOF
chmod +x crossagentcoding
./crossagentcoding -Cli env tools
```

## Test

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\selftest.ps1
```

Self-test uses a temporary user profile &mdash; your real configs are never touched.

---

## Security &mdash; Keys Stay Local

API keys you enter in **Memory Settings** are stored **only** in your local `settings.json` (inside your data home, e.g. `%USERPROFILE%\.CrossAgentCoding` &mdash; outside the repository). On Windows they are **encrypted at rest** (DPAPI, bound to your user account) and decrypted only in memory when the service starts. They are sent **only** to the LLM/embedding endpoint you configure, and are **never** committed to git. (Migrate an old plaintext key with `... -Cli memory encrypt`, or just re-save in Memory Settings.)

Two safeguards keep secrets out of the repo:

- **`.gitignore`** excludes `settings.json`, `.env*`, `*.local.json`, `*.key`, `*.secret`, etc.
- **A pre-commit hook** (`scripts/git-hooks/pre-commit`) scans every commit and blocks anything that looks like an API key (OpenAI / Anthropic / Zhipu &hellip;).

Enable the hook after cloning:

```bash
git config core.hooksPath scripts/git-hooks
```

A genuine false positive can be bypassed with `git commit --no-verify`.

---

## Project Structure

```
CrossAgentCoding/
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
