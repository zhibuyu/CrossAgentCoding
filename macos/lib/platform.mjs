// macOS path and architecture constants, plus settings/storage resolution.
// Mirrors the non-Windows branch of AgentMemoryManager.ps1's platform block and
// Get-CrossAgnetCodingHome / Get-StorageSettings.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { readJson, ensureDir } from './util.mjs';

export const HOME = os.homedir();
// macOS app data lives under ~/Library/Application Support (NOT ~/.config).
export const APP_SUPPORT = path.join(HOME, 'Library', 'Application Support');

export const AM_DIR = path.join(HOME, '.agentmemory');
export const LOCAL_BIN = path.join(HOME, '.local', 'bin');
export const NPM_GLOBAL = path.join(HOME, '.npm-global');

export const APP_NAME = 'CrossAgnetCoding';
export const APP_VERSION = '0.0.1';
export const III_VERSION = 'v0.11.2';

export const PORT = 3111;
export const STREAMS_PORT = 3112;
export const VIEWER_PORT = 3113;
export const ENGINE_PORT = 49134;

export const HF_MIRROR_URL = 'https://hf-mirror.com';

export const ARCH = os.arch(); // 'arm64' | 'x64'
export const IS_ARM64 = ARCH === 'arm64';

// iii-engine release target triple for this Mac (mirrors ps1:3014-3015).
export function iiiTarget() {
  return IS_ARM64 ? 'aarch64-apple-darwin' : 'x86_64-apple-darwin';
}

// macOS/Linux iii assets ship as .tar.gz (only the Windows asset is a .zip).
// The release tag itself contains a slash ("iii/vX.Y.Z"), so the path segment
// after /download/ is "iii/<version>".
export function iiiUrl() {
  return `https://github.com/iii-hq/iii/releases/download/iii/${III_VERSION}/iii-${iiiTarget()}.tar.gz`;
}

export function defaultHome() {
  return path.join(HOME, '.CrossAgnetCoding');
}

export function settingsPath() {
  if (process.env.CROSSAGNETCODING_SETTINGS && process.env.CROSSAGNETCODING_SETTINGS.trim()) {
    return process.env.CROSSAGNETCODING_SETTINGS;
  }
  return path.join(defaultHome(), 'settings.json');
}

export function readSettings() {
  return readJson(settingsPath());
}

// Persist the CrossAgnetCoding settings object (2-space JSON), creating the
// data home if needed. Returns the settings path.
export function writeSettings(settings) {
  const p = settingsPath();
  ensureDir(path.dirname(p));
  fs.writeFileSync(p, JSON.stringify(settings, null, 2) + '\n', 'utf8');
  return p;
}

// Resolved CrossAgnetCoding data home: env override > settings.dataHome > default.
export function crossAgnetCodingHome() {
  if (process.env.CROSSAGNETCODING_HOME && process.env.CROSSAGNETCODING_HOME.trim()) {
    return path.resolve(process.env.CROSSAGNETCODING_HOME);
  }
  const s = readSettings();
  if (s && typeof s.dataHome === 'string' && s.dataHome.trim()) {
    return path.resolve(s.dataHome);
  }
  return defaultHome();
}

// Relocatable storage roots (mirrors Get-StorageSettings).
export function storageSettings() {
  const s = readSettings();
  const storage = s && typeof s.storage === 'object' && s.storage ? s.storage : {};

  let serviceDir = AM_DIR;
  if (storage.serviceDir && String(storage.serviceDir).trim()) {
    serviceDir = path.resolve(String(storage.serviceDir));
  }

  let modelCacheDir = path.join(serviceDir, 'models');
  if (storage.modelCacheDir && String(storage.modelCacheDir).trim()) {
    modelCacheDir = path.resolve(String(storage.modelCacheDir));
  }

  return { serviceDir, modelCacheDir };
}

export function serviceWorkDir() {
  return storageSettings().serviceDir;
}

export function modelCacheDir() {
  return storageSettings().modelCacheDir;
}

export function serviceLogPath() {
  return path.join(serviceWorkDir(), 'agentmemory-service.log');
}

// Candidate locations for the globally-installed `agentmemory` CLI on macOS.
// npm's global bin lives at <prefix>/bin, so the manager checks its own prefix
// plus the common Homebrew / system prefixes.
export function agentMemoryCliCandidates() {
  return [
    path.join(NPM_GLOBAL, 'bin', 'agentmemory'),
    '/opt/homebrew/bin/agentmemory',
    '/usr/local/bin/agentmemory',
  ];
}

export function agentMemoryPackageJsonCandidates() {
  return [
    path.join(NPM_GLOBAL, 'lib', 'node_modules', '@agentmemory', 'agentmemory', 'package.json'),
    path.join(NPM_GLOBAL, 'node_modules', '@agentmemory', 'agentmemory', 'package.json'),
    '/opt/homebrew/lib/node_modules/@agentmemory/agentmemory/package.json',
    '/usr/local/lib/node_modules/@agentmemory/agentmemory/package.json',
  ];
}

export function iiiCandidates() {
  return [path.join(AM_DIR, 'bin', 'iii'), path.join(LOCAL_BIN, 'iii')];
}
