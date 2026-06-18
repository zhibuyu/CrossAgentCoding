#!/usr/bin/env node
// CrossAgentCoding macOS manager — Node.js entry point.
// No arguments (or `tui`) launches the interactive menu; otherwise dispatches a
// CLI subcommand. Pure Node standard library, zero npm dependencies.
import { initLangFromEnv, runTui } from './lib/tui.mjs';
import {
  showEnv,
  scanAgents,
  configureAgents,
  copyMcp,
  showCliSnippets,
} from './lib/actions.mjs';
import { installAll } from './lib/install.mjs';
import { startService, stopService, openViewer } from './lib/service.mjs';
import { runGui } from './lib/server.mjs';
import { setLang } from './lib/i18n.mjs';

function printHelp() {
  console.log(`CrossAgentCoding (macOS) — AgentMemory manager

Usage:
  cac                       Graphical web GUI (default)
  cac tui                   Interactive terminal menu
  cac env [tools]           Check environment
  cac install [all]         Install Node / AgentMemory / iii-engine
  cac start                 Start the AgentMemory service
  cac stop                  Stop the AgentMemory service
  cac agents scan           List Coding Agent status
  cac agents configure      Write MCP config for all detected agents
  cac mcp [copy]            Copy MCP config to clipboard
  cac mcp cli               Print CLI configuration snippets
  cac viewer                Open the memory viewer
  cac --lang <zh|en|zh-TW>  Set language (combine with any command)`);
}

async function main() {
  initLangFromEnv();
  const args = process.argv.slice(2);

  // Optional `--lang <x>` anywhere in the args.
  const li = args.indexOf('--lang');
  if (li >= 0 && args[li + 1]) {
    setLang(args[li + 1]);
    args.splice(li, 2);
  }

  // No args → graphical GUI (matches the Windows experience). `tui` forces the
  // terminal menu; `gui` is the explicit form of the default.
  if (args.length === 0 || args[0] === 'gui') {
    await runGui();
    return; // server keeps the event loop alive
  }
  if (args[0] === 'tui') {
    process.exit(await runTui());
  }

  const cmd = args.join(' ').toLowerCase();
  switch (cmd) {
    case 'env':
    case 'env tools':
      await showEnv();
      break;
    case 'install':
    case 'install all':
      await installAll();
      break;
    case 'start': {
      const r = await startService();
      process.exit(r.ok ? 0 : 1);
      break;
    }
    case 'stop':
      await stopService();
      break;
    case 'agents scan':
    case 'scan':
      scanAgents();
      break;
    case 'agents configure':
    case 'configure':
      configureAgents();
      break;
    case 'mcp':
    case 'mcp copy':
      copyMcp();
      break;
    case 'mcp cli':
      showCliSnippets();
      break;
    case 'viewer':
      await openViewer();
      break;
    case 'help':
    case '--help':
    case '-h':
      printHelp();
      break;
    default:
      console.log('Unknown command: ' + cmd);
      printHelp();
      process.exit(2);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
