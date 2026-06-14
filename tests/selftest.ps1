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
    "function Get-AgentClientStatuses",
    "function Configure-CodexMcp",
    "function Configure-TraeMcp",
    "function Configure-OpenCodeMcp",
    "function Configure-ClaudeMcp",
    "function Get-CliConfigCommands",
    "CodingAgentAccess"
)) {
    if ($source -notmatch [regex]::Escape($required)) {
        throw "Missing required source feature: $required"
    }
}

Write-Host "SOURCE_FEATURES_OK"
