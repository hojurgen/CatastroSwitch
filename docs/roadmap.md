# Roadmap

## Current decision

`CatastroSwitch` is fork-first.

For the operational breakdown that agents can execute directly, see `docs\implementation-plan.md`.

## Phase F0 - Control repo and fork bootstrap

Deliverables:

- grounded fork docs
- additive/minimal-diff strategy
- source map for likely patch zones
- bootstrap/self-host runbook

Exit criteria:

- a contributor can understand the product direction quickly
- a contributor can clone and self-host the fork on Windows

## Phase F1 - Workspace rail shell integration

Deliverables:

- product-owned workspace rail
- workbench layout integration
- focus, visibility, and persistence rules

Exit criteria:

- the rail behaves as a first-class workbench part

## Phase F2 - Workspace orchestration and profile behavior

Deliverables:

- workspace context/orchestration service
- workspace-aware profile application rules
- integration with existing profile resources

Exit criteria:

- entering a workspace can deterministically drive product-owned profile behavior

## Phase F3 - Extension-set behavior and session visibility

Deliverables:

- workspace-specific extension-set behavior
- product-owned agent/session summaries
- adapter boundary for external runtimes

Exit criteria:

- the fork can show trustworthy per-workspace behavior without pretending to own unsupported surfaces

## Phase F4 - Hardening and upstream sync

Deliverables:

- regression coverage for shell, profiles, and sessions
- upstream rebase/update process
- patch ownership map

Exit criteria:

- changes remain additive and rebase-friendly
- upstream merges are routine rather than disruptive

## Ongoing rule

Every phase should follow `docs\vscode-fork-additive-strategy.md`.

