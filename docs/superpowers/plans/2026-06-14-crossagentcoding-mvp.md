# CrossAgentCoding MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Build the MVP for Codex/TRAE-first workspace memory, agent connection checks, automatic MCP configuration, configurable data home, and CLI/TUI entry points.

**Architecture:** Keep the current PowerShell WinForms application, but add reusable core functions inside `src/AgentMemoryManager.ps1`. GUI, CLI, and TUI call the same target, workspace, session bridge, config writer, and environment-check functions.

**Tech Stack:** Windows PowerShell 5.1, WinForms, JSON/TOML/YAML-like file edits, IExpress packaging, AgentMemory MCP via `npx -y @agentmemory/mcp`.

---

### Task 1: Environment Check Cooldown

**Files:**
- Modify: `src/AgentMemoryManager.ps1`
- Modify: `tests/selftest.ps1`

- [x] **Step 1: Write a failing self-test assertion**

Add source checks to `tests/selftest.ps1` requiring `Get-NodeVersion` to use a cached status variable and a file-version fallback instead of blindly running `node.exe -v` on every timer tick.

- [x] **Step 2: Run the self-test and confirm it fails**

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\selftest.ps1
```

Expected: FAIL because the cache/cooldown markers do not exist yet.

- [x] **Step 3: Implement safe Node status**

Add script-level cache variables and update `Get-NodeVersion` so repeated failures are cooled down. Prefer command metadata and file version before executing Node.

- [x] **Step 4: Run self-test and confirm it passes**

Run the same command. Expected: PASS.

### Task 2: Target Definitions And Auto Configuration

**Files:**
- Modify: `src/AgentMemoryManager.ps1`
- Modify: `tests/selftest.ps1`

- [x] **Step 1: Write failing tests for supported targets**

Assert target IDs include `codex`, `trae-cn`, `trae`, `claude-code`, `claude-desktop`, `gemini`, `opencode`, `openclaw`, and `hermes`. Assert Codex and TRAE sort first.

- [x] **Step 2: Run self-test and confirm it fails**

Expected: FAIL because only four old targets exist.

- [x] **Step 3: Implement target definitions**

Add `Get-AgentTargetDefinitions`, config path helpers, status checks, and config writers for the MVP tools. Codex and TRAE must be first-class and must retain existing behavior.

- [x] **Step 4: Run self-test and confirm it passes**

Expected: PASS.

### Task 3: Workspace Memory And Session Bridge

**Files:**
- Modify: `src/AgentMemoryManager.ps1`
- Modify: `tests/selftest.ps1`

- [x] **Step 1: Write failing tests for workspace memory**

Assert same project path returns the same workspace hash, workspace files are created under the CrossAgentCoding data home, and bridge summaries survive account changes because they do not reference Codex auth state.

- [x] **Step 2: Run self-test and confirm it fails**

Expected: FAIL because workspace memory functions do not exist yet.

- [x] **Step 3: Implement workspace memory**

Add `Get-WorkspaceId`, `Get-WorkspacePath`, `Initialize-WorkspaceMemory`, `Add-SessionBridgeEntry`, and `Sync-WorkspacePromptFiles`.

- [x] **Step 4: Implement bounded session scanning**

Add `Import-CodexSessionBridge` and `Import-TraeSessionBridge` with bounded file count and bytes. If no readable files exist, write a clear zero-import summary instead of failing.

- [x] **Step 5: Run self-test and confirm it passes**

Expected: PASS.

### Task 4: Data Directory Settings And Migration

**Files:**
- Modify: `src/AgentMemoryManager.ps1`
- Modify: `tests/selftest.ps1`

- [x] **Step 1: Write failing tests for data home migration**

Assert default data home, custom data home via settings/env, and copy-then-verify migration.

- [x] **Step 2: Run self-test and confirm it fails**

Expected: FAIL because migration functions do not exist yet.

- [x] **Step 3: Implement settings and migration**

Add `Get-CrossAgentCodingSettingsPath`, `Read-CrossAgentCodingSettings`, `Write-CrossAgentCodingSettings`, `Get-CrossAgentCodingHome`, and `Move-CrossAgentCodingHome`.

- [x] **Step 4: Run self-test and confirm it passes**

Expected: PASS.

### Task 5: CLI And TUI MVP Entrypoints

**Files:**
- Modify: `src/AgentMemoryManager.ps1`
- Modify: `README.md`
- Modify: `docs/FUNCTIONS.md`
- Modify: `tests/selftest.ps1`

- [x] **Step 1: Write failing tests for command surface**

Assert source contains `Invoke-CliMode`, `Invoke-TuiMode`, `env tools`, `agents configure`, `workspace init`, `workspace bridge`, and `config migrate`.

- [x] **Step 2: Run self-test and confirm it fails**

Expected: FAIL because command handlers do not exist yet.

- [x] **Step 3: Implement CLI mode**

Add parameters and commands for status, agent scan/configure, workspace init/bridge, and config home/migrate.

- [x] **Step 4: Implement TUI mode**

Add a simple console menu that calls the same core operations.

- [x] **Step 5: Update docs**

Document MVP scope, Codex/TRAE priority, session bridge behavior, data directory migration, CLI, and TUI.

- [x] **Step 6: Run self-test and build**

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\selftest.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

Expected: both commands exit 0.
