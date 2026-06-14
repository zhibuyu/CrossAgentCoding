param(
    [switch]$SelfTest
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Continue"

$script:AM_DIR = Join-Path $env:USERPROFILE ".agentmemory"
$script:LOCAL_BIN = Join-Path $env:USERPROFILE ".local\bin"
$script:NPM_GLOBAL = Join-Path $env:APPDATA "npm"
$script:PORT = 3111
$script:Language = "zh"
$script:IsBusy = $false

$script:Text = @{
    zh = @{
        WindowTitle = "AgentMemory 管理器 v1.1"
        Title = "AgentMemory 共享记忆管理器"
        EnvCheck = "环境检查"
        ServiceStatus = "服务状态"
        LastAction = "操作反馈"
        InstallAll = "安装全部"
        StartService = "启动服务"
        StopService = "停止服务"
        CopyMcp = "复制 MCP 配置到剪贴板"
        CodingAgentAccess = "Coding Agent 接入"
        ScanAgents = "扫描 Agent"
        ConfigureAgents = "一键配置 MCP"
        CopyCli = "复制 CLI 命令"
        AgentInstalledConfigured = "{0} - 已安装 / 已配置"
        AgentInstalledNotConfigured = "{0} - 已安装 / 未配置"
        AgentMissingConfigured = "{0} - 未检测到安装 / 已有配置"
        AgentMissingNotConfigured = "{0} - 未安装 / 未配置"
        AgentScanDone = "Coding Agent 扫描完成"
        AgentConfigureDone = "Coding Agent MCP 配置完成，请重启对应工具"
        AgentConfigureTitle = "配置完成"
        AgentConfigureBody = "已尝试写入 Codex、TRAE SOLO CN、OpenCode、Claude Code 的用户级 MCP 配置。请查看日志并重启对应工具。"
        CopyCliOkBody = "CLI 配置命令已复制到剪贴板。"
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
        InitialLog1 = "AgentMemory 管理器已就绪"
        InitialLog2 = "未安装时请点击 [安装全部]"
        InitialLog3 = "安装完成后点击 [启动服务]"
    }
    en = @{
        WindowTitle = "AgentMemory Manager v1.1"
        Title = "AgentMemory Shared Memory Manager"
        EnvCheck = "Environment Check"
        ServiceStatus = "Service Status"
        LastAction = "Action Feedback"
        InstallAll = "Install All"
        StartService = "Start Service"
        StopService = "Stop Service"
        CopyMcp = "Copy MCP Config to Clipboard"
        CodingAgentAccess = "Coding Agent Access"
        ScanAgents = "Scan Agents"
        ConfigureAgents = "Configure MCP"
        CopyCli = "Copy CLI Commands"
        AgentInstalledConfigured = "{0} - Installed / Configured"
        AgentInstalledNotConfigured = "{0} - Installed / Not Configured"
        AgentMissingConfigured = "{0} - Not Detected / Configured"
        AgentMissingNotConfigured = "{0} - Not Installed / Not Configured"
        AgentScanDone = "Coding Agent scan complete"
        AgentConfigureDone = "Coding Agent MCP configuration complete. Restart the tools."
        AgentConfigureTitle = "Configured"
        AgentConfigureBody = "User-level MCP config was written for Codex, TRAE SOLO CN, OpenCode, and Claude Code when possible. Check the log and restart the tools."
        CopyCliOkBody = "CLI configuration commands copied to clipboard."
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
        InitialLog1 = "AgentMemory Manager ready"
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

function Get-NodeVersion {
    try {
        $cmd = Get-Command node.exe -ErrorAction Stop
        $version = & $cmd.Source -v 2>$null
        if ($LASTEXITCODE -eq 0 -and $version) {
            return [string]$version
        }
    } catch {
    }

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

function Get-CodexConfigPath {
    return (Join-Path $env:USERPROFILE ".codex\config.toml")
}

function Get-TraeConfigPath {
    return (Join-Path $env:APPDATA "TRAE SOLO CN\User\mcp.json")
}

function Get-OpenCodeConfigPath {
    return (Join-Path $env:USERPROFILE ".config\opencode\opencode.json")
}

function Get-ClaudeConfigPath {
    return (Join-Path $env:USERPROFILE ".claude\mcp.json")
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

function Configure-TraeMcp {
    $path = Get-TraeConfigPath
    $config = Read-JsonObject -Path $path
    $servers = Ensure-PropertyObject -Object $config -Name "mcpServers"
    $servers | Add-Member -NotePropertyName "agentmemory" -NotePropertyValue ([pscustomobject](Get-AgentMemoryServerObject)) -Force
    Write-JsonObject -Path $path -Object $config
    return $path
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
    $path = Get-ClaudeConfigPath
    $config = Read-JsonObject -Path $path
    $servers = Ensure-PropertyObject -Object $config -Name "mcpServers"
    $servers | Add-Member -NotePropertyName "agentmemory" -NotePropertyValue ([pscustomobject](Get-AgentMemoryServerObject)) -Force
    Write-JsonObject -Path $path -Object $config
    return $path
}

function Get-CliConfigCommands {
    $mcpJson = '{"command":"npx","args":["-y","@agentmemory/mcp"],"env":{"AGENTMEMORY_URL":"http://localhost:3111"}}'
    return @(
        'claude mcp add-json agentmemory ''' + $mcpJson + '''',
        'codex: add [mcp_servers.agentmemory] to %USERPROFILE%\.codex\config.toml',
        'TRAE SOLO CN: paste mcpServers.agentmemory into %APPDATA%\TRAE SOLO CN\User\mcp.json',
        'OpenCode: add mcp.agentmemory to %USERPROFILE%\.config\opencode\opencode.json'
    ) -join "`r`n"
}

function Get-AgentClientStatuses {
    $codexPath = Get-CodexConfigPath
    $traePath = Get-TraeConfigPath
    $openCodePath = Get-OpenCodeConfigPath
    $claudePath = Get-ClaudeConfigPath

    $codexCmd = Get-Command codex.exe -ErrorAction SilentlyContinue
    $openCodeCmd = Get-Command opencode -ErrorAction SilentlyContinue
    $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue

    $items = @(
        [pscustomobject]@{
            Id = "codex"
            Name = "Codex"
            Installed = (($null -ne $codexCmd) -or (Test-Path -LiteralPath $codexPath))
            CliAvailable = ($null -ne $codexCmd)
            ConfigPath = $codexPath
            Configured = (Test-Path -LiteralPath $codexPath) -and (Test-AgentMemoryTextConfigured (Get-Content -LiteralPath $codexPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue))
        },
        [pscustomobject]@{
            Id = "trae"
            Name = "TRAE SOLO CN"
            Installed = (Test-Path -LiteralPath (Join-Path $env:APPDATA "TRAE SOLO CN"))
            CliAvailable = $false
            ConfigPath = $traePath
            Configured = (Test-Path -LiteralPath $traePath) -and (Test-AgentMemoryTextConfigured (Get-Content -LiteralPath $traePath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue))
        },
        [pscustomobject]@{
            Id = "opencode"
            Name = "OpenCode"
            Installed = (($null -ne $openCodeCmd) -or (Test-Path -LiteralPath $openCodePath))
            CliAvailable = ($null -ne $openCodeCmd)
            ConfigPath = $openCodePath
            Configured = (Test-Path -LiteralPath $openCodePath) -and (Test-AgentMemoryTextConfigured (Get-Content -LiteralPath $openCodePath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue))
        },
        [pscustomobject]@{
            Id = "claude"
            Name = "Claude Code"
            Installed = (($null -ne $claudeCmd) -or (Test-Path -LiteralPath (Join-Path $env:USERPROFILE ".claude")))
            CliAvailable = ($null -ne $claudeCmd)
            ConfigPath = $claudePath
            Configured = (Test-Path -LiteralPath $claudePath) -and (Test-AgentMemoryTextConfigured (Get-Content -LiteralPath $claudePath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue))
        }
    )

    foreach ($item in $items) {
        $detail = if ($item.CliAvailable) { "CLI + MCP" } elseif ($item.Installed) { "MCP" } else { "not detected" }
        $item | Add-Member -NotePropertyName "Details" -NotePropertyValue $detail -Force
    }

    return $items
}

function Configure-AllAgentClients {
    $paths = New-Object System.Collections.Generic.List[string]
    [void]$paths.Add((Configure-CodexMcp))
    [void]$paths.Add((Configure-TraeMcp))
    [void]$paths.Add((Configure-OpenCodeMcp))
    [void]$paths.Add((Configure-ClaudeMcp))
    return @($paths)
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

    $clients = @(Get-AgentClientStatuses)
    foreach ($id in @("codex", "trae", "opencode", "claude")) {
        if (-not ($clients | Where-Object { $_.Id -eq $id })) {
            [void]$errors.Add("Missing client definition: $id")
        }
    }

    $cliCommands = Get-CliConfigCommands
    foreach ($needle in @("claude mcp add-json", "Codex", "TRAE SOLO CN", "OpenCode", "localhost:3111")) {
        if ($cliCommands -notmatch [regex]::Escape($needle)) {
            [void]$errors.Add("CLI commands missing: $needle")
        }
    }

    if ($env:AM_MANAGER_WRITE_TEST -eq "1") {
        $paths = @(Configure-AllAgentClients)
        if ($paths.Count -ne 4) {
            [void]$errors.Add("Expected 4 config paths from Configure-AllAgentClients")
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
    }

    if ($errors.Count -gt 0) {
        $errors | ForEach-Object { Write-Error $_ }
        exit 1
    }

    Write-Output "SELFTEST OK"
    exit 0
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
    $script:LanguageBox.Enabled = -not $Busy
    [System.Windows.Forms.Application]::DoEvents()
}

function Apply-Language {
    $script:Form.Text = T "WindowTitle"
    $script:TitleLabel.Text = T "Title"
    $script:EnvGroup.Text = T "EnvCheck"
    $script:ServiceGroup.Text = T "ServiceStatus"
    $script:ActionGroup.Text = T "LastAction"
    $script:BtnInstall.Text = T "InstallAll"
    $script:BtnStart.Text = T "StartService"
    $script:BtnStop.Text = T "StopService"
    $script:BtnMcp.Text = T "CopyMcp"
    $script:AgentGroup.Text = T "CodingAgentAccess"
    $script:BtnScanAgents.Text = T "ScanAgents"
    $script:BtnConfigureAgents.Text = T "ConfigureAgents"
    $script:BtnCopyCli.Text = T "CopyCli"
    $script:LogGroup.Text = T "Log"
    Update-Status
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

$script:Form = New-Object System.Windows.Forms.Form
$script:Form.Size = New-Object System.Drawing.Size(620, 720)
$script:Form.StartPosition = "CenterScreen"
$script:Form.FormBorderStyle = "FixedSingle"
$script:Form.MaximizeBox = $false
$script:Form.BackColor = [System.Drawing.Color]::White

$script:TitleLabel = New-Object System.Windows.Forms.Label
$script:TitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$script:TitleLabel.Size = New-Object System.Drawing.Size(430, 34)
$script:TitleLabel.Location = New-Object System.Drawing.Point(20, 14)
$script:Form.Controls.Add($script:TitleLabel)

$script:LanguageBox = New-Object System.Windows.Forms.ComboBox
$script:LanguageBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$script:LanguageBox.Items.Add("中文") | Out-Null
$script:LanguageBox.Items.Add("English") | Out-Null
$script:LanguageBox.SelectedIndex = 0
$script:LanguageBox.Size = New-Object System.Drawing.Size(110, 26)
$script:LanguageBox.Location = New-Object System.Drawing.Point(480, 17)
$script:Form.Controls.Add($script:LanguageBox)

$script:EnvGroup = New-Object System.Windows.Forms.GroupBox
$script:EnvGroup.Size = New-Object System.Drawing.Size(570, 112)
$script:EnvGroup.Location = New-Object System.Drawing.Point(20, 58)
$script:Form.Controls.Add($script:EnvGroup)

$script:NodeLabel = New-Object System.Windows.Forms.Label
$script:NodeLabel.Size = New-Object System.Drawing.Size(535, 24)
$script:NodeLabel.Location = New-Object System.Drawing.Point(14, 24)
$script:NodeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$script:EnvGroup.Controls.Add($script:NodeLabel)

$script:AgentMemoryLabel = New-Object System.Windows.Forms.Label
$script:AgentMemoryLabel.Size = New-Object System.Drawing.Size(535, 24)
$script:AgentMemoryLabel.Location = New-Object System.Drawing.Point(14, 52)
$script:AgentMemoryLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$script:EnvGroup.Controls.Add($script:AgentMemoryLabel)

$script:IiiLabel = New-Object System.Windows.Forms.Label
$script:IiiLabel.Size = New-Object System.Drawing.Size(535, 24)
$script:IiiLabel.Location = New-Object System.Drawing.Point(14, 80)
$script:IiiLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$script:EnvGroup.Controls.Add($script:IiiLabel)

$script:ServiceGroup = New-Object System.Windows.Forms.GroupBox
$script:ServiceGroup.Size = New-Object System.Drawing.Size(570, 58)
$script:ServiceGroup.Location = New-Object System.Drawing.Point(20, 180)
$script:Form.Controls.Add($script:ServiceGroup)

$script:ServiceLabel = New-Object System.Windows.Forms.Label
$script:ServiceLabel.Size = New-Object System.Drawing.Size(535, 28)
$script:ServiceLabel.Location = New-Object System.Drawing.Point(14, 22)
$script:ServiceLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$script:ServiceGroup.Controls.Add($script:ServiceLabel)

$script:BtnInstall = New-Object System.Windows.Forms.Button
$script:BtnInstall.Size = New-Object System.Drawing.Size(175, 42)
$script:BtnInstall.Location = New-Object System.Drawing.Point(20, 252)
$script:BtnInstall.BackColor = [System.Drawing.Color]::FromArgb(33, 150, 243)
$script:BtnInstall.ForeColor = [System.Drawing.Color]::White
$script:BtnInstall.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$script:BtnInstall.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$script:Form.Controls.Add($script:BtnInstall)

$script:BtnStart = New-Object System.Windows.Forms.Button
$script:BtnStart.Size = New-Object System.Drawing.Size(175, 42)
$script:BtnStart.Location = New-Object System.Drawing.Point(217, 252)
$script:BtnStart.BackColor = [System.Drawing.Color]::FromArgb(76, 175, 80)
$script:BtnStart.ForeColor = [System.Drawing.Color]::White
$script:BtnStart.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$script:BtnStart.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$script:Form.Controls.Add($script:BtnStart)

$script:BtnStop = New-Object System.Windows.Forms.Button
$script:BtnStop.Size = New-Object System.Drawing.Size(175, 42)
$script:BtnStop.Location = New-Object System.Drawing.Point(415, 252)
$script:BtnStop.BackColor = [System.Drawing.Color]::FromArgb(244, 67, 54)
$script:BtnStop.ForeColor = [System.Drawing.Color]::White
$script:BtnStop.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$script:BtnStop.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$script:Form.Controls.Add($script:BtnStop)

$script:BtnMcp = New-Object System.Windows.Forms.Button
$script:BtnMcp.Size = New-Object System.Drawing.Size(570, 34)
$script:BtnMcp.Location = New-Object System.Drawing.Point(20, 304)
$script:BtnMcp.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$script:BtnMcp.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$script:Form.Controls.Add($script:BtnMcp)

$script:AgentGroup = New-Object System.Windows.Forms.GroupBox
$script:AgentGroup.Size = New-Object System.Drawing.Size(570, 124)
$script:AgentGroup.Location = New-Object System.Drawing.Point(20, 348)
$script:Form.Controls.Add($script:AgentGroup)

$script:AgentLabels = New-Object System.Collections.ArrayList
$agentNames = @("Codex", "TRAE SOLO CN", "OpenCode", "Claude Code")
for ($i = 0; $i -lt $agentNames.Count; $i++) {
    $label = New-Object System.Windows.Forms.Label
    $label.Size = New-Object System.Drawing.Size(350, 21)
    $label.Location = New-Object System.Drawing.Point(14, (22 + ($i * 22)))
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $label.Text = $agentNames[$i]
    $script:AgentGroup.Controls.Add($label)
    [void]$script:AgentLabels.Add($label)
}

$script:BtnScanAgents = New-Object System.Windows.Forms.Button
$script:BtnScanAgents.Size = New-Object System.Drawing.Size(170, 28)
$script:BtnScanAgents.Location = New-Object System.Drawing.Point(386, 20)
$script:BtnScanAgents.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$script:BtnScanAgents.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$script:AgentGroup.Controls.Add($script:BtnScanAgents)

$script:BtnConfigureAgents = New-Object System.Windows.Forms.Button
$script:BtnConfigureAgents.Size = New-Object System.Drawing.Size(170, 28)
$script:BtnConfigureAgents.Location = New-Object System.Drawing.Point(386, 52)
$script:BtnConfigureAgents.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$script:BtnConfigureAgents.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$script:AgentGroup.Controls.Add($script:BtnConfigureAgents)

$script:BtnCopyCli = New-Object System.Windows.Forms.Button
$script:BtnCopyCli.Size = New-Object System.Drawing.Size(170, 28)
$script:BtnCopyCli.Location = New-Object System.Drawing.Point(386, 84)
$script:BtnCopyCli.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$script:BtnCopyCli.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$script:AgentGroup.Controls.Add($script:BtnCopyCli)

$script:ActionGroup = New-Object System.Windows.Forms.GroupBox
$script:ActionGroup.Size = New-Object System.Drawing.Size(570, 58)
$script:ActionGroup.Location = New-Object System.Drawing.Point(20, 482)
$script:Form.Controls.Add($script:ActionGroup)

$script:ActionLabel = New-Object System.Windows.Forms.Label
$script:ActionLabel.Size = New-Object System.Drawing.Size(535, 28)
$script:ActionLabel.Location = New-Object System.Drawing.Point(14, 22)
$script:ActionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$script:ActionGroup.Controls.Add($script:ActionLabel)

$script:LogGroup = New-Object System.Windows.Forms.GroupBox
$script:LogGroup.Size = New-Object System.Drawing.Size(570, 102)
$script:LogGroup.Location = New-Object System.Drawing.Point(20, 550)
$script:Form.Controls.Add($script:LogGroup)

$script:LogBox = New-Object System.Windows.Forms.TextBox
$script:LogBox.Multiline = $true
$script:LogBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$script:LogBox.ReadOnly = $true
$script:LogBox.Font = New-Object System.Drawing.Font("Consolas", 8)
$script:LogBox.Size = New-Object System.Drawing.Size(546, 74)
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
    Set-ActionFeedback (T "Ready")
})

$script:BtnInstall.Add_Click({ Install-All })
$script:BtnStart.Add_Click({ Start-AgentMemory })
$script:BtnStop.Add_Click({ Stop-AgentMemory })
$script:BtnMcp.Add_Click({ Copy-McpConfig })
$script:BtnScanAgents.Add_Click({ Scan-AgentClients })
$script:BtnConfigureAgents.Add_Click({ Configure-AgentClients })
$script:BtnCopyCli.Add_Click({ Copy-CliCommands })

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
Update-AgentClientStatus
Set-ActionFeedback (T "Ready")
Write-Log (T "InitialLog1")
Write-Log (T "InitialLog2")
Write-Log (T "InitialLog3")

[void]$script:Form.ShowDialog()




