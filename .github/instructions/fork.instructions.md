---
applyTo: "docs/vscode-fork-*.md,docs/fork-backlog.md,docs/implementation-plan.md,docs/agent-adapter-contract.md,fork/**/*.md"
---

- Ground fork claims in official VS Code repo docs, source organization docs, or concrete source paths.
- Read `docs/architecture.md`, `docs/implementation-plan.md`, `docs/vscode-fork-source-map.md`, and `docs/agent-adapter-contract.md` before large fork guidance changes.
- Prefer naming real `src/vs/...` files over vague references to "the VS Code internals".
- Treat the control repo and the runtime fork as separate GitHub repositories with different jobs.
- Keep phase branches and `.catastroswitch\phase-state\` artifacts in the real fork clone; keep docs, schemas, contracts, and agent guidance in the control repo.
- Keep control-repo artifacts and fork-runtime patches clearly separated.
- Do not pretend unsupported public APIs or universal session introspection exist.
- Prefer additive patches: new files, new services, narrow entrypoint hooks, and delegation over wholesale rewrites.
- Use TypeScript augmentation only to clarify types around a real runtime seam.
