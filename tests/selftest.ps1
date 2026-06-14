$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$script = Join-Path $root "src\AgentMemoryManager.ps1"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script -SelfTest

if ($LASTEXITCODE -ne 0) {
    throw "AgentMemoryManager self-test failed with exit code $LASTEXITCODE"
}

$tempRoot = Join-Path $env:TEMP ("agentmemory-manager-test-" + [guid]::NewGuid().ToString("N"))
$tempUser = Join-Path $tempRoot "user"
$tempAppData = Join-Path $tempRoot "appdata"
New-Item -ItemType Directory -Path $tempUser, $tempAppData | Out-Null

try {
    $oldUserProfile = $env:USERPROFILE
    $oldAppData = $env:APPDATA
    $oldWriteTest = $env:AM_MANAGER_WRITE_TEST
    $env:USERPROFILE = $tempUser
    $env:APPDATA = $tempAppData
    $env:AM_MANAGER_WRITE_TEST = "1"

    powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script -SelfTest

    if ($LASTEXITCODE -ne 0) {
        throw "AgentMemoryManager config writer self-test failed with exit code $LASTEXITCODE"
    }
} finally {
    $env:USERPROFILE = $oldUserProfile
    $env:APPDATA = $oldAppData
    $env:AM_MANAGER_WRITE_TEST = $oldWriteTest
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

$source = Get-Content -LiteralPath $script -Raw -Encoding UTF8

foreach ($required in @(
    '$script:APP_NAME = "CrossAgnetCoding"',
    '$script:APP_VERSION = "0.2.0"',
    "function Get-AgentClientStatuses",
    "function Configure-CodexMcp",
    "function Configure-TraeMcp",
    "function Configure-OpenCodeMcp",
    "function Configure-ClaudeMcp",
    "function Get-CliConfigCommands",
    "function Get-SharedPromptContent",
    "function Sync-SharedAgentFiles",
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
    "Version: 0.2.0",
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
