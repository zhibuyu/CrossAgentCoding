<p align="center">
  <img src="https://img.shields.io/badge/version-0.0.1-blue" alt="version">
  <img src="https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-0078D6" alt="platform">
  <img src="https://img.shields.io/badge/arch-x64%20%7C%20ARM64-orange" alt="arch">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="license">
  <img src="https://img.shields.io/badge/powershell-5.1%2B-5391FE" alt="powershell">
  <img src="https://img.shields.io/badge/MCP-compatible-purple" alt="MCP">
</p>

<h1 align="center">CrossAgentCoding</h1>

<p align="center">
  <a href="README.md">English</a> | <a href="README.zh-CN.md">简体中文</a> | <b>繁體中文</b>
</p>

<p align="center">
  <b>一份記憶，連接你所有的 AI 編碼助手。</b><br>
  一鍵將持久化上下文共享給 Codex、TRAE、Claude、Gemini、OpenCode、OpenClaw、Hermes 等工具。
</p>

<p align="center">
  <a href="#快速開始">快速開始</a> &bull;
  <a href="#支援的編碼工具">支援的編碼工具</a> &bull;
  <a href="#工作原理">工作原理</a> &bull;
  <a href="#核心功能">核心功能</a> &bull;
  <a href="#構建">構建</a> &bull;
  <a href="#路線圖">路線圖</a>
</p>

---

## 它解決什麼問題？

你可能同時使用多個 AI 編碼工具（Codex、TRAE、Claude、Gemini 等）。每個工具的對話記憶互相隔離，換工具、換帳號、重啟後就丟失了之前討論的目標、決策和約定。

**CrossAgentCoding 的做法：** 在本地啟動一個 AgentMemory 服務（`http://localhost:3111`），透過 MCP（模型上下文協定）一鍵接入所有編碼工具，讓它們共享同一份持久化記憶——上下文在切換工具、切換帳號、重啟後依然保留。

> 靈感來源：[rohitg00/agentmemory](https://github.com/rohitg00/agentmemory)（持久化記憶）和 [farion1231/cc-switch](https://github.com/farion1231/cc-switch/)（多工具配置）。

---

## 快速開始

### Windows（預構建 EXE）

1. 從 [Releases](https://github.com/zhibuyu/CrossAgentCoding/releases) 下載 `CrossAgentCoding.exe`
2. 執行，點選 **安裝全部** 安裝 Node.js、AgentMemory 和 iii-engine
3. 點選 **啟動服務**，等待顯示 `執行中 (localhost:3111)`
4. 點選 **全部配置** 寫入各工具的 MCP 配置
5. 重啟你的編碼工具，它們現在共享同一份記憶

### macOS / Linux（從原始碼執行）

```bash
# 先安裝 PowerShell 7+ 和 Node.js
# macOS: brew install powershell node@20
# Linux: sudo apt install powershell nodejs

# 複製並執行
git clone https://github.com/zhibuyu/CrossAgentCoding.git
cd CrossAgentCoding
pwsh ./src/AgentMemoryManager.ps1

# 或使用 CLI 模式
pwsh ./src/AgentMemoryManager.ps1 -Cli env tools
pwsh ./src/AgentMemoryManager.ps1 -Cli agents configure
```

> **注意：** macOS/Linux 下不支援 GUI，程式會自動以 CLI/TUI 模式執行。所有核心功能（安裝、配置、橋接、記憶設定）均可透過命令列完成。

### Windows（從原始碼執行）

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\src\AgentMemoryManager.ps1
```

---

## 支援的編碼工具

| 工具 | 配置路徑 | 自動檢測 | 一鍵配置 |
|-------|-------------|:-----------:|:----------------:|
| **Codex** | `~\.codex\config.toml` | ✅ | ✅ |
| **TRAE SOLO CN** | `%APPDATA%\TRAE SOLO CN\User\mcp.json` | ✅ | ✅ |
| **TRAE SOLO** | `%APPDATA%\TRAE SOLO\User\mcp.json` | ✅ | ✅ |
| **Qoder CN** | `%APPDATA%\QoderCN\SharedClientCache\mcp.json` | ✅ | ✅ |
| **Claude Code** | `~\.claude\mcp.json` | ✅ | ✅ |
| **Claude Desktop** | `%APPDATA%\Claude\claude_desktop_config.json` | ✅ | ✅ |
| **Gemini CLI** | `~\.gemini\settings.json` | ✅ | ✅ |
| **OpenCode** | `~\.config\opencode\opencode.json` | ✅ | ✅ |
| **OpenClaw** | `~\.openclaw\openclaw.json` | ✅ | ✅ |
| **Hermes Agent** | `~\.hermes\config.yaml` | ✅ | ✅ |

寫入配置前會自動建立帶時間戳的備份（`.bak-YYYYMMDDHHMMSS`）。

---

## 工作原理

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  Codex   │   │  TRAE    │   │  Claude  │   │  Gemini  │  ... 10 個工具
└────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘
     │              │              │              │
     └──────────────┼──────────────┼──────────────┘
                    │   MCP（模型上下文協定）
                    ▼
          ┌─────────────────────┐
          │  AgentMemory 服務    │  ← localhost:3111
          │  (REST + Streams)   │
          └──────────┬──────────┘
                     │
          ┌──────────▼──────────┐
          │    iii-engine        │  ← state_store + stream_store
          │  （嵌入式資料庫）     │
          └─────────────────────┘
```

1. **iii-engine** — 嵌入式鍵值 + 事件流資料庫（無需 Docker，無需外部資料庫）
2. **AgentMemory** — REST API，支援混合檢索（BM25 關鍵詞 + 語義向量）
3. **MCP 層** — 所有工具連接到同一個 `localhost:3111` 端點

---

## 核心功能

### 🧠 共享記憶
所有工具讀寫同一份持久記憶。關鍵詞 + 語義混合檢索。零配置 BM25 模式開箱即用；可選本地 MiniLM 向量模型（約 90MB，純 CPU）以獲得更好的語義匹配效果。

### 🔌 一鍵 MCP 配置
自動檢測已安裝的編碼工具並寫入 MCP 配置。支援單個工具配置/重配置。提供可複製的 MCP JSON 和 CLI 命令用於手動設定。

### 📋 共享 Prompt 檔案
生成 `AGENTS.md`、`CLAUDE.md`、`TRAE.md`、`GEMINI.md`、`OPENCODE.md`、`OPENCLAW.md`、`HERMES.md`——每個檔案告訴對應工具如何使用共享記憶。

### 🌉 工作區橋接
將專案目錄綁定到穩定的工作區 ID（路徑 + Git 遠端的 SHA256）。匯入 Codex 和 TRAE 的有界會話片段。生成 `handoff.md` 交接摘要，確保上下文在切換工具/帳號後依然保留。

### ⚙️ 記憶設定
- **向量檢索**：BM25 純關鍵詞（預設）/ 本地 MiniLM / OpenAI 相容 / Gemini / Voyage / Cohere
- **LLM**：OpenAI 相容 / Anthropic / Gemini / OpenRouter / MiniMax（可選，用於更智能的壓縮）
- **MCP 工具集**：核心（7 個工具）或全部（51 個工具）

### 📦 儲存遷移
三類目錄可獨立遷移：CrossAgentCoding 資料目錄、AgentMemory 記憶儲存目錄、模型快取目錄。支援 GUI 資料夾選擇器或 CLI。

### 🖥️ GUI + CLI + TUI
完整的 WinForms 圖形介面、PowerShell 命令列、文字介面三種模式。

### 🌐 記憶檢視器
內建 Web 檢視器（`http://localhost:3113`），用於瀏覽和管理記憶。

---

## 截圖

<!-- TODO: 添加截圖 -->
<p align="center">
  <i>截圖即將上線——歡迎 PR！</i>
</p>

---

## 構建

### Windows（IExpress EXE）

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

使用 Windows 內建 IExpress 打包。輸出：`release\CrossAgentCoding.exe`

### macOS / Linux

無需構建——直接從原始碼執行。如需建立啟動腳本：

```bash
# 建立便捷啟動器
cat > crossagentcoding << 'EOF'
#!/bin/bash
pwsh "$(dirname "$0")/src/AgentMemoryManager.ps1" "$@"
EOF
chmod +x crossagentcoding
./crossagentcoding -Cli env tools
```

## 測試

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\selftest.ps1
```

自測使用暫存使用者配置——不會觸碰你的真實配置檔案。

---

## 安全 —— 金鑰只留本機

你在**記憶設定**裡填的 API Key **只**儲存在本機 `settings.json`（位於資料目錄，如 `%USERPROFILE%\.CrossAgentCoding`，在儲存庫之外）。在 Windows 上它**加密儲存**（DPAPI，繫結你的使用者帳戶），僅在服務啟動時於記憶體中解密使用。它**只**會傳送給你設定的 LLM/Embedding 端點，**絕不**提交到 git。（舊的明文 Key 可用 `... -Cli memory encrypt` 遷移，或在記憶設定裡重新儲存一次即可。）

兩道防線確保金鑰不入庫：

- **`.gitignore`** 屏蔽 `settings.json`、`.env*`、`*.local.json`、`*.key`、`*.secret` 等；
- **pre-commit 鉤子**（`scripts/git-hooks/pre-commit`）在每次提交前掃描，攔截疑似 API Key（OpenAI / Anthropic / 智譜 …）。

複製後啟用鉤子：

```bash
git config core.hooksPath scripts/git-hooks
```

確屬誤報時可用 `git commit --no-verify` 跳過。

---

## 專案結構

```
CrossAgentCoding/
├── src/
│   ├── AgentMemoryManager.ps1   # 主程式（GUI + 全部邏輯）
│   └── launch.vbs               # 隱藏啟動器（無命令列視窗）
├── scripts/
│   └── build.ps1                # IExpress 構建腳本
├── tests/
│   └── selftest.ps1             # 無 UI 自測
├── docs/
│   ├── FUNCTIONS.md             # 開發者函數參考
│   └── superpowers/plans/       # 功能規劃
├── release/                     # 構建產物（gitignored）
├── trae-mcp-config.json         # 獨立 TRAE MCP 配置片段
└── README.md
```

---

## 路線圖

- [x] 10 工具 MCP 配置（Codex、TRAE、Qoder、Claude、Gemini、OpenCode、OpenClaw、Hermes）
- [x] 共享 Prompt 檔案生成
- [x] 工作區會話橋接（Codex + TRAE）
- [x] 記憶設定（向量檢索、LLM、工具集）
- [x] 儲存遷移（GUI + CLI）
- [x] CLI / TUI 模式
- [x] 啟動診斷和埠衝突檢測
- [ ] 截圖和演示 GIF
- [ ] 服務商切換面板
- [ ] 用量 / 成本分析
- [ ] WebDAV / 雲同步記憶備份
- [x] Linux 和 macOS 支援（CLI/TUI 模式）

---

## 參與貢獻

歡迎提交 PR、Issue 和功能建議！詳見 [CONTRIBUTING.md](CONTRIBUTING.md)（即將上線）。

## 授權條款

MIT — 詳見 [LICENSE](LICENSE)。

---

<p align="center">
  ⭐ 如果這個專案對你有幫助，請給個 Star！
</p>
