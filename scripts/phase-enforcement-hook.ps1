[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'phase-workflow-helpers.ps1')

$repoRoot = Split-Path -Parent $PSScriptRoot

function Read-HookPayload {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return [pscustomobject]@{}
    }

    return $raw | ConvertFrom-Json -Depth 20
}

function New-HookResult {
    return [ordered]@{
        continue = $true
    }
}

function Write-HookResult {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Result
    )

    [Console]::Out.Write(($Result | ConvertTo-Json -Depth 20))
}

function Test-IsUnderPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ChildPath,
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    $normalizedChild = [System.IO.Path]::GetFullPath($ChildPath).TrimEnd('\', '/')
    $normalizedRoot = [System.IO.Path]::GetFullPath($RootPath).TrimEnd('\', '/')
    if ($normalizedChild.Equals($normalizedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    return $normalizedChild.StartsWith($normalizedRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-StringLeaves {
    param(
        [AllowNull()]
        [object]$InputObject
    )

    $values = [System.Collections.Generic.List[string]]::new()
    $stack = [System.Collections.Stack]::new()
    $stack.Push($InputObject)

    while ($stack.Count -gt 0) {
        $current = $stack.Pop()
        if ($null -eq $current) {
            continue
        }

        if ($current -is [string]) {
            $values.Add($current)
            continue
        }

        if ($current -is [System.Collections.IDictionary]) {
            foreach ($value in $current.Values) {
                $stack.Push($value)
            }

            continue
        }

        if ($current -is [System.Collections.IEnumerable] -and $current -isnot [string]) {
            foreach ($item in $current) {
                $stack.Push($item)
            }

            continue
        }

        foreach ($property in $current.PSObject.Properties) {
            $stack.Push($property.Value)
        }
    }

    return @($values)
}

function Resolve-AbsolutePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value,
        [Parameter(Mandatory = $true)]
        [string]$CurrentDirectory
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    try {
        if ([System.IO.Path]::IsPathRooted($Value)) {
            return [System.IO.Path]::GetFullPath($Value)
        }

        $candidatePath = Join-Path $CurrentDirectory $Value
        if (Test-Path -LiteralPath $candidatePath) {
            return [System.IO.Path]::GetFullPath($candidatePath)
        }
    }
    catch {
        return $null
    }

    return $null
}

function Test-IsMutatingToolName {
    param(
        [string]$ToolName
    )

    if ([string]::IsNullOrWhiteSpace($ToolName)) {
        return $false
    }

    return $ToolName -match '(apply|create|edit|patch|rename|delete|remove|move|write|terminal|task|command|run)'
}

function Test-IsReadOnlyGitCommand {
    param(
        [string]$CommandLine
    )

    if ([string]::IsNullOrWhiteSpace($CommandLine)) {
        return $false
    }

    if ($CommandLine -notmatch '\bgit(\.exe)?\b') {
        return $false
    }

    if ($CommandLine -match '\b(add|commit|switch|checkout|restore|reset|clean|merge|rebase|cherry-pick|apply|am|stash|pull|push|rm|mv)\b') {
        return $false
    }

    return $CommandLine -match '\b(status|diff|show|log|rev-parse|branch|ls-files)\b' -or
        $CommandLine -match '\bworktree\s+list\b'
}

function Test-IsCleanupCommand {
    param(
        [string]$CommandLine
    )

    return -not [string]::IsNullOrWhiteSpace($CommandLine) -and $CommandLine -match 'repair-phase-worktree-state\.ps1'
}

function Test-IsWorkflowSyncCommand {
    param(
        [string]$CommandLine
    )

    return -not [string]::IsNullOrWhiteSpace($CommandLine) -and $CommandLine -match 'sync-phase-workflow-lane\.ps1'
}

function Test-IsGitCommitCommand {
    param(
        [string]$CommandLine
    )

    return -not [string]::IsNullOrWhiteSpace($CommandLine) -and $CommandLine -match '\bgit(\.exe)?\b.*\bcommit\b'
}

function Get-CommandLocationHints {
    param(
        [string]$CommandLine
    )

    if ([string]::IsNullOrWhiteSpace($CommandLine)) {
        return @()
    }

    $hints = [System.Collections.Generic.List[string]]::new()
    foreach ($pattern in @(
            '\bgit(\.exe)?\b\s+-C\s+(?<path>"[^"]+"|''[^'']+''|\S+)',
            '\bSet-Location\b\s+(?<path>"[^"]+"|''[^'']+''|\S+)',
            '\bPush-Location\b\s+(?<path>"[^"]+"|''[^'']+''|\S+)',
            '(?<!\S)cd\s+(?<path>"[^"]+"|''[^'']+''|\S+)'
        )) {
        foreach ($match in [regex]::Matches($CommandLine, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            $rawPath = [string]$match.Groups['path'].Value
            if ([string]::IsNullOrWhiteSpace($rawPath)) {
                continue
            }

            $hints.Add($rawPath.Trim().Trim("'\""))
        }
    }

    return @($hints)
}

function Resolve-CommandRepositoryRoot {
    param(
        [string]$CommandLine,
        [string]$CurrentDirectory,
        [Parameter(Mandatory = $true)]
        [pscustomobject]$PhaseContext
    )

    $candidates = [System.Collections.Generic.List[string]]::new()

    if (-not [string]::IsNullOrWhiteSpace($CurrentDirectory) -and (Test-Path -LiteralPath $CurrentDirectory -PathType Container)) {
        $candidates.Add([System.IO.Path]::GetFullPath($CurrentDirectory))
    }

    foreach ($hint in Get-CommandLocationHints -CommandLine $CommandLine) {
        $resolvedHint = Resolve-AbsolutePath -Value $hint -CurrentDirectory $CurrentDirectory
        if ($null -ne $resolvedHint) {
            $candidates.Add($resolvedHint)
        }
    }

    foreach ($root in @($PhaseContext.AllowedWorktree, $PhaseContext.ForkRoot, $repoRoot)) {
        if ([string]::IsNullOrWhiteSpace([string]$root)) {
            continue
        }

        foreach ($candidate in @($candidates)) {
            if (Test-IsUnderPath -ChildPath $candidate -RootPath $root) {
                return [System.IO.Path]::GetFullPath($root)
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($CommandLine) -and $CommandLine -match [regex]::Escape([System.IO.Path]::GetFullPath($root))) {
            return [System.IO.Path]::GetFullPath($root)
        }
    }

    return $null
}

function Test-ContainsBlockedGitPattern {
    param(
        [string]$CommandLine
    )

    if ([string]::IsNullOrWhiteSpace($CommandLine)) {
        return $false
    }

    return $CommandLine -match 'git(\.exe)?\s+.*\breset\s+--hard\b' -or
        $CommandLine -match 'git(\.exe)?\s+.*\bcheckout\s+--\b' -or
        $CommandLine -match 'git(\.exe)?\s+.*\bclean\s+-f' -or
        $CommandLine -match 'git(\.exe)?\s+.*\bpush\s+origin\s+main\b'
}

function Test-GitDirty {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath
    )

    if (-not (Test-Path -LiteralPath $RepoPath -PathType Container)) {
        return $false
    }

    $status = @(git -C $RepoPath status --porcelain 2>$null)
    return $status.Count -gt 0
}

function Get-PhaseContext {
    $forkRoot = Resolve-CatastroSwitchForkRoot -RepoRoot $repoRoot
    $activePhaseRecord = Get-PhaseStateRecord -ForkRoot $forkRoot
    $phaseRecord = if ($null -ne $activePhaseRecord) {
        $activePhaseRecord
    }
    else {
        Get-PhaseStateRecord -ForkRoot $forkRoot -IncludeTerminalStates
    }

    $phaseState = if ($null -ne $phaseRecord) { $phaseRecord.PhaseState } else { $null }
    $executionLock = if ($null -ne $phaseState) { $phaseState.executionLock } else { $null }
    $allowedWorktree = if ($null -ne $executionLock) { [string]$executionLock.allowedWorktree } else { '' }
    $allowedBranch = if ($null -ne $executionLock) { [string]$executionLock.allowedBranch } else { '' }
    $currentAllowedWorktreeBranch = ''
    $controlRepoBranch = ''

    try {
        $controlRepoBranch = Get-GitCurrentBranch -RepoPath $repoRoot
    }
    catch {
        $controlRepoBranch = ''
    }

    if (-not [string]::IsNullOrWhiteSpace($allowedWorktree) -and (Test-Path -LiteralPath $allowedWorktree -PathType Container)) {
        try {
            $currentAllowedWorktreeBranch = Get-GitCurrentBranch -RepoPath $allowedWorktree
        }
        catch {
            $currentAllowedWorktreeBranch = ''
        }
    }

    return [pscustomobject]@{
        ForkRoot = $forkRoot
        ActivePhaseRecord = $activePhaseRecord
        PhaseRecord = $phaseRecord
        PhaseState = $phaseState
        ExecutionLock = $executionLock
        AllowedWorktree = $allowedWorktree
        AllowedBranch = $allowedBranch
        CurrentAllowedWorktreeBranch = $currentAllowedWorktreeBranch
        ControlRepoBranch = $controlRepoBranch
        CleanSyncDirty = (Test-GitDirty -RepoPath $forkRoot)
    }
}

function New-ToolDecisionResult {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('allow', 'ask', 'deny')]
        [string]$Decision,
        [Parameter(Mandatory = $true)]
        [string]$Reason,
        [string]$AdditionalContext
    )

    $result = New-HookResult
    $result.hookSpecificOutput = [ordered]@{
        hookEventName = 'PreToolUse'
        permissionDecision = $Decision
        permissionDecisionReason = $Reason
    }

    if (-not [string]::IsNullOrWhiteSpace($AdditionalContext)) {
        $result.hookSpecificOutput.additionalContext = $AdditionalContext
    }

    return $result
}

try {
    $payload = Read-HookPayload
    $hookEventName = [string]$payload.hookEventName
    $result = New-HookResult
    $phaseContext = $null

    try {
        $phaseContext = Get-PhaseContext
    }
    catch {
        $result.systemMessage = "CatastroSwitch phase hook could not resolve the runtime fork: $($_.Exception.Message)"
    }

    switch ($hookEventName) {
        'SessionStart' {
            if ($null -eq $phaseContext -or $null -eq $phaseContext.PhaseState) {
                $result.hookSpecificOutput = [ordered]@{
                    hookEventName = 'SessionStart'
                    additionalContext = 'CatastroSwitch phase lock: no phase-state artifact was resolved for this session.'
                }
                break
            }

            $phaseState = $phaseContext.PhaseState
            $executionLock = $phaseContext.ExecutionLock
            $message = if ($null -ne $phaseContext.ActivePhaseRecord) {
                "CatastroSwitch phase lock: $($phaseState.phaseId) | status $($phaseState.phaseStatus) | activeAgent $($executionLock.activeAgent) | activeTask $($executionLock.activeTaskId) | allowedBranch $($executionLock.allowedBranch) | allowedWorktree $($executionLock.allowedWorktree) | next $($executionLock.nextHandoffTarget)"
            }
            else {
                "CatastroSwitch latest phase state: $($phaseState.phaseId) | status $($phaseState.phaseStatus) | no active non-terminal phase lock is in effect."
            }

            $result.hookSpecificOutput = [ordered]@{
                hookEventName = 'SessionStart'
                additionalContext = $message
            }

            if ($phaseContext.CleanSyncDirty -and $phaseContext.AllowedWorktree -and $phaseContext.AllowedWorktree -ne $phaseContext.ForkRoot) {
                $result.systemMessage = "Runtime fork root is dirty while the phase lock points at $($phaseContext.AllowedWorktree). Run scripts\\repair-phase-worktree-state.ps1 from the control repo before continuing."
            }

            if ($phaseContext.AllowedWorktree -and
                $phaseContext.AllowedBranch -and
                $phaseContext.CurrentAllowedWorktreeBranch -and
                $phaseContext.CurrentAllowedWorktreeBranch -ne $phaseContext.AllowedBranch) {
                $result.systemMessage = "Runtime worktree $($phaseContext.AllowedWorktree) is on branch $($phaseContext.CurrentAllowedWorktreeBranch), but the phase lock expects $($phaseContext.AllowedBranch). Run scripts\\sync-phase-workflow-lane.ps1 -Apply from the control repo before continuing."
            }

            break
        }
        'UserPromptSubmit' {
            if ($null -eq $phaseContext) {
                break
            }

            if ($phaseContext.CleanSyncDirty -and $phaseContext.AllowedWorktree -and $phaseContext.AllowedWorktree -ne $phaseContext.ForkRoot) {
                $result.systemMessage = "CatastroSwitch phase lock is active for $($phaseContext.AllowedWorktree), but the runtime clean-sync worktree is dirty. Repair the mirrored files before more mutating tool calls."
            }

            if ($phaseContext.AllowedWorktree -and
                $phaseContext.AllowedBranch -and
                $phaseContext.CurrentAllowedWorktreeBranch -and
                $phaseContext.CurrentAllowedWorktreeBranch -ne $phaseContext.AllowedBranch) {
                $result.systemMessage = "CatastroSwitch phase lock expects runtime branch $($phaseContext.AllowedBranch), but the locked worktree is currently on $($phaseContext.CurrentAllowedWorktreeBranch). Run scripts\\sync-phase-workflow-lane.ps1 -Apply before more workflow actions."
            }

            break
        }
        'PreToolUse' {
            if ($null -eq $phaseContext) {
                break
            }

            $toolName = [string]$payload.tool_name
            $stringLeaves = Get-StringLeaves -InputObject $payload.tool_input
            foreach ($commandText in $stringLeaves) {
                if (Test-ContainsBlockedGitPattern -CommandLine $commandText) {
                    $result = New-ToolDecisionResult -Decision 'deny' -Reason 'CatastroSwitch blocks destructive git commands in agent sessions.'
                    break
                }
            }

            if ($result.Contains('hookSpecificOutput')) {
                break
            }

            if (-not (Test-IsMutatingToolName -ToolName $toolName)) {
                break
            }

            $currentDirectory = if ([string]::IsNullOrWhiteSpace([string]$payload.cwd)) {
                $repoRoot
            }
            else {
                [string]$payload.cwd
            }

            $invokesWorkflowSync = $false
            foreach ($commandText in $stringLeaves) {
                if (Test-IsWorkflowSyncCommand -CommandLine $commandText) {
                    $invokesWorkflowSync = $true
                    break
                }
            }

            $runtimeBranchMismatch = $phaseContext.AllowedWorktree -and
                $phaseContext.AllowedBranch -and
                $phaseContext.CurrentAllowedWorktreeBranch -and
                $phaseContext.CurrentAllowedWorktreeBranch -ne $phaseContext.AllowedBranch

            foreach ($commandText in $stringLeaves) {
                $targetRepositoryRoot = Resolve-CommandRepositoryRoot -CommandLine $commandText -CurrentDirectory $currentDirectory -PhaseContext $phaseContext

                if ((Test-IsGitCommitCommand -CommandLine $commandText) -and
                    $targetRepositoryRoot -and
                    $targetRepositoryRoot -eq [System.IO.Path]::GetFullPath($repoRoot) -and
                    $phaseContext.ControlRepoBranch -eq 'main') {
                    $result = New-ToolDecisionResult -Decision 'deny' -Reason 'CatastroSwitch blocks commits on control-repo main. Create or switch to a branch first.'
                    break
                }

                if ($runtimeBranchMismatch -and
                    -not $invokesWorkflowSync -and
                    $targetRepositoryRoot -and
                    $targetRepositoryRoot -ne [System.IO.Path]::GetFullPath($repoRoot) -and
                    -not (Test-IsReadOnlyGitCommand -CommandLine $commandText) -and
                    -not (Test-IsCleanupCommand -CommandLine $commandText)) {
                    $result = New-ToolDecisionResult -Decision 'deny' -Reason "Runtime worktree branch mismatch: $($phaseContext.CurrentAllowedWorktreeBranch) is checked out, but the phase lock expects $($phaseContext.AllowedBranch). Run scripts\\sync-phase-workflow-lane.ps1 -Apply first."
                    break
                }
            }

            if ($result.Contains('hookSpecificOutput')) {
                break
            }

            foreach ($value in $stringLeaves) {
                $absolutePath = Resolve-AbsolutePath -Value $value -CurrentDirectory $currentDirectory
                if ($null -eq $absolutePath) {
                    continue
                }

                if ((Test-IsUnderPath -ChildPath $absolutePath -RootPath (Join-Path $repoRoot '.github\hooks')) -or
                    $absolutePath -eq (Join-Path $repoRoot 'scripts\phase-enforcement-hook.ps1') -or
                    $absolutePath -eq (Join-Path $repoRoot 'scripts\repair-phase-worktree-state.ps1')) {
                    $result = New-ToolDecisionResult -Decision 'ask' -Reason 'CatastroSwitch hook and repair scripts require explicit approval before they are edited.'
                    break
                }

                if ($phaseContext.AllowedWorktree -and
                    (Test-IsUnderPath -ChildPath $absolutePath -RootPath $phaseContext.ForkRoot) -and
                    -not (Test-IsUnderPath -ChildPath $absolutePath -RootPath $phaseContext.AllowedWorktree)) {
                    $result = New-ToolDecisionResult -Decision 'deny' -Reason "Phase lock allows runtime writes only in $($phaseContext.AllowedWorktree)."
                    break
                }
            }

            if ($result.Contains('hookSpecificOutput')) {
                break
            }

            foreach ($commandText in $stringLeaves) {
                if (-not $phaseContext.AllowedWorktree) {
                    continue
                }

                $targetsCleanSyncRoot = $commandText -match [regex]::Escape($phaseContext.ForkRoot)
                $targetsAllowedWorktree = $commandText -match [regex]::Escape($phaseContext.AllowedWorktree)
                if ($targetsCleanSyncRoot -and -not $targetsAllowedWorktree -and -not (Test-IsReadOnlyGitCommand -CommandLine $commandText) -and -not (Test-IsCleanupCommand -CommandLine $commandText)) {
                    $result = New-ToolDecisionResult -Decision 'deny' -Reason "Phase lock allows mutating runtime commands only in $($phaseContext.AllowedWorktree)."
                    break
                }
            }

            break
        }
        default {
            break
        }
    }

    Write-HookResult -Result $result
    exit 0
}
catch {
    $fallback = New-HookResult
    $fallback.systemMessage = "CatastroSwitch phase hook failed open: $($_.Exception.Message)"
    Write-HookResult -Result $fallback
    exit 0
}