[CmdletBinding()]
param(
    [string]$ForkRoot = 'C:\src\vscode-multiagent',
    [string]$OutputPath = 'CatastroSwitch.local.code-workspace'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot

if (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $repoRoot $OutputPath
}

if (-not (Test-Path -LiteralPath $ForkRoot -PathType Container)) {
    throw "Fork path not found: $ForkRoot"
}

$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory -and -not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
    $null = New-Item -ItemType Directory -Path $outputDirectory -Force
}

$workspace = [ordered]@{
    folders = @(
        [ordered]@{
            name = 'CatastroSwitch control repo'
            path = $repoRoot
        },
        [ordered]@{
            name = 'VS Code fork'
            path = $ForkRoot
        }
    )
    settings = [ordered]@{
        'task.quickOpen.detail' = $true
    }
    extensions = [ordered]@{
        recommendations = @(
            'github.copilot',
            'github.copilot-chat',
            'davidanson.vscode-markdownlint',
            'ms-vscode.powershell'
        )
    }
}

$workspace | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding utf8

Write-Host "Wrote local workspace file: $OutputPath"

