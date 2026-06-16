// Memory settings (embedding mode, optional LLM provider, MCP tool surface) and
// their translation into the AgentMemory service environment variables.
// Mirrors Get-MemorySettings (ps1:1576), Save-MemorySettings (ps1:1614),
// Get-ProviderKeyEnvName (ps1:1636) and Get-MemoryEnvMap (ps1:1651).
import { readSettings, writeSettings, modelCacheDir, HF_MIRROR_URL } from './platform.mjs';

function prop(obj, name, def) {
  if (obj && obj[name] != null && String(obj[name]).trim() !== '') return obj[name];
  return def;
}

const toBool = (v) => v === true || v === 'true';

// Effective memory settings with zero-config defaults (keyword search, no LLM,
// core 7-tool surface).
export function getMemorySettings() {
  const s = readSettings();
  const m = s && typeof s.memory === 'object' && s.memory ? s.memory : null;
  return {
    embeddingMode: String(prop(m, 'embeddingMode', 'keyword')), // keyword | local | cloud
    embeddingFormat: String(prop(m, 'embeddingFormat', prop(m, 'embeddingProvider', 'openai'))),
    embeddingBaseUrl: String(prop(m, 'embeddingBaseUrl', '')),
    embeddingModel: String(prop(m, 'embeddingModel', '')),
    embeddingDimensions: String(prop(m, 'embeddingDimensions', '')),
    embeddingApiKey: String(prop(m, 'embeddingApiKey', '')),
    llmFormat: String(prop(m, 'llmFormat', prop(m, 'llmProvider', 'none'))), // none|openai|anthropic|gemini|openrouter|minimax
    llmBaseUrl: String(prop(m, 'llmBaseUrl', '')),
    llmModel: String(prop(m, 'llmModel', '')),
    llmApiKey: String(prop(m, 'llmApiKey', '')),
    tools: String(prop(m, 'tools', 'core')), // core | all
    useHfMirror: m && Object.prototype.hasOwnProperty.call(m, 'useHfMirror') ? toBool(m.useHfMirror) : true,
  };
}

// Persist the memory object under settings.memory. Returns the settings path.
export function saveMemorySettings(memory) {
  const settings = readSettings();
  settings.memory = {
    embeddingMode: String(memory.embeddingMode || 'keyword'),
    embeddingFormat: String(memory.embeddingFormat || 'openai'),
    embeddingBaseUrl: String(memory.embeddingBaseUrl || ''),
    embeddingModel: String(memory.embeddingModel || ''),
    embeddingDimensions: String(memory.embeddingDimensions || ''),
    embeddingApiKey: String(memory.embeddingApiKey || ''),
    llmFormat: String(memory.llmFormat || 'none'),
    llmBaseUrl: String(memory.llmBaseUrl || ''),
    llmModel: String(memory.llmModel || ''),
    llmApiKey: String(memory.llmApiKey || ''),
    tools: String(memory.tools || 'core'),
    useHfMirror: toBool(memory.useHfMirror) || memory.useHfMirror === true,
  };
  return writeSettings(settings);
}

export function providerKeyEnvName(provider) {
  switch (provider) {
    case 'openai': return 'OPENAI_API_KEY';
    case 'gemini': return 'GEMINI_API_KEY';
    case 'anthropic': return 'ANTHROPIC_API_KEY';
    case 'minimax': return 'MINIMAX_API_KEY';
    case 'openrouter': return 'OPENROUTER_API_KEY';
    case 'voyage': return 'VOYAGE_API_KEY';
    case 'cohere': return 'COHERE_API_KEY';
    default: return '';
  }
}

// Every variable this manager owns is present (value or "") so the service env
// can both set and clear them as the user toggles options.
export function memoryEnvMap() {
  const m = getMemorySettings();
  const mc = modelCacheDir();
  const map = {
    EMBEDDING_PROVIDER: '',
    OPENAI_API_KEY: '',
    OPENAI_BASE_URL: '',
    OPENAI_MODEL: '',
    OPENAI_EMBEDDING_MODEL: '',
    OPENAI_EMBEDDING_DIMENSIONS: '',
    GEMINI_API_KEY: '',
    GEMINI_MODEL: '',
    ANTHROPIC_API_KEY: '',
    ANTHROPIC_BASE_URL: '',
    ANTHROPIC_MODEL: '',
    MINIMAX_API_KEY: '',
    MINIMAX_MODEL: '',
    OPENROUTER_API_KEY: '',
    OPENROUTER_MODEL: '',
    OPENROUTER_EMBEDDING_MODEL: '',
    VOYAGE_API_KEY: '',
    COHERE_API_KEY: '',
    AGENTMEMORY_TOOLS: '',
    HF_ENDPOINT: '',
    TRANSFORMERS_CACHE: mc,
    HF_HOME: mc,
    HF_HUB_CACHE: mc,
  };

  const set = (k, v) => {
    if (v != null && String(v).trim() !== '') map[k] = String(v);
  };

  // Embedding leg of hybrid search.
  if (m.embeddingMode === 'local') {
    map.EMBEDDING_PROVIDER = 'local';
    if (m.useHfMirror) map.HF_ENDPOINT = HF_MIRROR_URL;
  } else if (m.embeddingMode === 'cloud') {
    map.EMBEDDING_PROVIDER = m.embeddingFormat;
    const keyName = providerKeyEnvName(m.embeddingFormat);
    if (keyName) set(keyName, m.embeddingApiKey);
    if (m.embeddingFormat === 'openai') {
      set('OPENAI_BASE_URL', m.embeddingBaseUrl);
      set('OPENAI_EMBEDDING_MODEL', m.embeddingModel);
      set('OPENAI_EMBEDDING_DIMENSIONS', m.embeddingDimensions);
    } else if (m.embeddingFormat === 'openrouter') {
      set('OPENROUTER_EMBEDDING_MODEL', m.embeddingModel);
    }
  }
  // keyword mode leaves EMBEDDING_PROVIDER empty so AgentMemory stays BM25-only.

  // LLM provider for compression / summarization (optional).
  if (m.llmFormat && m.llmFormat !== 'none') {
    const keyName = providerKeyEnvName(m.llmFormat);
    if (keyName) set(keyName, m.llmApiKey);
    switch (m.llmFormat) {
      case 'openai':
        set('OPENAI_BASE_URL', m.llmBaseUrl);
        set('OPENAI_MODEL', m.llmModel);
        break;
      case 'anthropic':
        set('ANTHROPIC_BASE_URL', m.llmBaseUrl);
        set('ANTHROPIC_MODEL', m.llmModel);
        break;
      case 'gemini':
        set('GEMINI_MODEL', m.llmModel);
        break;
      case 'openrouter':
        set('OPENROUTER_MODEL', m.llmModel);
        break;
      case 'minimax':
        set('MINIMAX_MODEL', m.llmModel);
        break;
      default:
        break;
    }
  }

  map.AGENTMEMORY_TOOLS = m.tools === 'all' ? 'all' : 'core';
  return map;
}
