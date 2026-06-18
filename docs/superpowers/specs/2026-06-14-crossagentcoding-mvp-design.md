# CrossAgentCoding MVP Design

## Goal

Build a focused MVP that turns CrossAgentCoding into a shared workspace memory and agent-connection manager, with Codex and TRAE SOLO/CN as first-class paths.

## Product Scope

The MVP keeps the current Windows PowerShell/WinForms/IExpress stack. It does not attempt to clone the full `cc-switch` platform. Instead, it creates a reliable core that can be reused by GUI, CLI, and TUI entry points.

Included:

- AgentMemory install/start/stop and health checks.
- Tool detection and automatic MCP configuration.
- First-class Codex and TRAE SOLO/CN support.
- Additional target definitions for Claude Code, Claude Desktop, Gemini CLI, OpenCode, OpenClaw, and Hermes Agent.
- Workspace memory tied to a project directory, not to a Codex or TRAE account.
- Session bridge summaries from readable local session/log directories into CrossAgentCoding workspace memory.
- Configurable CrossAgentCoding data directory with safe migration.
- GUI status cards plus CLI/TUI commands for repeatable workflows.
- Environment detection that does not repeatedly launch a broken `node.exe`.

Deferred:

- Full provider switching.
- Proxy routing.
- Usage/cost dashboard.
- WebDAV/cloud sync.
- Native import of proprietary TRAE/Codex chat UI state.

## Architecture

The app remains one PowerShell source file for the MVP, but responsibilities are separated by function group:

- App home/settings: resolves `%USERPROFILE%\.CrossAgentCoding` by default, reads/writes `settings.json`, migrates data.
- Tool targets: declarative list of supported tools with install command, config path, MCP format, prompt file name, and priority.
- Environment status: checks Node.js, AgentMemory, iii-engine, and service state with cached results and cooldown.
- Config writers: JSON, TOML, and YAML-ish writers that back up user files before writing.
- Workspace memory: maps a project directory to a stable hash and stores summaries under `workspaces/<hash>/`.
- Session bridge: scans Codex sessions and TRAE log/user-data directories for project-related text, writes a bridge summary, and mirrors it into shared prompt files.
- Interfaces: GUI, CLI, and TUI call the same core functions.

## Codex And TRAE Requirements

Codex and TRAE SOLO/CN are mandatory MVP targets.

Codex:

- Detect `codex.exe`/`codex`, `%CODEX_HOME%`, and `%USERPROFILE%\.codex`.
- Configure `%CODEX_HOME%\config.toml` when `CODEX_HOME` points to an existing directory; otherwise configure `%USERPROFILE%\.codex\config.toml`.
- Detect sessions under `%CODEX_HOME%\sessions` or `%USERPROFILE%\.codex\sessions`.
- Sync `AGENTS.md` into the workspace shared memory output.

TRAE:

- Detect both `%APPDATA%\TRAE SOLO CN` and `%APPDATA%\TRAE SOLO`.
- Configure `User\mcp.json` under each detected TRAE data root.
- Scan readable logs/user-data text under detected TRAE roots, bounded by file count and size.
- Sync `TRAE.md` and `AGENTS.md` into shared memory output.

## Workspace Memory

Workspace identity is based on normalized project path plus Git remote when available. The memory store is independent from app accounts.

This means that if a user logs out of Codex and signs in with another account, loading the same project directory can still find CrossAgentCoding workspace memory. Codex's own old account history may be inaccessible, but bridge summaries and AgentMemory-backed project memory remain available.

Workspace files:

- `workspace.json`: path, hash, created/updated timestamps.
- `handoff.md`: latest cross-tool summary.
- `sessions.jsonl`: bridge entries from Codex/TRAE/imported summaries.
- `AGENTS.md`, `TRAE.md`, `CLAUDE.md`, `GEMINI.md`, `OPENCODE.md`, `OPENCLAW.md`, `HERMES.md`: generated prompts.

## Connection Status

Each target card reports:

- Installed.
- CLI available.
- Config path.
- MCP configured.
- Service reachable.
- Workspace bound.
- Shared prompt synced.

If missing, the UI/CLI/TUI offers automatic configuration. Writes always back up existing config files.

## Data Directory Migration

Default home:

```text
%USERPROFILE%\.CrossAgentCoding
```

The MVP supports:

- Show current data directory.
- Switch without migration.
- Migrate with copy-then-verify semantics.
- Open directory.
- Restore default.

Migration never deletes the old directory automatically.

## UI Direction

The GUI should move toward the `cc-switch` settings/about screen style:

- Top title and tab-like navigation.
- About/version card.
- Local environment check section.
- Tool cards in a responsive grid-like layout where WinForms allows.
- Codex and TRAE cards appear first.

The MVP can retain WinForms controls, but should avoid the current narrow status-list-only experience.

## Testing

Self-tests must cover:

- Target definitions include mandatory tools.
- Codex config path follows `CODEX_HOME` when valid.
- TRAE detects both CN and non-CN data roots.
- Config writers create AgentMemory MCP entries.
- Workspace identity is stable for the same path.
- Workspace memory is independent from account state.
- Session bridge writes bounded summaries.
- Data home migration copies and verifies files.
- Environment status avoids repeated Node execution after a failure.
