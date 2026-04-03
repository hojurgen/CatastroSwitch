[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ForkRoot,
    [ValidateSet('F0', 'F1', 'F2', 'F3', 'F4')]
    [string]$Phase,
    [string]$PhaseStatePath,
    [string]$MirrorWorktree
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'phase-workflow-helpers.ps1')

$repoRoot = Split-Path -Parent $PSScriptRoot
$resolvedForkRoot = Resolve-CatastroSwitchForkRoot -RepoRoot $repoRoot -PreferredForkRoot $ForkRoot
$phaseRecord = $null

if (-not [string]::IsNullOrWhiteSpace($PhaseStatePath) -or -not [string]::IsNullOrWhiteSpace($Phase)) {
    $phaseRecord = Get-PhaseStateRecord -ForkRoot $resolvedForkRoot -Phase $Phase -PhaseStatePath $PhaseStatePath -IncludeTerminalStates
}
elseif ([string]::IsNullOrWhiteSpace($MirrorWorktree)) {
    $phaseRecord = Get-PhaseStateRecord -ForkRoot $resolvedForkRoot -IncludeTerminalStates
}

$resolvedMirrorWorktree = if (-not [string]::IsNullOrWhiteSpace($MirrorWorktree)) {
    $MirrorWorktree
}
elseif ($null -ne $phaseRecord -and $null -ne $phaseRecord.PhaseState.executionLock -and -not [string]::IsNullOrWhiteSpace([string]$phaseRecord.PhaseState.executionLock.allowedWorktree)) {
    [string]$phaseRecord.PhaseState.executionLock.allowedWorktree
}
else {
    throw 'Unable to resolve the mirror worktree. Pass -MirrorWorktree explicitly or point the script at a phase-state file with executionLock.allowedWorktree.'
}

if (-not (Test-Path -LiteralPath $resolvedMirrorWorktree -PathType Container)) {
    throw "Mirror worktree not found: $resolvedMirrorWorktree"
}

function Test-PathsMatch {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$MirrorPath
    )

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        return $false
    }

    if (-not (Test-Path -LiteralPath $MirrorPath)) {
        return $false
    }

    if ((Get-Item -LiteralPath $SourcePath).PSIsContainer) {
        $sourceFiles = @(Get-ChildItem -LiteralPath $SourcePath -File -Recurse)
        foreach ($sourceFile in $sourceFiles) {
            $relativeChildPath = $sourceFile.FullName.Substring($SourcePath.Length).TrimStart('\', '/')
            $mirrorChildPath = Join-Path $MirrorPath $relativeChildPath
            if (-not (Test-Path -LiteralPath $mirrorChildPath -PathType Leaf)) {
                return $false
            }

            if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourceFile.FullName).Hash -ne (Get-FileHash -Algorithm SHA256 -LiteralPath $mirrorChildPath).Hash) {
                return $false
            }
        }

        return $true
    }

    return (Get-FileHash -Algorithm SHA256 -LiteralPath $SourcePath).Hash -eq (Get-FileHash -Algorithm SHA256 -LiteralPath $MirrorPath).Hash
}

$statusLines = @(git -C $resolvedForkRoot status --porcelain=v1 --untracked-files=all)
if ($statusLines.Count -eq 0) {
    Write-Host "Runtime worktree is already clean: $resolvedForkRoot"
    exit 0
}

$trackedPaths = [System.Collections.Generic.List[string]]::new()
$untrackedPaths = [System.Collections.Generic.List[string]]::new()
$nonMirroredPaths = [System.Collections.Generic.List[string]]::new()

foreach ($statusLine in $statusLines) {
    $statusCode = $statusLine.Substring(0, 2)
    $relativePath = $statusLine.Substring(3)
    if ($relativePath -match ' -> ') {
        $relativePath = $relativePath.Split(' -> ')[1]
    }

    $sourcePath = Join-Path $resolvedForkRoot $relativePath
    $mirrorPath = Join-Path $resolvedMirrorWorktree $relativePath
    if (-not (Test-PathsMatch -SourcePath $sourcePath -MirrorPath $mirrorPath)) {
        $nonMirroredPaths.Add($relativePath)
        continue
    }

    if ($statusCode -eq '??') {
        $untrackedPaths.Add($relativePath)
        continue
    }

    $trackedPaths.Add($relativePath)
}

if ($nonMirroredPaths.Count -gt 0) {
    throw "Refusing cleanup because these paths are not mirrored in ${resolvedMirrorWorktree}: $($nonMirroredPaths -join ', ')"
}

if ($PSCmdlet.ShouldProcess($resolvedForkRoot, 'Remove mirrored changes from the clean-sync worktree')) {
    foreach ($trackedPath in ($trackedPaths | Select-Object -Unique)) {
        & git -C $resolvedForkRoot restore --staged --worktree -- $trackedPath
        if ($LASTEXITCODE -ne 0) {
            throw "git restore failed for $trackedPath"
        }
    }

    foreach ($untrackedPath in ($untrackedPaths | Select-Object -Unique | Sort-Object Length -Descending)) {
        $absoluteUntrackedPath = Join-Path $resolvedForkRoot $untrackedPath
        if (Test-Path -LiteralPath $absoluteUntrackedPath) {
            Remove-Item -LiteralPath $absoluteUntrackedPath -Recurse -Force
        }
    }
}

$remainingStatus = @(git -C $resolvedForkRoot status --porcelain=v1 --untracked-files=all)
if ($remainingStatus.Count -gt 0) {
    throw "Cleanup completed only partially. Remaining status entries: $($remainingStatus -join '; ')"
}

$phaseLabel = if ($null -ne $phaseRecord) { [string]$phaseRecord.PhaseState.phaseId } else { 'unspecified phase' }
Write-Host "Cleaned mirrored runtime changes in $resolvedForkRoot using $resolvedMirrorWorktree for $phaseLabel."