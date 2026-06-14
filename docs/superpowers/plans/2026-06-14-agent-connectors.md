# Agent Connectors Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep AgentMemory Manager source code in the project, add open-source-friendly docs, and add Coding Agent detection/configuration for Codex, TRAE SOLO CN, OpenCode, and Claude Code.

**Architecture:** The project keeps the WinForms manager in `src/AgentMemoryManager.ps1`, the hidden launcher in `src/launch.vbs`, a reproducible IExpress build script in `scripts/build.ps1`, and self-tests in `tests/selftest.ps1`. The manager owns AgentMemory service install/start/stop plus client connector detection and MCP/CLI configuration helpers.

**Tech Stack:** Windows PowerShell 5.1, WinForms, IExpress SFX packaging, JSON/TOML file edits, Node/npm/npx for AgentMemory MCP.

---

### Task 1: Source Layout And Build

**Files:**
- Create: `README.md`
- Create: `docs/FUNCTIONS.md`
- Create: `scripts/build.ps1`
- Create: `tests/selftest.ps1`
- Modify: `src/AgentMemoryManager.ps1`

- [ ] Ensure `src/AgentMemoryManager.ps1` and `src/launch.vbs` are retained as editable source.
- [ ] Add `scripts/build.ps1` to package `src/AgentMemoryManager.ps1` and `src/launch.vbs` into `AgentMemoryManager_new.exe`.
- [ ] Add `tests/selftest.ps1` to run `src/AgentMemoryManager.ps1 -SelfTest`.
- [ ] Add documentation describing project structure, build command, test command, and feature responsibilities.

### Task 2: Coding Agent Detection

**Files:**
- Modify: `src/AgentMemoryManager.ps1`
- Test: `tests/selftest.ps1`

- [ ] Add `Get-AgentClientStatuses` to detect Codex, TRAE SOLO CN, OpenCode, and Claude Code.
- [ ] Detect installation by command and/or config path:
  - Codex: `codex.exe` or `%USERPROFILE%\.codex\config.toml`
  - TRAE SOLO CN: `%APPDATA%\TRAE SOLO CN\User\mcp.json`
  - OpenCode: `opencode` or `%USERPROFILE%\.config\opencode\opencode.json`
  - Claude Code: `claude` or `%USERPROFILE%\.claude`
- [ ] Detect MCP configured state by checking each config for the `agentmemory` server and `AGENTMEMORY_URL=http://localhost:3111`.
- [ ] Add self-test checks for all client definitions and config templates.

### Task 3: MCP And CLI Configuration

**Files:**
- Modify: `src/AgentMemoryManager.ps1`
- Test: `tests/selftest.ps1`

- [ ] Add `Configure-CodexMcp`, `Configure-TraeMcp`, `Configure-OpenCodeMcp`, and `Configure-ClaudeMcp`.
- [ ] Back up config files before writing using `.bak-YYYYMMDDHHMMSS`.
- [ ] For Codex, append/replace `[mcp_servers.agentmemory]` and `[mcp_servers.agentmemory.env]` in `config.toml`.
- [ ] For TRAE SOLO CN, merge `agentmemory` into `mcpServers` in `User\mcp.json`.
- [ ] For OpenCode, merge `mcp.agentmemory` into `opencode.json`.
- [ ] For Claude Code, create/update `%USERPROFILE%\.claude\mcp.json` with `mcpServers.agentmemory` when the CLI is unavailable; when the CLI exists, still provide copyable CLI commands.
- [ ] Add copy buttons for MCP JSON and CLI commands.

### Task 4: UI And Packaging Verification

**Files:**
- Modify: `src/AgentMemoryManager.ps1`
- Modify: `docs/FUNCTIONS.md`
- Build: `AgentMemoryManager_new.exe`

- [ ] Add a `Coding Agent Access` group to the UI with status lines and buttons.
- [ ] Keep Chinese/English language switching for all new strings.
- [ ] Run `tests/selftest.ps1`.
- [ ] Build `AgentMemoryManager_new.exe`.
- [ ] Verify package `RUNPROGRAM` is `wscript.exe launch.vbs`, not `cmd /c`.
- [ ] Smoke start the exe and verify no `cmd.exe` process is launched.
