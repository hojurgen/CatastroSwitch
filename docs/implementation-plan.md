# Detailed Implementation Plan

This document turns the `CatastroSwitch` roadmap into a **phase-specific multi-agent execution system**.

Use it when you want to run one phase autonomously in the real VS Code fork without re-deciding branch strategy, task ordering, validation, or review flow each time.

## Required inputs before any phase

Always read:

- `docs/grounding.md`
- `docs/architecture.md`
- `docs/vscode-fork-additive-strategy.md`
- `docs/vscode-fork-source-map.md`
- `docs/vscode-fork-build-runbook.md`
- `docs/fork-backlog.md`
- `docs/agent-adapter-contract.md`

If the phase touches registry shape or adapter boundaries, also read:

- `schemas/workspace-registry.schema.json`
- `examples/workspace-registry.sample.json`

If the phase touches shipped product branding assets, also read:

- `docs\vscode-fork-branding-assets.md`

## Phase execution contract

### One phase per branch

Each phase owns one integration branch in the real fork clone.

Recommended phase branches:

- `multiagent/f0-baseline-bootstrap`
- `multiagent/f1-workspace-rail`
- `multiagent/f2-workspace-orchestration`
- `multiagent/f3-extension-session`
- `multiagent/f4-hardening-sync`

Rules:

- Do not mix more than one phase on the same integration branch.
- If multiple coding tasks run in parallel, they must still target the same phase branch.
- Parallel work may use short-lived sibling task branches or worktrees named from the phase branch, for example `multiagent/f2-workspace-orchestration-t3-profile-policy`.
- The phase branch is the source of truth for Gatekeeper review.

### Phase state artifact

Use one machine-readable phase state file per phase in the real fork clone.

Recommended path:

```text
<fork-root>\.catastroswitch\phase-state\<phase>.phase-state.json
```

Canonical contract files in this control repo:

- `schemas\phase-execution-state.schema.json`
- `examples\phase-execution-state.sample.json`

Helper scripts:

- `scripts\new-phase-branch.ps1`
- `scripts\new-phase-task-branch.ps1`
- `scripts\new-phase-state.ps1`

The phase-state artifact is also the deterministic lock source for the shared workspace hooks and cleanup tooling. Keep `executionLock.activeAgent`, `executionLock.activeTaskId`, `executionLock.allowedBranch`, `executionLock.allowedWorktree`, `executionLock.nextHandoffTarget`, `executionLock.pendingReviewForTask`, and `executionLock.dirtyWorktreePolicy` current alongside the task and review fields.

### Deterministic guardrails

- `.github\hooks\phase-enforcement.json` reads the phase-state `executionLock` and blocks runtime writes that target the wrong branch or worktree.
- `scripts\sync-phase-workflow-lane.ps1 -Apply` realigns the runtime fork to the locked phase lane, or to the first incomplete phase when no non-terminal lane exists, before the router or resume prompts continue orchestration.
- When the latest passed phase records `gatekeeper.recommendedNextPhase`, the sync helper prefers that explicit handoff over generic first-incomplete inference.
- The clean-sync runtime checkout should stay clean unless the lock explicitly points at that checkout.
- If the clean-sync checkout mirrors files from the locked worktree, repair it from the control repo with `scripts\repair-phase-worktree-state.ps1` instead of ad hoc `git clean` or branch switching.
- The control-repo local `pre-commit` hook blocks commits on `main`, and the phase hook denies runtime mutations while the locked worktree is on the wrong branch.
- The runtime-fork installed git hooks block commits on clean sync branches, block commits on the wrong active phase branch, and block pushes to `upstream` or dirty clean-sync pushes unless you override them intentionally.
- A phase that reaches `Pass` or `Error` must clear the active lane and move `executionLock.dirtyWorktreePolicy` to `phase_pass_clean`.

### Upstream maintenance rule

- Keep one clean sync branch in the runtime fork, normally `main` or `upstream-main-sync`, and fast-forward it from `upstream/main`.
- Before planning or resuming a long-lived phase, confirm the active phase branch has been rebased onto that clean sync branch after any material upstream movement.
- After an upstream replay, rerun `npm run compile`, the focused browser suites for the owned seams in that phase, and a self-host smoke run when shell, profile, extension-apply, or chat/session surfaces changed.
- If an upstream refresh moves a documented seam or creates a new conflict hotspot, update the task graph and the relevant source-map or contract docs before more coding.

Update the phase state artifact after:

- Planner output
- each Coding Agent task handoff
- each Reviewer result
- each Gatekeeper result
- each `executionLock` handoff or cleanup event that changes the allowed runtime branch or worktree

### Planner -> Coding Agent -> Reviewer -> Gatekeeper loop

Every phase follows this loop:

1. The user selects one phase ID.
2. The Planner compares the current implementation against this document.
3. The Planner decides whether the phase needs fresh implementation, partial implementation, or re-implementation because earlier work missed or drifted from the plan.
4. The Planner emits a task graph with explicit sequential dependencies and explicit parallel groups.
5. Each ready task is handed to one Coding Agent.
6. Each Coding Agent hands its completed task to the Reviewer.
7. The Reviewer returns `Pass` or `Error` with reasoning.
8. Any `Error` goes back to the Coding Agent, or back to the Planner if the plan itself is wrong.
9. Steps 5 through 8 repeat until every task in the phase has a Reviewer `Pass`.
10. Once all tasks have passed review, the Gatekeeper reviews the phase branch as a whole.
11. The Gatekeeper returns `Pass` or `Error` with reasoning.
12. Any Gatekeeper `Error` goes back to the Planner for phase re-planning, then back through the Coding Agent and Reviewer loop again.

That loop can happen N times. Do not skip it just because a task looks small.

### Parallel versus sequential rule

The Planner may mark tasks as parallel only if all of the following are true:

- they do not edit the same upstream file or the same high-risk registration seam
- they do not compete over the same runtime contract or shared state model
- their validation can run independently before merge back into the phase branch
- their docs impact can be merged without rewriting each other

If two tasks share the same file, the same registration point, or the same data contract, default to sequential execution.

### Planner responsibilities

The Planner must:

- reconcile current state against the selected phase goal and exit criteria
- compare the selected phase branch against the current clean sync branch and call out when upstream replay is required before more feature work
- identify missing, partial, or incorrect work and plan re-implementation when needed
- emit a concrete task graph with:
  - task IDs
  - goals
  - dependencies
  - parallel groups
  - branch expectations
  - upstream rebase hotspots
  - validation per task
  - docs and tests that must be updated
- call out the exact reason why any task must stay sequential
- stop phase sprawl before it starts

### Coding Agent responsibilities

The Coding Agent must:

- implement exactly one Planner-approved task at a time
- stay on the current phase branch or an approved sibling task branch for it
- keep the task scoped to its task card
- run the task validation before handoff
- update docs/tests that are part of that task card
- hand off to the Reviewer with exact files changed and validation results

### Reviewer responsibilities

The Reviewer must:

- review exactly one completed task at a time
- compare the implementation against the task card, not against a new secret wishlist
- return `Pass` or `Error`
- explain reasoning, missing validation, broken assumptions, or docs drift
- send plan defects back to the Planner instead of forcing the Coding Agent to guess

### Gatekeeper responsibilities

The Gatekeeper must:

- review the whole phase after every task has a Reviewer `Pass`
- check the broader phase goal, exit criteria, task coverage, docs coverage, and cross-task coherence
- record whether the phase is ready to survive the next upstream replay or whether it is carrying explicit maintenance debt
- return `Pass` or `Error`
- explain reasoning in broader product terms, not just file-level feedback
- call out any phase task that still looks incomplete, incorrectly scoped, or unsupported by the documented boundaries

### Required output format

Planner output must include:

- phase ID
- phase branch
- phase status: fresh implementation, partial implementation, or re-implementation
- confirmed goals
- current gaps
- sequential chain
- parallel groups
- task cards with acceptance criteria
- required docs updates
- required validation
- next ready tasks
- a fenced `json` block that can be copied into the phase state artifact planner section

Reviewer output must include:

- `Outcome: Pass` or `Outcome: Error`
- task ID
- branch checked
- reasoning
- required fixes
- docs or validation gaps
- whether the task goes back to Coding Agent or Planner
- a fenced `json` block shaped like:

```json
{
  "outcome": "Pass",
  "taskId": "F1-T2",
  "branch": "multiagent/f1-workspace-rail-t2-shell-behavior",
  "reasoning": "Why the task passed or failed.",
  "requiredFixes": [],
  "docsOrValidationGaps": [],
  "nextHandoffTarget": "Coding Agent"
}
```

Gatekeeper output must include:

- `Outcome: Pass` or `Outcome: Error`
- phase ID
- phase branch
- goals checked
- errors
- broader risks
- reasoning
- required next action
- recommended next phase or `null`
- a fenced `json` block shaped like:

```json
{
  "outcome": "Pass",
  "phaseId": "F1",
  "phaseBranch": "multiagent/f1-workspace-rail",
  "goalsChecked": [],
  "errors": [],
  "broaderRisks": [],
  "reasoning": "Why the phase passed or failed.",
  "requiredNextAction": "Merge or continue to the next phase.",
  "recommendedNextPhase": "F2"
}
```

### Default patterns

- use one phase branch as the integration branch
- let the Planner define the task graph before coding starts
- keep tasks additive and seam-oriented
- let Coding Agents own one task each
- make Reviewer decisions task-scoped
- make Gatekeeper decisions phase-scoped
- update docs and tests inside the same loop instead of creating a documentation debt pile

### Default anti-patterns

- coding directly against a phase ask without a Planner task graph
- running multiple phases on one branch
- parallelizing tasks that touch the same upstream file or registration seam
- letting Coding Agents review their own work
- letting the Gatekeeper act as a second task reviewer instead of a phase checker
- treating `Error` as optional wording instead of a real stop signal
- calling a phase done because the UI looks plausible while tests, docs, and boundaries still drift

## Phase summary

| Phase | Phase branch | Goal | Gatekeeper pass signal |
|---|---|---|---|
| F0 | `multiagent/f0-baseline-bootstrap` | create a trustworthy baseline fork workflow and execution contract | the fork boots, patch zones are confirmed, and the operating agreement is documented |
| F1 | `multiagent/f1-workspace-rail` | land a product-owned workspace rail as a stable shell surface | the rail exists, behaves like a real workbench part, and the shell stays stable |
| F2 | `multiagent/f2-workspace-orchestration` | create workspace context and deterministic profile behavior | the rail is service-backed and profile behavior is explicit, reversible, and tested |
| F3 | `multiagent/f3-extension-session` | add extension-set behavior plus product-owned session summaries | extension and session behavior is explicit, bounded, and trustworthy |
| F4 | `multiagent/f4-hardening-sync` | harden the fork and make upstream maintenance routine | tests, ownership, and rebase playbooks make the fork sustainable |

## Phase F0 - Baseline and fork bootstrap

### Goal

Create a reliable fork baseline and remove execution ambiguity before product code starts.

### Entry criteria

- no trusted local self-host baseline exists yet, or the baseline needs to be revalidated

### Exit criteria

- the fork clone boots locally
- likely patch zones are confirmed against the checked-out source
- phase branch naming and execution rules are documented
- supporting docs reflect reality

### Default task graph

| Task ID | Goal | Depends on | Run mode | Primary surface | Validation |
|---|---|---|---|---|---|
| F0-T1 | clone, install, compile, watch, and self-host the fork baseline | none | sequential root | real fork clone plus upstream remotes | `npm install`, `npm run compile`, `npm run watch`, `scripts\\code.bat` |
| F0-T2 | confirm the exact upstream patch zones for shell, profiles, and chat | F0-T1 | parallel group A | fork source tree plus `docs\\vscode-fork-source-map.md` | all planned patch zones match the checked-out upstream version |
| F0-T3 | document phase branch naming, sibling task branch rule, and validation expectations | F0-T1 | parallel group B | control-repo docs and local working agreement | branch and workflow rules are explicit |
| F0-T4 | sync runbook, source map, and plan drift found during bootstrap | F0-T2, F0-T3 | sequential closeout | control-repo docs | control-repo validation passes and docs match reality |

### Phase patterns

- use F0 to remove ambiguity before any product-owned shell work
- treat branch and validation rules as phase-zero infrastructure

### Phase anti-patterns

- starting F1 without a self-hosted baseline
- guessing patch zones from stale docs

## Phase F1 - Workspace rail shell integration

### Goal

Land a product-owned workspace rail as a real workbench surface without destabilizing the shell.

### Entry criteria

- F0 has a trustworthy baseline

### Exit criteria

- the baseline desktop and server branding assets are replaced from a repeatable export manifest
- the rail is a real shell part
- focus, visibility, and persistence are correct
- a placeholder UI exists for later orchestration work
- shell regressions are covered and docs are synced

### Default task graph

| Task ID | Goal | Depends on | Run mode | Primary surface | Validation |
|---|---|---|---|---|---|
| F1-T0 | replace baseline product branding assets and establish the repeatable export workflow | none | sequential root | runtime fork `resources/{win32,darwin,linux,server}` plus `fork\tooling\branding-assets.manifest.json` | exported assets land in the fork, `scripts\code.bat` still launches, and the product surfaces show CatastroSwitch branding |
| F1-T1 | add the rail part, identifier, and layout slot | F1-T0 | sequential shell lane | `src/vs/workbench/browser/layout.ts` plus new part files | self-host launches and the rail is visible |
| F1-T2 | add focus, visibility, commands, and persistence | F1-T1 | parallel group A | rail part plus workbench command/state surfaces | rail state survives relaunch and focus flow works |
| F1-T3 | render placeholder workspace UI with stable layout behavior | F1-T1 | parallel group B | rail rendering files | placeholder UI renders, resizes, and does not break the shell |
| F1-T4 | add shell hardening, tests, and doc sync | F1-T2, F1-T3 | sequential closeout | shell tests plus control-repo docs | shell tests pass and docs match the rail shape |

### Phase patterns

- keep the rail product-owned from the first diff
- land static branding replacement before shell layout surgery so product identity and layout regressions do not blur together
- isolate shell registration from placeholder rendering when possible

### Phase anti-patterns

- mixing shell layout surgery with real workspace orchestration too early
- treating wordmark-heavy marketing art as the shipped app-icon master
- hiding persistence logic inside placeholder UI code

## Phase F2 - Workspace orchestration and profile behavior

### Goal

Create the workspace context service and make profile behavior deterministic and reversible.

### Entry criteria

- F1 has a stable rail shell surface

### Exit criteria

- the rail is backed by a real workspace context service
- workspace-to-profile policy is explicit
- non-extension profile resources follow workspace context
- recovery paths, feedback, and tests exist

### Default task graph

| Task ID | Goal | Depends on | Run mode | Primary surface | Validation |
|---|---|---|---|---|---|
| F2-T1 | create the workspace context service and registration seams | none | sequential root | new service under `src/vs/workbench/services/...` plus workbench registrations | service tests pass and consumers can subscribe |
| F2-T2 | connect the rail to the real workspace context service | F2-T1 | parallel group A | rail files plus service consumer paths | rail updates on state changes and placeholder-only logic is gone |
| F2-T3 | define workspace-to-profile resolution policy | F2-T1 | parallel group B | profile management and initialization seams | resolution logic is deterministic and testable |
| F2-T4 | apply workspace policy to non-extension profile resources | F2-T3 | sequential profile lane | settings, keybindings, tasks, snippets, and global state resources | non-extension resources behave consistently per workspace |
| F2-T5 | add recovery UX, rollback behavior, tests, and doc sync | F2-T2, F2-T4 | sequential closeout | user feedback, tests, and control-repo docs | recovery paths are documented, tested, and explicit |

### Phase patterns

- separate context service work from profile policy work as long as the shared model stays stable
- make profile behavior previewable, reversible, and explainable

### Phase anti-patterns

- letting profile logic leak into random UI handlers
- changing profile resources without an explicit policy layer first

## Phase F3 - Extension-set behavior and session visibility

### Goal

Add explicit extension-set behavior plus trustworthy product-owned session summaries.

### Entry criteria

- F2 has stable workspace context and profile behavior

### Exit criteria

- extension deltas are planned and applied explicitly
- product-owned session summaries exist and render in the rail
- unsupported external visibility is clearly marked as adapter-required
- the phase is hardened with tests and docs

### Default task graph

| Task ID | Goal | Depends on | Run mode | Primary surface | Validation |
|---|---|---|---|---|---|
| F3-T1 | compute the extension-state delta for a selected workspace | none | parallel root A | extension resources plus extension-management services | extension delta is deterministic and previewable |
| F3-T2 | create the product-owned session summary service | none | parallel root B | `src/vs/workbench/contrib/chat/common/...` and browser chat surfaces | session summaries are correct for supported product-owned runtimes |
| F3-T3 | implement the extension-set apply, confirm, and recovery flow | F3-T1 | sequential extension lane | extension-management application flow | apply flow works in self-host and failure paths are explicit |
| F3-T4 | surface session summaries in the rail | F3-T2 | sequential session lane | rail rendering plus session summary consumption | rail shows trustworthy session summaries and clear empty/error states |
| F3-T5 | harden the adapter boundary and supporting docs | F3-T2, F3-T4 | sequential boundary closeout | `docs\\agent-adapter-contract.md` plus runtime boundary points | product-owned versus adapter-driven visibility is explicit |
| F3-T6 | phase hardening, tests, and final doc sync | F3-T3, F3-T5 | sequential closeout | tests plus control-repo docs | extension and session behavior is covered and documented |

### Phase patterns

- let extension behavior and session visibility evolve in separate lanes until they meet in the rail
- keep unsupported third-party visibility outside the product-owned path

### Phase anti-patterns

- making silent extension changes without a preview/apply model
- presenting universal agent visibility when only product-owned or adapter-backed visibility exists

## Phase F4 - Hardening and upstream sync

### Goal

Make the fork sustainable through better coverage, clearer ownership, and a practical upstream sync playbook.

### Entry criteria

- F3 functionality is coherent enough to harden

### Exit criteria

- the highest-risk flows have regression coverage
- patch ownership is documented
- the upstream rebase playbook is actionable
- the release-readiness pass has enough evidence to trust the fork

### Default task graph

| Task ID | Goal | Depends on | Run mode | Primary surface | Validation |
|---|---|---|---|---|---|
| F4-T1 | expand regression coverage for shell, context, profiles, extension behavior, and session summaries | none | parallel group A | tests across shell, profile, extension, and chat surfaces | the highest-risk transitions are covered by practical regression tests |
| F4-T2 | document custom patch ownership by concern and file set | none | parallel group B | control-repo docs and fork notes | patch surfaces are auditable during rebases |
| F4-T3 | create the upstream rebase playbook and conflict heuristics | F4-T2 | sequential maintenance lane | rebase/runbook docs | the rebase playbook is concrete and repeatable |
| F4-T4 | prepare release-readiness evidence for Gatekeeper review | F4-T1, F4-T2, F4-T3 | sequential closeout | docs, tests, and readiness evidence | readiness evidence is complete enough for a phase-level `Pass` or `Error` |

### Phase patterns

- parallelize tests and ownership mapping while design context is still fresh
- make rebase documentation file-specific, not generic

### Phase anti-patterns

- treating hardening as vague cleanup with no evidence target
- writing a generic rebase note that does not name likely conflict zones

## Stop conditions

The Planner, Coding Agent, Reviewer, or Gatekeeper must stop and escalate if:

- a task would require copying a large upstream class
- a task crosses into another phase without explicit approval
- a required upstream seam no longer exists in the current VS Code version
- a proposed task would blur product-owned session state with unsupported universal introspection
- the task graph is wrong enough that the Coding Agent would have to invent a new plan
- the phase branch no longer reflects the phase being reviewed

## Minimum handoff artifacts

Every task handoff must include:

- phase ID
- task ID
- branch used
- summary of changes
- exact files changed
- validation run
- docs updated
- remaining risks

Every phase gate handoff must also include:

- completed task list
- Reviewer outcomes for each task
- unresolved risks
- next recommended action
