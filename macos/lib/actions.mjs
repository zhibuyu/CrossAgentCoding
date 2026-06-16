// Display-oriented actions shared by the CLI and the TUI.
import { PORT, STREAMS_PORT, VIEWER_PORT, crossAgnetCodingHome } from './platform.mjs';
import { environmentStatus } from './env.mjs';
import { agentClientStatuses, configureAllAgents } from './agents.mjs';
import { MCP_CONFIG_JSON, cliConfigCommands } from './mcp.mjs';
import { pbcopy } from './util.mjs';
import { t } from './i18n.mjs';

export async function showEnv(log = console.log) {
  const s = await environmentStatus();
  log(t('EnvHeader'));
  log('  ' + (s.node ? t('NodeInstalled', s.nodeVersion) : t('NodeMissing')));
  log(
    '  ' +
      (s.agentMemory
        ? t('AgentMemoryInstalled', s.agentMemoryVersion || '?')
        : t('AgentMemoryMissing'))
  );
  log('  ' + (s.iii ? t('IiiInstalled') : t('IiiMissing')));
  log('  ' + (s.service ? t('ServiceRunning', PORT) : t('ServiceStopped')));
  log('  ' + t('PortsInfo', PORT, STREAMS_PORT, VIEWER_PORT));
  log('  ' + t('DataHome', crossAgnetCodingHome()));
  return s;
}

export function scanAgents(log = console.log) {
  log(t('ScanHeader'));
  for (const a of agentClientStatuses()) {
    const inst = a.installed ? t('StatusInstalled') : t('StatusNotInstalled');
    const conf = a.configured ? t('StatusConfigured') : t('StatusNotConfigured');
    log(`  ${a.name.padEnd(16)} ${inst} / ${conf}`);
  }
}

export function configureAgents(log = console.log) {
  log(t('Configuring'));
  for (const r of configureAllAgents()) {
    if (r.configured) log('  ' + t('ConfigureWrote', r.name, r.path));
    else log('  ' + t('ConfigureSkip', r.name, r.error || 'not detected'));
  }
  log(t('ConfigureDone'));
}

export function copyMcp(log = console.log) {
  const ok = pbcopy(MCP_CONFIG_JSON);
  log(ok ? t('McpCopied') : t('McpCopyFail'));
  log(MCP_CONFIG_JSON);
}

export function showCliSnippets(log = console.log) {
  log(t('CliSnippets'));
  log(cliConfigCommands());
}
