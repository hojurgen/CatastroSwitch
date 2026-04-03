---
name: Workflow Router
description: "Use when: identify the next CatastroSwitch workflow step, inspect current phase or task context, pick the right agent, and continue the Planner -> Coding Agent -> Reviewer -> Gatekeeper loop."
argument-hint: "Optional: phase ID, task ID, blocker, branch, or current goal"
agent: Orchestrator
---

Use the current repo state plus any user-supplied context to decide which CatastroSwitch workflow agent should run next.

Ground the routing decision in [docs/implementation-plan.md](../../docs/implementation-plan.md), [CONTRIBUTING.md](../../CONTRIBUTING.md), and the current phase-state artifact in the real fork clone when one is available.
When the phase-state artifact has an `executionLock`, treat it as the current authoritative lane unless concrete repo evidence proves it is stale and the next step is to re-plan.

Your first response must be a short triage that includes:

- identified phase or task context
- current workflow stage
- recommended next step
- next agent
- any missing prerequisite that blocks execution

Routing rules:

- Route to `Fork Architect` when the current ask needs concrete `src/vs/...` patch zones, explicit fork-versus-control-repo boundaries, or phase-fit clarification before planning.
- Route to `Planner` when phase scope, task graph, phase branch setup, or phase-state initialization is missing or stale.
- Route to `Planner` when the active phase branch has not yet been replayed onto the current clean sync branch after upstream moved.
- Route to `Coding Agent` when a Planner-approved task is ready for implementation.
- Route to `Reviewer` when a completed task needs a pass or error decision.
- Route to `Gatekeeper` only when every task in the selected phase has a Reviewer `Pass`.
- Stay in `Orchestrator` when the user wants the full phase loop to continue end-to-end.

Execution rules:

- Run exactly one phase at a time.
- Keep runtime code changes in the separate VS Code fork checkout and durable docs, schemas, contracts, scripts, prompts, and agent guidance in this control repo.
- Use the active phase-state artifact in the real fork clone when it exists, and create or confirm the phase branch plus state file before planning if they are missing.
- Keep the phase-state `executionLock` aligned with the next real handoff instead of leaving the active branch or worktree implicit.
- Suggest the next concrete action before handing off.
- Ask a clarifying question only if the phase, task, or handoff target is still genuinely ambiguous after inspecting the available repo context.
- After the brief triage summary, immediately hand off to the chosen agent or continue the orchestration loop.