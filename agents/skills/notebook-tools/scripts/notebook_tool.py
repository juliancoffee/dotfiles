#!/usr/bin/env python3
import argparse
import difflib
import json
import subprocess
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def parse_notebook_json(raw: str, *, origin: str) -> dict:
    try:
        notebook = json.loads(raw)
    except json.JSONDecodeError as exc:
        fail(
            f"invalid notebook JSON in {origin} at line {exc.lineno}, "
            f"column {exc.colno}"
        )

    if not isinstance(notebook, dict):
        fail(f"invalid notebook JSON in {origin}: expected an object")

    return notebook


def load_notebook(path: Path, *, missing_ok: bool = False) -> dict | None:
    try:
        raw = path.read_text(encoding="utf-8")
    except FileNotFoundError:
        if missing_ok:
            return None
        fail(f"notebook not found: {path}")
    return parse_notebook_json(raw, origin=str(path))


def save_notebook(path: Path, notebook: dict) -> None:
    path.write_text(
        json.dumps(notebook, ensure_ascii=False, indent=1) + "\n",
        encoding="utf-8",
    )


def empty_notebook() -> dict:
    return {"cells": []}


def cells(notebook: dict) -> list:
    value = notebook.get("cells")
    if not isinstance(value, list):
        fail("notebook missing a valid 'cells' list")
    return value


def get_cell(notebook: dict, index: int) -> dict:
    notebook_cells = cells(notebook)
    if index < 0 or index >= len(notebook_cells):
        fail(f"cell index out of range: {index} (cells: 0..{len(notebook_cells) - 1})")
    cell = notebook_cells[index]
    if not isinstance(cell, dict):
        fail(f"cell {index} is not an object")
    return cell


def normalize_source(text: str) -> list[str]:
    if not text:
        return []
    return text.splitlines(keepends=True)


def source_to_text(source) -> str:
    if isinstance(source, list):
        return "".join(str(part) for part in source)
    if isinstance(source, str):
        return source
    return ""


def read_source(args: argparse.Namespace) -> str:
    sources = [bool(args.source_file), bool(args.stdin), args.text is not None]
    if sum(sources) != 1:
        fail("provide exactly one source input: --source-file, --stdin, or --text")
    if args.source_file:
        return Path(args.source_file).read_text(encoding="utf-8")
    if args.stdin:
        return sys.stdin.read()
    return args.text


def preview(text: str) -> str:
    for line in text.splitlines():
        stripped = line.strip()
        if stripped:
            return stripped[:80]
    return ""


def normalize_json(value: object) -> str:
    return json.dumps(
        value,
        ensure_ascii=False,
        indent=2,
        sort_keys=True,
    ) + "\n"


def notebook_cell_key(
    cell: dict,
    *,
    include_metadata: bool,
    include_outputs: bool,
) -> tuple[str, ...]:
    key = [
        str(cell.get("cell_type", "unknown")),
        source_to_text(cell.get("source")),
    ]
    if include_metadata:
        key.append(normalize_json(cell.get("metadata", {})))
    if include_outputs:
        key.append(str(cell.get("execution_count")))
        key.append(normalize_json(cell.get("outputs", [])))
    return tuple(key)


def git(
    repo_root: Path,
    *args: str,
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        ["git", "-C", str(repo_root), *args],
        capture_output=True,
        text=True,
        check=False,
    )
    if check and result.returncode != 0:
        message = result.stderr.strip() or result.stdout.strip() or "git failed"
        fail(message)
    return result


def notebook_repo_root(path: Path) -> Path:
    result = subprocess.run(
        ["git", "-C", str(path.parent), "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        fail(f"notebook is not inside a git repository: {path}")
    return Path(result.stdout.strip()).resolve()


def notebook_repo_path(path: Path, repo_root: Path) -> Path:
    resolved = path.resolve()
    try:
        return resolved.relative_to(repo_root)
    except ValueError:
        fail(f"notebook is outside repository root {repo_root}: {path}")


def git_revision_exists(repo_root: Path, revision: str) -> bool:
    result = git(
        repo_root,
        "rev-parse",
        "--verify",
        f"{revision}^{{commit}}",
        check=False,
    )
    return result.returncode == 0


def git_show_notebook(
    repo_root: Path,
    object_spec: str,
    *,
    missing_ok: bool,
) -> dict | None:
    result = git(repo_root, "show", object_spec, check=False)
    if result.returncode != 0:
        if missing_ok:
            return None
        message = result.stderr.strip() or result.stdout.strip() or "git show failed"
        fail(message)
    return parse_notebook_json(result.stdout, origin=object_spec)


def load_git_notebook_revision(
    repo_root: Path,
    repo_path: Path,
    revision: str,
) -> dict | None:
    return git_show_notebook(
        repo_root,
        f"{revision}:{repo_path.as_posix()}",
        missing_ok=True,
    )


def load_git_notebook_index(repo_root: Path, repo_path: Path) -> dict | None:
    return git_show_notebook(
        repo_root,
        f":{repo_path.as_posix()}",
        missing_ok=True,
    )


def diff_text(
    before: str,
    after: str,
    *,
    fromfile: str,
    tofile: str,
    context: int,
) -> list[str]:
    return list(
        difflib.unified_diff(
            before.splitlines(keepends=True),
            after.splitlines(keepends=True),
            fromfile=fromfile,
            tofile=tofile,
            n=context,
        )
    )


def diff_text_string(
    before: str,
    after: str,
    *,
    fromfile: str,
    tofile: str,
    context: int,
) -> str:
    return "".join(
        diff_text(
            before,
            after,
            fromfile=fromfile,
            tofile=tofile,
            context=context,
        )
    )


def print_diff_lines(lines: list[str]) -> None:
    for line in lines:
        sys.stdout.write(line)
    if lines and not lines[-1].endswith("\n"):
        print()


def cell_preview(cell: dict | None) -> str:
    if cell is None:
        return ""
    return preview(source_to_text(cell.get("source")))


def format_cell_ref(index: int | None, cell: dict | None) -> str:
    if index is None:
        return "-"
    cell_type = "unknown" if cell is None else str(cell.get("cell_type", "unknown"))
    return f"{index}:{cell_type}"


def changed_cells(
    before_cells: list[dict],
    after_cells: list[dict],
    *,
    include_metadata: bool,
    include_outputs: bool,
) -> list[tuple[str, int | None, int | None, dict | None, dict | None]]:
    before_keys = [
        notebook_cell_key(
            cell,
            include_metadata=include_metadata,
            include_outputs=include_outputs,
        )
        for cell in before_cells
    ]
    after_keys = [
        notebook_cell_key(
            cell,
            include_metadata=include_metadata,
            include_outputs=include_outputs,
        )
        for cell in after_cells
    ]

    matcher = difflib.SequenceMatcher(
        a=before_keys,
        b=after_keys,
        autojunk=False,
    )

    changes: list[tuple[str, int | None, int | None, dict | None, dict | None]] = []
    for tag, before_start, before_end, after_start, after_end in matcher.get_opcodes():
        if tag == "equal":
            continue
        if tag == "replace":
            pairs = min(before_end - before_start, after_end - after_start)
            for offset in range(pairs):
                changes.append(
                    (
                        "M",
                        before_start + offset,
                        after_start + offset,
                        before_cells[before_start + offset],
                        after_cells[after_start + offset],
                    )
                )
            for index in range(before_start + pairs, before_end):
                changes.append(("D", index, None, before_cells[index], None))
            for index in range(after_start + pairs, after_end):
                changes.append(("A", None, index, None, after_cells[index]))
            continue
        if tag == "delete":
            for index in range(before_start, before_end):
                changes.append(("D", index, None, before_cells[index], None))
            continue
        if tag == "insert":
            for index in range(after_start, after_end):
                changes.append(("A", None, index, None, after_cells[index]))
            continue
    return changes


def cell_matches_filter(
    payload: dict[str, object],
    cell_index: int,
) -> bool:
    return (
        payload["old_index"] == cell_index
        or payload["new_index"] == cell_index
    )


def emit_text_section(
    label: str,
    before: str,
    after: str,
    *,
    file_names: tuple[str, str],
    context: int,
) -> bool:
    lines = diff_text(
        before,
        after,
        fromfile=file_names[0],
        tofile=file_names[1],
        context=context,
    )
    if not lines:
        return False
    print(f"@@ {label} @@")
    print_diff_lines(lines)
    return True


def build_diff_section(
    label: str,
    before: str,
    after: str,
    *,
    file_names: tuple[str, str],
    context: int,
) -> dict[str, object]:
    diff = diff_text_string(
        before,
        after,
        fromfile=file_names[0],
        tofile=file_names[1],
        context=context,
    )
    return {
        "label": label,
        "changed": bool(diff),
        "diff": diff,
        "before": before,
        "after": after,
        "fromfile": file_names[0],
        "tofile": file_names[1],
    }


def build_cell_change_payload(
    change: tuple[str, int | None, int | None, dict | None, dict | None],
    *,
    include_metadata: bool,
    include_outputs: bool,
    context: int,
) -> dict[str, object]:
    tag, before_index, after_index, before_cell, after_cell = change
    before_type = None if before_cell is None else before_cell.get("cell_type")
    after_type = None if after_cell is None else after_cell.get("cell_type")

    sections = [
        build_diff_section(
            "source",
            "" if before_cell is None else source_to_text(before_cell.get("source")),
            "" if after_cell is None else source_to_text(after_cell.get("source")),
            file_names=(
                "/dev/null" if before_index is None else f"cell {before_index} (before)",
                "/dev/null" if after_index is None else f"cell {after_index} (after)",
            ),
            context=context,
        )
    ]

    if include_metadata:
        sections.append(
            build_diff_section(
                "metadata",
                ""
                if before_cell is None
                else normalize_json(before_cell.get("metadata", {})),
                ""
                if after_cell is None
                else normalize_json(after_cell.get("metadata", {})),
                file_names=(
                    (
                        "/dev/null"
                        if before_index is None
                        else f"cell {before_index} metadata (before)"
                    ),
                    (
                        "/dev/null"
                        if after_index is None
                        else f"cell {after_index} metadata (after)"
                    ),
                ),
                context=context,
            )
        )

    if include_outputs:
        sections.append(
            build_diff_section(
                "outputs",
                ""
                if before_cell is None
                else normalize_json(
                    {
                        "execution_count": before_cell.get("execution_count"),
                        "outputs": before_cell.get("outputs", []),
                    }
                ),
                ""
                if after_cell is None
                else normalize_json(
                    {
                        "execution_count": after_cell.get("execution_count"),
                        "outputs": after_cell.get("outputs", []),
                    }
                ),
                file_names=(
                    (
                        "/dev/null"
                        if before_index is None
                        else f"cell {before_index} outputs (before)"
                    ),
                    (
                        "/dev/null"
                        if after_index is None
                        else f"cell {after_index} outputs (after)"
                    ),
                ),
                context=context,
            )
        )

    return {
        "status": tag,
        "old_index": before_index,
        "new_index": after_index,
        "old_ref": format_cell_ref(before_index, before_cell),
        "new_ref": format_cell_ref(after_index, after_cell),
        "old_cell_type": before_type,
        "new_cell_type": after_type,
        "preview": cell_preview(after_cell) or cell_preview(before_cell),
        "sections": sections,
    }


def emit_cell_change(
    change: tuple[str, int | None, int | None, dict | None, dict | None],
    *,
    include_metadata: bool,
    include_outputs: bool,
    context: int,
) -> None:
    payload = build_cell_change_payload(
        change,
        include_metadata=include_metadata,
        include_outputs=include_outputs,
        context=context,
    )
    tag = str(payload["status"])
    before_type = payload["old_cell_type"]
    after_type = payload["new_cell_type"]
    print(
        "=== "
        f"{tag} old={payload['old_ref']} "
        f"new={payload['new_ref']} ==="
    )

    if before_type != after_type:
        print(f"cell_type: {before_type} -> {after_type}")

    emitted = False
    for section in payload["sections"]:
        if not section["changed"]:
            continue
        print(f"@@ {section['label']} @@")
        sys.stdout.write(str(section["diff"]))
        if section["diff"] and not str(section["diff"]).endswith("\n"):
            print()
        emitted = True

    if not emitted:
        print("(no textual diff)")


def command_diff(args: argparse.Namespace) -> None:
    path = Path(args.notebook).resolve()
    repo_root = notebook_repo_root(path)
    repo_path = notebook_repo_path(path, repo_root)

    revision = args.rev or "HEAD"
    if args.rev and not git_revision_exists(repo_root, revision):
        fail(f"unknown git revision: {revision}")
    if not args.rev and not git_revision_exists(repo_root, "HEAD"):
        before = None
        revision_label = "(empty)"
    else:
        before = load_git_notebook_revision(repo_root, repo_path, revision)
        revision_label = revision

    if args.staged:
        after = load_git_notebook_index(repo_root, repo_path)
        target_label = "index"
    else:
        after = load_notebook(path, missing_ok=True)
        target_label = "working tree"

    if before is None and after is None:
        fail(f"notebook not found in {revision_label} or {target_label}: {path}")

    before_cells = cells(empty_notebook() if before is None else before)
    after_cells = cells(empty_notebook() if after is None else after)
    changes = changed_cells(
        before_cells,
        after_cells,
        include_metadata=args.metadata,
        include_outputs=args.outputs,
    )
    change_payloads = [
        build_cell_change_payload(
            change,
            include_metadata=args.metadata,
            include_outputs=args.outputs,
            context=args.context,
        )
        for change in changes
    ]
    if args.cell is not None:
        filtered_pairs = [
            (change, payload)
            for change, payload in zip(changes, change_payloads, strict=True)
            if cell_matches_filter(payload, args.cell)
        ]
        if not filtered_pairs:
            fail(
                "no changed cell matches "
                f"--cell {args.cell} ({revision_label} -> {target_label})"
            )
        changes = [change for change, _ in filtered_pairs]
        change_payloads = [payload for _, payload in filtered_pairs]

    if args.json:
        print(
            json.dumps(
                {
                    "notebook": str(path),
                    "repo_root": str(repo_root),
                    "repo_path": repo_path.as_posix(),
                    "base": revision_label,
                    "target": target_label,
                    "include_metadata": args.metadata,
                    "include_outputs": args.outputs,
                    "context": args.context,
                    "requested_cell": args.cell,
                    "changed_cells_count": len(change_payloads),
                    "changed_cells": change_payloads,
                },
                ensure_ascii=False,
                indent=2,
            )
        )
        return

    if not changes:
        print(
            f"Changed cells: 0 ({revision_label} -> {target_label})"
        )
        return

    print(f"Changed cells: {len(changes)} ({revision_label} -> {target_label})")
    for payload in change_payloads:
        print(
            f"{payload['status']} old={payload['old_ref']} "
            f"new={payload['new_ref']} "
            f"{payload['preview']}"
        )

    for change in changes:
        print()
        emit_cell_change(
            change,
            include_metadata=args.metadata,
            include_outputs=args.outputs,
            context=args.context,
        )


def command_summary(args: argparse.Namespace) -> None:
    notebook = load_notebook(Path(args.notebook))
    for index, cell in enumerate(cells(notebook)):
        cell_type = cell.get("cell_type", "unknown")
        count = cell.get("execution_count")
        count_label = "-" if count is None else str(count)
        print(f"[{index}] {cell_type} exec={count_label} {preview(source_to_text(cell.get('source')))}")


def command_read(args: argparse.Namespace) -> None:
    notebook = load_notebook(Path(args.notebook))
    cell = get_cell(notebook, args.cell)
    payload = {
        "cell_type": cell.get("cell_type"),
        "execution_count": cell.get("execution_count"),
        "metadata": cell.get("metadata", {}),
        "source": source_to_text(cell.get("source")),
    }
    if args.outputs:
        payload["outputs"] = cell.get("outputs", [])
    print(json.dumps(payload, ensure_ascii=False, indent=2))


def clear_code_outputs(cell: dict) -> None:
    if cell.get("cell_type") == "code":
        cell["outputs"] = []
        cell["execution_count"] = None


def command_write(args: argparse.Namespace) -> None:
    path = Path(args.notebook)
    notebook = load_notebook(path)
    cell = get_cell(notebook, args.cell)
    cell["source"] = normalize_source(read_source(args))
    if not args.keep_outputs:
        clear_code_outputs(cell)
    save_notebook(path, notebook)
    print(f"updated cell {args.cell} in {path}")


def command_replace(args: argparse.Namespace) -> None:
    path = Path(args.notebook)
    notebook = load_notebook(path)
    cell = get_cell(notebook, args.cell)
    original = source_to_text(cell.get("source"))
    if args.old not in original:
        fail(f"target text not found in cell {args.cell}")
    updated = original.replace(args.old, args.new, args.count)
    cell["source"] = normalize_source(updated)
    if not args.keep_outputs:
        clear_code_outputs(cell)
    save_notebook(path, notebook)
    print(f"replaced text in cell {args.cell} in {path}")


def command_insert(args: argparse.Namespace) -> None:
    path = Path(args.notebook)
    notebook = load_notebook(path)
    notebook_cells = cells(notebook)
    source = normalize_source(read_source(args))
    new_cell = {
        "cell_type": args.cell_type,
        "metadata": {},
        "source": source,
    }
    if args.cell_type == "code":
        new_cell["execution_count"] = None
        new_cell["outputs"] = []

    if args.before is not None and args.after is not None:
        fail("use exactly one of --before or --after")
    if args.before is None and args.after is None:
        fail("use one of --before or --after")

    if args.before is not None:
        position = args.before
        if position < 0 or position > len(notebook_cells):
            fail(f"--before index out of range: {position}")
    else:
        if args.after < -1 or args.after >= len(notebook_cells):
            fail(f"--after index out of range: {args.after}")
        position = args.after + 1

    notebook_cells.insert(position, new_cell)
    save_notebook(path, notebook)
    print(f"inserted {args.cell_type} cell at index {position} in {path}")


def command_delete(args: argparse.Namespace) -> None:
    path = Path(args.notebook)
    notebook = load_notebook(path)
    notebook_cells = cells(notebook)
    get_cell(notebook, args.cell)
    del notebook_cells[args.cell]
    save_notebook(path, notebook)
    print(f"deleted cell {args.cell} from {path}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Read and modify Jupyter notebooks structurally."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    summary_parser = subparsers.add_parser("summary", help="List cells with short previews.")
    summary_parser.add_argument("notebook")
    summary_parser.set_defaults(func=command_summary)

    read_parser = subparsers.add_parser("read", help="Print one cell as JSON.")
    read_parser.add_argument("notebook")
    read_parser.add_argument("--cell", type=int, required=True)
    read_parser.add_argument("--outputs", action="store_true")
    read_parser.set_defaults(func=command_read)

    diff_parser = subparsers.add_parser(
        "diff",
        help="Show notebook-aware diffs against git.",
    )
    diff_parser.add_argument("notebook")
    diff_parser.add_argument(
        "--rev",
        help="Compare against a specific git revision instead of HEAD.",
    )
    diff_parser.add_argument(
        "--staged",
        action="store_true",
        help="Compare the git revision against the staged notebook blob.",
    )
    diff_parser.add_argument(
        "--metadata",
        action="store_true",
        help="Include metadata changes in cell matching and diff output.",
    )
    diff_parser.add_argument(
        "--outputs",
        action="store_true",
        help="Include execution_count and outputs in cell matching and diff output.",
    )
    diff_parser.add_argument(
        "--context",
        type=int,
        default=3,
        help="Number of unified diff context lines to show per cell.",
    )
    diff_parser.add_argument(
        "--cell",
        type=int,
        help="Show only the changed cell whose old or new index matches this value.",
    )
    diff_parser.add_argument(
        "--json",
        action="store_true",
        help="Emit machine-readable JSON instead of text output.",
    )
    diff_parser.set_defaults(func=command_diff)

    replace_parser = subparsers.add_parser("replace", help="Replace text inside one cell.")
    replace_parser.add_argument("notebook")
    replace_parser.add_argument("--cell", type=int, required=True)
    replace_parser.add_argument("--old", required=True)
    replace_parser.add_argument("--new", required=True)
    replace_parser.add_argument("--count", type=int, default=-1)
    replace_parser.add_argument("--keep-outputs", action="store_true")
    replace_parser.set_defaults(func=command_replace)

    write_parser = subparsers.add_parser("write", help="Replace a cell source.")
    write_parser.add_argument("notebook")
    write_parser.add_argument("--cell", type=int, required=True)
    write_parser.add_argument("--source-file")
    write_parser.add_argument("--stdin", action="store_true")
    write_parser.add_argument("--text")
    write_parser.add_argument("--keep-outputs", action="store_true")
    write_parser.set_defaults(func=command_write)

    insert_parser = subparsers.add_parser("insert", help="Insert a new cell.")
    insert_parser.add_argument("notebook")
    insert_parser.add_argument("--before", type=int)
    insert_parser.add_argument("--after", type=int)
    insert_parser.add_argument("--cell-type", choices=["code", "markdown", "raw"], default="code")
    insert_parser.add_argument("--source-file")
    insert_parser.add_argument("--stdin", action="store_true")
    insert_parser.add_argument("--text")
    insert_parser.set_defaults(func=command_insert)

    delete_parser = subparsers.add_parser("delete", help="Delete one cell.")
    delete_parser.add_argument("notebook")
    delete_parser.add_argument("--cell", type=int, required=True)
    delete_parser.set_defaults(func=command_delete)

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
