[CmdletBinding()]
param(
    [ValidateSet('F0', 'F1', 'F2', 'F3', 'F4')]
    [string]$Phase,
    [string]$ForkRoot,
    [switch]$Apply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'phase-workflow-helpers.ps1')

$repoRoot = Split-Path -Parent $PSScriptRoot
$resolvedForkRoot = Resolve-CatastroSwitchForkRoot -RepoRoot $repoRoot -PreferredForkRoot $ForkRoot
Assert-ForkGitRepository -ForkRoot $resolvedForkRoot

function Get-OptionalPhaseRecord {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PhaseId
    )

    $phaseStatePath = Get-DefaultPhaseStatePath -ForkRoot $resolvedForkRoot -Phase $PhaseId
    if (-not (Test-Path -LiteralPath $phaseStatePath -PathType Leaf)) {
        return $null
    }

    return Get-PhaseStateRecord -ForkRoot $resolvedForkRoot -PhaseStatePath $phaseStatePath -IncludeTerminalStates
}

function Resolve-RecommendedPhaseSelection {
    $recommendedSelection = $null

    foreach ($phaseId in Get-OrderedPhaseIds) {
        $phaseRecord = Get-OptionalPhaseRecord -PhaseId $phaseId
        if ($null -eq $phaseRecord) {
            continue
        }

        $phaseState = $phaseRecord.PhaseState
        if ([string]$phaseState.phaseStatus -ne 'pass') {
            continue
        }

        $candidatePhase = [string](($phaseState.gatekeeper | Select-Object -ExpandProperty recommendedNextPhase -ErrorAction SilentlyContinue))
        if ([string]::IsNullOrWhiteSpace($candidatePhase)) {
            continue
        }

        $candidateRecord = Get-OptionalPhaseRecord -PhaseId $candidatePhase
        if ($null -ne $candidateRecord -and [string]$candidateRecord.PhaseState.phaseStatus -eq 'pass') {
            continue
        }

        $recommendedSelection = [pscustomobject]@{
            Phase = $candidatePhase
            Record = $candidateRecord
            Reason = "gatekeeper recommended next phase from $phaseId ($candidatePhase)"
        }
    }

    return $recommendedSelection
}

function Resolve-PhaseSelection {
    param(
        [string]$ExplicitPhase
    )

    if (-not [string]::IsNullOrWhiteSpace($ExplicitPhase)) {
        return [pscustomobject]@{
            Phase = $ExplicitPhase
            Record = Get-OptionalPhaseRecord -PhaseId $ExplicitPhase
            Reason = "explicit phase request ($ExplicitPhase)"
        }
    }

    $activePhaseRecord = Get-PhaseStateRecord -ForkRoot $resolvedForkRoot
    if ($null -ne $activePhaseRecord) {
        return [pscustomobject]@{
            Phase = [string]$activePhaseRecord.PhaseState.phaseId
            Record = $activePhaseRecord
            Reason = 'active non-terminal phase-state artifact'
        }
    }

    $recommendedSelection = Resolve-RecommendedPhaseSelection
    if ($null -ne $recommendedSelection) {
        return $recommendedSelection
    }

    foreach ($phaseId in Get-OrderedPhaseIds) {
        $phaseRecord = Get-OptionalPhaseRecord -PhaseId $phaseId
        if ($null -eq $phaseRecord) {
            return [pscustomobject]@{
                Phase = $phaseId
                Record = $null
                Reason = "first incomplete phase without a phase-state artifact ($phaseId)"
            }
        }

        if ([string]$phaseRecord.PhaseState.phaseStatus -ne 'pass') {
            return [pscustomobject]@{
                Phase = $phaseId
                Record = $phaseRecord
                Reason = "first phase not yet passed ($phaseId)"
            }
        }
    }

    return [pscustomobject]@{
        Phase = $null
        Record = $null
        Reason = 'all documented phases are already in pass state'
    }
}

function Resolve-TargetLane {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Selection,
        [Parameter(Mandatory = $true)]
        [string]$CleanSyncBranch
    )

    if ([string]::IsNullOrWhiteSpace([string]$Selection.Phase)) {
        return [pscustomobject]@{
            Phase = $null
            PhaseBranch = $null
            PhaseStatus = 'pass'
            PhaseRecord = $null
            PhaseStatePath = $null
            TargetBranch = $CleanSyncBranch
            TargetWorktree = $resolvedForkRoot
            TaskId = $null
            CleanSyncBranch = $CleanSyncBranch
        }
    }

    $phaseBranch = Get-PhaseBranchName -Phase $Selection.Phase
    $phaseRecord = $Selection.Record
    $phaseState = if ($null -ne $phaseRecord) { $phaseRecord.PhaseState } else { $null }
    $phaseStatus = if ($null -ne $phaseState) { [string]$phaseState.phaseStatus } else { 'missing' }
    $executionLock = if ($null -ne $phaseState) { $phaseState.executionLock } else { $null }
    $activeTaskId = if ($null -ne $executionLock) { [string]$executionLock.activeTaskId } else { '' }

    $targetBranch = $phaseBranch
    $targetWorktree = $resolvedForkRoot

    if ($null -ne $phaseState -and $phaseStatus -notin @('pass', 'error')) {
        $lockedBranch = [string]$executionLock.allowedBranch
        if (-not [string]::IsNullOrWhiteSpace($lockedBranch)) {
            $targetBranch = $lockedBranch
        }
        elseif (-not [string]::IsNullOrWhiteSpace($activeTaskId)) {
            $targetBranch = Get-TaskBranchName -TaskId $activeTaskId
        }

        $lockedWorktree = [string]$executionLock.allowedWorktree
        if (-not [string]::IsNullOrWhiteSpace($lockedWorktree) -and (Test-Path -LiteralPath $lockedWorktree -PathType Container)) {
            $targetWorktree = $lockedWorktree
        }
    }

    $taskDefinition = Get-TaskDefinitionByBranchName -Branch $targetBranch
    $resolvedTaskId = if ($null -ne $taskDefinition) {
        [string]$taskDefinition.Task.Id
    }
    elseif (-not [string]::IsNullOrWhiteSpace($activeTaskId)) {
        $activeTaskId
    }
    else {
        $null
    }

    return [pscustomobject]@{
        Phase = $Selection.Phase
        PhaseBranch = $phaseBranch
        PhaseStatus = $phaseStatus
        PhaseRecord = $phaseRecord
        PhaseStatePath = if ($null -ne $phaseRecord) { $phaseRecord.Path } else { Get-DefaultPhaseStatePath -ForkRoot $resolvedForkRoot -Phase $Selection.Phase }
        TargetBranch = $targetBranch
        TargetWorktree = $targetWorktree
        TaskId = $resolvedTaskId
        CleanSyncBranch = $CleanSyncBranch
    }
}

function Update-PhaseLockFallbacks {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Lane
    )

    if ($null -eq $Lane.PhaseRecord) {
        return $false
    }

    if ($Lane.PhaseStatus -in @('pass', 'error')) {
        return $false
    }

    $phaseState = $Lane.PhaseRecord.PhaseState
    $executionLock = $phaseState.executionLock
    $updated = $false

    if ([string]$executionLock.allowedBranch -ne $Lane.TargetBranch) {
        $executionLock.allowedBranch = $Lane.TargetBranch
        $updated = $true
    }

    if ([string]$executionLock.allowedWorktree -ne $Lane.TargetWorktree) {
        $executionLock.allowedWorktree = $Lane.TargetWorktree
        $updated = $true
    }

    if ($updated) {
        Write-PhaseStateFile -Path $Lane.PhaseRecord.Path -PhaseState $phaseState
    }

    return $updated
}

function Set-PhaseLane {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Lane
    )

    $phaseBranchScript = Join-Path $PSScriptRoot 'new-phase-branch.ps1'
    $taskBranchScript = Join-Path $PSScriptRoot 'new-phase-task-branch.ps1'
    $phaseStateScript = Join-Path $PSScriptRoot 'new-phase-state.ps1'

    if ($null -eq $Lane.Phase) {
        $currentBranch = Get-GitCurrentBranch -RepoPath $resolvedForkRoot
        if ($currentBranch -ne $Lane.TargetBranch) {
            git -C $resolvedForkRoot switch $Lane.TargetBranch
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to switch the runtime clean sync branch to $($Lane.TargetBranch)."
            }

            return [pscustomobject]@{
                ActionTaken = "Switched the runtime clean sync branch to $($Lane.TargetBranch)."
                PhaseStateUpdated = $false
            }
        }

        return [pscustomobject]@{
            ActionTaken = "Runtime clean sync branch already aligned on $($Lane.TargetBranch)."
            PhaseStateUpdated = $false
        }
    }

    if ($null -eq $Lane.PhaseRecord) {
        & $phaseBranchScript -Phase $Lane.Phase -ForkRoot $Lane.TargetWorktree -Checkout
        & $phaseStateScript -Phase $Lane.Phase -ForkRoot $Lane.TargetWorktree

        return [pscustomobject]@{
            ActionTaken = "Created phase branch and initial phase state for $($Lane.Phase)."
            PhaseStateUpdated = $false
        }
    }

    if ($Lane.TaskId -and $Lane.TargetBranch -eq (Get-TaskBranchName -TaskId $Lane.TaskId)) {
        & $taskBranchScript -TaskId $Lane.TaskId -ForkRoot $Lane.TargetWorktree -Checkout
        $phaseStateUpdated = Update-PhaseLockFallbacks -Lane $Lane

        return [pscustomobject]@{
            ActionTaken = "Aligned the runtime worktree to task branch $($Lane.TargetBranch)."
            PhaseStateUpdated = $phaseStateUpdated
        }
    }

    if ($Lane.TargetBranch -eq $Lane.PhaseBranch) {
        & $phaseBranchScript -Phase $Lane.Phase -ForkRoot $Lane.TargetWorktree -Checkout
        $phaseStateUpdated = Update-PhaseLockFallbacks -Lane $Lane

        return [pscustomobject]@{
            ActionTaken = "Aligned the runtime worktree to phase branch $($Lane.TargetBranch)."
            PhaseStateUpdated = $phaseStateUpdated
        }
    }

    $existingBranch = @(git -C $Lane.TargetWorktree branch --list --format='%(refname:short)' -- $Lane.TargetBranch)
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to inspect git branches in $($Lane.TargetWorktree)."
    }

    if ([string]::IsNullOrWhiteSpace([string](@($existingBranch | Select-Object -First 1)[0]))) {
        throw "Execution lock expects branch $($Lane.TargetBranch), but it does not exist locally in $($Lane.TargetWorktree)."
    }

    git -C $Lane.TargetWorktree switch $Lane.TargetBranch
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to switch $($Lane.TargetWorktree) to branch $($Lane.TargetBranch)."
    }

    $phaseStateUpdated = Update-PhaseLockFallbacks -Lane $Lane

    return [pscustomobject]@{
        ActionTaken = "Aligned the runtime worktree to locked branch $($Lane.TargetBranch)."
        PhaseStateUpdated = $phaseStateUpdated
    }
}

$cleanSyncBranch = Get-CleanSyncBranchName -ForkRoot $resolvedForkRoot
$selection = Resolve-PhaseSelection -ExplicitPhase $Phase
$lane = Resolve-TargetLane -Selection $selection -CleanSyncBranch $cleanSyncBranch
$actionTaken = 'Dry run only.'
$phaseStateUpdated = $false

if ($Apply) {
    $syncResult = Set-PhaseLane -Lane $lane
    $actionTaken = [string]$syncResult.ActionTaken
    $phaseStateUpdated = [bool]$syncResult.PhaseStateUpdated
    $selection = Resolve-PhaseSelection -ExplicitPhase $Phase
    $lane = Resolve-TargetLane -Selection $selection -CleanSyncBranch $cleanSyncBranch
}

$currentTargetBranch = if (Test-Path -LiteralPath $lane.TargetWorktree -PathType Container) {
    Get-GitCurrentBranch -RepoPath $lane.TargetWorktree
}
else {
    ''
}

[ordered]@{
    selectedPhase = if ($null -ne $lane.Phase) { $lane.Phase } else { $null }
    selectionReason = $selection.Reason
    phaseStatus = $lane.PhaseStatus
    cleanSyncBranch = $lane.CleanSyncBranch
    phaseBranch = if ($null -ne $lane.PhaseBranch) { $lane.PhaseBranch } else { $null }
    targetBranch = $lane.TargetBranch
    currentBranch = $currentTargetBranch
    targetWorktree = $lane.TargetWorktree
    taskId = if ($null -ne $lane.TaskId) { $lane.TaskId } else { $null }
    phaseStatePath = if ($null -ne $lane.PhaseStatePath) { $lane.PhaseStatePath } else { $null }
    actionTaken = $actionTaken
    phaseStateUpdated = $phaseStateUpdated
} | ConvertTo-Json -Depth 10