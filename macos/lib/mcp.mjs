// MCP server object + copyable CLI snippets.
// Mirrors Get-McpConfig (ps1:919), Get-AgentMemoryServerObject (ps1:923) and
// Get-CliConfigCommands (ps1:1310).
import path from 'node:path';
import { HOME, APP_SUPPORT } from './platform.mjs';

// Compact one-line MCP config snippet (matches Get-McpConfig exactly).
export const MCP_CONFIG_JSON =
  '{"mcpServers":{"agentmemory":{"command":"npx","args":["-y","@agentmemory/mcp"],"env":{"AGENTMEMORY_URL":"http://localhost:3111"}}}}';

// The agentmemory MCP server object embedded under mcpServers.agentmemory.
export function agentMemoryServerObject() {
  return {
    command: 'npx',
    args: ['-y', '@agentmemory/mcp'],
    env: { AGENTMEMORY_URL: 'http://localhost:3111' },
  };
}

// Whether arbitrary config text already contains a configured agentmemory MCP
// server pointing at localhost:3111 (mirrors Test-AgentMemoryTextConfigured).
export function textConfigured(text) {
  if (!text || !text.trim()) return false;
  return /agentmemory/i.test(text) && /AGENTMEMORY_URL/.test(text) && /localhost:3111/.test(text);
}

// Copyable CLI configuration snippets (mirrors Get-CliConfigCommands).
export function cliConfigCommands() {
  const mcpJson =
    '{"command":"npx","args":["-y","@agentmemory/mcp"],"env":{"AGENTMEMORY_URL":"http://localhost:3111"}}';
  const codexPath = path.join(HOME, '.codex', 'config.toml');
  const traeCnPath = path.join(APP_SUPPORT, 'TRAE SOLO CN', 'User', 'mcp.json');
  const traePath = path.join(APP_SUPPORT, 'TRAE SOLO', 'User', 'mcp.json');
  const qoderPath = path.join(APP_SUPPORT, 'QoderCN', 'SharedClientCache', 'mcp.json');
  const geminiPath = path.join(HOME, '.gemini', 'settings.json');
  const opencodePath = path.join(HOME, '.config', 'opencode', 'opencode.json');
  const openclawPath = path.join(HOME, '.openclaw', 'openclaw.json');
  const hermesPath = path.join(HOME, '.hermes', 'config.yaml');
  return [
    `claude mcp add-json agentmemory '${mcpJson}'`,
    `codex: add [mcp_servers.agentmemory] to ${codexPath}`,
    `TRAE SOLO CN: paste mcpServers.agentmemory into ${traeCnPath}`,
    `TRAE SOLO: paste mcpServers.agentmemory into ${traePath}`,
    `Qoder CN: paste mcpServers.agentmemory into ${qoderPath}`,
    `Gemini CLI: add mcpServers.agentmemory to ${geminiPath}`,
    `OpenCode: add mcp.agentmemory to ${opencodePath}`,
    `OpenClaw: add mcpServers.agentmemory to ${openclawPath}`,
    `Hermes: add mcp_servers.agentmemory to ${hermesPath}`,
  ].join('\n');
}
