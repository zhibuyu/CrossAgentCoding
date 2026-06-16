// Bootstrap installation of Node.js (guided), AgentMemory (npm), and iii-engine
// (GitHub release .tar.gz for macOS). Mirrors Install-All (ps1:2921).
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import https from 'node:https';
import { spawnSync } from 'node:child_process';
import { NPM_GLOBAL, AM_DIR, LOCAL_BIN, III_VERSION, iiiUrl } from './platform.mjs';
import { nodeVersion, agentMemoryCliPath, iiiPath, localEmbeddingReady } from './env.mjs';
import { commandExists, ensureDir } from './util.mjs';
import { t } from './i18n.mjs';

// Node's https.get fallback. Follows up to 5 redirects (GitHub release assets
// redirect to a CDN) and aborts if the connection stalls, so a flaky CDN can
// never hang the installer forever.
function downloadFileHttps(url, dest, redirects = 0) {
  return new Promise((resolve, reject) => {
    if (redirects > 5) return reject(new Error('too many redirects'));
    const req = https.get(url, (res) => {
      const code = res.statusCode || 0;
      if (code >= 300 && code < 400 && res.headers.location) {
        res.resume();
        resolve(downloadFileHttps(res.headers.location, dest, redirects + 1));
        return;
      }
      if (code !== 200) {
        res.resume();
        reject(new Error(`HTTP ${code}`));
        return;
      }
      const file = fs.createWriteStream(dest);
      res.pipe(file);
      file.on('finish', () => file.close(() => resolve()));
      file.on('error', reject);
    });
    // Abort a stalled connection rather than hanging indefinitely.
    req.setTimeout(60000, () => req.destroy(new Error('download timed out')));
    req.on('error', reject);
  });
}

// Download a URL to `dest`. Prefer curl (always present on macOS): it follows
// redirects to GitHub's release CDN reliably and honours connect/transfer
// timeouts, whereas Node's https.get has been observed to stall mid-stream on
// that CDN. Falls back to the Node implementation if curl is missing or fails.
async function downloadFile(url, dest) {
  if (commandExists('curl')) {
    const r = spawnSync(
      'curl',
      ['-fL', '--connect-timeout', '30', '--retry', '2', '-o', dest, url],
      { stdio: 'ignore' }
    );
    if (r.status === 0 && fs.existsSync(dest) && fs.statSync(dest).size > 0) return;
    fs.rmSync(dest, { force: true });
  }
  return downloadFileHttps(url, dest);
}

function findFile(dir, name) {
  let entries = [];
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return null;
  }
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      const found = findFile(full, name);
      if (found) return found;
    } else if (entry.name === name) {
      return full;
    }
  }
  return null;
}

// Guide / perform Node.js installation. If Homebrew is present, runs
// `brew install node@20` (inherits stdio so the user sees progress); otherwise
// prints guidance and opens nodejs.org.
export function installNode(log = console.log) {
  if (nodeVersion()) {
    log(t('AlreadyInstalled', 'Node.js'));
    return { ok: true };
  }
  if (commandExists('brew')) {
    log(t('NodeNeeded'));
    const r = spawnSync('brew', ['install', 'node@20'], { stdio: 'inherit' });
    if (r.status === 0 && nodeVersion()) {
      log(t('InstallOk', 'Node.js'));
      return { ok: true };
    }
    log(t('InstallFail', 'Node.js', `brew exit ${r.status}`));
    return { ok: false };
  }
  log(t('NodeNeededNoBrew'));
  spawnSync('open', ['https://nodejs.org/']);
  return { ok: false };
}

// Install AgentMemory globally under ~/.npm-global (sets npm prefix so the CLI
// lands at ~/.npm-global/bin/agentmemory).
export function installAgentMemory(log = console.log) {
  if (agentMemoryCliPath()) {
    log(t('AlreadyInstalled', 'AgentMemory'));
    return { ok: true };
  }
  if (!nodeVersion()) {
    log(t('MissingNodeFirst'));
    return { ok: false };
  }
  log(t('InstallingAgentMemory'));
  ensureDir(path.join(NPM_GLOBAL, 'bin'));
  const r = spawnSync('npm', ['install', '-g', '@agentmemory/agentmemory'], {
    stdio: 'inherit',
    env: { ...process.env, npm_config_prefix: NPM_GLOBAL },
  });
  if (r.status === 0 && agentMemoryCliPath()) {
    log(t('InstallOk', 'AgentMemory'));
    return { ok: true };
  }
  log(t('InstallFail', 'AgentMemory', `npm exit ${r.status}`));
  return { ok: false };
}

// Download + extract the iii-engine release matching this Mac's architecture and
// place the binary in ~/.agentmemory/bin/iii and ~/.local/bin/iii.
export async function installIii(log = console.log) {
  if (iiiPath()) {
    log(t('AlreadyInstalled', 'iii-engine'));
    return { ok: true };
  }
  log(t('InstallingIii', III_VERSION));
  const tmpArchive = path.join(os.tmpdir(), 'agentmemory-iii.tar.gz');
  const tmpDir = path.join(os.tmpdir(), 'agentmemory-iii');
  try {
    await downloadFile(iiiUrl(), tmpArchive);
    fs.rmSync(tmpDir, { recursive: true, force: true });
    ensureDir(tmpDir);

    // macOS iii assets are gzip-compressed tarballs (not zips).
    const untar = spawnSync('tar', ['-xzf', tmpArchive, '-C', tmpDir], { encoding: 'utf8' });
    if (untar.status !== 0) throw new Error(`tar failed: ${untar.stderr || untar.status}`);

    const found = findFile(tmpDir, 'iii');
    if (!found) throw new Error('iii binary not found in archive');

    ensureDir(path.join(AM_DIR, 'bin'));
    ensureDir(LOCAL_BIN);
    for (const dest of [path.join(AM_DIR, 'bin', 'iii'), path.join(LOCAL_BIN, 'iii')]) {
      fs.copyFileSync(found, dest);
      fs.chmodSync(dest, 0o755);
    }

    fs.rmSync(tmpArchive, { force: true });
    fs.rmSync(tmpDir, { recursive: true, force: true });

    if (iiiPath()) {
      log(t('InstallOk', 'iii-engine'));
      return { ok: true };
    }
    throw new Error('iii not present after copy');
  } catch (e) {
    log(t('InstallFail', 'iii-engine', e.message));
    return { ok: false };
  }
}

// Install @xenova/transformers globally so AgentMemory can resolve it for local
// (offline) semantic search. Mirrors Install-LocalEmbedding (ps1:3350).
export function installLocalEmbedding(log = console.log) {
  if (localEmbeddingReady()) {
    log(t('LocalEmbeddingReady'));
    return { ok: true };
  }
  if (!nodeVersion()) {
    log(t('MissingNodeFirst'));
    return { ok: false };
  }
  log(t('InstallingLocalEmbedding'));
  ensureDir(path.join(NPM_GLOBAL, 'bin'));
  const r = spawnSync('npm', ['install', '-g', '@xenova/transformers'], {
    stdio: 'inherit',
    env: { ...process.env, npm_config_prefix: NPM_GLOBAL },
  });
  if (r.status === 0 && localEmbeddingReady()) {
    log(t('LocalEmbeddingInstalled'));
    return { ok: true };
  }
  log(t('LocalEmbeddingInstallFail', `npm exit ${r.status}`));
  return { ok: false };
}

// Run the full install flow: Node (guided) → AgentMemory → iii-engine.
export async function installAll(log = console.log) {
  log(t('InstallStart'));
  installNode(log);
  installAgentMemory(log);
  await installIii(log);
  log(t('InstallDone'));
}
