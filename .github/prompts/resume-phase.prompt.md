---
name: Resume Phase
description: "Use when: resume an active CatastroSwitch phase from the current branch or phase-state artifact, identify the next ready step, and continue the workflow loop."
argument-hint: "Optional: phase ID, branch, blocker, or resume note"
agent: Orchestrator
---

Resume exactly one active CatastroSwitch phase from the available repo context.

Ground the resume decision in [docs/implementation-plan.md](../../docs/implementation-plan.md), [CONTRIBUTING.md](../../CONTRIBUTING.md), and the phase-state artifact in the real fork clone when one exists.

Start by inspecting the current branch, current phase-state artifact, and recent workflow context to infer the active phase before asking for clarification.

Your first response must be a short resume summary that includes:

- active phase
- current branch
- phase-state artifact status
- next ready task or blocker
- next agent
- immediate next action

Resume rules:

- If the phase branch or phase-state artifact is missing, create or confirm them before planning.
- If the plan is missing, stale, or contradicted by the current implementation, hand off to `Planner`.
- If a Planner-approved task is ready, hand off to `Coding Agent`.
- If a completed task is waiting for review, hand off to `Reviewer`.
- If every task in the phase has a Reviewer `Pass`, hand off to `Gatekeeper`.
- Stay in `Orchestrator` only long enough to perform the resume triage and continue the correct handoff.

Execution rules:

- Run exactly one phase at a time.
- Keep runtime work in the fork checkout and durable docs, schemas, contracts, scripts, prompts, and agent guidance in this control repo.
- Ask a clarifying question only if no phase can be inferred from the branch, artifact, or nearby context.
- After the resume summary, immediately continue the workflow with the chosen agent.