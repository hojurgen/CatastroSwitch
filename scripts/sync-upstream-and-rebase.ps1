[CmdletBinding()]
param(
    [string]$ForkRoot = 'C:\src\vscode-multiagent',
    [string]$MainBranch = 'main',
    [string]$ProductBranch = 'catastroswitch',
    [switch]$Execute,
    [switch]$PushMain,
    [switch]$PushProductBranch
)

$ErrorActionPreference = 'Stop'

function Invoke-Git {
    param(
        [string[]]$Arguments,
        [string]$WorkingDirectory
    )

    Push-Location $WorkingDirectory
    try {
        & git @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw "git $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }
}

if (-not (Test-Path -Path (Join-Path -Path $ForkRoot -ChildPath '.git'))) {
    throw "Fork checkout not found: $ForkRoot"
}

$commands = @(
    "git -C $ForkRoot fetch origin --prune",
    "git -C $ForkRoot fetch upstream --prune",
    "git -C $ForkRoot switch $MainBranch",
    "git -C $ForkRoot merge --ff-only upstream/$MainBranch",
    "git -C $ForkRoot switch $ProductBranch",
    "git -C $ForkRoot rebase $MainBranch"
)

if ($PushMain) {
    $commands += "git -C $ForkRoot push origin $MainBranch"
}

if ($PushProductBranch) {
    $commands += "git -C $ForkRoot push --force-with-lease origin $ProductBranch"
}

if (-not $Execute) {
    Write-Host 'Preview mode. Re-run with -Execute to perform these commands:' -ForegroundColor Yellow
    $commands | ForEach-Object { Write-Host "  $_" }
    return
}

Invoke-Git -Arguments @('fetch', 'origin', '--prune') -WorkingDirectory $ForkRoot
Invoke-Git -Arguments @('fetch', 'upstream', '--prune') -WorkingDirectory $ForkRoot
Invoke-Git -Arguments @('switch', $MainBranch) -WorkingDirectory $ForkRoot
Invoke-Git -Arguments @('merge', '--ff-only', "upstream/$MainBranch") -WorkingDirectory $ForkRoot

if ($PushMain) {
    Invoke-Git -Arguments @('push', 'origin', $MainBranch) -WorkingDirectory $ForkRoot
}

Invoke-Git -Arguments @('switch', $ProductBranch) -WorkingDirectory $ForkRoot
Invoke-Git -Arguments @('rebase', $MainBranch) -WorkingDirectory $ForkRoot

if ($PushProductBranch) {
    Invoke-Git -Arguments @('push', '--force-with-lease', 'origin', $ProductBranch) -WorkingDirectory $ForkRoot
}

Write-Host 'Sync and rebase complete.'