// Start / stop the AgentMemory service and open the memory viewer.
// Mirrors Start-AgentMemory (ps1:3057), Stop-AgentMemoryProcesses (ps1:3201)
// and Open-MemoryViewer (ps1:3300).
import fs from 'node:fs';
import path from 'node:path';
import { spawn, spawnSync } from 'node:child_process';
import {
  HOME,
  AM_DIR,
  LOCAL_BIN,
  NPM_GLOBAL,
  PORT,
  STREAMS_PORT,
  VIEWER_PORT,
  ENGINE_PORT,
  serviceWorkDir,
  modelCacheDir,
  serviceLogPath,
} from './platform.mjs';
import { agentMemoryCliPath, missingDependencies, serviceRunning } from './env.mjs';
import { memoryEnvMap } from './memory.mjs';
import {
  listeningPids,
  processCommandLine,
  ensureDir,
  healthCheck,
  sleep,
} from './util.mjs';
import { t } from './i18n.mjs';

const PID_FILES = ['iii.pid', 'engine-state.json', 'worker.pid'];

// Environment the AgentMemory child inherits: augmented PATH so it can find
// node/iii/agentmemory, plus the relocatable model-cache dir.
function childEnv() {
  const mc = modelCacheDir();
  const extra = [
    path.join(AM_DIR, 'bin'),
    LOCAL_BIN,
    path.join(NPM_GLOBAL, 'bin'),
    '/opt/homebrew/bin',
    '/usr/local/bin',
  ];
  const seen = new Set();
  const parts = [];
  for (const p of [...extra, ...(process.env.PATH || '').split(':')]) {
    if (p && !seen.has(p)) {
      seen.add(p);
      parts.push(p);
    }
  }
  const env = {
    ...process.env,
    PATH: parts.join(':'),
    HOME,
    TRANSFORMERS_CACHE: mc,
    HF_HOME: mc,
    HF_HUB_CACHE: mc,
  };

  // Apply the user's memory settings (embedding provider/keys, LLM provider,
  // tool surface, HF mirror). Non-empty values are set; empty values are cleared
  // so turning an option off actually takes effect on the next start.
  for (const [k, v] of Object.entries(memoryEnvMap())) {
    if (v != null && String(v).trim() !== '') env[k] = String(v);
    else delete env[k];
  }
  return env;
}

function killPid(pid) {
  try {
    process.kill(pid, 'SIGTERM');
    return true;
  } catch {
    return false;
  }
}

// Kill stale AgentMemory / iii processes so a clean (re)start is not blocked by
// a zombie still holding the engine/stream ports. Returns the kill count.
export function stopAgentMemoryProcesses() {
  const targets = new Set();

  for (const pid of listeningPids([PORT, STREAMS_PORT, VIEWER_PORT, ENGINE_PORT])) {
    const cmd = processCommandLine(pid);
    if (/agentmemory/.test(cmd) || /\biii\b/.test(cmd)) targets.add(pid);
  }

  // Exact-name iii processes (mirrors Get-Process -Name "iii").
  try {
    const r = spawnSync('pgrep', ['-x', 'iii'], { encoding: 'utf8' });
    if (r.stdout) {
      for (const line of r.stdout.split('\n')) {
        const pid = parseInt(line.trim(), 10);
        if (Number.isInteger(pid) && pid > 0) targets.add(pid);
      }
    }
  } catch {
    // pgrep unavailable
  }

  let killed = 0;
  for (const pid of targets) {
    if (killPid(pid)) killed += 1;
  }
  return killed;
}

function removePidFiles() {
  for (const dir of [AM_DIR, serviceWorkDir()]) {
    for (const name of PID_FILES) {
      try {
        fs.rmSync(path.join(dir, name), { force: true });
      } catch {
        // best effort
      }
    }
  }
}

// Returns the listener pids on a port whose command line does NOT look like
// AgentMemory (a genuine conflict that should abort start).
function foreignListeners(ports) {
  const out = [];
  for (const pid of listeningPids(ports)) {
    const cmd = processCommandLine(pid);
    if (!/agentmemory/.test(cmd) && !/\biii\b/.test(cmd)) {
      out.push({ pid, cmd });
    }
  }
  return out;
}

// Start the service. `log` receives progress lines. Returns { ok, reason }.
export async function startService(log = console.log) {
  if (await serviceRunning()) {
    log(t('AlreadyRunning', PORT));
    return { ok: true, reason: 'already-running' };
  }

  const missing = await missingDependencies();
  if (missing.length > 0) {
    log(t('MissingInstallFirst', missing.join(', ')));
    return { ok: false, reason: 'missing-deps' };
  }

  const cleaned = stopAgentMemoryProcesses();
  if (cleaned > 0) {
    log(t('StaleCleaned', cleaned));
    await sleep(2000);
  }

  const conflicts = foreignListeners([STREAMS_PORT, VIEWER_PORT]);
  if (conflicts.length > 0) {
    for (const c of conflicts) {
      log(t('PortConflict', `${STREAMS_PORT}/${VIEWER_PORT}`, c.pid, c.cmd.slice(0, 40)));
    }
    return { ok: false, reason: 'port-conflict' };
  }

  const workDir = serviceWorkDir();
  ensureDir(workDir);
  ensureDir(modelCacheDir());
  removePidFiles();

  const serviceLog = serviceLogPath();
  try {
    fs.rmSync(serviceLog, { force: true });
  } catch {
    // ignore
  }

  log(t('Starting'));
  log(t('ServiceLog', serviceLog));

  const cli = agentMemoryCliPath();
  const logFd = fs.openSync(serviceLog, 'a');
  const child = spawn(cli, [], {
    cwd: workDir,
    env: childEnv(),
    detached: true,
    stdio: ['ignore', logFd, logFd],
  });
  child.unref();

  const timeout = 60;
  let started = false;
  for (let elapsed = 0; elapsed < timeout; elapsed += 3) {
    await sleep(3000);
    if (await healthCheck(PORT, 2000)) {
      started = true;
      break;
    }
    log(t('Waiting', elapsed + 3));
  }

  if (started) {
    log(t('StartOk', PORT));
    return { ok: true, reason: 'started' };
  }
  log(t('StartFail', timeout, serviceLog));
  return { ok: false, reason: 'timeout' };
}

// Stop the service and clean up pid files. Returns { ok, killed }.
export async function stopService(log = console.log) {
  log(t('Stopping'));
  const killed = stopAgentMemoryProcesses();
  removePidFiles();
  await sleep(1000);

  if (killed > 0) {
    log(t('StopOk'));
    return { ok: true, killed };
  }
  log(t('StopNothing'));
  return { ok: false, killed: 0 };
}

// Open the memory viewer in the default browser.
export async function openViewer(log = console.log) {
  if (!(await serviceRunning())) {
    log(t('ViewerNotRunning'));
    return { ok: false };
  }
  const url = `http://localhost:${VIEWER_PORT}`;
  spawnSync('open', [url]);
  log(t('ViewerOpened', url));
  return { ok: true };
}
