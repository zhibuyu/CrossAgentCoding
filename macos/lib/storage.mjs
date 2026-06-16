// Relocatable storage: move the AgentMemory service dir, the model cache dir, or
// the whole CrossAgnetCoding data home, copying existing data and repointing
// settings.json. Mirrors Move-StorageLocation (ps1:1901), Set-StorageSetting
// (ps1:1860) and Move-CrossAgnetCodingHome (ps1:1783).
import fs from 'node:fs';
import path from 'node:path';
import {
  readSettings,
  writeSettings,
  crossAgnetCodingHome,
  serviceWorkDir,
  modelCacheDir,
} from './platform.mjs';
import { ensureDir } from './util.mjs';

// Create `dir` and confirm it is writable before we migrate anything into it.
function assertWritable(dir) {
  ensureDir(dir);
  const probe = path.join(dir, '.write-test');
  fs.writeFileSync(probe, 'ok');
  fs.rmSync(probe, { force: true });
}

function copyDirContents(from, to) {
  ensureDir(to);
  if (!fs.existsSync(from)) return;
  for (const entry of fs.readdirSync(from)) {
    fs.cpSync(path.join(from, entry), path.join(to, entry), { recursive: true, force: true });
  }
}

const trimSep = (p) => p.replace(/[/\\]+$/, '');
// True when `target` is the same as, or nested inside, `current`.
function isInside(target, current) {
  const t = trimSep(target);
  const c = trimSep(current);
  return t === c || t.startsWith(c + path.sep);
}

// Persist storage.<key> in settings.json (key: serviceDir | modelCacheDir).
export function setStorageSetting(key, value) {
  const settings = readSettings();
  const storage = settings && typeof settings.storage === 'object' && settings.storage ? settings.storage : {};
  storage[key] = value;
  settings.storage = storage;
  return writeSettings(settings);
}

// Move serviceDir or modelCacheDir to `newDir`. Copies existing data unless
// switchOnly. Returns { key, oldDir, newDir, migrated }.
export function moveStorageLocation(key, newDir, switchOnly = false) {
  if (!newDir || !String(newDir).trim()) throw new Error('New storage directory is required');
  const target = path.resolve(newDir);
  const current = key === 'modelCacheDir' ? modelCacheDir() : serviceWorkDir();

  assertWritable(target);
  if (trimSep(target) !== trimSep(current) && isInside(target, current)) {
    throw new Error('New directory cannot be inside the current storage directory during migration');
  }
  if (!switchOnly && trimSep(target) !== trimSep(current) && fs.existsSync(current)) {
    copyDirContents(current, target);
  }
  setStorageSetting(key, target);
  return { key, oldDir: current, newDir: target, migrated: !switchOnly };
}

// Move the whole data home to `newHome`, copying contents and repointing
// settings.dataHome. Returns { oldHome, newHome, migrated }.
export function moveCrossAgnetCodingHome(newHome, switchOnly = false) {
  if (!newHome || !String(newHome).trim()) throw new Error('New CrossAgnetCoding data directory is required');
  const oldHome = crossAgnetCodingHome();
  const target = path.resolve(newHome);

  assertWritable(target);
  const sameDir = trimSep(target) === trimSep(oldHome);
  if (!switchOnly && !sameDir && fs.existsSync(oldHome)) {
    if (isInside(target, oldHome)) {
      throw new Error('New data directory cannot be inside the current data directory during migration');
    }
    copyDirContents(oldHome, target);
  }

  const settings = readSettings();
  settings.dataHome = target;
  settings.updatedAt = new Date().toISOString();
  writeSettings(settings);
  return { oldHome, newHome: target, migrated: !switchOnly && !sameDir };
}
