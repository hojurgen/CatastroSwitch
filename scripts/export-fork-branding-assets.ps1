[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ForkRoot,
    [string]$ManifestPath = '',
    [string]$StagingRoot = (Join-Path ([System.IO.Path]::GetTempPath()) 'CatastroSwitch-branding'),
    [switch]$PlanOnly,
    [switch]$RequireComplete
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $repoRoot 'fork\tooling\branding-assets.manifest.json'
}

function Resolve-ExistingPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$BasePath,
        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    $candidate = if ([System.IO.Path]::IsPathRooted($Path)) {
        $Path
    }
    else {
        Join-Path $BasePath $Path
    }

    if (-not (Test-Path -LiteralPath $candidate)) {
        throw "$Description not found: $candidate"
    }

    return (Resolve-Path -LiteralPath $candidate).Path
}

function Resolve-ForkPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    return Join-Path $ForkRoot $RelativePath
}

function New-ParentDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        $null = New-Item -ItemType Directory -Path $parent -Force
    }
}

function Get-ToolPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $command = Get-Command -Name $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) {
        if ($command.PSObject.Properties['Source'] -and $command.Source) {
            return [string]$command.Source
        }

        if ($command.PSObject.Properties['Path'] -and $command.Path) {
            return [string]$command.Path
        }
    }

    if ($Name -eq 'magick') {
        $searchRoots = @(
            $env:ProgramFiles,
            ${env:ProgramFiles(x86)},
            (Join-Path $env:LOCALAPPDATA 'Programs')
        ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

        foreach ($root in $searchRoots) {
            $installDirectories = Get-ChildItem -Path $root -Directory -Filter 'ImageMagick-*' -ErrorAction SilentlyContinue
            foreach ($installDirectory in @($installDirectories)) {
                $magickPath = Join-Path $installDirectory.FullName 'magick.exe'
                if (Test-Path -LiteralPath $magickPath) {
                    return $magickPath
                }
            }
        }
    }

    return $null
}

function Invoke-Magick {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    & $script:MagickPath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "ImageMagick failed: magick $($Arguments -join ' ')"
    }
}

function Get-TargetVariantForSize {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Target,
        [Parameter(Mandatory = $true)]
        [int]$Size
    )

    if (-not $Target.PSObject.Properties['sizeVariants']) {
        return $null
    }

    foreach ($variant in @($Target.sizeVariants)) {
        if (-not $variant.PSObject.Properties['sizes']) {
            continue
        }

        $variantSizes = @($variant.sizes | ForEach-Object { [int]$_ })
        if ($Size -in $variantSizes) {
            return $variant
        }
    }

    return $null
}

function New-SquarePng {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        [Parameter(Mandatory = $true)]
        [int]$Size,
        [AllowNull()]
        [object]$Variant = $null
    )

    New-ParentDirectory -Path $OutputPath

    $arguments = @('-background', 'none')
    if ([System.IO.Path]::GetExtension($SourcePath).ToLowerInvariant() -eq '.svg') {
        $arguments += @('-density', '384')
    }

    $arguments += @(
        $SourcePath
    )

    if ($Variant -and $Variant.PSObject.Properties['crop']) {
        $crop = $Variant.crop
        $widthPercent = [int]$crop.widthPercent
        $heightPercent = [int]$crop.heightPercent
        $offsetX = if ($crop.PSObject.Properties['offsetX']) { [int]$crop.offsetX } else { 0 }
        $offsetY = if ($crop.PSObject.Properties['offsetY']) { [int]$crop.offsetY } else { 0 }
        $offsetXText = if ($offsetX -ge 0) { "+$offsetX" } else { "$offsetX" }
        $offsetYText = if ($offsetY -ge 0) { "+$offsetY" } else { "$offsetY" }

        $arguments += @(
            '-gravity', 'center',
            '-crop', "$($widthPercent)%x$($heightPercent)%$offsetXText$offsetYText",
            '+repage'
        )
    }

    $arguments += @(
        '-alpha', 'on',
        '-resize', "${Size}x${Size}",
        '-gravity', 'center',
        '-extent', "${Size}x${Size}",
        "PNG32:$OutputPath"
    )

    Invoke-Magick -Arguments $arguments
}

function New-IcoTarget {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Target
    )

    $sourcePath = Resolve-ExistingPath -Path $Target.source -BasePath $repoRoot -Description 'Branding source asset'
    $outputPath = Resolve-ForkPath -RelativePath $Target.forkRelativeOutput
    $stagingDirectory = Join-Path $StagingRoot $Target.id
    $null = New-Item -ItemType Directory -Path $stagingDirectory -Force

    $variantPaths = @()
    foreach ($size in @($Target.sizes)) {
        $variantPath = Join-Path $stagingDirectory ("$size.png")
        $variant = Get-TargetVariantForSize -Target $Target -Size ([int]$size)
        New-SquarePng -SourcePath $sourcePath -OutputPath $variantPath -Size ([int]$size) -Variant $variant
        $variantPaths += $variantPath
    }

    New-ParentDirectory -Path $outputPath
    Invoke-Magick -Arguments ($variantPaths + @($outputPath))

    return [pscustomobject]@{
        Output = $Target.forkRelativeOutput
        Format = $Target.format
        Status = 'updated'
    }
}

function New-PngTarget {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Target
    )

    $sourcePath = Resolve-ExistingPath -Path $Target.source -BasePath $repoRoot -Description 'Branding source asset'
    $outputPath = Resolve-ForkPath -RelativePath $Target.forkRelativeOutput
    New-SquarePng -SourcePath $sourcePath -OutputPath $outputPath -Size ([int]$Target.size)

    return [pscustomobject]@{
        Output = $Target.forkRelativeOutput
        Format = $Target.format
        Status = 'updated'
    }
}

function New-IcnsTarget {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Target
    )

    $sourcePath = Resolve-ExistingPath -Path $Target.source -BasePath $repoRoot -Description 'Branding source asset'
    $outputPath = Resolve-ForkPath -RelativePath $Target.forkRelativeOutput
    $iconsetDirectory = Join-Path (Join-Path $StagingRoot 'darwin') 'code.iconset'
    $null = New-Item -ItemType Directory -Path $iconsetDirectory -Force

    $variantMap = @(
        @{ FileName = 'icon_16x16.png'; Size = 16 },
        @{ FileName = 'icon_16x16@2x.png'; Size = 32 },
        @{ FileName = 'icon_32x32.png'; Size = 32 },
        @{ FileName = 'icon_32x32@2x.png'; Size = 64 },
        @{ FileName = 'icon_128x128.png'; Size = 128 },
        @{ FileName = 'icon_128x128@2x.png'; Size = 256 },
        @{ FileName = 'icon_256x256.png'; Size = 256 },
        @{ FileName = 'icon_256x256@2x.png'; Size = 512 },
        @{ FileName = 'icon_512x512.png'; Size = 512 },
        @{ FileName = 'icon_512x512@2x.png'; Size = 1024 }
    )

    foreach ($variant in $variantMap) {
        $variantPath = Join-Path $iconsetDirectory $variant.FileName
        New-SquarePng -SourcePath $sourcePath -OutputPath $variantPath -Size $variant.Size
    }

    New-ParentDirectory -Path $outputPath

    if ($script:IconutilPath) {
        & $script:IconutilPath '-c' 'icns' '-o' $outputPath $iconsetDirectory
        if ($LASTEXITCODE -ne 0) {
            throw "iconutil failed while packaging $($Target.forkRelativeOutput)."
        }

        return [pscustomobject]@{
            Output = $Target.forkRelativeOutput
            Format = $Target.format
            Status = 'updated'
        }
    }

    if ($script:NpxPath) {
        $iconGenOutputDirectory = Join-Path $StagingRoot 'darwin-icon-gen'
        $null = New-Item -ItemType Directory -Path $iconGenOutputDirectory -Force

        $iconGenOutput = & $script:NpxPath '--yes' 'icon-gen' '-i' $sourcePath '-o' $iconGenOutputDirectory '--icns' '--icns-name' 'code' '--icns-sizes' '16,32,64,128,256,512,1024' '-r' 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "icon-gen failed while packaging $($Target.forkRelativeOutput)."
        }

        foreach ($line in @($iconGenOutput)) {
            Write-Host $line
        }

        $generatedIcnsPath = Join-Path $iconGenOutputDirectory 'code.icns'
        if (-not (Test-Path -LiteralPath $generatedIcnsPath)) {
            throw "icon-gen did not produce the expected ICNS file: $generatedIcnsPath"
        }

        Copy-Item -LiteralPath $generatedIcnsPath -Destination $outputPath -Force

        return [pscustomobject]@{
            Output = $Target.forkRelativeOutput
            Format = $Target.format
            Status = 'updated'
        }
    }

    if (-not $script:IconutilPath) {
        return [pscustomobject]@{
            Output = $Target.forkRelativeOutput
            Format = $Target.format
            Status = 'pending-manual-step'
            Details = "Run iconutil on macOS with staged iconset: $iconsetDirectory"
        }
    }
}

if (-not (Test-Path -LiteralPath $ForkRoot)) {
    throw "Fork root not found: $ForkRoot"
}

$resolvedManifestPath = Resolve-ExistingPath -Path $ManifestPath -BasePath $repoRoot -Description 'Branding manifest'
$manifest = Get-Content -Raw -LiteralPath $resolvedManifestPath | ConvertFrom-Json
$targets = @($manifest.targets)
if ($targets.Count -eq 0) {
    throw 'Branding manifest does not define any export targets.'
}

$script:MagickPath = Get-ToolPath -Name 'magick'
$script:IconutilPath = Get-ToolPath -Name 'iconutil'
$script:NpxPath = Get-ToolPath -Name 'npx'

Write-Host "Branding icon master: $($manifest.sourcePolicy.iconMaster)"
Write-Host "Fork root: $ForkRoot"
Write-Host "Manifest: $resolvedManifestPath"

if ($PlanOnly) {
    Write-Host 'Planned branding outputs:'
    foreach ($target in $targets) {
        $sizeSummary = if ($target.PSObject.Properties['sizes']) {
            (@($target.sizes) -join ', ')
        }
        else {
            [string]$target.size
        }

        Write-Host " - $($target.forkRelativeOutput) [$($target.format)] from $($target.source) sizes: $sizeSummary"
    }

    if (-not $script:MagickPath) {
        Write-Warning "ImageMagick 'magick' is not installed. Install it before running the full export."
    }
    if (-not $script:IconutilPath -and $script:NpxPath) {
        Write-Host "macOS 'iconutil' is not available on this machine. The script will use 'npx icon-gen' for ICNS packaging."
    }
    elseif (-not $script:IconutilPath) {
        Write-Warning "macOS 'iconutil' is not available on this machine. The ICNS bundle will require a macOS packaging step."
    }

    return
}

if (-not $script:MagickPath) {
    throw "ImageMagick 'magick' is required to export CatastroSwitch branding assets. Install it, then rerun the script."
}

if (Test-Path -LiteralPath $StagingRoot) {
    Remove-Item -LiteralPath $StagingRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $StagingRoot -Force

$results = New-Object System.Collections.Generic.List[object]

foreach ($target in $targets) {
    $result = switch ($target.format) {
        'png' { New-PngTarget -Target $target }
        'ico' { New-IcoTarget -Target $target }
        'icns' { New-IcnsTarget -Target $target }
        default { throw "Unsupported branding target format '$($target.format)' in $($target.id)." }
    }

    $results.Add($result)
}

Write-Host 'Branding export summary:'
foreach ($result in $results) {
    if ($result.Status -eq 'updated') {
        Write-Host " - updated $($result.Output) [$($result.Format)]"
        continue
    }

    Write-Warning "$($result.Output) [$($result.Format)] requires a manual follow-up: $($result.Details)"
}

$pendingResults = @($results | Where-Object { $_.Status -ne 'updated' })
if ($RequireComplete -and $pendingResults.Count -gt 0) {
    throw 'Branding export completed with pending manual steps. Rerun on macOS with iconutil to finish the ICNS bundle.'
}