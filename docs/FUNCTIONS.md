# CrossAgnetCoding Function Guide

This document explains the public behavior and important internal functions so the project can be maintained after release.

Version: 0.3.0-mvp

## Main User Workflows

### Environment Check

The manager checks:

- `node.exe`
- global `agentmemory.cmd`
- `iii.exe` under `%USERPROFILE%\.agentmemory\bin` or `%USERPROFILE%\.local\bin`
- local AgentMemory service on `localhost:3111`

Node.js detection uses file-version metadata and cached results before executing `node.exe`, so a broken Node install does not create repeated Windows error dialogs during GUI refresh.

### Install All

Installs missing dependencies:

- Node.js MSI when Node is missing.
- `@agentmemory/agentmemory` through npm.
- iii-engine from the GitHub release zip.

### Start Service

Starts `agentmemory.cmd` hidden through `cmd.exe` with output redirected to:

```text
%USERPROFILE%\.agentmemory\agentmemory-service.log
```

The UI waits for port `3111` and reports `Started`, `Already Running`, or `Start Failed`.

### Coding Agent Access

The manager detects and configures client-side AgentMemory access for:

- Codex
- TRAE SOLO CN
- TRAE SOLO
- Claude Code
- Claude Desktop
- Gemini CLI
- OpenCode
- OpenClaw
- Hermes Agent

The GUI presents these clients in an About-style `Local Environment Check` card grid, inspired by the cc-switch settings/about page. This is intentionally richer than a generic `Scan Agents` result: each card has install status, current version when it can be read without launching risky Node wrappers, latest-version placeholder, MCP connection status, and a per-tool configure action.

Each client has three concepts:

- Installed: command or config directory exists.
- MCP Configured: config file contains an `agentmemory` MCP server pointing at `http://localhost:3111`.
- CLI Available: command-line tool exists in PATH when applicable.

### cc-switch-inspired Shared Setup

CrossAgnetCoding borrows the practical multi-client setup ideas from `farion1231/cc-switch`:

- one place to scan Coding Agent clients
- one-click MCP configuration
- config backups before writes
- shared prompt/context files
- project-bound workspace memory
- Codex/TRAE session bridge summaries
- configurable data directory migration
- CLI/TUI mode for repeatable workflows
- copyable CLI snippets

`Sync-SharedAgentFiles` writes shared context files to:

```text
%USERPROFILE%\.CrossAgnetCoding\shared
```

Generated files:

- `AGENTS.md`
- `CLAUDE.md`
- `OPENCODE.md`
- `TRAE.md`

### Workspace Session Bridge

`Initialize-WorkspaceMemory` creates a project-bound workspace under the CrossAgnetCoding data home. `Import-CodexSessionBridge` and `Import-TraeSessionBridge` import bounded readable snippets into:

```text
workspaces\<workspace-id>\sessions.jsonl
workspaces\<workspace-id>\handoff.md
```

Workspace memory is keyed by the normalized project directory plus the Git `remote.origin.url` when the folder is a Git repository, and is independent from Codex account state. Non-Git folders fall back to a stable path-only identifier.

The GUI `Bridge Workspace` button runs the same flow: choose a project folder, import Codex/TRAE snippets, refresh the handoff, and regenerate prompt files for that workspace.

### CLI And TUI

The script supports:

```powershell
-Cli env tools
-Cli agents scan
-Cli agents configure
-Cli workspace init <path>
-Cli workspace bridge <path>
-Cli config home
-Cli config migrate <path>
-Tui
```

## Important Functions

### `Get-EnvironmentStatus`

Returns Node.js, AgentMemory, iii-engine, and service status.

### `Get-CrossAgnetCodingHome`

Returns:

```text
%USERPROFILE%\.CrossAgnetCoding
```

If settings contain `dataHome`, or `CROSSAGNETCODING_HOME` is set, the configured path is returned instead.

### `Move-CrossAgnetCodingHome`

Copies the current CrossAgnetCoding data directory to a new path, verifies it is writable, updates `settings.json`, and leaves the old directory in place.

The GUI `Migrate Data Home` button exposes the same migration behavior with a folder picker.

### `Get-AgentTargetDefinitions`

Returns the ordered MVP target list. Codex, TRAE SOLO CN, and TRAE SOLO are first.

### `Get-AgentClientStatuses`

Returns one status object per Coding Agent. Each object includes:

- `Id`
- `Name`
- `Installed`
- `Configured`
- `CliAvailable`
- `ConfigPath`
- `Details`

### `Get-AgentToolCards`

Transforms agent client status into the card view model used by the About page. Each card includes:

- `CurrentVersion`
- `LatestVersion`
- `InstallStatus`
- `ConfigStatus`
- `Detail`
- `ActionText`

Version reads are deliberately conservative. The manager prefers file metadata and does not repeatedly launch broken Node-backed commands just to populate the UI.

### `New-ToolCardControl` And `Update-ToolCardControls`

Build and refresh the WinForms local environment cards. These functions are the UI boundary for the cc-switch-inspired About page grid.

### `Configure-AllAgentClients`

Runs the supported config writers for installed or config-detectable clients.

### `Configure-CodexMcp`

Writes AgentMemory MCP configuration to:

```text
%USERPROFILE%\.codex\config.toml
```

### `Configure-TraeMcp`

Writes AgentMemory MCP configuration to:

```text
%APPDATA%\TRAE SOLO CN\User\mcp.json
%APPDATA%\TRAE SOLO\User\mcp.json
```

`Configure-TraeCnMcp` and `Configure-TraeSoloMcp` are available for single-target writes.

### `Configure-ClaudeDesktopMcp`

Writes AgentMemory MCP configuration to:

```text
%APPDATA%\Claude\claude_desktop_config.json
```

### `Configure-GeminiMcp`

Writes AgentMemory MCP configuration to:

```text
%USERPROFILE%\.gemini\settings.json
```

### `Configure-OpenClawMcp`

Writes AgentMemory MCP configuration to:

```text
%USERPROFILE%\.openclaw\openclaw.json
```

### `Configure-HermesMcp`

Writes a minimal Hermes YAML-style AgentMemory MCP block to:

```text
%USERPROFILE%\.hermes\config.yaml
```

### `Configure-OpenCodeMcp`

Writes AgentMemory MCP configuration to:

```text
%USERPROFILE%\.config\opencode\opencode.json
```

### `Configure-ClaudeMcp`

Writes AgentMemory MCP configuration to:

```text
%USERPROFILE%\.claude\mcp.json
```

The UI also provides copyable Claude CLI commands for users who prefer `claude mcp add-json`.

### `Get-McpConfig`

Returns a compact JSON MCP server snippet:

```json
{"mcpServers":{"agentmemory":{"command":"npx","args":["-y","@agentmemory/mcp"],"env":{"AGENTMEMORY_URL":"http://localhost:3111"}}}}
```

### `Get-CliConfigCommands`

Returns copyable commands for client CLIs and manual setup.

### `Get-SharedPromptContent`

Returns the shared context prompt written to all generated agent prompt files.

### `Sync-SharedAgentFiles`

Writes shared prompt files for Codex-style agents, Claude Code, OpenCode, and TRAE SOLO CN.

### `Get-ProjectGitRemote`

Returns the lowercased `remote.origin.url` for a project folder when Git is installed and the folder is a repository, otherwise an empty string. Used by `Get-WorkspaceId` to make workspace identity Git-remote aware.

### `Sync-WorkspacePromptFiles`

Writes workspace-specific prompt files for Codex, TRAE, Claude, Gemini, OpenCode, OpenClaw, and Hermes.

### `Get-CcSwitchInspiredFeatures`

Returns a short list of cc-switch-inspired features currently implemented in this project.

### `Get-CommandPathSafe`

Resolves an executable path the way `Get-Command` does, but inside a disposable runspace with a timeout (default 1.5s). A stale or unreachable entry in `PATH` (for example a disconnected mapped network drive) can make a normal `Get-Command` stall for tens of seconds; this helper abandons the lookup instead of blocking the UI thread. `Get-CommandAny` and `Get-NodeVersion` use it.

### `Get-PlaceholderToolCards`

Builds the tool-card list from target definitions only, with no command or config scanning, so the GUI grid renders instantly at startup. Real status is filled in by `Update-ToolCardControls` once the window is visible.

## Startup And Responsiveness

The packaged exe starts through `wscript.exe launch.vbs`, which runs the script in a hidden PowerShell window. To avoid a "clicking does nothing" experience:

- The main window is created and shown first; environment and agent scanning is deferred to a one-shot timer started from the form `Shown` event, so the window always appears before any potentially slow scan runs.
- Executable detection is bounded by `Get-CommandPathSafe`, so a dead `PATH` entry cannot hang the scan.
- Any terminating error during GUI bootstrap is written to `%TEMP%\CrossAgnetCoding-error.log` and shown in a message box instead of failing silently.
- `launch.vbs` surfaces a message box if PowerShell itself cannot start (for example a blocked execution policy).

Note: an unreachable UNC path placed first in the system `PATH` can stall the PowerShell/.NET process before any application code runs. That is an environment problem outside the app; remove the dead `PATH` entry to resolve it.

## Safety Rules

- Config files are backed up before automatic writes.
- The manager only writes user-level config files.
- Data home migration copies first and does not delete the old directory.
- Session bridge imports are bounded and write summaries, not full proprietary chat database migrations.
- The packaged exe must launch through `wscript.exe launch.vbs` so no black `cmd` window appears.
