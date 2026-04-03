# Grounding

This repository is maintained as a fork-first control repo grounded in official product documentation discovered through web search and Microsoft Learn.

## Official sources used

| Topic | Key takeaway | Source |
|---|---|---|
| Profiles | Profiles store settings, extensions, and UI layout changes and can be associated with folders and workspaces. | <https://code.visualstudio.com/docs/configure/profiles> |
| VS Code custom instructions | `.github/copilot-instructions.md`, `AGENTS.md`, and `.instructions.md` are supported customization surfaces. | <https://code.visualstudio.com/docs/copilot/customization/custom-instructions> |
| VS Code custom agents | `.github/agents` plus `.agent.md` files are supported in VS Code custom agents. | <https://code.visualstudio.com/docs/copilot/customization/custom-agents> |
| VS Code agent skills | `.github/skills/<skill-name>/SKILL.md` is a supported format for reusable agent skills. | <https://code.visualstudio.com/docs/copilot/customization/agent-skills> |
| GitHub custom agents | Repository-level custom agents live in `.github/agents/`. | <https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-custom-agents> |
| GitHub agent skills | Project skills live in `.github/skills/` and use `SKILL.md` with YAML frontmatter. | <https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-skills> |
| GitHub customization cheat sheet | Clarifies when to use instructions, agents, skills, prompt files, hooks, and MCP. | <https://docs.github.com/en/copilot/reference/customization-cheat-sheet> |
| GitHub fork sync workflow | A fork should fetch `upstream`, update its clean sync branch from `upstream/main`, and then push that branch back to the fork if you want the fork on GitHub to match upstream. | <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork> |
| Microsoft Learn Copilot customization module | Reinforces that instructions, prompt files, custom agents, and handoffs are first-class customization features in VS Code. | <https://learn.microsoft.com/en-us/training/modules/configure-customize-github-copilot-visual-studio-code/> |
| VS Code source organization | VS Code core is implemented in TypeScript, with the main code under `src/vs/` and built-in extensions under `extensions/`. | <https://github.com/microsoft/vscode/wiki/Source-Code-Organization> |
| VS Code contribution setup | The official contribution guide documents clone and build prerequisites such as Node, Python, native toolchains, and the warning to avoid spaces in the clone path. | <https://github.com/microsoft/vscode/wiki/How-to-Contribute> |
| VS Code repo build scripts | The root `package.json` defines the real `compile`, `watch`, `watch-web`, and related scripts used for self-host development. | <https://github.com/microsoft/vscode/blob/main/package.json> |
| VS Code self-host launcher | `scripts/code.bat` is the Windows launcher for the development build and shows the self-host prelaunch behavior. | <https://github.com/microsoft/vscode/blob/main/scripts/code.bat> |
| VS Code chat organization | The chat contrib documents where widget, participants, tools, model, and session-related code live. | <https://github.com/microsoft/vscode/blob/main/src/vs/workbench/contrib/chat/chatCodeOrganization.md> |
| TypeScript contributor guidelines | Microsoft's TypeScript project uses PascalCase for types and enum values, camelCase for functions and properties, avoids `I` interface prefixes, prefers `undefined` over `null`, and documents several strict style defaults. | <https://github.com/microsoft/TypeScript/wiki/Coding-guidelines> |
| VS Code coding guidelines | VS Code uses tabs, PascalCase for types, camelCase for members, JSDoc on key API surfaces, externalized user strings, arrow functions for callbacks, and braces on loop and conditional bodies. | <https://github.com/microsoft/vscode/wiki/Coding-Guidelines> |
| Azure SDK TypeScript design guidelines | Microsoft's Azure SDK guidance prefers explicit client APIs, overloads over ambiguous unions, standardized options naming, `abortSignal`, and dependable APIs with minimal breaking changes. | <https://azure.github.io/azure-sdk/typescript_design.html> |
| Azure JavaScript and TypeScript client guidance | Microsoft Learn recommends Azure client libraries that standardize authentication, retries, logging, paging, and long-running operations for JavaScript and TypeScript. | <https://learn.microsoft.com/en-us/azure/developer/javascript/sdk/use-azure-sdk> |
| TypeScript declaration merging | TypeScript can merge declarations and augment named exports, but augmentation is a type-level patch with explicit limits. | <https://www.typescriptlang.org/docs/handbook/declaration-merging.html> |
| TypeScript mixins | Mixins provide a composition-based way to build runtime behavior without pretending classes magically merge. | <https://www.typescriptlang.org/docs/handbook/mixins.html> |

## Web search role

Web search was used to discover and confirm the latest official documentation pages and public issue history relevant to:

- Copilot customization in VS Code
- profile orchestration limitations
- VS Code fork build and run docs
- concrete source patch zones
- additive TypeScript patterns for low-diff forking

The control repo itself is based on the official sources linked above and on public issue threads where product gaps are documented.

## Public issue history used for product boundaries

- Profile API request closed as not planned:  
  <https://github.com/microsoft/vscode/issues/211890>
- Programmatic profile switching request closed as not planned:  
  <https://github.com/microsoft/vscode/issues/226355>

## How the grounding shapes the fork plan

- The repository uses documented Copilot customization files for contributor automation.
- The fork docs point to concrete `src/vs/...` files instead of treating the VS Code codebase as a black box.
- Profile behavior is described in terms of real profile resources and documented API limits.
- Agent and session visibility guidance stays with product-owned runtime state or explicit adapters.
- The fork guidance prefers additive seams and small diffs over copying upstream files.
