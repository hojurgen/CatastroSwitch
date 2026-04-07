# CatastroSwitch Copilot Instructions

Use `docs/implementation-plan.md` as the only roadmap and workflow source of truth.

## Core Rules

- Do not create, depend on, or reintroduce mutable phase-execution JSON.
- When a JSON contract needs to point back to the roadmap, use `planPath`.
- Prefer additive changes under new CatastroSwitch-specific files and folders.
- Keep runtime product code in `C:\src\vscode-multiagent` on the `catastroswitch` branch.
- Treat this repository as the control repo for durable docs, contracts, prompts, and workflow agents.

## Product Direction

- The control plane is machine-local, not window-local.
- The UI target is a persistent CatastroSwitch sidebar plus an Alt+Tab-style workspace switcher overlay.
- Same-window switching is the default behavior.
- A same-window reload is acceptable when extension policy changes require a clean extension-host reset.

## Model Preference

- Run the CatastroSwitch workflow agents with `GPT-5.4` and `xhigh` reasoning whenever the active Copilot client supports that selection.
- Do not hard-code unsupported `model:` or undocumented reasoning fields into `.agent.md` or `.prompt.md` files if the local validator rejects them.
- Prefer inheriting the active chat session model so all custom agents use the same model and reasoning level consistently.

## Documentation Tool Preference

- When an agent has `microsoft-learn/*`, prefer it for Microsoft and Azure product documentation before using generic web search.
- When an agent has `azure-mcp/search`, use it for Azure-specific product, resource, and platform discovery when that context affects the task.
- When an agent has `context7/*`, prefer it for package, library, and framework documentation before using generic web search.
- Use generic `web` search only to fill gaps those tools cannot cover.

## Workflow Agents

The preferred workflow in this repo is:

1. `Orchestrator` owns one phase.
2. `Planner` decomposes that phase into concrete tasks.
3. `Gatekeeper` validates the planning stage.
4. `CodingAgent` implements one approved task at a time and may use `Researcher`.
5. `Reviewer` reviews each implemented task.
6. `Gatekeeper` validates each stage boundary.

## Loop Guardrails

- Never restart an already approved stage.
- Allow at most one rework cycle per stage in a single run.
- If a second gate fails for the same stage, mark the stage `blocked` with explicit reasons instead of looping.
- Agents should update durable docs only at milestone boundaries, not on every intermediate step.
