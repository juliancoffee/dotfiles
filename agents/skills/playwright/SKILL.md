---
name: "playwright"
description: "Use when the task requires automating a real browser from the terminal (navigation, form filling, snapshots, screenshots, data extraction, UI-flow debugging) via the bundled Python Playwright CLI wrappers."
---


# Playwright CLI Skill

Drive a real browser from the terminal using `playwright-cli` through the bundled Python entrypoints. This skill requires Python.
Treat this skill as CLI-first automation. Do not pivot to `@playwright/test` unless the user explicitly asks for test files.

## Prerequisite check (required)

Before proposing commands, check whether `python3` and `npm` are available:

```bash
command -v python3 >/dev/null 2>&1
command -v npm >/dev/null 2>&1
```

If either one is not available, pause and ask the user to install the missing runtime. Provide these steps verbatim:

```bash
# Verify Python is installed
python3 --version

# Verify Node/npm are installed
node --version
npm --version

# If missing, install the missing runtime(s), then verify:
python3 --version
npm --version
npx --version
```

Once `npm` is present, proceed with the Python entrypoint. A global install of `playwright-cli` is optional.

## Skill path (set once)

```bash
export AGENTS_HOME="${AGENTS_HOME:-$HOME/.agents}"
export PWCLI="$AGENTS_HOME/skills/playwright/scripts/playwright_cli.py"
export PWSHOT="$AGENTS_HOME/skills/playwright/scripts/playwright_screenshot.py"
```

User-scoped shared skills install under `$AGENTS_HOME/skills` (default: `~/.agents/skills`).

## Quick start

Use the Python entrypoint:

```bash
python3 "$PWCLI" --session index-013546 open https://playwright.dev
python3 "$PWCLI" --session index-013546 snapshot
python3 "$PWCLI" --session index-013546 click e15
python3 "$PWCLI" --session index-013546 type "Playwright"
python3 "$PWCLI" --session index-013546 press Enter
python3 "$PWCLI" --session index-013546 screenshot
python3 "$PWCLI" --session index-013546 close
```

For screenshot-only work, use the thin wrapper on top of `playwright-cli`:

```bash
python3 "$PWSHOT" https://playwright.dev \
  --output /tmp/playwright/index-013546.png \
  --full-page
```

If the user prefers a global install, this is also valid:

```bash
npm install -g @playwright/cli@latest
playwright-cli --help
```

## Core workflow

1. Pick a short unique `--session` name for the run. See Session hygiene for the naming rule. Do not rely on the default session.
2. Open the page.
3. Snapshot to get stable element refs.
4. Interact using refs from the latest snapshot.
5. Re-snapshot after navigation or significant DOM changes.
6. Capture artifacts (screenshot, pdf, traces) when useful.
7. Close the same session when you are done.

Session names must be unique per run, not just descriptive.
Name sessions as `<htmlname>-hhmmss`, where `hhmmss` is the current hour, minute, and second in 24-hour time.
If punctuation helps readability, `hh-mm-ss` is fine too, as long as the whole session name stays short enough.
For example, if the current time is `01:35:46`, use `index-013546` or `index-01-35-46`.
Keep session names to 16 characters or fewer.
Good: `index-013546`, `fusion-014212`, `swift-014359`
Bad: `demo`, `form`, `debug`, `tabs`, `test`

Minimal loop:

```bash
python3 "$PWCLI" --session index-013546 open https://example.com
python3 "$PWCLI" --session index-013546 snapshot
python3 "$PWCLI" --session index-013546 click e3
python3 "$PWCLI" --session index-013546 snapshot
python3 "$PWCLI" --session index-013546 close
```

## One-Shot Screenshots

Use the screenshot wrapper when the task is just open, optional wait, capture, close:

```bash
python3 "$PWSHOT" https://example.com \
  --output /tmp/playwright/example-013546.png \
  --full-page
```

Useful flags:

- `--selector ".hero"` to capture a specific element
- `--delay-ms 1500` to wait for late animations
- `--browser firefox` to pass a browser choice through to `playwright-cli open`
- `--headed` for visual debugging
- omit `--output` to default to `/tmp/playwright/<session>.png`
- `--dry-run` to print the exact underlying `playwright_cli.py` commands without running them

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
python3 "$PWCLI" --session form-013546 open https://example.com/form
python3 "$PWCLI" --session form-013546 snapshot
python3 "$PWCLI" --session form-013546 fill e1 "user@example.com"
python3 "$PWCLI" --session form-013546 fill e2 "password123"
python3 "$PWCLI" --session form-013546 click e3
python3 "$PWCLI" --session form-013546 snapshot
python3 "$PWCLI" --session form-013546 close
```

### Debug a UI flow with traces

```bash
python3 "$PWCLI" --session debug-013546 open https://example.com --headed
python3 "$PWCLI" --session debug-013546 tracing-start
# ...interactions...
python3 "$PWCLI" --session debug-013546 tracing-stop
python3 "$PWCLI" --session debug-013546 close
```

### Multi-tab work

```bash
python3 "$PWCLI" --session tabs-013546 open about:blank
python3 "$PWCLI" --session tabs-013546 tab-new https://example.com
python3 "$PWCLI" --session tabs-013546 tab-list
python3 "$PWCLI" --session tabs-013546 tab-select 0
python3 "$PWCLI" --session tabs-013546 snapshot
python3 "$PWCLI" --session tabs-013546 close
```

## Entrypoints

Use the Python entrypoints for Codex/tool execution:

```bash
python3 "$PWCLI" --help
```

This keeps the CLI invocation in normal argv form and tends to behave better with command-approval matching.

## Session hygiene

- Name sessions as `<htmlname>-hhmmss`, for example `index-013546`.
- Always pass a unique `--session` name.
- Keep session names to 16 characters or fewer.
- Good: `index-013546`, `fusion-014212`, `swift-014359`
- Bad: `demo`, `form`, `debug`, `tabs`, `test`
- Never use generic session names like `demo`, `form`, `debug`, `tabs`, or `test`.
- Reuse that same session name for every command in the flow.
- Always run `python3 "$PWCLI" --session NAME close` after the flow finishes.
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
- Default to headless for routine automation and screenshots.
- Use `--headed` only for interactive debugging or when a live visual check is specifically useful.
- Prefer `/tmp/playwright/` for screenshot outputs so captures stay out of the repo by default.
- Default to CLI commands and workflows, not Playwright test specs.
- Prefer `python3 "$PWCLI" ...` for Codex/tool execution.
- For screenshot-only flows, prefer `python3 "$PWSHOT" ...` over ad hoc multi-command sequences.
