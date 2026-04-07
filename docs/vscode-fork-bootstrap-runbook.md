# VS Code Fork Bootstrap Runbook

## Purpose

Use this runbook to create or repair the local runtime checkout at `C:\src\vscode-multiagent` from the existing GitHub fork at `https://github.com/hojurgen/vscode`.

## Prerequisites

- Git is installed and available on `PATH`.
- PowerShell is available.
- Node.js and npm are installed for the runtime build.
- ImageMagick is optional but recommended for local branding export through `magick`.
- `iconutil` is required on macOS if you need a real `app.icns` for darwin packaging.

## Bootstrap the local fork

Run the helper from the control repo root:

```powershell
.\scripts\bootstrap-vscode-fork.ps1
```

That helper:

- clones `hojurgen/vscode` into `C:\src\vscode-multiagent` when the checkout is missing
- repairs `origin` so it points to the personal fork
- adds or repairs `upstream` so it points to `microsoft/vscode`
- fetches both remotes
- optionally creates or tracks the `catastroswitch` branch when requested

## Prepare the maintenance workspace

Generate the machine-local maintenance workspace from the registry sample:

```powershell
.\scripts\generate-local-workspace.ps1
```

This rebuilds `CatastroSwitch.local.code-workspace` using the workspace registry contract rather than a hand-maintained folder list.

## Prepare branding assets

Export the product-branding payload from the canonical SVG source:

```powershell
.\scripts\export-product-icons.ps1
```

The generated files land under `out\branding\`. The runtime fork should consume those outputs during build and packaging so produced artifacts replace the stock VS Code icons.

On Windows, the export helper produces the win32, linux, and server/web payloads directly. A real `app.icns` is only generated when `iconutil` is available, so darwin packaging should be prepared from macOS or another environment that can provide `iconutil`.

## Build and self-host the runtime fork

From the runtime fork root:

```powershell
Set-Location C:\src\vscode-multiagent
npm install
npm run watch
```

Then launch the runtime from the control repo with the `Fork: self-host (isolated CatastroSwitch runtime)` configuration. That launch path uses an isolated user-data directory so CatastroSwitch runtime testing does not interfere with an existing VS Code profile.

## Sync with upstream

Preview the upstream sync and rebase flow:

```powershell
.\scripts\sync-upstream-and-rebase.ps1
```

Execute the same flow when ready:

```powershell
.\scripts\sync-upstream-and-rebase.ps1 -Execute -PushMain -PushProductBranch
```

Keep `main` as the upstream-sync branch and keep CatastroSwitch product work on `catastroswitch`.