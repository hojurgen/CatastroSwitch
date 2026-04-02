---
name: Review Ready Task
description: "Use when: review a completed CatastroSwitch task that is ready for Reviewer Pass or Error, using the active phase context and task card."
argument-hint: "Optional: task ID, branch, review focus, or blocker"
agent: Reviewer
---

Review exactly one completed CatastroSwitch task that is ready for the Reviewer step.

Ground the review in [docs/implementation-plan.md](../../docs/implementation-plan.md), [CONTRIBUTING.md](../../CONTRIBUTING.md), the relevant task card from the active phase-state artifact, and the documented fork boundary.

Before you review, inspect the current branch, current task context, and active phase-state artifact to identify the single task that is actually ready for review.

Selection rules:

- Prefer the explicitly named task if the user provides one.
- Otherwise select the single completed task that is awaiting Reviewer output.
- If no completed task is ready for review, say so clearly and stop.
- If multiple tasks appear to be simultaneously eligible, say so and name the ambiguity instead of guessing.

Review rules:

- Review exactly one task.
- Compare the implementation against the Planner task card, selected phase, docs updates, validation evidence, and the fork-versus-control-repo boundary.
- Return `Outcome: Pass` or `Outcome: Error` with the required fenced `json` block.
- If the problem is a task-card or dependency defect rather than an implementation defect, send it back to `Planner`.

Do not broaden into full-phase review. This prompt is only for the Reviewer step.