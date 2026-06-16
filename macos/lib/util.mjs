// Cross-platform-agnostic helpers for the macOS Node.js manager.
// Pure standard-library only (no npm dependencies), no platform.mjs import so
// platform.mjs can depend on this without a cycle.
import fs from 'node:fs';
import path from 'node:path';
import net from 'node:net';
import { spawnSync } from 'node:child_process';

// Timestamp matching the PowerShell manager's backup suffix: yyyyMMddHHmmss.
export function timestamp() {
  const d = new Date();
  const p = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}${p(d.getMonth() + 1)}${p(d.getDate())}${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`;
}

// Read a JSON file, returning {} on missing/empty/parse-error (mirrors
// Read-JsonObject in AgentMemoryManager.ps1).
export function readJson(filePath) {
  try {
    if (fs.existsSync(filePath)) {
      const raw = fs.readFileSync(filePath, 'utf8');
      if (raw && raw.trim().length > 0) return JSON.parse(raw);
    }
  } catch {
    // fall through
  }
  return {};
}

// Read a text file, returning "" on any failure.
export function readText(filePath) {
  try {
    if (fs.existsSync(filePath)) return fs.readFileSync(filePath, 'utf8');
  } catch {
    // fall through
  }
  return '';
}

// Copy an existing file to `<path>.bak-<timestamp>` before it is overwritten
// (mirrors Backup-ConfigFile).
export function backupFile(filePath) {
  try {
    if (fs.existsSync(filePath)) {
      fs.copyFileSync(filePath, `${filePath}.bak-${timestamp()}`);
    }
  } catch {
    // best-effort backup
  }
}

export function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

// Write a text file, creating parent dirs and backing up any existing file.
export function writeTextWithBackup(filePath, content) {
  ensureDir(path.dirname(filePath));
  backupFile(filePath);
  fs.writeFileSync(filePath, content, 'utf8');
  return filePath;
}

// Write a JSON file (2-space indent), creating parent dirs and backing up any
// existing file (mirrors Write-JsonObject).
export function writeJsonWithBackup(filePath, obj) {
  return writeTextWithBackup(filePath, JSON.stringify(obj, null, 2) + '\n');
}

// Resolve an executable's absolute path via `which`, or "" when not found.
export function which(name) {
  try {
    const r = spawnSync('/usr/bin/which', [name], { encoding: 'utf8' });
    if (r.status === 0 && r.stdout) {
      const first = r.stdout.split('\n').map((s) => s.trim()).find(Boolean);
      if (first) return first;
    }
  } catch {
    // fall through
  }
  return '';
}

export function commandExists(name) {
  return which(name).length > 0;
}

// True when something is accepting TCP connections on localhost:<port> — i.e.
// the service is up. This mirrors the Windows check (port in LISTEN state)
// rather than probing an HTTP route: AgentMemory's REST server answers 404 for
// /api/health (and every other guessed path), so an HTTP-200 probe never
// matched even though the service had started — the start loop always timed out.
export function healthCheck(port, timeoutMs = 2000) {
  return new Promise((resolve) => {
    const socket = net.connect({ host: '127.0.0.1', port });
    let done = false;
    const finish = (ok) => {
      if (done) return;
      done = true;
      socket.destroy();
      resolve(ok);
    };
    socket.setTimeout(timeoutMs);
    socket.once('connect', () => finish(true));
    socket.once('timeout', () => finish(false));
    socket.once('error', () => finish(false));
  });
}

// PIDs of processes listening on any of the given TCP ports (via lsof).
export function listeningPids(ports) {
  const pids = new Set();
  for (const port of ports) {
    try {
      const r = spawnSync('lsof', ['-nP', `-iTCP:${port}`, '-sTCP:LISTEN', '-t'], {
        encoding: 'utf8',
      });
      if (r.stdout) {
        for (const line of r.stdout.split('\n')) {
          const pid = parseInt(line.trim(), 10);
          if (Number.isInteger(pid) && pid > 0) pids.add(pid);
        }
      }
    } catch {
      // lsof unavailable or no match
    }
  }
  return [...pids];
}

// Full command line of a pid (via ps), lowercased, or "" on failure. Used to
// decide whether a listener "looks like AgentMemory".
export function processCommandLine(pid) {
  try {
    const r = spawnSync('ps', ['-p', String(pid), '-o', 'command='], { encoding: 'utf8' });
    if (r.status === 0 && r.stdout) return r.stdout.trim().toLowerCase();
  } catch {
    // fall through
  }
  return '';
}

export function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// Copy text to the macOS clipboard via pbcopy. Returns true on success.
export function pbcopy(text) {
  try {
    const r = spawnSync('pbcopy', [], { input: text, encoding: 'utf8' });
    return r.status === 0;
  } catch {
    return false;
  }
}
