---
name: Run CatastroSwitch Phase
description: "Run a CatastroSwitch phase through the orchestrator, planner, coding agent, reviewer, and gatekeeper workflow."
agent: Orchestrator
tools: [read, search, agent, todo]
argument-hint: "Phase id or phase name from docs/implementation-plan.md"
---
Run the requested CatastroSwitch phase from [implementation-plan.md](../../docs/implementation-plan.md).

Workflow:

1. `Planner` produces the phase task breakdown.
2. `Gatekeeper` validates the planning stage.
3. `CodingAgent` implements one approved task at a time and may use `Researcher`.
4. `Reviewer` reviews each implemented task.
5. `Gatekeeper` validates each stage before the workflow proceeds.
6. `Orchestrator` remains the only coordinator that chooses the next rework or implementation step.

Rules:

- Use `docs/implementation-plan.md` as the only roadmap source.
- Do not create or use mutable execution-state JSON.
- Respect the one-rework-per-stage guardrail.
- Stop as `blocked` instead of looping if a second gate fails.
