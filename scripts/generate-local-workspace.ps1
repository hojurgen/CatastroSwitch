[CmdletBinding()]
param(
    [string]$RegistryPath = 'C:\CatastroSwitch\examples\workspace-registry.sample.json',
    [string]$OutputPath = 'C:\CatastroSwitch\CatastroSwitch.local.code-workspace',
    [switch]$IncludeMissingWorkspaces
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -Path $RegistryPath)) {
    throw "Registry file not found: $RegistryPath"
}

$registry = Get-Content -Path $RegistryPath -Raw | ConvertFrom-Json -Depth 32

$folders = @(
    foreach ($workspace in $registry.workspaces) {
        if ($IncludeMissingWorkspaces -or (Test-Path -Path $workspace.localPath)) {
            [ordered]@{
                name = $workspace.label
                path = $workspace.localPath
            }
        }
    }
)

if (-not $folders) {
    throw 'No workspace folders were resolved. Use -IncludeMissingWorkspaces to include paths that do not yet exist.'
}

$workspaceDocument = [ordered]@{
    folders = $folders
    settings = [ordered]@{
        'task.quickOpen.detail' = $true
        'window.title' = 'CatastroSwitch maintenance'
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

$json = $workspaceDocument | ConvertTo-Json -Depth 10
Set-Content -Path $OutputPath -Value $json -Encoding utf8

Write-Host "Generated workspace: $OutputPath"
Write-Host "Resolved folders: $($folders.Count)"