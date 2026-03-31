---
name: vscode-fork-runbook
description: Guides contributors through cloning, building, self-hosting, and updating the VS Code fork used by CatastroSwitch.
---

# VS Code fork runbook

Use this skill when:

- preparing a local VS Code fork
- updating bootstrap docs
- verifying Windows build/run guidance

## Procedure

1. Start with `docs/vscode-fork-build-runbook.md`.
2. Use the official sources named there:
   - VS Code contribution guide
   - VS Code source organization guide
   - root `package.json`
   - `scripts/code.bat` or `scripts/code.sh`
3. Keep the recommended clone path free of spaces.
4. Keep the real fork clone outside `C:\CatastroSwitch`.
5. Keep the two-repository model explicit: durable docs and guidance live in the control repo, while build and self-host work live in the runtime fork.

## Minimum guidance to preserve

- Windows prerequisites
- `npm install`
- `npm run compile`
- `npm run watch`
- `scripts\code.bat`
- upstream rebase strategy
- which repository each workflow step runs in

