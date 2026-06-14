param(
    [switch]$SelfTest,
    [switch]$Cli,
    [switch]$Tui,
    [switch]$UiSmokeTest,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CommandArgs = @()
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Continue"

$script:AM_DIR = Join-Path $env:USERPROFILE ".agentmemory"
$script:LOCAL_BIN = Join-Path $env:USERPROFILE ".local\bin"
$script:NPM_GLOBAL = Join-Path $env:APPDATA "npm"
$script:APP_NAME = "CrossAgnetCoding"
$script:APP_VERSION = "0.3.0-mvp"
$script:PORT = 3111
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
        WindowTitle = "CrossAgnetCoding v0.3.0-mvp"
        Title = "CrossAgnetCoding 跨 Coding Agent 记忆管理器"
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
        CopyMcp = "复制 MCP 配置到剪贴板"
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
        Configured = "已连接 CrossAgnetCoding"
        NotConfigured = "未连接 CrossAgnetCoding"
        UnknownVersion = "可执行，版本未知"
        NotChecked = "未检查"
        Scanning = "扫描中…"
        InstallOrExecutableMissing = "not installed or not executable"
        ConfigureTool = "配置"
        ReconfigureTool = "重新配置"
        ToolConfigureDone = "{0} 已写入 CrossAgnetCoding MCP 配置"
        AgentInstalledConfigured = "{0} - 已安装 / 已配置"
        AgentInstalledNotConfigured = "{0} - 已安装 / 未配置"
        AgentMissingConfigured = "{0} - 未检测到安装 / 已有配置"
        AgentMissingNotConfigured = "{0} - 未安装 / 未配置"
        AgentScanDone = "Coding Agent 扫描完成"
        AgentConfigureDone = "Coding Agent MCP 配置完成，请重启对应工具"
        AgentConfigureTitle = "配置完成"
        AgentConfigureBody = "已尝试写入 Codex、TRAE SOLO、OpenCode、Claude、Gemini、OpenClaw、Hermes 的用户级 MCP 配置。请查看日志并重启对应工具。"
        CopyCliOkBody = "CLI 配置命令已复制到剪贴板。"
        SyncSharedDone = "共享 Prompt 文件已同步"
        BridgeWorkspacePrompt = "请选择要桥接记忆的项目目录"
        BridgeWorkspaceDone = "工作区桥接完成：{0}"
        BridgeWorkspaceTitle = "桥接完成"
        MigrateDataPrompt = "请选择新的 CrossAgnetCoding 数据目录"
        MigrateDataDone = "数据目录已迁移：{0}"
        MigrateDataTitle = "迁移完成"
        Log = "日志"
        Ready = "就绪"
        NodeInstalled = "Node.js - 已安装 {0}"
        NodeMissing = "Node.js - 未安装"
        AgentMemoryInstalled = "AgentMemory - 已安装"
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
        InitialLog1 = "CrossAgnetCoding 已就绪"
        InitialLog2 = "未安装时请点击 [安装全部]"
        InitialLog3 = "安装完成后点击 [启动服务]"
    }
    en = @{
        WindowTitle = "CrossAgnetCoding v0.3.0-mvp"
        Title = "CrossAgnetCoding Cross-Agent Memory Manager"
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
        CopyMcp = "Copy MCP Config to Clipboard"
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
        Configured = "Connected to CrossAgnetCoding"
        NotConfigured = "Not Connected to CrossAgnetCoding"
        UnknownVersion = "Executable, version unknown"
        NotChecked = "Not Checked"
        Scanning = "Scanning…"
        InstallOrExecutableMissing = "not installed or not executable"
        ConfigureTool = "Configure"
        ReconfigureTool = "Reconfigure"
        ToolConfigureDone = "{0} CrossAgnetCoding MCP config written"
        AgentInstalledConfigured = "{0} - Installed / Configured"
        AgentInstalledNotConfigured = "{0} - Installed / Not Configured"
        AgentMissingConfigured = "{0} - Not Detected / Configured"
        AgentMissingNotConfigured = "{0} - Not Installed / Not Configured"
        AgentScanDone = "Coding Agent scan complete"
        AgentConfigureDone = "Coding Agent MCP configuration complete. Restart the tools."
        AgentConfigureTitle = "Configured"
        AgentConfigureBody = "User-level MCP config was written for Codex, TRAE SOLO, OpenCode, Claude, Gemini, OpenClaw, and Hermes when possible. Check the log and restart the tools."
        CopyCliOkBody = "CLI configuration commands copied to clipboard."
        SyncSharedDone = "Shared prompt files synced"
        BridgeWorkspacePrompt = "Choose the project directory to bridge"
        BridgeWorkspaceDone = "Workspace bridge complete: {0}"
        BridgeWorkspaceTitle = "Bridge Complete"
        MigrateDataPrompt = "Choose the new CrossAgnetCoding data directory"
        MigrateDataDone = "Data directory migrated: {0}"
        MigrateDataTitle = "Migration Complete"
        Log = "Log"
        Ready = "Ready"
        NodeInstalled = "Node.js - Installed {0}"
        NodeMissing = "Node.js - Not Installed"
        AgentMemoryInstalled = "AgentMemory - Installed"
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
        InitialLog1 = "CrossAgnetCoding ready"
        InitialLog2 = "Click Install All when dependencies are missing"
        InitialLog3 = "Click Start Service after installation"
    }
}

function T {
    param(
        [string]$Key,
        [object[]]$Args = @()
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
    if ($Args.Count -gt 0) {
        return [string]::Format($value, $Args)
    }
    return $value
}

function Set-ManagerEnv {
    $env:HOME = $env:USERPROFILE

    $parts = @(
        (Join-Path $script:AM_DIR "bin"),
        $script:LOCAL_BIN,
        "C:\Program Files\nodejs",
        $script:NPM_GLOBAL,
        $env:Path
    )

    $env:Path = ($parts | Where-Object { $_ -and $_.Trim().Length -gt 0 }) -join ";"
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
        $nodeSource = Get-CommandPathSafe -Name "node.exe"
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
    try {
        $conn = Get-NetTCPConnection -LocalPort $script:PORT -State Listen -ErrorAction Stop
        return ($null -ne $conn)
    } catch {
        return $false
    }
}

function Get-ServicePids {
    try {
        return @(Get-NetTCPConnection -LocalPort $script:PORT -State Listen -ErrorAction Stop |
            Select-Object -ExpandProperty OwningProcess -Unique |
            Where-Object { $_ -and $_ -gt 0 })
    } catch {
        return @()
    }
}

function Get-EnvironmentStatus {
    Set-ManagerEnv

    $nodeVersion = Get-NodeVersion
    $agentMemoryCmd = Join-Path $script:NPM_GLOBAL "agentmemory.cmd"
    $iiiInAgentMemory = Join-Path $script:AM_DIR "bin\iii.exe"
    $iiiInLocal = Join-Path $script:LOCAL_BIN "iii.exe"

    return [pscustomobject]@{
        Node = ($nodeVersion.Length -gt 0)
        NodeVersion = $nodeVersion
        AgentMemory = (Test-Path -LiteralPath $agentMemoryCmd)
        AgentMemoryCmd = $agentMemoryCmd
        Iii = ((Test-Path -LiteralPath $iiiInAgentMemory) -or (Test-Path -LiteralPath $iiiInLocal))
        IiiPath = $(if (Test-Path -LiteralPath $iiiInAgentMemory) { $iiiInAgentMemory } else { $iiiInLocal })
        Service = (Test-ServiceRunning)
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

    return (Join-Path $env:USERPROFILE ".codex\config.toml")
}

function Get-TraeConfigPath {
    return (Join-Path $env:APPDATA "TRAE SOLO CN\User\mcp.json")
}

function Get-TraeSoloConfigPath {
    return (Join-Path $env:APPDATA "TRAE SOLO\User\mcp.json")
}

function Get-TraeConfigPaths {
    return @(
        (Get-TraeConfigPath),
        (Get-TraeSoloConfigPath)
    )
}

function Get-OpenCodeConfigPath {
    return (Join-Path $env:USERPROFILE ".config\opencode\opencode.json")
}

function Get-ClaudeConfigPath {
    return (Join-Path $env:USERPROFILE ".claude\mcp.json")
}

function Get-ClaudeDesktopConfigPath {
    return (Join-Path $env:APPDATA "Claude\claude_desktop_config.json")
}

function Get-GeminiConfigPath {
    return (Join-Path $env:USERPROFILE ".gemini\settings.json")
}

function Get-OpenClawConfigPath {
    return (Join-Path $env:USERPROFILE ".openclaw\openclaw.json")
}

function Get-HermesConfigPath {
    return (Join-Path $env:USERPROFILE ".hermes\config.yaml")
}

function Get-AgentTargetDefinitions {
    return @(
        [pscustomobject]@{
            Id = "codex"
            Name = "Codex"
            CommandNames = @("codex.exe", "codex")
            InstallRoot = (Split-Path -Parent (Get-CodexConfigPath))
            ConfigPath = Get-CodexConfigPath
            PromptFile = "AGENTS.md"
            ConfigureAction = "Configure-CodexMcp"
        },
        [pscustomobject]@{
            Id = "trae-cn"
            Name = "TRAE SOLO CN"
            CommandNames = @()
            InstallRoot = (Join-Path $env:APPDATA "TRAE SOLO CN")
            ConfigPath = Get-TraeConfigPath
            PromptFile = "TRAE.md"
            ConfigureAction = "Configure-TraeCnMcp"
        },
        [pscustomobject]@{
            Id = "trae"
            Name = "TRAE SOLO"
            CommandNames = @()
            InstallRoot = (Join-Path $env:APPDATA "TRAE SOLO")
            ConfigPath = Get-TraeSoloConfigPath
            PromptFile = "TRAE.md"
            ConfigureAction = "Configure-TraeSoloMcp"
        },
        [pscustomobject]@{
            Id = "claude-code"
            Name = "Claude Code"
            CommandNames = @("claude.exe", "claude")
            InstallRoot = (Join-Path $env:USERPROFILE ".claude")
            ConfigPath = Get-ClaudeConfigPath
            PromptFile = "CLAUDE.md"
            ConfigureAction = "Configure-ClaudeMcp"
        },
        [pscustomobject]@{
            Id = "claude-desktop"
            Name = "Claude Desktop"
            CommandNames = @()
            InstallRoot = (Join-Path $env:APPDATA "Claude")
            ConfigPath = Get-ClaudeDesktopConfigPath
            PromptFile = "CLAUDE.md"
            ConfigureAction = "Configure-ClaudeDesktopMcp"
        },
        [pscustomobject]@{
            Id = "gemini"
            Name = "Gemini CLI"
            CommandNames = @("gemini.exe", "gemini.cmd", "gemini")
            InstallRoot = (Join-Path $env:USERPROFILE ".gemini")
            ConfigPath = Get-GeminiConfigPath
            PromptFile = "GEMINI.md"
            ConfigureAction = "Configure-GeminiMcp"
        },
        [pscustomobject]@{
            Id = "opencode"
            Name = "OpenCode"
            CommandNames = @("opencode.exe", "opencode")
            InstallRoot = (Join-Path $env:USERPROFILE ".config\opencode")
            ConfigPath = Get-OpenCodeConfigPath
            PromptFile = "AGENTS.md"
            ConfigureAction = "Configure-OpenCodeMcp"
        },
        [pscustomobject]@{
            Id = "openclaw"
            Name = "OpenClaw"
            CommandNames = @("openclaw.exe", "openclaw")
            InstallRoot = (Join-Path $env:USERPROFILE ".openclaw")
            ConfigPath = Get-OpenClawConfigPath
            PromptFile = "OPENCLAW.md"
            ConfigureAction = "Configure-OpenClawMcp"
        },
        [pscustomobject]@{
            Id = "hermes"
            Name = "Hermes Agent"
            CommandNames = @("hermes.exe", "hermes")
            InstallRoot = (Join-Path $env:USERPROFILE ".hermes")
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
    return @(
        'claude mcp add-json agentmemory ''' + $mcpJson + '''',
        'codex: add [mcp_servers.agentmemory] to %USERPROFILE%\.codex\config.toml',
        'TRAE SOLO CN: paste mcpServers.agentmemory into %APPDATA%\TRAE SOLO CN\User\mcp.json',
        'TRAE SOLO: paste mcpServers.agentmemory into %APPDATA%\TRAE SOLO\User\mcp.json',
        'Gemini CLI: add mcpServers.agentmemory to %USERPROFILE%\.gemini\settings.json',
        'OpenCode: add mcp.agentmemory to %USERPROFILE%\.config\opencode\opencode.json',
        'OpenClaw: add mcpServers.agentmemory to %USERPROFILE%\.openclaw\openclaw.json',
        'Hermes: add mcp_servers.agentmemory to %USERPROFILE%\.hermes\config.yaml'
    ) -join "`r`n"
}

function Get-AgentClientStatuses {
    $items = New-Object System.Collections.Generic.List[object]

    foreach ($target in Get-AgentTargetDefinitions) {
        $cmd = Get-CommandAny -Names $target.CommandNames
        $configPath = [string]$target.ConfigPath
        $installed = (($null -ne $cmd) -or (Test-Path -LiteralPath $target.InstallRoot) -or (Test-Path -LiteralPath $configPath))
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
            if ($status.CliAvailable) { "CLI + MCP" } else { "MCP config path detected" }
        } else {
            T "InstallOrExecutableMissing"
        }

        [void]$cards.Add([pscustomobject]@{
            Id = $target.Id
            Name = $target.Name
            Platform = "Win"
            Installed = [bool]$status.Installed
            Configured = [bool]$status.Configured
            ConfigPath = $status.ConfigPath
            CurrentVersion = Get-ToolVersionText -CommandInfo $cmd
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
            Platform = "Win"
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

function Get-DefaultCrossAgnetCodingHome {
    return (Join-Path $env:USERPROFILE ".CrossAgnetCoding")
}

function Get-CrossAgnetCodingSettingsPath {
    if (-not [string]::IsNullOrWhiteSpace($env:CROSSAGNETCODING_SETTINGS)) {
        return $env:CROSSAGNETCODING_SETTINGS
    }

    return (Join-Path (Get-DefaultCrossAgnetCodingHome) "settings.json")
}

function Read-CrossAgnetCodingSettings {
    $path = Get-CrossAgnetCodingSettingsPath
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

function Write-CrossAgnetCodingSettings {
    param([object]$Settings)

    $path = Get-CrossAgnetCodingSettingsPath
    $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    Set-Content -LiteralPath $path -Value ($Settings | ConvertTo-Json -Depth 12) -Encoding UTF8
    return $path
}

function Get-CrossAgnetCodingHome {
    if (-not [string]::IsNullOrWhiteSpace($env:CROSSAGNETCODING_HOME)) {
        return [System.IO.Path]::GetFullPath($env:CROSSAGNETCODING_HOME)
    }

    $settings = Read-CrossAgnetCodingSettings
    if ($settings.PSObject.Properties.Name -contains "dataHome" -and -not [string]::IsNullOrWhiteSpace($settings.dataHome)) {
        return [System.IO.Path]::GetFullPath([string]$settings.dataHome)
    }

    return (Get-DefaultCrossAgnetCodingHome)
}

function Move-CrossAgnetCodingHome {
    param(
        [string]$NewHome,
        [switch]$SwitchOnly
    )

    if ([string]::IsNullOrWhiteSpace($NewHome)) {
        throw "New CrossAgnetCoding data directory is required"
    }

    $oldHome = Get-CrossAgnetCodingHome
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

    $settings = Read-CrossAgnetCodingSettings
    if (-not ($settings.PSObject.Properties.Name -contains "dataHome")) {
        $settings | Add-Member -NotePropertyName "dataHome" -NotePropertyValue $targetHome -Force
    } else {
        $settings.dataHome = $targetHome
    }
    $settings | Add-Member -NotePropertyName "updatedAt" -NotePropertyValue ((Get-Date).ToString("o")) -Force
    [void](Write-CrossAgnetCodingSettings -Settings $settings)

    return [pscustomobject]@{
        OldHome = $oldHome
        NewHome = $targetHome
        SettingsPath = Get-CrossAgnetCodingSettingsPath
        Migrated = (-not $SwitchOnly)
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

    return (Join-Path (Join-Path (Get-CrossAgnetCodingHome) "workspaces") (Get-WorkspaceId -ProjectPath $ProjectPath))
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
# CrossAgnetCoding Workspace Handoff

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
        (Join-Path $env:APPDATA "TRAE SOLO CN"),
        (Join-Path $env:APPDATA "TRAE SOLO")
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
# CrossAgnetCoding Shared Agent Context

Use AgentMemory for durable cross-agent context.

AgentMemory MCP endpoint:
http://localhost:3111

Recommended workflow:
1. At task start, search AgentMemory for project goals, decisions, and active constraints.
2. During work, store durable decisions, file paths, test commands, and cross-agent handoff notes.
3. At task end, summarize what changed and write a concise memory entry.

This file is generated by CrossAgnetCoding and inspired by cc-switch style shared agent configuration.
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
    $appHome = Get-CrossAgnetCodingHome
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
        [switch]$Wait
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    $psi.Arguments = $Arguments
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

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
    Write-Output "CrossAgnetCoding CLI MVP"
    Write-Output "Commands:"
    Write-Output "  env tools                       Check local tools and service"
    Write-Output "  agents scan                     List agent connection status"
    Write-Output "  agents configure                Auto-configure AgentMemory MCP"
    Write-Output "  workspace init [path]           Initialize workspace memory"
    Write-Output "  workspace bridge [path]         Import Codex/TRAE bridge summaries"
    Write-Output "  config home                     Show CrossAgnetCoding data directory"
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
        Write-Output (Get-CrossAgnetCodingHome)
        return
    } elseif ($command -match "^config migrate ") {
        if ($CliArgs.Count -lt 3) {
            Write-Error "config migrate requires a target path"
            $script:CliExitCode = 2
            return
        }
        $result = Move-CrossAgnetCodingHome -NewHome $CliArgs[2]
        Write-Output "migrated: $($result.NewHome)"
        return
    }

    Write-CliHelp
    $script:CliExitCode = 2
}

function Invoke-TuiMode {
    while ($true) {
        Write-Host ""
        Write-Host "CrossAgnetCoding TUI MVP"
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
    if ([string]::IsNullOrWhiteSpace((Get-CommandPathSafe -Name "powershell.exe"))) {
        [void]$errors.Add("Get-CommandPathSafe failed to resolve a known executable")
    }
    if ((Get-CommandPathSafe -Name "cac-definitely-missing-cmd-xyz.exe") -ne "") {
        [void]$errors.Add("Get-CommandPathSafe should return empty for a missing command")
    }

    # Placeholder cards must cover every target without scanning so the window can
    # render instantly before status is populated.
    $placeholderCards = @(Get-PlaceholderToolCards)
    if ($placeholderCards.Count -ne (@(Get-AgentTargetDefinitions)).Count) {
        [void]$errors.Add("Placeholder tool cards do not match target definitions")
    }

    # Codex config path must follow CODEX_HOME when it points to an existing
    # directory. The write-test path forces the default location, so this branch
    # is only meaningful outside write-test mode.
    if ($env:AM_MANAGER_WRITE_TEST -ne "1") {
        $codexHomeDir = Join-Path $env:TEMP ("cac-codexhome-" + [guid]::NewGuid().ToString("N"))
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

        $projectDir = Join-Path $env:USERPROFILE "sample-project"
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
            $gitProject = Join-Path $env:USERPROFILE "git-sample-project"
            New-Item -ItemType Directory -Path $gitProject -Force | Out-Null
            & git -C $gitProject init --quiet 2>$null | Out-Null
            $idBeforeRemote = Get-WorkspaceId -ProjectPath $gitProject
            & git -C $gitProject remote add origin "https://example.com/crossagnetcoding.git" 2>$null | Out-Null
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

        $codexSessionDir = Join-Path (Split-Path -Parent (Get-CodexConfigPath)) "sessions\2026"
        New-Item -ItemType Directory -Path $codexSessionDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $codexSessionDir "sample.jsonl") -Value '{"message":"Codex worked on routing"}' -Encoding UTF8
        [void](Import-CodexSessionBridge -ProjectPath $projectDir)

        $traeLogDir = Join-Path $env:APPDATA "TRAE SOLO CN\logs"
        New-Item -ItemType Directory -Path $traeLogDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $traeLogDir "sample.log") -Value "TRAE completed UI review" -Encoding UTF8
        [void](Import-TraeSessionBridge -ProjectPath $projectDir)

        $sessionLines = @(Get-Content -LiteralPath $bridgePath -Encoding UTF8)
        if ($sessionLines.Count -lt 3) {
            [void]$errors.Add("Expected bridge entries from manual, Codex, and TRAE imports")
        }

        $oldHome = Get-CrossAgnetCodingHome
        $markerPath = Join-Path $oldHome "migration-marker.txt"
        if (-not (Test-Path -LiteralPath $oldHome)) {
            New-Item -ItemType Directory -Path $oldHome -Force | Out-Null
        }
        Set-Content -LiteralPath $markerPath -Value "keep me" -Encoding UTF8
        $newHome = Join-Path $env:TEMP ("crossagnetcoding-home-" + [guid]::NewGuid().ToString("N"))
        $migration = Move-CrossAgnetCodingHome -NewHome $newHome
        if ((Get-CrossAgnetCodingHome) -ne $migration.NewHome) {
            [void]$errors.Add("CrossAgnetCoding home did not switch after migration")
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
    $script:LogBox.AppendText("[$ts] $Message`r`n")
    $script:LogBox.SelectionStart = $script:LogBox.TextLength
    $script:LogBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Set-ActionFeedback {
    param(
        [string]$Message,
        [System.Drawing.Color]$Color = [System.Drawing.Color]::Black
    )

    $script:ActionLabel.Text = $Message
    $script:ActionLabel.ForeColor = $Color
    [System.Windows.Forms.Application]::DoEvents()
}

function Set-Busy {
    param([bool]$Busy)

    $script:IsBusy = $Busy
    $script:BtnInstall.Enabled = -not $Busy
    $script:BtnStart.Enabled = -not $Busy
    $script:BtnStop.Enabled = -not $Busy
    $script:BtnMcp.Enabled = -not $Busy
    $script:BtnScanAgents.Enabled = -not $Busy
    $script:BtnConfigureAgents.Enabled = -not $Busy
    $script:BtnCopyCli.Enabled = -not $Busy
    $script:BtnSyncShared.Enabled = -not $Busy
    $script:BtnWorkspaceBridge.Enabled = -not $Busy
    $script:BtnMigrateHome.Enabled = -not $Busy
    $script:LanguageBox.Enabled = -not $Busy
    [System.Windows.Forms.Application]::DoEvents()
}

function Apply-Language {
    $script:Form.Text = T "WindowTitle"
    $script:TitleLabel.Text = T "SettingsTitle"
    $script:AboutHeadingLabel.Text = T "AICodeToolAbout"
    $script:AboutDescriptionLabel.Text = T "AboutDescription"
    $script:ProductNameLabel.Text = "CrossAgnetCoding"
    $script:ProductVersionLabel.Text = "Version $script:APP_VERSION"
    $script:LocalEnvLabel.Text = T "LocalEnvCheck"
    $script:ActionGroup.Text = T "LastAction"
    $script:BtnInstall.Text = T "InstallAll"
    $script:BtnStart.Text = T "StartService"
    $script:BtnStop.Text = T "StopService"
    $script:BtnMcp.Text = T "CopyMcp"
    $script:BtnScanAgents.Text = T "ScanAgents"
    $script:BtnConfigureAgents.Text = T "ConfigureAll"
    $script:BtnUpgradeAll.Text = T "UpgradeAll"
    $script:BtnCopyCli.Text = T "CopyCli"
    $script:BtnSyncShared.Text = T "SyncSharedFiles"
    $script:BtnWorkspaceBridge.Text = T "BridgeWorkspace"
    $script:BtnMigrateHome.Text = T "MigrateDataHome"
    $script:LogGroup.Text = T "Log"
    if ($script:NavButtons -and $script:NavButtons.Count -eq 6) {
        $script:NavButtons[0].Text = T "GeneralTab"
        $script:NavButtons[1].Text = T "RouteTab"
        $script:NavButtons[2].Text = T "AuthTab"
        $script:NavButtons[3].Text = T "AdvancedTab"
        $script:NavButtons[4].Text = T "UsageTab"
        $script:NavButtons[5].Text = T "AboutTab"
    }
}

function Update-Status {
    $status = Get-EnvironmentStatus

    if ($status.Node) {
        $script:NodeLabel.Text = T "NodeInstalled" @($status.NodeVersion)
        $script:NodeLabel.ForeColor = [System.Drawing.Color]::DarkGreen
    } else {
        $script:NodeLabel.Text = T "NodeMissing"
        $script:NodeLabel.ForeColor = [System.Drawing.Color]::Red
    }

    if ($status.AgentMemory) {
        $script:AgentMemoryLabel.Text = T "AgentMemoryInstalled"
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
            try {
                Write-Log "Downloading Node.js..."
                $msi = Join-Path $env:TEMP "agentmemory-node.msi"
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -Uri "https://nodejs.org/dist/v20.11.0/node-v20.11.0-x64.msi" -OutFile $msi -UseBasicParsing
                $result = Invoke-HiddenProcess -FilePath "msiexec.exe" -Arguments "/i `"$msi`" /quiet /norestart" -Wait -TimeoutSeconds 900
                Remove-Item -LiteralPath $msi -Force -ErrorAction SilentlyContinue
                $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")

                if ($result.ExitCode -eq 0 -and (Get-NodeVersion).Length -gt 0) {
                    Write-Log (T "InstallOk" @("Node.js"))
                } else {
                    Write-Log (T "InstallFail" @("Node.js", "exit $($result.ExitCode)"))
                }
            } catch {
                Write-Log (T "InstallFail" @("Node.js", $_.Exception.Message))
            }
        }

        $agentMemoryCmd = Join-Path $script:NPM_GLOBAL "agentmemory.cmd"
        if (Test-Path -LiteralPath $agentMemoryCmd) {
            Write-Log (T "AlreadyInstalled" @("AgentMemory"))
        } elseif ((Get-NodeVersion).Length -eq 0) {
            Write-Log (T "MissingInstallFirst" @("Node.js"))
        } else {
            try {
                Write-Log "Installing AgentMemory..."
                $result = Invoke-HiddenProcess -FilePath "cmd.exe" -Arguments "/d /c npm install -g @agentmemory/agentmemory" -Wait -TimeoutSeconds 900
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

        $iiiInAgentMemory = Join-Path $script:AM_DIR "bin\iii.exe"
        $iiiInLocal = Join-Path $script:LOCAL_BIN "iii.exe"
        if ((Test-Path -LiteralPath $iiiInAgentMemory) -or (Test-Path -LiteralPath $iiiInLocal)) {
            Write-Log (T "AlreadyInstalled" @("iii-engine"))
        } else {
            try {
                Write-Log "Downloading iii-engine..."
                New-Item -ItemType Directory -Path (Join-Path $script:AM_DIR "bin") -Force | Out-Null
                New-Item -ItemType Directory -Path $script:LOCAL_BIN -Force | Out-Null

                $zip = Join-Path $env:TEMP "agentmemory-iii.zip"
                $extractDir = Join-Path $env:TEMP "agentmemory-iii"
                if (Test-Path -LiteralPath $extractDir) {
                    Remove-Item -LiteralPath $extractDir -Recurse -Force
                }

                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -Uri "https://github.com/iii-hq/iii/releases/download/iii/v0.11.2/iii-x86_64-pc-windows-msvc.zip" -OutFile $zip -UseBasicParsing
                Expand-Archive -Path $zip -DestinationPath $extractDir -Force

                $found = Get-ChildItem -LiteralPath $extractDir -Recurse -Filter "iii.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($found) {
                    Copy-Item -LiteralPath $found.FullName -Destination $iiiInLocal -Force
                    Copy-Item -LiteralPath $found.FullName -Destination $iiiInAgentMemory -Force
                }

                Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $extractDir -Recurse -Force -ErrorAction SilentlyContinue

                if ((Test-Path -LiteralPath $iiiInAgentMemory) -or (Test-Path -LiteralPath $iiiInLocal)) {
                    Write-Log (T "InstallOk" @("iii-engine"))
                } else {
                    Write-Log (T "InstallFail" @("iii-engine", "iii.exe not found"))
                }
            } catch {
                Write-Log (T "InstallFail" @("iii-engine", $_.Exception.Message))
            }
        }

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
        if (Test-ServiceRunning) {
            Update-Status
            Set-ActionFeedback (T "Running" @($script:PORT)) ([System.Drawing.Color]::DarkGreen)
            [System.Windows.Forms.MessageBox]::Show((T "StartAlreadyBody" @($script:PORT)), (T "StartAlreadyTitle"), "OK", "Information") | Out-Null
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
        New-Item -ItemType Directory -Path $script:AM_DIR -Force | Out-Null
        Remove-Item -LiteralPath (Join-Path $script:AM_DIR "iii.pid") -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath (Join-Path $script:AM_DIR "engine-state.json") -Force -ErrorAction SilentlyContinue

        $agentMemoryCmd = Join-Path $script:NPM_GLOBAL "agentmemory.cmd"
        $serviceLog = Join-Path $script:AM_DIR "agentmemory-service.log"
        Remove-Item -LiteralPath $serviceLog -Force -ErrorAction SilentlyContinue

        Write-Log (T "StartRequested")
        Write-Log (T "ServiceLog" @($serviceLog))

        $cmdLine = "/d /c `"`"$agentMemoryCmd`" > `"$serviceLog`" 2>&1`""
        Invoke-HiddenProcess -FilePath "cmd.exe" -Arguments $cmdLine | Out-Null

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
            if (Test-Path -LiteralPath $serviceLog) {
                $tail = Get-Content -LiteralPath $serviceLog -Tail 8 -ErrorAction SilentlyContinue
                foreach ($line in $tail) {
                    if ($line) { Write-Log $line }
                }
            }
            [System.Windows.Forms.MessageBox]::Show((T "StartFailBody" @($timeout)), (T "StartFailTitle"), "OK", "Error") | Out-Null
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
        $pids = @(Get-ServicePids)
        $stoppedAny = $false

        foreach ($servicePid in $pids) {
            try {
                Stop-Process -Id $servicePid -Force -ErrorAction Stop
                $stoppedAny = $true
            } catch {
                Write-Log $_.Exception.Message
            }
        }

        Get-Process -Name "iii" -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Stop-Process -Id $_.Id -Force -ErrorAction Stop
                $stoppedAny = $true
            } catch {
            }
        }

        Remove-Item -LiteralPath (Join-Path $script:AM_DIR "iii.pid") -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath (Join-Path $script:AM_DIR "engine-state.json") -Force -ErrorAction SilentlyContinue

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

function Copy-McpConfig {
    [System.Windows.Forms.Clipboard]::SetText((Get-McpConfig))
    Set-ActionFeedback (T "CopyOkBody") ([System.Drawing.Color]::DarkGreen)
    Write-Log (T "CopyOkBody")
    [System.Windows.Forms.MessageBox]::Show((T "CopyOkBody"), (T "CopyOkTitle"), "OK", "Information") | Out-Null
}

function Scan-AgentClients {
    Update-AgentClientStatus
    Set-ActionFeedback (T "AgentScanDone") ([System.Drawing.Color]::DarkGreen)
    Write-Log (T "AgentScanDone")
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
    [System.Windows.Forms.Clipboard]::SetText((Get-CliConfigCommands))
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
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "CrossAgnetCoding", "OK", "Error") | Out-Null
    } finally {
        Set-Busy $false
        $dialog.Dispose()
    }
}

function Migrate-DataHomeFromUi {
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = T "MigrateDataPrompt"
    $dialog.ShowNewFolderButton = $true
    $dialog.SelectedPath = Get-CrossAgnetCodingHome

    try {
        if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            return
        }

        Set-Busy $true
        $result = Move-CrossAgnetCodingHome -NewHome $dialog.SelectedPath
        Write-Log "Data home: $($result.NewHome)"
        Set-ActionFeedback (T "MigrateDataDone" @($result.NewHome)) ([System.Drawing.Color]::DarkGreen)
        [System.Windows.Forms.MessageBox]::Show((T "MigrateDataDone" @($result.NewHome)), (T "MigrateDataTitle"), "OK", "Information") | Out-Null
        [void](Sync-SharedAgentFiles)
    } catch {
        Set-ActionFeedback $_.Exception.Message ([System.Drawing.Color]::Red)
        Write-Log $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "CrossAgnetCoding", "OK", "Error") | Out-Null
    } finally {
        Set-Busy $false
        $dialog.Dispose()
    }
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
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "CrossAgnetCoding", "OK", "Error") | Out-Null
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
    $panel.Size = New-Object System.Drawing.Size(350, 156)
    $panel.Location = New-Object System.Drawing.Point($X, $Y)
    $panel.BackColor = [System.Drawing.Color]::White
    $panel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $nameLabel = New-CardLabel -Text $Card.Name -X 18 -Y 16 -Width 200 -Height 24 -Size 9.5 -Style ([System.Drawing.FontStyle]::Bold)
    $panel.Controls.Add($nameLabel)

    $platformLabel = New-CardLabel -Text $Card.Platform -X 18 -Y 42 -Width 46 -Height 22 -Size 8
    $platformLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $platformLabel.BackColor = [System.Drawing.Color]::FromArgb(230, 244, 255)
    $platformLabel.ForeColor = [System.Drawing.Color]::FromArgb(22, 119, 255)
    $panel.Controls.Add($platformLabel)

    $installLabel = New-CardLabel -Text $Card.InstallStatus -X 245 -Y 18 -Width 82 -Height 22 -Size 8.5
    $installLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
    $panel.Controls.Add($installLabel)

    $currentTitle = New-CardLabel -Text (T "CurrentVersion") -X 18 -Y 76 -Width 84 -Height 20 -Size 8
    $currentTitle.ForeColor = [System.Drawing.Color]::FromArgb(107, 114, 128)
    $panel.Controls.Add($currentTitle)

    $currentValue = New-CardLabel -Text $Card.CurrentVersion -X 212 -Y 76 -Width 116 -Height 20 -Size 8
    $currentValue.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
    $panel.Controls.Add($currentValue)

    $latestTitle = New-CardLabel -Text (T "LatestVersion") -X 18 -Y 98 -Width 84 -Height 20 -Size 8
    $latestTitle.ForeColor = [System.Drawing.Color]::FromArgb(107, 114, 128)
    $panel.Controls.Add($latestTitle)

    $latestValue = New-CardLabel -Text $Card.LatestVersion -X 212 -Y 98 -Width 116 -Height 20 -Size 8
    $latestValue.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
    $panel.Controls.Add($latestValue)

    $detailLabel = New-CardLabel -Text $Card.Detail -X 18 -Y 122 -Width 210 -Height 20 -Size 8
    $detailLabel.ForeColor = [System.Drawing.Color]::FromArgb(107, 114, 128)
    $panel.Controls.Add($detailLabel)

    $actionButton = New-FlatButton -Text $Card.ActionText -X 248 -Y 120 -Width 80 -Height 26
    $actionButton.Tag = $Card.Id
    $actionButton.Add_Click({ Configure-AgentToolFromUi -TargetId ([string]$this.Tag) })
    $panel.Controls.Add($actionButton)

    return [pscustomobject]@{
        Id = $Card.Id
        Panel = $panel
        NameLabel = $nameLabel
        PlatformLabel = $platformLabel
        InstallLabel = $installLabel
        CurrentTitle = $currentTitle
        CurrentValue = $currentValue
        LatestTitle = $latestTitle
        LatestValue = $latestValue
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
        $control.CurrentTitle.Text = T "CurrentVersion"
        $control.CurrentValue.Text = $card.CurrentVersion
        $control.LatestTitle.Text = T "LatestVersion"
        $control.LatestValue.Text = $card.LatestVersion
        $control.DetailLabel.Text = $card.Detail
        $control.ActionButton.Text = $card.ActionText

        if ($card.Configured) {
            $control.InstallLabel.ForeColor = [System.Drawing.Color]::FromArgb(22, 163, 74)
        } elseif ($card.Installed) {
            $control.InstallLabel.ForeColor = [System.Drawing.Color]::FromArgb(217, 119, 6)
        } else {
            $control.InstallLabel.ForeColor = [System.Drawing.Color]::FromArgb(107, 114, 128)
        }
    }

    [System.Windows.Forms.Application]::DoEvents()
}

# GUI mode. The packaged exe launches this script through a hidden window, so a
# terminating error here would otherwise look like "nothing happens" on click.
# Wrap the whole GUI bootstrap so any failure is logged and shown to the user.
try {

$script:Form = New-Object System.Windows.Forms.Form
$script:Form.Size = New-Object System.Drawing.Size(1180, 900)
$script:Form.StartPosition = "CenterScreen"
$script:Form.FormBorderStyle = "FixedSingle"
$script:Form.MaximizeBox = $false
$script:Form.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 250)

$script:HeaderPanel = New-Object System.Windows.Forms.Panel
$script:HeaderPanel.Size = New-Object System.Drawing.Size(1164, 78)
$script:HeaderPanel.Location = New-Object System.Drawing.Point(0, 0)
$script:HeaderPanel.BackColor = [System.Drawing.Color]::White
$script:Form.Controls.Add($script:HeaderPanel)

$script:BackButton = New-FlatButton -Text "<" -X 24 -Y 20 -Width 38 -Height 34
$script:BackButton.Add_Click({
    Update-Status
    Update-AgentClientStatus
    Set-ActionFeedback (T "Ready")
})
$script:HeaderPanel.Controls.Add($script:BackButton)

$script:TitleLabel = New-Object System.Windows.Forms.Label
$script:TitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$script:TitleLabel.Size = New-Object System.Drawing.Size(240, 34)
$script:TitleLabel.Location = New-Object System.Drawing.Point(76, 23)
$script:HeaderPanel.Controls.Add($script:TitleLabel)

$script:LanguageBox = New-Object System.Windows.Forms.ComboBox
$script:LanguageBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$script:LanguageBox.Items.Add("中文") | Out-Null
$script:LanguageBox.Items.Add("English") | Out-Null
$script:LanguageBox.SelectedIndex = 0
$script:LanguageBox.Size = New-Object System.Drawing.Size(110, 26)
$script:LanguageBox.Location = New-Object System.Drawing.Point(1024, 24)
$script:HeaderPanel.Controls.Add($script:LanguageBox)

$script:NavPanel = New-Object System.Windows.Forms.Panel
$script:NavPanel.Size = New-Object System.Drawing.Size(1120, 44)
$script:NavPanel.Location = New-Object System.Drawing.Point(22, 88)
$script:NavPanel.BackColor = [System.Drawing.Color]::White
$script:NavPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$script:Form.Controls.Add($script:NavPanel)

$script:NavButtons = New-Object System.Collections.ArrayList
for ($i = 0; $i -lt 6; $i++) {
    $tabButton = New-FlatButton -Text "" -X (2 + ($i * 186)) -Y 5 -Width 178 -Height 32 -Primary:($i -eq 5)
    if ($i -ne 5) {
        $tabButton.Enabled = $false
        $tabButton.ForeColor = [System.Drawing.Color]::FromArgb(156, 163, 175)
    }
    $script:NavPanel.Controls.Add($tabButton)
    [void]$script:NavButtons.Add($tabButton)
}

$script:AboutHeadingLabel = New-CardLabel -Text "" -X 24 -Y 154 -Width 220 -Height 24 -Size 10.5 -Style ([System.Drawing.FontStyle]::Bold)
$script:Form.Controls.Add($script:AboutHeadingLabel)

$script:AboutDescriptionLabel = New-CardLabel -Text "" -X 24 -Y 180 -Width 520 -Height 22 -Size 8.5
$script:AboutDescriptionLabel.ForeColor = [System.Drawing.Color]::FromArgb(107, 114, 128)
$script:Form.Controls.Add($script:AboutDescriptionLabel)

$script:AboutPanel = New-Object System.Windows.Forms.Panel
$script:AboutPanel.Size = New-Object System.Drawing.Size(1120, 108)
$script:AboutPanel.Location = New-Object System.Drawing.Point(24, 216)
$script:AboutPanel.BackColor = [System.Drawing.Color]::White
$script:AboutPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$script:Form.Controls.Add($script:AboutPanel)

$script:ProductNameLabel = New-CardLabel -Text "" -X 24 -Y 24 -Width 300 -Height 28 -Size 11 -Style ([System.Drawing.FontStyle]::Bold)
$script:AboutPanel.Controls.Add($script:ProductNameLabel)

$script:ProductVersionLabel = New-CardLabel -Text "" -X 24 -Y 58 -Width 180 -Height 22 -Size 8
$script:ProductVersionLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$script:ProductVersionLabel.BackColor = [System.Drawing.Color]::White
$script:ProductVersionLabel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$script:AboutPanel.Controls.Add($script:ProductVersionLabel)

$script:NodeLabel = New-Object System.Windows.Forms.Label
$script:NodeLabel.Size = New-Object System.Drawing.Size(210, 20)
$script:NodeLabel.Location = New-Object System.Drawing.Point(246, 20)
$script:NodeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$script:AboutPanel.Controls.Add($script:NodeLabel)

$script:AgentMemoryLabel = New-Object System.Windows.Forms.Label
$script:AgentMemoryLabel.Size = New-Object System.Drawing.Size(210, 20)
$script:AgentMemoryLabel.Location = New-Object System.Drawing.Point(246, 45)
$script:AgentMemoryLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$script:AboutPanel.Controls.Add($script:AgentMemoryLabel)

$script:IiiLabel = New-Object System.Windows.Forms.Label
$script:IiiLabel.Size = New-Object System.Drawing.Size(210, 20)
$script:IiiLabel.Location = New-Object System.Drawing.Point(246, 70)
$script:IiiLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$script:AboutPanel.Controls.Add($script:IiiLabel)

$script:ServiceLabel = New-Object System.Windows.Forms.Label
$script:ServiceLabel.Size = New-Object System.Drawing.Size(210, 20)
$script:ServiceLabel.Location = New-Object System.Drawing.Point(470, 45)
$script:ServiceLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$script:AboutPanel.Controls.Add($script:ServiceLabel)

$script:BtnInstall = New-FlatButton -Text "" -X 700 -Y 16 -Width 94 -Height 28 -Primary
$script:AboutPanel.Controls.Add($script:BtnInstall)

$script:BtnStart = New-FlatButton -Text "" -X 802 -Y 16 -Width 94 -Height 28
$script:AboutPanel.Controls.Add($script:BtnStart)

$script:BtnStop = New-FlatButton -Text "" -X 904 -Y 16 -Width 94 -Height 28
$script:AboutPanel.Controls.Add($script:BtnStop)

$script:BtnMcp = New-FlatButton -Text "" -X 1006 -Y 16 -Width 94 -Height 28
$script:AboutPanel.Controls.Add($script:BtnMcp)

$script:BtnCopyCli = New-FlatButton -Text "" -X 700 -Y 58 -Width 94 -Height 28
$script:AboutPanel.Controls.Add($script:BtnCopyCli)

$script:BtnSyncShared = New-FlatButton -Text "" -X 802 -Y 58 -Width 94 -Height 28
$script:AboutPanel.Controls.Add($script:BtnSyncShared)

$script:BtnWorkspaceBridge = New-FlatButton -Text "" -X 904 -Y 58 -Width 94 -Height 28
$script:AboutPanel.Controls.Add($script:BtnWorkspaceBridge)

$script:BtnMigrateHome = New-FlatButton -Text "" -X 1006 -Y 58 -Width 94 -Height 28
$script:AboutPanel.Controls.Add($script:BtnMigrateHome)

$script:LocalEnvLabel = New-CardLabel -Text "" -X 24 -Y 356 -Width 240 -Height 26 -Size 10.5 -Style ([System.Drawing.FontStyle]::Bold)
$script:Form.Controls.Add($script:LocalEnvLabel)

$script:BtnScanAgents = New-FlatButton -Text "" -X 828 -Y 350 -Width 96 -Height 28
$script:Form.Controls.Add($script:BtnScanAgents)

$script:BtnConfigureAgents = New-FlatButton -Text "" -X 934 -Y 350 -Width 96 -Height 28
$script:Form.Controls.Add($script:BtnConfigureAgents)

$script:BtnUpgradeAll = New-FlatButton -Text (T "UpgradeAll") -X 1040 -Y 350 -Width 104 -Height 28 -Primary
$script:BtnUpgradeAll.Enabled = $false
$script:Form.Controls.Add($script:BtnUpgradeAll)

$script:ToolCardsPanel = New-Object System.Windows.Forms.Panel
$script:ToolCardsPanel.Size = New-Object System.Drawing.Size(1120, 360)
$script:ToolCardsPanel.Location = New-Object System.Drawing.Point(24, 390)
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
    $y = $row * 172
    $cardControl = New-ToolCardControl -Card $initialCards[$i] -X $x -Y $y
    $script:ToolCardsPanel.Controls.Add($cardControl.Panel)
    [void]$script:ToolCardControls.Add($cardControl)
}

$script:ActionGroup = New-Object System.Windows.Forms.GroupBox
$script:ActionGroup.Size = New-Object System.Drawing.Size(570, 58)
$script:ActionGroup.Location = New-Object System.Drawing.Point(24, 766)
$script:Form.Controls.Add($script:ActionGroup)

$script:ActionLabel = New-Object System.Windows.Forms.Label
$script:ActionLabel.Size = New-Object System.Drawing.Size(535, 28)
$script:ActionLabel.Location = New-Object System.Drawing.Point(14, 22)
$script:ActionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$script:ActionGroup.Controls.Add($script:ActionLabel)

$script:LogGroup = New-Object System.Windows.Forms.GroupBox
$script:LogGroup.Size = New-Object System.Drawing.Size(530, 58)
$script:LogGroup.Location = New-Object System.Drawing.Point(614, 766)
$script:Form.Controls.Add($script:LogGroup)

$script:LogBox = New-Object System.Windows.Forms.TextBox
$script:LogBox.Multiline = $true
$script:LogBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$script:LogBox.ReadOnly = $true
$script:LogBox.Font = New-Object System.Drawing.Font("Consolas", 8)
$script:LogBox.Size = New-Object System.Drawing.Size(506, 30)
$script:LogBox.Location = New-Object System.Drawing.Point(12, 20)
$script:LogBox.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$script:LogBox.ForeColor = [System.Drawing.Color]::FromArgb(200, 255, 200)
$script:LogGroup.Controls.Add($script:LogBox)

$script:LanguageBox.Add_SelectedIndexChanged({
    if ($script:LanguageBox.SelectedIndex -eq 1) {
        $script:Language = "en"
    } else {
        $script:Language = "zh"
    }
    Apply-Language
    Update-Status
    Update-ToolCardControls
    Set-ActionFeedback (T "Ready")
})

$script:BtnInstall.Add_Click({ Install-All })
$script:BtnStart.Add_Click({ Start-AgentMemory })
$script:BtnStop.Add_Click({ Stop-AgentMemory })
$script:BtnMcp.Add_Click({ Copy-McpConfig })
$script:BtnScanAgents.Add_Click({ Scan-AgentClients })
$script:BtnConfigureAgents.Add_Click({ Configure-AgentClients })
$script:BtnCopyCli.Add_Click({ Copy-CliCommands })
$script:BtnSyncShared.Add_Click({ Sync-SharedFilesFromUi })
$script:BtnWorkspaceBridge.Add_Click({ Bridge-WorkspaceFromUi })
$script:BtnMigrateHome.Add_Click({ Migrate-DataHomeFromUi })

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 5000
$timer.Add_Tick({
    if (-not $script:IsBusy) {
        Update-Status
        Update-AgentClientStatus
    }
})
$timer.Start()

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

[void]$script:Form.ShowDialog()

} catch {
    $logPath = Join-Path ([System.IO.Path]::GetTempPath()) "CrossAgnetCoding-error.log"
    $detail = "[" + (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + "] CrossAgnetCoding startup failed`r`n" +
        ($_ | Out-String) + "`r`n" + [string]$_.ScriptStackTrace
    try { Set-Content -LiteralPath $logPath -Value $detail -Encoding UTF8 } catch {}
    try {
        [System.Windows.Forms.MessageBox]::Show(
            "CrossAgnetCoding 启动失败 / failed to start:`r`n`r`n" + ($_ | Out-String) +
                "`r`n日志 / Log: $logPath",
            "CrossAgnetCoding",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    } catch {}
    # The user has already been notified above, so exit 0 to avoid the launcher
    # showing a second, redundant failure dialog.
    exit 0
}




