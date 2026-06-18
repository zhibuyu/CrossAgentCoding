param(
    [switch]$SelfTest,
    [switch]$Cli,
    [switch]$Tui,
    [switch]$UiSmokeTest,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CommandArgs = @()
)

# --- Platform detection ---
$script:IsWindows = $PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows -or ([Environment]::OSVersion.Platform -eq 'Win32NT')
$script:IsMacOS   = $PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS   -or ($false)
$script:IsLinux   = $PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux   -or ($false)
# Fallback for PowerShell 5.1 on Windows
if ($PSVersionTable.PSVersion.Major -lt 6) {
    $script:IsWindows = $true
    $script:IsMacOS   = $false
    $script:IsLinux   = $false
}

# Architecture detection
$script:IsArm64 = $false
try {
    $arch = if ($script:IsWindows) {
        [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
    } else {
        (uname -m 2>$null) -replace '\s+', ''
    }
    $script:IsArm64 = ($arch -eq 'Arm64') -or ($arch -match '^(arm64|aarch64)$')
} catch {}

# Platform-specific paths
if ($script:IsWindows) {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $script:HomeDir = $env:USERPROFILE
    $script:AppDataDir = $env:APPDATA
    $script:LocalAppDataDir = $env:LOCALAPPDATA
    $script:TempDir = $env:TEMP
    $script:PathSep = ";"
    $script:ExeExt = ".exe"
    $script:CmdExt = ".cmd"
    $script:NodeExe = "node.exe"
    $script:ShellCmd = "cmd.exe"
    $script:ShellArgs = "/d /c"
} else {
    $script:HomeDir = $env:HOME
    $script:AppDataDir = if ($script:IsMacOS) {
        [System.IO.Path]::Combine($env:HOME, "Library", "Application Support")
    } else {
        Join-Path $env:HOME ".config"
    }
    $script:LocalAppDataDir = Join-Path $env:HOME ".local"
    $script:TempDir = if ($env:TMPDIR) { $env:TMPDIR } else { "/tmp" }
    $script:PathSep = ":"
    $script:ExeExt = ""
    $script:CmdExt = ""
    $script:NodeExe = "node"
    $script:ShellCmd = "/bin/sh"
    $script:ShellArgs = "-c"
}

$ErrorActionPreference = "Continue"

$script:AM_DIR = Join-Path $script:HomeDir ".agentmemory"
$script:LOCAL_BIN = Join-Path $script:LocalAppDataDir "bin"
$script:NPM_GLOBAL = if ($script:IsWindows) { Join-Path $script:AppDataDir "npm" } else { Join-Path $script:HomeDir ".npm-global" }
$script:APP_NAME = "CrossAgentCoding"
$script:APP_VERSION = "0.0.1"
$script:III_VERSION = "v0.11.2"
$script:PORT = 3111
$script:STREAMS_PORT = 3112
$script:VIEWER_PORT = 3113
$script:HF_MIRROR_URL = "https://hf-mirror.com"
$script:Language = "zh"
$script:IsBusy = $false
$script:CliExitCode = 0
$script:NodeVersionCache = ""
$script:NodeVersionCacheTime = [datetime]::MinValue
$script:NodeVersionFailureTime = [datetime]::MinValue
$script:NodeVersionCacheSeconds = 30
$script:NodeVersionFailureCooldownSeconds = 300

$script:Text = @{
    zh = @{
        WindowTitle = "CrossAgentCoding v0.0.1"
        Title = "CrossAgentCoding 跨 Coding Agent 记忆管理器"
        SettingsTitle = "设置"
        AboutTab = "关于"
        GeneralTab = "通用"
        RouteTab = "路由"
        AuthTab = "认证"
        AdvancedTab = "高级"
        UsageTab = "使用统计"
        AICodeToolAbout = "关于"
        AboutDescription = "查看版本信息与本地 AI Code 工具接入状态。"
        LocalEnvCheck = "本地环境检查"
        EnvCheck = "基础依赖"
        ServiceStatus = "服务状态"
        LastAction = "操作反馈"
        InstallAll = "安装全部"
        StartService = "启动服务"
        StopService = "停止服务"
        CopyMcp = "复制 MCP 配置"
        OpenViewer = "打开记忆查看器"
        MemorySettings = "记忆设置"
        StorageSettings = "存储设置"
        StorageTitle = "存储位置设置"
        StorageHomeRow = "CrossAgentCoding 数据目录（工作区、共享 Prompt、设置）"
        StorageServiceRow = "AgentMemory 数据目录（记忆库 data/ 与服务日志）"
        StorageModelRow = "模型缓存目录（本地向量模型 all-MiniLM-L6-v2）"
        StorageChooseMigrate = "选择并迁移…"
        StorageNote = "迁移会把现有数据复制到新目录并切换指向（旧目录保留）。AgentMemory 相关目录需重启服务后生效。"
        StoragePickService = "选择 AgentMemory 数据目录"
        StoragePickModel = "选择模型缓存目录"
        StorageMigrated = "已迁移到：{0}（重启服务后生效）"
        CheckStatus = "检查状态"
        ViewerNotRunning = "服务未运行，请先启动服务再打开查看器"
        StatusRequested = "正在查询 AgentMemory 状态…"
        StatusServiceDown = "服务未运行，无法查询状态。请先启动服务。"
        MemorySettingsSaved = "记忆设置已保存，重启服务后生效"
        UpdateChecking = "正在检查 AgentMemory 更新…"
        UpdateCheckFail = "检查更新失败（可能是网络/镜像问题）"
        UpdateLatest = "已是最新版本 v{0}"
        UpdateAvailableTitle = "发现新版本"
        UpdateAvailableBody = "发现 AgentMemory 新版本 v{0}（当前 v{1}）。`r`n是否现在更新？更新后请重启服务。"
        Updating = "正在更新 AgentMemory 到 v{0}，请稍候…"
        UpdateOk = "AgentMemory 已更新到 v{0}，请重启服务生效"
        UpdateFail = "AgentMemory 更新失败：{0}"
        AgentMemoryNotInstalled = "AgentMemory 未安装，请先点【安装全部】"
        StaleCleaned = "已清理 {0} 个残留进程"
        InstallingLocalEmbedding = "正在安装本地向量依赖 (@xenova/transformers)，请稍候…"
        LocalEmbeddingInstalled = "本地向量依赖安装完成，重启服务后即可使用本地语义检索"
        LocalEmbeddingInstallFail = "本地向量依赖安装失败：{0}"
        LocalEmbeddingReady = "本地向量依赖已就绪"
        PortsInfo = "服务端口：REST {0} · 流 {1} · 查看器 {2}"
        CodingAgentAccess = "Coding Agent 接入"
        ScanAgents = "刷新"
        ConfigureAgents = "一键配置 MCP"
        CopyCli = "复制 CLI 命令"
        SyncSharedFiles = "同步共享 Prompt"
        BridgeWorkspace = "桥接工作区"
        MigrateDataHome = "迁移数据目录"
        OfficialSite = "官方网站"
        GitHub = "GitHub"
        Changelog = "更新日志"
        CheckUpdate = "检查更新"
        DiagnoseConflicts = "诊断安装冲突"
        UpgradeAll = "全部升级 (0)"
        ConfigureAll = "全部配置"
        CurrentVersion = "当前版本"
        LatestVersion = "最新版本"
        ConfigStatus = "配置状态"
        InstallStatus = "安装状态"
        Installed = "已安装"
        NotInstalled = "未安装"
        Configured = "已连接 CrossAgentCoding"
        NotConfigured = "未连接 CrossAgentCoding"
        UnknownVersion = "可执行，版本未知"
        NotChecked = "未检查"
        Scanning = "扫描中…"
        VersionUnknown = "版本未知"
        DetailCliMcp = "命令行 + MCP"
        DetailMcpDetected = "已检测到 MCP 配置路径"
        InstallOrExecutableMissing = "未安装或不可执行"
        ConfigureTool = "配置"
        ReconfigureTool = "重新配置"
        ToolConfigureDone = "{0} 已写入 CrossAgentCoding MCP 配置"
        AgentInstalledConfigured = "{0} - 已安装 / 已配置"
        AgentInstalledNotConfigured = "{0} - 已安装 / 未配置"
        AgentMissingConfigured = "{0} - 未检测到安装 / 已有配置"
        AgentMissingNotConfigured = "{0} - 未安装 / 未配置"
        AgentScanDone = "Coding Agent 扫描完成"
        AgentConfigureDone = "Coding Agent MCP 配置完成，请重启对应工具"
        AgentConfigureTitle = "配置完成"
        AgentConfigureBody = "已尝试写入 Codex、TRAE SOLO、Qoder CN、OpenCode、Claude、Gemini、OpenClaw、Hermes 的用户级 MCP 配置。请查看日志并重启对应工具。"
        CopyCliOkBody = "CLI 配置命令已复制到剪贴板。"
        SyncSharedDone = "共享 Prompt 文件已同步"
        BridgeWorkspacePrompt = "请选择要桥接记忆的项目目录"
        BridgeWorkspaceDone = "工作区桥接完成：{0}"
        BridgeWorkspaceTitle = "桥接完成"
        MigrateDataPrompt = "请选择新的 CrossAgentCoding 数据目录"
        MigrateDataDone = "数据目录已迁移：{0}"
        MigrateDataTitle = "迁移完成"
        Log = "日志"
        DataPathInfo = "数据目录：{0}      AgentMemory 存储：{1}"
        ModelCacheLabel = "模型缓存：{0}"
        Ready = "就绪"
        NodeInstalled = "Node.js - 已安装 {0}"
        NodeMissing = "Node.js - 未安装"
        AgentMemoryInstalled = "AgentMemory - 已安装 {0}"
        AgentMemoryMissing = "AgentMemory - 未安装"
        IiiInstalled = "iii-engine - 已安装"
        IiiMissing = "iii-engine - 未安装"
        Running = "运行中 (localhost:{0})"
        NotRunning = "未运行"
        Starting = "正在启动..."
        Stopping = "正在停止..."
        Installing = "正在安装..."
        InstallStart = "开始检查并安装依赖"
        AlreadyInstalled = "{0} 已安装，跳过"
        InstallOk = "{0} 安装成功"
        InstallFail = "{0} 安装失败：{1}"
        InstallDone = "安装流程已完成"
        InstallDoneTitle = "安装完成"
        InstallDoneBody = "安装流程已完成，请查看状态和日志。"
        StartAlreadyTitle = "已启动"
        StartAlreadyBody = "服务已经在 localhost:{0} 运行。"
        StartMissingTitle = "缺少依赖"
        StartMissingBody = "检测到未安装：{0}`r`n是否现在安装？"
        StartOkTitle = "启动成功"
        StartOkBody = "AgentMemory 已启动。`r`n地址：http://localhost:{0}"
        StartFailTitle = "启动失败"
        StartFailBody = "AgentMemory 没有在 {0} 秒内启动。请查看日志。"
        StopOkTitle = "已停止"
        StopOkBody = "AgentMemory 服务已停止。"
        StopNothingTitle = "未运行"
        StopNothingBody = "当前没有检测到运行中的 AgentMemory 服务。"
        CopyOkTitle = "已复制"
        CopyOkBody = "MCP 配置已复制到剪贴板。"
        Waiting = "等待服务启动... ({0}s)"
        StartRequested = "正在启动 AgentMemory"
        StopRequested = "正在停止 AgentMemory"
        MissingInstallFirst = "未安装：{0}，请先安装"
        ServiceLog = "服务日志：{0}"
        SelfTestOk = "SELFTEST OK"
        InitialLog1 = "CrossAgentCoding 已就绪"
        InitialLog2 = "未安装时请点击 [安装全部]"
        InitialLog3 = "安装完成后点击 [启动服务]"
    }
    en = @{
        WindowTitle = "CrossAgentCoding v0.0.1"
        Title = "CrossAgentCoding Cross-Agent Memory Manager"
        SettingsTitle = "Settings"
        AboutTab = "About"
        GeneralTab = "General"
        RouteTab = "Route"
        AuthTab = "Auth"
        AdvancedTab = "Advanced"
        UsageTab = "Usage"
        AICodeToolAbout = "About"
        AboutDescription = "Review version information and local AI Code tool connection status."
        LocalEnvCheck = "Local Environment Check"
        EnvCheck = "Core Dependencies"
        ServiceStatus = "Service Status"
        LastAction = "Action Feedback"
        InstallAll = "Install All"
        StartService = "Start Service"
        StopService = "Stop Service"
        CopyMcp = "Copy MCP Config"
        OpenViewer = "Open Memory Viewer"
        MemorySettings = "Memory Settings"
        StorageSettings = "Storage Settings"
        StorageTitle = "Storage Locations"
        StorageHomeRow = "CrossAgentCoding data (workspaces, shared prompts, settings)"
        StorageServiceRow = "AgentMemory data (memory store data/ and service log)"
        StorageModelRow = "Model cache (local embedding model all-MiniLM-L6-v2)"
        StorageChooseMigrate = "Choose & migrate…"
        StorageNote = "Migration copies existing data to the new folder and switches the pointer (old folder kept). AgentMemory folders apply after a service restart."
        StoragePickService = "Choose AgentMemory data directory"
        StoragePickModel = "Choose model cache directory"
        StorageMigrated = "Migrated to: {0} (restart the service to apply)"
        CheckStatus = "Check Status"
        ViewerNotRunning = "Service is not running. Start it before opening the viewer."
        StatusRequested = "Querying AgentMemory status…"
        StatusServiceDown = "Service is not running, cannot query status. Start it first."
        MemorySettingsSaved = "Memory settings saved. Restart the service to apply."
        UpdateChecking = "Checking AgentMemory updates…"
        UpdateCheckFail = "Update check failed (network/registry issue)"
        UpdateLatest = "Already up to date (v{0})"
        UpdateAvailableTitle = "Update Available"
        UpdateAvailableBody = "AgentMemory v{0} is available (current v{1}).`r`nUpdate now? Restart the service afterwards."
        Updating = "Updating AgentMemory to v{0}…"
        UpdateOk = "AgentMemory updated to v{0}. Restart the service to apply."
        UpdateFail = "AgentMemory update failed: {0}"
        AgentMemoryNotInstalled = "AgentMemory is not installed. Click Install All first."
        StaleCleaned = "Cleaned {0} stale process(es)"
        InstallingLocalEmbedding = "Installing local embedding dependency (@xenova/transformers)…"
        LocalEmbeddingInstalled = "Local embedding dependency installed. Restart the service to use local semantic search."
        LocalEmbeddingInstallFail = "Local embedding dependency install failed: {0}"
        LocalEmbeddingReady = "Local embedding dependency is ready"
        PortsInfo = "Ports: REST {0} · Streams {1} · Viewer {2}"
        CodingAgentAccess = "Coding Agent Access"
        ScanAgents = "Refresh"
        ConfigureAgents = "Configure MCP"
        CopyCli = "Copy CLI Commands"
        SyncSharedFiles = "Sync Shared Prompt"
        BridgeWorkspace = "Bridge Workspace"
        MigrateDataHome = "Migrate Data Home"
        OfficialSite = "Official Site"
        GitHub = "GitHub"
        Changelog = "Changelog"
        CheckUpdate = "Check Updates"
        DiagnoseConflicts = "Diagnose Conflicts"
        UpgradeAll = "Upgrade All (0)"
        ConfigureAll = "Configure All"
        CurrentVersion = "Current Version"
        LatestVersion = "Latest Version"
        ConfigStatus = "Config Status"
        InstallStatus = "Install Status"
        Installed = "Installed"
        NotInstalled = "Not Installed"
        Configured = "Connected to CrossAgentCoding"
        NotConfigured = "Not Connected to CrossAgentCoding"
        UnknownVersion = "Executable, version unknown"
        NotChecked = "Not Checked"
        Scanning = "Scanning…"
        VersionUnknown = "Unknown"
        DetailCliMcp = "CLI + MCP"
        DetailMcpDetected = "MCP config path detected"
        InstallOrExecutableMissing = "Not installed or not executable"
        ConfigureTool = "Configure"
        ReconfigureTool = "Reconfigure"
        ToolConfigureDone = "{0} CrossAgentCoding MCP config written"
        AgentInstalledConfigured = "{0} - Installed / Configured"
        AgentInstalledNotConfigured = "{0} - Installed / Not Configured"
        AgentMissingConfigured = "{0} - Not Detected / Configured"
        AgentMissingNotConfigured = "{0} - Not Installed / Not Configured"
        AgentScanDone = "Coding Agent scan complete"
        AgentConfigureDone = "Coding Agent MCP configuration complete. Restart the tools."
        AgentConfigureTitle = "Configured"
        AgentConfigureBody = "User-level MCP config was written for Codex, TRAE SOLO, Qoder CN, OpenCode, Claude, Gemini, OpenClaw, and Hermes when possible. Check the log and restart the tools."
        CopyCliOkBody = "CLI configuration commands copied to clipboard."
        SyncSharedDone = "Shared prompt files synced"
        BridgeWorkspacePrompt = "Choose the project directory to bridge"
        BridgeWorkspaceDone = "Workspace bridge complete: {0}"
        BridgeWorkspaceTitle = "Bridge Complete"
        MigrateDataPrompt = "Choose the new CrossAgentCoding data directory"
        MigrateDataDone = "Data directory migrated: {0}"
        MigrateDataTitle = "Migration Complete"
        Log = "Log"
        DataPathInfo = "Data dir: {0}      AgentMemory storage: {1}"
        ModelCacheLabel = "Model cache: {0}"
        Ready = "Ready"
        NodeInstalled = "Node.js - Installed {0}"
        NodeMissing = "Node.js - Not Installed"
        AgentMemoryInstalled = "AgentMemory - Installed {0}"
        AgentMemoryMissing = "AgentMemory - Not Installed"
        IiiInstalled = "iii-engine - Installed"
        IiiMissing = "iii-engine - Not Installed"
        Running = "Running (localhost:{0})"
        NotRunning = "Not Running"
        Starting = "Starting..."
        Stopping = "Stopping..."
        Installing = "Installing..."
        InstallStart = "Checking and installing dependencies"
        AlreadyInstalled = "{0} already installed, skipped"
        InstallOk = "{0} installed"
        InstallFail = "{0} failed: {1}"
        InstallDone = "Install flow complete"
        InstallDoneTitle = "Install Complete"
        InstallDoneBody = "Install flow complete. Check status and log."
        StartAlreadyTitle = "Already Running"
        StartAlreadyBody = "Service is already running on localhost:{0}."
        StartMissingTitle = "Missing Dependencies"
        StartMissingBody = "Missing: {0}`r`nInstall now?"
        StartOkTitle = "Started"
        StartOkBody = "AgentMemory started.`r`nURL: http://localhost:{0}"
        StartFailTitle = "Start Failed"
        StartFailBody = "AgentMemory did not start within {0} seconds. Check the log."
        StopOkTitle = "Stopped"
        StopOkBody = "AgentMemory service stopped."
        StopNothingTitle = "Not Running"
        StopNothingBody = "No running AgentMemory service was detected."
        CopyOkTitle = "Copied"
        CopyOkBody = "MCP config copied to clipboard."
        Waiting = "Waiting for service... ({0}s)"
        StartRequested = "Starting AgentMemory"
        StopRequested = "Stopping AgentMemory"
        MissingInstallFirst = "Missing: {0}. Please install first."
        ServiceLog = "Service log: {0}"
        SelfTestOk = "SELFTEST OK"
        InitialLog1 = "CrossAgentCoding ready"
        InitialLog2 = "Click Install All when dependencies are missing"
        InitialLog3 = "Click Start Service after installation"
    }
    "zh-TW" = @{
        WindowTitle = "CrossAgentCoding v0.0.1"
        Title = "CrossAgentCoding 跨 Coding Agent 記憶管理器"
        SettingsTitle = "設定"
        AboutTab = "關於"
        GeneralTab = "一般"
        RouteTab = "路由"
        AuthTab = "認證"
        AdvancedTab = "進階"
        UsageTab = "使用統計"
        AICodeToolAbout = "關於"
        AboutDescription = "檢視版本資訊與本地 AI Code 工具接入狀態。"
        LocalEnvCheck = "本地環境檢查"
        EnvCheck = "基礎依賴"
        ServiceStatus = "服務狀態"
        LastAction = "操作回饋"
        InstallAll = "安裝全部"
        StartService = "啟動服務"
        StopService = "停止服務"
        CopyMcp = "複製 MCP 配置"
        OpenViewer = "開啟記憶檢視器"
        MemorySettings = "記憶設定"
        StorageSettings = "儲存設定"
        StorageTitle = "儲存位置設定"
        StorageHomeRow = "CrossAgentCoding 資料目錄（工作區、共享 Prompt、設定）"
        StorageServiceRow = "AgentMemory 資料目錄（記憶庫 data/ 與服務日誌）"
        StorageModelRow = "模型快取目錄（本地向量模型 all-MiniLM-L6-v2）"
        StorageChooseMigrate = "選擇並遷移…"
        StorageNote = "遷移會把現有資料複製到新目錄並切換指向（舊目錄保留）。AgentMemory 相關目錄需重啟服務後生效。"
        StoragePickService = "選擇 AgentMemory 資料目錄"
        StoragePickModel = "選擇模型快取目錄"
        StorageMigrated = "已遷移到：{0}（重啟服務後生效）"
        CheckStatus = "檢查狀態"
        ViewerNotRunning = "服務未執行，請先啟動服務再開啟檢視器"
        StatusRequested = "正在查詢 AgentMemory 狀態…"
        StatusServiceDown = "服務未執行，無法查詢狀態。請先啟動服務。"
        MemorySettingsSaved = "記憶設定已儲存，重啟服務後生效"
        UpdateChecking = "正在檢查 AgentMemory 更新…"
        UpdateCheckFail = "檢查更新失敗（可能是網路/鏡像問題）"
        UpdateLatest = "已是最新版本 v{0}"
        UpdateAvailableTitle = "發現新版本"
        UpdateAvailableBody = "發現 AgentMemory 新版本 v{0}（當前 v{1}）。`r`n是否現在更新？更新後請重啟服務。"
        Updating = "正在更新 AgentMemory 到 v{0}，請稍候…"
        UpdateOk = "AgentMemory 已更新到 v{0}，請重啟服務生效"
        UpdateFail = "AgentMemory 更新失敗：{0}"
        AgentMemoryNotInstalled = "AgentMemory 未安裝，請先點【安裝全部】"
        StaleCleaned = "已清理 {0} 個殘留處理程序"
        InstallingLocalEmbedding = "正在安裝本地向量依賴 (@xenova/transformers)，請稍候…"
        LocalEmbeddingInstalled = "本地向量依賴安裝完成，重啟服務後即可使用本地語義檢索"
        LocalEmbeddingInstallFail = "本地向量依賴安裝失敗：{0}"
        LocalEmbeddingReady = "本地向量依賴已就緒"
        PortsInfo = "服務埠：REST {0} · 流 {1} · 檢視器 {2}"
        CodingAgentAccess = "Coding Agent 接入"
        ScanAgents = "重新整理"
        ConfigureAgents = "一鍵配置 MCP"
        CopyCli = "複製 CLI 命令"
        SyncSharedFiles = "同步共享 Prompt"
        BridgeWorkspace = "橋接工作區"
        MigrateDataHome = "遷移資料目錄"
        OfficialSite = "官方網站"
        GitHub = "GitHub"
        Changelog = "更新日誌"
        CheckUpdate = "檢查更新"
        DiagnoseConflicts = "診斷安裝衝突"
        UpgradeAll = "全部升級 (0)"
        ConfigureAll = "全部配置"
        CurrentVersion = "當前版本"
        LatestVersion = "最新版本"
        ConfigStatus = "配置狀態"
        InstallStatus = "安裝狀態"
        Installed = "已安裝"
        NotInstalled = "未安裝"
        Configured = "已連接 CrossAgentCoding"
        NotConfigured = "未連接 CrossAgentCoding"
        UnknownVersion = "可執行，版本未知"
        NotChecked = "未檢查"
        Scanning = "掃描中…"
        VersionUnknown = "版本未知"
        DetailCliMcp = "命令列 + MCP"
        DetailMcpDetected = "已檢測到 MCP 配置路徑"
        InstallOrExecutableMissing = "未安裝或不可執行"
        ConfigureTool = "配置"
        ReconfigureTool = "重新配置"
        ToolConfigureDone = "{0} 已寫入 CrossAgentCoding MCP 配置"
        AgentInstalledConfigured = "{0} - 已安裝 / 已配置"
        AgentInstalledNotConfigured = "{0} - 已安裝 / 未配置"
        AgentMissingConfigured = "{0} - 未檢測到安裝 / 已有配置"
        AgentMissingNotConfigured = "{0} - 未安裝 / 未配置"
        AgentScanDone = "Coding Agent 掃描完成"
        AgentConfigureDone = "Coding Agent MCP 配置完成，請重啟對應工具"
        AgentConfigureTitle = "配置完成"
        AgentConfigureBody = "已嘗試寫入 Codex、TRAE SOLO、Qoder CN、OpenCode、Claude、Gemini、OpenClaw、Hermes 的使用者級 MCP 配置。請檢視日誌並重啟對應工具。"
        CopyCliOkBody = "CLI 配置命令已複製到剪貼簿。"
        SyncSharedDone = "共享 Prompt 檔案已同步"
        BridgeWorkspacePrompt = "請選擇要橋接記憶的專案目錄"
        BridgeWorkspaceDone = "工作區橋接完成：{0}"
        BridgeWorkspaceTitle = "橋接完成"
        MigrateDataPrompt = "請選擇新的 CrossAgentCoding 資料目錄"
        MigrateDataDone = "資料目錄已遷移：{0}"
        MigrateDataTitle = "遷移完成"
        Log = "日誌"
        DataPathInfo = "資料目錄：{0}      AgentMemory 儲存：{1}"
        ModelCacheLabel = "模型快取：{0}"
        Ready = "就緒"
        NodeInstalled = "Node.js - 已安裝 {0}"
        NodeMissing = "Node.js - 未安裝"
        AgentMemoryInstalled = "AgentMemory - 已安裝 {0}"
        AgentMemoryMissing = "AgentMemory - 未安裝"
        IiiInstalled = "iii-engine - 已安裝"
        IiiMissing = "iii-engine - 未安裝"
        Running = "執行中 (localhost:{0})"
        NotRunning = "未執行"
        Starting = "正在啟動..."
        Stopping = "正在停止..."
        Installing = "正在安裝..."
        InstallStart = "開始檢查並安裝依賴"
        AlreadyInstalled = "{0} 已安裝，跳過"
        InstallOk = "{0} 安裝成功"
        InstallFail = "{0} 安裝失敗：{1}"
        InstallDone = "安裝流程已完成"
        InstallDoneTitle = "安裝完成"
        InstallDoneBody = "安裝流程已完成，請檢視狀態和日誌。"
        StartAlreadyTitle = "已啟動"
        StartAlreadyBody = "服務已經在 localhost:{0} 執行。"
        StartMissingTitle = "缺少依賴"
        StartMissingBody = "檢測到未安裝：{0}`r`n是否現在安裝？"
        StartOkTitle = "啟動成功"
        StartOkBody = "AgentMemory 已啟動。`r`n位址：http://localhost:{0}"
        StartFailTitle = "啟動失敗"
        StartFailBody = "AgentMemory 沒有在 {0} 秒內啟動。請檢視日誌。"
        StopOkTitle = "已停止"
        StopOkBody = "AgentMemory 服務已停止。"
        StopNothingTitle = "未執行"
        StopNothingBody = "當前沒有檢測到執行中的 AgentMemory 服務。"
        CopyOkTitle = "已複製"
        CopyOkBody = "MCP 配置已複製到剪貼簿。"
        Waiting = "等待服務啟動... ({0}s)"
        StartRequested = "正在啟動 AgentMemory"
        StopRequested = "正在停止 AgentMemory"
        MissingInstallFirst = "未安裝：{0}，請先安裝"
        ServiceLog = "服務日誌：{0}"
        SelfTestOk = "SELFTEST OK"
        InitialLog1 = "CrossAgentCoding 已就緒"
        InitialLog2 = "未安裝時請點選 [安裝全部]"
        InitialLog3 = "安裝完成後點選 [啟動服務]"
    }
}

function T {
    param(
        [string]$Key,
        # Must NOT be named $Args: that collides with the automatic $args
        # variable, leaving the parameter empty so every "{0}" placeholder would
        # leak through unformatted.
        [object[]]$FormatArgs = @()
    )

    if ($script:Text -isnot [hashtable]) {
        return $Key
    }

    if (-not $script:Text.ContainsKey($script:Language)) {
        $script:Language = "zh"
    }

    $langTable = $script:Text[$script:Language]
    if (-not $langTable.ContainsKey($Key)) {
        return $Key
    }

    $value = [string]$langTable[$Key]
    if ($FormatArgs.Count -gt 0) {
        return [string]::Format($value, $FormatArgs)
    }
    return $value
}

function Set-ManagerEnv {
    $env:HOME = $script:HomeDir

    # Collect existing PATH entries, split by path separator
    $existing = @()
    if ($env:Path) {
        $existing = $env:Path -split [regex]::Escape($script:PathSep) | Where-Object { $_ -and $_.Trim().Length -gt 0 }
    }

    # New entries to prepend (without duplicates already in PATH)
    $newEntries = @(
        (Join-Path $script:AM_DIR "bin"),
        $script:LOCAL_BIN,
        $(if ($script:IsWindows) { "${env:ProgramFiles}\nodejs" } else { "/usr/local/bin" }),
        $script:NPM_GLOBAL
    )

    # Deduplicate: only prepend entries not already present
    $existingSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($e in $existing) { [void]$existingSet.Add($e.TrimEnd('\')) }

    $toPrepend = [System.Collections.Generic.List[string]]::new()
    foreach ($entry in $newEntries) {
        if ($entry -and $entry.Trim().Length -gt 0) {
            $normalized = $entry.TrimEnd('\')
            if (-not $existingSet.Contains($normalized)) {
                $toPrepend.Add($entry)
                [void]$existingSet.Add($normalized)
            }
        }
    }

    # Build final PATH, checking length to avoid "环境变量名或值太长" error
    $finalParts = $toPrepend + $existing
    $maxPathLength = 32767  # Windows PATH limit
    $result = ""
    foreach ($part in $finalParts) {
        $test = if ($result) { "$result$($script:PathSep)$part" } else { $part }
        if ($test.Length -gt $maxPathLength) {
            break  # Stop adding entries once we approach the limit
        }
        $result = $test
    }

    $env:Path = $result
}

function Get-NodeVersionFromFile {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
        return ""
    }

    try {
        $version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($Path).ProductVersion
        if (-not [string]::IsNullOrWhiteSpace($version)) {
            $clean = ([string]$version).Trim()
            if ($clean -notmatch "^v") {
                $clean = "v$clean"
            }
            return $clean
        }
    } catch {
    }

    return ""
}

function Get-NodeVersion {
    $now = Get-Date
    if ($script:NodeVersionCache -and (($now - $script:NodeVersionCacheTime).TotalSeconds -lt $script:NodeVersionCacheSeconds)) {
        return $script:NodeVersionCache
    }

    if (($now - $script:NodeVersionFailureTime).TotalSeconds -lt $script:NodeVersionFailureCooldownSeconds) {
        return ""
    }

    try {
        $nodeSource = Get-CommandPathSafe -Name $script:NodeExe
        if ([string]::IsNullOrWhiteSpace($nodeSource)) {
            $script:NodeVersionFailureTime = $now
            return ""
        }
        $fileVersion = Get-NodeVersionFromFile -Path $nodeSource
        if ($fileVersion) {
            $script:NodeVersionCache = $fileVersion
            $script:NodeVersionCacheTime = $now
            return $fileVersion
        }

        if ($env:CAC_TEST_NO_NODE_EXEC -eq "1") {
            return ""
        }

        $version = & $nodeSource -v 2>$null
        if ($LASTEXITCODE -eq 0 -and $version) {
            $script:NodeVersionCache = [string]$version
            $script:NodeVersionCacheTime = $now
            return $script:NodeVersionCache
        }
    } catch {
    }

    $script:NodeVersionFailureTime = $now
    return ""
}

function Test-ServiceRunning {
    # Fast TCP socket probe (works on all platforms, ~100ms instead of the
    # 1-5s that Get-NetTCPConnection can take). The previous Get-NetTCPConnection
    # call blocked the UI thread for seconds at a time inside the 5-second
    # refresh timer, making the window close button unresponsive.
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $asyncResult = $tcpClient.BeginConnect("localhost", $script:PORT, $null, $null)
        $connected = $asyncResult.AsyncWaitHandle.WaitOne(800)
        if ($connected -and $tcpClient.Connected) {
            $tcpClient.EndConnect($asyncResult)
            $tcpClient.Close()
            return $true
        }
        $tcpClient.Close()
        return $false
    } catch {
        return $false
    }
}

function Get-ServicePids {
    if (-not $script:IsWindows) {
        return @()
    }
    try {
        return @(Get-NetTCPConnection -LocalPort $script:PORT -State Listen -ErrorAction Stop |
            Select-Object -ExpandProperty OwningProcess -Unique |
            Where-Object { $_ -and $_ -gt 0 })
    } catch {
        return @()
    }
}

function Get-ProcessCommandLineById {
    param([int]$ProcessId)

    if ($ProcessId -le 0) {
        return ""
    }

    if (-not $script:IsWindows) {
        return ""
    }

    try {
        $proc = Get-CimInstance Win32_Process -Filter ("ProcessId = {0}" -f $ProcessId) -ErrorAction Stop
        if ($proc -and -not [string]::IsNullOrWhiteSpace([string]$proc.CommandLine)) {
            return [string]$proc.CommandLine
        }
    } catch {
    }

    return ""
}

function Get-ServicePortConflicts {
    param([int[]]$Ports = @($script:PORT, $script:STREAMS_PORT, $script:VIEWER_PORT))

    if (-not $script:IsWindows) {
        return @()
    }

    $conflicts = New-Object System.Collections.ArrayList
    foreach ($port in $Ports) {
        try {
            $listeners = @(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction Stop)
            foreach ($listener in $listeners) {
                $ownerPid = [int]$listener.OwningProcess
                $name = "unknown"
                try {
                    $proc = Get-Process -Id $ownerPid -ErrorAction Stop
                    $name = [string]$proc.ProcessName
                } catch {
                }

                $commandLine = Get-ProcessCommandLineById -ProcessId $ownerPid
                $ownerText = ($name + " " + $commandLine).ToLowerInvariant()
                [void]$conflicts.Add([pscustomobject]@{
                    Port                 = $port
                    LocalAddress         = [string]$listener.LocalAddress
                    ProcessId            = $ownerPid
                    ProcessName          = $name
                    LooksLikeAgentMemory = (($ownerText -match "agentmemory") -or ($ownerText -match "iii(\.exe)?"))
                })
            }
        } catch {
        }
    }

    return $conflicts.ToArray()
}

function Format-ServicePortConflict {
    param([object]$Conflict)

    return ("Port {0} is in use by PID {1} ({2}) at {3}" -f $Conflict.Port, $Conflict.ProcessId, $Conflict.ProcessName, $Conflict.LocalAddress)
}

function Show-ServicePortConflicts {
    param([object[]]$Conflicts)

    $lines = New-Object System.Collections.Generic.List[string]
    [void]$lines.Add("AgentMemory cannot start because required ports are already in use:")
    foreach ($conflict in $Conflicts) {
        [void]$lines.Add("  - " + (Format-ServicePortConflict -Conflict $conflict))
    }

    foreach ($line in $lines) {
        Write-Log $line
    }

    $message = ($lines -join "`r`n")
    Set-ActionFeedback ($lines[0]) ([System.Drawing.Color]::Red)
    [System.Windows.Forms.MessageBox]::Show($message, (T "StartFailTitle"), "OK", "Error") | Out-Null
}

function Get-CleanLogLine {
    param([string]$Line)

    if ($null -eq $Line) {
        return ""
    }

    $escape = [regex]::Escape([string][char]27)
    $clean = [regex]::Replace([string]$Line, ($escape + "\[[0-9;?]*[ -/]*[@-~]"), "")
    $clean = [regex]::Replace($clean, "[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]", "")
    return $clean.Trim()
}

function Get-ServiceStartupFailureDetail {
    param(
        [string]$ServiceLog,
        [int]$TimeoutSeconds
    )

    $lines = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace($ServiceLog)) {
        [void]$lines.Add("Service log: $ServiceLog")
    }

    $conflicts = @(Get-ServicePortConflicts)
    if ($conflicts.Count -gt 0) {
        [void]$lines.Add("Current port listeners:")
        foreach ($conflict in $conflicts) {
            [void]$lines.Add("  - " + (Format-ServicePortConflict -Conflict $conflict))
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($ServiceLog) -and (Test-Path -LiteralPath $ServiceLog)) {
        $rawTail = @(Get-Content -LiteralPath $ServiceLog -Tail 60 -ErrorAction SilentlyContinue)
        $cleanTail = @($rawTail | ForEach-Object { Get-CleanLogLine $_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        $interesting = @($cleanTail | Where-Object {
            $_ -match "failed to bind" -or
            $_ -match "Port already in use" -or
            $_ -match "address already in use" -or
            $_ -match "EADDRINUSE" -or
            $_ -match "process crashed" -or
            $_ -match "did not become ready" -or
            $_ -match "^Error:"
        })

        if ($interesting.Count -gt 0) {
            [void]$lines.Add("Detected startup error:")
            foreach ($line in $interesting | Select-Object -Last 12) {
                [void]$lines.Add("  " + $line)
            }
        } elseif ($cleanTail.Count -gt 0) {
            [void]$lines.Add("Recent service log:")
            foreach ($line in $cleanTail | Select-Object -Last 8) {
                [void]$lines.Add("  " + $line)
            }
        }
    } elseif (-not [string]::IsNullOrWhiteSpace($ServiceLog)) {
        [void]$lines.Add("Service log was not created before the $TimeoutSeconds second timeout.")
    }

    return ($lines -join "`r`n")
}

function Get-AgentMemoryPackageJsonPath {
    return [System.IO.Path]::Combine($script:NPM_GLOBAL, "node_modules", "@agentmemory", "agentmemory", "package.json")
}

function Get-AgentMemoryVersion {
    # Installed AgentMemory version, read straight from its package.json.
    $pkgJson = Get-AgentMemoryPackageJsonPath
    if (Test-Path -LiteralPath $pkgJson) {
        try {
            $v = (Get-Content -LiteralPath $pkgJson -Raw -Encoding UTF8 | ConvertFrom-Json).version
            if (-not [string]::IsNullOrWhiteSpace([string]$v)) {
                return ([string]$v).Trim()
            }
        } catch {
        }
    }
    return ""
}

function Get-EnvironmentStatus {
    Set-ManagerEnv

    $nodeVersion = Get-NodeVersion
    $agentMemoryCmd = Join-Path $script:NPM_GLOBAL "agentmemory$($script:CmdExt)"
    $iiiInAgentMemory = [System.IO.Path]::Combine($script:AM_DIR, "bin", "iii$($script:ExeExt)")
    $iiiInLocal = [System.IO.Path]::Combine($script:LOCAL_BIN, "iii$($script:ExeExt)")

    return [pscustomobject]@{
        Node = ($nodeVersion.Length -gt 0)
        NodeVersion = $nodeVersion
        AgentMemory = (Test-Path -LiteralPath $agentMemoryCmd)
        AgentMemoryCmd = $agentMemoryCmd
        AgentMemoryVersion = (Get-AgentMemoryVersion)
        Iii = ((Test-Path -LiteralPath $iiiInAgentMemory) -or (Test-Path -LiteralPath $iiiInLocal))
        IiiPath = $(if (Test-Path -LiteralPath $iiiInAgentMemory) { $iiiInAgentMemory } else { $iiiInLocal })
        Service = (Test-ServiceRunning)
    }
}

function Get-AgentMemoryLatestVersion {
    # Latest published version via the user's configured npm registry (works with
    # China mirrors). Returns "" on any failure (offline / blocked).
    try {
        Set-ManagerEnv
        $result = Invoke-HiddenProcess -FilePath $script:ShellCmd -Arguments "$($script:ShellArgs) npm view @agentmemory/agentmemory version" -Wait -TimeoutSeconds 60
        if ($result.ExitCode -eq 0) {
            $v = ([string]$result.Output).Trim()
            if ($v -match "^\d+\.\d+\.\d+") {
                return $v
            }
        }
    } catch {
    }
    return ""
}

function Compare-SemVer {
    # Returns 1 if A > B, -1 if A < B, 0 if equal/unknown.
    param([string]$A, [string]$B)
    try {
        $va = [version]([regex]::Match($A, "\d+\.\d+\.\d+").Value)
        $vb = [version]([regex]::Match($B, "\d+\.\d+\.\d+").Value)
        return $va.CompareTo($vb)
    } catch {
        return 0
    }
}

function Get-MissingDependencyNames {
    $status = Get-EnvironmentStatus
    $missing = New-Object System.Collections.Generic.List[string]

    if (-not $status.Node) { [void]$missing.Add("Node.js") }
    if (-not $status.AgentMemory) { [void]$missing.Add("AgentMemory") }
    if (-not $status.Iii) { [void]$missing.Add("iii-engine") }

    return @($missing)
}

function Get-McpConfig {
    return '{"mcpServers":{"agentmemory":{"command":"npx","args":["-y","@agentmemory/mcp"],"env":{"AGENTMEMORY_URL":"http://localhost:3111"}}}}'
}

function Get-AgentMemoryServerObject {
    return [ordered]@{
        command = "npx"
        args = @("-y", "@agentmemory/mcp")
        env = [ordered]@{
            AGENTMEMORY_URL = "http://localhost:3111"
        }
    }
}

function Test-AgentMemoryTextConfigured {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    return (($Text -match "agentmemory") -and ($Text -match "AGENTMEMORY_URL") -and ($Text -match "localhost:3111"))
}

function Backup-ConfigFile {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        $stamp = Get-Date -Format "yyyyMMddHHmmss"
        Copy-Item -LiteralPath $Path -Destination "$Path.bak-$stamp" -Force
    }
}

function Read-JsonObject {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        if (-not [string]::IsNullOrWhiteSpace($raw)) {
            return ($raw | ConvertFrom-Json)
        }
    }

    return [pscustomobject]@{}
}

function Ensure-PropertyObject {
    param(
        [object]$Object,
        [string]$Name
    )

    if (-not ($Object.PSObject.Properties.Name -contains $Name) -or $null -eq $Object.$Name) {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue ([pscustomobject]@{}) -Force
    }

    return $Object.$Name
}

function Write-JsonObject {
    param(
        [string]$Path,
        [object]$Object
    )

    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    Backup-ConfigFile -Path $Path
    $json = $Object | ConvertTo-Json -Depth 20
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
}

function Get-CommandPathSafe {
    param(
        [string]$Name,
        [int]$TimeoutMs = 1500
    )

    # Resolve an executable without hanging on a dead/slow PATH entry (e.g. a
    # stale mapped network drive). Get-Command scans every PATH directory, which
    # can stall for tens of seconds on an unreachable UNC path. Run it in a
    # disposable runspace and abandon it if it exceeds the timeout.
    $ps = [System.Management.Automation.PowerShell]::Create()
    try {
        [void]$ps.AddScript('param($n) $c = Get-Command $n -ErrorAction SilentlyContinue; if ($c) { [string]$c.Source } else { "" }').AddArgument($Name)
        $async = $ps.BeginInvoke()
        if ($async.AsyncWaitHandle.WaitOne($TimeoutMs)) {
            $result = $ps.EndInvoke($async)
            $ps.Dispose()
            if ($result -and $result.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$result[0])) {
                return [string]$result[0]
            }
            return ""
        }

        # Timed out: stop and abandon the runspace; do not block on Dispose.
        try { [void]$ps.BeginStop($null, $null) } catch {}
        return ""
    } catch {
        try { $ps.Dispose() } catch {}
        return ""
    }
}

function Get-CommandAny {
    param([string[]]$Names)

    foreach ($name in $Names) {
        $source = Get-CommandPathSafe -Name $name
        if (-not [string]::IsNullOrWhiteSpace($source)) {
            return [pscustomobject]@{ Name = $name; Source = $source }
        }
    }

    return $null
}

function Get-CodexConfigPath {
    if ($env:AM_MANAGER_WRITE_TEST -ne "1" -and -not [string]::IsNullOrWhiteSpace($env:CODEX_HOME) -and (Test-Path -LiteralPath $env:CODEX_HOME)) {
        return (Join-Path $env:CODEX_HOME "config.toml")
    }

    return ([System.IO.Path]::Combine($script:HomeDir, ".codex", "config.toml"))
}

function Get-TraeConfigPath {
    return ([System.IO.Path]::Combine($script:AppDataDir, "TRAE SOLO CN", "User", "mcp.json"))
}

function Get-TraeSoloConfigPath {
    return ([System.IO.Path]::Combine($script:AppDataDir, "TRAE SOLO", "User", "mcp.json"))
}

function Get-TraeConfigPaths {
    return @(
        (Get-TraeConfigPath),
        (Get-TraeSoloConfigPath)
    )
}

function Get-QoderCnConfigPath {
    # Qoder CN is a VS Code-based AI IDE. Its MCP servers live in the shared
    # client cache (verified against an installed build), using the same
    # mcpServers JSON schema as TRAE SOLO.
    return ([System.IO.Path]::Combine($script:AppDataDir, "QoderCN", "SharedClientCache", "mcp.json"))
}

function Get-OpenCodeConfigPath {
    return ([System.IO.Path]::Combine($script:HomeDir, ".config", "opencode", "opencode.json"))
}

function Get-ClaudeConfigPath {
    return ([System.IO.Path]::Combine($script:HomeDir, ".claude", "mcp.json"))
}

function Get-ClaudeDesktopConfigPath {
    return ([System.IO.Path]::Combine($script:AppDataDir, "Claude", "claude_desktop_config.json"))
}

function Get-GeminiConfigPath {
    return ([System.IO.Path]::Combine($script:HomeDir, ".gemini", "settings.json"))
}

function Get-OpenClawConfigPath {
    return ([System.IO.Path]::Combine($script:HomeDir, ".openclaw", "openclaw.json"))
}

function Get-HermesConfigPath {
    return ([System.IO.Path]::Combine($script:HomeDir, ".hermes", "config.yaml"))
}

function Get-AgentTargetDefinitions {
    return @(
        [pscustomobject]@{
            Id = "codex"
            Name = "Codex"
            CommandNames = @("codex$($script:ExeExt)", "codex")
            InstallRoot = (Split-Path -Parent (Get-CodexConfigPath))
            ConfigPath = Get-CodexConfigPath
            PromptFile = "AGENTS.md"
            ConfigureAction = "Configure-CodexMcp"
        },
        [pscustomobject]@{
            Id = "trae-cn"
            Name = "TRAE SOLO CN"
            CommandNames = @()
            InstallRoot = (Join-Path $script:AppDataDir "TRAE SOLO CN")
            ConfigPath = Get-TraeConfigPath
            PromptFile = "TRAE.md"
            ConfigureAction = "Configure-TraeCnMcp"
        },
        [pscustomobject]@{
            Id = "trae"
            Name = "TRAE SOLO"
            CommandNames = @()
            InstallRoot = (Join-Path $script:AppDataDir "TRAE SOLO")
            ConfigPath = Get-TraeSoloConfigPath
            PromptFile = "TRAE.md"
            ConfigureAction = "Configure-TraeSoloMcp"
        },
        [pscustomobject]@{
            Id = "qoder-cn"
            Name = "Qoder CN"
            CommandNames = @()
            InstallRoot = (Join-Path $script:AppDataDir "QoderCN")
            ConfigPath = Get-QoderCnConfigPath
            PromptFile = "AGENTS.md"
            ConfigureAction = "Configure-QoderCnMcp"
        },
        [pscustomobject]@{
            Id = "claude-code"
            Name = "Claude Code"
            CommandNames = @("claude$($script:ExeExt)", "claude")
            InstallRoot = (Join-Path $script:HomeDir ".claude")
            ConfigPath = Get-ClaudeConfigPath
            PromptFile = "CLAUDE.md"
            ConfigureAction = "Configure-ClaudeMcp"
        },
        [pscustomobject]@{
            Id = "claude-desktop"
            Name = "Claude Desktop"
            CommandNames = @()
            InstallRoot = (Join-Path $script:AppDataDir "Claude")
            ConfigPath = Get-ClaudeDesktopConfigPath
            PromptFile = "CLAUDE.md"
            ConfigureAction = "Configure-ClaudeDesktopMcp"
        },
        [pscustomobject]@{
            Id = "gemini"
            Name = "Gemini CLI"
            CommandNames = @("gemini$($script:ExeExt)", "gemini$($script:CmdExt)", "gemini")
            InstallRoot = (Join-Path $script:HomeDir ".gemini")
            ConfigPath = Get-GeminiConfigPath
            PromptFile = "GEMINI.md"
            ConfigureAction = "Configure-GeminiMcp"
        },
        [pscustomobject]@{
            Id = "opencode"
            Name = "OpenCode"
            CommandNames = @("opencode$($script:ExeExt)", "opencode")
            InstallRoot = ([System.IO.Path]::Combine($script:HomeDir, ".config", "opencode"))
            ConfigPath = Get-OpenCodeConfigPath
            PromptFile = "AGENTS.md"
            ConfigureAction = "Configure-OpenCodeMcp"
        },
        [pscustomobject]@{
            Id = "openclaw"
            Name = "OpenClaw"
            CommandNames = @("openclaw$($script:ExeExt)", "openclaw")
            InstallRoot = (Join-Path $script:HomeDir ".openclaw")
            ConfigPath = Get-OpenClawConfigPath
            PromptFile = "OPENCLAW.md"
            ConfigureAction = "Configure-OpenClawMcp"
        },
        [pscustomobject]@{
            Id = "hermes"
            Name = "Hermes Agent"
            CommandNames = @("hermes$($script:ExeExt)", "hermes")
            InstallRoot = (Join-Path $script:HomeDir ".hermes")
            ConfigPath = Get-HermesConfigPath
            PromptFile = "HERMES.md"
            ConfigureAction = "Configure-HermesMcp"
        }
    )
}

function Configure-JsonMcpServers {
    param([string]$Path)

    $config = Read-JsonObject -Path $Path
    $servers = Ensure-PropertyObject -Object $config -Name "mcpServers"
    $servers | Add-Member -NotePropertyName "agentmemory" -NotePropertyValue ([pscustomobject](Get-AgentMemoryServerObject)) -Force
    Write-JsonObject -Path $Path -Object $config
    return $Path
}

function Configure-CodexMcp {
    $path = Get-CodexConfigPath
    $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $existing = ""
    if (Test-Path -LiteralPath $path) {
        $existing = Get-Content -LiteralPath $path -Raw -Encoding UTF8
        Backup-ConfigFile -Path $path
    }

    $pattern = "(?ms)^\[mcp_servers\.agentmemory\].*?(?=^\[[^\r\n]+\]|\z)"
    $withoutServer = [regex]::Replace($existing, $pattern, "").TrimEnd()
    $block = @"

[mcp_servers.agentmemory]
command = "npx"
args = ["-y", "@agentmemory/mcp"]
startup_timeout_sec = 60

[mcp_servers.agentmemory.env]
AGENTMEMORY_URL = "http://localhost:3111"
"@

    Set-Content -LiteralPath $path -Value ($withoutServer + $block + "`r`n") -Encoding UTF8
    return $path
}

function Configure-TraeCnMcp {
    return (Configure-JsonMcpServers -Path (Get-TraeConfigPath))
}

function Configure-TraeSoloMcp {
    return (Configure-JsonMcpServers -Path (Get-TraeSoloConfigPath))
}

function Configure-QoderCnMcp {
    return (Configure-JsonMcpServers -Path (Get-QoderCnConfigPath))
}

function Configure-TraeMcp {
    param([switch]$All)

    if ($All) {
        $paths = New-Object System.Collections.Generic.List[string]
        foreach ($path in Get-TraeConfigPaths) {
            [void]$paths.Add((Configure-JsonMcpServers -Path $path))
        }
        return @($paths)
    }

    return (Configure-TraeCnMcp)
}

function Configure-OpenCodeMcp {
    $path = Get-OpenCodeConfigPath
    $config = Read-JsonObject -Path $path
    $mcp = Ensure-PropertyObject -Object $config -Name "mcp"
    $server = [ordered]@{
        type = "local"
        enabled = $true
        command = @("npx", "-y", "@agentmemory/mcp")
        environment = [ordered]@{
            AGENTMEMORY_URL = "http://localhost:3111"
        }
    }
    $mcp | Add-Member -NotePropertyName "agentmemory" -NotePropertyValue ([pscustomobject]$server) -Force
    Write-JsonObject -Path $path -Object $config
    return $path
}

function Configure-ClaudeMcp {
    return (Configure-JsonMcpServers -Path (Get-ClaudeConfigPath))
}

function Configure-ClaudeDesktopMcp {
    return (Configure-JsonMcpServers -Path (Get-ClaudeDesktopConfigPath))
}

function Configure-GeminiMcp {
    return (Configure-JsonMcpServers -Path (Get-GeminiConfigPath))
}

function Configure-OpenClawMcp {
    return (Configure-JsonMcpServers -Path (Get-OpenClawConfigPath))
}

function Configure-HermesMcp {
    $path = Get-HermesConfigPath
    $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    Backup-ConfigFile -Path $path
    $block = @"
mcp_servers:
  agentmemory:
    command: npx
    args: ["-y", "@agentmemory/mcp"]
    env:
      AGENTMEMORY_URL: "http://localhost:3111"

memory:
  provider: agentmemory
"@
    Set-Content -LiteralPath $path -Value ($block + "`r`n") -Encoding UTF8
    return $path
}

function Get-CliConfigCommands {
    $mcpJson = '{"command":"npx","args":["-y","@agentmemory/mcp"],"env":{"AGENTMEMORY_URL":"http://localhost:3111"}}'
    $codexPath = [System.IO.Path]::Combine($script:HomeDir, ".codex", "config.toml")
     $traeCnPath = [System.IO.Path]::Combine($script:AppDataDir, "TRAE SOLO CN", "User", "mcp.json")
     $traePath = [System.IO.Path]::Combine($script:AppDataDir, "TRAE SOLO", "User", "mcp.json")
     $qoderPath = [System.IO.Path]::Combine($script:AppDataDir, "QoderCN", "SharedClientCache", "mcp.json")
     $geminiPath = [System.IO.Path]::Combine($script:HomeDir, ".gemini", "settings.json")
     $opencodePath = [System.IO.Path]::Combine($script:HomeDir, ".config", "opencode", "opencode.json")
     $openclawPath = [System.IO.Path]::Combine($script:HomeDir, ".openclaw", "openclaw.json")
     $hermesPath = [System.IO.Path]::Combine($script:HomeDir, ".hermes", "config.yaml")
    return @(
        'claude mcp add-json agentmemory ''' + $mcpJson + '''',
        "codex: add [mcp_servers.agentmemory] to $codexPath",
        "TRAE SOLO CN: paste mcpServers.agentmemory into $traeCnPath",
        "TRAE SOLO: paste mcpServers.agentmemory into $traePath",
        "Qoder CN: paste mcpServers.agentmemory into $qoderPath",
        "Gemini CLI: add mcpServers.agentmemory to $geminiPath",
        "OpenCode: add mcp.agentmemory to $opencodePath",
        "OpenClaw: add mcpServers.agentmemory to $openclawPath",
        "Hermes: add mcp_servers.agentmemory to $hermesPath"
    ) -join "`r`n"
}

function Test-AgentInstallPresent {
    param(
        [object]$Target,
        $CommandInfo
    )

    # A resolvable CLI is definitive proof of installation.
    if ($null -ne $CommandInfo) {
        return $true
    }

    $root = [string]$Target.InstallRoot
    if ([string]::IsNullOrWhiteSpace($root) -or -not (Test-Path -LiteralPath $root)) {
        return $false
    }

    # Ignore the artifacts this manager creates itself: the config file, its
    # timestamped backups, and the single directory chain leading to the config
    # file. Any *other* entry is evidence of a genuine installation, since real
    # tools create cache, session, profile and storage subdirectories while the
    # manager only ever writes one flat config file. This prevents a tool that
    # was merely "configured" (but never installed) from reporting as installed.
    $configPath = [string]$Target.ConfigPath
    $configName = Split-Path -Leaf $configPath
    $managedTop = $configName
    try {
        $rel = $configPath.Substring($root.Length).TrimStart("\", "/")
        $managedTop = ($rel -split "[\\/]")[0]
    } catch {
    }

    foreach ($item in @(Get-ChildItem -LiteralPath $root -Force -ErrorAction SilentlyContinue)) {
        $name = $item.Name
        if ($name -eq $configName) { continue }
        if ($name -like ($configName + ".bak-*")) { continue }
        if ($name -eq $managedTop) {
            if ($item.PSIsContainer) {
                $inner = @(Get-ChildItem -LiteralPath $item.FullName -Force -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -ne $configName -and ($_.Name -notlike ($configName + ".bak-*")) })
                if ($inner.Count -gt 0) { return $true }
            }
            continue
        }
        return $true
    }

    return $false
}

function Get-AgentClientStatuses {
    $items = New-Object System.Collections.Generic.List[object]

    foreach ($target in Get-AgentTargetDefinitions) {
        $cmd = Get-CommandAny -Names $target.CommandNames
        $configPath = [string]$target.ConfigPath
        $installed = Test-AgentInstallPresent -Target $target -CommandInfo $cmd
        $configured = (Test-Path -LiteralPath $configPath) -and (Test-AgentMemoryTextConfigured (Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue))
        [void]$items.Add([pscustomobject]@{
            Id = $target.Id
            Name = $target.Name
            Installed = $installed
            CliAvailable = ($null -ne $cmd)
            ConfigPath = $configPath
            PromptFile = $target.PromptFile
            Configured = $configured
        })
    }

    foreach ($item in $items) {
        $detail = if ($item.CliAvailable) { "CLI + MCP" } elseif ($item.Installed) { "MCP" } else { "not detected" }
        $item | Add-Member -NotePropertyName "Details" -NotePropertyValue $detail -Force
    }

    return $items
}

function Get-ToolVersionText {
    param([object]$CommandInfo)

    if ($null -eq $CommandInfo) {
        return T "NotInstalled"
    }

    $source = [string]$CommandInfo.Source
    if (-not [string]::IsNullOrWhiteSpace($source) -and (Test-Path -LiteralPath $source)) {
        try {
            $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($source)
            if (-not [string]::IsNullOrWhiteSpace($versionInfo.ProductVersion)) {
                return ([string]$versionInfo.ProductVersion).Trim()
            }
            if (-not [string]::IsNullOrWhiteSpace($versionInfo.FileVersion)) {
                return ([string]$versionInfo.FileVersion).Trim()
            }
        } catch {
        }
    }

    return T "UnknownVersion"
}

function Get-AgentToolCards {
    $cards = New-Object System.Collections.Generic.List[object]
    $statuses = @{}
    foreach ($status in Get-AgentClientStatuses) {
        $statuses[$status.Id] = $status
    }

    foreach ($target in Get-AgentTargetDefinitions) {
        $cmd = Get-CommandAny -Names $target.CommandNames
        $status = $statuses[$target.Id]
        $installedText = if ($status.Installed) { T "Installed" } else { T "NotInstalled" }
        $configuredText = if ($status.Configured) { T "Configured" } else { T "NotConfigured" }
        $detail = if ($status.Installed) {
            if ($status.CliAvailable) { T "DetailCliMcp" } else { T "DetailMcpDetected" }
        } else {
            T "InstallOrExecutableMissing"
        }
        $currentVersion = if ($null -ne $cmd) {
            Get-ToolVersionText -CommandInfo $cmd
        } elseif ($status.Installed) {
            T "VersionUnknown"
        } else {
            T "NotInstalled"
        }

        [void]$cards.Add([pscustomobject]@{
            Id = $target.Id
            Name = $target.Name
            Platform = if ($script:IsWindows) { "Win" } elseif ($script:IsMacOS) { "Mac" } else { "Linux" }
            Installed = [bool]$status.Installed
            Configured = [bool]$status.Configured
            ConfigPath = $status.ConfigPath
            CurrentVersion = $currentVersion
            LatestVersion = T "NotChecked"
            InstallStatus = $installedText
            ConfigStatus = $configuredText
            Detail = $detail
            ActionText = if ($status.Configured) { T "ReconfigureTool" } else { T "ConfigureTool" }
        })
    }

    return $cards.ToArray()
}

function Get-PlaceholderToolCards {
    # Lightweight card list built only from target definitions, with no command
    # or config scanning. Used to render the tool grid instantly at startup; real
    # status is filled in by Update-ToolCardControls once the window is visible.
    $cards = New-Object System.Collections.Generic.List[object]
    foreach ($target in Get-AgentTargetDefinitions) {
        [void]$cards.Add([pscustomobject]@{
            Id = $target.Id
            Name = $target.Name
            Platform = if ($script:IsWindows) { "Win" } elseif ($script:IsMacOS) { "Mac" } else { "Linux" }
            Installed = $false
            Configured = $false
            ConfigPath = [string]$target.ConfigPath
            CurrentVersion = T "Scanning"
            LatestVersion = T "NotChecked"
            InstallStatus = T "Scanning"
            ConfigStatus = T "Scanning"
            Detail = T "Scanning"
            ActionText = T "ConfigureTool"
        })
    }
    return $cards.ToArray()
}

function Configure-AllAgentClients {
    $paths = New-Object System.Collections.Generic.List[string]
    $errors = New-Object System.Collections.Generic.List[string]

    $configureActions = @(
        @{ Name = "Codex"; Action = { Configure-CodexMcp } },
        @{ Name = "TRAE CN"; Action = { Configure-TraeCnMcp } },
        @{ Name = "TRAE SOLO"; Action = { Configure-TraeSoloMcp } },
        @{ Name = "Qoder CN"; Action = { Configure-QoderCnMcp } },
        @{ Name = "OpenCode"; Action = { Configure-OpenCodeMcp } },
        @{ Name = "Claude Code"; Action = { Configure-ClaudeMcp } },
        @{ Name = "Claude Desktop"; Action = { Configure-ClaudeDesktopMcp } },
        @{ Name = "Gemini CLI"; Action = { Configure-GeminiMcp } },
        @{ Name = "OpenClaw"; Action = { Configure-OpenClawMcp } },
        @{ Name = "Hermes Agent"; Action = { Configure-HermesMcp } }
    )

    foreach ($entry in $configureActions) {
        try {
            $result = & $entry.Action
            if ($result) {
                [void]$paths.Add($result)
            }
        } catch {
            [void]$errors.Add("$($entry.Name): $($_.Exception.Message)")
        }
    }

    if ($errors.Count -gt 0) {
        Write-Log "Config warnings: $($errors -join '; ')"
    }

    return @($paths)
}

function Get-DefaultCrossAgentCodingHome {
    return (Join-Path $script:HomeDir ".CrossAgentCoding")
}

function Get-CrossAgentCodingSettingsPath {
    if (-not [string]::IsNullOrWhiteSpace($env:CrossAgentCoding_SETTINGS)) {
        return $env:CrossAgentCoding_SETTINGS
    }

    return (Join-Path (Get-DefaultCrossAgentCodingHome) "settings.json")
}

function Read-CrossAgentCodingSettings {
    $path = Get-CrossAgentCodingSettingsPath
    if (Test-Path -LiteralPath $path) {
        try {
            $raw = Get-Content -LiteralPath $path -Raw -Encoding UTF8
            if (-not [string]::IsNullOrWhiteSpace($raw)) {
                return ($raw | ConvertFrom-Json)
            }
        } catch {
        }
    }

    return [pscustomobject]@{}
}

function Write-CrossAgentCodingSettings {
    param([object]$Settings)

    $path = Get-CrossAgentCodingSettingsPath
    $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    Set-Content -LiteralPath $path -Value ($Settings | ConvertTo-Json -Depth 12) -Encoding UTF8
    return $path
}

function Protect-Secret {
    # Encrypt a secret at rest with Windows DPAPI (CurrentUser scope). The stored
    # form "dpapi:<base64>" is only decryptable by the same Windows user on this
    # machine. Off-Windows (mac/Linux) DPAPI is unavailable, so the value is kept
    # as-is and protected by file permissions instead.
    param([string]$Plain)

    if ([string]::IsNullOrEmpty($Plain)) { return "" }
    if ($Plain -like "dpapi:*") { return $Plain }   # already encrypted
    if (-not $script:IsWindows) { return $Plain }
    try {
        Add-Type -AssemblyName System.Security -ErrorAction Stop
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Plain)
        $enc = [System.Security.Cryptography.ProtectedData]::Protect($bytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
        return "dpapi:" + [Convert]::ToBase64String($enc)
    } catch {
        return $Plain
    }
}

function Unprotect-Secret {
    param([string]$Stored)

    if ([string]::IsNullOrEmpty($Stored)) { return "" }
    if ($Stored -notlike "dpapi:*") { return $Stored }   # legacy / plaintext
    if (-not $script:IsWindows) { return "" }            # cannot decrypt off-Windows
    try {
        Add-Type -AssemblyName System.Security -ErrorAction Stop
        $enc = [Convert]::FromBase64String($Stored.Substring(6))
        $bytes = [System.Security.Cryptography.ProtectedData]::Unprotect($enc, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
        return [System.Text.Encoding]::UTF8.GetString($bytes)
    } catch {
        return ""
    }
}

function Get-MemorySettings {
    # Reads the optional "memory" object from CrossAgentCoding settings.json and
    # fills in safe defaults. Defaults keep AgentMemory zero-config: keyword-only
    # (BM25) search, no LLM provider, the 7-tool core surface.
    # API keys are stored DPAPI-encrypted and decrypted here for in-memory use.
    $settings = Read-CrossAgentCodingSettings
    $memory = $null
    if ($settings.PSObject.Properties.Name -contains "memory") {
        $memory = $settings.memory
    }

    function Get-Prop {
        param($Obj, [string]$Name, $Default)
        if ($null -ne $Obj -and ($Obj.PSObject.Properties.Name -contains $Name) -and $null -ne $Obj.$Name -and -not [string]::IsNullOrWhiteSpace([string]$Obj.$Name)) {
            return $Obj.$Name
        }
        return $Default
    }

    return [pscustomobject]@{
        EmbeddingMode       = [string](Get-Prop $memory "embeddingMode" "keyword")     # keyword | local | cloud
        # Cloud embedding "format"/provider. "openai" means any OpenAI-compatible
        # endpoint (set EmbeddingBaseUrl for a custom one).
        EmbeddingFormat     = [string](Get-Prop $memory "embeddingFormat" ([string](Get-Prop $memory "embeddingProvider" "openai")))
        EmbeddingBaseUrl    = [string](Get-Prop $memory "embeddingBaseUrl" "")
        EmbeddingModel      = [string](Get-Prop $memory "embeddingModel" "")
        EmbeddingDimensions = [string](Get-Prop $memory "embeddingDimensions" "")
        EmbeddingApiKey     = [string](Unprotect-Secret ([string](Get-Prop $memory "embeddingApiKey" "")))
        # LLM "format": none | openai (Chat Completions) | anthropic (Messages) |
        # gemini | openrouter | minimax. openai/anthropic accept a custom Base URL.
        LlmFormat           = [string](Get-Prop $memory "llmFormat" ([string](Get-Prop $memory "llmProvider" "none")))
        LlmBaseUrl          = [string](Get-Prop $memory "llmBaseUrl" "")
        LlmModel            = [string](Get-Prop $memory "llmModel" "")
        LlmApiKey           = [string](Unprotect-Secret ([string](Get-Prop $memory "llmApiKey" "")))
        Tools               = [string](Get-Prop $memory "tools" "core")               # core | all
        UseHfMirror         = [bool](Get-Prop $memory "useHfMirror" $true)
        # LLM-gated features (all require an LLM key; default off, matching AgentMemory).
        GraphExtraction     = [bool](Get-Prop $memory "graphExtraction" $false)
        Consolidation       = [bool](Get-Prop $memory "consolidation" $false)
        AutoCompress        = [bool](Get-Prop $memory "autoCompress" $false)
        InjectContext       = [bool](Get-Prop $memory "injectContext" $false)
    }
}

function Save-MemorySettings {
    param([object]$Memory)

    $settings = Read-CrossAgentCodingSettings
    $obj = [ordered]@{
        embeddingMode       = [string]$Memory.EmbeddingMode
        embeddingFormat     = [string]$Memory.EmbeddingFormat
        embeddingBaseUrl    = [string]$Memory.EmbeddingBaseUrl
        embeddingModel      = [string]$Memory.EmbeddingModel
        embeddingDimensions = [string]$Memory.EmbeddingDimensions
        embeddingApiKey     = Protect-Secret ([string]$Memory.EmbeddingApiKey)
        llmFormat           = [string]$Memory.LlmFormat
        llmBaseUrl          = [string]$Memory.LlmBaseUrl
        llmModel            = [string]$Memory.LlmModel
        llmApiKey           = Protect-Secret ([string]$Memory.LlmApiKey)
        tools               = [string]$Memory.Tools
        useHfMirror         = [bool]$Memory.UseHfMirror
        graphExtraction     = [bool]$Memory.GraphExtraction
        consolidation       = [bool]$Memory.Consolidation
        autoCompress        = [bool]$Memory.AutoCompress
        injectContext       = [bool]$Memory.InjectContext
    }
    $settings | Add-Member -NotePropertyName "memory" -NotePropertyValue ([pscustomobject]$obj) -Force
    return (Write-CrossAgentCodingSettings -Settings $settings)
}

function Get-ProviderKeyEnvName {
    param([string]$Provider)

    switch ($Provider) {
        "openai"     { return "OPENAI_API_KEY" }
        "gemini"     { return "GEMINI_API_KEY" }
        "anthropic"  { return "ANTHROPIC_API_KEY" }
        "minimax"    { return "MINIMAX_API_KEY" }
        "openrouter" { return "OPENROUTER_API_KEY" }
        "voyage"     { return "VOYAGE_API_KEY" }
        "cohere"     { return "COHERE_API_KEY" }
        default      { return "" }
    }
}

function Get-MemoryEnvMap {
    # Translates the saved memory settings into the AgentMemory environment
    # variables the service reads at startup. Every variable this manager owns is
    # always present in the map (value or empty) so Apply-MemoryEnv can both set
    # and clear them when the user toggles options off.
    $m = Get-MemorySettings
    $map = [ordered]@{
        EMBEDDING_PROVIDER          = ""
        OPENAI_API_KEY              = ""
        OPENAI_BASE_URL             = ""
        OPENAI_MODEL                = ""
        OPENAI_EMBEDDING_MODEL      = ""
        OPENAI_EMBEDDING_DIMENSIONS = ""
        GEMINI_API_KEY              = ""
        GEMINI_MODEL                = ""
        ANTHROPIC_API_KEY           = ""
        ANTHROPIC_BASE_URL          = ""
        ANTHROPIC_MODEL             = ""
        MINIMAX_API_KEY             = ""
        MINIMAX_MODEL               = ""
        OPENROUTER_API_KEY          = ""
        OPENROUTER_MODEL            = ""
        OPENROUTER_EMBEDDING_MODEL  = ""
        VOYAGE_API_KEY              = ""
        COHERE_API_KEY              = ""
        AGENTMEMORY_TOOLS           = ""
        GRAPH_EXTRACTION_ENABLED    = ""
        CONSOLIDATION_ENABLED       = ""
        AGENTMEMORY_AUTO_COMPRESS   = ""
        AGENTMEMORY_INJECT_CONTEXT  = ""
        HF_ENDPOINT                 = ""
        TRANSFORMERS_CACHE          = ""
        HF_HOME                     = ""
        HF_HUB_CACHE                = ""
    }

    # Local embedding model download location (relocatable storage). Several env
    # names exist across Transformers.js / HF tooling versions, so set them all.
    $modelCacheDir = Get-ModelCacheDir
    $map["TRANSFORMERS_CACHE"] = $modelCacheDir
    $map["HF_HOME"] = $modelCacheDir
    $map["HF_HUB_CACHE"] = $modelCacheDir

    # Embedding leg of hybrid search.
    if ($m.EmbeddingMode -eq "local") {
        $map["EMBEDDING_PROVIDER"] = "local"
        if ($m.UseHfMirror) {
            $map["HF_ENDPOINT"] = $script:HF_MIRROR_URL
        }
    } elseif ($m.EmbeddingMode -eq "cloud") {
        $map["EMBEDDING_PROVIDER"] = $m.EmbeddingFormat
        $keyName = Get-ProviderKeyEnvName -Provider $m.EmbeddingFormat
        if ($keyName -and -not [string]::IsNullOrWhiteSpace($m.EmbeddingApiKey)) {
            $map[$keyName] = $m.EmbeddingApiKey
        }
        if ($m.EmbeddingFormat -eq "openai") {
            # OpenAI-compatible embeddings (custom endpoint, e.g. SiliconFlow / vLLM).
            if (-not [string]::IsNullOrWhiteSpace($m.EmbeddingBaseUrl)) { $map["OPENAI_BASE_URL"] = $m.EmbeddingBaseUrl }
            if (-not [string]::IsNullOrWhiteSpace($m.EmbeddingModel)) { $map["OPENAI_EMBEDDING_MODEL"] = $m.EmbeddingModel }
            if (-not [string]::IsNullOrWhiteSpace($m.EmbeddingDimensions)) { $map["OPENAI_EMBEDDING_DIMENSIONS"] = $m.EmbeddingDimensions }
        } elseif ($m.EmbeddingFormat -eq "openrouter") {
            if (-not [string]::IsNullOrWhiteSpace($m.EmbeddingModel)) { $map["OPENROUTER_EMBEDDING_MODEL"] = $m.EmbeddingModel }
        }
    }
    # keyword mode leaves EMBEDDING_PROVIDER empty so AgentMemory stays BM25-only.

    # LLM provider for compression / summarization / graph features, with custom
    # base URL + model for the two API formats the user can target.
    if ($m.LlmFormat -and $m.LlmFormat -ne "none") {
        $keyName = Get-ProviderKeyEnvName -Provider $m.LlmFormat
        if ($keyName -and -not [string]::IsNullOrWhiteSpace($m.LlmApiKey)) {
            $map[$keyName] = $m.LlmApiKey
        }
        switch ($m.LlmFormat) {
            "openai" {
                if (-not [string]::IsNullOrWhiteSpace($m.LlmBaseUrl)) { $map["OPENAI_BASE_URL"] = $m.LlmBaseUrl }
                if (-not [string]::IsNullOrWhiteSpace($m.LlmModel)) { $map["OPENAI_MODEL"] = $m.LlmModel }
            }
            "anthropic" {
                if (-not [string]::IsNullOrWhiteSpace($m.LlmBaseUrl)) { $map["ANTHROPIC_BASE_URL"] = $m.LlmBaseUrl }
                if (-not [string]::IsNullOrWhiteSpace($m.LlmModel)) { $map["ANTHROPIC_MODEL"] = $m.LlmModel }
            }
            "gemini"     { if (-not [string]::IsNullOrWhiteSpace($m.LlmModel)) { $map["GEMINI_MODEL"] = $m.LlmModel } }
            "openrouter" { if (-not [string]::IsNullOrWhiteSpace($m.LlmModel)) { $map["OPENROUTER_MODEL"] = $m.LlmModel } }
            "minimax"    { if (-not [string]::IsNullOrWhiteSpace($m.LlmModel)) { $map["MINIMAX_MODEL"] = $m.LlmModel } }
        }
    }

    if ($m.Tools -eq "all") {
        $map["AGENTMEMORY_TOOLS"] = "all"
    } else {
        $map["AGENTMEMORY_TOOLS"] = "core"
    }

    # LLM-gated features (knowledge graph, consolidation, etc.). Only meaningful
    # with an LLM provider configured; set "true" when the user opts in.
    if ($m.GraphExtraction) { $map["GRAPH_EXTRACTION_ENABLED"] = "true" }
    if ($m.Consolidation)   { $map["CONSOLIDATION_ENABLED"] = "true" }
    if ($m.AutoCompress)    { $map["AGENTMEMORY_AUTO_COMPRESS"] = "true" }
    if ($m.InjectContext)   { $map["AGENTMEMORY_INJECT_CONTEXT"] = "true" }

    return $map
}

function Apply-MemoryEnv {
    # Pushes the memory env map into the current process so the AgentMemory
    # service (launched as a child with inherited environment) picks it up.
    $map = Get-MemoryEnvMap
    foreach ($name in $map.Keys) {
        $value = [string]$map[$name]
        if ([string]::IsNullOrWhiteSpace($value)) {
            Remove-Item -LiteralPath ("Env:" + $name) -ErrorAction SilentlyContinue
        } else {
            Set-Item -LiteralPath ("Env:" + $name) -Value $value
        }
    }
}

function Get-AgentMemoryCliPath {
    return (Join-Path $script:NPM_GLOBAL "agentmemory$($script:CmdExt)")
}

function Get-XenovaTransformersPath {
    return [System.IO.Path]::Combine($script:NPM_GLOBAL, "node_modules", "@xenova", "transformers")
}

function Test-LocalEmbeddingReady {
    return (Test-Path -LiteralPath (Get-XenovaTransformersPath))
}

function Get-CrossAgentCodingHome {
    if (-not [string]::IsNullOrWhiteSpace($env:CrossAgentCoding_HOME)) {
        return [System.IO.Path]::GetFullPath($env:CrossAgentCoding_HOME)
    }

    $settings = Read-CrossAgentCodingSettings
    if ($settings.PSObject.Properties.Name -contains "dataHome" -and -not [string]::IsNullOrWhiteSpace($settings.dataHome)) {
        return [System.IO.Path]::GetFullPath([string]$settings.dataHome)
    }

    return (Get-DefaultCrossAgentCodingHome)
}

function Move-CrossAgentCodingHome {
    param(
        [string]$NewHome,
        [switch]$SwitchOnly
    )

    if ([string]::IsNullOrWhiteSpace($NewHome)) {
        throw "New CrossAgentCoding data directory is required"
    }

    $oldHome = Get-CrossAgentCodingHome
    $targetHome = [System.IO.Path]::GetFullPath($NewHome)
    if (-not (Test-Path -LiteralPath $targetHome)) {
        New-Item -ItemType Directory -Path $targetHome -Force | Out-Null
    }

    $probe = Join-Path $targetHome ".write-test"
    Set-Content -LiteralPath $probe -Value "ok" -Encoding UTF8
    Remove-Item -LiteralPath $probe -Force

    if (-not $SwitchOnly -and (Test-Path -LiteralPath $oldHome)) {
        $oldFull = [System.IO.Path]::GetFullPath($oldHome).TrimEnd("\", "/")
        $targetFull = $targetHome.TrimEnd("\", "/")
        if ($targetFull.StartsWith($oldFull, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "New data directory cannot be inside the current data directory during migration"
        }

        Get-ChildItem -LiteralPath $oldHome -Force -ErrorAction SilentlyContinue | ForEach-Object {
            $dest = Join-Path $targetHome $_.Name
            Copy-Item -LiteralPath $_.FullName -Destination $dest -Recurse -Force
        }
    }

    $settings = Read-CrossAgentCodingSettings
    if (-not ($settings.PSObject.Properties.Name -contains "dataHome")) {
        $settings | Add-Member -NotePropertyName "dataHome" -NotePropertyValue $targetHome -Force
    } else {
        $settings.dataHome = $targetHome
    }
    $settings | Add-Member -NotePropertyName "updatedAt" -NotePropertyValue ((Get-Date).ToString("o")) -Force
    [void](Write-CrossAgentCodingSettings -Settings $settings)

    return [pscustomobject]@{
        OldHome = $oldHome
        NewHome = $targetHome
        SettingsPath = Get-CrossAgentCodingSettingsPath
        Migrated = (-not $SwitchOnly)
    }
}

function Get-StorageSettings {
    # Relocatable storage roots. serviceDir is the working directory the
    # AgentMemory service runs in, so its iii data store (./data/state_store.db
    # and ./data/stream_store) and service log land there. modelCacheDir is where
    # the local embedding model (all-MiniLM-L6-v2) is downloaded.
    $settings = Read-CrossAgentCodingSettings
    $storage = $null
    if ($settings.PSObject.Properties.Name -contains "storage") {
        $storage = $settings.storage
    }

    $serviceDir = $script:AM_DIR
    if ($null -ne $storage -and ($storage.PSObject.Properties.Name -contains "serviceDir") -and -not [string]::IsNullOrWhiteSpace([string]$storage.serviceDir)) {
        $serviceDir = [System.IO.Path]::GetFullPath([string]$storage.serviceDir)
    }

    $modelCacheDir = Join-Path $serviceDir "models"
    if ($null -ne $storage -and ($storage.PSObject.Properties.Name -contains "modelCacheDir") -and -not [string]::IsNullOrWhiteSpace([string]$storage.modelCacheDir)) {
        $modelCacheDir = [System.IO.Path]::GetFullPath([string]$storage.modelCacheDir)
    }

    return [pscustomobject]@{
        ServiceDir    = $serviceDir
        ModelCacheDir = $modelCacheDir
    }
}

function Set-StorageSetting {
    param(
        [string]$Key,    # serviceDir | modelCacheDir
        [string]$Value
    )

    $settings = Read-CrossAgentCodingSettings
    $storage = if ($settings.PSObject.Properties.Name -contains "storage") { $settings.storage } else { [pscustomobject]@{} }
    $storage | Add-Member -NotePropertyName $Key -NotePropertyValue $Value -Force
    $settings | Add-Member -NotePropertyName "storage" -NotePropertyValue $storage -Force
    return (Write-CrossAgentCodingSettings -Settings $settings)
}

function Get-ServiceWorkDir {
    return (Get-StorageSettings).ServiceDir
}

function Get-ModelCacheDir {
    return (Get-StorageSettings).ModelCacheDir
}

function Get-ServiceLogPath {
    return (Join-Path (Get-ServiceWorkDir) "agentmemory-service.log")
}

function Copy-DirectoryContents {
    param(
        [string]$From,
        [string]$To
    )

    if (-not (Test-Path -LiteralPath $To)) {
        New-Item -ItemType Directory -Path $To -Force | Out-Null
    }
    if (Test-Path -LiteralPath $From) {
        Get-ChildItem -LiteralPath $From -Force -ErrorAction SilentlyContinue | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $To $_.Name) -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Move-StorageLocation {
    param(
        [string]$Key,        # serviceDir | modelCacheDir
        [string]$NewDir,
        [switch]$SwitchOnly  # only repoint, do not copy existing data
    )

    if ([string]::IsNullOrWhiteSpace($NewDir)) {
        throw "New storage directory is required"
    }

    $target = [System.IO.Path]::GetFullPath($NewDir)
    $current = if ($Key -eq "modelCacheDir") { Get-ModelCacheDir } else { Get-ServiceWorkDir }
    $currentFull = [System.IO.Path]::GetFullPath($current).TrimEnd("\", "/")
    $targetFull = $target.TrimEnd("\", "/")

    if (-not (Test-Path -LiteralPath $target)) {
        New-Item -ItemType Directory -Path $target -Force | Out-Null
    }

    # Verify writability up front.
    $probe = Join-Path $target ".write-test"
    Set-Content -LiteralPath $probe -Value "ok" -Encoding UTF8
    Remove-Item -LiteralPath $probe -Force

    if ($targetFull.StartsWith($currentFull, [System.StringComparison]::OrdinalIgnoreCase) -and $targetFull -ne $currentFull) {
        throw "New directory cannot be inside the current storage directory during migration"
    }

    if (-not $SwitchOnly -and $targetFull -ne $currentFull -and (Test-Path -LiteralPath $current)) {
        Copy-DirectoryContents -From $current -To $target
    }

    [void](Set-StorageSetting -Key $Key -Value $target)

    return [pscustomobject]@{
        Key = $Key
        OldDir = $current
        NewDir = $target
    }
}

function Get-ProjectGitRemote {
    param([string]$ProjectPath)

    if ([string]::IsNullOrWhiteSpace($ProjectPath) -or -not (Test-Path -LiteralPath $ProjectPath)) {
        return ""
    }

    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) {
        return ""
    }

    try {
        $remote = & git -C $ProjectPath config --get remote.origin.url 2>$null
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($remote)) {
            return ""
        }
        return ([string]$remote).Trim().ToLowerInvariant()
    } catch {
        return ""
    }
}

function Get-WorkspaceId {
    param([string]$ProjectPath)

    if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
        $ProjectPath = (Get-Location).Path
    }

    $normalized = [System.IO.Path]::GetFullPath($ProjectPath).TrimEnd("\", "/").ToLowerInvariant()

    # Workspace identity is the normalized project path plus the Git remote when
    # available. The remote is appended only when present so that non-Git
    # projects keep stable, path-only identifiers.
    $identity = $normalized
    $remote = Get-ProjectGitRemote -ProjectPath $ProjectPath
    if (-not [string]::IsNullOrWhiteSpace($remote)) {
        $identity = $normalized + "|" + $remote
    }

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($identity)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $sha.ComputeHash($bytes)
    } finally {
        $sha.Dispose()
    }

    $hex = -join ($hashBytes | ForEach-Object { $_.ToString("x2") })
    return $hex.Substring(0, 16)
}

function Get-WorkspacePath {
    param([string]$ProjectPath)

    return (Join-Path (Join-Path (Get-CrossAgentCodingHome) "workspaces") (Get-WorkspaceId -ProjectPath $ProjectPath))
}

function Get-WorkspacePromptFileNames {
    return @("AGENTS.md", "TRAE.md", "CLAUDE.md", "GEMINI.md", "OPENCODE.md", "OPENCLAW.md", "HERMES.md")
}

function Sync-WorkspacePromptFiles {
    param([string]$ProjectPath)

    $workspacePath = Get-WorkspacePath -ProjectPath $ProjectPath
    if (-not (Test-Path -LiteralPath $workspacePath)) {
        New-Item -ItemType Directory -Path $workspacePath -Force | Out-Null
    }

    $handoffPath = Join-Path $workspacePath "handoff.md"
    $handoff = ""
    if (Test-Path -LiteralPath $handoffPath) {
        $handoff = Get-Content -LiteralPath $handoffPath -Raw -Encoding UTF8
    }

    $content = (Get-SharedPromptContent) + "`r`n`r`n## Workspace`r`nProject: $([System.IO.Path]::GetFullPath($ProjectPath))`r`nWorkspace ID: $(Get-WorkspaceId -ProjectPath $ProjectPath)`r`n`r`n## Latest Handoff`r`n$handoff"
    $paths = New-Object System.Collections.Generic.List[string]
    foreach ($name in Get-WorkspacePromptFileNames) {
        $path = Join-Path $workspacePath $name
        Set-Content -LiteralPath $path -Value $content -Encoding UTF8
        [void]$paths.Add($path)
    }

    return @($paths)
}

function Initialize-WorkspaceMemory {
    param([string]$ProjectPath)

    if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
        $ProjectPath = (Get-Location).Path
    }

    $fullPath = [System.IO.Path]::GetFullPath($ProjectPath)
    $workspacePath = Get-WorkspacePath -ProjectPath $fullPath
    if (-not (Test-Path -LiteralPath $workspacePath)) {
        New-Item -ItemType Directory -Path $workspacePath -Force | Out-Null
    }

    $workspace = [ordered]@{
        id = Get-WorkspaceId -ProjectPath $fullPath
        projectPath = $fullPath
        updatedAt = (Get-Date).ToString("o")
    }
    $workspaceFile = Join-Path $workspacePath "workspace.json"
    if (-not (Test-Path -LiteralPath $workspaceFile)) {
        $workspace.createdAt = $workspace.updatedAt
    } else {
        try {
            $existing = Get-Content -LiteralPath $workspaceFile -Raw -Encoding UTF8 | ConvertFrom-Json
            $workspace.createdAt = $existing.createdAt
        } catch {
            $workspace.createdAt = $workspace.updatedAt
        }
    }

    Set-Content -LiteralPath $workspaceFile -Value ($workspace | ConvertTo-Json -Depth 8) -Encoding UTF8
    [void](Sync-WorkspacePromptFiles -ProjectPath $fullPath)

    return [pscustomobject]@{
        Id = $workspace.id
        ProjectPath = $fullPath
        WorkspacePath = $workspacePath
        WorkspaceFile = $workspaceFile
    }
}

function Add-SessionBridgeEntry {
    param(
        [string]$ProjectPath,
        [string]$Tool,
        [string]$Summary,
        [string]$SourcePath = ""
    )

    $workspace = Initialize-WorkspaceMemory -ProjectPath $ProjectPath
    $entry = [ordered]@{
        timestamp = (Get-Date).ToString("o")
        workspaceId = $workspace.Id
        projectPath = $workspace.ProjectPath
        tool = $Tool
        sourcePath = $SourcePath
        summary = $Summary
    }

    $sessionsPath = Join-Path $workspace.WorkspacePath "sessions.jsonl"
    Add-Content -LiteralPath $sessionsPath -Value ($entry | ConvertTo-Json -Compress -Depth 8) -Encoding UTF8

    $handoff = @"
# CrossAgentCoding Workspace Handoff

Project: $($workspace.ProjectPath)
Workspace ID: $($workspace.Id)
Updated: $($entry.timestamp)
Tool: $Tool
Source: $SourcePath

$Summary
"@
    Set-Content -LiteralPath (Join-Path $workspace.WorkspacePath "handoff.md") -Value $handoff -Encoding UTF8
    [void](Sync-WorkspacePromptFiles -ProjectPath $workspace.ProjectPath)
    return $sessionsPath
}

function Get-BoundedTextFiles {
    param(
        [string[]]$Roots,
        [int]$MaxFiles = 20,
        [int]$MaxBytes = 4000
    )

    $items = New-Object System.Collections.Generic.List[object]
    foreach ($root in $Roots) {
        if (-not (Test-Path -LiteralPath $root)) {
            continue
        }

        Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Length -gt 0 -and $_.Length -le 1048576 -and $_.Extension -match "(\.jsonl|\.json|\.md|\.txt|\.log)$" } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First $MaxFiles |
            ForEach-Object {
                if ($items.Count -lt $MaxFiles) {
                    $text = ""
                    try {
                        $text = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 -ErrorAction Stop
                    } catch {
                        $text = ""
                    }
                    if ($text.Length -gt $MaxBytes) {
                        $text = $text.Substring(0, $MaxBytes)
                    }
                    [void]$items.Add([pscustomobject]@{
                        Path = $_.FullName
                        Text = $text
                    })
                }
            }
    }

    return $items.ToArray()
}

function Get-CodexSessionRoots {
    $codexHome = Split-Path -Parent (Get-CodexConfigPath)
    return @((Join-Path $codexHome "sessions"))
}

function Get-TraeDataRoots {
    return @(
        (Join-Path $script:AppDataDir "TRAE SOLO CN"),
        (Join-Path $script:AppDataDir "TRAE SOLO")
    )
}

function Import-CodexSessionBridge {
    param([string]$ProjectPath)

    $files = @(Get-BoundedTextFiles -Roots (Get-CodexSessionRoots) -MaxFiles 12 -MaxBytes 3000)
    if ($files.Count -eq 0) {
        return (Add-SessionBridgeEntry -ProjectPath $ProjectPath -Tool "Codex" -Summary "No readable Codex session files were found for bridge import." -SourcePath "")
    }

    $summary = "Imported Codex session snippets:`r`n" + (($files | ForEach-Object { "- $($_.Path)`r`n$($_.Text)" }) -join "`r`n")
    return (Add-SessionBridgeEntry -ProjectPath $ProjectPath -Tool "Codex" -Summary $summary -SourcePath ($files[0].Path))
}

function Import-TraeSessionBridge {
    param([string]$ProjectPath)

    $roots = Get-TraeDataRoots | ForEach-Object { Join-Path $_ "logs" }
    $files = @(Get-BoundedTextFiles -Roots $roots -MaxFiles 12 -MaxBytes 3000)
    if ($files.Count -eq 0) {
        return (Add-SessionBridgeEntry -ProjectPath $ProjectPath -Tool "TRAE" -Summary "No readable TRAE session or log files were found for bridge import." -SourcePath "")
    }

    $summary = "Imported TRAE session/log snippets:`r`n" + (($files | ForEach-Object { "- $($_.Path)`r`n$($_.Text)" }) -join "`r`n")
    return (Add-SessionBridgeEntry -ProjectPath $ProjectPath -Tool "TRAE" -Summary $summary -SourcePath ($files[0].Path))
}

function Get-SharedPromptContent {
    return @"
# CrossAgentCoding Shared Agent Context

Use AgentMemory for durable cross-agent context.

AgentMemory MCP endpoint:
http://localhost:3111

Recommended workflow:
1. At task start, search AgentMemory for project goals, decisions, and active constraints.
2. During work, store durable decisions, file paths, test commands, and cross-agent handoff notes.
3. At task end, summarize what changed and write a concise memory entry.

This file is generated by CrossAgentCoding and inspired by cc-switch style shared agent configuration.
"@
}

function Get-CcSwitchInspiredFeatures {
    return @(
        "Unified MCP configuration across Coding Agents",
        "User-level config backup before writes",
        "Shared prompt/context files for Codex, Claude Code, OpenCode, and TRAE SOLO CN",
        "Copyable CLI snippets for manual setup",
        "Fast scan of installed/configured agent clients"
    )
}

function Sync-SharedAgentFiles {
    $appHome = Get-CrossAgentCodingHome
    $sharedDir = Join-Path $appHome "shared"
    if (-not (Test-Path -LiteralPath $sharedDir)) {
        New-Item -ItemType Directory -Path $sharedDir -Force | Out-Null
    }

    $content = Get-SharedPromptContent
    $paths = @(
        (Join-Path $sharedDir "AGENTS.md"),
        (Join-Path $sharedDir "CLAUDE.md"),
        (Join-Path $sharedDir "OPENCODE.md"),
        (Join-Path $sharedDir "TRAE.md"),
        (Join-Path $sharedDir "GEMINI.md"),
        (Join-Path $sharedDir "OPENCLAW.md"),
        (Join-Path $sharedDir "HERMES.md")
    )

    foreach ($path in $paths) {
        Set-Content -LiteralPath $path -Value $content -Encoding UTF8
    }

    return $paths
}

function Invoke-HiddenProcess {
    param(
        [string]$FilePath,
        [string]$Arguments,
        [int]$TimeoutSeconds = 0,
        [string]$WorkingDirectory = "",
        [switch]$Wait
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    $psi.Arguments = $Arguments
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) {
        $psi.WorkingDirectory = $WorkingDirectory
    }

    if ($Wait) {
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
    }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    [void]$process.Start()

    if (-not $Wait) {
        return [pscustomobject]@{
            ExitCode = $null
            Output = ""
            Error = ""
            Process = $process
        }
    }

    $completed = $true
    if ($TimeoutSeconds -gt 0) {
        $completed = $process.WaitForExit($TimeoutSeconds * 1000)
    } else {
        $process.WaitForExit()
    }

    if (-not $completed) {
        try { $process.Kill() } catch {}
        throw "Process timed out: $FilePath $Arguments"
    }

    return [pscustomobject]@{
        ExitCode = $process.ExitCode
        Output = $process.StandardOutput.ReadToEnd()
        Error = $process.StandardError.ReadToEnd()
        Process = $process
    }
}

function Write-CliHelp {
    Write-Output "CrossAgentCoding CLI MVP"
    Write-Output "Commands:"
    Write-Output "  env tools                       Check local tools and service"
    Write-Output "  agents scan                     List agent connection status"
    Write-Output "  agents configure                Auto-configure AgentMemory MCP"
    Write-Output "  workspace init [path]           Initialize workspace memory"
    Write-Output "  workspace bridge [path]         Import Codex/TRAE bridge summaries"
    Write-Output "  config home                     Show CrossAgentCoding data directory"
    Write-Output "  config migrate <path>           Migrate data directory"
}

function Get-CliArgsFromInvocationLine {
    param([string]$Line)

    if ([string]::IsNullOrWhiteSpace($Line)) {
        return @()
    }

    $match = [regex]::Match($Line, "(?i)\s-Cli\s+(?<tail>.+)$")
    if (-not $match.Success) {
        return @()
    }

    $tail = $match.Groups["tail"].Value.Trim()
    if ([string]::IsNullOrWhiteSpace($tail)) {
        return @()
    }

    $matches = [regex]::Matches($tail, '"([^"]+)"|''([^'']+)''|(\S+)')
    return @($matches | ForEach-Object {
        if ($_.Groups[1].Success) { $_.Groups[1].Value }
        elseif ($_.Groups[2].Success) { $_.Groups[2].Value }
        else { $_.Groups[3].Value }
    })
}

function Invoke-CliMode {
    param([string[]]$CliArgs)

    $script:CliExitCode = 0
    if ($CliArgs.Count -eq 0) {
        Write-CliHelp
        return
    }

    $command = (($CliArgs -join " ")).ToLowerInvariant()
    if ($command -eq "env tools") {
        $status = Get-EnvironmentStatus
        Write-Output "Node: $($status.Node) $($status.NodeVersion)"
        Write-Output "AgentMemory: $($status.AgentMemory)"
        Write-Output "iii-engine: $($status.Iii)"
        Write-Output "Service: $($status.Service)"
        return
    } elseif ($command -eq "agents scan") {
        Get-AgentClientStatuses | ForEach-Object {
            Write-Output "$($_.Id)`t$($_.Name)`tinstalled=$($_.Installed)`tconfigured=$($_.Configured)`tpath=$($_.ConfigPath)"
        }
        return
    } elseif ($command -eq "agents configure") {
        Configure-AllAgentClients | ForEach-Object { Write-Output "configured: $_" }
        return
    } elseif ($command -match "^workspace init") {
        $projectPath = if ($CliArgs.Count -ge 3) { $CliArgs[2] } else { (Get-Location).Path }
        $workspace = Initialize-WorkspaceMemory -ProjectPath $projectPath
        Write-Output "workspace: $($workspace.Id)"
        Write-Output "path: $($workspace.WorkspacePath)"
        return
    } elseif ($command -match "^workspace bridge") {
        $projectPath = if ($CliArgs.Count -ge 3) { $CliArgs[2] } else { (Get-Location).Path }
        [void](Import-CodexSessionBridge -ProjectPath $projectPath)
        [void](Import-TraeSessionBridge -ProjectPath $projectPath)
        $workspace = Initialize-WorkspaceMemory -ProjectPath $projectPath
        Write-Output "bridge imported: $($workspace.WorkspacePath)"
        return
    } elseif ($command -eq "config home") {
        Write-Output (Get-CrossAgentCodingHome)
        return
    } elseif ($command -eq "memory show") {
        $m = Get-MemorySettings
        Write-Output "embeddingMode: $($m.EmbeddingMode)"
        Write-Output "embeddingFormat: $($m.EmbeddingFormat)"
        Write-Output "embeddingBaseUrl: $($m.EmbeddingBaseUrl)"
        Write-Output "embeddingModel: $($m.EmbeddingModel)"
        Write-Output "embeddingDimensions: $($m.EmbeddingDimensions)"
        Write-Output "embeddingApiKey: $(if ($m.EmbeddingApiKey) { '***set***' } else { '(empty)' })"
        Write-Output "llmFormat: $($m.LlmFormat)"
        Write-Output "llmBaseUrl: $($m.LlmBaseUrl)"
        Write-Output "llmModel: $($m.LlmModel)"
        Write-Output "llmApiKey: $(if ($m.LlmApiKey) { '***set***' } else { '(empty)' })"
        Write-Output "tools: $($m.Tools)"
        Write-Output "useHfMirror: $($m.UseHfMirror)"
        Write-Output "keyStorage: $(if ($script:IsWindows) { 'DPAPI-encrypted (CurrentUser)' } else { 'plaintext (file perms)' })"
        Write-Output "graphExtraction: $($m.GraphExtraction)"
        Write-Output "consolidation: $($m.Consolidation)"
        Write-Output "autoCompress: $($m.AutoCompress)"
        Write-Output "injectContext: $($m.InjectContext)"
        Write-Output "localEmbeddingReady: $(Test-LocalEmbeddingReady)"
        return
    } elseif ($command -eq "memory encrypt") {
        # Migrate any legacy plaintext API keys in settings.json to DPAPI-encrypted form.
        $m = Get-MemorySettings
        [void](Save-MemorySettings -Memory $m)
        Write-Output "memory secrets re-saved (encrypted at rest on Windows via DPAPI)"
        return
    } elseif ($command -eq "memory env") {
        $map = Get-MemoryEnvMap
        foreach ($name in $map.Keys) {
            $value = [string]$map[$name]
            if ($name -match "API_KEY" -and -not [string]::IsNullOrWhiteSpace($value)) { $value = "***set***" }
            Write-Output "$name=$value"
        }
        return
    } elseif ($command -eq "storage show") {
        $s = Get-StorageSettings
        Write-Output "CrossAgentCodingHome: $(Get-CrossAgentCodingHome)"
        Write-Output "serviceDir: $($s.ServiceDir)"
        Write-Output "modelCacheDir: $($s.ModelCacheDir)"
        Write-Output "serviceLog: $(Get-ServiceLogPath)"
        return
    } elseif ($command -match "^storage service ") {
        if ($CliArgs.Count -lt 3) { Write-Error "storage service requires a target path"; $script:CliExitCode = 2; return }
        $r = Move-StorageLocation -Key "serviceDir" -NewDir $CliArgs[2]
        Write-Output "serviceDir migrated: $($r.NewDir)"
        return
    } elseif ($command -match "^storage model ") {
        if ($CliArgs.Count -lt 3) { Write-Error "storage model requires a target path"; $script:CliExitCode = 2; return }
        $r = Move-StorageLocation -Key "modelCacheDir" -NewDir $CliArgs[2]
        Write-Output "modelCacheDir migrated: $($r.NewDir)"
        return
    } elseif ($command -match "^config migrate ") {
        if ($CliArgs.Count -lt 3) {
            Write-Error "config migrate requires a target path"
            $script:CliExitCode = 2
            return
        }
        $result = Move-CrossAgentCodingHome -NewHome $CliArgs[2]
        Write-Output "migrated: $($result.NewHome)"
        return
    }

    Write-CliHelp
    $script:CliExitCode = 2
}

function Invoke-TuiMode {
    while ($true) {
        Write-Host ""
        Write-Host "CrossAgentCoding TUI MVP"
        Write-Host "1. env tools"
        Write-Host "2. agents scan"
        Write-Host "3. agents configure"
        Write-Host "4. workspace init"
        Write-Host "5. workspace bridge"
        Write-Host "6. config home"
        Write-Host "0. exit"
        $choice = Read-Host "Select"
        switch ($choice) {
            "1" { [void](Invoke-CliMode -CliArgs @("env", "tools")) }
            "2" { [void](Invoke-CliMode -CliArgs @("agents", "scan")) }
            "3" { [void](Invoke-CliMode -CliArgs @("agents", "configure")) }
            "4" {
                $path = Read-Host "Workspace path (blank for current)"
                if ([string]::IsNullOrWhiteSpace($path)) { $path = (Get-Location).Path }
                [void](Invoke-CliMode -CliArgs @("workspace", "init", $path))
            }
            "5" {
                $path = Read-Host "Workspace path (blank for current)"
                if ([string]::IsNullOrWhiteSpace($path)) { $path = (Get-Location).Path }
                [void](Invoke-CliMode -CliArgs @("workspace", "bridge", $path))
            }
            "6" { [void](Invoke-CliMode -CliArgs @("config", "home")) }
            "0" { return 0 }
            default { Write-Host "Unknown choice" }
        }
    }
}

if ($SelfTest) {
    $ErrorActionPreference = "Stop"
    $errors = New-Object System.Collections.Generic.List[string]

    foreach ($lang in @("zh", "en")) {
        foreach ($key in $script:Text.zh.Keys) {
            if (-not $script:Text[$lang].ContainsKey($key)) {
                [void]$errors.Add("Missing text key $lang.$key")
            }
        }
    }

    $status = Get-EnvironmentStatus
    if ($null -eq $status) {
        [void]$errors.Add("Environment status returned null")
    }

    if ((Get-McpConfig) -notmatch "agentmemory") {
        [void]$errors.Add("MCP config missing agentmemory")
    }

    $targets = @(Get-AgentTargetDefinitions)
    foreach ($id in @("codex", "trae-cn", "trae", "claude-code", "claude-desktop", "gemini", "opencode", "openclaw", "hermes")) {
        if (-not ($targets | Where-Object { $_.Id -eq $id })) {
            [void]$errors.Add("Missing target definition: $id")
        }
    }

    if ($targets.Count -lt 9) {
        [void]$errors.Add("Expected at least 9 target definitions")
    }

    $clients = @(Get-AgentClientStatuses)
    foreach ($id in @("codex", "trae-cn", "trae", "claude-code", "claude-desktop", "gemini", "opencode", "openclaw", "hermes")) {
        if (-not ($clients | Where-Object { $_.Id -eq $id })) {
            [void]$errors.Add("Missing client definition: $id")
        }
    }

    $cliCommands = Get-CliConfigCommands
    foreach ($needle in @("claude mcp add-json", "Codex", "TRAE SOLO CN", "TRAE SOLO", "Gemini CLI", "OpenCode", "OpenClaw", "Hermes", "localhost:3111")) {
        if ($cliCommands -notmatch [regex]::Escape($needle)) {
            [void]$errors.Add("CLI commands missing: $needle")
        }
    }

    $ccSwitchFeatures = @(Get-CcSwitchInspiredFeatures)
    if ($ccSwitchFeatures.Count -lt 3) {
        [void]$errors.Add("cc-switch inspired feature list is too small")
    }

    if ((Get-SharedPromptContent) -notmatch "localhost:3111") {
        [void]$errors.Add("Shared prompt missing AgentMemory endpoint")
    }

    # The bounded command lookup must find a real executable and return "" for a
    # missing one without throwing, so startup scans never hang the UI thread.
    if ([string]::IsNullOrWhiteSpace((Get-CommandPathSafe -Name "powershell$($script:ExeExt)"))) {
        [void]$errors.Add("Get-CommandPathSafe failed to resolve a known executable")
    }
    if ((Get-CommandPathSafe -Name "cac-definitely-missing-cmd-xyz.exe") -ne "") {
        [void]$errors.Add("Get-CommandPathSafe should return empty for a missing command")
    }

    Write-Output "SELFTEST_STAGE startup-diagnostics"
    $startupLog = Join-Path $script:TempDir ("cac-startup-log-" + [guid]::NewGuid().ToString("N") + ".log")
    try {
        $esc = [char]27
        Set-Content -LiteralPath $startupLog -Encoding UTF8 -Value @(
            ($esc.ToString() + "[?25l|"),
            "Error: failed to initialize worker 'iii-http': failed to bind to 127.0.0.1:3111",
            "|",
            "Common causes:",
            "  - Port already in use (see below)"
        )
        $cleanLine = Get-CleanLogLine ($esc.ToString() + "[?25lError: failed to bind to 127.0.0.1:3111")
        if ($cleanLine -match [regex]::Escape([string]$esc) -or $cleanLine -notmatch "failed to bind") {
            [void]$errors.Add("Startup log cleaner did not remove control sequences")
        }

        $detail = Get-ServiceStartupFailureDetail -ServiceLog $startupLog -TimeoutSeconds 60
        if ($detail -notmatch "failed to bind to 127.0.0.1:3111" -or $detail -notmatch "Port already in use") {
            [void]$errors.Add("Startup failure detail did not surface bind failure")
        }
    } finally {
        Remove-Item -LiteralPath $startupLog -Force -ErrorAction SilentlyContinue
    }
    Write-Output "SELFTEST_STAGE startup-diagnostics-done"

    # Placeholder cards must cover every target without scanning so the window can
    # render instantly before status is populated.
    $placeholderCards = @(Get-PlaceholderToolCards)
    if ($placeholderCards.Count -ne (@(Get-AgentTargetDefinitions)).Count) {
        [void]$errors.Add("Placeholder tool cards do not match target definitions")
    }

    # Install detection must not treat the manager's own config writes as proof of
    # installation: a directory holding only the config file (and its backups) is
    # "configured but not installed"; a real install adds other content.
    $detectRoot = Join-Path $script:TempDir ("cac-install-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $detectRoot -Force | Out-Null
    try {
        $detectCfg = Join-Path $detectRoot "settings.json"
        Set-Content -LiteralPath $detectCfg -Value "{}" -Encoding UTF8
        $flatTarget = [pscustomobject]@{ InstallRoot = $detectRoot; ConfigPath = $detectCfg }
        if (Test-AgentInstallPresent -Target $flatTarget -CommandInfo $null) {
            [void]$errors.Add("Config-only directory wrongly detected as installed")
        }
        Set-Content -LiteralPath ($detectCfg + ".bak-20260101000000") -Value "{}" -Encoding UTF8
        if (Test-AgentInstallPresent -Target $flatTarget -CommandInfo $null) {
            [void]$errors.Add("Config+backup directory wrongly detected as installed")
        }
        if (-not (Test-AgentInstallPresent -Target $flatTarget -CommandInfo ([pscustomobject]@{ Source = "x" }))) {
            [void]$errors.Add("Resolvable CLI should count as installed")
        }
        New-Item -ItemType Directory -Path (Join-Path $detectRoot "cache") -Force | Out-Null
        if (-not (Test-AgentInstallPresent -Target $flatTarget -CommandInfo $null)) {
            [void]$errors.Add("Real install (extra subdirectory) not detected")
        }

        # Nested config (TRAE-style User\mcp.json): the managed sub-folder alone is
        # not an install, but other content inside it is.
        $nestedRoot = Join-Path $detectRoot "nested"
        $nestedUser = Join-Path $nestedRoot "User"
        New-Item -ItemType Directory -Path $nestedUser -Force | Out-Null
        $nestedCfg = Join-Path $nestedUser "mcp.json"
        Set-Content -LiteralPath $nestedCfg -Value "{}" -Encoding UTF8
        $nestedTarget = [pscustomobject]@{ InstallRoot = $nestedRoot; ConfigPath = $nestedCfg }
        if (Test-AgentInstallPresent -Target $nestedTarget -CommandInfo $null) {
            [void]$errors.Add("Manager-created nested config wrongly detected as installed")
        }
        Set-Content -LiteralPath (Join-Path $nestedUser "settings.json") -Value "{}" -Encoding UTF8
        if (-not (Test-AgentInstallPresent -Target $nestedTarget -CommandInfo $null)) {
            [void]$errors.Add("Real content inside nested config folder not detected")
        }
    } finally {
        Remove-Item -LiteralPath $detectRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Codex config path must follow CODEX_HOME when it points to an existing
    # directory. The write-test path forces the default location, so this branch
    # is only meaningful outside write-test mode.
    if ($env:AM_MANAGER_WRITE_TEST -ne "1") {
        $codexHomeDir = Join-Path $script:TempDir ("cac-codexhome-" + [guid]::NewGuid().ToString("N"))
        New-Item -ItemType Directory -Path $codexHomeDir -Force | Out-Null
        $oldCodexHome = $env:CODEX_HOME
        try {
            $env:CODEX_HOME = $codexHomeDir
            if ((Get-CodexConfigPath) -ne (Join-Path $codexHomeDir "config.toml")) {
                [void]$errors.Add("Codex config path did not follow CODEX_HOME")
            }
        } finally {
            $env:CODEX_HOME = $oldCodexHome
            Remove-Item -LiteralPath $codexHomeDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    if ($env:AM_MANAGER_WRITE_TEST -eq "1") {
        $paths = @(Configure-AllAgentClients)
        if ($paths.Count -lt 8) {
            [void]$errors.Add("Expected at least 8 config paths from Configure-AllAgentClients")
        }
        foreach ($path in $paths) {
            if (-not (Test-Path -LiteralPath $path)) {
                [void]$errors.Add("Config writer did not create: $path")
            } else {
                $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
                if (-not (Test-AgentMemoryTextConfigured $text)) {
                    [void]$errors.Add("Config writer missing AgentMemory settings: $path")
                }
            }
        }

        $sharedPaths = @(Sync-SharedAgentFiles)
        if ($sharedPaths.Count -ne 7) {
            [void]$errors.Add("Expected 7 shared agent files")
        }
        foreach ($path in $sharedPaths) {
            if (-not (Test-Path -LiteralPath $path)) {
                [void]$errors.Add("Shared file writer did not create: $path")
            }
        }

        $projectDir = Join-Path $script:HomeDir "sample-project"
        New-Item -ItemType Directory -Path $projectDir -Force | Out-Null
        $workspaceA = Initialize-WorkspaceMemory -ProjectPath $projectDir
        $workspaceB = Initialize-WorkspaceMemory -ProjectPath $projectDir
        if ($workspaceA.Id -ne $workspaceB.Id) {
            [void]$errors.Add("Workspace ID is not stable")
        }
        if (-not (Test-Path -LiteralPath (Join-Path $workspaceA.WorkspacePath "workspace.json"))) {
            [void]$errors.Add("Workspace metadata missing")
        }

        # When a Git remote is present, it must contribute to the workspace
        # identity so different repositories at the same path stay distinct.
        if (Get-Command git -ErrorAction SilentlyContinue) {
            $gitProject = Join-Path $script:HomeDir "git-sample-project"
            New-Item -ItemType Directory -Path $gitProject -Force | Out-Null
            & git -C $gitProject init --quiet 2>$null | Out-Null
            $idBeforeRemote = Get-WorkspaceId -ProjectPath $gitProject
            & git -C $gitProject remote add origin "https://example.com/CrossAgentCoding.git" 2>$null | Out-Null
            $idAfterRemote = Get-WorkspaceId -ProjectPath $gitProject
            if ($idBeforeRemote -eq $idAfterRemote) {
                [void]$errors.Add("Workspace ID did not incorporate Git remote")
            }
            if ((Get-WorkspaceId -ProjectPath $gitProject) -ne $idAfterRemote) {
                [void]$errors.Add("Workspace ID with Git remote is not stable")
            }
        }

        $bridgePath = Add-SessionBridgeEntry -ProjectPath $projectDir -Tool "Codex" -Summary "Implemented parser and ran tests." -SourcePath "codex-session.jsonl"
        if (-not (Test-Path -LiteralPath $bridgePath)) {
            [void]$errors.Add("Session bridge file missing")
        }
        $handoffPath = Join-Path $workspaceA.WorkspacePath "handoff.md"
        if (-not ((Get-Content -LiteralPath $handoffPath -Raw -Encoding UTF8) -match "Implemented parser")) {
            [void]$errors.Add("Handoff summary missing bridge text")
        }

        $codexSessionDir = [System.IO.Path]::Combine((Split-Path -Parent (Get-CodexConfigPath)), "sessions", "2026")
        New-Item -ItemType Directory -Path $codexSessionDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $codexSessionDir "sample.jsonl") -Value '{"message":"Codex worked on routing"}' -Encoding UTF8
        [void](Import-CodexSessionBridge -ProjectPath $projectDir)

        $traeLogDir = [System.IO.Path]::Combine($script:AppDataDir, "TRAE SOLO CN", "logs")
        New-Item -ItemType Directory -Path $traeLogDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $traeLogDir "sample.log") -Value "TRAE completed UI review" -Encoding UTF8
        [void](Import-TraeSessionBridge -ProjectPath $projectDir)

        $sessionLines = @(Get-Content -LiteralPath $bridgePath -Encoding UTF8)
        if ($sessionLines.Count -lt 3) {
            [void]$errors.Add("Expected bridge entries from manual, Codex, and TRAE imports")
        }

        $oldHome = Get-CrossAgentCodingHome
        $markerPath = Join-Path $oldHome "migration-marker.txt"
        if (-not (Test-Path -LiteralPath $oldHome)) {
            New-Item -ItemType Directory -Path $oldHome -Force | Out-Null
        }
        Set-Content -LiteralPath $markerPath -Value "keep me" -Encoding UTF8
        $newHome = Join-Path $script:TempDir ("CrossAgentCoding-home-" + [guid]::NewGuid().ToString("N"))
        $migration = Move-CrossAgentCodingHome -NewHome $newHome
        if ((Get-CrossAgentCodingHome) -ne $migration.NewHome) {
            [void]$errors.Add("CrossAgentCoding home did not switch after migration")
        }
        if (-not (Test-Path -LiteralPath (Join-Path $newHome "migration-marker.txt"))) {
            [void]$errors.Add("Migration did not copy existing data")
        }
    }

    if ($errors.Count -gt 0) {
        $errors | ForEach-Object { Write-Error $_ }
        exit 1
    }

    Write-Output "SELFTEST OK"
    exit 0
}

if ($Cli) {
    $effectiveCommandArgs = @($CommandArgs)
    if ($effectiveCommandArgs.Count -eq 0 -and $MyInvocation.UnboundArguments.Count -gt 0) {
        $effectiveCommandArgs = @($MyInvocation.UnboundArguments)
    }
    if ($effectiveCommandArgs.Count -gt 0 -and $effectiveCommandArgs[0] -match "^-Cli$") {
        $effectiveCommandArgs = @($effectiveCommandArgs | Select-Object -Skip 1)
    }
    if ($effectiveCommandArgs.Count -eq 0) {
        $effectiveCommandArgs = @(Get-CliArgsFromInvocationLine -Line $MyInvocation.Line)
    }
    Invoke-CliMode -CliArgs $effectiveCommandArgs
    exit $script:CliExitCode
}

if ($Tui) {
    exit (Invoke-TuiMode)
}

function Write-Log {
    param([string]$Message)

    $ts = Get-Date -Format "HH:mm:ss"
    if ($script:LogBox) {
        $script:LogBox.AppendText("[$ts] $Message`r`n")
        $script:LogBox.SelectionStart = $script:LogBox.TextLength
        $script:LogBox.ScrollToCaret()
    } else {
        Write-Host "[$ts] $Message"
    }
}

function Set-ActionFeedback {
    param(
        [string]$Message,
        [System.Drawing.Color]$Color = [System.Drawing.Color]::Black
    )

    if ($script:ActionLabel) {
        $script:ActionLabel.Text = $Message
        $script:ActionLabel.ForeColor = $Color
        [System.Windows.Forms.Application]::DoEvents()
    } else {
        Write-Host $Message
    }
}

function Set-Busy {
    param([bool]$Busy)

    $script:IsBusy = $Busy
    if ($script:BtnInstall) {
        $script:BtnInstall.Enabled = -not $Busy
        $script:BtnStartStop.Enabled = -not $Busy
        $script:BtnMcp.Enabled = -not $Busy
        $script:BtnViewer.Enabled = -not $Busy
        $script:BtnMemorySettings.Enabled = -not $Busy
        $script:BtnCheckUpdate.Enabled = -not $Busy
        $script:BtnCheckStatus.Enabled = -not $Busy
        $script:BtnScanAgents.Enabled = -not $Busy
        $script:BtnConfigureAgents.Enabled = -not $Busy
        $script:BtnCopyCli.Enabled = -not $Busy
        $script:BtnSyncShared.Enabled = -not $Busy
        $script:BtnWorkspaceBridge.Enabled = -not $Busy
        $script:BtnMigrateHome.Enabled = -not $Busy
        $script:LanguageBox.Enabled = -not $Busy
        [System.Windows.Forms.Application]::DoEvents()
    }
}

function Apply-Language {
    $script:Form.Text = T "WindowTitle"
    $script:ProductNameLabel.Text = "CrossAgentCoding"
    $script:ProductVersionLabel.Text = "Version $script:APP_VERSION"
    $script:LocalEnvLabel.Text = T "LocalEnvCheck"
    $script:ActionGroup.Text = T "LastAction"
    $script:BtnInstall.Text = T "InstallAll"
    if (Test-ServiceRunning) {
        $script:BtnStartStop.Text = T "StopService"
    } else {
        $script:BtnStartStop.Text = T "StartService"
    }
    $script:BtnMcp.Text = T "CopyMcp"
    $script:BtnViewer.Text = T "OpenViewer"
    $script:BtnMemorySettings.Text = T "MemorySettings"
    $script:BtnCheckUpdate.Text = T "CheckUpdate"
    $script:BtnCheckStatus.Text = T "CheckStatus"
    $script:BtnScanAgents.Text = T "ScanAgents"
    $script:BtnConfigureAgents.Text = T "ConfigureAll"
    $script:BtnCopyCli.Text = T "CopyCli"
    $script:BtnSyncShared.Text = T "SyncSharedFiles"
    $script:BtnWorkspaceBridge.Text = T "BridgeWorkspace"
    $script:BtnMigrateHome.Text = T "StorageSettings"
    $script:LogGroup.Text = T "Log"
    Update-DataPathLabel
}

function Update-DataPathLabel {
    if ($null -eq $script:DataPathLabel) {
        return
    }

    $dataHome = Get-CrossAgentCodingHome
    $line1 = T "DataPathInfo" @($dataHome, (Get-ServiceWorkDir))
    $line2 = (T "ModelCacheLabel" @((Get-ModelCacheDir))) + "      " + (T "PortsInfo" @($script:PORT, $script:STREAMS_PORT, $script:VIEWER_PORT))
    $script:DataPathLabel.Text = $line1 + "`r`n" + $line2
}

function Update-Status {
    if (-not $script:StatusLabel -and -not $script:NodeLabel) { return }
    $status = Get-EnvironmentStatus

    if ($status.Node) {
        $script:NodeLabel.Text = T "NodeInstalled" @($status.NodeVersion)
        $script:NodeLabel.ForeColor = [System.Drawing.Color]::DarkGreen
    } else {
        $script:NodeLabel.Text = T "NodeMissing"
        $script:NodeLabel.ForeColor = [System.Drawing.Color]::Red
    }

    if ($status.AgentMemory) {
        $amVersion = if ($status.AgentMemoryVersion) { "v" + $status.AgentMemoryVersion } else { "" }
        $script:AgentMemoryLabel.Text = (T "AgentMemoryInstalled" @($amVersion)).TrimEnd()
        $script:AgentMemoryLabel.ForeColor = [System.Drawing.Color]::DarkGreen
    } else {
        $script:AgentMemoryLabel.Text = T "AgentMemoryMissing"
        $script:AgentMemoryLabel.ForeColor = [System.Drawing.Color]::Red
    }

    if ($status.Iii) {
        $script:IiiLabel.Text = T "IiiInstalled"
        $script:IiiLabel.ForeColor = [System.Drawing.Color]::DarkGreen
    } else {
        $script:IiiLabel.Text = T "IiiMissing"
        $script:IiiLabel.ForeColor = [System.Drawing.Color]::Red
    }

    if ($status.Service) {
        $script:ServiceLabel.Text = T "Running" @($script:PORT)
        $script:ServiceLabel.ForeColor = [System.Drawing.Color]::DarkGreen
    } else {
        $script:ServiceLabel.Text = T "NotRunning"
        $script:ServiceLabel.ForeColor = [System.Drawing.Color]::Red
    }

    Update-DataPathLabel

    if ($null -ne $script:BtnStartStop) {
        if ($status.Service) {
            # Service is up: the button now stops it (red accent).
            $script:BtnStartStop.Text = T "StopService"
            $script:BtnStartStop.BackColor = [System.Drawing.Color]::White
            $script:BtnStartStop.ForeColor = [System.Drawing.Color]::FromArgb(220, 38, 38)
        } else {
            # Service is down: the button starts it (primary blue).
            $script:BtnStartStop.Text = T "StartService"
            $script:BtnStartStop.BackColor = [System.Drawing.Color]::FromArgb(24, 144, 255)
            $script:BtnStartStop.ForeColor = [System.Drawing.Color]::White
        }
    }

    [System.Windows.Forms.Application]::DoEvents()
}

function Get-AgentStatusDisplayText {
    param([object]$Client)

    if ($Client.Installed -and $Client.Configured) {
        return T "AgentInstalledConfigured" @($Client.Name)
    }
    if ($Client.Installed -and -not $Client.Configured) {
        return T "AgentInstalledNotConfigured" @($Client.Name)
    }
    if (-not $Client.Installed -and $Client.Configured) {
        return T "AgentMissingConfigured" @($Client.Name)
    }
    return T "AgentMissingNotConfigured" @($Client.Name)
}

function Update-AgentClientStatus {
    if (-not $script:AgentStatusLabel -and ($null -eq $script:ToolCardControls -or $script:ToolCardControls.Count -eq 0)) { return }
    if ($null -ne $script:ToolCardControls -and $script:ToolCardControls.Count -gt 0) {
        Update-ToolCardControls
        return
    }

    $clients = @(Get-AgentClientStatuses)
    for ($i = 0; $i -lt $script:AgentLabels.Count; $i++) {
        $client = $clients[$i]
        $label = $script:AgentLabels[$i]
        $label.Text = Get-AgentStatusDisplayText -Client $client
        if ($client.Configured) {
            $label.ForeColor = [System.Drawing.Color]::DarkGreen
        } elseif ($client.Installed) {
            $label.ForeColor = [System.Drawing.Color]::DarkOrange
        } else {
            $label.ForeColor = [System.Drawing.Color]::Red
        }
    }

    [System.Windows.Forms.Application]::DoEvents()
}

function Install-All {
    Set-Busy $true
    Set-ActionFeedback (T "Installing") ([System.Drawing.Color]::DarkOrange)
    Write-Log (T "InstallStart")
    Set-ManagerEnv

    try {
        if ((Get-NodeVersion).Length -gt 0) {
            Write-Log (T "AlreadyInstalled" @("Node.js"))
        } else {
            if ($script:IsWindows) {
                try {
                    Write-Log "Downloading Node.js..."
                    $msi = Join-Path $script:TempDir "agentmemory-node.msi"
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                    Invoke-WebRequest -Uri "https://nodejs.org/dist/v20.11.0/node-v20.11.0-x64.msi" -OutFile $msi -UseBasicParsing
                    Invoke-HiddenProcess -FilePath "msiexec.exe" -Arguments "/i `"$msi`" /quiet /norestart" -Wait -TimeoutSeconds 900
                    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
                    # Clear version cache so Update-Status reflects the new installation immediately
                    $script:NodeVersionCache = ""
                    $script:NodeVersionCacheTime = [datetime]::MinValue
                    $script:NodeVersionFailureTime = [datetime]::MinValue
                    Write-Log (T "InstallOk" @("Node.js"))
                } catch {
                    Write-Log (T "InstallFail" @("Node.js", $_.Exception.Message))
                }
            } elseif ($script:IsMacOS) {
                Write-Log "Node.js not found. Please install it via: brew install node@20"
                Write-Log "Or download from: https://nodejs.org/"
            } else {
                Write-Log "Node.js not found. Please install it via your package manager."
                Write-Log "e.g. sudo apt install nodejs  or  sudo dnf install nodejs"
            }
        }
        Update-Status
        [System.Windows.Forms.Application]::DoEvents()

        $agentMemoryCmd = Join-Path $script:NPM_GLOBAL "agentmemory$($script:CmdExt)"
        if (Test-Path -LiteralPath $agentMemoryCmd) {
            Write-Log (T "AlreadyInstalled" @("AgentMemory"))
        } elseif ((Get-NodeVersion).Length -eq 0) {
            Write-Log (T "MissingInstallFirst" @("Node.js"))
        } else {
            try {
                Write-Log "Installing AgentMemory..."
                $result = Invoke-HiddenProcess -FilePath $script:ShellCmd -Arguments "$($script:ShellArgs) npm install -g @agentmemory/agentmemory" -Wait -TimeoutSeconds 900
                if ($result.ExitCode -eq 0 -and (Test-Path -LiteralPath $agentMemoryCmd)) {
                    Write-Log (T "InstallOk" @("AgentMemory"))
                } else {
                    $detail = if ($result.Error) { $result.Error.Trim() } else { "exit $($result.ExitCode)" }
                    Write-Log (T "InstallFail" @("AgentMemory", $detail))
                }
            } catch {
                Write-Log (T "InstallFail" @("AgentMemory", $_.Exception.Message))
            }
        }
        Update-Status
        [System.Windows.Forms.Application]::DoEvents()

        $iiiInAgentMemory = [System.IO.Path]::Combine($script:AM_DIR, "bin", "iii$($script:ExeExt)")
        $iiiInLocal = [System.IO.Path]::Combine($script:LOCAL_BIN, "iii$($script:ExeExt)")
        $iiiPath = if (Test-Path -LiteralPath $iiiInAgentMemory) { $iiiInAgentMemory } elseif (Test-Path -LiteralPath $iiiInLocal) { $iiiInLocal } else { $null }
        $iiiOk = $false
        if ($iiiPath) {
            try {
                $iiiVer = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($iiiPath).ProductVersion
                if ($iiiVer -and $iiiVer.Trim() -eq $script:III_VERSION) {
                    $iiiOk = $true
                }
            } catch {}
        }
        if ($iiiOk) {
            Write-Log (T "AlreadyInstalled" @("iii-engine"))
        } else {
            if ($iiiPath) {
                Write-Log "iii-engine version mismatch (need $script:III_VERSION), reinstalling..."
                Remove-Item -LiteralPath $iiiInAgentMemory -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $iiiInLocal -Force -ErrorAction SilentlyContinue
            }
            try {
                Write-Log "Downloading iii-engine $script:III_VERSION..."
                New-Item -ItemType Directory -Path (Join-Path $script:AM_DIR "bin") -Force | Out-Null
                New-Item -ItemType Directory -Path $script:LOCAL_BIN -Force | Out-Null

                $zip = Join-Path $script:TempDir "agentmemory-iii.zip"
                $extractDir = Join-Path $script:TempDir "agentmemory-iii"
                if (Test-Path -LiteralPath $extractDir) {
                    Remove-Item -LiteralPath $extractDir -Recurse -Force
                }

                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $iiiTarget = if ($script:IsWindows) {
                    if ($script:IsArm64) { "aarch64-pc-windows-msvc" } else { "x86_64-pc-windows-msvc" }
                } elseif ($script:IsMacOS) {
                    if ($script:IsArm64) { "aarch64-apple-darwin" } else { "x86_64-apple-darwin" }
                } else {
                    if ($script:IsArm64) { "aarch64-unknown-linux-gnu" } else { "x86_64-unknown-linux-gnu" }
                }
                $iiiUrl = "https://github.com/iii-hq/iii/releases/download/iii/$script:III_VERSION/iii-$iiiTarget.zip"
                Invoke-WebRequest -Uri $iiiUrl -OutFile $zip -UseBasicParsing
                Expand-Archive -Path $zip -DestinationPath $extractDir -Force

                $found = Get-ChildItem -LiteralPath $extractDir -Recurse -Filter "iii$($script:ExeExt)" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($found) {
                    Copy-Item -LiteralPath $found.FullName -Destination $iiiInLocal -Force
                    Copy-Item -LiteralPath $found.FullName -Destination $iiiInAgentMemory -Force
                }

                Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $extractDir -Recurse -Force -ErrorAction SilentlyContinue

                if ((Test-Path -LiteralPath $iiiInAgentMemory) -or (Test-Path -LiteralPath $iiiInLocal)) {
                    Write-Log (T "InstallOk" @("iii-engine"))
                } else {
                    Write-Log (T "InstallFail" @("iii-engine", "iii$($script:ExeExt) not found"))
                }
            } catch {
                Write-Log (T "InstallFail" @("iii-engine", $_.Exception.Message))
            }
        }
        Update-Status
        [System.Windows.Forms.Application]::DoEvents()

        Write-Log (T "InstallDone")
        Set-ActionFeedback (T "InstallDone") ([System.Drawing.Color]::DarkGreen)
        Update-Status
        [System.Windows.Forms.MessageBox]::Show((T "InstallDoneBody"), (T "InstallDoneTitle"), "OK", "Information") | Out-Null
    } finally {
        Set-Busy $false
    }
}

function Start-AgentMemory {
    Set-Busy $true
    Set-ActionFeedback (T "Starting") ([System.Drawing.Color]::DarkOrange)

    try {
        $restListeners = @(Get-ServicePortConflicts -Ports @($script:PORT))
        if ($restListeners.Count -gt 0 -and (@($restListeners | Where-Object { $_.LooksLikeAgentMemory }).Count -gt 0)) {
            Update-Status
            Set-ActionFeedback (T "Running" @($script:PORT)) ([System.Drawing.Color]::DarkGreen)
            [System.Windows.Forms.MessageBox]::Show((T "StartAlreadyBody" @($script:PORT)), (T "StartAlreadyTitle"), "OK", "Information") | Out-Null
            return
        } elseif ($restListeners.Count -gt 0) {
            Show-ServicePortConflicts -Conflicts $restListeners
            return
        }

        $missing = @(Get-MissingDependencyNames)
        if ($missing.Count -gt 0) {
            $missingText = $missing -join ", "
            Set-ActionFeedback (T "MissingInstallFirst" @($missingText)) ([System.Drawing.Color]::Red)
            $choice = [System.Windows.Forms.MessageBox]::Show((T "StartMissingBody" @($missingText)), (T "StartMissingTitle"), "YesNo", "Warning")
            if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
                Set-Busy $false
                Install-All
                Set-Busy $true
                $missing = @(Get-MissingDependencyNames)
                if ($missing.Count -gt 0) {
                    Set-ActionFeedback (T "MissingInstallFirst" @(($missing -join ", "))) ([System.Drawing.Color]::Red)
                    return
                }
            } else {
                return
            }
        }

        Set-ManagerEnv
        Apply-MemoryEnv

        # Clear stale AgentMemory/iii processes first. A zombie engine still
        # holding 3112 / 49134 (after a crash or closing the window without
        # stopping) is the usual cause of "did not start within 60s". We only
        # reach here when 3111 has no healthy AgentMemory listener, so killing
        # leftover AgentMemory/iii processes is safe.
        $cleaned = Stop-AgentMemoryProcesses
        if ($cleaned -gt 0) {
            Write-Log (T "StaleCleaned" @($cleaned))
            Start-Sleep -Seconds 2
        }

        # Abort only when a NON-AgentMemory process still holds a required port.
        $portConflicts = @(Get-ServicePortConflicts -Ports @($script:STREAMS_PORT, $script:VIEWER_PORT) | Where-Object { -not $_.LooksLikeAgentMemory })
        if ($portConflicts.Count -gt 0) {
            Show-ServicePortConflicts -Conflicts $portConflicts
            return
        }

        # The service writes its iii data store to ./data relative to its working
        # directory, so run it inside the configurable storage dir (keeps the
        # growing state_store/stream_store off the launch folder and on whatever
        # drive the user picked).
        $workDir = Get-ServiceWorkDir
        New-Item -ItemType Directory -Path $workDir -Force | Out-Null
        New-Item -ItemType Directory -Path (Get-ModelCacheDir) -Force | Out-Null
        foreach ($dir in @($script:AM_DIR, $workDir)) {
            Remove-Item -LiteralPath (Join-Path $dir "iii.pid") -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath (Join-Path $dir "engine-state.json") -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath (Join-Path $dir "worker.pid") -Force -ErrorAction SilentlyContinue
        }

        $agentMemoryCmd = Join-Path $script:NPM_GLOBAL "agentmemory$($script:CmdExt)"
        $serviceLog = Get-ServiceLogPath
        Remove-Item -LiteralPath $serviceLog -Force -ErrorAction SilentlyContinue

        Write-Log (T "StartRequested")
        Write-Log (T "ServiceLog" @($serviceLog))

        $cmdLine = "$($script:ShellArgs) `"`"$agentMemoryCmd`" > `"$serviceLog`" 2>&1`""
        Invoke-HiddenProcess -FilePath $script:ShellCmd -Arguments $cmdLine -WorkingDirectory $workDir | Out-Null

        $timeout = 60
        $started = $false
        for ($elapsed = 0; $elapsed -lt $timeout; $elapsed += 3) {
            Start-Sleep -Seconds 3
            if (Test-ServiceRunning) {
                $started = $true
                break
            }
            Write-Log (T "Waiting" @(($elapsed + 3)))
        }

        if ($started) {
            Update-Status
            Set-ActionFeedback (T "Running" @($script:PORT)) ([System.Drawing.Color]::DarkGreen)
            Write-Log (T "StartOkBody" @($script:PORT))
            [System.Windows.Forms.MessageBox]::Show((T "StartOkBody" @($script:PORT)), (T "StartOkTitle"), "OK", "Information") | Out-Null
        } else {
            Update-Status
            Set-ActionFeedback (T "StartFailTitle") ([System.Drawing.Color]::Red)
            Write-Log (T "StartFailBody" @($timeout))
            $detail = Get-ServiceStartupFailureDetail -ServiceLog $serviceLog -TimeoutSeconds $timeout
            if (-not [string]::IsNullOrWhiteSpace($detail)) {
                foreach ($line in ($detail -split "`r?`n")) {
                    if ($line) { Write-Log $line }
                }
            }
            $message = T "StartFailBody" @($timeout)
            if (-not [string]::IsNullOrWhiteSpace($detail)) {
                $message = $message + "`r`n`r`n" + $detail
            }
            [System.Windows.Forms.MessageBox]::Show($message, (T "StartFailTitle"), "OK", "Error") | Out-Null
        }
    } finally {
        Set-Busy $false
    }
}

function Stop-AgentMemory {
    Set-Busy $true
    Set-ActionFeedback (T "Stopping") ([System.Drawing.Color]::DarkOrange)

    try {
        Write-Log (T "StopRequested")
        $killed = Stop-AgentMemoryProcesses
        $stoppedAny = ($killed -gt 0)

        foreach ($dir in @($script:AM_DIR, (Get-ServiceWorkDir))) {
            Remove-Item -LiteralPath (Join-Path $dir "iii.pid") -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath (Join-Path $dir "engine-state.json") -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath (Join-Path $dir "worker.pid") -Force -ErrorAction SilentlyContinue
        }

        Start-Sleep -Seconds 1
        Update-Status

        if ($stoppedAny) {
            Set-ActionFeedback (T "StopOkBody") ([System.Drawing.Color]::DarkGreen)
            Write-Log (T "StopOkBody")
            [System.Windows.Forms.MessageBox]::Show((T "StopOkBody"), (T "StopOkTitle"), "OK", "Information") | Out-Null
        } else {
            Set-ActionFeedback (T "StopNothingBody") ([System.Drawing.Color]::DarkOrange)
            Write-Log (T "StopNothingBody")
            [System.Windows.Forms.MessageBox]::Show((T "StopNothingBody"), (T "StopNothingTitle"), "OK", "Information") | Out-Null
        }
    } finally {
        Set-Busy $false
    }
}

function Stop-AgentMemoryProcesses {
    # Kill stale AgentMemory / iii-engine / worker processes so a clean (re)start
    # is not blocked by a zombie still holding the engine (49134) or stream ports.
    # NOTE: uses $procId, never $pid (that is an automatic variable in PowerShell).
    $targets = New-Object System.Collections.Generic.List[int]

    foreach ($conflict in @(Get-ServicePortConflicts -Ports @($script:PORT, $script:STREAMS_PORT, $script:VIEWER_PORT, 49134))) {
        if ($conflict.LooksLikeAgentMemory -and [int]$conflict.ProcessId -gt 0) {
            [void]$targets.Add([int]$conflict.ProcessId)
        }
    }
    foreach ($proc in @(Get-Process -Name "iii" -ErrorAction SilentlyContinue)) {
        [void]$targets.Add([int]$proc.Id)
    }
    foreach ($proc in @(Get-Process -Name "node" -ErrorAction SilentlyContinue)) {
        $cl = Get-ProcessCommandLineById -ProcessId ([int]$proc.Id)
        if ($cl -match "agentmemory") {
            [void]$targets.Add([int]$proc.Id)
        }
    }

    $killed = 0
    foreach ($procId in (@($targets) | Select-Object -Unique)) {
        try {
            Stop-Process -Id $procId -Force -ErrorAction Stop
            $killed++
        } catch {
        }
    }
    return $killed
}

function Check-AgentMemoryUpdate {
    if (-not (Test-Path -LiteralPath (Join-Path $script:NPM_GLOBAL "agentmemory$($script:CmdExt)"))) {
        Set-ActionFeedback (T "AgentMemoryNotInstalled") ([System.Drawing.Color]::DarkOrange)
        Write-Log (T "AgentMemoryNotInstalled")
        return
    }

    Set-Busy $true
    Set-ActionFeedback (T "UpdateChecking") ([System.Drawing.Color]::DarkOrange)
    Write-Log (T "UpdateChecking")
    try {
        $current = Get-AgentMemoryVersion
        $latest = Get-AgentMemoryLatestVersion
        if ([string]::IsNullOrWhiteSpace($latest)) {
            Set-ActionFeedback (T "UpdateCheckFail") ([System.Drawing.Color]::Red)
            Write-Log (T "UpdateCheckFail")
            return
        }

        Write-Log ("AgentMemory current=v$current latest=v$latest")
        if ((Compare-SemVer -A $latest -B $current) -le 0) {
            Set-ActionFeedback (T "UpdateLatest" @($current)) ([System.Drawing.Color]::DarkGreen)
            Write-Log (T "UpdateLatest" @($current))
            return
        }

        $choice = [System.Windows.Forms.MessageBox]::Show((T "UpdateAvailableBody" @($latest, $current)), (T "UpdateAvailableTitle"), "YesNo", "Question")
        if ($choice -ne [System.Windows.Forms.DialogResult]::Yes) {
            return
        }

        Set-ActionFeedback (T "Updating" @($latest)) ([System.Drawing.Color]::DarkOrange)
        Write-Log (T "Updating" @($latest))
        $result = Invoke-HiddenProcess -FilePath $script:ShellCmd -Arguments "$($script:ShellArgs) npm install -g @agentmemory/agentmemory@latest" -Wait -TimeoutSeconds 900
        $new = Get-AgentMemoryVersion
        if ($result.ExitCode -eq 0 -and (Compare-SemVer -A $new -B $current) -gt 0) {
            Update-Status
            Set-ActionFeedback (T "UpdateOk" @($new)) ([System.Drawing.Color]::DarkGreen)
            Write-Log (T "UpdateOk" @($new))
            [System.Windows.Forms.MessageBox]::Show((T "UpdateOk" @($new)), (T "UpdateAvailableTitle"), "OK", "Information") | Out-Null
        } else {
            $detail = if ($result.Error) { $result.Error.Trim() } else { "exit $($result.ExitCode)" }
            Set-ActionFeedback (T "UpdateFail" @($detail)) ([System.Drawing.Color]::Red)
            Write-Log (T "UpdateFail" @($detail))
        }
    } catch {
        Set-ActionFeedback (T "UpdateFail" @($_.Exception.Message)) ([System.Drawing.Color]::Red)
        Write-Log (T "UpdateFail" @($_.Exception.Message))
    } finally {
        Set-Busy $false
    }
}

function Copy-McpConfig {
    if ($script:IsWindows) {
        [System.Windows.Forms.Clipboard]::SetText((Get-McpConfig))
    } else {
        $json = Get-McpConfig
        if (Get-Command pbcopy -ErrorAction SilentlyContinue) { $json | pbcopy }
        elseif (Get-Command xclip -ErrorAction SilentlyContinue) { $json | xclip -selection clipboard }
        else { Write-Log "Clipboard not available; config printed above" }
    }
    Set-ActionFeedback (T "CopyOkBody") ([System.Drawing.Color]::DarkGreen)
    Write-Log (T "CopyOkBody")
    [System.Windows.Forms.MessageBox]::Show((T "CopyOkBody"), (T "CopyOkTitle"), "OK", "Information") | Out-Null
}

function Open-MemoryViewer {
    # The AgentMemory service serves a web viewer at REST port + 2 (3113). It is
    # the visual way to browse/inspect the shared memory all agents read & write.
    if (-not (Test-ServiceRunning)) {
        Set-ActionFeedback (T "ViewerNotRunning") ([System.Drawing.Color]::DarkOrange)
        Write-Log (T "ViewerNotRunning")
        return
    }

    $url = "http://localhost:$script:VIEWER_PORT"
    if ($script:IsWindows) { Start-Process $url } elseif ($script:IsMacOS) { Start-Process "open" -ArgumentList $url } else { Start-Process "xdg-open" -ArgumentList $url }
    Write-Log "Viewer: $url"
    Set-ActionFeedback ("Viewer: $url") ([System.Drawing.Color]::DarkGreen)
}

function Show-MemoryStatus {
    if (-not (Test-ServiceRunning)) {
        Set-ActionFeedback (T "StatusServiceDown") ([System.Drawing.Color]::DarkOrange)
        Write-Log (T "StatusServiceDown")
        return
    }

    Set-Busy $true
    Set-ActionFeedback (T "StatusRequested") ([System.Drawing.Color]::DarkOrange)
    Write-Log (T "StatusRequested")
    try {
        Set-ManagerEnv
        $cli = Get-AgentMemoryCliPath
        $result = Invoke-HiddenProcess -FilePath $script:ShellCmd -Arguments ("$($script:ShellArgs) `"`"" + $cli + "`" status`"") -Wait -TimeoutSeconds 60
        $text = [string]$result.Output + "`n" + [string]$result.Error
        foreach ($line in ($text -split "`r?`n")) {
            # Drop the CLI's box-drawing / status glyphs so the log stays readable.
            $clean = ($line -replace '[─-╿■-◿✓✗│└├╭╮╯╰]', '').Trim()
            if (-not [string]::IsNullOrWhiteSpace($clean)) {
                Write-Log $clean
            }
        }
        Set-ActionFeedback (T "Ready") ([System.Drawing.Color]::DarkGreen)
    } catch {
        Set-ActionFeedback $_.Exception.Message ([System.Drawing.Color]::Red)
        Write-Log $_.Exception.Message
    } finally {
        Set-Busy $false
    }
}

function Install-LocalEmbedding {
    # Local semantic search needs @xenova/transformers (Transformers.js). It is an
    # optional dependency npm may skip, so install it globally where AgentMemory
    # can resolve it (alongside the already-present onnxruntime-node).
    if (Test-LocalEmbeddingReady) {
        Set-ActionFeedback (T "LocalEmbeddingReady") ([System.Drawing.Color]::DarkGreen)
        Write-Log (T "LocalEmbeddingReady")
        return $true
    }

    Set-Busy $true
    Set-ActionFeedback (T "InstallingLocalEmbedding") ([System.Drawing.Color]::DarkOrange)
    Write-Log (T "InstallingLocalEmbedding")
    try {
        Set-ManagerEnv
        $result = Invoke-HiddenProcess -FilePath $script:ShellCmd -Arguments "$($script:ShellArgs) npm install -g @xenova/transformers" -Wait -TimeoutSeconds 900
        if ($result.ExitCode -eq 0 -and (Test-LocalEmbeddingReady)) {
            Set-ActionFeedback (T "LocalEmbeddingInstalled") ([System.Drawing.Color]::DarkGreen)
            Write-Log (T "LocalEmbeddingInstalled")
            return $true
        }

        $detail = if ($result.Error) { $result.Error.Trim() } else { "exit $($result.ExitCode)" }
        Set-ActionFeedback (T "LocalEmbeddingInstallFail" @($detail)) ([System.Drawing.Color]::Red)
        Write-Log (T "LocalEmbeddingInstallFail" @($detail))
        return $false
    } catch {
        Set-ActionFeedback (T "LocalEmbeddingInstallFail" @($_.Exception.Message)) ([System.Drawing.Color]::Red)
        Write-Log (T "LocalEmbeddingInstallFail" @($_.Exception.Message))
        return $false
    } finally {
        Set-Busy $false
    }
}

function Scan-AgentClients {
    Update-AgentClientStatus
    Set-ActionFeedback (T "AgentScanDone") ([System.Drawing.Color]::DarkGreen)
    Write-Log (T "AgentScanDone")
}

function Show-MemorySettingsDialog {
    $isEn = ($script:Language -eq "en")
    $m = Get-MemorySettings

    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = T "MemorySettings"
    $dlg.Size = New-Object System.Drawing.Size(600, 742)
    $dlg.StartPosition = "CenterParent"
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox = $false
    $dlg.MinimizeBox = $false
    $dlg.BackColor = [System.Drawing.Color]::White
    $dlg.AutoScroll = $true

    $addLabel = {
        param([string]$Text, [int]$X, [int]$Y, [int]$W, [int]$H = 22, [bool]$Bold = $false, [bool]$Gray = $false)
        $lb = New-Object System.Windows.Forms.Label
        $lb.Text = $Text
        $lb.Location = New-Object System.Drawing.Point($X, $Y)
        $lb.Size = New-Object System.Drawing.Size($W, $H)
        $fs = if ($Bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
        $lb.Font = New-Object System.Drawing.Font("Segoe UI", 9, $fs)
        if ($Gray) { $lb.ForeColor = [System.Drawing.Color]::FromArgb(107, 114, 128) }
        $dlg.Controls.Add($lb)
        return $lb
    }
    $addCombo = {
        param([string[]]$Items, [int]$X, [int]$Y, [int]$W)
        $cb = New-Object System.Windows.Forms.ComboBox
        $cb.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
        $cb.Location = New-Object System.Drawing.Point($X, $Y)
        $cb.Size = New-Object System.Drawing.Size($W, 24)
        foreach ($it in $Items) { [void]$cb.Items.Add($it) }
        $dlg.Controls.Add($cb)
        return $cb
    }
    $addText = {
        param([int]$X, [int]$Y, [int]$W, [string]$Value)
        $tb = New-Object System.Windows.Forms.TextBox
        $tb.Location = New-Object System.Drawing.Point($X, $Y)
        $tb.Size = New-Object System.Drawing.Size($W, 24)
        $tb.Text = $Value
        $dlg.Controls.Add($tb)
        return $tb
    }

    # Value arrays parallel to the localized combo items.
    $modeValues = @("keyword", "local", "cloud")
    $embFormatValues = @("openai", "gemini", "voyage", "cohere", "openrouter")
    $llmFormatValues = @("none", "openai", "anthropic", "gemini", "openrouter", "minimax")
    $toolValues = @("core", "all")

    # Section 1: embedding / semantic search
    [void](& $addLabel ($(if ($isEn) { "1. Semantic search (vectors)" } else { "① 语义检索（向量）" })) 20 14 540 22 $true)
    [void](& $addLabel ($(if ($isEn) { "Search mode" } else { "检索方式" })) 20 46 150)
    $cmbMode = & $addCombo @($(if ($isEn) { @("Keyword only (BM25)", "Local MiniLM (offline)", "Cloud API (custom)") } else { @("纯关键词 BM25（零配置）", "本地 MiniLM（离线语义）", "云端 API（自定义接入）") })) 180 44 388

    [void](& $addLabel ($(if ($isEn) { "Cloud format" } else { "云端格式" })) 20 80 150)
    $cmbEmbFormat = & $addCombo @($(if ($isEn) { @("OpenAI-compatible", "Gemini", "Voyage", "Cohere", "OpenRouter") } else { @("OpenAI 兼容", "Gemini", "Voyage", "Cohere", "OpenRouter") })) 180 78 200

    [void](& $addLabel ($(if ($isEn) { "Base URL" } else { "端点地址" })) 20 114 150)
    $txtEmbBaseUrl = & $addText 180 112 388 $m.EmbeddingBaseUrl

    [void](& $addLabel ($(if ($isEn) { "Embedding model" } else { "Embedding 模型" })) 20 148 150)
    $txtEmbModel = & $addText 180 146 228 $m.EmbeddingModel
    [void](& $addLabel ($(if ($isEn) { "Dim" } else { "维度" })) 416 148 40)
    $txtEmbDims = & $addText 458 146 110 $m.EmbeddingDimensions

    [void](& $addLabel ($(if ($isEn) { "Embedding key" } else { "Embedding Key" })) 20 182 150)
    $txtEmbKey = & $addText 180 180 388 $m.EmbeddingApiKey

    $chkHfMirror = New-Object System.Windows.Forms.CheckBox
    $chkHfMirror.Text = $(if ($isEn) { "Download local model via hf-mirror.com" } else { "本地模型走 hf-mirror.com 镜像下载（国内更快）" })
    $chkHfMirror.Location = New-Object System.Drawing.Point(180, 212)
    $chkHfMirror.Size = New-Object System.Drawing.Size(388, 22)
    $chkHfMirror.Checked = $m.UseHfMirror
    $dlg.Controls.Add($chkHfMirror)

    $btnInstallLocal = New-Object System.Windows.Forms.Button
    $btnInstallLocal.Text = $(if ($isEn) { "Install local deps" } else { "安装本地向量依赖" })
    $btnInstallLocal.Location = New-Object System.Drawing.Point(180, 238)
    $btnInstallLocal.Size = New-Object System.Drawing.Size(150, 28)
    $btnInstallLocal.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $dlg.Controls.Add($btnInstallLocal)
    $lblLocalStatus = & $addLabel "" 340 242 180 22 $false $true

    $refreshLocalStatus = {
        if (Test-LocalEmbeddingReady) {
            $lblLocalStatus.Text = $(if ($isEn) { "ready" } else { "已就绪" })
            $lblLocalStatus.ForeColor = [System.Drawing.Color]::FromArgb(22, 163, 74)
        } else {
            $lblLocalStatus.Text = $(if ($isEn) { "not installed" } else { "未安装" })
            $lblLocalStatus.ForeColor = [System.Drawing.Color]::FromArgb(217, 119, 6)
        }
    }
    & $refreshLocalStatus
    $btnInstallLocal.Add_Click({ [void](Install-LocalEmbedding); & $refreshLocalStatus })

    # Section 2: LLM provider (optional), with custom OpenAI/Anthropic endpoint
    [void](& $addLabel ($(if ($isEn) { "2. LLM smart compression (optional)" } else { "② LLM 智能压缩（可选）" })) 20 280 540 22 $true)
    [void](& $addLabel ($(if ($isEn) { "API format" } else { "API 格式" })) 20 312 150)
    $cmbLlmFormat = & $addCombo @($(if ($isEn) { @("None", "OpenAI Chat Completions", "Anthropic Messages", "Gemini", "OpenRouter", "MiniMax") } else { @("不使用", "OpenAI Chat Completions", "Anthropic Messages", "Gemini", "OpenRouter", "MiniMax") })) 180 310 260
    [void](& $addLabel ($(if ($isEn) { "Base URL" } else { "端点地址" })) 20 346 150)
    $txtLlmBaseUrl = & $addText 180 344 388 $m.LlmBaseUrl
    [void](& $addLabel ($(if ($isEn) { "Model ID" } else { "模型 ID" })) 20 380 150)
    $txtLlmModel = & $addText 180 378 388 $m.LlmModel
    [void](& $addLabel "LLM Key" 20 414 150)
    $txtLlmKey = & $addText 180 412 388 $m.LlmApiKey

    # Section 3: LLM-gated features (knowledge graph etc. — all need the LLM above)
    [void](& $addLabel ($(if ($isEn) { "3. LLM-powered features (need LLM key above)" } else { "③ LLM 增强功能（需上面配置 LLM）" })) 20 452 540 22 $true)
    $addCheck = {
        param([string]$Text, [int]$X, [int]$Y, [int]$W, [bool]$Checked)
        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text = $Text
        $cb.Location = New-Object System.Drawing.Point($X, $Y)
        $cb.Size = New-Object System.Drawing.Size($W, 22)
        $cb.Checked = $Checked
        $dlg.Controls.Add($cb)
        return $cb
    }
    $chkGraph        = & $addCheck ($(if ($isEn) { "Knowledge graph extraction" } else { "知识图谱提取" })) 180 478 230 $m.GraphExtraction
    $chkConsolidation = & $addCheck ($(if ($isEn) { "Memory consolidation" } else { "记忆整合" })) 416 478 152 $m.Consolidation
    $chkAutoCompress  = & $addCheck ($(if ($isEn) { "LLM auto-compress" } else { "LLM 自动压缩" })) 180 502 230 $m.AutoCompress
    $chkInject        = & $addCheck ($(if ($isEn) { "Inject context into chat" } else { "注入上下文到对话" })) 416 502 152 $m.InjectContext

    # Section 4: MCP tool surface
    [void](& $addLabel ($(if ($isEn) { "4. MCP tool surface" } else { "④ MCP 工具集" })) 20 538 540 22 $true)
    [void](& $addLabel ($(if ($isEn) { "Tools exposed" } else { "暴露给工具的工具集" })) 20 570 150)
    $cmbTools = & $addCombo @($(if ($isEn) { @("core (7 tools, default)", "all (51 tools)") } else { @("core（7 个工具，默认）", "all（51 个工具）") })) 180 568 260

    [void](& $addLabel ($(if ($isEn) { "Base URL must NOT include /chat/completions (it is appended automatically). Model/URL empty = provider default. Section 3 needs the LLM above. Saved locally; applied after a service restart." } else { "端点地址不要带 /chat/completions（会自动补全）；端点/模型留空＝用官方默认。③ 的功能需配好上面的 LLM。设置保存在本机，重启服务后生效；Key 仅存本地。" })) 20 600 552 56 $false $true)

    # Initial selections
    $cmbMode.SelectedIndex = [Math]::Max(0, [Array]::IndexOf($modeValues, $m.EmbeddingMode))
    $cmbEmbFormat.SelectedIndex = [Math]::Max(0, [Array]::IndexOf($embFormatValues, $m.EmbeddingFormat))
    $cmbLlmFormat.SelectedIndex = [Math]::Max(0, [Array]::IndexOf($llmFormatValues, $m.LlmFormat))
    $cmbTools.SelectedIndex = [Math]::Max(0, [Array]::IndexOf($toolValues, $m.Tools))

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = $(if ($isEn) { "Cancel" } else { "取消" })
    $btnCancel.Location = New-Object System.Drawing.Point(370, 660)
    $btnCancel.Size = New-Object System.Drawing.Size(90, 30)
    $btnCancel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $dlg.Controls.Add($btnCancel)

    $btnSave = New-Object System.Windows.Forms.Button
    $btnSave.Text = $(if ($isEn) { "Save" } else { "保存" })
    $btnSave.Location = New-Object System.Drawing.Point(468, 660)
    $btnSave.Size = New-Object System.Drawing.Size(90, 30)
    $btnSave.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnSave.BackColor = [System.Drawing.Color]::FromArgb(24, 144, 255)
    $btnSave.ForeColor = [System.Drawing.Color]::White
    $dlg.Controls.Add($btnSave)
    $dlg.AcceptButton = $btnSave
    $dlg.CancelButton = $btnCancel

    $btnSave.Add_Click({
        $saved = [pscustomobject]@{
            EmbeddingMode       = $modeValues[$cmbMode.SelectedIndex]
            EmbeddingFormat     = $embFormatValues[$cmbEmbFormat.SelectedIndex]
            EmbeddingBaseUrl    = $txtEmbBaseUrl.Text.Trim()
            EmbeddingModel      = $txtEmbModel.Text.Trim()
            EmbeddingDimensions = $txtEmbDims.Text.Trim()
            EmbeddingApiKey     = $txtEmbKey.Text.Trim()
            LlmFormat           = $llmFormatValues[$cmbLlmFormat.SelectedIndex]
            LlmBaseUrl          = $txtLlmBaseUrl.Text.Trim()
            LlmModel            = $txtLlmModel.Text.Trim()
            LlmApiKey           = $txtLlmKey.Text.Trim()
            Tools               = $toolValues[$cmbTools.SelectedIndex]
            UseHfMirror         = [bool]$chkHfMirror.Checked
            GraphExtraction     = [bool]$chkGraph.Checked
            Consolidation       = [bool]$chkConsolidation.Checked
            AutoCompress        = [bool]$chkAutoCompress.Checked
            InjectContext       = [bool]$chkInject.Checked
        }
        [void](Save-MemorySettings -Memory $saved)
        $dlg.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $dlg.Close()
    })

    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Set-ActionFeedback (T "MemorySettingsSaved") ([System.Drawing.Color]::DarkGreen)
        Write-Log (T "MemorySettingsSaved")
    }
    $dlg.Dispose()
}

function Configure-AgentClients {
    Set-Busy $true
    try {
        $paths = @(Configure-AllAgentClients)
        foreach ($path in $paths) {
            Write-Log "MCP config: $path"
        }
        Update-AgentClientStatus
        Set-ActionFeedback (T "AgentConfigureDone") ([System.Drawing.Color]::DarkGreen)
        Write-Log (T "AgentConfigureDone")
        [System.Windows.Forms.MessageBox]::Show((T "AgentConfigureBody"), (T "AgentConfigureTitle"), "OK", "Information") | Out-Null
    } catch {
        Set-ActionFeedback $_.Exception.Message ([System.Drawing.Color]::Red)
        Write-Log $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "AgentMemory", "OK", "Error") | Out-Null
    } finally {
        Set-Busy $false
    }
}

function Copy-CliCommands {
    if ($script:IsWindows) {
        [System.Windows.Forms.Clipboard]::SetText((Get-CliConfigCommands))
    } else {
        $text = Get-CliConfigCommands
        if (Get-Command pbcopy -ErrorAction SilentlyContinue) { $text | pbcopy }
        elseif (Get-Command xclip -ErrorAction SilentlyContinue) { $text | xclip -selection clipboard }
        else { Write-Log "Clipboard not available; commands printed above" }
    }
    Set-ActionFeedback (T "CopyCliOkBody") ([System.Drawing.Color]::DarkGreen)
    Write-Log (T "CopyCliOkBody")
    [System.Windows.Forms.MessageBox]::Show((T "CopyCliOkBody"), (T "CopyOkTitle"), "OK", "Information") | Out-Null
}

function Sync-SharedFilesFromUi {
    Set-Busy $true
    try {
        $paths = @(Sync-SharedAgentFiles)
        foreach ($path in $paths) {
            Write-Log "Shared file: $path"
        }
        Set-ActionFeedback (T "SyncSharedDone") ([System.Drawing.Color]::DarkGreen)
        Write-Log (T "SyncSharedDone")
    } finally {
        Set-Busy $false
    }
}

function Bridge-WorkspaceFromUi {
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = T "BridgeWorkspacePrompt"
    $dialog.ShowNewFolderButton = $false
    $dialog.SelectedPath = (Get-Location).Path

    try {
        if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            return
        }

        Set-Busy $true
        $projectPath = $dialog.SelectedPath
        [void](Import-CodexSessionBridge -ProjectPath $projectPath)
        [void](Import-TraeSessionBridge -ProjectPath $projectPath)
        $workspace = Initialize-WorkspaceMemory -ProjectPath $projectPath
        Write-Log "Workspace bridge: $($workspace.WorkspacePath)"
        Set-ActionFeedback (T "BridgeWorkspaceDone" @($workspace.WorkspacePath)) ([System.Drawing.Color]::DarkGreen)
        [System.Windows.Forms.MessageBox]::Show((T "BridgeWorkspaceDone" @($workspace.WorkspacePath)), (T "BridgeWorkspaceTitle"), "OK", "Information") | Out-Null
    } catch {
        Set-ActionFeedback $_.Exception.Message ([System.Drawing.Color]::Red)
        Write-Log $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "CrossAgentCoding", "OK", "Error") | Out-Null
    } finally {
        Set-Busy $false
        $dialog.Dispose()
    }
}

function Migrate-DataHomeFromUi {
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = T "MigrateDataPrompt"
    $dialog.ShowNewFolderButton = $true
    $dialog.SelectedPath = Get-CrossAgentCodingHome

    try {
        if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            return
        }

        Set-Busy $true
        $result = Move-CrossAgentCodingHome -NewHome $dialog.SelectedPath
        Write-Log "Data home: $($result.NewHome)"
        Set-ActionFeedback (T "MigrateDataDone" @($result.NewHome)) ([System.Drawing.Color]::DarkGreen)
        [System.Windows.Forms.MessageBox]::Show((T "MigrateDataDone" @($result.NewHome)), (T "MigrateDataTitle"), "OK", "Information") | Out-Null
        [void](Sync-SharedAgentFiles)
    } catch {
        Set-ActionFeedback $_.Exception.Message ([System.Drawing.Color]::Red)
        Write-Log $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "CrossAgentCoding", "OK", "Error") | Out-Null
    } finally {
        Set-Busy $false
        $dialog.Dispose()
    }
}

function Migrate-StorageLocationFromUi {
    param(
        [string]$Key,            # serviceDir | modelCacheDir
        [string]$PromptKey,
        [string]$CurrentDir
    )

    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = T $PromptKey
    $dialog.ShowNewFolderButton = $true
    if (Test-Path -LiteralPath $CurrentDir) { $dialog.SelectedPath = $CurrentDir }

    try {
        if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            return $false
        }

        Set-Busy $true
        $result = Move-StorageLocation -Key $Key -NewDir $dialog.SelectedPath
        Write-Log "Storage [$Key]: $($result.NewDir)"
        Set-ActionFeedback (T "StorageMigrated" @($result.NewDir)) ([System.Drawing.Color]::DarkGreen)
        return $true
    } catch {
        Set-ActionFeedback $_.Exception.Message ([System.Drawing.Color]::Red)
        Write-Log $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "CrossAgentCoding", "OK", "Error") | Out-Null
        return $false
    } finally {
        Set-Busy $false
        $dialog.Dispose()
    }
}

function Show-StorageSettingsDialog {
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = T "StorageTitle"
    $dlg.Size = New-Object System.Drawing.Size(680, 416)
    $dlg.StartPosition = "CenterParent"
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox = $false
    $dlg.MinimizeBox = $false
    $dlg.BackColor = [System.Drawing.Color]::White

    $rows = @(
        @{ Name = (T "StorageHomeRow");    Get = { Get-CrossAgentCodingHome }; Action = "home" },
        @{ Name = (T "StorageServiceRow"); Get = { Get-ServiceWorkDir };       Action = "service" },
        @{ Name = (T "StorageModelRow");   Get = { Get-ModelCacheDir };        Action = "model" }
    )

    $pathLabels = @()
    $y = 18
    for ($i = 0; $i -lt $rows.Count; $i++) {
        $row = $rows[$i]

        $nameLb = New-Object System.Windows.Forms.Label
        $nameLb.Text = $row.Name
        $nameLb.Location = New-Object System.Drawing.Point(20, $y)
        $nameLb.Size = New-Object System.Drawing.Size(630, 20)
        $nameLb.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $dlg.Controls.Add($nameLb)

        $pathLb = New-Object System.Windows.Forms.Label
        $pathLb.Text = [string](& $row.Get)
        $pathLb.Location = New-Object System.Drawing.Point(20, ($y + 24))
        $pathLb.Size = New-Object System.Drawing.Size(490, 36)
        $pathLb.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
        $pathLb.ForeColor = [System.Drawing.Color]::FromArgb(107, 114, 128)
        $dlg.Controls.Add($pathLb)
        $pathLabels += $pathLb

        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = T "StorageChooseMigrate"
        $btn.Location = New-Object System.Drawing.Point(524, ($y + 22))
        $btn.Size = New-Object System.Drawing.Size(120, 30)
        $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btn.Tag = $row.Action
        $dlg.Controls.Add($btn)

        $y += 78
    }

    $refresh = {
        $pathLabels[0].Text = [string](Get-CrossAgentCodingHome)
        $pathLabels[1].Text = [string](Get-ServiceWorkDir)
        $pathLabels[2].Text = [string](Get-ModelCacheDir)
        Update-DataPathLabel
    }

    foreach ($c in $dlg.Controls) {
        if ($c -is [System.Windows.Forms.Button] -and $c.Tag) {
            $c.Add_Click({
                switch ([string]$this.Tag) {
                    "home"    { [void](Migrate-DataHomeFromUi) }
                    "service" { [void](Migrate-StorageLocationFromUi -Key "serviceDir" -PromptKey "StoragePickService" -CurrentDir (Get-ServiceWorkDir)) }
                    "model"   { [void](Migrate-StorageLocationFromUi -Key "modelCacheDir" -PromptKey "StoragePickModel" -CurrentDir (Get-ModelCacheDir)) }
                }
                & $refresh
            })
        }
    }

    $noteLb = New-Object System.Windows.Forms.Label
    $noteLb.Text = T "StorageNote"
    $noteLb.Location = New-Object System.Drawing.Point(20, ($y + 4))
    $noteLb.Size = New-Object System.Drawing.Size(630, 36)
    $noteLb.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $noteLb.ForeColor = [System.Drawing.Color]::FromArgb(107, 114, 128)
    $dlg.Controls.Add($noteLb)

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "OK"
    $btnClose.Location = New-Object System.Drawing.Point(554, ($y + 46))
    $btnClose.Size = New-Object System.Drawing.Size(90, 30)
    $btnClose.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnClose.BackColor = [System.Drawing.Color]::FromArgb(24, 144, 255)
    $btnClose.ForeColor = [System.Drawing.Color]::White
    $btnClose.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $dlg.Controls.Add($btnClose)
    $dlg.AcceptButton = $btnClose

    [void]$dlg.ShowDialog()
    $dlg.Dispose()
}

function Configure-AgentToolFromUi {
    param([string]$TargetId)

    Set-Busy $true
    try {
        $target = @(Get-AgentTargetDefinitions | Where-Object { $_.Id -eq $TargetId } | Select-Object -First 1)
        if ($target.Count -eq 0) {
            throw "Unknown tool target: $TargetId"
        }

        $actionName = [string]$target[0].ConfigureAction
        $path = & $actionName
        Write-Log "MCP config: $path"
        Update-AgentClientStatus
        Set-ActionFeedback (T "ToolConfigureDone" @($target[0].Name)) ([System.Drawing.Color]::DarkGreen)
    } catch {
        Set-ActionFeedback $_.Exception.Message ([System.Drawing.Color]::Red)
        Write-Log $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "CrossAgentCoding", "OK", "Error") | Out-Null
    } finally {
        Set-Busy $false
    }
}

function New-CardLabel {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [float]$Size = 8.5,
        [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular
    )

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Location = New-Object System.Drawing.Point($X, $Y)
    $label.Size = New-Object System.Drawing.Size($Width, $Height)
    $label.Font = New-Object System.Drawing.Font("Segoe UI", $Size, $Style)
    $label.AutoEllipsis = $true
    return $label
}

function New-FlatButton {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [switch]$Primary
    )

    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Location = New-Object System.Drawing.Point($X, $Y)
    $button.Size = New-Object System.Drawing.Size($Width, $Height)
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    if ($Primary) {
        $button.BackColor = [System.Drawing.Color]::FromArgb(24, 144, 255)
        $button.ForeColor = [System.Drawing.Color]::White
    } else {
        $button.BackColor = [System.Drawing.Color]::White
        $button.ForeColor = [System.Drawing.Color]::FromArgb(55, 65, 81)
    }
    return $button
}

function New-ToolCardControl {
    param(
        [object]$Card,
        [int]$X,
        [int]$Y
    )

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Size = New-Object System.Drawing.Size(350, 108)
    $panel.Location = New-Object System.Drawing.Point($X, $Y)
    $panel.BackColor = [System.Drawing.Color]::White
    $panel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $nameLabel = New-CardLabel -Text $Card.Name -X 18 -Y 14 -Width 200 -Height 24 -Size 9.5 -Style ([System.Drawing.FontStyle]::Bold)
    $panel.Controls.Add($nameLabel)

    $platformLabel = New-CardLabel -Text $Card.Platform -X 18 -Y 40 -Width 46 -Height 22 -Size 8
    $platformLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $platformLabel.BackColor = [System.Drawing.Color]::FromArgb(230, 244, 255)
    $platformLabel.ForeColor = [System.Drawing.Color]::FromArgb(22, 119, 255)
    $panel.Controls.Add($platformLabel)

    $installLabel = New-CardLabel -Text $Card.InstallStatus -X 245 -Y 16 -Width 82 -Height 22 -Size 8.5
    $installLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
    $panel.Controls.Add($installLabel)

    $detailLabel = New-CardLabel -Text $Card.Detail -X 18 -Y 74 -Width 210 -Height 20 -Size 8
    $detailLabel.ForeColor = [System.Drawing.Color]::FromArgb(107, 114, 128)
    $panel.Controls.Add($detailLabel)

    $actionButton = New-FlatButton -Text $Card.ActionText -X 248 -Y 72 -Width 84 -Height 26
    $actionButton.Tag = $Card.Id
    $actionButton.Add_Click({ Configure-AgentToolFromUi -TargetId ([string]$this.Tag) })
    $panel.Controls.Add($actionButton)

    return [pscustomobject]@{
        Id = $Card.Id
        Panel = $panel
        NameLabel = $nameLabel
        PlatformLabel = $platformLabel
        InstallLabel = $installLabel
        DetailLabel = $detailLabel
        ActionButton = $actionButton
    }
}

function Update-ToolCardControls {
    if ($null -eq $script:ToolCardControls) {
        return
    }

    $cards = @{}
    foreach ($card in Get-AgentToolCards) {
        $cards[$card.Id] = $card
    }

    foreach ($control in $script:ToolCardControls) {
        if (-not $cards.ContainsKey($control.Id)) {
            continue
        }

        $card = $cards[$control.Id]
        $control.NameLabel.Text = $card.Name
        $control.PlatformLabel.Text = $card.Platform
        $control.InstallLabel.Text = $card.InstallStatus
        $control.DetailLabel.Text = $card.Detail
        $control.ActionButton.Text = $card.ActionText

        # Install status uses exactly two colors: green = installed, gray = not
        # installed. Configuration state is conveyed by the detail line, not by a
        # third install-label color.
        if ($card.Installed) {
            $control.InstallLabel.ForeColor = [System.Drawing.Color]::FromArgb(22, 163, 74)
        } else {
            $control.InstallLabel.ForeColor = [System.Drawing.Color]::FromArgb(156, 163, 175)
        }
    }

    [System.Windows.Forms.Application]::DoEvents()
}

# GUI mode. The packaged exe launches this script through a hidden window, so a
# terminating error here would otherwise look like "nothing happens" on click.
# Wrap the whole GUI bootstrap so any failure is logged and shown to the user.
if (-not $script:IsWindows) {
    Write-Host "GUI mode is only available on Windows. Use -Cli or -Tui instead."
    Write-Host "Example: powershell -File AgentMemoryManager.ps1 -Cli env tools"
    exit 1
}

try {

$script:Form = New-Object System.Windows.Forms.Form
$script:Form.Size = New-Object System.Drawing.Size(1180, 796)
$script:Form.StartPosition = "CenterScreen"
$script:Form.FormBorderStyle = "FixedSingle"
$script:Form.MaximizeBox = $false
$script:Form.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 250)

# Set application icon from icon/icon.ico (relative to script location)
# Form.Icon only sets the title-bar icon; we also need to force the taskbar icon
# via WM_SETICON because the host process is powershell.exe.
try {
    $iconCandidates = @(
        (Join-Path $PSScriptRoot "..\icon\icon.ico"),
        (Join-Path $PSScriptRoot "icon.ico")
    )
    $appIcon = $null
    foreach ($iconPath in $iconCandidates) {
        if (Test-Path -LiteralPath $iconPath) {
            $appIcon = New-Object System.Drawing.Icon($iconPath)
            break
        }
    }
    if ($appIcon) {
        $script:Form.Icon = $appIcon
        # Force the taskbar icon via Win32 SendMessage(WM_SETICON, ICON_BIG)
        $script:Form.Add_Shown({
            $code = @'
using System;
using System.Runtime.InteropServices;
public class TaskbarIcon {
    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    public const uint WM_SETICON = 0x0080;
    public const IntPtr ICON_SMALL = IntPtr.Zero;
    public static readonly IntPtr ICON_BIG = (IntPtr)1;
}
'@
            try {
                Add-Type -TypeDefinition $code -ErrorAction Stop
                $handle = $appIcon.Handle
                [TaskbarIcon]::SendMessage($script:Form.Handle, [TaskbarIcon]::WM_SETICON, [TaskbarIcon]::ICON_BIG, $handle)
                [TaskbarIcon]::SendMessage($script:Form.Handle, [TaskbarIcon]::WM_SETICON, [TaskbarIcon]::ICON_SMALL, $handle)
            } catch {}
        })
    }
} catch {}

$script:HeaderPanel = New-Object System.Windows.Forms.Panel
$script:HeaderPanel.Size = New-Object System.Drawing.Size(1164, 60)
$script:HeaderPanel.Location = New-Object System.Drawing.Point(0, 0)
$script:HeaderPanel.BackColor = [System.Drawing.Color]::White
$script:Form.Controls.Add($script:HeaderPanel)

# Product name on the left of the header (replaces the removed "设置/关于" labels).
$script:HeaderTitleLabel = New-Object System.Windows.Forms.Label
$script:HeaderTitleLabel.Text = "CrossAgentCoding"
$script:HeaderTitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$script:HeaderTitleLabel.Size = New-Object System.Drawing.Size(400, 36)
$script:HeaderTitleLabel.Location = New-Object System.Drawing.Point(24, 12)
$script:HeaderPanel.Controls.Add($script:HeaderTitleLabel)

$script:LanguageBox = New-Object System.Windows.Forms.ComboBox
$script:LanguageBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$script:LanguageBox.Items.Add("中文") | Out-Null
$script:LanguageBox.Items.Add("English") | Out-Null
$script:LanguageBox.Items.Add("繁體中文") | Out-Null
$script:LanguageBox.SelectedIndex = 0
$script:LanguageBox.Size = New-Object System.Drawing.Size(110, 26)
$script:LanguageBox.Location = New-Object System.Drawing.Point(1030, 16)
$script:HeaderPanel.Controls.Add($script:LanguageBox)

# Tab navigation was removed: only the "About" view is implemented, so the
# unfinished General/Route/Auth/Advanced/Usage tabs are no longer rendered.
$script:NavButtons = $null

$script:AboutPanel = New-Object System.Windows.Forms.Panel
$script:AboutPanel.Size = New-Object System.Drawing.Size(1132, 124)
$script:AboutPanel.Location = New-Object System.Drawing.Point(24, 70)
$script:AboutPanel.BackColor = [System.Drawing.Color]::White
$script:AboutPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$script:Form.Controls.Add($script:AboutPanel)

$script:ProductNameLabel = New-CardLabel -Text "" -X 20 -Y 14 -Width 180 -Height 28 -Size 11 -Style ([System.Drawing.FontStyle]::Bold)
$script:AboutPanel.Controls.Add($script:ProductNameLabel)

$script:ProductVersionLabel = New-CardLabel -Text "" -X 20 -Y 50 -Width 160 -Height 24 -Size 8
$script:ProductVersionLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$script:ProductVersionLabel.BackColor = [System.Drawing.Color]::White
$script:ProductVersionLabel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$script:AboutPanel.Controls.Add($script:ProductVersionLabel)

$script:NodeLabel = New-Object System.Windows.Forms.Label
$script:NodeLabel.Size = New-Object System.Drawing.Size(198, 20)
$script:NodeLabel.Location = New-Object System.Drawing.Point(232, 14)
$script:NodeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$script:AboutPanel.Controls.Add($script:NodeLabel)

$script:AgentMemoryLabel = New-Object System.Windows.Forms.Label
$script:AgentMemoryLabel.Size = New-Object System.Drawing.Size(198, 20)
$script:AgentMemoryLabel.Location = New-Object System.Drawing.Point(232, 40)
$script:AgentMemoryLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$script:AboutPanel.Controls.Add($script:AgentMemoryLabel)

$script:IiiLabel = New-Object System.Windows.Forms.Label
$script:IiiLabel.Size = New-Object System.Drawing.Size(198, 20)
$script:IiiLabel.Location = New-Object System.Drawing.Point(232, 66)
$script:IiiLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$script:AboutPanel.Controls.Add($script:IiiLabel)

$script:ServiceLabel = New-Object System.Windows.Forms.Label
$script:ServiceLabel.Size = New-Object System.Drawing.Size(170, 24)
$script:ServiceLabel.Location = New-Object System.Drawing.Point(436, 38)
$script:ServiceLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$script:AboutPanel.Controls.Add($script:ServiceLabel)

# Action buttons: three rows of wide buttons on the right of the status panel.
# Row 1 = service, Row 2 = connect/memory, Row 3 = workspace/data.
$script:BtnInstall = New-FlatButton -Text "" -X 616 -Y 12 -Width 122 -Height 28 -Primary
$script:AboutPanel.Controls.Add($script:BtnInstall)

$script:BtnStartStop = New-FlatButton -Text "" -X 746 -Y 12 -Width 122 -Height 28
$script:AboutPanel.Controls.Add($script:BtnStartStop)

$script:BtnCheckStatus = New-FlatButton -Text "" -X 876 -Y 12 -Width 122 -Height 28
$script:AboutPanel.Controls.Add($script:BtnCheckStatus)

$script:BtnViewer = New-FlatButton -Text "" -X 1006 -Y 12 -Width 122 -Height 28
$script:AboutPanel.Controls.Add($script:BtnViewer)

$script:BtnMcp = New-FlatButton -Text "" -X 616 -Y 48 -Width 122 -Height 28
$script:AboutPanel.Controls.Add($script:BtnMcp)

$script:BtnCopyCli = New-FlatButton -Text "" -X 746 -Y 48 -Width 122 -Height 28
$script:AboutPanel.Controls.Add($script:BtnCopyCli)

$script:BtnMemorySettings = New-FlatButton -Text "" -X 876 -Y 48 -Width 122 -Height 28
$script:AboutPanel.Controls.Add($script:BtnMemorySettings)

$script:BtnCheckUpdate = New-FlatButton -Text "" -X 1006 -Y 48 -Width 122 -Height 28
$script:AboutPanel.Controls.Add($script:BtnCheckUpdate)

$script:BtnSyncShared = New-FlatButton -Text "" -X 616 -Y 84 -Width 122 -Height 28
$script:AboutPanel.Controls.Add($script:BtnSyncShared)

$script:BtnWorkspaceBridge = New-FlatButton -Text "" -X 746 -Y 84 -Width 122 -Height 28
$script:AboutPanel.Controls.Add($script:BtnWorkspaceBridge)

$script:BtnMigrateHome = New-FlatButton -Text "" -X 876 -Y 84 -Width 122 -Height 28
$script:AboutPanel.Controls.Add($script:BtnMigrateHome)

# Shows the current data directory, service log path, and live service ports so
# the user knows exactly where data lives before deciding whether to migrate it.
$script:DataPathLabel = New-CardLabel -Text "" -X 26 -Y 202 -Width 1106 -Height 36 -Size 8.5
$script:DataPathLabel.ForeColor = [System.Drawing.Color]::FromArgb(107, 114, 128)
$script:Form.Controls.Add($script:DataPathLabel)

$script:LocalEnvLabel = New-CardLabel -Text "" -X 24 -Y 246 -Width 300 -Height 26 -Size 10.5 -Style ([System.Drawing.FontStyle]::Bold)
$script:Form.Controls.Add($script:LocalEnvLabel)

$script:BtnScanAgents = New-FlatButton -Text "" -X 948 -Y 242 -Width 92 -Height 28
$script:Form.Controls.Add($script:BtnScanAgents)

$script:BtnConfigureAgents = New-FlatButton -Text "" -X 1044 -Y 242 -Width 104 -Height 28 -Primary
$script:Form.Controls.Add($script:BtnConfigureAgents)

$script:ToolCardsPanel = New-Object System.Windows.Forms.Panel
$script:ToolCardsPanel.Size = New-Object System.Drawing.Size(1132, 300)
$script:ToolCardsPanel.Location = New-Object System.Drawing.Point(24, 276)
$script:ToolCardsPanel.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 250)
$script:ToolCardsPanel.AutoScroll = $true
$script:Form.Controls.Add($script:ToolCardsPanel)

$script:AgentLabels = New-Object System.Collections.ArrayList
$script:ToolCardControls = New-Object System.Collections.ArrayList
$initialCards = @(Get-PlaceholderToolCards)
for ($i = 0; $i -lt $initialCards.Count; $i++) {
    $col = $i % 3
    $row = [math]::Floor($i / 3)
    $x = $col * 370
    $y = $row * 122
    $cardControl = New-ToolCardControl -Card $initialCards[$i] -X $x -Y $y
    $script:ToolCardsPanel.Controls.Add($cardControl.Panel)
    [void]$script:ToolCardControls.Add($cardControl)
}

$script:ActionGroup = New-Object System.Windows.Forms.GroupBox
$script:ActionGroup.Size = New-Object System.Drawing.Size(548, 150)
$script:ActionGroup.Location = New-Object System.Drawing.Point(24, 588)
$script:Form.Controls.Add($script:ActionGroup)

$script:ActionLabel = New-Object System.Windows.Forms.Label
$script:ActionLabel.Size = New-Object System.Drawing.Size(520, 116)
$script:ActionLabel.Location = New-Object System.Drawing.Point(14, 24)
$script:ActionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$script:ActionGroup.Controls.Add($script:ActionLabel)

$script:LogGroup = New-Object System.Windows.Forms.GroupBox
$script:LogGroup.Size = New-Object System.Drawing.Size(572, 150)
$script:LogGroup.Location = New-Object System.Drawing.Point(584, 588)
$script:Form.Controls.Add($script:LogGroup)

$script:LogBox = New-Object System.Windows.Forms.TextBox
$script:LogBox.Multiline = $true
$script:LogBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$script:LogBox.ReadOnly = $true
$script:LogBox.Font = New-Object System.Drawing.Font("Consolas", 8.5)
$script:LogBox.Size = New-Object System.Drawing.Size(548, 116)
$script:LogBox.Location = New-Object System.Drawing.Point(12, 22)
$script:LogBox.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$script:LogBox.ForeColor = [System.Drawing.Color]::FromArgb(200, 255, 200)
$script:LogGroup.Controls.Add($script:LogBox)

$script:LanguageBox.Add_SelectedIndexChanged({
    if ($script:LanguageBox.SelectedIndex -eq 1) {
        $script:Language = "en"
    } elseif ($script:LanguageBox.SelectedIndex -eq 2) {
        $script:Language = "zh-TW"
    } else {
        $script:Language = "zh"
    }
    Apply-Language
    Update-Status
    Update-ToolCardControls
    Set-ActionFeedback (T "Ready")
})

$script:BtnInstall.Add_Click({ Install-All })
$script:BtnStartStop.Add_Click({
    # Single toggle button: stop when the service is up, otherwise start it.
    if (Test-ServiceRunning) {
        Stop-AgentMemory
    } else {
        Start-AgentMemory
    }
    Update-Status
})
$script:BtnMcp.Add_Click({ Copy-McpConfig })
$script:BtnViewer.Add_Click({ Open-MemoryViewer })
$script:BtnMemorySettings.Add_Click({ Show-MemorySettingsDialog })
$script:BtnCheckUpdate.Add_Click({ Check-AgentMemoryUpdate })
$script:BtnCheckStatus.Add_Click({ Show-MemoryStatus })
$script:BtnScanAgents.Add_Click({ Scan-AgentClients })
$script:BtnConfigureAgents.Add_Click({ Configure-AgentClients })
$script:BtnCopyCli.Add_Click({ Copy-CliCommands })
$script:BtnSyncShared.Add_Click({ Sync-SharedFilesFromUi })
$script:BtnWorkspaceBridge.Add_Click({ Bridge-WorkspaceFromUi })
$script:BtnMigrateHome.Add_Click({ Show-StorageSettingsDialog })

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 5000
$timer.Add_Tick({
    if (-not $script:IsBusy) {
        Update-Status
        Update-AgentClientStatus
    }
})
$timer.Start()
$script:RefreshTimer = $timer

Apply-Language
Set-ActionFeedback (T "Scanning")
if ($UiSmokeTest) {
    Write-Output "UI_SMOKE_OK"
    exit 0
}
Write-Log (T "InitialLog1")
Write-Log (T "InitialLog2")
Write-Log (T "InitialLog3")

# Populate environment and agent status only after the window has actually
# painted. A synchronous scan inside the Shown handler would block the UI thread
# before the first paint, so the window would never appear. Instead, start a
# one-shot timer from Shown; its first tick runs inside the live message loop,
# after the window is visible, so the window always shows even if the scan is slow.
$script:InitialScanTimer = New-Object System.Windows.Forms.Timer
$script:InitialScanTimer.Interval = 120
$script:InitialScanTimer.Add_Tick({
    $script:InitialScanTimer.Stop()
    try {
        Update-Status
        Update-AgentClientStatus
        Set-ActionFeedback (T "Ready")
    } catch {
        Set-ActionFeedback ("Scan error: " + $_.Exception.Message)
    }
})
$script:Form.Add_Shown({ $script:InitialScanTimer.Start() })

# Stop timers immediately when the user closes the window (X button or
# taskbar "Close window"). Without this, a timer tick firing during
# shutdown can block the UI thread and prevent the form from disposing.
# Local variables are used (not $script:) because PowerShell 5.1 cannot
# convert script blocks that reference script-scoped variables into
# FormClosingEventHandler delegates when loaded via -File.
$localRefreshTimer = $script:RefreshTimer
$localScanTimer = $script:InitialScanTimer
$script:Form.Add_FormClosing({
    if ($localRefreshTimer) { $localRefreshTimer.Stop() }
    if ($localScanTimer) { $localScanTimer.Stop() }
})

[void]$script:Form.ShowDialog()

# Clean up timers after the window closes.
$script:RefreshTimer.Stop()
$script:RefreshTimer.Dispose()
if ($script:InitialScanTimer) {
    $script:InitialScanTimer.Stop()
    $script:InitialScanTimer.Dispose()
}

} catch {
    $logPath = Join-Path ([System.IO.Path]::GetTempPath()) "CrossAgentCoding-error.log"
    $detail = "[" + (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + "] CrossAgentCoding startup failed`r`n" +
        ($_ | Out-String) + "`r`n" + [string]$_.ScriptStackTrace
    try { Set-Content -LiteralPath $logPath -Value $detail -Encoding UTF8 } catch {}
    try {
        [System.Windows.Forms.MessageBox]::Show(
            "CrossAgentCoding 启动失败 / failed to start:`r`n`r`n" + ($_ | Out-String) +
                "`r`n日志 / Log: $logPath",
            "CrossAgentCoding",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    } catch {}
    # The user has already been notified above, so exit 0 to avoid the launcher
    # showing a second, redundant failure dialog.
    exit 0
}




