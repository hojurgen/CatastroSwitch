---
name: Implement CatastroSwitch Task
description: "Run the CodingAgent on one approved CatastroSwitch task with reviewer handoff."
agent: CodingAgent
tools: [read, edit, search, execute, agent, todo]
argument-hint: "One approved task from docs/implementation-plan.md"
---
Implement one approved CatastroSwitch task from [implementation-plan.md](../../docs/implementation-plan.md).

Rules:

- Stay within the scope of one task.
- Use `Researcher` only when needed.
- Validate the task before handing it to `Reviewer`.
- If the reviewer rejects the task twice, stop and report `blocked`.
- Do not route directly to `Gatekeeper`; the handoff must go through `Reviewer`.
