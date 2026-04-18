import json
import subprocess
import sys
from pathlib import Path

NOTEBOOK_TOOL = (
    Path(__file__).resolve().parent.parent
    / "scripts/notebook_tool.py"
)


def write_notebook(path: Path, cells: list[dict]) -> None:
    notebook = {
        "cells": cells,
        "metadata": {},
        "nbformat": 4,
        "nbformat_minor": 5,
    }
    path.write_text(
        json.dumps(notebook, ensure_ascii=False, indent=1) + "\n",
        encoding="utf-8",
    )


def git(cwd: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=cwd,
        capture_output=True,
        text=True,
        check=True,
    )


def run_tool(cwd: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(NOTEBOOK_TOOL), *args],
        cwd=cwd,
        capture_output=True,
        text=True,
        check=True,
    )


def make_repo(tmp_path: Path) -> Path:
    git(tmp_path, "init")
    git(tmp_path, "config", "user.name", "Codex Tests")
    git(tmp_path, "config", "user.email", "codex@example.com")
    return tmp_path


def test_diff_reports_changed_cells_and_per_cell_hunks(tmp_path: Path) -> None:
    repo = make_repo(tmp_path)
    notebook = repo / "demo.ipynb"
    write_notebook(
        notebook,
        [
            {
                "cell_type": "markdown",
                "metadata": {},
                "source": ["# Title\n"],
            },
            {
                "cell_type": "code",
                "metadata": {},
                "execution_count": 1,
                "outputs": [],
                "source": ["print('old')\n"],
            },
        ],
    )
    git(repo, "add", "demo.ipynb")
    git(repo, "commit", "-m", "initial")

    write_notebook(
        notebook,
        [
            {
                "cell_type": "markdown",
                "metadata": {},
                "source": ["# Title\n"],
            },
            {
                "cell_type": "code",
                "metadata": {},
                "execution_count": None,
                "outputs": [],
                "source": ["print('new')\n"],
            },
            {
                "cell_type": "markdown",
                "metadata": {},
                "source": ["## Added\n"],
            },
        ],
    )

    result = run_tool(repo, "diff", "demo.ipynb")

    assert "Changed cells: 2 (HEAD -> working tree)" in result.stdout
    assert "M old=1:code new=1:code print('new')" in result.stdout
    assert "A old=- new=2:markdown ## Added" in result.stdout
    assert "@@ source @@" in result.stdout
    assert "-print('old')" in result.stdout
    assert "+print('new')" in result.stdout
    assert "+++ cell 2 (after)" in result.stdout


def test_diff_can_compare_staged_notebook(tmp_path: Path) -> None:
    repo = make_repo(tmp_path)
    notebook = repo / "demo.ipynb"
    write_notebook(
        notebook,
        [
            {
                "cell_type": "code",
                "metadata": {},
                "execution_count": 1,
                "outputs": [],
                "source": ["value = 1\n"],
            }
        ],
    )
    git(repo, "add", "demo.ipynb")
    git(repo, "commit", "-m", "initial")

    write_notebook(
        notebook,
        [
            {
                "cell_type": "code",
                "metadata": {},
                "execution_count": None,
                "outputs": [],
                "source": ["value = 2\n"],
            }
        ],
    )
    git(repo, "add", "demo.ipynb")

    result = run_tool(repo, "diff", "demo.ipynb", "--staged")

    assert "Changed cells: 1 (HEAD -> index)" in result.stdout
    assert "-value = 1" in result.stdout
    assert "+value = 2" in result.stdout


def test_diff_json_reports_changed_cells_and_sections(tmp_path: Path) -> None:
    repo = make_repo(tmp_path)
    notebook = repo / "demo.ipynb"
    write_notebook(
        notebook,
        [
            {
                "cell_type": "code",
                "metadata": {"tag": "before"},
                "execution_count": 1,
                "outputs": [{"output_type": "stream", "text": ["old\n"]}],
                "source": ["value = 1\n"],
            }
        ],
    )
    git(repo, "add", "demo.ipynb")
    git(repo, "commit", "-m", "initial")

    write_notebook(
        notebook,
        [
            {
                "cell_type": "code",
                "metadata": {"tag": "after"},
                "execution_count": 2,
                "outputs": [{"output_type": "stream", "text": ["new\n"]}],
                "source": ["value = 2\n"],
            }
        ],
    )

    result = run_tool(
        repo,
        "diff",
        "demo.ipynb",
        "--json",
        "--metadata",
        "--outputs",
    )
    payload = json.loads(result.stdout)

    assert payload["base"] == "HEAD"
    assert payload["target"] == "working tree"
    assert payload["changed_cells_count"] == 1

    changed_cell = payload["changed_cells"][0]
    assert changed_cell["status"] == "M"
    assert changed_cell["old_index"] == 0
    assert changed_cell["new_index"] == 0

    sections = {section["label"]: section for section in changed_cell["sections"]}
    assert sections["source"]["changed"] is True
    assert "-value = 1" in sections["source"]["diff"]
    assert "+value = 2" in sections["source"]["diff"]
    assert sections["metadata"]["changed"] is True
    assert '"before"' in sections["metadata"]["diff"]
    assert '"after"' in sections["metadata"]["diff"]
    assert sections["outputs"]["changed"] is True
    assert '"execution_count": 1' in sections["outputs"]["diff"]
    assert '"execution_count": 2' in sections["outputs"]["diff"]


def test_diff_cell_filters_text_output_to_one_changed_cell(tmp_path: Path) -> None:
    repo = make_repo(tmp_path)
    notebook = repo / "demo.ipynb"
    write_notebook(
        notebook,
        [
            {
                "cell_type": "markdown",
                "metadata": {},
                "source": ["# One\n"],
            },
            {
                "cell_type": "code",
                "metadata": {},
                "execution_count": 1,
                "outputs": [],
                "source": ["value = 1\n"],
            },
        ],
    )
    git(repo, "add", "demo.ipynb")
    git(repo, "commit", "-m", "initial")

    write_notebook(
        notebook,
        [
            {
                "cell_type": "markdown",
                "metadata": {},
                "source": ["# One changed\n"],
            },
            {
                "cell_type": "code",
                "metadata": {},
                "execution_count": None,
                "outputs": [],
                "source": ["value = 2\n"],
            },
        ],
    )

    result = run_tool(repo, "diff", "demo.ipynb", "--cell", "1")

    assert "Changed cells: 1 (HEAD -> working tree)" in result.stdout
    assert "M old=1:code new=1:code value = 2" in result.stdout
    assert "M old=0:markdown new=0:markdown # One changed" not in result.stdout
    assert "-value = 1" in result.stdout
    assert "+value = 2" in result.stdout


def test_diff_cell_filters_json_output_to_one_changed_cell(tmp_path: Path) -> None:
    repo = make_repo(tmp_path)
    notebook = repo / "demo.ipynb"
    write_notebook(
        notebook,
        [
            {
                "cell_type": "markdown",
                "metadata": {},
                "source": ["# One\n"],
            },
            {
                "cell_type": "code",
                "metadata": {},
                "execution_count": 1,
                "outputs": [],
                "source": ["value = 1\n"],
            },
        ],
    )
    git(repo, "add", "demo.ipynb")
    git(repo, "commit", "-m", "initial")

    write_notebook(
        notebook,
        [
            {
                "cell_type": "markdown",
                "metadata": {},
                "source": ["# One changed\n"],
            },
            {
                "cell_type": "code",
                "metadata": {},
                "execution_count": None,
                "outputs": [],
                "source": ["value = 2\n"],
            },
        ],
    )

    result = run_tool(repo, "diff", "demo.ipynb", "--json", "--cell", "1")
    payload = json.loads(result.stdout)

    assert payload["requested_cell"] == 1
    assert payload["changed_cells_count"] == 1
    assert len(payload["changed_cells"]) == 1
    assert payload["changed_cells"][0]["new_index"] == 1
    assert "value = 2" in payload["changed_cells"][0]["preview"]
