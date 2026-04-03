# Agent Adapter Contract

## Purpose

This document defines the safe integration model for surfacing agent status per workspace in the `CatastroSwitch` fork.

The product must not assume it can inspect all Copilot or third-party sessions directly. Instead, it should use product-owned runtimes or explicit adapters.

For F3, the runtime boundary is concrete:

- `src/vs/workbench/contrib/chat/browser/productSessionSummaryService.ts` only counts product-owned sessions in the `IProductSessionSummary.sessions` list.
- `src/vs/workbench/browser/parts/workspacerail/workspaceRailPart.ts` renders explicit `adapter-required` and `blocked` boundary states when non-owned session types exist.
- `src/vs/workbench/services/workspaces/common/productSessionSummaryService.ts` carries the shared summary contract, including the boundary metadata that keeps owned counts separate from excluded visibility.

That means the rail must never imply that the visible product-owned summary is a universal inventory of every agent session the editor can host.

## Current F3 boundary

The current runtime contract is intentionally narrow.

- Product-owned: local chat sessions that `CatastroSwitch` owns end-to-end inside the fork runtime.
- Adapter-required: delegated runtimes such as `copilotcli`, `copilot-cloud-agent`, `claude-code`, `openai-codex`, `copilot-growth`, `agent-host-*`, and `remote-*`. These may exist in the workbench, but they are excluded from the product-owned summary until an explicit adapter contract exists.
- Blocked: arbitrary contributed or undocumented session types with no approved adapter contract.

This split is grounded in the current fork patch zones rather than in hypothetical future adapters. If the runtime only knows that a non-owned provider exists, it must surface the boundary and exclude that provider from the product-owned count.

## Current F3 validation posture

The current F3 boundary is backed primarily by focused browser tests rather than by recorded self-host evidence.

- `src/vs/workbench/services/workspaces/test/browser/productSessionSummaryService.test.ts` covers product-owned, adapter-required, and blocked summary classification.
- `src/vs/workbench/test/browser/parts/workspacerail/workspaceRailPart.test.ts` covers the `adapter-required` and `blocked` rail slots, including summary-driven rerender behavior.
- `src/vs/workbench/test/browser/parts/workspacerail/workspaceRailActions.test.ts` covers the explicit `workbench.action.applyWorkspaceExtensionSet` command dispatch.
- `src/vs/workbench/services/workspaces/test/browser/workspaceExtensionSetApplyService.test.ts` covers confirm, apply, unsupported-only, and recovery behavior for the extension-set apply lane.

No non-interactive self-host or manual evidence is currently recorded on the integrated F3 phase branch for invoking `workbench.action.applyWorkspaceExtensionSet` or for live workspace-rail smoke on the new boundary slots. Treat that as an explicit residual validation gap for Reviewer and Gatekeeper, not as implied proof that those product surfaces were manually verified.

## Adapter categories

### 1. Product-owned runtimes

`CatastroSwitch` owns the runtime, lifecycle, and state.

Examples:

- workspace orchestration jobs created by the fork
- product-owned background workers
- fork-owned chat or session surfaces

These are fully supported.

### 2. Peer adapters

A peer extension or local tool exposes a documented surface that `CatastroSwitch` can call.

Possible surfaces:

- VS Code command
- exported extension API
- workspace file
- local IPC or HTTP endpoint
- MCP-backed integration

These are supported only when the peer opts in.

### 3. External service adapters

The product talks to an explicit backend or local companion process that owns the agent inventory.

These are supported when:

- users configure them explicitly,
- the data contract is stable,
- and failure states are surfaced clearly.

### 4. Unsupported introspection

Anything that depends on undocumented access to:

- arbitrary Copilot internals
- arbitrary peer extension runtime state
- private profile storage
- non-public session registries

is out of scope for the product and should not be represented as a supported capability.

## Suggested TypeScript contract

```ts
export interface ProductSessionVisibilityBoundary {
  adapterRequiredCount: number;
  blockedCount: number;
  adapterRequiredProviders: readonly string[];
  blockedProviders: readonly string[];
}

export interface IProductSessionSummary {
  workspaceId: string;
  workspaceName: string;
  status: 'empty' | 'completed' | 'failed' | 'in-progress' | 'needs-input';
  emptyReason?: 'empty-window' | 'no-owned-sessions';
  totalSessions: number;
  sessions: readonly ProductSessionSummaryEntry[];
  visibilityBoundary: ProductSessionVisibilityBoundary;
}

export interface ProductSessionSummaryEntry {
  title: string;
  providerId: string;
  providerLabel: string;
  location: string;
  status: 'completed' | 'failed' | 'in-progress' | 'needs-input';
  requestCount: number;
}

export interface AgentStatusAdapter {
  id: string;
  label: string;
  kind: 'owned' | 'peer' | 'external';

  canListWorkspaces(): Promise<boolean>;
  listWorkspaceStatuses(): Promise<WorkspaceAgentStatus[]>;
}

export interface WorkspaceAgentStatus {
  workspaceId: string;
  summary: string;
  health: 'ok' | 'warning' | 'error' | 'unknown';
  details?: string;
}
```

## UX rules

- If no adapter exists, show `adapter-required`.
- If the capability is impossible with the current product boundary, show `blocked`.
- Keep adapter-required and blocked counts out of the product-owned session total.
- Do not silently omit unsupported data and imply completeness.
- Keep product-owned state visually distinct from adapter state.

## Failure handling

When an adapter fails:

- render the last known summary only if it is clearly marked stale, or
- render an explicit adapter error state.

Do not hide adapter failures.

## Privacy and trust

Agent state can include sensitive project metadata. Adapters should be:

- explicit
- least-privilege
- documented
- removable

## Recommended rollout

1. Start with product-owned runtime state.
2. Add peer adapters only with a documented contract.
3. Add external service adapters only behind explicit configuration.
4. Keep universal introspection out of scope.

