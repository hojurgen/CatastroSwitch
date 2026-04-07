[CmdletBinding()]
param(
    [string]$LogoSvgPath = 'C:\CatastroSwitch\assets\logo.svg',
    [string]$OutputRoot = 'C:\CatastroSwitch\out\branding',
    [switch]$RequireMagick
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -Path $LogoSvgPath)) {
    throw "Branding asset not found: $LogoSvgPath"
}

New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null

$magick = Get-Command -Name 'magick' -ErrorAction SilentlyContinue
$copiedSvgPath = Join-Path -Path $OutputRoot -ChildPath 'logo.svg'
Copy-Item -Path $LogoSvgPath -Destination $copiedSvgPath -Force

$requestedOutputs = @(
    @{ Name = 'app-16.png'; Size = 16 },
    @{ Name = 'app-32.png'; Size = 32 },
    @{ Name = 'app-64.png'; Size = 64 },
    @{ Name = 'app-70.png'; Size = 70 },
    @{ Name = 'app-128.png'; Size = 128 },
    @{ Name = 'app-150.png'; Size = 150 },
    @{ Name = 'app-192.png'; Size = 192 },
    @{ Name = 'app-256.png'; Size = 256 },
    @{ Name = 'app-512.png'; Size = 512 },
    @{ Name = 'app-1024.png'; Size = 1024 }
)

if (-not $magick) {
    $manifest = [ordered]@{
        generatedAt = (Get-Date).ToString('o')
        source = $LogoSvgPath
        copiedSvg = $copiedSvgPath
        status = 'magick-not-found'
        requestedOutputs = $requestedOutputs.Name
    }

    $manifest | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path -Path $OutputRoot -ChildPath 'branding-manifest.json') -Encoding utf8

    $message = 'ImageMagick (magick) is not installed. The canonical SVG was copied, but raster product icons were not generated.'
    if ($RequireMagick) {
        throw $message
    }

    Write-Warning $message
    return
}

$pngPaths = @()
foreach ($output in $requestedOutputs) {
    $destination = Join-Path -Path $OutputRoot -ChildPath $output.Name
    & $magick.Source -background none -density 384 $LogoSvgPath -resize "$($output.Size)x$($output.Size)" $destination
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to generate $destination"
    }

    $pngPaths += $destination
}

$icoPath = Join-Path -Path $OutputRoot -ChildPath 'app.ico'
$icoInputs = @(
    (Join-Path -Path $OutputRoot -ChildPath 'app-16.png'),
    (Join-Path -Path $OutputRoot -ChildPath 'app-32.png'),
    (Join-Path -Path $OutputRoot -ChildPath 'app-64.png'),
    (Join-Path -Path $OutputRoot -ChildPath 'app-256.png')
)
& $magick.Source @icoInputs $icoPath
if ($LASTEXITCODE -ne 0) {
    throw "Failed to generate $icoPath"
}

$faviconPath = Join-Path -Path $OutputRoot -ChildPath 'favicon.ico'
$faviconInputs = @(
    (Join-Path -Path $OutputRoot -ChildPath 'app-16.png'),
    (Join-Path -Path $OutputRoot -ChildPath 'app-32.png'),
    (Join-Path -Path $OutputRoot -ChildPath 'app-64.png')
)
& $magick.Source @faviconInputs $faviconPath
if ($LASTEXITCODE -ne 0) {
    throw "Failed to generate $faviconPath"
}

$icnsPath = Join-Path -Path $OutputRoot -ChildPath 'app.icns'
$iconutil = Get-Command -Name 'iconutil' -ErrorAction SilentlyContinue
$generatedIcns = $false
if ($iconutil) {
    $iconsetPath = Join-Path -Path $OutputRoot -ChildPath 'app.iconset'
    if (Test-Path -Path $iconsetPath) {
        Remove-Item -Path $iconsetPath -Recurse -Force
    }

    New-Item -ItemType Directory -Path $iconsetPath -Force | Out-Null

    $iconsetMappings = @{
        'app-16.png' = 'icon_16x16.png'
        'app-32.png' = @('icon_16x16@2x.png', 'icon_32x32.png')
        'app-64.png' = 'icon_32x32@2x.png'
        'app-128.png' = 'icon_128x128.png'
        'app-256.png' = @('icon_128x128@2x.png', 'icon_256x256.png')
        'app-512.png' = @('icon_256x256@2x.png', 'icon_512x512.png')
        'app-1024.png' = 'icon_512x512@2x.png'
    }

    foreach ($sourceName in $iconsetMappings.Keys) {
        $targets = @($iconsetMappings[$sourceName])
        foreach ($targetName in $targets) {
            Copy-Item -Path (Join-Path -Path $OutputRoot -ChildPath $sourceName) -Destination (Join-Path -Path $iconsetPath -ChildPath $targetName) -Force
        }
    }

    & $iconutil.Source -c icns $iconsetPath -o $icnsPath
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to generate $icnsPath with iconutil"
    }

    $generatedIcns = $true
}
elseif (Test-Path -Path $icnsPath) {
    Remove-Item -Path $icnsPath -Force
}

$manifest = [ordered]@{
    generatedAt = (Get-Date).ToString('o')
    source = $LogoSvgPath
    copiedSvg = $copiedSvgPath
    iconFiles = @($requestedOutputs.Name) + @('app.ico', 'favicon.ico')
    darwinIcnsGenerated = $generatedIcns
}

if ($generatedIcns) {
    $manifest.iconFiles += 'app.icns'
}

$manifest | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path -Path $OutputRoot -ChildPath 'branding-manifest.json') -Encoding utf8

if (-not $generatedIcns) {
    Write-Warning 'iconutil was not found. Windows, Linux, and server branding assets were generated, but app.icns was skipped.'
}

Write-Host "Generated branding assets in $OutputRoot"