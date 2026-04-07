# CatastroSwitch Implementation Plan

## Status

Phase 1 is complete.

- Branding is already implemented.
- The runtime fork is cloned locally at `C:\src\vscode-multiagent`.
- The branding pipeline already derives product icons from `C:\CatastroSwitch\assets\logo.svg`.
- The next work is the actual control-plane product, not more bootstrap work.

## Goal

Build a CatastroSwitch control plane inside the VS Code fork that:

1. Lists the workspaces known on the local machine.
2. Lists the local GitHub Copilot sessions known on the local machine.
3. Lets the user switch the current VS Code window to a selected workspace.
4. Applies the chosen extension policy for that workspace.
5. Lets the user switch back to the previous workspace.
6. Surfaces local-machine status for active, waiting, stale, and errored agent work.

This should stay mostly additive. The default strategy is to add new CatastroSwitch-specific services, views, and contracts, and only touch existing VS Code files at narrow registration or integration seams.

## Product Requirements

### Required

- Machine-local workspace inventory.
- Machine-local GitHub Copilot session inventory.
- Same-window workspace switching.
- Switch-back to the prior workspace.
- Workspace-specific extension policy.
- Local-machine agent monitoring.
- Durable control-repo plan without loop-driving execution JSON.

### Preferred v1 Behavior

- The UI is machine-centric, not window-centric.
- Workspaces come from two sources in v1: the CatastroSwitch registry and VS Code recent-workspace history.
- Sessions come from the existing sessions provider stack in the runtime fork.
- Extension policy changes should avoid invasive core edits.
- When extension changes are significant, restart the extension host by reloading the same window.

### Not In Scope for v1

- Cross-machine sync.
- Full filesystem scanning for arbitrary workspaces.
- A custom extension-host lifecycle implementation.
- Deep refactoring of core workbench, storage, or extension runtime systems.
- Replacing VS Code Profiles as a concept. Profiles remain useful as metadata and policy templates.

## Design Principles

### Additive First

Create CatastroSwitch-specific code under new folders and new services wherever possible.

### Narrow Core Seams

When an existing VS Code file must change, keep the change surgical: registration, import, small interface extension, or a single event hook.

### Machine-Local Model

The primary user-facing entities are:

- local workspaces
- local GitHub Copilot sessions
- local switch history
- local machine status

Open windows are only one implementation detail used to transport or publish state.

### Same Window

The control plane should reuse the current window. If the target workspace needs a materially different extension set, restart the extension host by reloading that same window. Do not fall back to opening a second window in normal flow.

### Durable Plan, Ephemeral Telemetry

Plan, contracts, samples, and operator docs belong in the control repo. Heartbeats and session snapshots stay machine-local and outside version control.

### No Agent Loop Artifact

CatastroSwitch should not depend on a mutable phase-execution JSON file that agents continuously rewrite while working.

- `docs/implementation-plan.md` is the authoritative roadmap.
- Runtime and sample artifacts may carry a simple `planPath` string back to that roadmap.
- Agents should update durable planning docs only at milestone boundaries, not on every intermediate step.
- No product flow should require an agent to spin on status-field mutation to decide what to do next.

## Current Baseline

### Phase 1 Completed

Phase 1 covered branding and runtime bootstrap.

Completed artifacts include:

- `C:\CatastroSwitch\scripts\export-product-icons.ps1`
- `C:\CatastroSwitch\assets\logo.svg`
- `C:\src\vscode-multiagent\build\lib\catastroswitchBranding.ts`
- runtime self-host branding integration on the `catastroswitch` branch

This plan starts from that completed state.

## Product Model

### Workspace Sources

CatastroSwitch should treat the local machine workspace catalog as a merge of:

1. Durable managed workspace entries from the CatastroSwitch registry.
2. Recently opened workspace history from VS Code application or profile storage.

The merged catalog should label each workspace with its source:

- managed
- recent
- managed-and-recent

### Session Sources

CatastroSwitch should treat the local machine session catalog as a merge of:

- active sessions from the sessions provider stack
- local snapshot data written by CatastroSwitch monitoring services

The merged session model should surface:

- provider
- status
- workspace correlation
- recent tool activity summary
- last heartbeat
- stale or error state

### Switch Policy

Each managed workspace should be able to resolve:

- target local path
- optional profile template
- extension policy
- monitoring settings
- plan reference

### Switch-Back State

The current window should maintain a small persisted switch-back history so a reload does not destroy the return path.

## Runtime Architecture

### Control Repo Responsibilities

The control repo should own:

- the human-readable implementation plan
- the GitHub Copilot workflow instructions, custom agents, and prompt entrypoints
- workspace registry schema and sample
- agent session snapshot schema and sample
- operator and bootstrap docs

### Runtime Fork Responsibilities

The runtime fork should own:

- local machine discovery services
- the CatastroSwitch UI container and views
- same-window switch orchestration
- extension policy application
- machine-local session heartbeat publishing and aggregation

## Code Strategy

## New Code To Add

### Control Repo

- `docs/implementation-plan.md`
- future schema and sample updates for extension policy and discovery hints

### Runtime Fork

Preferred new runtime folders:

- `src/vs/workbench/contrib/catastroswitch/browser/`
- `src/vs/workbench/contrib/catastroswitch/common/`
- `src/vs/workbench/services/catastroswitch/browser/`
- `src/vs/workbench/services/catastroswitch/common/`
- `src/vs/workbench/contrib/catastroswitch/test/`

Preferred new runtime files:

- `src/vs/workbench/contrib/catastroswitch/browser/catastroswitch.contribution.ts`
- `src/vs/workbench/contrib/catastroswitch/browser/catastroswitchIcons.ts`
- `src/vs/workbench/contrib/catastroswitch/browser/common.ts`
- `src/vs/workbench/contrib/catastroswitch/browser/controlPlaneViewPaneContainer.ts`
- `src/vs/workbench/contrib/catastroswitch/browser/overviewView.ts`
- `src/vs/workbench/contrib/catastroswitch/browser/workspacesView.ts`
- `src/vs/workbench/contrib/catastroswitch/browser/sessionsView.ts`
- `src/vs/workbench/contrib/catastroswitch/browser/workspaceSwitchQuickAccess.ts`
- `src/vs/workbench/contrib/catastroswitch/browser/controlPlaneActions.ts`
- `src/vs/workbench/contrib/catastroswitch/browser/media/controlPlane.css`
- `src/vs/workbench/services/catastroswitch/common/catastroswitchTypes.ts`
- `src/vs/workbench/services/catastroswitch/common/catastroswitchWorkspaceCatalogService.ts`
- `src/vs/workbench/services/catastroswitch/common/catastroswitchSessionCatalogService.ts`
- `src/vs/workbench/services/catastroswitch/common/catastroswitchSwitchService.ts`
- `src/vs/workbench/services/catastroswitch/common/catastroswitchExtensionPolicyService.ts`
- `src/vs/workbench/services/catastroswitch/common/catastroswitchSnapshotStoreService.ts`
- `src/vs/workbench/services/catastroswitch/browser/catastroswitchWorkspaceCatalogService.ts`
- `src/vs/workbench/services/catastroswitch/browser/catastroswitchSessionCatalogService.ts`
- `src/vs/workbench/services/catastroswitch/browser/catastroswitchSwitchService.ts`
- `src/vs/workbench/services/catastroswitch/browser/catastroswitchExtensionPolicyService.ts`
- `src/vs/workbench/services/catastroswitch/browser/catastroswitchSnapshotStoreService.ts`

These files should contain the CatastroSwitch logic instead of pushing new responsibilities into unrelated workbench areas.

## Existing Files To Touch Minimally

### Runtime Fork Registration and Integration

Touch these only for additive registration or tiny seam extensions:

- `src/vs/workbench/workbench.common.main.ts`
  - Why: import the CatastroSwitch contribution file so the workbench loads the new UI and services.
  - Expected change: one additive import.

- `src/vs/workbench/services/workspaces/browser/abstractWorkspaceEditingService.ts`
  - Why: only if the existing enter-workspace event chain does not provide enough information for CatastroSwitch switch tracking.
  - Expected change: tiny event payload extension or hook, only if required.

- `src/vs/platform/workspace/common/workspaceEditing.ts`
  - Why: only if a small interface extension is needed to carry prior-workspace metadata or switch join behavior.
  - Expected change: one small interface addition, only if required.

- `src/vs/workbench/services/userDataProfile/browser/userDataProfileManagement.ts`
  - Why: only if CatastroSwitch needs a cleaner event surface for profile synchronization during same-window switching.
  - Expected change: event exposure only, not profile logic rewrites.

- `src/vs/workbench/services/extensions/common/abstractExtensionService.ts`
  - Why: ideally not at all. Only revisit if the public or existing internal event surface proves insufficient.
  - Expected change: none in v1 unless testing proves a narrow restart hook is unavoidable.

## Existing Files To Read But Not Refactor

Use these as dependencies or references. Do not rewrite them for v1:

- `src/vs/workbench/services/workspaces/browser/workspacesService.ts`
- `src/vs/sessions/contrib/sessions/browser/sessionsProvidersService.ts`
- `src/vs/sessions/contrib/sessions/browser/sessionsManagementService.ts`
- `src/vs/platform/extensionManagement/common/extensionEnablementService.ts`
- `src/vs/workbench/services/host/browser/host.ts`
- `src/vs/platform/storage/common/storage.ts`

## Existing Files That Should Remain Untouched

Do not refactor these systems for v1:

- extension host startup and shutdown internals
- core workspace context service state flow
- storage service implementation details
- host service window-opening internals
- user data profile persistence internals

The plan should use existing public or semi-public seams around those systems instead of changing their core behavior.

## UI Specification

### Placement

Add a new Activity Bar container named `CatastroSwitch`.

- Location: primary sidebar
- Icon: a dedicated CatastroSwitch theme icon registered through the icon registry
- Behavior: persistent like Explorer, Search, Source Control, Extensions

### Primary Workspace Switcher

Workspace switching should not primarily behave like a static sidebar list. It should feel visually closer to Windows Alt+Tab.

Preferred v1 interaction:

- invoke a centered switcher overlay from a command and keybinding
- render workspaces as large selectable cards rather than thin rows
- let the user cycle rapidly across workspace cards with keyboard navigation
- show enough metadata on each card to decide without opening details first
- accept selection to switch the current window to that workspace

Recommended implementation seam:

- build the switcher as a CatastroSwitch Quick Access provider or Quick Pick-style overlay
- keep it additive by registering a new provider rather than building a custom floating shell from scratch
- keep the sidebar container for overview, session monitoring, and deeper browsing

The sidebar remains the durable control-plane home. The Alt+Tab-style switcher becomes the fast entry point for switching.

### View Layout

The CatastroSwitch container should ship with three views in v1.

#### 1. Overview View

Purpose: machine-local summary.

Content:

- current workspace label and path
- current switch-back target, if available
- count of managed workspaces
- count of recent workspaces
- count of active GitHub Copilot sessions
- count of waiting sessions
- count of stale or errored sessions

Title actions:

- Refresh
- Switch Back
- Toggle Managed Only
- Open Settings

Empty state:

- explain that CatastroSwitch needs either registry entries or VS Code recent workspaces
- provide actions to open the registry sample or refresh discovery

#### 2. Workspaces View

Purpose: browse and inspect the local machine workspace catalog, while the primary switch gesture uses the Alt+Tab-style overlay.

Grouping:

- Current
- Managed
- Recent
- Unmanaged Recent

Each row should show:

- workspace label
- normalized local path as secondary text
- source badges such as `Managed`, `Recent`, `Current`
- extension policy badge such as `Profile: Runtime` or `Policy: Custom`
- session count if the workspace currently has monitored activity
- last active timestamp when available

Primary row actions:

- Switch Here
- Open Switcher
- Switch Back
- Open Plan
- Reveal Registry Entry
- Add To Registry for recent-only entries

Context menu actions:

- Copy Path
- Open In Native Explorer
- Open Plan
- Show Session Details

Visual direction:

- native workbench list or tree view, not a custom webview in v1
- badges and icons should use theme colors and native workbench patterns
- use severity colors only for alert states

### Alt+Tab-Style Workspace Overlay

This is the signature CatastroSwitch interaction.

Behavior:

- appears centered over the current workbench, similar in visual weight to a system switcher or command overlay
- shows one horizontal strip or compact grid of workspace cards
- highlights the current selection strongly
- supports cycling by keyboard with immediate visual feedback
- allows quick confirmation to switch, dismiss, or switch back

Each workspace card should show:

- workspace label
- short normalized path
- current-state badge such as `Current`, `Managed`, or `Recent`
- small status indicators for active GitHub Copilot sessions
- extension-policy hint such as `Runtime Profile` or `Custom Policy`
- optional plan badge when the workspace is part of active delivery work

Recommended actions inside the overlay:

- `Enter`: switch to selected workspace
- `Tab` or arrow keys: cycle selection
- `Shift+Tab`: reverse cycle
- `Ctrl+Delete` or an action button: remove a recent-only entry from the machine-local recent list if supported later
- `Esc`: dismiss without switching

Visual direction:

- cards should feel like live switch targets rather than configuration rows
- keep previews schematic in v1; do not attempt live bitmap thumbnails of editors or windows
- use strong focus treatment, concise metadata, and session badges to mimic the decision speed of Alt+Tab without building a full OS-level task switcher clone
- keep the overlay native to workbench quick input theming and focus rules where possible

#### 3. Sessions View

Purpose: browse local GitHub Copilot sessions by status and workspace.

Grouping:

- Active
- Waiting
- Stale
- Error

Each row should show:

- session title or fallback identifier
- provider name
- correlated workspace label or path
- status badge
- last tool summary chip or short text
- last heartbeat time

Primary row actions:

- Focus Workspace
- Switch To Workspace
- Open Plan
- Refresh Session Status

Context menu actions:

- Copy Session Id
- Reveal Snapshot File
- Mark Stale Ignored for local diagnostics only

### Detail Behavior

Selecting a workspace or session should not require a custom editor in v1.

Preferred v1 approach:

- show rich rows in native views
- use tooltip text for compact details
- open the implementation plan or registry JSON in a normal editor when deeper inspection is needed

### Switch-Back UX

The top-level CatastroSwitch toolbar should always surface `Switch Back` when a valid prior workspace exists.

Behavior:

- disabled when no prior workspace is stored
- enabled after any successful CatastroSwitch-driven switch
- survives same-window reload

### Alerts and Monitoring UX

The container should surface machine-local alert states without becoming noisy.

Use:

- warning badges for stale sessions
- error badges for broken snapshots or failed workspace resolution
- subtle status text for idle or waiting sessions

Avoid:

- modal popups for normal polling state
- custom dashboards that fight the native workbench shell in v1

## Detailed Phases

### Tracking Conventions

- Use the checklists below as the execution ledger for implementation work.
- A `Planner` task should clear one coherent group of unchecked items and should not span multiple phases.
- A phase is ready for `Gatekeeper` only when its implementation checklist and validation checklist are complete.
- Mark a checkbox complete only after the repo state or runtime behavior has been verified.
- The preferred execution order remains sequential unless a dependency is explicitly called out as independent.

### Current Phase Status

- Phase 1: complete
- Phase 2: in progress
- Phases 3 to 7: not started

## Phase 1 - Branding Foundation

Status: complete.

Objective:

- Replace stock VS Code branding with CatastroSwitch branding using `logo.svg` as the single source of truth.

Completed checklist:

- [x] Export CatastroSwitch product icons from `assets/logo.svg`.
- [x] Integrate CatastroSwitch branding into the runtime fork build pipeline.
- [x] Verify self-host branding uses CatastroSwitch assets on the `catastroswitch` branch.

No further implementation work is planned here beyond normal regression verification after upstream rebases.

## Phase 2 - Repo Plan and Contract Alignment

Status: in progress.

Objective:

- Make the machine-local product model durable in the control repo before runtime implementation starts.

Dependencies:

- Phase 1 complete.

Implementation checklist:

### Plan and docs

- [x] Establish `docs/implementation-plan.md` as the authoritative roadmap.
- [x] Update `docs/architecture.md` to match the machine-local, same-window product direction.
- [x] Update `README.md` so the control repo purpose and roadmap entrypoint are clear.
- [ ] Add a short operator-facing section that explains how to execute a phase against this plan without reintroducing workflow-state JSON.

### Workflow surfaces

- [x] Add `.github/copilot-instructions.md` for repository-wide workflow rules.
- [x] Add `.github/agents/*.agent.md` for Orchestrator, Planner, Researcher, CodingAgent, Reviewer, and Gatekeeper.
- [x] Add `.github/prompts/*.prompt.md` entrypoints for phase execution, single-task execution, and stage gating.
- [x] Align the agent instructions so they prefer authoritative MCP documentation tools when available.

### Contracts and samples

- [x] Remove the old phase-execution JSON schema and sample from the control repo.
- [x] Update `schemas/workspace-registry.schema.json` to use `planPath` instead of workflow-state references.
- [x] Update `schemas/agent-session-snapshot.schema.json` to use `planPath` instead of workflow-state references.
- [x] Update the workspace and session sample JSON files so they point back to this plan.
- [ ] Add any missing extension-policy metadata needed by Phase 5 without overdesigning the contract early.
- [ ] Add any missing discovery or source metadata needed by Phase 3 deduplication and labeling.

### Repo ergonomics

- [x] Keep `.vscode/settings.json` aligned with the current schema samples.
- [ ] Perform one final consistency pass so plan, docs, schema samples, and workflow prompts describe the same current operating model.
- [ ] Land the control-repo alignment changes once the plan wording and contracts are stable.

Validation checklist:

- [x] No agent or prompt depends on mutable workflow-state JSON.
- [x] Remaining JSON files are product contracts or examples, not workflow-control state.
- [x] Workspace customization files validate cleanly after the workflow updates.
- [ ] `README.md`, `docs/architecture.md`, and this plan use the same terminology for machine-local workspaces, sessions, and same-window switching.
- [ ] Sample JSON files still validate after any Phase 2 contract edits.

Ready to advance when:

- All remaining Phase 2 checkboxes are complete.

## Phase 3 - Machine Discovery Services

Status: not started.

Objective:

- Build runtime services that can list local workspaces and local GitHub Copilot sessions without switching the current window.

Dependencies:

- Phase 2 complete enough that the registry and snapshot contracts are stable for first implementation.

Implementation checklist:

### Shared types and service surface

- [ ] Create shared CatastroSwitch types for workspace entries, workspace sources, session entries, session status, and workspace-session correlation.
- [ ] Define read-only service interfaces for the workspace catalog and session catalog.
- [ ] Add refresh or event semantics so the UI can react to catalog updates without inventing a custom runtime protocol.

### Workspace discovery

- [ ] Load managed workspaces from the CatastroSwitch registry contract.
- [ ] Load recent workspaces from existing VS Code workspace history services.
- [ ] Normalize workspace identifiers and local paths before merge.
- [ ] Deduplicate managed and recent entries into `managed`, `recent`, and `managed-and-recent` categories.
- [ ] Preserve enough source metadata for the Workspaces view badges and filters.

### Session discovery

- [ ] Read provider-backed session state from the sessions provider stack.
- [ ] Read active-session state from the existing sessions management services.
- [ ] Define the initial correlation rules between sessions and workspaces using path data and identifiers where available.
- [ ] Expose a read-only machine-local session catalog with stable status values.

### Tests and validation

- [ ] Add unit tests for workspace merge and deduplication behavior.
- [ ] Add unit tests for session-to-workspace correlation rules.
- [ ] Add tests for deterministic labeling of unmanaged recent workspaces.

Validation checklist:

- [ ] The workspace catalog returns stable results across repeated refreshes.
- [ ] The session catalog returns stable results across repeated refreshes.
- [ ] Unmanaged recent workspaces remain visible but clearly marked.
- [ ] No switching or mutation behavior has been added yet.
- [ ] No session provider refactor is required for the initial service surface.

Ready to advance when:

- The runtime fork exposes stable read-only catalogs for workspaces and sessions.

## Phase 4 - Control Plane Shell

Status: not started.

Objective:

- Add the machine-local CatastroSwitch UI shell inside the workbench.

Dependencies:

- Phase 3 services available in at least a read-only form.

Implementation checklist:

### Registration and contribution wiring

- [ ] Add `catastroswitch.contribution.ts` and register the CatastroSwitch Activity Bar container.
- [ ] Register CatastroSwitch icons and any required theme contributions.
- [ ] Add the minimal additive import in `src/vs/workbench/workbench.common.main.ts`.

### Sidebar views

- [ ] Implement the Overview view using native workbench view patterns.
- [ ] Implement the Workspaces view using native list or tree patterns.
- [ ] Implement the Sessions view using native list or tree patterns.
- [ ] Wire toolbar actions for refresh, switch back, filtering, and settings access.

### Primary switcher overlay

- [ ] Implement the Alt+Tab-style workspace switcher as a Quick Access or Quick Pick-style overlay.
- [ ] Show workspace cards or rich items with label, path, source badges, session indicators, and policy hints.
- [ ] Add command and keybinding entrypoints for the switcher.
- [ ] Support fast keyboard cycling and confirmation behavior.

### UX polish

- [ ] Add CatastroSwitch-specific CSS only where native theming is insufficient.
- [ ] Implement empty states for missing registry entries or empty recent-workspace history.
- [ ] Ensure the UI remains useful before switching and monitoring are fully complete.

### Tests and validation

- [ ] Add view registration tests where feasible.
- [ ] Add UI or service tests for empty states and filter behavior.
- [ ] Add tests or smoke steps for switcher command availability and keyboard navigation.

Validation checklist:

- [ ] The Activity Bar shows CatastroSwitch.
- [ ] The sidebar renders Overview, Workspaces, and Sessions views.
- [ ] The switcher overlay opens from a command and feels Alt+Tab-like.
- [ ] Refresh and filter actions work against live or mock-backed data.
- [ ] No webview dashboard is required for v1.

Ready to advance when:

- The control-plane shell is useful in read-only mode before same-window switching lands.

## Phase 5 - Same-Window Switch and Return Flow

Status: not started.

Objective:

- Let the user switch the current window to a selected workspace, apply that workspace's extension policy, and switch back later.

Dependencies:

- Phase 3 catalogs available.
- Phase 4 switcher and workspace actions available.

Implementation checklist:

### Switch orchestration

- [ ] Create `catastroswitchSwitchService` with a clear request flow from switcher selection to workspace transition.
- [ ] Resolve the target workspace entry from the workspace catalog.
- [ ] Persist switch-back state before invoking workspace transition.
- [ ] Use existing workspace editing services for same-window switching instead of opening a second window.

### Extension policy application

- [ ] Create `catastroswitchExtensionPolicyService`.
- [ ] Resolve the target profile template and extension policy for the selected workspace.
- [ ] Apply enable or disable decisions through existing extension enablement seams.
- [ ] Detect when the extension delta requires a same-window reload.

### Recovery and switch-back

- [ ] Persist enough application-scoped state to keep `Switch Back` available after reload.
- [ ] Restore switch-back affordances after a successful reload.
- [ ] Handle failure paths so a partial switch does not silently discard return-state information.

### Minimal integration seams

- [ ] Confirm whether `abstractWorkspaceEditingService.ts` needs a small extension for switch tracking.
- [ ] Confirm whether `workspaceEditing.ts` needs a tiny interface addition for prior-workspace metadata.
- [ ] Confirm whether `userDataProfileManagement.ts` needs a small event seam for profile synchronization.
- [ ] Avoid touching extension-host internals unless tests prove a narrow seam is unavoidable.

### Tests and validation

- [ ] Add tests for successful same-window switching.
- [ ] Add tests for switch-back after reload.
- [ ] Add tests for extension-policy application and reload decisions.
- [ ] Add tests for failure recovery when the target workspace is missing or policy application fails.

Validation checklist:

- [ ] The current window switches to the selected workspace without opening a second window in the normal path.
- [ ] The correct extension policy is applied.
- [ ] Significant extension changes trigger a same-window reload, not a new-window switch.
- [ ] `Switch Back` returns to the prior workspace reliably.
- [ ] The implementation remains mostly additive around existing workspace and profile services.

Ready to advance when:

- Same-window switching and switch-back are reliable enough to use daily in the runtime fork.

## Phase 6 - Machine-Local Session Monitoring and Aggregation

Status: not started.

Objective:

- Publish and aggregate machine-local GitHub Copilot session state so the CatastroSwitch UI can monitor local work.

Dependencies:

- Phase 3 session catalog available.
- Phase 4 sessions UI available.

Implementation checklist:

### Snapshot format and storage

- [ ] Finalize the first usable snapshot payload shape against `schemas/agent-session-snapshot.schema.json`.
- [ ] Choose the shared local snapshot directory under user-data or app-data.
- [ ] Add configuration hooks for snapshot location where the workspace registry needs to influence it later.

### Writer and reader services

- [ ] Implement a per-process snapshot writer or heartbeat publisher.
- [ ] Implement a snapshot reader or aggregator service.
- [ ] Add stale-detection logic based on heartbeat timestamps and configured timeouts.
- [ ] Map recent tool activity summaries into the aggregated session model.

### UI wiring and degraded states

- [ ] Surface aggregated session state in the Sessions view.
- [ ] Surface stale and error counts in the Overview view.
- [ ] Handle corrupted snapshot files without breaking the entire monitoring view.
- [ ] Handle missing paths, missing workspaces, or partially populated snapshot fields cleanly.

### Tests and validation

- [ ] Add tests for snapshot read and write behavior.
- [ ] Add tests for stale detection and timeout handling.
- [ ] Add tests for corrupted snapshot recovery.
- [ ] Add tests for recent-tool-summary rendering or mapping behavior.

Validation checklist:

- [ ] Local processes publish snapshots or heartbeats.
- [ ] The Sessions view can show active, waiting, stale, and error states.
- [ ] Dead processes become stale after the configured timeout.
- [ ] Recent tool summaries are visible when available.
- [ ] Broken snapshot files degrade cleanly instead of breaking the whole view.

Ready to advance when:

- Machine-local monitoring is stable enough that the UI reflects real local activity and failure states.

## Phase 7 - Hardening and Rollout

Status: not started.

Objective:

- Prove reliability before feature expansion.

Dependencies:

- Phases 3 through 6 implemented.

Implementation checklist:

### Automated verification

- [ ] Add or finish automated tests for discovery merge and deduplication.
- [ ] Add or finish automated tests for same-window switching.
- [ ] Add or finish automated tests for switch-back reliability after reload.
- [ ] Add or finish automated tests for extension policy application.
- [ ] Add or finish automated tests for stale session detection and snapshot corruption handling.

### Manual verification

- [ ] Write a manual smoke test runbook for same-window switching.
- [ ] Write a manual smoke test runbook for machine-local monitoring.
- [ ] Run a self-host verification pass against the runtime fork.

### Documentation and rollout readiness

- [ ] Update operator runbooks for coding-agent execution against the current workflow.
- [ ] Confirm repo docs, sample contracts, and runtime behavior describe the same product model.
- [ ] Capture known limitations and explicit v2 backlog items rather than letting them drift into v1.

Validation checklist:

- [ ] The repo docs, sample contracts, and runtime code all describe the same product model.
- [ ] The current window can switch and switch back reliably.
- [ ] Machine-local session monitoring is stable enough for daily use.
- [ ] Empty, missing-path, and corrupted-snapshot states degrade cleanly.

Ready to close when:

- The product is usable day to day without requiring fallback workflow hacks.

## Suggested Work Package Order

Recommended execution order for a coding agent:

1. Finish the remaining Phase 2 checkboxes.
2. Build Phase 3 discovery services and tests.
3. Build Phase 4 UI shell wired to the Phase 3 catalogs.
4. Build Phase 5 same-window switching and extension policy.
5. Build Phase 6 monitoring and aggregation.
6. Run Phase 7 hardening, smoke tests, and rollout documentation.

This order gives useful visibility early and keeps switching complexity out of the initial service scaffolding.

## Release Readiness Checklist

- [ ] The control repo contains a durable plan doc and sample contracts that point back to it through `planPath`.
- [ ] The runtime fork contains new CatastroSwitch folders rather than broad edits across unrelated workbench code.
- [ ] The CatastroSwitch sidebar can render even before switching is implemented.
- [ ] Managed and recent workspaces can be listed side by side.
- [ ] Sessions can be listed with source, status, and workspace correlation.
- [ ] Same-window switching uses one window and preserves switch-back.
- [ ] Significant extension changes cause same-window reload rather than new-window opening.
- [ ] Local monitoring shows stale sessions after timeout.
- [ ] Broken snapshot files and missing workspace paths degrade cleanly.

## Coding Agent Notes

When a coding agent runs against this plan, it should follow these constraints:

- prefer additive CatastroSwitch-specific services and views
- avoid refactoring core VS Code systems unless a tiny seam is truly required
- keep workbench UI native; do not start with a webview dashboard
- ship read-only discovery before mutation
- treat same-window reload as acceptable when extension policy demands it
- keep the control repo as the durable source of contracts and planning artifacts

The next implementation task should be finishing the remaining Phase 2 items and then starting Phase 3 service scaffolding.