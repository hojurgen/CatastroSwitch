[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ForkRoot,
    [string]$ManifestPath = '',
    [string]$StagingRoot = (Join-Path ([System.IO.Path]::GetTempPath()) 'CatastroSwitch-branding'),
    [switch]$PlanOnly,
    [switch]$RequireComplete,
    [switch]$CompileFork
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

function Get-CanonicalTargetSourceRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Target
    )

    $targetId = [string]$Target.id
    if ($targetId -eq 'workbench-code-icon') {
        return $script:BrandingWorkbenchIconSource
    }

    return $script:BrandingRasterIconMaster
}

function Resolve-CanonicalTargetSourcePath {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Target,
        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    $targetId = [string]$Target.id
    $expectedSource = Get-CanonicalTargetSourceRelativePath -Target $Target
    if ([string]::IsNullOrWhiteSpace($expectedSource)) {
        throw "Branding source policy is incomplete for target '$targetId'."
    }

    $declaredSource = if ($Target.PSObject.Properties['source']) { [string]$Target.source } else { '' }
    if ($declaredSource -ne $expectedSource) {
        throw "Branding target '$targetId' must use $expectedSource."
    }

    return Resolve-ExistingPath -Path $expectedSource -BasePath $repoRoot -Description $Description
}

function Assert-TargetVariantsUseCanonicalSource {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Target
    )

    if (-not $Target.PSObject.Properties['sizeVariants']) {
        return
    }

    $targetId = [string]$Target.id
    $expectedSource = Get-CanonicalTargetSourceRelativePath -Target $Target
    foreach ($variant in @($Target.sizeVariants)) {
        if (-not $variant.PSObject.Properties['source']) {
            continue
        }

        $variantSource = [string]$variant.source
        if ([string]::IsNullOrWhiteSpace($variantSource)) {
            continue
        }

        if ($variantSource -ne $expectedSource) {
            throw "Branding target '$targetId' size variants must use $expectedSource."
        }
    }
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

function Invoke-ForkCompile {
    $forkPackageJsonPath = Join-Path $ForkRoot 'package.json'
    if (-not (Test-Path -LiteralPath $forkPackageJsonPath)) {
        throw "Fork root does not look like a Node.js checkout: $ForkRoot"
    }

    $npmPath = Get-ToolPath -Name 'npm'
    if (-not $npmPath) {
        throw "npm is required when -CompileFork is used. Install Node.js, then rerun the script."
    }

    Write-Host "Compiling runtime fork in $ForkRoot ..."
    Push-Location $ForkRoot
    try {
        & $npmPath 'run' 'compile'
        if ($LASTEXITCODE -ne 0) {
            throw 'Fork compile failed while refreshing branding outputs.'
        }
    }
    finally {
        Pop-Location
    }
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

function Test-ImagesPixelIdentical {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExistingPath,
        [Parameter(Mandatory = $true)]
        [string]$CandidatePath
    )

    if (-not (Test-Path -LiteralPath $ExistingPath) -or -not (Test-Path -LiteralPath $CandidatePath)) {
        return $false
    }

    $compareMetricPath = Join-Path $StagingRoot ([System.Guid]::NewGuid().ToString() + '.compare.txt')
    try {
        $compareProcess = Start-Process -FilePath $script:MagickPath -ArgumentList @('compare', '-metric', 'AE', $ExistingPath, $CandidatePath, 'null:') -RedirectStandardError $compareMetricPath -NoNewWindow -Wait -PassThru
        $compareMetric = if (Test-Path -LiteralPath $compareMetricPath) {
            (Get-Content -LiteralPath $compareMetricPath -Raw).Trim()
        }
        else {
            ''
        }

        if ($compareMetric -match '^(?<pixels>\d+(\.\d+)?)(\s+\([^\)]+\))?$') {
            return ([double]$Matches.pixels -eq 0)
        }

        return ($compareProcess.ExitCode -eq 0)
    }
    finally {
        if (Test-Path -LiteralPath $compareMetricPath) {
            Remove-Item -LiteralPath $compareMetricPath -Force
        }
    }
}

function Publish-GeneratedTarget {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CandidatePath,
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        [switch]$PreservePixelEquivalentPng
    )

    New-ParentDirectory -Path $OutputPath

    if (Test-Path -LiteralPath $OutputPath) {
        $existingHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $OutputPath).Hash
        $candidateHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $CandidatePath).Hash
        if ($existingHash -eq $candidateHash) {
            Remove-Item -LiteralPath $CandidatePath -Force
            return 'unchanged'
        }

        if ($PreservePixelEquivalentPng -and (Test-ImagesPixelIdentical -ExistingPath $OutputPath -CandidatePath $CandidatePath)) {
            Remove-Item -LiteralPath $CandidatePath -Force
            return 'unchanged'
        }
    }

    Move-Item -LiteralPath $CandidatePath -Destination $OutputPath -Force
    return 'updated'
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

    $sourcePath = Resolve-CanonicalTargetSourcePath -Target $Target -Description 'Branding source asset'
    $outputPath = Resolve-ForkPath -RelativePath $Target.forkRelativeOutput
    $stagingDirectory = Join-Path $StagingRoot $Target.id
    $null = New-Item -ItemType Directory -Path $stagingDirectory -Force

    $variantPaths = @()
    foreach ($size in @($Target.sizes)) {
        $variantPath = Join-Path $stagingDirectory ("$size.png")
        $variant = Get-TargetVariantForSize -Target $Target -Size ([int]$size)
        $variantSourcePath = $sourcePath

        New-SquarePng -SourcePath $variantSourcePath -OutputPath $variantPath -Size ([int]$size) -Variant $variant
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

    $sourcePath = Resolve-CanonicalTargetSourcePath -Target $Target -Description 'Branding source asset'
    $outputPath = Resolve-ForkPath -RelativePath $Target.forkRelativeOutput
    $candidatePath = Join-Path $StagingRoot ("$($Target.id)-candidate.png")
    New-SquarePng -SourcePath $sourcePath -OutputPath $candidatePath -Size ([int]$Target.size)
    $status = Publish-GeneratedTarget -CandidatePath $candidatePath -OutputPath $outputPath -PreservePixelEquivalentPng

    return [pscustomobject]@{
        Output = $Target.forkRelativeOutput
        Format = $Target.format
        Status = $status
    }
}

function Copy-AssetTarget {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Target
    )

    $sourcePath = Resolve-CanonicalTargetSourcePath -Target $Target -Description 'Branding source asset'
    $outputPath = Resolve-ForkPath -RelativePath $Target.forkRelativeOutput
    New-ParentDirectory -Path $outputPath
    Copy-Item -LiteralPath $sourcePath -Destination $outputPath -Force

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

    $sourcePath = Resolve-CanonicalTargetSourcePath -Target $Target -Description 'Branding source asset'
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

$script:BrandingRasterIconMaster = $null
if ($manifest.PSObject.Properties['sourcePolicy'] -and $manifest.sourcePolicy.PSObject.Properties['rasterIconMaster']) {
    $script:BrandingRasterIconMaster = [string]$manifest.sourcePolicy.rasterIconMaster
}

$script:BrandingWorkbenchIconSource = $null
if ($manifest.PSObject.Properties['sourcePolicy'] -and $manifest.sourcePolicy.PSObject.Properties['workbenchIconSource']) {
    $script:BrandingWorkbenchIconSource = [string]$manifest.sourcePolicy.workbenchIconSource
}

$script:BrandingIconPreview = $null
if ($manifest.PSObject.Properties['sourcePolicy'] -and $manifest.sourcePolicy.PSObject.Properties['iconPreview']) {
    $script:BrandingIconPreview = [string]$manifest.sourcePolicy.iconPreview
}

if ($script:BrandingRasterIconMaster -ne 'assets/logo.svg') {
    throw 'Branding manifest must keep assets/logo.svg as the shipped raster icon master.'
}
if ($script:BrandingWorkbenchIconSource -ne 'assets/logo.svg') {
    throw 'Branding manifest must keep assets/logo.svg as the workbench SVG source.'
}
if ($script:BrandingIconPreview -ne 'assets/logo.svg') {
    throw 'Branding manifest must keep assets/logo.svg as the icon preview source.'
}

$null = Resolve-ExistingPath -Path $script:BrandingRasterIconMaster -BasePath $repoRoot -Description 'Branding raster icon master'
$null = Resolve-ExistingPath -Path $script:BrandingWorkbenchIconSource -BasePath $repoRoot -Description 'Branding workbench icon source'
$null = Resolve-ExistingPath -Path $script:BrandingIconPreview -BasePath $repoRoot -Description 'Branding icon preview source'

foreach ($target in $targets) {
    $null = Resolve-CanonicalTargetSourcePath -Target $target -Description 'Branding source asset'
    Assert-TargetVariantsUseCanonicalSource -Target $target
}

$script:MagickPath = Get-ToolPath -Name 'magick'
$script:IconutilPath = Get-ToolPath -Name 'iconutil'
$script:NpxPath = Get-ToolPath -Name 'npx'

if ($script:BrandingRasterIconMaster) {
    Write-Host "Branding raster icon master: $($script:BrandingRasterIconMaster)"
}
if ($script:BrandingWorkbenchIconSource) {
    Write-Host "Branding workbench icon source: $($script:BrandingWorkbenchIconSource)"
}
Write-Host "Fork root: $ForkRoot"
Write-Host "Manifest: $resolvedManifestPath"

if ($PlanOnly) {
    Write-Host 'Planned branding outputs:'
    foreach ($target in $targets) {
        $sizeSummary = if ($target.PSObject.Properties['sizes']) {
            (@($target.sizes) -join ', ')
        }
        elseif ($target.PSObject.Properties['size']) {
            [string]$target.size
        }
        else {
            'direct-copy'
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
    if ($CompileFork) {
        Write-Host "After export, the script will also run 'npm run compile' in $ForkRoot so the in-app workbench icon refreshes from the same control-repo source."
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
        'svg' { Copy-AssetTarget -Target $target }
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

    if ($result.Status -eq 'unchanged') {
        Write-Host " - unchanged $($result.Output) [$($result.Format)]"
        continue
    }

    Write-Warning "$($result.Output) [$($result.Format)] requires a manual follow-up: $($result.Details)"
}

$updatedWorkbenchIcon = @(
    $results | Where-Object {
        $_.Status -eq 'updated' -and $_.Output -eq 'src/vs/workbench/browser/media/code-icon.svg'
    }
).Count -gt 0

if ($CompileFork) {
    Invoke-ForkCompile
}
elseif ($updatedWorkbenchIcon) {
    Write-Host 'Next step in the runtime fork: run npm run compile before self-hosting so out/vs/workbench/browser/media/code-icon.svg picks up the exported workbench SVG.'
}

$pendingResults = @($results | Where-Object { $_.Status -ne 'updated' })
if ($RequireComplete -and $pendingResults.Count -gt 0) {
    throw 'Branding export completed with pending manual steps. Rerun on macOS with iconutil to finish the ICNS bundle.'
}