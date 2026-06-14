# AgentMemory Manager Function Guide

This document explains the public behavior and important internal functions so the project can be maintained after release.

## Main User Workflows

### Environment Check

The manager checks:

- `node.exe`
- global `agentmemory.cmd`
- `iii.exe` under `%USERPROFILE%\.agentmemory\bin` or `%USERPROFILE%\.local\bin`
- local AgentMemory service on `localhost:3111`

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
- OpenCode
- Claude Code

Each client has three concepts:

- Installed: command or config directory exists.
- MCP Configured: config file contains an `agentmemory` MCP server pointing at `http://localhost:3111`.
- CLI Available: command-line tool exists in PATH when applicable.

## Important Functions

### `Get-EnvironmentStatus`

Returns Node.js, AgentMemory, iii-engine, and service status.

### `Get-AgentClientStatuses`

Returns one status object per Coding Agent. Each object includes:

- `Id`
- `Name`
- `Installed`
- `Configured`
- `CliAvailable`
- `ConfigPath`
- `Details`

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

## Safety Rules

- Config files are backed up before automatic writes.
- The manager only writes user-level config files.
- The packaged exe must launch through `wscript.exe launch.vbs` so no black `cmd` window appears.
