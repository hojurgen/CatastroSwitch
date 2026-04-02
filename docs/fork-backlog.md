# Fork Backlog

This backlog is the product backlog for the `CatastroSwitch` VS Code fork.

Cross-cutting rule:

- execute every epic with the additive strategy from `docs/vscode-fork-additive-strategy.md`
- prefer new files, new services, and small integration diffs over copying upstream implementations
- use `docs/implementation-plan.md` for the executable phase-specific task graph

## Epic 1 - Workspace rail

Goal:

- introduce a product-owned workspace rail to the left of the primary sidebar

Primary patch zones:

- `src/vs/workbench/browser/workbench.ts`
- `src/vs/workbench/browser/layout.ts`
- `src/vs/workbench/services/layout/browser/layoutService.ts`
- `src/vs/workbench/browser/contextkeys.ts`
- `src/vs/workbench/common/contextkeys.ts`
- `src/vs/workbench/browser/parts/workspacerail/workspaceRailPart.ts`
- `src/vs/workbench/browser/parts/workspacerail/workspaceRailActions.ts`
- `src/vs/workbench/browser/parts/workspacerail/media/workspaceRailPart.css`

Current F1 status:

- resolved: the rail is a dedicated workbench part (`Parts.WORKSPACERAIL_PART`), not a specialization of the existing sidebar or activity bar
- resolved: shell-level focus, visibility toggles, zen-mode restore behavior, and persisted layout state belong to the layout service seam
- resolved: F1 keeps the rail always available as product-owned shell chrome with placeholder content instead of pretending orchestration is already complete
- remaining: replace placeholder shell content with orchestration-backed workspace switching and summaries in later epics

Done when:

- the rail feels native to the workbench
- workspace switching no longer depends on existing extension view-container limits

Current validation bar for the F1 shell closeout:

- browser-unit coverage for the rail part and rail actions
- compile and shell-regression validation in the runtime fork

## Epic 2 - Workspace orchestration service

Goal:

- create a product-owned service that models active workspace, intended profile, startup behavior, and rail state

Likely location:

- a new service under `src/vs/workbench/services/...`

Responsibilities:

- resolve workspace metadata
- decide what profile behavior should occur on entry
- expose state to the rail UI
- coordinate with chat/session and profile subsystems

Done when:

- the shell has one authoritative workspace-orchestration model

## Epic 3 - Workspace-aware profile orchestration

Goal:

- make workspace entry invoke product-owned profile behavior

Primary patch zones:

- `src/vs/platform/userDataProfile/common/userDataProfile.ts`
- `src/vs/workbench/services/userDataProfile/browser/userDataProfileManagement.ts`
- `src/vs/workbench/services/userDataProfile/browser/userDataProfileInit.ts`
- `src/vs/workbench/services/userDataProfile/browser/startupProfileSelection.ts`
- `src/vs/workbench/services/userDataProfile/common/workspaceProfileSelectionPolicy.ts`
- `src/vs/workbench/services/userDataProfile/browser/userDataProfileImportExportService.ts`

Feedback and recovery surface:

- `src/vs/workbench/browser/parts/workspacerail/workspaceRailPart.ts`

Resource surfaces to align:

- `settingsResource.ts`
- `keybindingsResource.ts`
- `tasksResource.ts`
- `snippetsResource.ts`
- `extensionsResource.ts`
- `globalStateResource.ts`
- `mcpProfileResource.ts`

Done when:

- workspace-to-profile rules are deterministic and reversible
- profile state changes are explicit rather than implicit magic

## Epic 4 - Workspace-specific extension-set behavior

Goal:

- make workspace entry able to drive product-owned extension-set behavior safely

Why this is fork work:

- the product owns behavior that public extension APIs do not expose as a coherent automation surface

Likely touch points:

- profile resources, especially `extensionsResource.ts`
- workbench extension-management services registered from `workbench.common.main.ts`

Risks:

- requiring restart or reload semantics
- user surprise if extension state changes feel hidden
- overlap with existing profile and recommendation behavior

Done when:

- the product clearly explains what will change
- the change is reversible and testable

## Epic 5 - Product-owned agent/session visibility

Goal:

- show trustworthy running agents per workspace for product-owned agent and session surfaces

Primary patch zones:

- `src/vs/workbench/contrib/chat/common/participants`
- `src/vs/workbench/contrib/chat/common/model`
- `src/vs/workbench/contrib/chat/common/tools`
- `src/vs/workbench/contrib/chat/browser/widget`
- `src/vs/workbench/contrib/chat/browser/widgetHosts`
- `src/vs/workbench/contrib/chat/browser/chatSessions`

Rules:

- use product-owned chat and session state where VS Code actually owns the runtime
- keep third-party or external systems on the explicit adapter contract
- do not claim universal introspection unless the product truly owns that session model

Done when:

- the workspace rail can show reliable session summaries for supported agents

## Epic 6 - Control-repo integration

Goal:

- keep the fork and `C:\CatastroSwitch` aligned instead of letting them drift apart

Keep in the control repo:

- `schemas/workspace-registry.schema.json`
- `examples/workspace-registry.sample.json`
- `docs/agent-adapter-contract.md`
- grounded fork docs
- Copilot instructions, agents, and skills

Move into the fork:

- new workbench chrome
- workspace orchestration service
- profile switching and orchestration
- product-owned extension-set behavior
- product-owned agent and session visibility

Done when:

- the control repo remains the design contract
- the fork remains the product implementation

## Cross-cutting engineering rule - Upgrade discipline

Every fork epic should be implemented so that an upstream rebase mostly sees:

- new `CatastroSwitch` files,
- narrow registration changes,
- and small, obvious seams in existing upstream files.

If a solution starts by copying an upstream workbench part or rewriting a large existing class, revisit the design first.

