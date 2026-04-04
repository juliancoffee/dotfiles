---
name: "playwright"
description: "Use when the task requires automating a real browser from the terminal (navigation, form filling, snapshots, screenshots, data extraction, UI-flow debugging) via `playwright-cli` or the bundled wrapper script."
---


# Playwright CLI Skill

Drive a real browser from the terminal using `playwright-cli`. Prefer the bundled wrapper script so the CLI works even when it is not globally installed.
Treat this skill as CLI-first automation. Do not pivot to `@playwright/test` unless the user explicitly asks for test files.

## Prerequisite check (required)

Before proposing commands, check whether `npx` is available (the wrapper depends on it):

```bash
command -v npx >/dev/null 2>&1
```

If it is not available, pause and ask the user to install Node.js/npm (which provides `npx`). Provide these steps verbatim:

```bash
# Verify Node/npm are installed
node --version
npm --version

# If missing, install Node.js/npm, then:
npm install -g @playwright/cli@latest
playwright-cli --help
```

Once `npx` is present, proceed with the wrapper script. A global install of `playwright-cli` is optional.

## Skill path (set once)

```bash
export CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
export PWCLI="$CODEX_HOME/skills/playwright/scripts/playwright_cli.sh"
```

User-scoped skills install under `$CODEX_HOME/skills` (default: `~/.codex/skills`).

## Quick start

Use the wrapper script:

```bash
"$PWCLI" --session shot-playwright-home-20260404-01 open https://playwright.dev --headed
"$PWCLI" --session shot-playwright-home-20260404-01 snapshot
"$PWCLI" --session shot-playwright-home-20260404-01 click e15
"$PWCLI" --session shot-playwright-home-20260404-01 type "Playwright"
"$PWCLI" --session shot-playwright-home-20260404-01 press Enter
"$PWCLI" --session shot-playwright-home-20260404-01 screenshot
"$PWCLI" --session shot-playwright-home-20260404-01 close
```

If the user prefers a global install, this is also valid:

```bash
npm install -g @playwright/cli@latest
playwright-cli --help
```

## Core workflow

1. Pick a unique `--session` name for the run. Do not rely on the default session.
2. Open the page.
3. Snapshot to get stable element refs.
4. Interact using refs from the latest snapshot.
5. Re-snapshot after navigation or significant DOM changes.
6. Capture artifacts (screenshot, pdf, traces) when useful.
7. Close the same session when you are done.

Session names must be unique per run, not just descriptive.
Good: `shot-index-20260404-01`, `debug-checkout-20260404-02`, `tabs-docs-20260404-01`
Bad: `demo`, `form`, `debug`, `tabs`, `test`

Minimal loop:

```bash
"$PWCLI" --session flow-example-home-20260404-01 open https://example.com
"$PWCLI" --session flow-example-home-20260404-01 snapshot
"$PWCLI" --session flow-example-home-20260404-01 click e3
"$PWCLI" --session flow-example-home-20260404-01 snapshot
"$PWCLI" --session flow-example-home-20260404-01 close
```

## When to snapshot again

Snapshot again after:

- navigation
- clicking elements that change the UI substantially
- opening/closing modals or menus
- tab switches

Refs can go stale. When a command fails due to a missing ref, snapshot again.

## Recommended patterns

### Form fill and submit

```bash
"$PWCLI" --session form-login-20260404-01 open https://example.com/form
"$PWCLI" --session form-login-20260404-01 snapshot
"$PWCLI" --session form-login-20260404-01 fill e1 "user@example.com"
"$PWCLI" --session form-login-20260404-01 fill e2 "password123"
"$PWCLI" --session form-login-20260404-01 click e3
"$PWCLI" --session form-login-20260404-01 snapshot
"$PWCLI" --session form-login-20260404-01 close
```

### Debug a UI flow with traces

```bash
"$PWCLI" --session debug-home-20260404-01 open https://example.com --headed
"$PWCLI" --session debug-home-20260404-01 tracing-start
# ...interactions...
"$PWCLI" --session debug-home-20260404-01 tracing-stop
"$PWCLI" --session debug-home-20260404-01 close
```

### Multi-tab work

```bash
"$PWCLI" --session tabs-example-20260404-01 open about:blank
"$PWCLI" --session tabs-example-20260404-01 tab-new https://example.com
"$PWCLI" --session tabs-example-20260404-01 tab-list
"$PWCLI" --session tabs-example-20260404-01 tab-select 0
"$PWCLI" --session tabs-example-20260404-01 snapshot
"$PWCLI" --session tabs-example-20260404-01 close
```

## Wrapper script

The wrapper script uses `npx --package @playwright/cli playwright-cli` so the CLI can run without a global install:

```bash
"$PWCLI" --help
```

Prefer the wrapper unless the repository already standardizes on a global install.
The wrapper also adds a targeted fallback for `close` when Python is available. If Python is unavailable, the wrapper warns and falls back to the basic `npx` behavior, so you should re-check that the session actually exited.

## Session hygiene

- Always pass a unique `--session` name.
- Never use generic session names like `demo`, `form`, `debug`, `tabs`, or `test`.
- Prefer a pattern like `<task>-<page>-<date>-<counter>`.
- Reuse that same session name for every command in the flow.
- Always run `"$PWCLI" --session NAME close` after the flow finishes.
- If `close` reports trouble, re-check the session/process state before starting a new run.

## References

Open only what you need:

- CLI command reference: `references/cli.md`
- Practical workflows and troubleshooting: `references/workflows.md`

## Guardrails

- Always snapshot before referencing element ids like `e12`.
- Re-snapshot when refs seem stale.
- Prefer explicit commands over `eval` and `run-code` unless needed.
- When you do not have a fresh snapshot, use placeholder refs like `eX` and say why; do not bypass refs with `run-code`.
- Use `--headed` when a visual check will help.
- When capturing artifacts in this repo, use `output/playwright/` and avoid introducing new top-level artifact folders.
- Default to CLI commands and workflows, not Playwright test specs.
