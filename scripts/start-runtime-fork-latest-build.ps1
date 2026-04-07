[CmdletBinding()]
param(
    [string]$ForkRoot = 'C:\src\vscode-multiagent',
    [string]$OpenPath = 'C:\CatastroSwitch',
    [string]$RuntimeStateRoot = "$env:APPDATA\CatastroSwitch\runtime",
    [string[]]$AdditionalArguments
)

$ErrorActionPreference = 'Stop'

$launcher = Join-Path -Path $ForkRoot -ChildPath 'scripts\code.bat'
if (-not (Test-Path -Path $launcher)) {
    throw "Runtime launcher not found: $launcher"
}

$userDataDir = Join-Path -Path $RuntimeStateRoot -ChildPath 'userdata'
$extensionsDir = Join-Path -Path $RuntimeStateRoot -ChildPath 'extensions'

New-Item -ItemType Directory -Path $userDataDir -Force | Out-Null
New-Item -ItemType Directory -Path $extensionsDir -Force | Out-Null

$arguments = @(
    '--user-data-dir', $userDataDir,
    '--extensions-dir', $extensionsDir
)

if (Test-Path -Path $OpenPath) {
    $arguments += $OpenPath
}

if ($AdditionalArguments) {
    $arguments += $AdditionalArguments
}

Push-Location $ForkRoot
try {
    $env:CATASTROSWITCH_CONTROL_REPO = 'C:\CatastroSwitch'
    $env:CATASTROSWITCH_BRANDING_ROOT = 'C:\CatastroSwitch\out\branding'
    & $launcher @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Runtime launcher failed with exit code $LASTEXITCODE"
    }
}
finally {
    Remove-Item Env:CATASTROSWITCH_CONTROL_REPO -ErrorAction SilentlyContinue
    Remove-Item Env:CATASTROSWITCH_BRANDING_ROOT -ErrorAction SilentlyContinue
    Pop-Location
}
