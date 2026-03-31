# VS Code Fork Build Runbook

This runbook is for creating and operating a local VS Code fork that can absorb the `CatastroSwitch` product changes.

Grounding:

- VS Code contribution guide: <https://github.com/microsoft/vscode/wiki/How-to-Contribute>
- VS Code source organization: <https://github.com/microsoft/vscode/wiki/Source-Code-Organization>
- VS Code coding guidelines: <https://github.com/microsoft/vscode/wiki/Coding-Guidelines>
- VS Code root `package.json`: <https://github.com/microsoft/vscode/blob/main/package.json>
- VS Code Windows self-host launcher: <https://github.com/microsoft/vscode/blob/main/scripts/code.bat>
- VS Code scripts directory: <https://github.com/microsoft/vscode/tree/main/scripts>
- TypeScript contributor guidelines: <https://github.com/microsoft/TypeScript/wiki/Coding-guidelines>
- Azure SDK TypeScript design guidelines: <https://azure.github.io/azure-sdk/typescript_design.html>
- Microsoft Learn Azure JavaScript and TypeScript client guidance: <https://learn.microsoft.com/en-us/azure/developer/javascript/sdk/use-azure-sdk>

## Recommended local layout

Do not put the VS Code clone inside `C:\CatastroSwitch`.

Use a separate path without spaces:

```text
C:\CatastroSwitch
C:\src\vscode-multiagent
```

The upstream contribution guide explicitly warns against clone paths that contain spaces.

## Windows prerequisites

Before cloning:

- Git
- Node.js 22.x or newer, matching the current upstream guide and dependency set
- Python for native module builds via `node-gyp`
- Visual Studio Build Tools or Visual Studio with the C/C++ toolchain and Windows SDK

Because VS Code uses native dependencies, Windows build toolchain setup is not optional.

## Fork and clone flow

1. Create your GitHub fork of `microsoft/vscode`.
2. Clone your fork into a no-space path.
3. Add upstream so rebases stay simple.
4. Harden the local clone so `upstream` is fetch-only and plain `git push` goes to your fork.

Example:

```powershell
git clone https://github.com/<your-org-or-user>/vscode.git C:\src\vscode-multiagent
Set-Location C:\src\vscode-multiagent
git remote add upstream https://github.com/microsoft/vscode.git
git remote set-url --push upstream no_push
git config --local remote.pushDefault origin
git config --local push.default simple
git remote -v
```

This keeps rebases from `microsoft/vscode` available while making an accidental `git push upstream` fail locally.

## GitHub repository roles

Use two GitHub repositories with different responsibilities:

- `github.com/<owner>/vscode` is the runtime fork. This is the repository that rebases from `microsoft/vscode` and carries the actual product code changes.
- `github.com/<owner>/CatastroSwitch` or `github.com/<owner>/catastroswitch-control` is the control repo. This is where docs, schemas, contracts, workflow scripts, and agent guidance live.

Only the runtime fork rebases from `microsoft/vscode`. Do not treat the control repo as a patch overlay that gets merged wholesale into the fork.

## First bootstrap

From the fork root:

```powershell
npm install
```

Why `npm install`:

- the official root `package.json` defines the real build/watch scripts
- the repository uses preinstall/postinstall hooks and native dependencies

Useful scripts from the official `package.json`:

- `npm run compile`
- `npm run watch`
- `npm run watch-web`
- `npm run electron`
- `npm run eslint`

## CatastroSwitch TypeScript policy overlay

The control repo keeps canonical fork policy overlays under:

```text
C:\CatastroSwitch\fork\tooling
```

Start with:

- `fork\tooling\tsconfig.catastroswitch.strict.json`
- `fork\tooling\eslint.catastroswitch.config.mjs`

Use them as overlays on top of the real fork's existing TypeScript and ESLint setup instead of replacing the upstream stack wholesale.

Recommended adoption order:

1. Extend the relevant fork `tsconfig*.json` files with the strict overlay options.
2. Import the ESLint overlay into the fork's ESLint entrypoint.
3. Scope the strict lint rules to CatastroSwitch-owned files first, then opt specific upstream patch files in intentionally.
4. Run `npm run eslint` before the usual compile/watch/self-host loop.

## Self-host workflow on Windows

### One-off compile

Use this when you want a clean build before first launch:

```powershell
npm run compile
```

### Iterative development

Terminal 1:

```powershell
npm run watch
```

Terminal 2:

```powershell
scripts\code.bat
```

The official `scripts\code.bat` launcher:

- runs `build/lib/preLaunch.ts` unless `VSCODE_SKIP_PRELAUNCH` is set
- resolves the product executable under `.build\electron\`
- launches the development build in self-host mode

If repeated restarts become slow and prelaunch is already satisfied, you can opt into faster relaunches:

```powershell
$env:VSCODE_SKIP_PRELAUNCH = "1"
scripts\code.bat
```

## Optional alternate launchers

The upstream scripts directory also contains dedicated launchers for other modes, including:

- `scripts\code-web.bat`
- `scripts\code-server.bat`

For `CatastroSwitch`, start with the desktop app first because the requested UI changes are desktop workbench changes.

## Suggested branch strategy

Use a branch structure that isolates upstream sync from phase execution:

- `main` or `upstream-main-sync` for a clean mirror/rebase branch
- one active phase branch per selected phase, for example:
  - `multiagent/f0-baseline-bootstrap`
  - `multiagent/f1-workspace-rail`
  - `multiagent/f2-workspace-orchestration`
  - `multiagent/f3-extension-session`
  - `multiagent/f4-hardening-sync`
- short-lived sibling task branches or worktrees named from the current phase branch only when the Planner marks a task as parallel-safe, for example `multiagent/f2-workspace-orchestration-t3-profile-policy`

Typical refresh flow for a phase branch:

```powershell
git fetch upstream
git checkout upstream-main-sync
git rebase upstream/main
git checkout multiagent/f1-workspace-rail
git rebase upstream-main-sync
```

If the phase branch does not exist yet, create it from `C:\CatastoSwitch` with `scripts\new-phase-branch.ps1`.

## Cross-repo build and pull-request flow

Typical day-to-day flow:

1. Start in `C:\CatastroSwitch` to review the current phase plan, source map, contracts, and workflow rules.
2. Move to the fork checkout at `C:\src\vscode-multiagent` for all runtime code changes.
3. Sync the fork from `microsoft/vscode` by updating the clean sync branch, then rebase the active phase branch.
4. Build and run from the fork checkout:
  - `npm install` when dependencies change or the baseline needs to be refreshed
  - `npm run compile` for a clean build
  - `npm run watch` during iterative development
  - `scripts\code.bat` to self-host the desktop product
5. Update the control repo only when the runtime work changed the documented workflow, patch inventory, contracts, schemas, or grounded product boundaries.
6. Open one pull request in the fork for runtime code and, when needed, a separate pull request in the control repo for docs or contract updates. Cross-link the two pull requests rather than mixing both concerns into one repository.

Treat the control repo as the source of durable planning and workflow truth, and the fork as the source of executable product behavior.

## Phase workflow helpers

The control repo now ships helper scripts for the phase workflow:

- `scripts\new-phase-branch.ps1`
- `scripts\new-phase-task-branch.ps1`
- `scripts\new-phase-state.ps1`

Recommended usage:

1. Create or switch to the phase branch.
2. Create the initial phase state file under the real fork clone.
3. Create sibling task branches only when a Planner-approved task is safe to run in parallel.

Recommended phase state path in the fork clone:

```text
<fork-root>\.catastroswitch\phase-state\<phase>.phase-state.json
```

That file should be treated as workflow state, not as product runtime code.

## Where code will likely land

You will spend most of your time in:

- `src/vs/workbench/...` for shell, layout, views, and product services
- `src/vs/platform/userDataProfile/...` for profile model and persistence
- `src/vs/workbench/contrib/chat/...` for product-owned agent/session surfaces
- `extensions/...` only when a built-in extension needs to cooperate with the fork

## Recommended day-one validation

After cloning and bootstrapping, confirm:

1. `npm install` finishes cleanly.
2. `npm run compile` succeeds.
3. `npm run eslint` succeeds after the CatastroSwitch policy overlay is wired in.
4. `npm run watch` starts without immediate failure.
5. `scripts\code.bat` launches the development build.
6. You can identify the baseline workbench layout before patching it.

## How this relates to `C:\CatastroSwitch`

`C:\CatastroSwitch` stays valuable even after the fork exists.

Keep using it for:

- workspace registry design
- explicit agent adapter contracts
- grounded capability documentation
- extension-side experiments that do not require product changes

Treat the fork as the home for product-owned chrome, profile orchestration, and product-owned agent visibility.

