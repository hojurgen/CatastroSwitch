# VS Code Fork Additive Strategy

This document explains how to extend a VS Code fork in an upgrade-friendly way.

The goal is simple:

- add the `CatastroSwitch` product behavior,
- avoid copying large upstream files,
- and keep rebases against `microsoft/vscode` as small and mechanical as possible.

Grounding:

- TypeScript declaration merging and module augmentation: <https://www.typescriptlang.org/docs/handbook/declaration-merging.html>
- TypeScript mixins: <https://www.typescriptlang.org/docs/handbook/mixins.html>
- VS Code source organization: <https://github.com/microsoft/vscode/wiki/Source-Code-Organization>
- VS Code contribution guide: <https://github.com/microsoft/vscode/wiki/How-to-Contribute>

## Short answer

Yes, TypeScript has additive mechanisms, but they are not all equally useful for a VS Code fork.

### Additive at the type level

TypeScript supports:

- interface merging
- namespace merging
- module augmentation

These are useful when you want to extend the compiler's view of an existing API without replacing the original declaration.

### Additive at the runtime level

For runtime behavior, the safer patterns are usually:

- new services
- new workbench parts
- wrapper/delegating classes
- mixin-style composition
- small registration hooks in existing entrypoints

That is the main strategy for `CatastroSwitch`.

## What TypeScript can and cannot do

### Declaration merging

The TypeScript handbook describes declaration merging as combining multiple declarations with the same name into a single definition.

That is useful for:

- extending interfaces
- refining overloads
- augmenting named exports with additional type members

But it does **not** mean you can safely "merge two classes together" at runtime.

### Module augmentation

The handbook also documents module augmentation:

- you can augment existing named exports
- the declarations are merged as if they were in the original module
- you cannot add new top-level declarations through augmentation
- default exports cannot be augmented

This is valuable when you need the compiler to understand an extension seam around an existing module.

For a VS Code fork, that means module augmentation is a **type-shaping tool**, not the primary implementation strategy.

### Mixins

The TypeScript mixins guide shows how to build runtime behavior by composing classes instead of relying only on inheritance.

That matters because the upgrade-friendly question is mostly a runtime/design question, not a syntax question.

If you want minimal upstream diffs, prefer composition and narrow extension points over "replace this whole upstream class with ours".

## Recommended `CatastroSwitch` strategy

Use the following order of preference.

### 1. Add new files first

Prefer creating new files such as:

- `WorkspaceRailPart`
- `WorkspaceContextService`
- `WorkspaceProfileOrchestrator`
- `WorkspaceAgentSummaryService`

Then integrate them with small changes to existing upstream files.

This keeps the fork diff readable and makes rebases much easier.

### 2. Patch registries and entrypoints, not whole implementations

Prefer small changes in places like:

- `workbench.common.main.ts`
- `workbench.desktop.main.ts`
- `layout.ts`
- service registration files
- action/contribution registration files

These are better integration points than editing large swaths of existing behavior-heavy classes.

### 3. Prefer delegation over copying

If an existing part already does 80 percent of what you need:

- wrap it,
- host it,
- or delegate to it.

Do **not** start by copying an upstream file like `sidebarPart.ts` into a fork-specific version unless there is no viable seam.

Copied files become merge magnets.

### 4. Use module augmentation only when it clarifies a seam

Good use:

- extending a named exported interface with optional metadata used by a new `CatastroSwitch` service
- telling the compiler about an intentionally added method on an existing internal type

Bad use:

- treating module augmentation as a substitute for a real architecture
- patching prototypes broadly just because TypeScript can describe it

### 5. Keep fork-owned behavior in fork-owned services

For `CatastroSwitch`, the safest additive model is:

- new rail UI: own new part
- workspace switching/orchestration: own new service
- profile application rules: extend profile orchestration via focused hooks
- agent/session summaries: own new product service that reads existing chat/session state

This is much more upgrade-friendly than scattering custom logic across many upstream methods.

### 6. Make upstream touchpoints obvious

When you must edit an upstream file:

- keep the diff narrow
- place the integration near a natural registration seam
- avoid unrelated cleanup in the same change
- add a brief comment only if the seam would otherwise be hard to understand

The goal is for a future rebase to answer:

- what did `CatastroSwitch` add?
- where does it hook in?
- can the hook move cleanly if upstream reorganizes?

## Concrete examples for this fork

### Workspace rail

Prefer:

- create a new workbench part for the workspace rail
- register/layout it from `src/vs/workbench/browser/layout.ts`
- integrate with the existing sidebar/activity bar with the smallest possible diff

Avoid:

- rewriting `ActivitybarPart` or `SidebarPart` wholesale

### Workspace orchestration

Prefer:

- a new service under `src/vs/workbench/services/...`
- minimal registration in `workbench.common.main.ts` or `workbench.desktop.main.ts`

Avoid:

- embedding orchestration logic into unrelated UI classes

### Profile behavior

Prefer:

- extend the existing profile management flow with a small orchestration layer
- reuse the existing resource-specific profile files

Avoid:

- inventing a second workspace state model that duplicates settings/tasks/extensions/snippets handling

### Agent visibility

Prefer:

- a product-owned service that summarizes session state from existing chat/session models
- explicit adapters for anything external or third-party

Avoid:

- monkey-patching broad chat internals unless there is no service seam
- claiming universal introspection

## Patterns to avoid

- copying entire upstream files into fork-specific twins
- replacing stable upstream abstractions with custom one-off abstractions
- prototype patching as the default strategy
- invasive edits across many files when one new service plus one registration hook would do
- mixing feature work and large refactors in the same fork patch

## Upgrade checklist

Before merging a fork change, ask:

1. Did we add a new file instead of editing an upstream file wherever possible?
2. Are the upstream edits limited to registration, wiring, or narrow seam changes?
3. Did we avoid copying an upstream class?
4. If we used module augmentation, is it only clarifying types around a real seam?
5. Would an upstream rebase show a small, understandable diff?

If the answer to several of these is "no", the design is probably too invasive.

