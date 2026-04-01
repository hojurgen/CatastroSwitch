# Fork tooling policies

This folder keeps the canonical TypeScript and ESLint policy overlays for the real `CatastroSwitch` VS Code fork.

These files are not active in `C:\CatastroSwitch` itself because this control repo is not a Node or TypeScript package. They live here so the fork has a grounded, reviewable source of truth instead of ad hoc lint and compiler drift.

## Source alignment

The policy files here are intentionally aligned with:

- `microsoft/TypeScript` coding guidelines
- `microsoft/vscode` coding guidelines
- Azure SDK TypeScript design guidance
- Microsoft Learn guidance for JavaScript and TypeScript Azure client usage

See `..\..\docs\grounding.md` for the exact source links.

## Files

- `tsconfig.catastroswitch.strict.json` - compiler strictness overlay for CatastroSwitch-owned fork code
- `eslint.catastroswitch.config.mjs` - type-aware ESLint overlay for CatastroSwitch-owned fork code
- `branding-assets.manifest.json` - machine-readable map from control-repo branding sources to runtime fork icon outputs

## How to adopt in the real fork

1. Extend the relevant fork `tsconfig*.json` files from `tsconfig.catastroswitch.strict.json`, or copy the `compilerOptions` into the fork's existing layered `tsconfig` setup if direct `extends` is awkward.
2. Import `eslint.catastroswitch.config.mjs` into the fork's ESLint entrypoint and start by applying it only to CatastroSwitch-owned files and intentionally patched upstream files.
3. When branding assets change, run `scripts\export-fork-branding-assets.ps1 -CompileFork` from the control repo against the fork root so every generated runtime icon and the compiled in-app workbench icon stay consistent with `assets\logo.svg` and the manifest.
4. Reuse upstream VS Code dependencies where possible. The upstream repo already ships `eslint` and `typescript-eslint`, so this is meant to be an overlay, not a replacement lint stack.
5. After wiring the overlay into the real fork, run `npm run eslint`, `npm run compile`, and the smallest relevant self-host loop before merging.

## Review rules that still need human judgment

- Externalize user-visible strings.
- Prefer top-level `export function` over `export const` when better stack traces matter.
- Keep option bag, abort signal, and duration naming consistent on shared service APIs.
