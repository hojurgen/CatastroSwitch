# VS Code Fork Branding Assets

This document defines how `CatastroSwitch` branding sources in the control repo map to the generated runtime assets in the real VS Code fork.

Keep the repository boundary explicit:

- `C:\CatastroSwitch` owns the source artwork, export manifest, and workflow guidance.
- `C:\src\vscode-multiagent` owns the generated runtime binaries that the product actually ships.

## Runtime fork targets

The current runtime fork surfaces that carry the product icon set are:

- `resources\win32\code.ico`
- `resources\win32\code_70x70.png`
- `resources\win32\code_150x150.png`
- `resources\darwin\code.icns`
- `resources\linux\code.png`
- `src\vs\workbench\browser\media\code-icon.svg`
- `resources\server\favicon.ico`
- `resources\server\code-192.png`
- `resources\server\code-512.png`

Those paths are the replacement targets for CatastroSwitch branding.

## Source policy

Use `assets\logo.svg` as the shipped icon master for both generated raster outputs and direct SVG copy surfaces.

Why this single-source setup is deliberate:

- `assets\logo.svg` is now the current square transparent master in the control repo.
- the export script can rasterize that SVG into ICO, PNG, and ICNS outputs for the packaged desktop and server surfaces.
- the workbench target is copied directly from the same SVG, which keeps the packaged icons and in-app product icon aligned.

Use `assets\logo.svg` as the quick preview or fallback source when a smaller local preview is enough.

Treat everything under `assets\draft\` as draft, historical, or experimental artwork unless a manifest target explicitly references it.

That includes the legacy wordmark, rounded, circular, taskbar, and archived logo variants kept for comparison or future experiments.

## Machine-readable export spec

The canonical source-to-output map lives in:

```text
fork\tooling\branding-assets.manifest.json
```

That manifest is the control-repo source of truth for:

- which asset is the shipped icon master
- which runtime fork path each generated file should replace
- which nominal sizes each generated output should use

## Target map

| Runtime target | Format | Source | Intended role |
|---|---|---|---|
| `resources\win32\code.ico` | ICO | `assets\logo.svg` | Windows desktop and shell icon payload with exact Win32 shell sizes; the 16 through 32 pixel frames downscale from the source art margins for title-bar legibility |
| `resources\win32\code_70x70.png` | PNG | `assets\logo.svg` | Windows visual elements small tile logo used by the packaged Win32 shell metadata |
| `resources\win32\code_150x150.png` | PNG | `assets\logo.svg` | Windows visual elements medium tile logo used by the packaged Win32 shell metadata |
| `resources\darwin\code.icns` | ICNS | `assets\logo.svg` | macOS app icon bundle |
| `resources\linux\code.png` | PNG | `assets\logo.svg` | Linux desktop icon |
| `src\vs\workbench\browser\media\code-icon.svg` | SVG | `assets\logo.svg` | In-app workbench product icon used by title bar, getting started, update tooltip, banner, and walkthrough surfaces |
| `resources\server\favicon.ico` | ICO | `assets\logo.svg` | server and web favicon payload |
| `resources\server\code-192.png` | PNG | `assets\logo.svg` | server and web icon surface |
| `resources\server\code-512.png` | PNG | `assets\logo.svg` | server and web icon surface |

The workbench uses `src\vs\workbench\browser\media\code-icon.svg` for several in-app surfaces. Updating only the packaged desktop icons under `resources\` does not change those in-app references.

The reproducible refresh path is the control-repo export script with `-CompileFork`, or the matching `Fork: export branding assets` VS Code task. That path exports every runtime icon surface from `assets\logo.svg` and then recompiles the runtime fork so the built copy under `out\vs\workbench\browser\media\code-icon.svg` refreshes before self-hosted verification.

## Windows small-size policy

Microsoft's Windows icon guidance calls out two constraints that matter here:

- Windows looks for an exact size match first and scales down when that size is missing.
- small icons should keep a singular metaphor and remain recognizable at shell sizes.

To reflect that guidance, the Win32 ICO export now includes these exact shell-facing sizes:

- 16
- 20
- 24
- 30
- 32
- 36
- 40
- 48
- 60
- 64
- 72
- 80
- 96
- 128
- 256

All generated Windows, Linux, macOS, and server raster outputs now derive from `assets\logo.svg`. The direct workbench SVG target also comes from `assets\logo.svg`, so the packaged icons and in-app product icon stay aligned.

For `resources\win32\code.ico`, the 16, 20, 24, 30, and 32 pixel frames downscale from the source art's built-in composition margins. That keeps the title-bar icon readable at small Windows sizes while the larger ICO frames and the Win32 PNG visual-element assets continue to use the full original scene.

## Export workflow

1. Update the shipped source art under `assets\logo.svg` when the product icon changes.
2. Update `fork\tooling\branding-assets.manifest.json` if the target set or source policy changes.
3. From `C:\CatastroSwitch`, run:

```powershell
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\export-fork-branding-assets.ps1 -ForkRoot C:\src\vscode-multiagent -CompileFork
```

4. Review the generated files in the runtime fork. The reproducible path above exports packaged assets and recompiles the fork so the in-app workbench icon also refreshes from `assets\logo.svg`.
5. Commit generated runtime assets in the runtime fork.
6. Commit manifest and documentation changes in the control repo only when the mapping or workflow changed.

Useful option:

```powershell
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\export-fork-branding-assets.ps1 -ForkRoot C:\src\vscode-multiagent -PlanOnly
```

If you intentionally run a real export without `-CompileFork`, run `npm run compile` from the runtime fork before self-hosting so the in-app workbench icon surfaces stop reading a stale compiled SVG.

## Tooling expectations

- ImageMagick `magick` is required for PNG and ICO generation.
- macOS `iconutil` is preferred for packaging the final `resources\darwin\code.icns` bundle.
- `npx icon-gen` is supported as a cross-platform fallback for ICNS packaging when Node.js is available.

When `iconutil` is unavailable, the export script first tries `npx icon-gen`. If neither tool is available, it stages a `code.iconset` directory and reports the explicit packaging step instead of guessing a cross-platform `.icns` conversion.
