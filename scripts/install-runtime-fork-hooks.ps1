[CmdletBinding()]
param(
    [string]$ForkRoot,
    [switch]$SkipExcludeUpdate,
    [switch]$SkipUpstreamPushProtection
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'phase-workflow-helpers.ps1')

$repoRoot = Split-Path -Parent $PSScriptRoot
$resolvedForkRoot = Resolve-CatastroSwitchForkRoot -RepoRoot $repoRoot -PreferredForkRoot $ForkRoot
Assert-ForkGitRepository -ForkRoot $resolvedForkRoot

$runtimeHooksPath = Join-Path $repoRoot '.githooks-runtime'
if (-not (Test-Path -LiteralPath $runtimeHooksPath -PathType Container)) {
    throw "Runtime hooks path not found: $runtimeHooksPath"
}

git -C $resolvedForkRoot config core.hooksPath $runtimeHooksPath
if ($LASTEXITCODE -ne 0) {
    throw "Failed to set core.hooksPath for $resolvedForkRoot"
}

$excludePath = @(git -C $resolvedForkRoot rev-parse --git-path info/exclude 2>$null)
if ($LASTEXITCODE -ne 0) {
    throw "Failed to resolve info/exclude for $resolvedForkRoot"
}

$resolvedExcludePath = [string](@($excludePath | Select-Object -First 1)[0]).Trim()
if (-not $SkipExcludeUpdate -and -not [string]::IsNullOrWhiteSpace($resolvedExcludePath)) {
    $excludeDirectory = Split-Path -Parent $resolvedExcludePath
    if (-not (Test-Path -LiteralPath $excludeDirectory -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $excludeDirectory -Force
    }

    if (-not (Test-Path -LiteralPath $resolvedExcludePath -PathType Leaf)) {
        New-Item -ItemType File -Path $resolvedExcludePath -Force | Out-Null
    }

    $excludeContents = Get-Content -LiteralPath $resolvedExcludePath -ErrorAction SilentlyContinue
    if ('/.catastroswitch/' -notin @($excludeContents)) {
        Add-Content -LiteralPath $resolvedExcludePath -Value '/.catastroswitch/'
    }
}

if (-not $SkipUpstreamPushProtection) {
    $upstreamUrl = @(git -C $resolvedForkRoot remote get-url upstream 2>$null)
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace([string](@($upstreamUrl | Select-Object -First 1)[0]))) {
        git -C $resolvedForkRoot remote set-url --push upstream no_push
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to set fetch-only upstream push URL for $resolvedForkRoot"
        }
    }
}

[ordered]@{
    forkRoot = $resolvedForkRoot
    hooksPath = $runtimeHooksPath
    excludeUpdated = -not $SkipExcludeUpdate
    upstreamPushProtectionApplied = -not $SkipUpstreamPushProtection
} | ConvertTo-Json -Depth 5
