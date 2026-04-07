[CmdletBinding()]
param(
    [string]$ForkRoot = 'C:\src\vscode-multiagent',
    [string]$OriginUrl = 'https://github.com/hojurgen/vscode.git',
    [string]$UpstreamUrl = 'https://github.com/microsoft/vscode.git',
    [string]$MainBranch = 'main',
    [string]$ProductBranch = 'catastroswitch',
    [switch]$EnsureProductBranch
)

$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string]$Message)

    Write-Host "==> $Message" -ForegroundColor Cyan
}

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

function Get-GitOutput {
    param(
        [string[]]$Arguments,
        [string]$WorkingDirectory
    )

    Push-Location $WorkingDirectory
    try {
        $result = & git @Arguments 2>$null
        if ($LASTEXITCODE -ne 0) {
            return $null
        }

        return ($result | Out-String).Trim()
    }
    finally {
        Pop-Location
    }
}

$forkParent = Split-Path -Path $ForkRoot -Parent
if (-not (Test-Path -Path $forkParent)) {
    Write-Step "Creating parent directory $forkParent"
    New-Item -ItemType Directory -Path $forkParent -Force | Out-Null
}

if (-not (Test-Path -Path $ForkRoot)) {
    Write-Step "Cloning $OriginUrl into $ForkRoot"
    Invoke-Git -Arguments @('clone', $OriginUrl, $ForkRoot) -WorkingDirectory $forkParent
}
elseif (-not (Test-Path -Path (Join-Path -Path $ForkRoot -ChildPath '.git'))) {
    throw "Fork root exists but is not a git repository: $ForkRoot"
}

Write-Step 'Ensuring origin points at the personal fork'
$origin = Get-GitOutput -Arguments @('remote', 'get-url', 'origin') -WorkingDirectory $ForkRoot
if ($origin -and $origin -ne $OriginUrl) {
    Invoke-Git -Arguments @('remote', 'set-url', 'origin', $OriginUrl) -WorkingDirectory $ForkRoot
}

Write-Step 'Ensuring upstream points at microsoft/vscode'
$upstream = Get-GitOutput -Arguments @('remote', 'get-url', 'upstream') -WorkingDirectory $ForkRoot
if (-not $upstream) {
    Invoke-Git -Arguments @('remote', 'add', 'upstream', $UpstreamUrl) -WorkingDirectory $ForkRoot
}
elseif ($upstream -ne $UpstreamUrl) {
    Invoke-Git -Arguments @('remote', 'set-url', 'upstream', $UpstreamUrl) -WorkingDirectory $ForkRoot
}

Write-Step 'Fetching origin and upstream'
Invoke-Git -Arguments @('fetch', 'origin', '--prune') -WorkingDirectory $ForkRoot
Invoke-Git -Arguments @('fetch', 'upstream', '--prune') -WorkingDirectory $ForkRoot

if ($EnsureProductBranch) {
    Write-Step "Ensuring local product branch $ProductBranch exists"
    $localProductBranch = Get-GitOutput -Arguments @('rev-parse', '--verify', $ProductBranch) -WorkingDirectory $ForkRoot
    $remoteProductBranch = Get-GitOutput -Arguments @('ls-remote', '--heads', 'origin', $ProductBranch) -WorkingDirectory $ForkRoot

    if ($localProductBranch) {
        Invoke-Git -Arguments @('switch', $ProductBranch) -WorkingDirectory $ForkRoot
    }
    elseif ($remoteProductBranch) {
        Invoke-Git -Arguments @('switch', '--track', '-c', $ProductBranch, "origin/$ProductBranch") -WorkingDirectory $ForkRoot
    }
    else {
        Invoke-Git -Arguments @('switch', $MainBranch) -WorkingDirectory $ForkRoot
        Invoke-Git -Arguments @('pull', '--ff-only', 'origin', $MainBranch) -WorkingDirectory $ForkRoot
        Invoke-Git -Arguments @('switch', '-c', $ProductBranch, $MainBranch) -WorkingDirectory $ForkRoot
    }
}

Write-Step 'Current remotes'
Invoke-Git -Arguments @('remote', '-v') -WorkingDirectory $ForkRoot

Write-Step 'Bootstrap complete'
Write-Host "Fork root: $ForkRoot"
Write-Host "Origin:    $(Get-GitOutput -Arguments @('remote', 'get-url', 'origin') -WorkingDirectory $ForkRoot)"
Write-Host "Upstream:  $(Get-GitOutput -Arguments @('remote', 'get-url', 'upstream') -WorkingDirectory $ForkRoot)"