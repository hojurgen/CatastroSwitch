---
name: Workflow stability rules
description: Keep local setup and contributor workflow changes deliberate, documented, and low-churn.
applyTo: "README.md,CONTRIBUTING.md,.vscode/**/*.json,scripts/**/*.ps1"
---
# Workflow stability rules

- Prefer the existing contributor workflow unless a concrete problem requires a change.
- Reuse the current folder layout, scripts, and workspace conventions before introducing new setup steps or files.
- When a workflow spans the control repo and the runtime fork, state which repository each command, branch, and validation step belongs to.
- If commands, local setup, or workspace behavior change, update the relevant docs in the same change so the workflow stays stable.
- Keep machine-specific paths and personal environment assumptions out of committed workspace files.
- Make the smallest coherent workflow change that can be explained and validated clearly.
