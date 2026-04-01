# Contributing

## Short version

I do not accept outside contributions.

This repository exists to reduce my workload, not to create a charming second job where I review surprise pull requests, triage random issues, and pretend that unsolicited workflow opinions count as engineering.

So, no:

- I am not taking external PRs.
- I am not taking external issues.
- If you found a bug, weird edge case, or bad assumption, congratulations on your private lore. Please enjoy it locally.

## If you are not a maintainer

Please do not open pull requests.

Please also do not open issues. I could not care less.

If you desperately need to improve something, fork it, fix it, enjoy your personal sense of closure, and keep moving.

## If you are a maintainer

Congratulations. This document is suddenly useful instead of decorative.

Rules:

- Keep the repo fork-only. This is the control tower, not the runtime.
- Keep the real VS Code fork checkout outside `C:\CatastroSwitch`. Do not turn this repo into a landfill for a full product clone.
- Prefer grounded, additive changes over clever churn. If the diff looks like a personality disorder, rewrite it.
- Keep docs, schema, and fork tooling overlays aligned when their contracts change.
- Keep the per-phase state artifact current if you use the Planner, Reviewer, or Gatekeeper loop. Magical thinking is not state management.

Pick the right repository before you start:

- Runtime fork changes belong in your VS Code fork repository, for example `github.com/<owner>/vscode`.
- Control artifacts belong here, in the separate `CatastroSwitch` control repo.
- If a feature changes both, use two branches and two pull requests. Keep the runtime code review in the fork and the docs or contract review in the control repo.

In the runtime fork clone, keep `upstream` fetch-only and keep default pushes pointed at `origin`.
In the runtime fork clone, add `/.catastroswitch/` to `.git/info/exclude` so local phase-state artifacts stay out of `git status`.
In this control repo, enable the committed hooks path with `git config core.hooksPath .githooks` so direct pushes to `origin/main` are blocked unless you intentionally override them.

Before sending changes out, run:

- VS Code task: `Control repo: validate`
- terminal: `powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-control-repo.ps1`

If you need the actual fork workflow, read `docs\vscode-fork-build-runbook.md`. Shockingly, that is where the runbook instructions live.

Typical maintainer loop:

1. Plan in this repo.
2. Implement and build in the fork repo.
3. Use `npm install`, `npm run compile`, `npm run watch`, and `scripts\code.bat` from the fork checkout.
4. If branding sources changed in this control repo, run `powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\export-fork-branding-assets.ps1 -ForkRoot C:\src\vscode-multiagent -CompileFork` before committing the generated fork resources. The script enforces `assets\logo.svg` as the single icon source, updates the packaged runtime assets, and recompiles the fork so in-app workbench icon surfaces refresh from the same source. ImageMagick is required for raster export, and the script uses either macOS `iconutil` or `npx icon-gen` to package `resources\darwin\code.icns`.
5. In the fork checkout, keep `microsoft/vscode` as a fetch-only `upstream` remote.
6. In the fork checkout, keep `/.catastroswitch/` ignored via `.git/info/exclude` so local phase-state files do not dirty the runtime branch.
7. In this control repo, keep the local `pre-push` hook enabled before pushing changes.
8. Update this repo only if the implementation changed docs, source maps, schemas, contracts, or workflow guidance.
9. Cross-link paired PRs when one feature spans both repos.

TypeScript and ESLint policy overlays for the real fork live under `fork\tooling\`.

Phase workflow helpers live under:

- `scripts\new-phase-branch.ps1`
- `scripts\new-phase-task-branch.ps1`
- `scripts\new-phase-state.ps1`

Workflow agents live under:

- `.github\agents\planner.agent.md`
- `.github\agents\coding-agent.agent.md`
- `.github\agents\reviewer.agent.md`
- `.github\agents\gatekeeper.agent.md`
- `.github\agents\orchestrator.agent.md`
- `.github\agents\fork-architect.agent.md`

Reusable skills live under:

- `.github\skills\fork-phase-execution\SKILL.md`
- `.github\skills\vscode-fork-runbook\SKILL.md`
- `.github\skills\vscode-fork-scout\SKILL.md`
- `.github\skills\workspace-registry-design\SKILL.md`
- `.github\skills\source-grounding\SKILL.md`
