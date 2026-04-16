#!/usr/bin/env python3
import argparse
import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_notebook(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"notebook not found: {path}")
    except json.JSONDecodeError as exc:
        fail(f"invalid notebook JSON at line {exc.lineno}, column {exc.colno}")


def save_notebook(path: Path, notebook: dict) -> None:
    path.write_text(json.dumps(notebook, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")


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
    parser = argparse.ArgumentParser(description="Read and modify Jupyter notebooks structurally.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    summary_parser = subparsers.add_parser("summary", help="List cells with short previews.")
    summary_parser.add_argument("notebook")
    summary_parser.set_defaults(func=command_summary)

    read_parser = subparsers.add_parser("read", help="Print one cell as JSON.")
    read_parser.add_argument("notebook")
    read_parser.add_argument("--cell", type=int, required=True)
    read_parser.add_argument("--outputs", action="store_true")
    read_parser.set_defaults(func=command_read)

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
