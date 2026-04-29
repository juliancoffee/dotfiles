---
name: project-bootstrap
description: Use when the user wants to create, scaffold, initialize, or bootstrap a brand-new project or repository. Pick a safe workspace path first, strongly prefer `~/Workspace/lab` on this machine, avoid fuzzying into user-content folders like Documents or Movies, then initialize the project with language-appropriate tooling such as `uv init`, `cargo init`, `dune`, or Vite. For Python, prefer Hatch, pytest, and `src/` layout.
metadata:
  short-description: Create new projects in a safe workspace with sensible defaults
---

# Project Bootstrap

Use this skill when the user wants a brand-new project directory with initial tooling and layout.

## Path selection

Choose the project root before running any scaffolding commands.

Path priority:

1. If the user gave an explicit path, use it.
2. On this machine, prefer `~/Workspace/lab/<project-name>`.
3. On other machines, look for a safe workspace-like root under `$HOME` such as:
   - `~/Workspace`
   - `~/Code`
   - `~/Projects`
   - `~/Dev`
   - `~/src`
   - `~/work`
4. If a safe workspace root exists, prefer creating or using its `lab/` child for scratch or personal projects.
5. If no safe workspace root exists, ask the user where new projects should live instead of guessing.

Hard exclusions:

- Never choose `~/Documents`, `~/Downloads`, `~/Desktop`, `~/Movies`, `~/Music`, `~/Pictures`, `~/Library`, `~/Applications`, or similar user-content folders as the default project root.
- Never "fuzzy match" into a random existing folder just because the name looks close.

Before creating the directory:

- Confirm the final absolute path in your own reasoning.
- If the target directory already exists and is not empty, ask the user whether to reuse it.
- If the target directory does not exist, create it, including the `lab/` parent when that is the selected safe default.

## Tool selection

Prefer the language-native initializer when it exists.

### Python

- For most new Python projects, start with a single-file layout.
- Prefer `uv init` for small scripts, experiments, and one-off tools.
- Switch to packaged `src/` layout with `uv init --package` when the project clearly needs multiple files, reusable packaging boundaries, or a real importable package.
- If the user describes a library, use `uv init --lib`.
- After bootstrap, configure the project to use Hatch as the build backend.
- Add pytest as the default test dependency and create a `tests/` directory when the scaffold did not create one.
- Tests are still fine for single-file projects; do not treat pytest as a reason by itself to force `src/` layout.
- Remember what `src/` layout means: importable package code lives under `src/<package_name>/` instead of at the repo root, which helps avoid accidentally importing the working tree directly and keeps packaging boundaries cleaner.
- Prefer `uv run` and `uv add` for follow-up commands.
- For concrete examples of `src/` layout versus single-file layout, read `references/python-project-layouts.md`.

Reference: official uv docs say `uv init` defaults to an application project, while `--lib` creates a library and `--package` creates a packaged app with `src/` layout. For why `src/` layout is useful when the project grows, prefer the PyPA guide [src layout vs flat layout](https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/). See also uv’s [Creating projects](https://docs.astral.sh/uv/concepts/projects/init/).

### Rust

- Prefer `cargo init`.
- Use `--lib` for libraries and the default binary layout for apps unless the user asks otherwise.
- If the user asked for a fresh repository rather than initializing inside an existing repo, create the directory first and run `cargo init` inside it.

### OCaml

- Prefer Dune, not an opam-heavy manual bootstrap.
- Use `dune init proj <name>` for a normal new project.
- Prefer current Dune package-management style in `dune-project` over hand-rolled opam-first setup when dependencies are needed.
- The result should build with `dune build` without requiring the user to manually wire a lot of opam boilerplate.
- If `dune` is missing, stop and ask instead of inventing a partial OCaml setup.

Reference: Dune docs describe `dune init` as limited but suitable for generating project structure, and Dune package management is designed around project-local configuration and lockfiles rather than global state. See [CLI](https://dune.readthedocs.io/en/latest/usage.html) and [package management](https://dune.readthedocs.io/en/stable/explanation/package-management.html).

### JavaScript / TypeScript

- Default package manager: `pnpm`.
- If the project is clearly frontend or browser-facing, prefer Vite.
- For frontend Vite projects, prefer `pnpm create vite`.
- If the user names a framework supported by Vite templates, pass the matching template instead of leaving it interactive when practical.
- If the project is Node-only, CLI-oriented, library-oriented, or backend-oriented, do not assume Vite. Use the smallest sensible initializer for that stack, or ask one focused question if the scaffold shape is unclear.
- If the project already clearly uses another package manager, follow the existing manager instead of switching.

Reference: Vite’s official getting-started guide includes `pnpm create vite`, and pnpm is a strong default for modern JS/TS projects, especially with workspaces. See [Getting Started](https://vite.dev/guide/) and [pnpm](https://pnpm.io/).

### Other languages or unknown stack

- If there is a well-known project initializer, use it.
- Otherwise:
  1. create the directory
  2. run `git init`
  3. add the smallest sensible starter files only if the user asked
- If the stack choice materially affects the bootstrap, ask a focused question instead of guessing.

## Workflow

1. Identify the requested language, framework, and whether it is an app, library, or experiment.
2. Resolve a safe absolute target path using the rules above.
3. Check whether the relevant tool exists before scaffolding.
4. Initialize the project with the language-appropriate command.
5. Run the smallest validation command that proves the scaffold worked:
   - Python: `uv run pytest` when tests are configured, otherwise inspect generated files or run the generated entrypoint
   - Rust: `cargo check`
   - OCaml: `dune build`
   - JS/TS: install dependencies if needed and run a non-destructive validation step such as checking generated scripts or `npm run build` when appropriate
6. Report the created path, the command used, and any follow-up commands the user will likely want next.

## Guardrails

- Prefer non-interactive commands when you can infer the right template safely.
- Do not create the project in a content folder just because no workspace exists.
- Do not run home-directory installers or unrelated setup steps unless the user asked.
- If tool availability is missing or the stack choice is ambiguous in a way that changes the scaffold shape, ask one focused question.
- Keep the initial scaffold minimal; do not turn "create a project" into a whole platform setup unless the user asked for that.
