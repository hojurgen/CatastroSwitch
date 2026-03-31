---
name: vscode-fork-scout
description: Maps CatastroSwitch requirements to concrete VS Code fork patch zones and documents what stays in the control repo versus what lands in the fork.
---

# VS Code fork scout

Use this skill when a request touches:

- unsupported workbench chrome
- profile orchestration
- workspace-driven extension-set behavior
- product-owned agent or session visibility

## Procedure

1. Read `docs/architecture.md`.
2. Read `docs/implementation-plan.md`.
3. Read `docs/vscode-fork-additive-strategy.md`.
4. Read `docs/vscode-fork-source-map.md`.
5. Read `docs/agent-adapter-contract.md` when external runtimes are involved.
6. Name the concrete `src/vs/...` files or directories involved.
7. Choose the smallest additive seam that can support the feature.
8. Keep schema, adapter contracts, workflow scripts, and other control-repo artifacts in the control repo root, for example `C:\CatastroSwitch`, when they remain design inputs rather than runtime code.
9. Call out when a feature needs paired runtime-fork and control-repo changes instead of implying a single repo change.

## Output checklist

- the feature requirement
- why the product needs a fork-level change
- the likely Code - OSS patch zones
- the smallest additive patch strategy
- what stays in the control repo
- what moves into the runtime fork
- whether the work is fork-only or needs paired control-repo updates

