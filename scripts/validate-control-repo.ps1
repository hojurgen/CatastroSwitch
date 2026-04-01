[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot

function Assert-FileExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $path = Join-Path $repoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing required file: $RelativePath"
    }

    return $path
}

function Read-JsonFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $path = Assert-FileExists -RelativePath $RelativePath
    $json = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
    return $json
}

function Assert-ContainsValue {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Values,
        [Parameter(Mandatory = $true)]
        [string]$ExpectedValue,
        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    if ($ExpectedValue -notin $Values) {
        throw "$Description is missing expected value '$ExpectedValue'."
    }
}

function Get-PropertyValue {
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject,
        [Parameter(Mandatory = $true)]
        [string]$PropertyName
    )

    $property = $InputObject.PSObject.Properties[$PropertyName]
    if (-not $property) {
        return $null
    }

    return $property.Value
}

function Assert-RequiredProperties {
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject,
        [Parameter(Mandatory = $true)]
        [string[]]$RequiredProperties,
        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    foreach ($requiredProperty in $RequiredProperties) {
        if (-not $InputObject.PSObject.Properties[$requiredProperty]) {
            throw "$Description is missing required property '$requiredProperty'."
        }
    }
}

function Assert-StringValue {
    param(
        [AllowNull()]
        [object]$Value,
        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    if ($null -ne $Value -and $Value -isnot [string]) {
        throw "$Description must be a string."
    }
}

function Assert-StringArray {
    param(
        [AllowNull()]
        [object]$Value,
        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    if ($null -eq $Value) {
        return
    }

    foreach ($item in @($Value)) {
        if ($item -isnot [string]) {
            throw "$Description must contain only strings."
        }
    }
}

function Assert-IntegerMinimum {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Value,
        [Parameter(Mandatory = $true)]
        [long]$Minimum,
        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    if ($Value -isnot [byte] -and $Value -isnot [int16] -and $Value -isnot [int32] -and $Value -isnot [int64]) {
        throw "$Description must be an integer."
    }

    if ($Value -lt $Minimum) {
        throw "$Description must be greater than or equal to $Minimum."
    }
}

function Assert-EnumValue {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Value,
        [Parameter(Mandatory = $true)]
        [string[]]$AllowedValues,
        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    if ($Value -isnot [string]) {
        throw "$Description must be a string."
    }

    if ($Value -notin $AllowedValues) {
        throw "$Description must be one of: $($AllowedValues -join ', ')."
    }
}

function Validate-WorkspaceRegistrySample {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Schema,
        [Parameter(Mandatory = $true)]
        [object]$Sample
    )

    Assert-RequiredProperties -InputObject $Sample -RequiredProperties @($Schema.required) -Description 'workspace registry root'

    $versionMinimum = [long](Get-PropertyValue -InputObject $Schema.properties.version -PropertyName 'minimum')
    Assert-IntegerMinimum -Value (Get-PropertyValue -InputObject $Sample -PropertyName 'version') -Minimum $versionMinimum -Description 'workspace registry version'

    $workspaces = Get-PropertyValue -InputObject $Sample -PropertyName 'workspaces'
    $workspaces = @($workspaces)

    $workspaceSchema = $Schema.definitions.workspace
    $agentAdapterSchema = $Schema.definitions.agentAdapter
    $visibilityEnum = @($agentAdapterSchema.properties.visibility.enum)

    for ($workspaceIndex = 0; $workspaceIndex -lt $workspaces.Count; $workspaceIndex++) {
        $workspace = $workspaces[$workspaceIndex]
        $workspaceLabel = "workspace[$workspaceIndex]"

        Assert-RequiredProperties -InputObject $workspace -RequiredProperties @($workspaceSchema.required) -Description $workspaceLabel
        Assert-StringValue -Value (Get-PropertyValue -InputObject $workspace -PropertyName 'id') -Description "$workspaceLabel.id"
        Assert-StringValue -Value (Get-PropertyValue -InputObject $workspace -PropertyName 'label') -Description "$workspaceLabel.label"
        Assert-StringValue -Value (Get-PropertyValue -InputObject $workspace -PropertyName 'path') -Description "$workspaceLabel.path"
        Assert-StringValue -Value (Get-PropertyValue -InputObject $workspace -PropertyName 'profileAffinity') -Description "$workspaceLabel.profileAffinity"
        Assert-StringValue -Value (Get-PropertyValue -InputObject $workspace -PropertyName 'owner') -Description "$workspaceLabel.owner"
        Assert-StringValue -Value (Get-PropertyValue -InputObject $workspace -PropertyName 'notes') -Description "$workspaceLabel.notes"
        Assert-StringArray -Value (Get-PropertyValue -InputObject $workspace -PropertyName 'desiredBehaviors') -Description "$workspaceLabel.desiredBehaviors"

        $agentAdapters = Get-PropertyValue -InputObject $workspace -PropertyName 'agentAdapters'
        if ($null -ne $agentAdapters) {
            $agentAdapters = @($agentAdapters)

            for ($adapterIndex = 0; $adapterIndex -lt $agentAdapters.Count; $adapterIndex++) {
                $agentAdapter = $agentAdapters[$adapterIndex]
                $adapterLabel = "$workspaceLabel.agentAdapters[$adapterIndex]"

                Assert-RequiredProperties -InputObject $agentAdapter -RequiredProperties @($agentAdapterSchema.required) -Description $adapterLabel
                Assert-StringValue -Value (Get-PropertyValue -InputObject $agentAdapter -PropertyName 'id') -Description "$adapterLabel.id"
                Assert-StringValue -Value (Get-PropertyValue -InputObject $agentAdapter -PropertyName 'label') -Description "$adapterLabel.label"
                Assert-EnumValue -Value (Get-PropertyValue -InputObject $agentAdapter -PropertyName 'visibility') -AllowedValues $visibilityEnum -Description "$adapterLabel.visibility"
                Assert-StringValue -Value (Get-PropertyValue -InputObject $agentAdapter -PropertyName 'status') -Description "$adapterLabel.status"
                Assert-StringValue -Value (Get-PropertyValue -InputObject $agentAdapter -PropertyName 'notes') -Description "$adapterLabel.notes"
            }
        }
    }

    $productCapabilities = Get-PropertyValue -InputObject $Sample -PropertyName 'productCapabilities'
    $productCapabilities = @($productCapabilities)

    $productCapabilitySchema = $Schema.definitions.productCapability
    $phaseEnum = @($productCapabilitySchema.properties.phase.enum)
    $statusEnum = @($productCapabilitySchema.properties.status.enum)

    for ($capabilityIndex = 0; $capabilityIndex -lt $productCapabilities.Count; $capabilityIndex++) {
        $productCapability = $productCapabilities[$capabilityIndex]
        $capabilityLabel = "productCapabilities[$capabilityIndex]"

        Assert-RequiredProperties -InputObject $productCapability -RequiredProperties @($productCapabilitySchema.required) -Description $capabilityLabel
        Assert-StringValue -Value (Get-PropertyValue -InputObject $productCapability -PropertyName 'feature') -Description "$capabilityLabel.feature"
        Assert-EnumValue -Value (Get-PropertyValue -InputObject $productCapability -PropertyName 'phase') -AllowedValues $phaseEnum -Description "$capabilityLabel.phase"
        Assert-EnumValue -Value (Get-PropertyValue -InputObject $productCapability -PropertyName 'status') -AllowedValues $statusEnum -Description "$capabilityLabel.status"
        Assert-StringArray -Value (Get-PropertyValue -InputObject $productCapability -PropertyName 'patchAreas') -Description "$capabilityLabel.patchAreas"
        Assert-StringArray -Value (Get-PropertyValue -InputObject $productCapability -PropertyName 'sourceDocs') -Description "$capabilityLabel.sourceDocs"
        Assert-StringValue -Value (Get-PropertyValue -InputObject $productCapability -PropertyName 'notes') -Description "$capabilityLabel.notes"
    }
}

function Validate-PhaseExecutionStateSample {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Schema,
        [Parameter(Mandatory = $true)]
        [object]$Sample
    )

    Assert-RequiredProperties -InputObject $Sample -RequiredProperties @($Schema.required) -Description 'phase execution state root'

    $versionMinimum = [long](Get-PropertyValue -InputObject $Schema.properties.version -PropertyName 'minimum')
    Assert-IntegerMinimum -Value (Get-PropertyValue -InputObject $Sample -PropertyName 'version') -Minimum $versionMinimum -Description 'phase execution state version'
    Assert-EnumValue -Value (Get-PropertyValue -InputObject $Sample -PropertyName 'phaseId') -AllowedValues @($Schema.properties.phaseId.enum) -Description 'phase execution state phaseId'
    Assert-StringValue -Value (Get-PropertyValue -InputObject $Sample -PropertyName 'phaseBranch') -Description 'phase execution state phaseBranch'
    Assert-EnumValue -Value (Get-PropertyValue -InputObject $Sample -PropertyName 'phaseMode') -AllowedValues @($Schema.properties.phaseMode.enum) -Description 'phase execution state phaseMode'
    Assert-EnumValue -Value (Get-PropertyValue -InputObject $Sample -PropertyName 'phaseStatus') -AllowedValues @($Schema.properties.phaseStatus.enum) -Description 'phase execution state phaseStatus'

    $planner = Get-PropertyValue -InputObject $Sample -PropertyName 'planner'
    $plannerSchema = $Schema.definitions.planner
    Assert-RequiredProperties -InputObject $planner -RequiredProperties @($plannerSchema.required) -Description 'phase planner'
    Assert-StringValue -Value (Get-PropertyValue -InputObject $planner -PropertyName 'summary') -Description 'phase planner summary'
    Assert-StringArray -Value (Get-PropertyValue -InputObject $planner -PropertyName 'currentGaps') -Description 'phase planner currentGaps'
    Assert-StringArray -Value (Get-PropertyValue -InputObject $planner -PropertyName 'sequentialTasks') -Description 'phase planner sequentialTasks'
    Assert-StringArray -Value (Get-PropertyValue -InputObject $planner -PropertyName 'readyTasks') -Description 'phase planner readyTasks'

    $parallelGroupSchema = $Schema.definitions.parallelGroup
    $parallelGroups = @($planner.parallelGroups)
    for ($parallelGroupIndex = 0; $parallelGroupIndex -lt $parallelGroups.Count; $parallelGroupIndex++) {
        $parallelGroup = $parallelGroups[$parallelGroupIndex]
        $parallelGroupLabel = "planner.parallelGroups[$parallelGroupIndex]"

        Assert-RequiredProperties -InputObject $parallelGroup -RequiredProperties @($parallelGroupSchema.required) -Description $parallelGroupLabel
        Assert-StringValue -Value (Get-PropertyValue -InputObject $parallelGroup -PropertyName 'id') -Description "$parallelGroupLabel.id"
        Assert-StringArray -Value (Get-PropertyValue -InputObject $parallelGroup -PropertyName 'tasks') -Description "$parallelGroupLabel.tasks"
        Assert-StringValue -Value (Get-PropertyValue -InputObject $parallelGroup -PropertyName 'reason') -Description "$parallelGroupLabel.reason"
    }

    $taskSchema = $Schema.definitions.task
    $taskStatusEnum = @($taskSchema.properties.status.enum)
    $reviewSchema = $Schema.definitions.review
    $reviewOutcomeEnum = @($reviewSchema.properties.outcome.enum)
    $reviewTargetEnum = @($reviewSchema.properties.nextHandoffTarget.enum)
    $tasks = @($Sample.tasks)

    for ($taskIndex = 0; $taskIndex -lt $tasks.Count; $taskIndex++) {
        $task = $tasks[$taskIndex]
        $taskLabel = "tasks[$taskIndex]"

        Assert-RequiredProperties -InputObject $task -RequiredProperties @($taskSchema.required) -Description $taskLabel
        Assert-StringValue -Value (Get-PropertyValue -InputObject $task -PropertyName 'id') -Description "$taskLabel.id"
        Assert-StringValue -Value (Get-PropertyValue -InputObject $task -PropertyName 'title') -Description "$taskLabel.title"
        Assert-EnumValue -Value (Get-PropertyValue -InputObject $task -PropertyName 'status') -AllowedValues $taskStatusEnum -Description "$taskLabel.status"
        Assert-StringArray -Value (Get-PropertyValue -InputObject $task -PropertyName 'dependsOn') -Description "$taskLabel.dependsOn"
        Assert-StringValue -Value (Get-PropertyValue -InputObject $task -PropertyName 'parallelGroup') -Description "$taskLabel.parallelGroup"
        Assert-StringValue -Value (Get-PropertyValue -InputObject $task -PropertyName 'branch') -Description "$taskLabel.branch"
        Assert-StringArray -Value (Get-PropertyValue -InputObject $task -PropertyName 'filesChanged') -Description "$taskLabel.filesChanged"
        Assert-StringArray -Value (Get-PropertyValue -InputObject $task -PropertyName 'validation') -Description "$taskLabel.validation"
        Assert-StringArray -Value (Get-PropertyValue -InputObject $task -PropertyName 'docsUpdated') -Description "$taskLabel.docsUpdated"

        $review = Get-PropertyValue -InputObject $task -PropertyName 'review'
        $reviewLabel = "$taskLabel.review"
        Assert-RequiredProperties -InputObject $review -RequiredProperties @($reviewSchema.required) -Description $reviewLabel
        Assert-EnumValue -Value (Get-PropertyValue -InputObject $review -PropertyName 'outcome') -AllowedValues $reviewOutcomeEnum -Description "$reviewLabel.outcome"
        Assert-StringValue -Value (Get-PropertyValue -InputObject $review -PropertyName 'reasoning') -Description "$reviewLabel.reasoning"
        Assert-StringArray -Value (Get-PropertyValue -InputObject $review -PropertyName 'requiredFixes') -Description "$reviewLabel.requiredFixes"
        Assert-StringArray -Value (Get-PropertyValue -InputObject $review -PropertyName 'docsOrValidationGaps') -Description "$reviewLabel.docsOrValidationGaps"
        Assert-EnumValue -Value (Get-PropertyValue -InputObject $review -PropertyName 'nextHandoffTarget') -AllowedValues $reviewTargetEnum -Description "$reviewLabel.nextHandoffTarget"
    }

    $gatekeeper = Get-PropertyValue -InputObject $Sample -PropertyName 'gatekeeper'
    $gatekeeperSchema = $Schema.definitions.gatekeeper
    $gatekeeperOutcomeEnum = @($gatekeeperSchema.properties.outcome.enum)
    Assert-RequiredProperties -InputObject $gatekeeper -RequiredProperties @($gatekeeperSchema.required) -Description 'phase gatekeeper'
    Assert-EnumValue -Value (Get-PropertyValue -InputObject $gatekeeper -PropertyName 'outcome') -AllowedValues $gatekeeperOutcomeEnum -Description 'phase gatekeeper outcome'
    Assert-StringArray -Value (Get-PropertyValue -InputObject $gatekeeper -PropertyName 'goalsChecked') -Description 'phase gatekeeper goalsChecked'
    Assert-StringArray -Value (Get-PropertyValue -InputObject $gatekeeper -PropertyName 'errors') -Description 'phase gatekeeper errors'
    Assert-StringArray -Value (Get-PropertyValue -InputObject $gatekeeper -PropertyName 'broaderRisks') -Description 'phase gatekeeper broaderRisks'
    Assert-StringValue -Value (Get-PropertyValue -InputObject $gatekeeper -PropertyName 'reasoning') -Description 'phase gatekeeper reasoning'
    Assert-StringValue -Value (Get-PropertyValue -InputObject $gatekeeper -PropertyName 'requiredNextAction') -Description 'phase gatekeeper requiredNextAction'
}

$jsonFiles = @(
    'schemas\workspace-registry.schema.json',
    'examples\workspace-registry.sample.json',
    'schemas\phase-execution-state.schema.json',
    'examples\phase-execution-state.sample.json',
    'fork\tooling\branding-assets.manifest.json',
    'fork\tooling\tsconfig.catastroswitch.strict.json',
    '.vscode\extensions.json',
    '.vscode\launch.json',
    '.vscode\mcp.json',
    '.vscode\settings.json',
    '.vscode\tasks.json'
)

Write-Host 'Parsing JSON files...'
foreach ($relativePath in $jsonFiles) {
    $null = Read-JsonFile -RelativePath $relativePath
    Write-Host " - OK: $relativePath"
}

$schema = Read-JsonFile -RelativePath 'schemas\workspace-registry.schema.json'
$sample = Read-JsonFile -RelativePath 'examples\workspace-registry.sample.json'
Validate-WorkspaceRegistrySample -Schema $schema -Sample $sample
Write-Host ' - OK: sample registry satisfies the schema contract checks'

$phaseSchema = Read-JsonFile -RelativePath 'schemas\phase-execution-state.schema.json'
$phaseSample = Read-JsonFile -RelativePath 'examples\phase-execution-state.sample.json'
Validate-PhaseExecutionStateSample -Schema $phaseSchema -Sample $phaseSample
Write-Host ' - OK: sample phase execution state satisfies the schema contract checks'

$extensions = Read-JsonFile -RelativePath '.vscode\extensions.json'
$recommendedExtensions = @($extensions.recommendations)
$unwantedExtensions = @($extensions.unwantedRecommendations)
Assert-ContainsValue -Values $recommendedExtensions -ExpectedValue 'github.copilot' -Description '.vscode\extensions.json recommendations'
Assert-ContainsValue -Values $recommendedExtensions -ExpectedValue 'github.copilot-chat' -Description '.vscode\extensions.json recommendations'
Assert-ContainsValue -Values $unwantedExtensions -ExpectedValue 'dbaeumer.vscode-eslint' -Description '.vscode\extensions.json unwantedRecommendations'
Assert-ContainsValue -Values $unwantedExtensions -ExpectedValue 'biomejs.biome' -Description '.vscode\extensions.json unwantedRecommendations'

$settings = Read-JsonFile -RelativePath '.vscode\settings.json'
$schemaMappings = @($settings.PSObject.Properties['json.schemas'].Value)
$expectedMapping = $schemaMappings | Where-Object {
    '/examples/workspace-registry.sample.json' -in $_.fileMatch -and $_.url -eq './schemas/workspace-registry.schema.json'
}
if (-not $expectedMapping) {
    throw ".vscode\settings.json is missing the workspace registry schema mapping for examples\workspace-registry.sample.json."
}
$expectedPhaseMapping = $schemaMappings | Where-Object {
    '/examples/phase-execution-state.sample.json' -in $_.fileMatch -and $_.url -eq './schemas/phase-execution-state.schema.json'
}
if (-not $expectedPhaseMapping) {
    throw ".vscode\settings.json is missing the phase execution state schema mapping for examples\phase-execution-state.sample.json."
}
Write-Host ' - OK: schema mappings are present'

$mcpConfig = Read-JsonFile -RelativePath '.vscode\mcp.json'
$mcpServers = $mcpConfig.servers
if ('microsoft-learn' -notin $mcpServers.PSObject.Properties.Name) {
    throw ".vscode\mcp.json is missing the 'microsoft-learn' server."
}
if ('github' -notin $mcpServers.PSObject.Properties.Name) {
    throw ".vscode\mcp.json is missing the 'github' server."
}
$microsoftLearnServer = Get-PropertyValue -InputObject $mcpServers -PropertyName 'microsoft-learn'
$githubServer = Get-PropertyValue -InputObject $mcpServers -PropertyName 'github'
if ((Get-PropertyValue -InputObject $microsoftLearnServer -PropertyName 'url') -ne 'https://learn.microsoft.com/api/mcp') {
    throw ".vscode\mcp.json has an unexpected URL for the 'microsoft-learn' server."
}
if ((Get-PropertyValue -InputObject $githubServer -PropertyName 'url') -ne 'https://api.githubcopilot.com/mcp') {
    throw ".vscode\mcp.json has an unexpected URL for the 'github' server."
}
Write-Host ' - OK: MCP workspace defaults are present'

$tasksConfig = Read-JsonFile -RelativePath '.vscode\tasks.json'
$validateTask = @($tasksConfig.tasks | Where-Object { $_.label -eq 'Control repo: validate' }) | Select-Object -First 1
if (-not $validateTask) {
    throw ".vscode\tasks.json is missing the 'Control repo: validate' task."
}
if ('.\scripts\validate-control-repo.ps1' -notin @($validateTask.args)) {
    throw ".vscode\tasks.json does not route the validation task through .\scripts\validate-control-repo.ps1."
}
Write-Host ' - OK: VS Code validation task points at the shared script'

$workspaceTask = @($tasksConfig.tasks | Where-Object { $_.label -eq 'Control repo: create local workspace file' }) | Select-Object -First 1
if (-not $workspaceTask) {
    throw ".vscode\tasks.json is missing the 'Control repo: create local workspace file' task."
}
if ('.\scripts\new-local-workspace.ps1' -notin @($workspaceTask.args)) {
    throw ".vscode\tasks.json does not route the workspace task through .\scripts\new-local-workspace.ps1."
}
Write-Host ' - OK: VS Code local workspace task points at the shared script'

$phaseBranchTask = @($tasksConfig.tasks | Where-Object { $_.label -eq 'Control repo: create phase branch' }) | Select-Object -First 1
if (-not $phaseBranchTask) {
    throw ".vscode\tasks.json is missing the 'Control repo: create phase branch' task."
}
if ('.\scripts\new-phase-branch.ps1' -notin @($phaseBranchTask.args)) {
    throw ".vscode\tasks.json does not route the phase branch task through .\scripts\new-phase-branch.ps1."
}

$phaseTaskBranchTask = @($tasksConfig.tasks | Where-Object { $_.label -eq 'Control repo: create phase task branch' }) | Select-Object -First 1
if (-not $phaseTaskBranchTask) {
    throw ".vscode\tasks.json is missing the 'Control repo: create phase task branch' task."
}
if ('.\scripts\new-phase-task-branch.ps1' -notin @($phaseTaskBranchTask.args)) {
    throw ".vscode\tasks.json does not route the phase task branch task through .\scripts\new-phase-task-branch.ps1."
}

$phaseStateTask = @($tasksConfig.tasks | Where-Object { $_.label -eq 'Control repo: write phase state file' }) | Select-Object -First 1
if (-not $phaseStateTask) {
    throw ".vscode\tasks.json is missing the 'Control repo: write phase state file' task."
}
if ('.\scripts\new-phase-state.ps1' -notin @($phaseStateTask.args)) {
    throw ".vscode\tasks.json does not route the phase state task through .\scripts\new-phase-state.ps1."
}

$brandingExportTask = @($tasksConfig.tasks | Where-Object { $_.label -eq 'Fork: export branding assets' }) | Select-Object -First 1
if (-not $brandingExportTask) {
    throw ".vscode\tasks.json is missing the 'Fork: export branding assets' task."
}
if ('.\scripts\export-fork-branding-assets.ps1' -notin @($brandingExportTask.args)) {
    throw ".vscode\tasks.json does not route the branding export task through .\scripts\export-fork-branding-assets.ps1."
}
if ('-CompileFork' -notin @($brandingExportTask.args)) {
    throw ".vscode\tasks.json does not route the branding export task through the reproducible export-and-compile flow."
}

$taskInputIds = @($tasksConfig.inputs | ForEach-Object { $_.id })
if ('phaseId' -notin $taskInputIds) {
    throw ".vscode\tasks.json is missing the 'phaseId' input."
}
if ('phaseTaskId' -notin $taskInputIds) {
    throw ".vscode\tasks.json is missing the 'phaseTaskId' input."
}
Write-Host ' - OK: phase workflow tasks, branding export task, and inputs are present'

$gitattributesPath = Assert-FileExists -RelativePath '.gitattributes'
$gitattributes = Get-Content -Raw -LiteralPath $gitattributesPath
foreach ($expectedLine in @(
    '*.md text eol=lf',
    '*.json text eol=lf',
    '*.mjs text eol=lf',
    '*.yml text eol=lf',
    '*.yaml text eol=lf',
    '.githooks/* text eol=lf',
    '*.ps1 text eol=lf',
    '*.bat text eol=crlf',
    '*.cmd text eol=crlf'
)) {
    if ($gitattributes -notmatch [regex]::Escape($expectedLine)) {
        throw ".gitattributes is missing '$expectedLine'."
    }
}
Write-Host ' - OK: line ending rules are present'

$prePushHookPath = Assert-FileExists -RelativePath '.githooks\pre-push'
$prePushHookContents = Get-Content -Raw -LiteralPath $prePushHookPath
if ($prePushHookContents -notmatch [regex]::Escape('refs/heads/main')) {
    throw '.githooks\pre-push is missing the origin/main protection.'
}
if ($prePushHookContents -notmatch [regex]::Escape('CATASTROSWITCH_ALLOW_MAIN_PUSH')) {
    throw '.githooks\pre-push is missing the explicit override guard.'
}
Write-Host ' - OK: control-repo pre-push hook is present'

$gitignorePath = Assert-FileExists -RelativePath '.gitignore'
$gitignoreContents = Get-Content -Raw -LiteralPath $gitignorePath
if ($gitignoreContents -notmatch [regex]::Escape('*.local.code-workspace')) {
    throw ".gitignore is missing '*.local.code-workspace'."
}
Write-Host ' - OK: local workspace files are ignored'

$workspaceScriptPath = Assert-FileExists -RelativePath 'scripts\new-local-workspace.ps1'
$workspaceScriptContents = Get-Content -Raw -LiteralPath $workspaceScriptPath
if ($workspaceScriptContents -notmatch [regex]::Escape("CatastroSwitch.local.code-workspace")) {
    throw 'scripts\new-local-workspace.ps1 is missing the expected local workspace default.'
}
Write-Host ' - OK: local workspace generator is present'

$phaseWorkflowHelperPath = Assert-FileExists -RelativePath 'scripts\phase-workflow-helpers.ps1'
$phaseWorkflowHelperContents = Get-Content -Raw -LiteralPath $phaseWorkflowHelperPath
$null = Assert-FileExists -RelativePath 'scripts\new-phase-branch.ps1'
$null = Assert-FileExists -RelativePath 'scripts\new-phase-task-branch.ps1'
$phaseStateScriptPath = Assert-FileExists -RelativePath 'scripts\new-phase-state.ps1'
$phaseStateScriptContents = Get-Content -Raw -LiteralPath $phaseStateScriptPath
$brandingExportScriptPath = Assert-FileExists -RelativePath 'scripts\export-fork-branding-assets.ps1'
$brandingExportScriptContents = Get-Content -Raw -LiteralPath $brandingExportScriptPath
if ($phaseWorkflowHelperContents -notmatch [regex]::Escape('.catastroswitch\phase-state')) {
    throw 'scripts\phase-workflow-helpers.ps1 is missing the default phase state path.'
}
if ($phaseStateScriptContents -notmatch [regex]::Escape('Get-DefaultPhaseStatePath')) {
    throw 'scripts\new-phase-state.ps1 is missing the shared phase state path helper call.'
}
if ($brandingExportScriptContents -notmatch [regex]::Escape('branding-assets.manifest.json')) {
    throw 'scripts\export-fork-branding-assets.ps1 is missing the shared branding manifest reference.'
}
if ($brandingExportScriptContents -notmatch [regex]::Escape('CompileFork')) {
    throw 'scripts\export-fork-branding-assets.ps1 is missing the fork compile step for the reproducible branding flow.'
}
Write-Host ' - OK: phase workflow helper scripts and branding export script are present'

$forkReadmePath = Assert-FileExists -RelativePath 'fork\README.md'
$forkReadmeContents = Get-Content -Raw -LiteralPath $forkReadmePath
if ($forkReadmeContents -notmatch [regex]::Escape('tooling\README.md')) {
    throw 'fork\README.md is missing the tooling policy reference.'
}

$toolingReadmePath = Assert-FileExists -RelativePath 'fork\tooling\README.md'
$toolingReadmeContents = Get-Content -Raw -LiteralPath $toolingReadmePath
if ($toolingReadmeContents -notmatch [regex]::Escape('tsconfig.catastroswitch.strict.json')) {
    throw 'fork\tooling\README.md is missing the tsconfig policy reference.'
}
if ($toolingReadmeContents -notmatch [regex]::Escape('eslint.catastroswitch.config.mjs')) {
    throw 'fork\tooling\README.md is missing the ESLint policy reference.'
}
$brandingManifest = Read-JsonFile -RelativePath 'fork\tooling\branding-assets.manifest.json'
Assert-RequiredProperties -InputObject $brandingManifest -RequiredProperties @('version', 'sourcePolicy', 'targets') -Description 'branding manifest root'
Assert-IntegerMinimum -Value (Get-PropertyValue -InputObject $brandingManifest -PropertyName 'version') -Minimum 1 -Description 'branding manifest version'
$brandingSourcePolicy = Get-PropertyValue -InputObject $brandingManifest -PropertyName 'sourcePolicy'
Assert-RequiredProperties -InputObject $brandingSourcePolicy -RequiredProperties @('rasterIconMaster', 'workbenchIconSource', 'iconPreview') -Description 'branding manifest sourcePolicy'
$brandingRasterIconMaster = Get-PropertyValue -InputObject $brandingSourcePolicy -PropertyName 'rasterIconMaster'
$brandingWorkbenchIconSource = Get-PropertyValue -InputObject $brandingSourcePolicy -PropertyName 'workbenchIconSource'
$brandingIconPreview = Get-PropertyValue -InputObject $brandingSourcePolicy -PropertyName 'iconPreview'
Assert-StringValue -Value $brandingRasterIconMaster -Description 'branding manifest sourcePolicy.rasterIconMaster'
Assert-StringValue -Value $brandingWorkbenchIconSource -Description 'branding manifest sourcePolicy.workbenchIconSource'
Assert-StringValue -Value $brandingIconPreview -Description 'branding manifest sourcePolicy.iconPreview'
if ($brandingRasterIconMaster -ne 'assets/logo.svg') {
    throw 'fork\tooling\branding-assets.manifest.json must keep assets/logo.svg as the shipped icon master.'
}
if ($brandingWorkbenchIconSource -ne 'assets/logo.svg') {
    throw 'fork\tooling\branding-assets.manifest.json must keep assets/logo.svg as the workbench SVG source.'
}
if ($brandingIconPreview -ne $brandingRasterIconMaster) {
    throw 'fork\tooling\branding-assets.manifest.json must keep iconPreview aligned with the shipped icon master.'
}
$null = Assert-FileExists -RelativePath $brandingRasterIconMaster
$null = Assert-FileExists -RelativePath $brandingWorkbenchIconSource
$null = Assert-FileExists -RelativePath $brandingIconPreview
$brandingTargets = @($brandingManifest.targets)
$brandingTargetSourcesById = @{}
foreach ($brandingTarget in $brandingTargets) {
    Assert-RequiredProperties -InputObject $brandingTarget -RequiredProperties @('id', 'source', 'forkRelativeOutput', 'format') -Description 'branding manifest target'

    $brandingTargetId = Get-PropertyValue -InputObject $brandingTarget -PropertyName 'id'
    $brandingTargetSource = Get-PropertyValue -InputObject $brandingTarget -PropertyName 'source'
    Assert-StringValue -Value $brandingTargetId -Description 'branding manifest target id'
    Assert-StringValue -Value $brandingTargetSource -Description "branding manifest target '$brandingTargetId'.source"
    $null = Assert-FileExists -RelativePath $brandingTargetSource
    $brandingTargetSourcesById[$brandingTargetId] = $brandingTargetSource

    if ($brandingTargetId -eq 'workbench-code-icon') {
        if ($brandingTargetSource -ne $brandingWorkbenchIconSource) {
            throw "branding manifest target '$brandingTargetId' must use $brandingWorkbenchIconSource as its SVG source."
        }

        continue
    }

    if ($brandingTargetSource -ne $brandingRasterIconMaster) {
        throw "branding manifest target '$brandingTargetId' must use $brandingRasterIconMaster for packaged and raster outputs."
    }
}
$brandingOutputPaths = @($brandingTargets | ForEach-Object { Get-PropertyValue -InputObject $_ -PropertyName 'forkRelativeOutput' })
foreach ($expectedBrandingOutput in @(
    'resources/win32/code.ico',
    'resources/win32/code_70x70.png',
    'resources/win32/code_150x150.png',
    'resources/darwin/code.icns',
    'resources/linux/code.png',
    'src/vs/workbench/browser/media/code-icon.svg',
    'resources/server/favicon.ico',
    'resources/server/code-192.png',
    'resources/server/code-512.png'
)) {
    Assert-ContainsValue -Values $brandingOutputPaths -ExpectedValue $expectedBrandingOutput -Description 'branding manifest targets'
}
if ($brandingTargetSourcesById['workbench-code-icon'] -ne $brandingWorkbenchIconSource) {
    throw 'branding manifest workbench target is not aligned with sourcePolicy.workbenchIconSource.'
}
$null = Assert-FileExists -RelativePath 'fork\tooling\eslint.catastroswitch.config.mjs'
Write-Host ' - OK: fork tooling policy files and branding manifest are present'

$plannerAgentPath = Assert-FileExists -RelativePath '.github\agents\planner.agent.md'
$codingAgentPath = Assert-FileExists -RelativePath '.github\agents\coding-agent.agent.md'
$reviewerAgentPath = Assert-FileExists -RelativePath '.github\agents\reviewer.agent.md'
$gatekeeperAgentPath = Assert-FileExists -RelativePath '.github\agents\gatekeeper.agent.md'
$orchestratorAgentPath = Assert-FileExists -RelativePath '.github\agents\orchestrator.agent.md'
$phaseSkillPath = Assert-FileExists -RelativePath '.github\skills\fork-phase-execution\SKILL.md'

$plannerAgentContents = Get-Content -Raw -LiteralPath $plannerAgentPath
$codingAgentContents = Get-Content -Raw -LiteralPath $codingAgentPath
$reviewerAgentContents = Get-Content -Raw -LiteralPath $reviewerAgentPath
$gatekeeperAgentContents = Get-Content -Raw -LiteralPath $gatekeeperAgentPath
$orchestratorAgentContents = Get-Content -Raw -LiteralPath $orchestratorAgentPath
$phaseSkillContents = Get-Content -Raw -LiteralPath $phaseSkillPath

if ($plannerAgentContents -notmatch [regex]::Escape('agent: Coding Agent')) {
    throw '.github\agents\planner.agent.md is missing the Coding Agent handoff.'
}
if ($plannerAgentContents -notmatch [regex]::Escape('agent: Gatekeeper')) {
    throw '.github\agents\planner.agent.md is missing the Gatekeeper handoff.'
}
if ($plannerAgentContents -notmatch [regex]::Escape('docs/vscode-fork-source-map.md') -or $plannerAgentContents -notmatch [regex]::Escape('docs/vscode-fork-build-runbook.md')) {
    throw '.github\agents\planner.agent.md is missing the current source-map or build-runbook planning inputs.'
}
if ($plannerAgentContents -notmatch [regex]::Escape('schemas/workspace-registry.schema.json') -or $plannerAgentContents -notmatch [regex]::Escape('examples/workspace-registry.sample.json')) {
    throw '.github\agents\planner.agent.md is missing the conditional registry/schema planning inputs.'
}
if ($plannerAgentContents -notmatch [regex]::Escape('docs/vscode-fork-branding-assets.md')) {
    throw '.github\agents\planner.agent.md is missing the conditional branding planning input.'
}
if ($plannerAgentContents -notmatch [regex]::Escape('Reviewer `Pass`')) {
    throw '.github\agents\planner.agent.md is missing the Gatekeeper timing guardrail.'
}
if ($codingAgentContents -notmatch [regex]::Escape('name: Coding Agent')) {
    throw '.github\agents\coding-agent.agent.md is missing the Coding Agent name.'
}
if ($codingAgentContents -notmatch [regex]::Escape('agent: Reviewer')) {
    throw '.github\agents\coding-agent.agent.md is missing the Reviewer handoff.'
}
if ($reviewerAgentContents -notmatch [regex]::Escape('Outcome: Pass') -or $reviewerAgentContents -notmatch [regex]::Escape('Outcome: Error')) {
    throw '.github\agents\reviewer.agent.md is missing the required Pass/Error output contract.'
}
if ($gatekeeperAgentContents -notmatch [regex]::Escape('Outcome: Pass') -or $gatekeeperAgentContents -notmatch [regex]::Escape('Outcome: Error')) {
    throw '.github\agents\gatekeeper.agent.md is missing the required Pass/Error output contract.'
}
if ($orchestratorAgentContents -notmatch [regex]::Escape('agent: Planner') -or $orchestratorAgentContents -notmatch [regex]::Escape('agent: Gatekeeper')) {
    throw '.github\agents\orchestrator.agent.md is missing the required phase orchestration handoffs.'
}
if ($orchestratorAgentContents -notmatch [regex]::Escape('phase state artifact')) {
    throw '.github\agents\orchestrator.agent.md is missing the phase state artifact guidance.'
}
if ($orchestratorAgentContents -notmatch [regex]::Escape('scripts\new-phase-branch.ps1')) {
    throw '.github\agents\orchestrator.agent.md is missing the phase branch creation guidance.'
}
if ($orchestratorAgentContents -notmatch [regex]::Escape('scripts\new-phase-task-branch.ps1')) {
    throw '.github\agents\orchestrator.agent.md is missing the sibling task branch guidance.'
}
if ($phaseSkillContents -notmatch [regex]::Escape('Gatekeeper') -or $phaseSkillContents -notmatch [regex]::Escape('Reviewer')) {
    throw '.github\skills\fork-phase-execution\SKILL.md is missing the phase execution loop.'
}
if ($phaseSkillContents -notmatch [regex]::Escape('phase state artifact')) {
    throw '.github\skills\fork-phase-execution\SKILL.md is missing the phase state artifact guidance.'
}
Write-Host ' - OK: phase execution agent graph is present'

$workflowPath = Assert-FileExists -RelativePath '.github\workflows\validate-control-repo.yml'
$workflowContents = Get-Content -Raw -LiteralPath $workflowPath
if ($workflowContents -notmatch 'scripts[\\/]+validate-control-repo\.ps1') {
    throw '.github\workflows\validate-control-repo.yml does not run the shared validation script.'
}
if ($workflowContents -notmatch [regex]::Escape('"fork/**"')) {
    throw '.github\workflows\validate-control-repo.yml is missing the fork/** path filter.'
}
Write-Host ' - OK: CI workflow uses the shared validation script'

$prTemplatePath = Assert-FileExists -RelativePath '.github\pull_request_template.md'
$prTemplateContents = Get-Content -Raw -LiteralPath $prTemplatePath
if ($prTemplateContents -notmatch [regex]::Escape('.\scripts\validate-control-repo.ps1')) {
    throw '.github\pull_request_template.md is missing the shared validation command.'
}
if ($prTemplateContents -notmatch [regex]::Escape('## Phase workflow')) {
    throw '.github\pull_request_template.md is missing the phase workflow section.'
}
if ($prTemplateContents -notmatch [regex]::Escape('Phase state artifact:')) {
    throw '.github\pull_request_template.md is missing the phase state artifact field.'
}
if ($prTemplateContents -notmatch [regex]::Escape('.catastroswitch\phase-state\<phase-id>.phase-state.json')) {
    throw '.github\pull_request_template.md is missing the default phase state artifact path example.'
}
if ($prTemplateContents -notmatch [regex]::Escape('Gatekeeper result (`Pass` or `Error`):')) {
    throw '.github\pull_request_template.md is missing the Gatekeeper result field.'
}
Write-Host ' - OK: pull request template is present'

$forkBacklogPath = Assert-FileExists -RelativePath 'docs\fork-backlog.md'
$forkBacklogContents = Get-Content -Raw -LiteralPath $forkBacklogPath
if ($forkBacklogContents -match 'work-package') {
    throw 'docs\fork-backlog.md still references the retired work-package execution model.'
}
if ($forkBacklogContents -notmatch [regex]::Escape('phase-specific task graph')) {
    throw 'docs\fork-backlog.md is missing the phase-specific execution guidance.'
}

$forkRunbookPath = Assert-FileExists -RelativePath 'docs\vscode-fork-build-runbook.md'
$forkRunbookContents = Get-Content -Raw -LiteralPath $forkRunbookPath
if ($forkRunbookContents -match [regex]::Escape('multiagent/main')) {
    throw 'docs\vscode-fork-build-runbook.md still references the retired multiagent/main branch strategy.'
}
if ($forkRunbookContents -notmatch [regex]::Escape('one active phase branch per selected phase')) {
    throw 'docs\vscode-fork-build-runbook.md is missing the phase branch strategy guidance.'
}
if ($forkRunbookContents -notmatch [regex]::Escape('short-lived sibling task branches or worktrees named from the current phase branch')) {
    throw 'docs\vscode-fork-build-runbook.md is missing the sibling task branch guidance.'
}
if ($forkRunbookContents -notmatch [regex]::Escape('export-fork-branding-assets.ps1')) {
    throw 'docs\vscode-fork-build-runbook.md is missing the branding export workflow command.'
}

$readmePath = Assert-FileExists -RelativePath 'README.md'
$readmeContents = Get-Content -Raw -LiteralPath $readmePath
if ($readmeContents -notmatch [regex]::Escape('docs\vscode-fork-branding-assets.md')) {
    throw 'README.md is missing the branding asset workflow doc reference.'
}

$contributingPath = Assert-FileExists -RelativePath 'CONTRIBUTING.md'
$contributingContents = Get-Content -Raw -LiteralPath $contributingPath
if ($contributingContents -notmatch [regex]::Escape('export-fork-branding-assets.ps1')) {
    throw 'CONTRIBUTING.md is missing the branding export workflow command.'
}
Write-Host ' - OK: fork execution docs reflect the phase branch workflow'

Write-Host 'Control repo validation passed.'

