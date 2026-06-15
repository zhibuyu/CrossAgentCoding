# CrossAgnetCoding

Version: 0.3.0-mvp

CrossAgnetCoding 是一个 Windows 桌面工具（GUI + CLI/TUI），用于在本机多个 Coding Agent 之间**共享 AgentMemory 记忆与工作区交接（handoff）上下文**。

简单说：它在本地跑一个 AgentMemory 服务，并把这个服务以 MCP 的方式接入你装的各种 AI 编码工具（Codex、TRAE、Qoder CN、Claude、Gemini 等），让它们读写**同一份长期记忆**，从而在不同工具/不同账号之间不丢失项目上下文。

仓库地址：

```text
https://github.com/zhibuyu/CrossAgnetCoding
```

## 它解决什么问题

你可能同时用好几个 AI 编码工具。每个工具的对话记忆是各自独立的，换工具、换账号、关掉重开，之前讨论的目标、决策、约定就丢了。

CrossAgnetCoding 的做法：

- 本地启动 AgentMemory 服务（`http://localhost:3111`）作为统一的"长期记忆"。
- 一键把这个记忆服务以 MCP 形式写进各个工具的配置里，让它们都连到同一个记忆。
- 提供"共享 Prompt"和"工作区桥接"，把记忆的用法和最近的交接摘要喂给每个工具。
持久化记忆参考[rohitg00/agentmemory](https://github.com/rohitg00/agentmemory) 
多工具统一管理的思路参考了 [farion1231/cc-switch](https://github.com/farion1231/cc-switch/)。

## 支持的 Coding Agent

会自动检测安装状态，并可一键写入用户级 MCP 配置：

| 工具 | 配置文件位置 |
| --- | --- |
| Codex | `%USERPROFILE%\.codex\config.toml` |
| TRAE SOLO CN | `%APPDATA%\TRAE SOLO CN\User\mcp.json` |
| TRAE SOLO | `%APPDATA%\TRAE SOLO\User\mcp.json` |
| **Qoder CN** | `%APPDATA%\QoderCN\SharedClientCache\mcp.json` |
| Claude Code | `%USERPROFILE%\.claude\mcp.json` |
| Claude Desktop | `%APPDATA%\Claude\claude_desktop_config.json` |
| Gemini CLI | `%USERPROFILE%\.gemini\settings.json` |
| OpenCode | `%USERPROFILE%\.config\opencode\opencode.json` |
| OpenClaw | `%USERPROFILE%\.openclaw\openclaw.json` |
| Hermes Agent | `%USERPROFILE%\.hermes\config.yaml` |

> **关于 Qoder CN 的说明**：Qoder CN 是 VS Code 系的 AI IDE，其 MCP 配置位于 `%APPDATA%\QoderCN\SharedClientCache\mcp.json`（已对照实际安装版本确认），采用与 TRAE SOLO 相同的 `mcpServers` JSON 结构。

每次写入配置前都会先备份原文件（生成 `*.bak-时间戳`）。

## 界面说明（各按钮做什么）

### 顶部状态区

- **安装全部**：检查并安装运行所需的 Node.js、AgentMemory、iii-engine。
- **启动服务 / 停止服务**（同一个按钮，切换）：启动或停止本地 AgentMemory 服务。服务未运行时显示蓝色"启动服务"，运行中显示红色"停止服务"。状态会自动刷新。
- **检查状态**：调用 `agentmemory status`，把健康状态、会话/记忆条数、Provider、Embeddings 模式等显示在日志区。
- **打开记忆查看器**：用浏览器打开 `http://localhost:3113`，可视化浏览/管理所有共享记忆（服务需在运行中）。
- **记忆设置**：配置语义检索方式、LLM 提供方、MCP 工具集（详见下方"记忆设置"一节）。
- **复制 MCP 配置**：把 AgentMemory 的 MCP JSON 复制到剪贴板，便于手动粘贴到工具里。
- **复制 CLI 命令**：复制各工具手动接入的命令/路径提示到剪贴板。
- **同步共享 Prompt**：见下方"功能详解"。
- **桥接工作区**：见下方"功能详解"。
- **存储设置**：选择并迁移三类存储目录（CrossAgnetCoding 数据 / AgentMemory 记忆库 / 本地模型缓存），详见下方"存储设置"。

界面中间会显示**三类存储目录**与**服务端口**（REST 3111 / 流 3112 / 查看器 3113）：第一行是 CrossAgnetCoding 数据目录和 AgentMemory 存储目录，第二行是模型缓存目录和端口，方便你随时确认数据/模型/日志在哪个盘、磁盘不够时往哪迁。

### 本地环境检查区

- **刷新**：重新扫描各工具的安装/配置状态。
- **全部配置**：一键把 AgentMemory MCP 写入上表所有工具的用户级配置。
- 每张卡片显示：工具名、平台、是否**已安装**（绿色）/**未安装**（灰色）、是否已检测到 MCP 配置路径，以及单独的**配置 / 重新配置**按钮。

## 功能详解

### 同步共享 Prompt

在数据目录下的 `shared\` 文件夹生成一组共享上下文文件（`AGENTS.md`、`CLAUDE.md`、`OPENCODE.md`、`TRAE.md`、`GEMINI.md`、`OPENCLAW.md`、`HERMES.md`）。

每个文件内容相同，告诉对应的 Agent：

- AgentMemory 的 MCP 入口是 `http://localhost:3111`；
- 推荐工作流：**任务开始**时先在 AgentMemory 里检索项目目标/决策/约束 →**进行中**把决策、文件路径、测试命令、交接备注写进记忆 →**任务结束**时总结并写一条简洁的记忆。

作用：让每个工具用**统一的方式**使用这份共享记忆。它只在数据目录里生成参考文件，不会自动塞进你的项目目录。

### 桥接工作区

选择一个项目目录后，CrossAgnetCoding 会：

1. 为该项目计算一个稳定的**工作区 ID**＝`SHA256(规范化路径 + Git 远程地址)` 的前 16 位。因为绑定的是项目路径（和 Git 远程），所以**即使你退出 Codex 换个账号登录，打开同一个项目仍能找回这份工作区记忆**。
2. 从 Codex 的会话目录（`~/.codex/sessions`）和 TRAE 的日志目录（`%APPDATA%\TRAE SOLO[ CN]\logs`）中，导入**有限长度**的可读片段（最多 12 个文件、每个截断到约 3000 字节）。
3. 把这些内容写进工作区记忆 `数据目录\workspaces\<工作区ID>\`：
   - `sessions.jsonl`：追加式的桥接记录；
   - `handoff.md`：最近一次跨工具交接摘要；
   - `workspace.json`：工作区元数据；
   - 以及一组生成的 prompt 文件（含共享 Prompt + 工作区信息 + 最新交接）。

作用：生成一份**绑定到项目、可被各工具读取的交接上下文**，让上下文在不同工具/账号之间延续。

> 注意：桥接**不会**强制让 Codex 和 TRAE 去读对方的原生聊天数据库，而是把有界、可读的片段导入到 CrossAgnetCoding 的工作区记忆里。

### 存储设置（数据/模型目录迁移）

点 **存储设置** 按钮打开弹窗，里面有三类**可独立选择目录并迁移**的存储（默认都在 C 盘，磁盘不够时可整体迁到别的盘）：

| 存储 | 默认位置 | 装什么 |
| --- | --- | --- |
| CrossAgnetCoding 数据目录 | `%USERPROFILE%\.CrossAgnetCoding` | 工作区记忆、共享 Prompt、设置、桥接日志 |
| AgentMemory 数据目录 | `%USERPROFILE%\.agentmemory` | 记忆库 `data/`（state_store + stream_store，**会随使用变大**）、服务日志 |
| 模型缓存目录 | `<AgentMemory 数据目录>\models` | 本地向量模型 `all-MiniLM-L6-v2`（~90MB） |

每行点"**选择并迁移…**"选个新目录即可：程序会把现有数据**复制到新目录并切换指向**，旧目录保留不动。AgentMemory 相关目录（数据/模型）**需重启服务后生效**——因为 AgentMemory 的记忆库是写在"服务工作目录下的 `data/`"，迁移其实就是换服务的工作目录。

> 也可用命令行：`-Cli storage show` 看当前三个目录；`-Cli storage service <新目录>` / `-Cli storage model <新目录>` 迁移。

## 记忆是怎么共享的（通俗版）

AgentMemory 本质是**一个只跑在你本机的"记忆数据库 + 服务"**，分三层：

1. **底层 iii-engine**（就是要装的 `iii.exe`）：提供三个原语 `state_store`（键值库）+ `stream_store`（事件流）+ 引擎，记忆就存在这里。
2. **中间 AgentMemory 服务**：在 `localhost:3111` 开放 REST 接口（另有 3112 流接口、3113 网页查看器）。
3. **接入层 MCP**：每个 coding 工具里写的那段 `agentmemory` MCP 配置，是一个统一指向 `http://localhost:3111` 的"转接头"。

**共享是这样发生的**：Codex / TRAE / Qoder / Claude 等工具全都连到**同一个 3111 服务**。A 工具把"这个项目用 pnpm、接口在 X 文件"写进记忆，B 工具下次开工一搜就能拿到。检索方式是**关键词（BM25）+ 语义（向量）混合**。

## 记忆设置：语义检索 / LLM / 工具集

点界面上的 **记忆设置** 按钮打开。设置保存在本机 `settings.json` 的 `memory` 字段里，**启动/重启服务后对 AgentMemory 生效**（API Key 只存在本地）。

### ① 语义检索（向量）

"语义"这一半需要把文字转成向量，因此需要一个 embedding 模型。提供三种方式：

| 方式 | 说明 | 需要什么 |
| --- | --- | --- |
| **纯关键词 BM25**（默认） | 零配置，开箱即用，中文带 jieba 分词。语义近似匹配弱一些。 | 无 |
| **本地 MiniLM** | 离线本地跑 `all-MiniLM-L6-v2`，语义检索效果好、不联网、不花钱。 | 一次性下载 ~90MB 模型 + `@xenova/transformers` 依赖 |
| **云端 API** | 用 OpenAI / Gemini / Voyage / Cohere / OpenRouter 的向量服务。 | 对应 API Key + 联网 |

**关于 all-MiniLM-L6-v2**：约 2300 万参数、ONNX 量化后 ~90MB、**纯 CPU 跑，不需要显卡**，普通电脑（含本机 Win11）都能轻松部署。在"记忆设置"里选"本地 MiniLM"并点**安装本地向量依赖**即可装好 `@xenova/transformers`（`onnxruntime-node` 一般已随 AgentMemory 装好）。模型会下载到**模型缓存目录**（默认在 AgentMemory 数据目录下的 `models\`，可在"存储设置"里改到别的盘）。

> ⚠️ **国内网络注意**：本地模型首次会从 `huggingface.co` 下载。勾选"本地模型走 hf-mirror.com 镜像"可显著加速；也可改用云端 API，或干脆用纯关键词（不下载任何模型）。

### ② LLM 智能压缩（可选）

配上 OpenAI / MiniMax / Anthropic / Gemini / OpenRouter 的 API Key 后，AgentMemory 会用 LLM 对记忆做更聪明的压缩/总结（并可启用知识图谱、记忆整合等）。**不配也能用**——此时是 noop 模式，用零-LLM 合成压缩，检索照常工作。

### ③ MCP 工具集

- **core**（7 个工具，默认）：最常用的记忆读写。
- **all**（51 个工具）：暴露 AgentMemory 的全部能力给 coding 工具。

## 服务端口

| 端口 | 用途 |
| --- | --- |
| `3111` | REST API（MCP 与各工具连接的地址） |
| `3112` | Streams 流接口 |
| `3113` | 网页查看器（"打开记忆查看器"按钮指向这里） |

## 数据目录

涉及的三类存储（默认位置，均可在"存储设置"里改到别的盘）：

```text
CrossAgnetCoding 数据：%USERPROFILE%\.CrossAgnetCoding        （工作区、共享 Prompt、设置、桥接日志）
AgentMemory 数据：     %USERPROFILE%\.agentmemory             （记忆库 data\ 、服务日志 agentmemory-service.log）
模型缓存：             %USERPROFILE%\.agentmemory\models       （本地向量模型）
```

主界面会实时显示这三类目录。迁移方式：
- 界面 **存储设置** 按钮（推荐，一次搞定三类）；
- 或命令行：`config migrate <新目录>`（CrossAgnetCoding 数据）、`storage service <新目录>`（AgentMemory 数据）、`storage model <新目录>`（模型缓存）。

## 使用方法（GUI Usage）

1. 运行：

```text
CrossAgnetCoding.exe
```

2. 若缺少 Node.js / AgentMemory / iii-engine，点击**安装全部**。
3. 点击**启动服务**，确认状态变为 `运行中 (localhost:3111)`。
4. 在"本地环境检查"区点击**全部配置**写入各工具的 MCP 配置；或在单张卡片上点**配置 / 重新配置**只配某一个工具。
5. （可选）点**记忆设置**选择语义检索方式 / 配置 LLM / 选工具集，保存后**重启服务**生效；点**检查状态**确认 Provider 与 Embeddings 模式；点**打开记忆查看器**在浏览器查看记忆。
6. 需要时点**同步共享 Prompt**、**桥接工作区**。
7. 配置变更后，按需重启 Codex、TRAE、Qoder CN、Claude、Gemini、OpenClaw、Hermes 等工具，使其加载新的 MCP 配置。

## 命令行 / TUI（CLI Usage）

直接运行源码脚本即可使用命令行/文本界面：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\AgentMemoryManager.ps1 -Cli env tools
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\AgentMemoryManager.ps1 -Cli agents scan
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\AgentMemoryManager.ps1 -Cli agents configure
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\AgentMemoryManager.ps1 -Cli workspace init "D:\path\to\project"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\AgentMemoryManager.ps1 -Cli workspace bridge "D:\path\to\project"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\AgentMemoryManager.ps1 -Cli config home
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\AgentMemoryManager.ps1 -Cli config migrate "D:\CrossAgnetCodingData"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\AgentMemoryManager.ps1 -Cli memory show
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\AgentMemoryManager.ps1 -Cli memory env
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\AgentMemoryManager.ps1 -Cli storage show
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\AgentMemoryManager.ps1 -Cli storage service "D:\AgentMemoryData"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\AgentMemoryManager.ps1 -Cli storage model "D:\AgentMemoryModels"
```

`memory show` 打印当前记忆设置；`memory env` 打印这些设置会传给 AgentMemory 服务的环境变量（API Key 以 `***set***` 脱敏）。`storage show` 打印三类存储目录；`storage service` / `storage model` 迁移 AgentMemory 数据 / 模型缓存目录。

TUI 模式：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\AgentMemoryManager.ps1 -Tui
```

## 直接运行源码（开发测试用）

不打包也能测试，行为与打包后的 exe 一致：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\AgentMemoryManager.ps1
```

## 构建（Build）

在项目目录下执行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

产物（用系统自带 IExpress 打包）：

```text
release\CrossAgnetCoding.exe
```

## 测试（Test）

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\selftest.ps1
```

自检使用临时用户目录做配置写入测试，**不会**改动你真实的 Codex/TRAE/Qoder/OpenCode/Claude 配置。

## 项目结构

- `src/AgentMemoryManager.ps1` — 主程序（WinForms 界面 + 全部管理逻辑）。
- `src/launch.vbs` — 打包后 exe 使用的隐藏启动器（避免弹黑色 cmd 窗口）。
- `scripts/build.ps1` — 用 IExpress 构建 `CrossAgnetCoding.exe`。
- `tests/selftest.ps1` — 非 UI 自检与配置写入测试。
- `docs/FUNCTIONS.md` — 面向贡献者的功能与函数说明。
- `trae-mcp-config.json` — 独立的 TRAE 兼容 MCP 配置片段。

## 说明

CrossAgnetCoding 不会自动复制每一条聊天记录。它做的是：给多个 Coding Agent 一个**共享的 AgentMemory MCP 端点**和**共享 Prompt**，让它们能写入、读取持久的任务上下文。

本 MVP 暂未包含：完整的供应商切换、代理路由、用量/成本看板、WebDAV/云同步。
