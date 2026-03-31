---
name: workspace-registry-design
description: Maintains the workspace registry schema, sample catalog, and adapter metadata model used by the fork control repo.
---

# Workspace registry design

This skill governs the data contract behind the fork's workspace catalog and planning metadata.

## Rules

- Keep `schemas/workspace-registry.schema.json` and `examples/workspace-registry.sample.json` synchronized.
- Store desired workspace behavior and adapter boundaries without inventing unsupported runtime delivery.
- Model agent visibility using:
  - `supported`
  - `adapter-required`
  - `blocked`
- Keep `profileAffinity`, `desiredBehaviors`, and `productCapabilities` aligned with the active fork plan.

## When updating the registry

1. Update the schema first.
2. Update the sample registry.
3. Update `docs/architecture.md`, `docs/implementation-plan.md`, and `docs/fork-backlog.md` if semantics changed.
