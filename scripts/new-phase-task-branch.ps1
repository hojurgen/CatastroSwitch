[CmdletBinding()]
param(
    [string]$TaskId,
    [string]$ForkRoot = 'C:\src\vscode-multiagent',
    [switch]$Checkout
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'phase-workflow-helpers.ps1')

$taskDefinition = Get-TaskDefinition -TaskId $TaskId
$phaseBranch = $taskDefinition.Branch
$taskBranch = Get-TaskBranchName -TaskId $TaskId

if (-not $Checkout) {
    Write-Host "Recommended phase task branch: $taskBranch"
    return
}

Assert-ForkGitRepository -ForkRoot $ForkRoot

$existingPhaseBranch = git -C $ForkRoot branch --list --format='%(refname:short)' -- $phaseBranch
if ($LASTEXITCODE -ne 0) {
    throw "Failed to inspect git branches in $ForkRoot"
}

if ([string]::IsNullOrWhiteSpace($existingPhaseBranch)) {
    throw "Phase branch does not exist locally yet: $phaseBranch. Create it first."
}

git -C $ForkRoot switch $phaseBranch
if ($LASTEXITCODE -ne 0) {
    throw "Failed to switch to phase branch: $phaseBranch"
}

$existingTaskBranch = git -C $ForkRoot branch --list --format='%(refname:short)' -- $taskBranch
if ($LASTEXITCODE -ne 0) {
    throw "Failed to inspect git task branches in $ForkRoot"
}

if ([string]::IsNullOrWhiteSpace($existingTaskBranch)) {
    git -C $ForkRoot switch -c $taskBranch
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create phase task branch: $taskBranch"
    }

    Write-Host "Created and checked out phase task branch: $taskBranch"
    return
}

git -C $ForkRoot switch $taskBranch
if ($LASTEXITCODE -ne 0) {
    throw "Failed to switch to phase task branch: $taskBranch"
}

Write-Host "Checked out existing phase task branch: $taskBranch"
