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
| Add a workspace rail left of the primary sidebar | Public extension APIs do not let an extension add a new workbench chrome strip beyond documented containers. | `src/vs/workbench/browser/workbench.ts`, `src/vs/workbench/browser/layout.ts`, `src/vs/workbench/services/layout/browser/layoutService.ts`, `src/vs/workbench/browser/parts/sidebar/sidebarPart.ts`, `src/vs/workbench/browser/parts/activitybar/activitybarPart.ts`, `src/vs/workbench/browser/parts/compositeBar.ts`, `src/vs/workbench/browser/parts/paneCompositeBar.ts`, `src/vs/workbench/browser/workbench.contribution.ts` |
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

These are the first files to understand before adding a new product-owned rail:

- `src/vs/workbench/browser/workbench.ts`
  - owns workbench part creation and is the first concrete seam for introducing a new rail part instance
- `src/vs/workbench/browser/layout.ts`
  - primary layout orchestration and part placement logic
  - likely home for a new part identifier, layout slot, persistence rules, and resize/focus behavior
- `src/vs/workbench/services/layout/browser/layoutService.ts`
  - defines layout service seams, part identifiers, and layout-facing contracts that a new rail needs to participate in cleanly
- `src/vs/workbench/browser/parts/sidebar/sidebarPart.ts`
  - current primary sidebar behavior
  - important because your requested rail lives immediately adjacent to this surface
- `src/vs/workbench/browser/parts/activitybar/activitybarPart.ts`
  - existing narrow icon rail behavior
  - useful reference if the new workspace rail should feel like a sibling chrome element
- `src/vs/workbench/browser/parts/compositeBar.ts`
- `src/vs/workbench/browser/parts/paneCompositeBar.ts`
  - likely reference points for icon-strip behavior, pinning, sizing, ordering, and drag/drop
- `src/vs/workbench/browser/workbench.contribution.ts`
  - useful when the workspace rail needs configuration, commands, or workbench-level contribution wiring
- `src/vs/workbench/workbench.common.main.ts`
  - central workbench composition for common/browser-side contributions and services
  - primary shared registration seam for new services and product wiring
- `src/vs/workbench/workbench.desktop.main.ts`
  - desktop-specific composition and services
  - useful when the workspace rail needs native desktop-only behavior beyond the common registration seam

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

1. Add a source-level design note for the new workspace rail and decide whether it is:
   - a sibling of the Activity Bar, or
   - a sibling of the Sidebar.
2. Introduce a workbench service for active workspace orchestration.
3. Add profile-selection rules that consume workspace metadata.
4. Expose product-owned agent/session summaries into the new rail.
5. Reuse the existing extension harness only for adapter-driven and schema-driven concerns.

