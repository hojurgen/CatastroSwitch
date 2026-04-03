[CmdletBinding()]
param(
    [ValidateSet('pre-commit')]
    [string]$HookName,
    [Parameter(Mandatory = $true)]
    [string]$ForkRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'phase-workflow-helpers.ps1')

function Fail-Hook {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [string]$AdditionalMessage
    )

    [Console]::Error.WriteLine($Message)
    if (-not [string]::IsNullOrWhiteSpace($AdditionalMessage)) {
        [Console]::Error.WriteLine($AdditionalMessage)
    }

    exit 1
}

Assert-ForkGitRepository -ForkRoot $ForkRoot

switch ($HookName) {
    'pre-commit' {
        $currentBranch = Get-GitCurrentBranch -RepoPath $ForkRoot
        if ($currentBranch -eq 'HEAD') {
            Fail-Hook -Message 'Commits from detached HEAD are blocked in the runtime fork.' -AdditionalMessage 'Switch to a real branch before committing.'
        }

        if ($currentBranch -in @('main', 'upstream-main-sync') -and $env:CATASTROSWITCH_ALLOW_CLEAN_SYNC_COMMIT -ne '1') {
            Fail-Hook -Message "Commits on the runtime clean sync branch '$currentBranch' are blocked." -AdditionalMessage 'Use a phase or task branch, or override intentionally with CATASTROSWITCH_ALLOW_CLEAN_SYNC_COMMIT=1 git commit ...'
        }

        $activePhaseRecord = Get-PhaseStateRecord -ForkRoot $ForkRoot
        if ($null -eq $activePhaseRecord) {
            exit 0
        }

        $phaseState = $activePhaseRecord.PhaseState
        $allowedBranch = [string]$phaseState.executionLock.allowedBranch
        if (-not [string]::IsNullOrWhiteSpace($allowedBranch) -and $currentBranch -ne $allowedBranch -and $env:CATASTROSWITCH_ALLOW_PHASE_BRANCH_COMMIT -ne '1') {
            $phaseId = [string]$phaseState.phaseId
            Fail-Hook -Message "Active phase $phaseId is locked to branch '$allowedBranch', but the runtime fork is on '$currentBranch'." -AdditionalMessage 'Run powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\sync-phase-workflow-lane.ps1 -Apply from C:\CatastroSwitch, or override intentionally with CATASTROSWITCH_ALLOW_PHASE_BRANCH_COMMIT=1 git commit ...'
        }

        exit 0
    }
}

exit 0
