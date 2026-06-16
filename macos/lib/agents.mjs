// Coding Agent target definitions, install/configured detection, and per-tool
// MCP config writers. Mirrors Get-AgentTargetDefinitions (ps1:1089),
// Test-AgentInstallPresent (ps1:1333), Get-AgentClientStatuses (ps1:1382) and
// the Configure-*Mcp writers (ps1:1188-1308).
import fs from 'node:fs';
import path from 'node:path';
import { HOME, APP_SUPPORT } from './platform.mjs';
import {
  which,
  readJson,
  readText,
  writeJsonWithBackup,
  writeTextWithBackup,
  ensureDir,
  backupFile,
} from './util.mjs';
import { agentMemoryServerObject, textConfigured } from './mcp.mjs';

// format: 'json' (mcpServers.agentmemory) | 'opencode' | 'codex' | 'hermes'
export function agentTargets() {
  return [
    {
      id: 'codex',
      name: 'Codex',
      commandNames: ['codex'],
      installRoot: path.join(HOME, '.codex'),
      configPath: path.join(HOME, '.codex', 'config.toml'),
      format: 'codex',
    },
    {
      id: 'trae-cn',
      name: 'TRAE SOLO CN',
      commandNames: [],
      installRoot: path.join(APP_SUPPORT, 'TRAE SOLO CN'),
      configPath: path.join(APP_SUPPORT, 'TRAE SOLO CN', 'User', 'mcp.json'),
      format: 'json',
    },
    {
      id: 'trae',
      name: 'TRAE SOLO',
      commandNames: [],
      installRoot: path.join(APP_SUPPORT, 'TRAE SOLO'),
      configPath: path.join(APP_SUPPORT, 'TRAE SOLO', 'User', 'mcp.json'),
      format: 'json',
    },
    {
      id: 'qoder-cn',
      name: 'Qoder CN',
      commandNames: [],
      installRoot: path.join(APP_SUPPORT, 'QoderCN'),
      configPath: path.join(APP_SUPPORT, 'QoderCN', 'SharedClientCache', 'mcp.json'),
      format: 'json',
    },
    {
      id: 'claude-code',
      name: 'Claude Code',
      commandNames: ['claude'],
      installRoot: path.join(HOME, '.claude'),
      configPath: path.join(HOME, '.claude', 'mcp.json'),
      format: 'json',
    },
    {
      id: 'claude-desktop',
      name: 'Claude Desktop',
      commandNames: [],
      installRoot: path.join(APP_SUPPORT, 'Claude'),
      configPath: path.join(APP_SUPPORT, 'Claude', 'claude_desktop_config.json'),
      format: 'json',
    },
    {
      id: 'gemini',
      name: 'Gemini CLI',
      commandNames: ['gemini'],
      installRoot: path.join(HOME, '.gemini'),
      configPath: path.join(HOME, '.gemini', 'settings.json'),
      format: 'json',
    },
    {
      id: 'opencode',
      name: 'OpenCode',
      commandNames: ['opencode'],
      installRoot: path.join(HOME, '.config', 'opencode'),
      configPath: path.join(HOME, '.config', 'opencode', 'opencode.json'),
      format: 'opencode',
    },
    {
      id: 'openclaw',
      name: 'OpenClaw',
      commandNames: ['openclaw'],
      installRoot: path.join(HOME, '.openclaw'),
      configPath: path.join(HOME, '.openclaw', 'openclaw.json'),
      format: 'json',
    },
    {
      id: 'hermes',
      name: 'Hermes Agent',
      commandNames: ['hermes'],
      installRoot: path.join(HOME, '.hermes'),
      configPath: path.join(HOME, '.hermes', 'config.yaml'),
      format: 'hermes',
    },
  ];
}

function resolveCommand(commandNames) {
  for (const name of commandNames) {
    const p = which(name);
    if (p) return p;
  }
  return '';
}

// Whether the tool looks genuinely installed (not merely configured by us).
// Mirrors Test-AgentInstallPresent: a resolvable CLI is proof; otherwise scan
// the install root for any artifact other than our own config file + backups
// and the single managed directory chain leading to it.
function installPresent(target, cliPath) {
  if (cliPath) return true;

  const root = target.installRoot;
  if (!root || !fs.existsSync(root)) return false;

  const configName = path.basename(target.configPath);
  let managedTop = configName;
  try {
    const rel = path.relative(root, target.configPath);
    managedTop = rel.split(path.sep)[0];
  } catch {
    // keep configName
  }

  let entries = [];
  try {
    entries = fs.readdirSync(root);
  } catch {
    return false;
  }

  for (const name of entries) {
    if (name === configName) continue;
    if (name.startsWith(configName + '.bak-')) continue;
    if (name === managedTop) {
      const full = path.join(root, name);
      let isDir = false;
      try {
        isDir = fs.statSync(full).isDirectory();
      } catch {
        isDir = false;
      }
      if (isDir) {
        let inner = [];
        try {
          inner = fs.readdirSync(full);
        } catch {
          inner = [];
        }
        const meaningful = inner.filter(
          (n) => n !== configName && !n.startsWith(configName + '.bak-')
        );
        if (meaningful.length > 0) return true;
      }
      continue;
    }
    return true;
  }
  return false;
}

// One status object per Coding Agent (mirrors Get-AgentClientStatuses).
export function agentClientStatuses() {
  return agentTargets().map((target) => {
    const cliPath = resolveCommand(target.commandNames);
    const installed = installPresent(target, cliPath);
    const configured =
      fs.existsSync(target.configPath) && textConfigured(readText(target.configPath));
    return {
      id: target.id,
      name: target.name,
      installed,
      cliAvailable: cliPath.length > 0,
      configured,
      configPath: target.configPath,
    };
  });
}

// --- Config writers ---------------------------------------------------------

function configureJsonMcpServers(configPath) {
  const config = readJson(configPath);
  if (typeof config.mcpServers !== 'object' || config.mcpServers === null) {
    config.mcpServers = {};
  }
  config.mcpServers.agentmemory = agentMemoryServerObject();
  return writeJsonWithBackup(configPath, config);
}

function configureOpenCode(configPath) {
  const config = readJson(configPath);
  if (typeof config.mcp !== 'object' || config.mcp === null) {
    config.mcp = {};
  }
  config.mcp.agentmemory = {
    type: 'local',
    enabled: true,
    command: ['npx', '-y', '@agentmemory/mcp'],
    environment: { AGENTMEMORY_URL: 'http://localhost:3111' },
  };
  return writeJsonWithBackup(configPath, config);
}

// Remove the parent [mcp_servers.agentmemory] block and any of its
// [mcp_servers.agentmemory.*] subsections from existing TOML text.
function stripCodexAgentMemory(text) {
  const lines = text.split(/\r?\n/);
  const out = [];
  let skipping = false;
  for (const line of lines) {
    const m = line.match(/^\[([^\]]+)\]/);
    if (m) {
      const section = m[1];
      if (section === 'mcp_servers.agentmemory' || section.startsWith('mcp_servers.agentmemory.')) {
        skipping = true;
        continue;
      }
      skipping = false;
      out.push(line);
      continue;
    }
    if (!skipping) out.push(line);
  }
  return out.join('\n').replace(/\s+$/, '');
}

function configureCodex(configPath) {
  ensureDir(path.dirname(configPath));
  let existing = '';
  if (fs.existsSync(configPath)) {
    existing = readText(configPath);
    backupFile(configPath);
  }
  const withoutServer = stripCodexAgentMemory(existing);
  const block = [
    '[mcp_servers.agentmemory]',
    'command = "npx"',
    'args = ["-y", "@agentmemory/mcp"]',
    'startup_timeout_sec = 60',
    '',
    '[mcp_servers.agentmemory.env]',
    'AGENTMEMORY_URL = "http://localhost:3111"',
  ].join('\n');
  const body = withoutServer ? withoutServer + '\n\n' : '';
  fs.writeFileSync(configPath, body + block + '\n', 'utf8');
  return configPath;
}

function configureHermes(configPath) {
  ensureDir(path.dirname(configPath));
  backupFile(configPath);
  const block = [
    'mcp_servers:',
    '  agentmemory:',
    '    command: npx',
    '    args: ["-y", "@agentmemory/mcp"]',
    '    env:',
    '      AGENTMEMORY_URL: "http://localhost:3111"',
    '',
    'memory:',
    '  provider: agentmemory',
  ].join('\n');
  fs.writeFileSync(configPath, block + '\n', 'utf8');
  return configPath;
}

// Write the MCP config for a single target; returns the written path.
export function configureTarget(target) {
  switch (target.format) {
    case 'codex':
      return configureCodex(target.configPath);
    case 'opencode':
      return configureOpenCode(target.configPath);
    case 'hermes':
      return configureHermes(target.configPath);
    case 'json':
    default:
      return configureJsonMcpServers(target.configPath);
  }
}

// Configure every detectable target (installed OR config-dir already present).
// Returns [{ name, path, configured }].
export function configureAllAgents() {
  const results = [];
  const statuses = agentClientStatuses();
  for (const target of agentTargets()) {
    const status = statuses.find((s) => s.id === target.id);
    const detectable = status && (status.installed || fs.existsSync(path.dirname(target.configPath)));
    if (!detectable) {
      results.push({ name: target.name, path: target.configPath, configured: false });
      continue;
    }
    try {
      const written = configureTarget(target);
      results.push({ name: target.name, path: written, configured: true });
    } catch (e) {
      results.push({ name: target.name, path: target.configPath, configured: false, error: e.message });
    }
  }
  return results;
}
