# Python Project Layouts

Use this note when the project-bootstrap skill is creating a Python project and the user or context suggests there is a choice between:

- packaged `src/` layout
- single-file or flat-root layout

Default rule:

- Prefer single-file layout for most fresh one-off projects, scripts, experiments, and lightweight tools.
- Switch to `src/` layout when the project clearly needs multiple files, reusable packaging boundaries, or library-style structure.

The PyPA guide on why `src/` layout is useful is here:
[src layout vs flat layout](https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/)

## Example: `src/` layout

Real project: `$HOME/Workspace/repos/ron-py`

Relevant tree:

```text
ron-py/
├── LICENSE
├── Makefile
├── README.md
├── Ron.g4
├── main.py
├── pyproject.toml
├── src/
│   └── ron/
│       ├── __init__.py
│       ├── mapper.py
│       ├── models.py
│       ├── parser.py
│       ├── py.typed
│       ├── visitor.py
│       └── _generated/
└── tests/
    ├── test_getitem.py
    ├── test_mapper.py
    ├── test_public.py
    ├── test_simple.py
    └── test_spans.py
```

Relevant `pyproject.toml` excerpt:

```toml
[project]
name = "ron-python"
version = "0.0.5"
requires-python = ">=3.12"

[dependency-groups]
dev = [
    "antlr4-tools>=0.2.2",
    "mypy>=1.19.1",
    "pdoc>=16.0.0",
    "pytest>=9.0.2",
    "rich>=14.3.1",
    "ruff>=0.14.14",
    "types-antlr4-python3-runtime>=4.13.0.20251118",
]

[tool.hatch.build.targets.wheel]
packages = ["src/ron"]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

Why this is a good `src/` example:

- importable package code lives under `src/ron/`
- tests live separately under `tests/`
- Hatch/Hatchling explicitly package `src/ron`
- pytest is present in the dev dependency group

This is the model to follow when the user wants a proper package, a reusable library, or a multi-file Python codebase.

## Example: single-file layout

Real project: `$HOME/Workspace/lab/bencher`

Relevant tree:

```text
bencher/
├── LICENSE
├── README.md
├── fib.py
├── main.py
├── pyproject.toml
└── uv.lock
```

Relevant `pyproject.toml` excerpt:

```toml
[project]
name = "bencher"
version = "0.1.0"
requires-python = ">=3.14"

[project.scripts]
bencher = "main:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["main.py"]
```

Why this is a good single-file example:

- the project entrypoint lives at repo root in `main.py`
- there is no `src/` package tree
- packaging points directly at the single file

This layout is the default when the project is intentionally small or likely to stay lightweight. You can still add pytest and a `tests/` directory around it.

## Decision rule

Choose `src/` layout when:

- the project is a library
- the project will grow beyond one or two files
- clean packaging/import boundaries matter
- the user wants tests, typing, and buildable packaging from the start

Choose single-file layout when:

- the project is a tiny script
- the project is a one-off utility or experiment
- the user explicitly wants minimum ceremony
- the codebase is intentionally small and disposable

If the user did not specify otherwise, prefer the `bencher` style first and move toward the `ron-py` style only when the project shape calls for it.
