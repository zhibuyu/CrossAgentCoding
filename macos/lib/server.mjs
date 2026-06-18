// Local control server for the macOS web GUI. Serves the single-page front-end
// and exposes the existing manager logic (env/install/service/agents/mcp) as a
// small JSON API plus a Server-Sent-Events log stream. Pure Node stdlib — no
// npm dependencies, so the bundle stays a couple of MB.
import http from 'node:http';
import fs from 'node:fs';
import net from 'node:net';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn, spawnSync } from 'node:child_process';

import {
  APP_NAME,
  APP_VERSION,
  ARCH,
  PORT,
  STREAMS_PORT,
  VIEWER_PORT,
  CrossAgentCodingHome,
  serviceWorkDir,
  modelCacheDir,
} from './platform.mjs';
import { environmentStatus, localEmbeddingReady } from './env.mjs';
import { agentClientStatuses, configureAllAgents, agentTargets, configureTarget } from './agents.mjs';
import { MCP_CONFIG_JSON, cliConfigCommands } from './mcp.mjs';
import { installAll, installLocalEmbedding } from './install.mjs';
import { startService, stopService, openViewer } from './service.mjs';
import { syncSharedAgentFiles, initializeWorkspaceMemory } from './workspace.mjs';
import { moveStorageLocation, moveCrossAgentCodingHome } from './storage.mjs';
import { getMemorySettings, saveMemorySettings } from './memory.mjs';
import { pbcopy } from './util.mjs';
import { setLang, getLang, allStrings, t } from './i18n.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const WEB_DIR = path.join(HERE, '..', 'web');

// --- log/feedback bus -------------------------------------------------------
// SSE clients subscribe; actions push log lines and feedback through here.
const clients = new Set();
let busy = false;

function broadcast(event) {
  const payload = `data: ${JSON.stringify(event)}\n\n`;
  for (const res of clients) {
    try {
      res.write(payload);
    } catch {
      // client gone; cleaned up on its 'close'
    }
  }
}

function pushLog(line) {
  broadcast({ type: 'log', line: String(line), ts: Date.now() });
}

function pushFeedback(text, level = 'info') {
  broadcast({ type: 'feedback', text: String(text), level });
}

// Native macOS folder picker via osascript. Returns the chosen POSIX path, or
// null when the user cancels. spawnSync is fine here: the whole interaction is
// modal — the manager is meant to wait on the user's choice.
function chooseFolder(promptText, defaultPath) {
  let inner = `choose folder with prompt ${JSON.stringify(promptText)}`;
  if (defaultPath && fs.existsSync(defaultPath)) {
    inner += ` default location (POSIX file ${JSON.stringify(defaultPath)})`;
  }
  const r = spawnSync('osascript', ['-e', `POSIX path of (${inner})`], { encoding: 'utf8' });
  if (r.status === 0 && r.stdout && r.stdout.trim()) return r.stdout.trim().replace(/\/+$/, '');
  return null; // cancelled or error
}

// --- API state --------------------------------------------------------------
async function buildState() {
  const env = await environmentStatus();
  return {
    app: { name: APP_NAME, version: APP_VERSION, arch: ARCH, platform: 'Mac' },
    lang: getLang(),
    strings: allStrings(),
    env: {
      node: env.node,
      nodeVersion: env.nodeVersion,
      agentMemory: env.agentMemory,
      agentMemoryVersion: env.agentMemoryVersion,
      iii: env.iii,
      localEmbedding: localEmbeddingReady(),
      service: env.service,
      ports: { rest: PORT, streams: STREAMS_PORT, viewer: VIEWER_PORT },
      dataHome: CrossAgentCodingHome(),
      serviceDir: serviceWorkDir(),
      modelCacheDir: modelCacheDir(),
    },
    agents: agentClientStatuses(),
  };
}

// --- actions ----------------------------------------------------------------
// Each action streams progress via pushLog/pushFeedback and resolves to {ok}.
// `busy` serializes them so the UI cannot fire overlapping installs/starts.
async function runAction(name, params = {}) {
  if (busy) {
    pushFeedback(t('GuiBusy'), 'warn');
    return { ok: false, reason: 'busy' };
  }
  busy = true;
  broadcast({ type: 'busy', busy: true });
  try {
    switch (name) {
      case 'configure-one': {
        const target = agentTargets().find((x) => x.id === params.id);
        if (!target) return { ok: false, reason: 'unknown-agent' };
        try {
          const written = configureTarget(target);
          pushLog('  ' + t('ConfigureWrote', target.name, written));
          pushFeedback(t('ConfigureWrote', target.name, written), 'ok');
          return { ok: true };
        } catch (e) {
          pushLog('  ' + t('ConfigureSkip', target.name, e.message));
          pushFeedback(t('ConfigureSkip', target.name, e.message), 'warn');
          return { ok: false, error: e.message };
        }
      }
      case 'install':
        await installAll(pushLog);
        pushFeedback(t('InstallDone'), 'ok');
        return { ok: true };
      case 'start': {
        const r = await startService(pushLog);
        pushFeedback(r.ok ? t('StartOk', PORT) : t('GuiStopped'), r.ok ? 'ok' : 'warn');
        return r;
      }
      case 'stop': {
        const r = await stopService(pushLog);
        pushFeedback(r.ok ? t('StopOk') : t('StopNothing'), 'info');
        return r;
      }
      case 'configure': {
        pushLog(t('Configuring'));
        for (const c of configureAllAgents()) {
          if (c.configured) pushLog('  ' + t('ConfigureWrote', c.name, c.path));
          else pushLog('  ' + t('ConfigureSkip', c.name, c.error || 'not detected'));
        }
        pushFeedback(t('ConfigureDone'), 'ok');
        return { ok: true };
      }
      case 'mcp-copy': {
        const ok = pbcopy(MCP_CONFIG_JSON);
        pushLog(ok ? t('McpCopied') : t('McpCopyFail'));
        pushFeedback(ok ? t('McpCopied') : t('McpCopyFail'), ok ? 'ok' : 'warn');
        return { ok };
      }
      case 'cli-copy': {
        const ok = pbcopy(cliConfigCommands());
        pushLog(ok ? t('GuiCliCopied') : t('McpCopyFail'));
        pushFeedback(ok ? t('GuiCliCopied') : t('McpCopyFail'), ok ? 'ok' : 'warn');
        return { ok };
      }
      case 'viewer': {
        const r = await openViewer(pushLog);
        if (!r.ok) pushFeedback(t('ViewerNotRunning'), 'warn');
        return r;
      }
      case 'sync-shared': {
        const paths = syncSharedAgentFiles();
        for (const p of paths) pushLog('  ' + p);
        pushFeedback(t('SyncSharedDone'), 'ok');
        return { ok: true };
      }
      case 'install-local-embedding': {
        const r = installLocalEmbedding(pushLog);
        pushFeedback(r.ok ? t('LocalEmbeddingInstalled') : t('LocalEmbeddingInstallFail', ''), r.ok ? 'ok' : 'warn');
        return r;
      }
      case 'bridge': {
        const dir = chooseFolder(t('BridgeWorkspacePrompt'), CrossAgentCodingHome());
        if (!dir) return { ok: false, reason: 'cancelled' };
        const ws = initializeWorkspaceMemory(dir);
        pushLog(t('BridgeWorkspaceDone', ws.workspacePath));
        pushFeedback(t('BridgeWorkspaceDone', ws.workspacePath), 'ok');
        return { ok: true };
      }
      case 'migrate': {
        // params.key: home | serviceDir | modelCacheDir
        const key = params.key || 'home';
        const promptKey =
          key === 'modelCacheDir' ? 'StoragePickModel' : key === 'serviceDir' ? 'StoragePickService' : 'MigrateDataPrompt';
        const current =
          key === 'modelCacheDir' ? modelCacheDir() : key === 'serviceDir' ? serviceWorkDir() : CrossAgentCodingHome();
        const dir = chooseFolder(t(promptKey), current);
        if (!dir) return { ok: false, reason: 'cancelled' };
        const result = key === 'home' ? moveCrossAgentCodingHome(dir) : moveStorageLocation(key, dir);
        const newDir = result.newDir || result.newHome;
        pushLog(t('StorageMigrated', newDir));
        pushFeedback(t('StorageMigrated', newDir), 'ok');
        return { ok: true };
      }
      case 'refresh':
        // Status is re-fetched by the client via /api/state; nothing to do here.
        return { ok: true };
      default:
        return { ok: false, reason: 'unknown-action' };
    }
  } finally {
    busy = false;
    broadcast({ type: 'busy', busy: false });
    broadcast({ type: 'done', action: name });
  }
}

// --- HTTP plumbing ----------------------------------------------------------
function sendJson(res, obj, code = 200) {
  const body = JSON.stringify(obj);
  res.writeHead(code, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(body);
}

// Read a request body to a string (capped at 1 MB).
function readBody(req) {
  return new Promise((resolve) => {
    let data = '';
    req.on('data', (c) => {
      data += c;
      if (data.length > 1_000_000) req.destroy();
    });
    req.on('end', () => resolve(data));
    req.on('error', () => resolve(''));
  });
}

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
};

function serveStatic(res, urlPath) {
  const rel = urlPath === '/' ? 'index.html' : urlPath.replace(/^\/+/, '');
  const full = path.normalize(path.join(WEB_DIR, rel));
  if (!full.startsWith(WEB_DIR)) {
    res.writeHead(403);
    res.end('forbidden');
    return;
  }
  fs.readFile(full, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('not found');
      return;
    }
    res.writeHead(200, { 'Content-Type': MIME[path.extname(full)] || 'application/octet-stream' });
    res.end(data);
  });
}

// Once the GUI window has connected at least once, treat "all clients gone" as
// "the user closed the window" and exit shortly after — so closing the browser
// window quits the manager like a normal app (a page refresh reconnects within
// the grace window, so it is not mistaken for a close).
let everConnected = false;
let quitTimer = null;

function handleSse(res) {
  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    Connection: 'keep-alive',
  });
  res.write(': connected\n\n');
  clients.add(res);
  everConnected = true;
  if (quitTimer) {
    clearTimeout(quitTimer);
    quitTimer = null;
  }
  const keepAlive = setInterval(() => {
    try {
      res.write(': ping\n\n');
    } catch {
      // ignore
    }
  }, 25000);
  res.on('close', () => {
    clearInterval(keepAlive);
    clients.delete(res);
    if (everConnected && clients.size === 0 && !quitTimer) {
      quitTimer = setTimeout(() => {
        if (clients.size === 0) process.exit(0);
      }, 3000);
    }
  });
}

export function createServer() {
  return http.createServer(async (req, res) => {
    const url = new URL(req.url, 'http://localhost');
    const pathname = url.pathname;

    try {
      if (pathname === '/api/state') {
        return sendJson(res, await buildState());
      }
      if (pathname === '/api/events') {
        return handleSse(res);
      }
      if (pathname === '/api/lang') {
        const lang = url.searchParams.get('lang') || 'zh';
        setLang(lang);
        return sendJson(res, { ok: true, lang: getLang() });
      }
      if (pathname === '/api/memory' && req.method === 'GET') {
        return sendJson(res, getMemorySettings());
      }
      if (pathname === '/api/memory' && req.method === 'POST') {
        let obj = {};
        try {
          obj = JSON.parse((await readBody(req)) || '{}');
        } catch {
          // keep defaults
        }
        saveMemorySettings(obj);
        pushLog(t('MemorySettingsSaved'));
        pushFeedback(t('MemorySettingsSaved'), 'ok');
        return sendJson(res, { ok: true });
      }
      if (pathname === '/api/quit') {
        sendJson(res, { ok: true });
        setTimeout(() => process.exit(0), 100);
        return;
      }
      if (pathname.startsWith('/api/action/') && req.method === 'POST') {
        const name = pathname.slice('/api/action/'.length);
        const r = await runAction(name, { id: url.searchParams.get('id') });
        return sendJson(res, r);
      }
      if (req.method === 'GET') {
        return serveStatic(res, pathname);
      }
      res.writeHead(404);
      res.end('not found');
    } catch (e) {
      sendJson(res, { ok: false, error: String(e && e.message ? e.message : e) }, 500);
    }
  });
}

// Find a free TCP port starting at `start` (the GUI control port is separate
// from the AgentMemory service ports 3111-3113).
function findFreePort(start) {
  return new Promise((resolve) => {
    const tryPort = (p) => {
      const srv = net.createServer();
      srv.once('error', () => tryPort(p + 1));
      srv.once('listening', () => {
        srv.close(() => resolve(p));
      });
      srv.listen(p, '127.0.0.1');
    };
    tryPort(start);
  });
}

// Launch the GUI in a chromeless app window if Chrome/Edge/Brave is available,
// otherwise fall back to the default browser via `open`.
//
// IMPORTANT: use async `spawn` (detached + unref), NOT spawnSync. On first
// launch the browser binary becomes a long-lived foreground process, and
// spawnSync would block this Node thread until that browser quit — freezing the
// HTTP server so the page could never load its data (a blank window).
function openGui(urlStr) {
  const appBrowsers = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
    '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',
  ];
  for (const bin of appBrowsers) {
    if (fs.existsSync(bin)) {
      try {
        const child = spawn(bin, [`--app=${urlStr}`, '--window-size=1200,820'], {
          detached: true,
          stdio: 'ignore',
        });
        child.unref();
        return true;
      } catch {
        // try next
      }
    }
  }
  // `open` returns immediately, so it never blocks the event loop.
  spawn('open', [urlStr], { detached: true, stdio: 'ignore' }).unref();
  return true;
}

// Start the control server, open the GUI, and keep the process alive. Returns
// the chosen port.
export async function runGui() {
  const port = await findFreePort(38010);
  const server = createServer();
  await new Promise((resolve) => server.listen(port, '127.0.0.1', resolve));
  const urlStr = `http://localhost:${port}/`;
  console.log(`CrossAgentCoding GUI: ${urlStr}`);
  console.log('关闭此终端或在界面点击「退出」可结束。/ Close this terminal or click “Quit” to stop.');
  // Seed the log panel once a client connects shortly after open.
  setTimeout(() => {
    pushLog(t('GuiInitLog1'));
    pushLog(t('GuiInitLog2'));
    pushLog(t('GuiInitLog3'));
  }, 800);
  openGui(urlStr);
  return port;
}
