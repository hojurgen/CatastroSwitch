# CatastroSwitch Architecture

## Boundary

CatastroSwitch is a control repo, not the runtime product checkout.

- The control repo owns durable contracts, bootstrap assets, runbooks, and branding sources.
- The runtime product lives in the separate `hojurgen/vscode` fork cloned locally to `C:\src\vscode-multiagent`.
- The runtime fork tracks `microsoft/vscode` as `upstream` and carries CatastroSwitch product changes on the long-lived `catastroswitch` branch.

## Control-repo assets

- `schemas/` defines the machine-readable contracts for workspace routing and agent session snapshots.
- `examples/` provides sample payloads that keep those contracts concrete and testable.
- `scripts/` provides repeatable bootstrap and maintenance entrypoints for fork checkout, branding export, workspace generation, and upstream sync.
- `assets/logo.svg` is the single source of truth for CatastroSwitch product branding.

## Machine-local catalogs and same-window switching

The user-facing model is machine-local, not window-local.

- CatastroSwitch should merge the durable workspace registry with VS Code recent-workspace history to build one machine-local workspace catalog.
- Each managed workspace entry resolves a local path, a profile template handle, an extension policy, a fork target, a monitoring policy, and a plan reference.
- `CatastroSwitch.local.code-workspace` remains only a machine-local maintenance workspace generated from the registry.
- The runtime UI should use same-window workspace switching so the current window moves to the selected workspace and preserves a switch-back path, instead of treating new windows as the primary experience.

## Branding flow

Branding is part of the build, not a manual post-build tweak.

1. The control repo stores the canonical branding asset in `assets/logo.svg`.
2. `scripts/export-product-icons.ps1` derives the raster assets required by the runtime fork.
3. The runtime fork consumes those outputs in its build and packaging steps.
4. Verification must confirm the produced artifacts no longer contain stock VS Code icons.

## Monitoring flow

Agent monitoring is local-machine first and GitHub Copilot session focused.

- Local VS Code processes publish heartbeat and session summary snapshots to a shared local snapshot directory.
- The control plane aggregates those snapshots together with live session provider data into a machine-local session catalog with workspace correlation, waiting states, stale states, and errors.
- The implementation plan remains the durable roadmap reference; ephemeral monitoring data stays outside version control.