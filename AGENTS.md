# AGENTS.md

## Purpose

This repository is a fork-first control repo for `CatastroSwitch`.

The actual product runtime should live in a separate VS Code fork checkout such as `C:\src\vscode-multiagent`.

Operationally this means two repositories: this control repo plus a separate runtime fork such as `github.com/<owner>/vscode` that rebases from `microsoft/vscode`. Phase branches and `.catastroswitch\phase-state\` artifacts live in the fork clone. Durable docs, schemas, contracts, scripts, agents, and skills live here.

## Required reading before major changes

- `docs/grounding.md`
- `docs/architecture.md`
- `docs/implementation-plan.md`
- `docs/vscode-fork-additive-strategy.md`
- `docs/vscode-fork-source-map.md`
- `docs/vscode-fork-build-runbook.md`
- `docs/fork-backlog.md`
- `docs/agent-adapter-contract.md`
- `schemas/workspace-registry.schema.json`
- `examples/workspace-registry.sample.json`

## Non-negotiable rules

- Keep the repo fork-only.
- Keep the actual VS Code fork outside this repo.
- Keep the remote split explicit: the runtime fork rebases from `microsoft/vscode`, while the control repo carries docs, schemas, contracts, scripts, agents, and skills.
- Do not claim unsupported public APIs can perform product-only work.
- Do not claim universal third-party or Copilot session visibility unless the product truly owns that runtime.
- Keep the contributor workflow stable: prefer existing commands, workspace files, scripts, and folder layout over churn.
- If local setup, workspace files, or documented commands change, update `.vscode`, `README.md`, `CONTRIBUTING.md`, and the relevant runbook in the same change.
- Execute one phase at a time on its own branch in the real fork clone.
- Keep the active phase branch and `.catastroswitch\phase-state\` artifact in the real fork clone, not in this control repo.
- Start each phase with Planner output against the selected phase, then use the Coding Agent -> Reviewer loop for every ready task in that phase.
- Run Gatekeeper only after every task in the phase has a Reviewer `Pass`.
- Treat Gatekeeper `Error` as a real stop signal that returns the phase to Planner and Coding Agent work.
- Keep the machine-readable phase state artifact current while the phase loop runs.
- Prefer additive fork patches: new files, new services, narrow registration hooks, and delegation over copying upstream files.
- When planning or writing fork-runtime TypeScript, prefer strict types, narrow interfaces, explicit errors, and existing VS Code service patterns over `any`-style escape hatches or speculative abstractions.
- Treat TypeScript module augmentation as a type-level seam tool, not as permission to broadly monkey-patch runtime behavior.
- Keep `schemas/workspace-registry.schema.json` and `examples/workspace-registry.sample.json` in sync when their contract changes.
- Keep agents, skills, and instructions explicitly fork-related.
- Update documentation when fork structure, patch areas, or adapter boundaries change.
- Validate with the existing checks for the touched surface before calling work done; if only control-repo docs or metadata changed, do a consistency review and say there is no root-level build.

## Documentation guidance

- Cite official sources where capability boundaries matter.
- Ground Copilot, MCP, Teams, App Insights, and VS Code capability claims in official docs, concrete source paths, or directly inspected code before stating them as facts.
- Name concrete `src/vs/...` patch zones when documenting fork work.
- Document the smallest additive seam that can support the change.
- Be explicit about what stays in the control repo versus what belongs in the fork clone.
- Distinguish verified behavior from proposed design when research is still incomplete.
- Be explicit about which phase tasks can run in parallel and which must remain sequential.
- Reviewer and Gatekeeper outputs should be machine-readable enough to drop into the phase state artifact without translation.

## Validation

There is no root-level `npm` validation workflow in this control repo.

When you change the workspace registry contract or adapter rules, update the paired docs and sample data in the same change.

