[CmdletBinding()]
param(
    [ValidateSet('F0', 'F1', 'F2', 'F3', 'F4')]
    [string]$Phase,
    [ValidateSet('fresh_implementation', 'partial_implementation', 'reimplementation')]
    [string]$PhaseMode = 'fresh_implementation',
    [string]$ForkRoot = 'C:\src\vscode-multiagent',
    [string]$OutputPath,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'phase-workflow-helpers.ps1')

$usesForkRootOutput = $false

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $usesForkRootOutput = $true
    $OutputPath = Get-DefaultPhaseStatePath -ForkRoot $ForkRoot -Phase $Phase
}
elseif (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $usesForkRootOutput = $true
    $OutputPath = Join-Path $ForkRoot $OutputPath
}

if ($usesForkRootOutput -and -not (Test-Path -LiteralPath $ForkRoot -PathType Container)) {
    throw "Fork path not found: $ForkRoot"
}

$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory -and -not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
    $null = New-Item -ItemType Directory -Path $outputDirectory -Force
}

if ((Test-Path -LiteralPath $OutputPath -PathType Leaf) -and -not $Force) {
    throw "Phase state file already exists: $OutputPath. Use -Force to overwrite it."
}

$allowedWorktree = if (Test-Path -LiteralPath $ForkRoot -PathType Container) {
    $ForkRoot
}
else {
    ''
}

$phaseState = New-PhaseStateObject -Phase $Phase -PhaseMode $PhaseMode -AllowedWorktree $allowedWorktree
$phaseState | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8

Write-Host "Wrote phase state file: $OutputPath"
