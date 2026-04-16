#!/usr/bin/env python3
"""Install a skill from a local directory into $AGENTS_HOME/skills."""

from __future__ import annotations

import argparse
import os
import shutil
import sys


class InstallError(Exception):
    """Raised when local skill installation cannot be completed."""


class Args(argparse.Namespace):
    """Parsed command-line arguments for local skill installation."""

    local_path: str
    dest: str | None
    name: str | None


def _agents_home() -> str:
    """Return the configured agents home directory."""
    return os.environ.get("AGENTS_HOME", os.path.expanduser("~/.agents"))


def _default_dest() -> str:
    """Return the default skills installation root."""
    return os.path.join(_agents_home(), "skills")


def _validate_skill_name(name: str) -> None:
    """Ensure the destination skill name is a single safe path segment."""
    altsep = os.path.altsep
    if not name or os.path.sep in name or (altsep and altsep in name):
        raise InstallError("Skill name must be a single path segment.")
    if name in (".", ".."):
        raise InstallError("Invalid skill name.")


def _resolve_local_path(path: str) -> str:
    """Resolve and validate the source skill directory on disk."""
    resolved = os.path.realpath(os.path.expanduser(path))
    if not os.path.isdir(resolved):
        raise InstallError(f"Local skill path not found: {path}")
    return resolved


def _validate_skill(path: str) -> None:
    """Verify that the source directory looks like a skill."""
    skill_md = os.path.join(path, "SKILL.md")
    if not os.path.isfile(skill_md):
        raise InstallError("SKILL.md not found in selected skill directory.")


def _copy_skill(src: str, dest_dir: str) -> None:
    """Copy a skill directory into the destination root."""
    os.makedirs(os.path.dirname(dest_dir), exist_ok=True)
    if os.path.exists(dest_dir):
        raise InstallError(f"Destination already exists: {dest_dir}")
    shutil.copytree(
        src,
        dest_dir,
        ignore=shutil.ignore_patterns("__pycache__", ".DS_Store", "target"),
    )


def _parse_args(argv: list[str]) -> Args:
    """Parse command-line arguments for local skill installation."""
    parser = argparse.ArgumentParser(description="Install a skill from a local directory.")
    parser.add_argument("local_path", help="Local skill directory to install")
    parser.add_argument(
        "--dest",
        help="Destination skills directory (default: $AGENTS_HOME/skills or ~/.agents/skills)",
    )
    parser.add_argument(
        "--name",
        help="Destination skill name (defaults to the source directory basename)",
    )
    return parser.parse_args(argv, namespace=Args())


def main(argv: list[str]) -> int:
    """Install the requested local skill and report the destination."""
    args = _parse_args(argv)
    try:
        src = _resolve_local_path(args.local_path)
        _validate_skill(src)
        skill_name = args.name or os.path.basename(src.rstrip(os.sep))
        _validate_skill_name(skill_name)
        dest_root = args.dest or _default_dest()
        dest_dir = os.path.join(dest_root, skill_name)
        _copy_skill(src, dest_dir)
        print(f"Installed {skill_name} to {dest_dir}")
        return 0
    except InstallError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
