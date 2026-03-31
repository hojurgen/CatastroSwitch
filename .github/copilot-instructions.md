---
applyTo: "**"
---
# CatastroSwitch Copilot instructions

## Project intent

This repository is a fork-first control repo for a custom VS Code product.

All runtime implementation belongs in a separate VS Code fork checkout such as `C:\src\vscode-multiagent`.

Operationally this is a two-repository model: this control repo plus a separate runtime fork such as `github.com/<owner>/vscode` that rebases from `microsoft/vscode`.

## Architecture rules

- Read `docs/grounding.md`, `docs/architecture.md`, `docs/implementation-plan.md`, and `docs/vscode-fork-additive-strategy.md` before large changes.
- Keep the actual VS Code fork source tree outside this repo.
- Prefer additive seams: new services, new parts, and narrow registration hooks over copying upstream files.
- Keep `schemas/workspace-registry.schema.json`, `examples/workspace-registry.sample.json`, and `docs/agent-adapter-contract.md` aligned when their contract changes.

## Workflow rules

- Keep the contributor workflow stable: reuse existing scripts, workspace files, setup steps, and folder layout unless a concrete problem requires a change.
- Keep phase branches and `.catastroswitch\phase-state\` artifacts in the real fork clone, not in this control repo.
- If one feature spans runtime code and control-repo artifacts, keep the changes separated by repository and update the paired docs or workflow guidance here.
- If commands, workspace files, or local setup change, update `.vscode`, `README.md`, `CONTRIBUTING.md`, and the relevant runbook in the same change.
- Finish with the smallest coherent change that can be validated using the existing checks for the touched surface.

## TypeScript quality rules

- For fork-runtime TypeScript guidance or future code, prefer existing VS Code service patterns, narrow interfaces, explicit contracts, and strict types.
- Avoid `any`, `as any`, broad catch-and-ignore behavior, and speculative abstractions that are not anchored to a real seam.
- Use augmentation only when it clarifies a genuine seam; it does not replace runtime architecture.

## Research rules

- Ground claims about VS Code, Copilot, MCP, Teams, and App Insights in official docs, concrete source paths, or directly inspected code before stating them as facts.
- Distinguish verified behavior, proposed design, and open questions when the available evidence is incomplete.

## Repo rules

- The repo root is not a TypeScript package.
- Do not add archived or prototype runtime tracks back into this repository.
- Keep agents, skills, and instructions focused on the fork product and its control-repo artifacts.

## Documentation rules

- Keep the repo clearly fork-only.
- When patch zones, boundaries, or rollout rules change, update the relevant docs.
- Be explicit about what stays in this repo versus what belongs in the actual VS Code fork clone.

