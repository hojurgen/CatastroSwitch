# VS Code Fork Source Map

This document maps the `CatastroSwitch` product requirements to concrete areas of the upstream VS Code codebase.

It is grounded in:

- VS Code source organization: <https://github.com/microsoft/vscode/wiki/Source-Code-Organization>
- VS Code contribution guide: <https://github.com/microsoft/vscode/wiki/How-to-Contribute>
- TypeScript declaration merging and module augmentation: <https://www.typescriptlang.org/docs/handbook/declaration-merging.html>
- TypeScript mixins: <https://www.typescriptlang.org/docs/handbook/mixins.html>
- VS Code root entrypoints and scripts:
  - <https://github.com/microsoft/vscode/blob/main/src/vs/workbench/workbench.common.main.ts>
  - <https://github.com/microsoft/vscode/blob/main/src/vs/workbench/workbench.desktop.main.ts>
  - <https://github.com/microsoft/vscode/blob/main/package.json>
- VS Code chat organization:
  - <https://github.com/microsoft/vscode/blob/main/src/vs/workbench/contrib/chat/chatCodeOrganization.md>

Use this alongside `docs/vscode-fork-additive-strategy.md` so source mapping and implementation style stay aligned.

## Goal-to-area map

| Product goal | Why it needs a fork | Primary patch zones |
|---|---|---|
| Add a workspace rail left of the primary sidebar | Public extension APIs do not let an extension add a new workbench chrome strip beyond documented containers. | `src/vs/workbench/browser/workbench.ts`, `src/vs/workbench/browser/layout.ts`, `src/vs/workbench/services/layout/browser/layoutService.ts`, `src/vs/workbench/browser/contextkeys.ts`, `src/vs/workbench/common/contextkeys.ts`, `src/vs/workbench/browser/parts/workspacerail/workspaceRailPart.ts`, `src/vs/workbench/browser/parts/workspacerail/workspaceRailActions.ts`, `src/vs/workbench/browser/parts/workspacerail/media/workspaceRailPart.css` |
| Make workspace entry switch product-owned state | Product-owned switching needs tighter control than `vscode.openFolder` plus manual user flows. | `src/vs/workbench/workbench.common.main.ts`, `src/vs/workbench/workbench.desktop.main.ts`, new workbench service under `src/vs/workbench/services/...` |
| Apply workspace-specific profile behavior | Public APIs do not allow extensions to switch profiles programmatically. | `src/vs/platform/userDataProfile/common/userDataProfile.ts`, `src/vs/workbench/services/userDataProfile/browser/userDataProfileManagement.ts`, `src/vs/workbench/services/userDataProfile/browser/userDataProfileInit.ts` |
| Carry workspace-specific settings/extensions/tasks/snippets state | These resources are already modeled by the profile subsystem and should be extended there, not reimplemented ad hoc. | `src/vs/workbench/services/userDataProfile/browser/settingsResource.ts`, `src/vs/workbench/services/userDataProfile/browser/keybindingsResource.ts`, `src/vs/workbench/services/userDataProfile/browser/tasksResource.ts`, `src/vs/workbench/services/userDataProfile/browser/snippetsResource.ts`, `src/vs/workbench/services/userDataProfile/browser/extensionsResource.ts`, `src/vs/workbench/services/userDataProfile/browser/globalStateResource.ts`, `src/vs/workbench/services/userDataProfile/browser/mcpProfileResource.ts` |
| Show product-owned running agents per workspace | Reliable agent/session visibility belongs in product-owned chat/session services, not in unsupported extension introspection. | `src/vs/workbench/contrib/chat/browser/chat.contribution.ts`, `src/vs/workbench/contrib/chat/browser/chatSessions/chatSessions.contribution.ts`, `src/vs/workbench/contrib/chat/browser/widgetHosts/viewPane/chatViewPane.ts`, `src/vs/workbench/contrib/chat/browser/widget`, `src/vs/workbench/contrib/chat/browser/widgetHosts`, `src/vs/workbench/contrib/chat/common/chatService/chatService.ts`, `src/vs/workbench/contrib/chat/common/model/chatModel.ts`, `src/vs/workbench/contrib/chat/common/participants`, `src/vs/workbench/contrib/chat/common/tools` |

## Upgrade-friendly implementation style

For every patch zone in this document:

- prefer new files over rewriting existing ones
- prefer registration hooks over deep method rewrites
- prefer delegation over copied upstream classes
- use TypeScript augmentation only as a type-level seam tool when needed

That is the difference between a fork that rebases cleanly and a fork that becomes a permanent merge conflict.

## Workbench shell and layout

The F1 runtime seam is now concrete rather than hypothetical. These are the primary files for the implemented shell-only rail:

- `src/vs/workbench/browser/workbench.ts`
  - owns workbench part creation and now hosts the rail container between the Activity Bar and primary Sidebar
- `src/vs/workbench/browser/layout.ts`
  - primary layout orchestration and part placement logic
  - owns the rail slot, persistence rules, resize math, visibility toggles, and focus behavior
- `src/vs/workbench/services/layout/browser/layoutService.ts`
  - defines `Parts.WORKSPACERAIL_PART` so the rail participates in layout contracts cleanly
- `src/vs/workbench/browser/contextkeys.ts`
- `src/vs/workbench/common/contextkeys.ts`
  - bind and expose the rail visibility and focus contexts used by layout commands and menus
- `src/vs/workbench/browser/parts/workspacerail/workspaceRailPart.ts`
  - owns the fixed-width rail shell and the current placeholder workspace chrome used in F1
- `src/vs/workbench/browser/parts/workspacerail/workspaceRailActions.ts`
  - registers the rail toggle, hide, and focus actions against the layout service seam
- `src/vs/workbench/browser/parts/workspacerail/media/workspaceRailPart.css`
  - keeps the rail shell visually bounded so it behaves like intentional workbench chrome instead of ad hoc content
- `src/vs/workbench/workbench.common.main.ts`
  - central workbench composition for common/browser-side contributions and services
  - remains the shared registration seam for later orchestration services, not for the F1 shell-only rail
- `src/vs/workbench/workbench.desktop.main.ts`
  - desktop-specific composition and services
  - remains relevant only when later phases need desktop-specific workspace behavior beyond the current common shell seam

Regression coverage for the F1 rail shell should live with browser workbench tests, currently under:

- `src/vs/workbench/test/browser/parts/workspacerail/workspaceRailPart.test.ts`
- `src/vs/workbench/test/browser/parts/workspacerail/workspaceRailActions.test.ts`

## Profiles and workspace-owned state

The product behavior you want should be layered on the existing profile system rather than replacing it.

Start here:

- `src/vs/platform/userDataProfile/common/userDataProfile.ts`
  - profile model and low-level profile concepts
- `src/vs/workbench/services/userDataProfile/browser/userDataProfileManagement.ts`
  - browser/workbench-facing profile management flows
- `src/vs/workbench/services/userDataProfile/browser/userDataProfileInit.ts`
  - profile initialization path
- `src/vs/workbench/services/userDataProfile/browser/userDataProfileImportExportService.ts`
  - useful if workspace bundles need import/export semantics

Resource-specific profile surfaces already exist:

- `src/vs/workbench/services/userDataProfile/browser/settingsResource.ts`
- `src/vs/workbench/services/userDataProfile/browser/keybindingsResource.ts`
- `src/vs/workbench/services/userDataProfile/browser/tasksResource.ts`
- `src/vs/workbench/services/userDataProfile/browser/snippetsResource.ts`
- `src/vs/workbench/services/userDataProfile/browser/extensionsResource.ts`
- `src/vs/workbench/services/userDataProfile/browser/globalStateResource.ts`
- `src/vs/workbench/services/userDataProfile/browser/mcpProfileResource.ts`

That resource split is a good sign: the fork should extend profile orchestration, not bolt on a second competing workspace-state system.

## Chat and agent visibility

The upstream chat contrib now documents its own internal organization.

According to `chatCodeOrganization.md`, useful starting points are:

- `src/vs/workbench/contrib/chat/browser/chat.contribution.ts`
- `src/vs/workbench/contrib/chat/browser/chatSessions/chatSessions.contribution.ts`
- `src/vs/workbench/contrib/chat/browser/widgetHosts/viewPane/chatViewPane.ts`
- `src/vs/workbench/contrib/chat/browser/widget`
- `src/vs/workbench/contrib/chat/browser/widgetHosts`
- `src/vs/workbench/contrib/chat/common/chatService/chatService.ts`
- `src/vs/workbench/contrib/chat/common/model/chatModel.ts`
- `src/vs/workbench/contrib/chat/common/participants`
- `src/vs/workbench/contrib/chat/common/tools`

For `CatastroSwitch`, this suggests a clean separation:

- product-owned agent/session visibility should come from chat/session services inside the fork
- third-party or external agents should still use the explicit adapter model from `docs/agent-adapter-contract.md`

## Suggested cut line

Keep these concerns in `C:\CatastroSwitch`:

- registry schema and sample data
- extension-side UX experiments
- adapter contracts for external agent systems
- docs that explain capability boundaries

Move these concerns into the VS Code fork:

- new left-of-sidebar chrome
- workspace-to-profile orchestration
- workspace-driven extension-set behavior
- product-owned agent/session summaries
- any workbench persistence or focus behavior tied to the new rail

## First patch sequence

1. Introduce `Parts.WORKSPACERAIL_PART` and insert a dedicated rail container between the Activity Bar and the primary Sidebar.
2. Wire rail visibility, focus, and persisted shell state through `layout.ts`, `layoutService.ts`, and the workspace-rail context keys.
3. Keep the initial rail UI limited to a fixed-width placeholder shell in `workspaceRailPart.ts` plus narrow layout actions in `workspaceRailActions.ts`.
4. Add orchestration, profiles, extension-set behavior, and agent summaries only in later phases after the shell seam is stable.
5. Keep schema, adapter, and contributor-workflow artifacts in the control repo rather than drifting runtime behavior back into this repository.

