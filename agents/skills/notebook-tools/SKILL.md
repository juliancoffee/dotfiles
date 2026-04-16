---
name: notebook-tools
description: Use when working with Jupyter notebooks (`.ipynb`) and the task involves reading, replacing text in, writing, inserting, deleting, or validating notebook cells. Prefer this skill over raw JSON changes when notebook structure or outputs must stay intact.
---

# Notebook Tools

Use the bundled CLI to inspect and change notebooks structurally instead of patching raw JSON by hand.
This keeps cell arrays, metadata, and multiline `source` fields consistent.

## Quick Start

Set the helper path once:

```bash
export AGENTS_HOME="${AGENTS_HOME:-$HOME/.agents}"
export NBTOOL="$AGENTS_HOME/skills/notebook-tools/scripts/notebook_tool.py"
```

Inspect a notebook before editing:

```bash
python3 "$NBTOOL" summary path/to/notebook.ipynb
python3 "$NBTOOL" read path/to/notebook.ipynb --cell 3
python3 "$NBTOOL" replace path/to/notebook.ipynb --cell 3 --old "foo" --new "bar"
```

Write a cell from a file:

```bash
python3 "$NBTOOL" write path/to/notebook.ipynb --cell 3 --source-file /tmp/cell.py
```

Insert a new markdown cell after cell 3:

```bash
python3 "$NBTOOL" insert path/to/notebook.ipynb --after 3 --cell-type markdown --source-file /tmp/note.md
```

Delete a cell:

```bash
python3 "$NBTOOL" delete path/to/notebook.ipynb --cell 5
```

## Workflow

1. Run `summary` first to map the notebook.
2. Run `read` on the target cell before changing it.
3. Use `replace`, `write`, `insert`, or `delete` instead of direct JSON edits.
4. Run `summary` or `read` again to verify the final structure.

## Commands

### `summary`

Prints one line per cell with:

- cell index
- cell type
- execution count for code cells
- first non-empty source line preview

Use this to find the right cell quickly.

### `read`

Reads one cell and prints:

- cell type
- execution count
- metadata
- source

Add `--outputs` to also print code-cell outputs in JSON form.

### `write`

Replaces a cell's `source`.

Recommended input options:

- `--source-file PATH`
- `--text "..."` for short single-line changes
- stdin with `--stdin`

By default this also clears outputs and resets `execution_count` for code cells. Pass `--keep-outputs` if you explicitly want to preserve them.

### `replace`

Performs an in-cell string replacement without rewriting the whole cell.

Required:

- `--old "..."` and `--new "..."`

Optional:

- `--count N` to limit replacements
- `--keep-outputs` to preserve code-cell outputs

Use `replace` for small, surgical changes. Use `write` when replacing the full cell body is clearer.

### `insert`

Inserts a new cell before or after an index.

Required:

- exactly one of `--before` or `--after`
- one source input

Optional:

- `--cell-type code|markdown|raw`

### `delete`

Deletes one cell by index.

## Guardrails

- Prefer source files or stdin for multiline edits.
- Do not hand-edit notebook JSON unless the user specifically asks for raw JSON changes.
- For code cells, clear stale outputs unless preserving outputs is part of the task.
- Re-run `summary` after structural changes to confirm indexes shifted as expected.
