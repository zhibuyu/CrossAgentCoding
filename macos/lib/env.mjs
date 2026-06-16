// Environment detection: Node.js, AgentMemory CLI, iii-engine, and the running
// service. Mirrors Get-EnvironmentStatus / Get-AgentMemoryVersion.
import fs from 'node:fs';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import {
  PORT,
  STREAMS_PORT,
  VIEWER_PORT,
  NPM_GLOBAL,
  agentMemoryCliCandidates,
  agentMemoryPackageJsonCandidates,
  iiiCandidates,
} from './platform.mjs';
import { which, readJson, healthCheck } from './util.mjs';

// Where @xenova/transformers (Transformers.js) may resolve from for local
// semantic search: the npm global lib dir, a flat prefix, or bundled inside the
// installed agentmemory package. Mirrors Get-XenovaTransformersPath (ps1:1762).
export function localEmbeddingReady() {
  const candidates = [
    path.join(NPM_GLOBAL, 'lib', 'node_modules', '@xenova', 'transformers'),
    path.join(NPM_GLOBAL, 'node_modules', '@xenova', 'transformers'),
    path.join(NPM_GLOBAL, 'lib', 'node_modules', '@agentmemory', 'agentmemory', 'node_modules', '@xenova', 'transformers'),
  ];
  return candidates.some((c) => fs.existsSync(c));
}

export function nodeVersion() {
  try {
    const r = spawnSync('node', ['--version'], { encoding: 'utf8' });
    if (r.status === 0 && r.stdout) return r.stdout.trim();
  } catch {
    // fall through
  }
  return '';
}

// Absolute path of the global agentmemory CLI, or "" if not found.
export function agentMemoryCliPath() {
  for (const candidate of agentMemoryCliCandidates()) {
    if (fs.existsSync(candidate)) return candidate;
  }
  const w = which('agentmemory');
  return w || '';
}

// Installed AgentMemory version read from its package.json, or "".
export function agentMemoryVersion() {
  for (const pkg of agentMemoryPackageJsonCandidates()) {
    if (fs.existsSync(pkg)) {
      const v = readJson(pkg).version;
      if (v && String(v).trim()) return String(v).trim();
    }
  }
  return '';
}

export function iiiPath() {
  for (const candidate of iiiCandidates()) {
    if (fs.existsSync(candidate)) return candidate;
  }
  return '';
}

export async function serviceRunning() {
  return healthCheck(PORT, 2000);
}

// Full environment snapshot (mirrors the Get-EnvironmentStatus object).
export async function environmentStatus() {
  const node = nodeVersion();
  const amCli = agentMemoryCliPath();
  const iii = iiiPath();
  return {
    node: node.length > 0,
    nodeVersion: node,
    agentMemory: amCli.length > 0,
    agentMemoryCli: amCli,
    agentMemoryVersion: agentMemoryVersion(),
    iii: iii.length > 0,
    iiiPath: iii,
    service: await serviceRunning(),
    ports: { rest: PORT, streams: STREAMS_PORT, viewer: VIEWER_PORT },
  };
}

// Names of missing core dependencies (mirrors Get-MissingDependencyNames).
export async function missingDependencies() {
  const s = await environmentStatus();
  const missing = [];
  if (!s.node) missing.push('Node.js');
  if (!s.agentMemory) missing.push('AgentMemory');
  if (!s.iii) missing.push('iii-engine');
  return missing;
}
