# Agent Adapter Contract

## Purpose

This document defines the safe integration model for surfacing agent status per workspace in the `CatastroSwitch` fork.

The product must not assume it can inspect all Copilot or third-party sessions directly. Instead, it should use product-owned runtimes or explicit adapters.

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

