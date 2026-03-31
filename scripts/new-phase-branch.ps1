[CmdletBinding()]
param(
    [ValidateSet('F0', 'F1', 'F2', 'F3', 'F4')]
    [string]$Phase,
    [string]$ForkRoot = 'C:\src\vscode-multiagent',
    [switch]$Checkout
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'phase-workflow-helpers.ps1')

$branch = Get-PhaseBranchName -Phase $Phase

if (-not $Checkout) {
    Write-Host "Recommended phase branch: $branch"
    return
}

Assert-ForkGitRepository -ForkRoot $ForkRoot

$existingBranch = git -C $ForkRoot branch --list --format='%(refname:short)' -- $branch
if ($LASTEXITCODE -ne 0) {
    throw "Failed to inspect git branches in $ForkRoot"
}

if ([string]::IsNullOrWhiteSpace($existingBranch)) {
    git -C $ForkRoot switch -c $branch
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create phase branch: $branch"
    }

    Write-Host "Created and checked out phase branch: $branch"
    return
}

git -C $ForkRoot switch $branch
if ($LASTEXITCODE -ne 0) {
    throw "Failed to switch to phase branch: $branch"
}

Write-Host "Checked out existing phase branch: $branch"
