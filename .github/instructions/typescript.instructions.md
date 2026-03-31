---
name: TypeScript quality rules
description: Quality bar for future TypeScript changes in the control repo or fork planning track.
applyTo: "**/*.ts,**/*.tsx,**/*.cts,**/*.mts"
---
# TypeScript quality rules

- Prefer existing repo or VS Code patterns before introducing new abstractions.
- Keep changes additive and upgrade-friendly: new services, adapters, registries, and narrow hooks over broad rewrites.
- Prefer strict types, narrow interfaces, and explicit contracts over `any`, `as any`, or `as unknown as`.
- Use module augmentation only when it clarifies a real seam; it does not replace runtime architecture.
- Surface errors explicitly; do not hide failures behind broad `try/catch` blocks or silent fallbacks.
- Keep validation close to the touched surface and update adjacent docs or schema contracts in the same change.
