$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$script = Join-Path $root "src\AgentMemoryManager.ps1"
$source = Get-Content -LiteralPath $script -Raw -Encoding UTF8

foreach ($requiredSafeNode in @(
    '$script:NodeVersionCache',
    '$script:NodeVersionCacheTime',
    '$script:NodeVersionFailureTime',
    'CAC_TEST_NO_NODE_EXEC',
    'Get-NodeVersionFromFile'
)) {
    if ($source -notmatch [regex]::Escape($requiredSafeNode)) {
        throw "Missing safe Node detection feature: $requiredSafeNode"
    }
}

foreach ($requiredTargetFeature in @(
    "function Get-AgentTargetDefinitions",
    'Id = "trae-cn"',
    'Id = "trae"',
    'Id = "claude-code"',
    'Id = "claude-desktop"',
    'Id = "gemini"',
    'Id = "openclaw"',
    'Id = "hermes"',
    "function Get-TraeConfigPaths",
    "function Configure-ClaudeDesktopMcp",
    "function Configure-GeminiMcp",
    "function Configure-OpenClawMcp",
    "function Configure-HermesMcp"
)) {
    if ($source -notmatch [regex]::Escape($requiredTargetFeature)) {
        throw "Missing MVP target feature: $requiredTargetFeature"
    }
}

foreach ($requiredStartupFeature in @(
    "function Get-CommandPathSafe",
    "function Get-PlaceholderToolCards",
    "Add_Shown",
    "InitialScanTimer"
)) {
    if ($source -notmatch [regex]::Escape($requiredStartupFeature)) {
        throw "Missing non-blocking startup feature: $requiredStartupFeature"
    }
}

foreach ($requiredWorkspaceFeature in @(
    "function Get-WorkspaceId",
    "function Get-ProjectGitRemote",
    "function Get-WorkspacePath",
    "function Initialize-WorkspaceMemory",
    "function Add-SessionBridgeEntry",
    "function Sync-WorkspacePromptFiles",
    "function Import-CodexSessionBridge",
    "function Import-TraeSessionBridge",
    "sessions.jsonl",
    "handoff.md"
)) {
    if ($source -notmatch [regex]::Escape($requiredWorkspaceFeature)) {
        throw "Missing workspace bridge feature: $requiredWorkspaceFeature"
    }
}

foreach ($requiredHomeFeature in @(
    "function Get-CrossAgnetCodingSettingsPath",
    "function Read-CrossAgnetCodingSettings",
    "function Write-CrossAgnetCodingSettings",
    "function Move-CrossAgnetCodingHome",
    "CROSSAGNETCODING_HOME",
    "dataHome"
)) {
    if ($source -notmatch [regex]::Escape($requiredHomeFeature)) {
        throw "Missing data home feature: $requiredHomeFeature"
    }
}

foreach ($requiredCliFeature in @(
    "function Invoke-CliMode",
    "function Invoke-TuiMode",
    "env tools",
    "agents configure",
    "workspace init",
    "workspace bridge",
    "config migrate",
    '[switch]$Cli',
    "[switch]$Tui",
    "[switch]$UiSmokeTest"
)) {
    if ($source -notmatch [regex]::Escape($requiredCliFeature)) {
        throw "Missing CLI/TUI feature: $requiredCliFeature"
    }
}

foreach ($requiredAboutUiFeature in @(
    "function Get-AgentToolCards",
    "function New-ToolCardControl",
    "function Update-ToolCardControls",
    '$script:AboutPanel',
    '$script:ToolCardsPanel',
    '$script:ToolCardControls',
    "LocalEnvCheck",
    "CurrentVersion",
    "LatestVersion",
    "AICodeToolAbout"
)) {
    if ($source -notmatch [regex]::Escape($requiredAboutUiFeature)) {
        throw "Missing about/local environment UI feature: $requiredAboutUiFeature"
    }
}

$oldNoNodeExec = $env:CAC_TEST_NO_NODE_EXEC
$env:CAC_TEST_NO_NODE_EXEC = "1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script -SelfTest

if ($LASTEXITCODE -ne 0) {
    throw "AgentMemoryManager self-test failed with exit code $LASTEXITCODE"
}

$uiSmokeOutput = powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script -UiSmokeTest
if ($LASTEXITCODE -ne 0 -or (($uiSmokeOutput -join "`n") -notmatch "UI_SMOKE_OK")) {
    throw "AgentMemoryManager UI smoke test failed"
}

$tempRoot = Join-Path $env:TEMP ("agentmemory-manager-test-" + [guid]::NewGuid().ToString("N"))
$tempUser = Join-Path $tempRoot "user"
$tempAppData = Join-Path $tempRoot "appdata"
New-Item -ItemType Directory -Path $tempUser, $tempAppData | Out-Null

try {
    $oldUserProfile = $env:USERPROFILE
    $oldAppData = $env:APPDATA
    $oldWriteTest = $env:AM_MANAGER_WRITE_TEST
    $oldNoNodeExecInner = $env:CAC_TEST_NO_NODE_EXEC
    $env:USERPROFILE = $tempUser
    $env:APPDATA = $tempAppData
    $env:AM_MANAGER_WRITE_TEST = "1"
    $env:CAC_TEST_NO_NODE_EXEC = "1"

    powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script -SelfTest

    if ($LASTEXITCODE -ne 0) {
        throw "AgentMemoryManager config writer self-test failed with exit code $LASTEXITCODE"
    }
} finally {
    $env:USERPROFILE = $oldUserProfile
    $env:APPDATA = $oldAppData
    $env:AM_MANAGER_WRITE_TEST = $oldWriteTest
    $env:CAC_TEST_NO_NODE_EXEC = $oldNoNodeExecInner
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

$env:CAC_TEST_NO_NODE_EXEC = $oldNoNodeExec

foreach ($required in @(
    '$script:APP_NAME = "CrossAgnetCoding"',
    '$script:APP_VERSION = "0.3.0-mvp"',
    "function Get-AgentClientStatuses",
    "function Get-AgentTargetDefinitions",
    "function Configure-CodexMcp",
    "function Configure-TraeMcp",
    "function Configure-ClaudeDesktopMcp",
    "function Configure-GeminiMcp",
    "function Configure-OpenClawMcp",
    "function Configure-HermesMcp",
    "function Configure-OpenCodeMcp",
    "function Configure-ClaudeMcp",
    "function Get-CliConfigCommands",
    "function Get-SharedPromptContent",
    "function Sync-SharedAgentFiles",
    "function Get-WorkspaceId",
    "function Initialize-WorkspaceMemory",
    "function Add-SessionBridgeEntry",
    "function Import-CodexSessionBridge",
    "function Import-TraeSessionBridge",
    "function Move-CrossAgnetCodingHome",
    "function Bridge-WorkspaceFromUi",
    "function Migrate-DataHomeFromUi",
    "function Get-AgentToolCards",
    "function New-ToolCardControl",
    "function Update-ToolCardControls",
    "function Invoke-CliMode",
    "function Invoke-TuiMode",
    '$script:AboutPanel',
    '$script:ToolCardsPanel',
    '$script:ToolCardControls',
    '$script:BtnWorkspaceBridge',
    '$script:BtnMigrateHome',
    "function Get-CcSwitchInspiredFeatures",
    "CodingAgentAccess"
)) {
    if ($source -notmatch [regex]::Escape($required)) {
        throw "Missing required source feature: $required"
    }
}

$readme = Get-Content -LiteralPath (Join-Path $root "README.md") -Raw -Encoding UTF8
foreach ($requiredReadme in @(
    "# CrossAgnetCoding",
    "Version: 0.3.0-mvp",
    "CrossAgnetCoding.exe",
    "https://github.com/rohitg00/agentmemory",
    "https://github.com/farion1231/cc-switch",
    "Usage"
)) {
    if ($readme -notmatch [regex]::Escape($requiredReadme)) {
        throw "README missing required content: $requiredReadme"
    }
}

$buildScript = Get-Content -LiteralPath (Join-Path $root "scripts\build.ps1") -Raw -Encoding UTF8
if ($buildScript -notmatch [regex]::Escape("CrossAgnetCoding.exe")) {
    throw "Build script does not output CrossAgnetCoding.exe"
}

Write-Host "SOURCE_FEATURES_OK"
