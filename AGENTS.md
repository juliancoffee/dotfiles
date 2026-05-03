# AGENTS.md

## About
This is a personal dotfiles repo. It stores configs and support files that are linked into the local home directory.

## How It Works
`config.py` is the source of truth for installation. It maps files and directories in this repo to their target locations in `$HOME` and manages symlinks.

Most changes should stay inside the repo. Running `config.py` changes local machine state, so treat it as an explicit installer action, not a casual read or check command.

## Rules
- Do not run `config.py` unless the user explicitly asks.
- Do not create or remove symlinks in `$HOME` unless the user explicitly asks.
- Prefer non-dot names in the repo when practical.
- Use dotted target paths only where the installed program expects them.
- Prefer `uv run ...` for Python commands and tests in this repo.
- Prefer reading, searching, and tests before taking actions that affect install layout.
- Read `README.md`, `config.py`, and relevant tests before changing installer behavior.
- Add a short comment above each function explaining what it does.
- The first line of a function comment must be short.
- Keep changes minimal and avoid repo-wide restructuring unless the user explicitly requests it.
- Review your code with `git diff` afterwards, to ensure code quality and simplicity. Read it!
- Fix all error-hiding fallbacks, unneeded helper functions, and all other problems you'll find.

## Notes
- Repo naming and installed-path naming are different concerns.
- If hidden files are annoying in tooling, prefer fixing the tooling before spreading more dot-prefixed paths through the repo.
- `config.py` should handle mapping repo paths to real target paths.
