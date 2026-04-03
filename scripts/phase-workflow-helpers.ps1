function Get-PhaseWorkflowCatalog {
    return [ordered]@{
        F0 = [ordered]@{
            Branch = 'multiagent/f0-baseline-bootstrap'
            Tasks = @(
                [ordered]@{ Id = 'F0-T1'; Title = 'clone-bootstrap-selfhost'; BranchSuffix = 't1-bootstrap-baseline'; DependsOn = @(); ParallelGroup = $null },
                [ordered]@{ Id = 'F0-T2'; Title = 'baseline-patch-inventory'; BranchSuffix = 't2-patch-inventory'; DependsOn = @('F0-T1'); ParallelGroup = 'A' },
                [ordered]@{ Id = 'F0-T3'; Title = 'phase-working-agreement'; BranchSuffix = 't3-working-agreement'; DependsOn = @('F0-T1'); ParallelGroup = 'B' },
                [ordered]@{ Id = 'F0-T4'; Title = 'baseline-doc-sync'; BranchSuffix = 't4-doc-sync'; DependsOn = @('F0-T2', 'F0-T3'); ParallelGroup = $null }
            )
        }
        F1 = [ordered]@{
            Branch = 'multiagent/f1-workspace-rail'
            Tasks = @(
                [ordered]@{ Id = 'F1-T0'; Title = 'branding-export-workflow'; BranchSuffix = 't0-branding-export'; DependsOn = @(); ParallelGroup = $null },
                [ordered]@{ Id = 'F1-T1'; Title = 'add-rail-part-and-layout-slot'; BranchSuffix = 't1-rail-layout'; DependsOn = @('F1-T0'); ParallelGroup = $null },
                [ordered]@{ Id = 'F1-T2'; Title = 'rail-focus-visibility-persistence'; BranchSuffix = 't2-shell-behavior'; DependsOn = @('F1-T1'); ParallelGroup = 'A' },
                [ordered]@{ Id = 'F1-T3'; Title = 'rail-placeholder-workspace-ui'; BranchSuffix = 't3-placeholder-ui'; DependsOn = @('F1-T1'); ParallelGroup = 'B' },
                [ordered]@{ Id = 'F1-T4'; Title = 'shell-hardening-and-doc-sync'; BranchSuffix = 't4-hardening-doc-sync'; DependsOn = @('F1-T2', 'F1-T3'); ParallelGroup = $null }
            )
        }
        F2 = [ordered]@{
            Branch = 'multiagent/f2-workspace-orchestration'
            Tasks = @(
                [ordered]@{ Id = 'F2-T1'; Title = 'create-workspace-context-service'; BranchSuffix = 't1-workspace-context'; DependsOn = @(); ParallelGroup = $null },
                [ordered]@{ Id = 'F2-T2'; Title = 'connect-rail-to-workspace-context'; BranchSuffix = 't2-rail-service-integration'; DependsOn = @('F2-T1'); ParallelGroup = 'A' },
                [ordered]@{ Id = 'F2-T3'; Title = 'profile-selection-policy'; BranchSuffix = 't3-profile-policy'; DependsOn = @('F2-T1'); ParallelGroup = 'B' },
                [ordered]@{ Id = 'F2-T4'; Title = 'non-extension-profile-resources'; BranchSuffix = 't4-profile-resources'; DependsOn = @('F2-T3'); ParallelGroup = $null },
                [ordered]@{ Id = 'F2-T5'; Title = 'recovery-tests-and-doc-sync'; BranchSuffix = 't5-recovery-doc-sync'; DependsOn = @('F2-T2', 'F2-T4'); ParallelGroup = $null }
            )
        }
        F3 = [ordered]@{
            Branch = 'multiagent/f3-extension-session'
            Tasks = @(
                [ordered]@{ Id = 'F3-T1'; Title = 'extension-set-planner'; BranchSuffix = 't1-extension-planner'; DependsOn = @(); ParallelGroup = 'A' },
                [ordered]@{ Id = 'F3-T2'; Title = 'product-session-summary-service'; BranchSuffix = 't2-session-summary'; DependsOn = @(); ParallelGroup = 'B' },
                [ordered]@{ Id = 'F3-T3'; Title = 'extension-set-apply-flow'; BranchSuffix = 't3-extension-apply'; DependsOn = @('F3-T1'); ParallelGroup = $null },
                [ordered]@{ Id = 'F3-T4'; Title = 'rail-session-integration'; BranchSuffix = 't4-rail-session-ui'; DependsOn = @('F3-T2'); ParallelGroup = $null },
                [ordered]@{ Id = 'F3-T5'; Title = 'external-adapter-boundary'; BranchSuffix = 't5-adapter-boundary'; DependsOn = @('F3-T2', 'F3-T4'); ParallelGroup = $null },
                [ordered]@{ Id = 'F3-T6'; Title = 'phase-hardening-tests-and-doc-sync'; BranchSuffix = 't6-hardening-doc-sync'; DependsOn = @('F3-T3', 'F3-T5'); ParallelGroup = $null }
            )
        }
        F4 = [ordered]@{
            Branch = 'multiagent/f4-hardening-sync'
            Tasks = @(
                [ordered]@{ Id = 'F4-T1'; Title = 'regression-coverage-expansion'; BranchSuffix = 't1-regression-coverage'; DependsOn = @(); ParallelGroup = 'A' },
                [ordered]@{ Id = 'F4-T2'; Title = 'patch-ownership-map'; BranchSuffix = 't2-patch-ownership'; DependsOn = @(); ParallelGroup = 'B' },
                [ordered]@{ Id = 'F4-T3'; Title = 'upstream-rebase-playbook'; BranchSuffix = 't3-rebase-playbook'; DependsOn = @('F4-T2'); ParallelGroup = $null },
                [ordered]@{ Id = 'F4-T4'; Title = 'release-readiness-evidence'; BranchSuffix = 't4-release-readiness'; DependsOn = @('F4-T1', 'F4-T2', 'F4-T3'); ParallelGroup = $null }
            )
        }
    }
}

function Get-PhaseDefinition {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Phase
    )

    $catalog = Get-PhaseWorkflowCatalog
    $phaseDefinition = $catalog[$Phase]
    if ($null -eq $phaseDefinition) {
        throw "Unknown phase ID: $Phase"
    }

    return $phaseDefinition
}

function Get-TaskDefinition {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskId
    )

    $catalog = Get-PhaseWorkflowCatalog
    foreach ($phaseId in $catalog.Keys) {
        foreach ($task in @($catalog[$phaseId].Tasks)) {
            if ($task.Id -eq $TaskId) {
                return [ordered]@{
                    Phase = $phaseId
                    Branch = $catalog[$phaseId].Branch
                    Task = $task
                }
            }
        }
    }

    throw "Unknown task ID: $TaskId"
}

function Get-PhaseBranchName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Phase
    )

    return (Get-PhaseDefinition -Phase $Phase).Branch
}

function Get-TaskBranchName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskId
    )

    $taskDefinition = Get-TaskDefinition -TaskId $TaskId
    return "$($taskDefinition.Branch)-$($taskDefinition.Task.BranchSuffix)"
}

function Get-OrderedPhaseIds {
    return @((Get-PhaseWorkflowCatalog).Keys)
}

function Get-TaskDefinitionByBranchName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Branch
    )

    $catalog = Get-PhaseWorkflowCatalog
    foreach ($phaseId in $catalog.Keys) {
        $phaseBranch = [string]$catalog[$phaseId].Branch
        foreach ($task in @($catalog[$phaseId].Tasks)) {
            $taskBranch = "$phaseBranch-$($task.BranchSuffix)"
            if ($taskBranch -eq $Branch) {
                return [ordered]@{
                    Phase = $phaseId
                    Branch = $phaseBranch
                    Task = $task
                }
            }
        }
    }

    return $null
}

function Assert-ForkGitRepository {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ForkRoot
    )

    if (-not (Test-Path -LiteralPath $ForkRoot -PathType Container)) {
        throw "Fork path not found: $ForkRoot"
    }

    $gitDirectory = Join-Path $ForkRoot '.git'
    if (-not (Test-Path -LiteralPath $gitDirectory)) {
        throw "Fork path is not a git checkout: $ForkRoot"
    }
}

function Get-DefaultPhaseStatePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ForkRoot,
        [Parameter(Mandatory = $true)]
        [string]$Phase
    )

    return Join-Path $ForkRoot ".catastroswitch\phase-state\$Phase.phase-state.json"
}

function Get-GitCurrentBranch {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath
    )

    if (-not (Test-Path -LiteralPath $RepoPath -PathType Container)) {
        throw "Git repository path not found: $RepoPath"
    }

    $branch = @(git -C $RepoPath rev-parse --abbrev-ref HEAD 2>$null)
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to resolve current git branch in $RepoPath"
    }

    return [string](@($branch | Select-Object -First 1)[0]).Trim()
}

function Get-CleanSyncBranchName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ForkRoot
    )

    Assert-ForkGitRepository -ForkRoot $ForkRoot

    foreach ($candidate in @('main', 'upstream-main-sync')) {
        $existingBranch = @(git -C $ForkRoot branch --list --format='%(refname:short)' -- $candidate 2>$null)
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to inspect git branches in $ForkRoot"
        }

        if (-not [string]::IsNullOrWhiteSpace([string](@($existingBranch | Select-Object -First 1)[0]))) {
            return $candidate
        }
    }

    return 'main'
}

function Resolve-CatastroSwitchForkRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [string]$PreferredForkRoot
    )

    if (-not [string]::IsNullOrWhiteSpace($PreferredForkRoot)) {
        if (-not (Test-Path -LiteralPath $PreferredForkRoot -PathType Container)) {
            throw "Fork path not found: $PreferredForkRoot"
        }

        return $PreferredForkRoot
    }

    $environmentForkRoot = $env:CATASTROSWITCH_FORK_ROOT
    if (-not [string]::IsNullOrWhiteSpace($environmentForkRoot) -and (Test-Path -LiteralPath $environmentForkRoot -PathType Container)) {
        return $environmentForkRoot
    }

    $workspaceFile = Join-Path $RepoRoot 'CatastroSwitch.local.code-workspace'
    if (Test-Path -LiteralPath $workspaceFile -PathType Leaf) {
        try {
            $workspace = Get-Content -Raw -LiteralPath $workspaceFile | ConvertFrom-Json
            foreach ($folder in @($workspace.folders)) {
                $candidatePath = [string]$folder.path
                if ([string]::IsNullOrWhiteSpace($candidatePath)) {
                    continue
                }

                if (-not [System.IO.Path]::IsPathRooted($candidatePath)) {
                    $candidatePath = Join-Path $RepoRoot $candidatePath
                }

                $candidatePath = [System.IO.Path]::GetFullPath($candidatePath)
                if ($candidatePath -eq [System.IO.Path]::GetFullPath($RepoRoot)) {
                    continue
                }

                if (Test-Path -LiteralPath $candidatePath -PathType Container) {
                    return $candidatePath
                }
            }
        }
        catch {
            # Fall back to the default path when the local workspace file is absent or invalid.
        }
    }

    $defaultForkRoot = 'C:\src\vscode-multiagent'
    if (Test-Path -LiteralPath $defaultForkRoot -PathType Container) {
        return $defaultForkRoot
    }

    throw 'Unable to resolve the runtime fork root. Set CATASTROSWITCH_FORK_ROOT or create CatastroSwitch.local.code-workspace.'
}

function Get-PhaseStateRecord {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ForkRoot,
        [string]$Phase,
        [string]$PhaseStatePath,
        [switch]$IncludeTerminalStates
    )

    $candidatePaths = @()

    if (-not [string]::IsNullOrWhiteSpace($PhaseStatePath)) {
        $candidatePaths = @($PhaseStatePath)
    }
    elseif (-not [string]::IsNullOrWhiteSpace($Phase)) {
        $candidatePaths = @(Get-DefaultPhaseStatePath -ForkRoot $ForkRoot -Phase $Phase)
    }
    else {
        $phaseStateDirectory = Join-Path $ForkRoot '.catastroswitch\phase-state'
        if (-not (Test-Path -LiteralPath $phaseStateDirectory -PathType Container)) {
            return $null
        }

        $candidatePaths = @(Get-ChildItem -LiteralPath $phaseStateDirectory -Filter '*.phase-state.json' -File |
            Sort-Object LastWriteTimeUtc -Descending |
            ForEach-Object { $_.FullName })
    }

    if ($candidatePaths.Count -eq 0) {
        return $null
    }

    $records = foreach ($candidatePath in $candidatePaths) {
        if (-not (Test-Path -LiteralPath $candidatePath -PathType Leaf)) {
            if (-not [string]::IsNullOrWhiteSpace($PhaseStatePath) -or -not [string]::IsNullOrWhiteSpace($Phase)) {
                throw "Phase state file not found: $candidatePath"
            }

            continue
        }

        $phaseState = Get-Content -Raw -LiteralPath $candidatePath | ConvertFrom-Json
        $phaseStatus = [string]$phaseState.phaseStatus
        if (-not $IncludeTerminalStates -and $phaseStatus -in @('pass', 'error')) {
            continue
        }

        [pscustomobject]@{
            Path = $candidatePath
            PhaseState = $phaseState
            LastWriteTimeUtc = (Get-Item -LiteralPath $candidatePath).LastWriteTimeUtc
        }
    }

    $records = @($records)
    if ($records.Count -gt 0) {
        return @($records | Sort-Object LastWriteTimeUtc -Descending)[0]
    }

    if (-not $IncludeTerminalStates) {
        return $null
    }

    foreach ($candidatePath in $candidatePaths) {
        if (-not (Test-Path -LiteralPath $candidatePath -PathType Leaf)) {
            continue
        }

        return [pscustomobject]@{
            Path = $candidatePath
            PhaseState = (Get-Content -Raw -LiteralPath $candidatePath | ConvertFrom-Json)
            LastWriteTimeUtc = (Get-Item -LiteralPath $candidatePath).LastWriteTimeUtc
        }
    }

    return $null
}

function New-PhaseStateObject {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Phase,
        [Parameter(Mandatory = $true)]
        [ValidateSet('fresh_implementation', 'partial_implementation', 'reimplementation')]
        [string]$PhaseMode,
        [string]$AllowedWorktree = ''
    )

    $phaseDefinition = Get-PhaseDefinition -Phase $Phase
    $parallelGroups = @()
    $readyTasks = @()
    $sequentialTasks = @()

    foreach ($task in @($phaseDefinition.Tasks)) {
        if (@($task.DependsOn).Count -eq 0) {
            $readyTasks += $task.Id
        }

        if ([string]::IsNullOrWhiteSpace([string]$task.ParallelGroup)) {
            $sequentialTasks += $task.Id
        }
    }

    foreach ($parallelGroup in @($phaseDefinition.Tasks | Group-Object ParallelGroup)) {
        if ([string]::IsNullOrWhiteSpace([string]$parallelGroup.Name)) {
            continue
        }

        $parallelGroups += [ordered]@{
            id = $parallelGroup.Name
            tasks = @($parallelGroup.Group | ForEach-Object { $_.Id })
            reason = "Default parallel group $($parallelGroup.Name) from docs/implementation-plan.md."
        }
    }

    $tasks = foreach ($task in @($phaseDefinition.Tasks)) {
        [ordered]@{
            id = $task.Id
            title = $task.Title
            status = 'planned'
            dependsOn = @($task.DependsOn)
            parallelGroup = if ([string]::IsNullOrWhiteSpace([string]$task.ParallelGroup)) { $null } else { $task.ParallelGroup }
            branch = Get-TaskBranchName -TaskId $task.Id
            filesChanged = @()
            validation = @()
            docsUpdated = @()
            review = [ordered]@{
                outcome = 'Pending'
                reasoning = ''
                requiredFixes = @()
                docsOrValidationGaps = @()
                nextHandoffTarget = 'Coding Agent'
            }
        }
    }

    return [ordered]@{
        version = 2
        phaseId = $Phase
        phaseBranch = $phaseDefinition.Branch
        phaseMode = $PhaseMode
        phaseStatus = 'planning'
        executionLock = [ordered]@{
            activeAgent = 'Planner'
            activeTaskId = $null
            allowedBranch = $phaseDefinition.Branch
            allowedWorktree = $AllowedWorktree
            nextHandoffTarget = 'Planner'
            pendingReviewForTask = $null
            dirtyWorktreePolicy = 'only_locked_worktree_may_be_dirty'
        }
        planner = [ordered]@{
            summary = 'Planner has not populated this phase yet.'
            currentGaps = @()
            sequentialTasks = @($sequentialTasks)
            parallelGroups = @($parallelGroups)
            readyTasks = @($readyTasks)
        }
        tasks = @($tasks)
        gatekeeper = [ordered]@{
            outcome = 'Pending'
            goalsChecked = @()
            errors = @()
            broaderRisks = @()
            reasoning = ''
            requiredNextAction = 'Run Planner for this phase.'
        }
    }
}

function Write-PhaseStateFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [object]$PhaseState
    )

    $PhaseState | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Path -Encoding utf8
}
