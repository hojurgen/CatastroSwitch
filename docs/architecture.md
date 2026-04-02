# Architecture

## Goal

Build a forked VS Code product that adds:

- a workspace rail to the left of the primary sidebar
- workspace-aware orchestration
- product-owned profile behavior
- workspace-specific extension-set behavior
- product-owned agent/session visibility

This repository is not the runtime product itself.

It is the control repo for:

- architecture and grounding docs
- workspace registry schema and example data
- adapter contracts
- Copilot guidance
- fork planning and upgrade discipline

The actual product runtime should live in a separate VS Code fork checkout such as `C:\src\vscode-multiagent`.

## High-level shape

```text
┌──────────────────────────────────────────────────────────────┐
│ C:\CatastroSwitch                                           │
│  ├─ docs, backlog, grounding, source map                    │
│  ├─ schemas + examples                                      │
│  ├─ adapter contract                                        │
│  └─ Copilot instructions / agents / skills                  │
└──────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│ C:\src\vscode-multiagent                                    │
│  VS Code fork runtime                                       │
│  ├─ Workspace rail part                                     │
│  ├─ Workspace orchestration service                         │
│  ├─ Profile orchestration hooks                             │
│  ├─ Extension-set behavior                                  │
│  └─ Agent/session summary surfaces                          │
└──────────────────────────────────────────────────────────────┘
```

## GitHub topology

The same split should exist remotely, not just on disk:

- `github.com/<owner>/vscode` is the runtime fork. It carries the actual product implementation and rebases from `microsoft/vscode`.
- `github.com/<owner>/CatastroSwitch` or `github.com/<owner>/catastroswitch-control` is the control repo. It carries docs, schemas, contracts, workflow state helpers, and contributor guidance.

This is not a two-repo mirror of the same code. Runtime patches land in the fork. Control-repo changes land in the control repo. Cross-cutting work may require one pull request in each repository.

## Product runtime architecture

The fork should be structured additively around a few product-owned components.

### 1. Workspace rail part

Primary responsibility:

- render the product-owned workspace rail shell to the left of the primary sidebar
- own shell-level visibility, focus, and layout persistence behavior for that rail
- host placeholder workspace chrome in F1 while orchestration-driven switching and summaries stay deferred to later phases

Current F1 patch zones:

- `src/vs/workbench/browser/workbench.ts`
- `src/vs/workbench/browser/layout.ts`
- `src/vs/workbench/services/layout/browser/layoutService.ts`
- `src/vs/workbench/browser/contextkeys.ts`
- `src/vs/workbench/common/contextkeys.ts`
- `src/vs/workbench/browser/parts/workspacerail/workspaceRailPart.ts`
- `src/vs/workbench/browser/parts/workspacerail/workspaceRailActions.ts`

Follow-on phases can add orchestration-backed content and richer workspace switching without changing the control-repo boundary: the rail shell itself stays in the runtime fork, while the contract docs and sample metadata stay here.

### 2. Workspace orchestration service

Primary responsibility:

- track active workspace context
- resolve workspace metadata and intended behavior
- coordinate rail state, profile behavior, extension-set policy, and session summaries

Likely location:

- new service under `src/vs/workbench/services/...`

### 3. Profile orchestration layer

Primary responsibility:

- extend the existing profile system with workspace-aware rules
- reuse existing settings, tasks, snippets, extension, and global-state resource handling

Likely patch zones:

- `src/vs/platform/userDataProfile/common/userDataProfile.ts`
- `src/vs/workbench/services/userDataProfile/browser/...`

### 4. Agent/session summary service

Primary responsibility:

- summarize product-owned agent/session state per workspace
- integrate safely with external adapters when the runtime is not product-owned

Likely patch zones:

- `src/vs/workbench/contrib/chat/common/...`
- `src/vs/workbench/contrib/chat/browser/...`

## Role of this repo

`C:\CatastroSwitch` should continue to own the durable artifacts that are useful across fork iterations:

- grounded architecture decisions
- additive patch strategy
- source map for patch areas
- fork backlog and execution plan
- workspace registry schema and example data
- adapter contract for external systems
- Copilot instructions for contributors and agents

## Workspace registry and adapter artifacts

The following control-repo files define desired behavior without pretending to be runtime code:

- `schemas\workspace-registry.schema.json`
- `examples\workspace-registry.sample.json`
- `docs\agent-adapter-contract.md`

They describe workspace identity, profile affinity, desired behaviors, adapter metadata, and product capability planning.

## Upgrade discipline

The fork should follow the additive strategy from `docs\vscode-fork-additive-strategy.md`:

- new files before rewrites
- new services before scattered logic
- narrow registration hooks before deep edits
- delegation before copied upstream classes

That rule is as important as the component breakdown itself.

