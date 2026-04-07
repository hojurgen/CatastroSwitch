# CatastroSwitch Architecture

## Boundary

CatastroSwitch is a control repo, not the runtime product checkout.

- The control repo owns durable contracts, bootstrap assets, runbooks, and branding sources.
- The runtime product lives in the separate `hojurgen/vscode` fork cloned locally to `C:\src\vscode-multiagent`.
- The runtime fork tracks `microsoft/vscode` as `upstream` and carries CatastroSwitch product changes on the long-lived `catastroswitch` branch.

## Control-repo assets

- `schemas/` defines the machine-readable contracts for workspace routing, phase execution state, and agent session snapshots.
- `examples/` provides sample payloads that keep those contracts concrete and testable.
- `scripts/` provides repeatable bootstrap and maintenance entrypoints for fork checkout, branding export, workspace generation, and upstream sync.
- `assets/logo.svg` is the single source of truth for CatastroSwitch product branding.

## Registry-driven switching

The user-facing switching model is registry-driven.

- Each workspace entry resolves a local path, profile, fork target, and monitoring policy.
- `CatastroSwitch.local.code-workspace` is only a machine-local maintenance workspace generated from the registry.
- The runtime UI will eventually open registered workspaces with their assigned VS Code profile instead of mutating the current window.

## Branding flow

Branding is part of the build, not a manual post-build tweak.

1. The control repo stores the canonical branding asset in `assets/logo.svg`.
2. `scripts/export-product-icons.ps1` derives the raster assets required by the runtime fork.
3. The runtime fork consumes those outputs in its build and packaging steps.
4. Verification must confirm the produced artifacts no longer contain stock VS Code icons.

## Monitoring flow

Agent monitoring is local-machine first.

- Each open runtime window writes a heartbeat and session summary to a shared local snapshot directory.
- The control plane aggregates those snapshots into a machine-local view of active workspaces, waiting states, and errors.
- Repo-owned phase-state artifacts remain durable references; ephemeral monitoring data stays outside version control.