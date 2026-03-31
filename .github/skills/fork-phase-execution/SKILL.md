---
name: fork-phase-execution
description: Executes one CatastroSwitch phase at a time using the Planner -> Coding Agent -> Reviewer loop and the final Gatekeeper pass.
---

# Fork phase execution

Use this skill when a planner or coding agent is asked to run a large autonomous task for the fork.

## Procedure

1. Read `docs/implementation-plan.md`.
2. Pick exactly one phase ID unless the user explicitly asks for more.
3. Read the related phase context from:
   - `docs/architecture.md`
   - `docs/vscode-fork-additive-strategy.md`
   - `docs/vscode-fork-source-map.md`
4. Create or confirm the phase branch in the runtime fork checkout for that phase.
5. Create or confirm the phase state artifact in the runtime fork checkout for that phase.
6. Ask the Planner to reconcile current implementation versus the selected phase.
7. Use the Planner output to identify:
   - sequential tasks
   - parallel task groups
   - docs and validation required for each task
8. For each ready task:
   - send it to the Coding Agent
   - send the Coding Agent result to the Reviewer
   - if the Reviewer returns `Error`, loop back to the Coding Agent or Planner
9. Update the phase state artifact in the runtime fork checkout after planning, after each review, and after the Gatekeeper result.
10. Do not run the Gatekeeper until every task in the phase has a Reviewer `Pass`.
11. Run the Gatekeeper on the whole phase branch.
12. If the Gatekeeper returns `Error`, send the result back to the Planner and continue the loop.
13. If the Gatekeeper returns `Pass`, prepare the phase handoff and next-phase recommendation.

## Never do this

- Do not silently sprawl into multiple phases.
- Do not skip the Reviewer loop for a task.
- Do not skip the Gatekeeper because the phase looks "mostly done."
- Do not let the phase state artifact drift from the real loop.
- Do not copy a large upstream class unless the plan explicitly justifies it.
- Do not blur product-owned session visibility with unsupported universal introspection.
- Do not mix multiple phases on one branch.
- Do not treat the control repo as the home for runtime phase branches or phase state files.
