---
name: Gate CatastroSwitch Stage
description: "Run the Gatekeeper agent against a planning, implementation, or review stage result."
agent: Gatekeeper
tools: [read, search]
argument-hint: "Stage name plus the content to gate"
---
Evaluate the provided CatastroSwitch stage result against [implementation-plan.md](../../docs/implementation-plan.md).

Return one of:

- `approve`
- `rework`
- `blocked`

Rules:

- Do not reopen an approved stage.
- If the same stage has already failed one rework cycle, return `blocked` instead of requesting more churn.
- Return the decision to `Orchestrator`; do not choose the rework executor directly.
