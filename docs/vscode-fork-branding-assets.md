# VS Code Fork Branding Assets

This document defines how `CatastroSwitch` branding sources in the control repo map to the generated runtime assets in the real VS Code fork.

Keep the repository boundary explicit:

- `C:\CatastroSwitch` owns the source artwork, export manifest, and workflow guidance.
- `C:\src\vscode-multiagent` owns the generated runtime binaries that the product actually ships.

## Runtime fork targets

The current runtime fork surfaces that carry the product icon set are:

- `resources\win32\code.ico`
- `resources\darwin\code.icns`
- `resources\linux\code.png`
- `resources\server\favicon.ico`
- `resources\server\code-192.png`
- `resources\server\code-512.png`

Those paths are the replacement targets for CatastroSwitch branding.

## Source policy

Use `assets\logo-rounded-icon-hd.svg` as the primary shipped app-icon master.

Why that file:

- it is square
- it is the highest-resolution rounded icon source in the repo
- it avoids the embedded wordmark that hurts legibility at 16 px and 32 px

Use `assets\logo-rounded-icon.svg` as the quick preview or fallback source when a smaller local preview is enough.

Do not treat the following as the shipped desktop icon master:

- `assets\logo.png`
- `assets\logo.svg`
- `assets\logo-hd.svg`
- `assets\logo-rounded.svg`
- `assets\logo-rounded-hd.svg`

Those variants carry the wordmark or a non-icon framing and are better suited to README, splash, about, or marketing surfaces.

Treat `assets\logo-circle.svg` and `assets\logo-circle-hd.svg` as optional circular variants for avatar-like or future favicon experiments, not as the default desktop icon master.

## Machine-readable export spec

The canonical source-to-output map lives in:

```text
fork\tooling\branding-assets.manifest.json
```

That manifest is the control-repo source of truth for:

- which asset is the primary icon master
- which runtime fork path each generated file should replace
- which nominal sizes each generated output should use

## Target map

| Runtime target | Format | Source | Intended role |
|---|---|---|---|
| `resources\win32\code.ico` | ICO | `assets\logo-rounded-icon-hd.svg` | Windows desktop and shell icon payload |
| `resources\darwin\code.icns` | ICNS | `assets\logo-rounded-icon-hd.svg` | macOS app icon bundle |
| `resources\linux\code.png` | PNG | `assets\logo-rounded-icon-hd.svg` | Linux desktop icon |
| `resources\server\favicon.ico` | ICO | `assets\logo-rounded-icon-hd.svg` | server and web favicon |
| `resources\server\code-192.png` | PNG | `assets\logo-rounded-icon-hd.svg` | server and web icon surface |
| `resources\server\code-512.png` | PNG | `assets\logo-rounded-icon-hd.svg` | server and web icon surface |

## Export workflow

1. Update the source art under `assets\`.
2. Update `fork\tooling\branding-assets.manifest.json` if the target set or source policy changes.
3. From `C:\CatastroSwitch`, run:

```powershell
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\export-fork-branding-assets.ps1 -ForkRoot C:\src\vscode-multiagent
```

4. Review the generated files in the runtime fork.
5. Commit generated runtime assets in the runtime fork.
6. Commit manifest and documentation changes in the control repo only when the mapping or workflow changed.

Useful option:

```powershell
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\export-fork-branding-assets.ps1 -ForkRoot C:\src\vscode-multiagent -PlanOnly
```

## Tooling expectations

- ImageMagick `magick` is required for PNG and ICO generation.
- macOS `iconutil` is preferred for packaging the final `resources\darwin\code.icns` bundle.
- `npx icon-gen` is supported as a cross-platform fallback for ICNS packaging when Node.js is available.

When `iconutil` is unavailable, the export script first tries `npx icon-gen`. If neither tool is available, it stages a `code.iconset` directory and reports the explicit packaging step instead of guessing a cross-platform `.icns` conversion.