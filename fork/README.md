# Fork Track

This folder is the landing zone for planning and grounding artifacts that support the `CatastroSwitch` VS Code fork.

It is not a clone of `microsoft/vscode`.

## Read this first

- `..\docs\implementation-plan.md`
- `..\docs\vscode-fork-additive-strategy.md`
- `..\docs\vscode-fork-source-map.md`
- `..\docs\vscode-fork-build-runbook.md`
- `..\docs\fork-backlog.md`
- `..\docs\agent-adapter-contract.md`

## What belongs here

- fork planning notes
- grounded patch-zone guidance
- registry and adapter contract references that the fork should consume or mirror
- TypeScript and ESLint policy overlays that the real fork should consume or mirror

## Tooling policy overlays

See `tooling\README.md` for the canonical TypeScript and ESLint policy files that the real fork should import or copy into its own build and lint setup.

## Recommended local setup

Keep the real VS Code fork in a separate path such as:

```text
C:\src\vscode-multiagent
```

Do not clone the full VS Code source tree into `C:\CatastroSwitch`.

