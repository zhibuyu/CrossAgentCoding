param(
    [string]$OutputExe = "D:\otherWorkspace\code_plugin\CrossAgnet\AgentMemoryManager_new.exe"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root "src"
$stage = Join-Path $root "_manager_stage"
$sed = Join-Path $root "_manager_build.sed"

if (Test-Path -LiteralPath $stage) {
    Remove-Item -LiteralPath $stage -Recurse -Force
}

New-Item -ItemType Directory -Path $stage | Out-Null

$scriptSource = Join-Path $src "AgentMemoryManager.ps1"
$scriptTarget = Join-Path $stage "AgentMemoryManager.ps1"
$scriptText = Get-Content -LiteralPath $scriptSource -Raw -Encoding UTF8
Set-Content -LiteralPath $scriptTarget -Value $scriptText -Encoding Unicode

Copy-Item -LiteralPath (Join-Path $src "launch.vbs") -Destination (Join-Path $stage "launch.vbs") -Force

if (Test-Path -LiteralPath $OutputExe) {
    Remove-Item -LiteralPath $OutputExe -Force
}

$stageForSed = $stage.TrimEnd("\") + "\"
$sedText = @"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=0
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=
DisplayLicense=
FinishMessage=
TargetName=$OutputExe
FriendlyName=AgentMemory Manager
AppLaunched=wscript.exe launch.vbs
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
SourceFiles=SourceFiles
[Strings]
FILE0="AgentMemoryManager.ps1"
FILE1="launch.vbs"
[SourceFiles]
SourceFiles0=$stageForSed
[SourceFiles0]
%FILE0%=
%FILE1%=
"@

Set-Content -LiteralPath $sed -Value $sedText -Encoding ASCII

$iexpress = Join-Path $env:WINDIR "System32\iexpress.exe"
$process = Start-Process -FilePath $iexpress -ArgumentList "/N", $sed -Wait -PassThru -WindowStyle Hidden

if ($process.ExitCode -ne 0) {
    throw "IExpress failed with exit code $($process.ExitCode)"
}

if (-not (Test-Path -LiteralPath $OutputExe)) {
    throw "IExpress did not create $OutputExe"
}

Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $sed -Force -ErrorAction SilentlyContinue

Write-Host "Built $OutputExe"
