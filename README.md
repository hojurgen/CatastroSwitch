# CatastroSwitch

<p align="left">
  <img src="assets/logo.svg" alt="CatastroSwitch logo" width="320" />
</p>

`CatastroSwitch` is a fork-first control repository for a custom VS Code product.

All runtime implementation belongs in a separate VS Code fork checkout, for example `C:\src\vscode-multiagent`.

## Start here

### What this repo is for

- grounded fork docs
- executable phase plan
- workspace registry schema and example data
- phase execution state schema and sample data
- agent adapter contract
- fork-consumable TypeScript and ESLint policy overlays
- GitHub Copilot instructions, agents, and skills

### Read this first

- `docs\architecture.md`
- `docs\implementation-plan.md`
- `docs\vscode-fork-additive-strategy.md`
- `docs\vscode-fork-source-map.md`
- `docs\vscode-fork-branding-assets.md`
- `docs\vscode-fork-build-runbook.md`
- `docs\fork-backlog.md`
- `docs\grounding.md`
- `docs\agent-adapter-contract.md`

### Recommended local layout

```text
C:\CatastroSwitch
C:\src\vscode-multiagent
```

Keep the real VS Code fork outside this repository.

After you clone the fork, generate an ignored local multi-root workspace file that opens both trees:

```powershell
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\new-local-workspace.ps1
```

This writes `CatastroSwitch.local.code-workspace` in the repo root so contributors can work across the control repo and the fork without committing machine-specific workspace paths.

If your fork checkout does not live at `C:\src\vscode-multiagent`, set `CATASTROSWITCH_FORK_ROOT` in your shell or profile so the shared workflow hooks and repair scripts resolve the correct runtime checkout.

### Scope boundary

- This repo keeps planning, schema, contract, and agent-guidance artifacts.
- The actual shell, profile, extension-management, and chat/session patches live in the fork clone.

### GitHub repo model

Use two GitHub repositories with different jobs:

- `github.com/<owner>/vscode` is the runtime repository. It stays a fork of `microsoft/vscode`, carries the real product code, and keeps an `upstream` remote for rebases.
- `github.com/<owner>/CatastroSwitch` or `github.com/<owner>/catastroswitch-control` is the control repository. It keeps docs, schemas, contracts, workflow scripts, and agent guidance.

Recommended local hardening for the runtime fork:

- keep `upstream` fetch-only by setting its push URL to `no_push`
- set the fork clone to push to `origin` by default
- add `/.catastroswitch/` to the fork repo `.git/info/exclude` so local phase-state artifacts do not dirty `git status`
- install the managed runtime git hooks with `powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-runtime-fork-hooks.ps1 -ForkRoot C:\src\vscode-multiagent` so commits on clean sync branches and accidental pushes to `upstream` are blocked locally

Recommended local hardening for this control repo:

- enable the committed hooks path with `git config core.hooksPath .githooks`
- keep the local `pre-commit` and `pre-push` hooks active so commits and pushes to `main` require an explicit override

Do not duplicate runtime patches into the control repo. If one feature changes both runtime code and control artifacts, keep one change in the fork and a separate change in the control repo.

### Practical flow

1. Plan the phase and maintain the durable product docs in this repo.
2. If you want chat to inspect the current workflow state and continue from the right agent, use one of the shared workspace prompts under `.github\prompts\`: `workflow-router.prompt.md` for general routing, `resume-phase.prompt.md` for strict phase resumption, or `review-ready-task.prompt.md` for the Reviewer entrypoint.
  `workflow-router.prompt.md` and `resume-phase.prompt.md` should start by running `powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\sync-phase-workflow-lane.ps1 -Apply`, which aligns the runtime fork to the active non-terminal phase lane or the first incomplete phase before more routing happens.
  The shared workspace hook at `.github\hooks\phase-enforcement.json` also reads the phase-state `executionLock` when one exists and blocks writes to the wrong runtime worktree.
3. Sync and rebase the fork from `microsoft/vscode` in the separate fork checkout.
  Keep the runtime fork `main` or `upstream-main-sync` branch as a clean sync branch that fast-forwards from `upstream/main`, then rebase the active phase branch onto that clean branch before resuming product work.
4. Create or update the active phase branch in the fork.
5. Build and run from the fork checkout with `npm install`, `npm run compile`, `npm run watch`, and `scripts\code.bat`.
  If the clean-sync fork worktree mirrors files from the active phase worktree, run `powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\repair-phase-worktree-state.ps1 -Phase <phase-id>` from this control repo before continuing.
  If the latest passed phase recorded a `recommendedNextPhase`, the workflow lane helper now prefers that explicit handoff before it falls back to the first incomplete phase.
  After an upstream refresh or phase-branch rebase, rerun `npm run compile`, the focused browser suites for the owned seams you touched, and a self-host smoke run for shell or chat changes before trusting the branch again.
6. If product branding sources changed under `assets\logo.svg`, run `Fork: export branding assets` from this control repo against the fork checkout before committing the generated runtime assets. That task exports all packaged icons and recompiles the fork so the in-app workbench icon also refreshes from the same control-repo source.
7. Update this repo only when the docs, contracts, schemas, or workflow expectations change.
8. Run `Control repo: validate` when this repo changes.

## Repository contents

### Repository layout

```text
C:\CatastroSwitch
├─ .github
│  ├─ agents
│  ├─ hooks
│  ├─ instructions
│  ├─ prompts
│  └─ skills
├─ assets
├─ docs
├─ examples
├─ fork
│  └─ tooling
├─ schemas
├─ AGENTS.md
├─ CONTRIBUTING.md
└─ CHANGELOG.md
```

### Key docs

- `docs\architecture.md` - fork-first architecture and repo role
- `docs\implementation-plan.md` - phase-specific execution graph plus Planner, Coding Agent, Reviewer, and Gatekeeper loop
- `docs\vscode-fork-additive-strategy.md` - minimal-diff strategy for easier upstream upgrades
- `docs\vscode-fork-source-map.md` - concrete Code - OSS patch zones
- `docs\vscode-fork-branding-assets.md` - branding source-to-output mapping plus runtime asset export rules
- `docs\vscode-fork-build-runbook.md` - clone, bootstrap, and self-host guidance
- `docs\fork-backlog.md` - practical fork epics
- `docs\agent-adapter-contract.md` - rules for adapter-backed external agent visibility
- `docs\grounding.md` - official sources used to keep the fork plan honest
- `fork\tooling\README.md` - canonical TypeScript and ESLint policy overlays for the real fork

### Workspace registry contract

These files stay in the control repo because they describe fork intent rather than runtime implementation:

- `schemas\workspace-registry.schema.json`
- `examples\workspace-registry.sample.json`

They model workspace identity, profile affinity, desired behaviors, adapter metadata, and product capability planning.

### Phase execution state contract

These files define the machine-readable artifact that tracks one phase at a time:

- `schemas\phase-execution-state.schema.json`
- `examples\phase-execution-state.sample.json`

Recommended real fork path:

```text
<fork-root>\.catastroswitch\phase-state\<phase>.phase-state.json
```

Use the helper scripts under `scripts\` to create the phase branch, task branch, and initial phase state file.
The phase-state contract also carries an `executionLock` that records the active agent, active task, allowed runtime branch and worktree, next handoff, pending review lane, and the dirty-worktree policy for the current stage.
Workspace hooks under `.github\hooks\phase-enforcement.json` read that lock so the chat workflow can block writes to the wrong runtime checkout instead of relying on memory.

## Why the name

I picked `CatastroSwitch` because my daily work is basically speedrunning workspace hopping while talking to customers and babysitting agents in other workspaces at the same time, all so I can stumble into the next customer meeting looking prepared. Usually there is not even a one-minute gap between those contexts, because apparently context switching is now a competitive sport. One minute it is code review, then performance troubleshooting, then debugging, then some PoC in another language with another tool, then an architecture discussion, then removing go-live blockers on a process/business level because calm and continuity were clearly rejected during planning.

Also, I love cats. I have three of them. They occasionally help by walking across my keyboard or meowing into the camera during customer calls, because clearly professionalism improves when surprise feline QA gets involved.

My wife also loves me enough to throw sandwiches into the office when I am working overtime and apparently expects me to catch them like a dolphin being tossed food or toys at a marine park. This occasionally ends with lunch hitting me in the face because I was busy context switching and not paying attention. Love you, Babe. Apparently even lunch delivery in this house is event-driven and doubles as a live reflex test.

So yes: switching everywhere, small to medium catastrophes everywhere, cats, and airborne sandwiches. The name was not exactly hard to find.

YES! I mentioned agents. AND CATS. FOCUS ON THE CATS. AND THE AIRBORNE SANDWICHES. The code is AI-generated because apparently my job now is "writing software" but curating top-tier AI slop while three cats and a ballistic lunch-delivery system masquerade as quality control.
