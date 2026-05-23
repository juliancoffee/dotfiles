#!/usr/bin/env python3
"""Install the bundled `dstu-report` Typst package into Typst's local packages."""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tomllib
from pathlib import Path


def fail(message: str) -> "NoReturn":
    print(message, file=sys.stderr)
    raise SystemExit(1)


def read_manifest(package_dir: Path) -> tuple[str, str]:
    manifest_path = package_dir / "typst.toml"
    if not manifest_path.is_file():
        fail(f"package manifest not found at {manifest_path}")

    manifest = tomllib.loads(manifest_path.read_text(encoding="utf-8"))
    package_name = manifest.get("package", {}).get("name")
    package_version = manifest.get("package", {}).get("version")
    if not isinstance(package_name, str) or not isinstance(package_version, str):
        fail(f"failed to read package name/version from {manifest_path}")
    return package_name, package_version


def read_typst_package_root() -> Path:
    try:
        result = subprocess.run(
            ["typst", "info", "--format", "json"],
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        fail("typst is required but was not found in PATH")
    except subprocess.CalledProcessError as error:
        fail(f"failed to query Typst package info: {error.stderr or error.stdout}")

    try:
        info = json.loads(result.stdout)
        package_path = info["packages"]["package-path"]
    except (json.JSONDecodeError, KeyError, TypeError):
        fail("failed to determine Typst package path from `typst info --format json`")

    if not isinstance(package_path, str) or not package_path:
        fail("Typst reported an empty package path")
    return Path(package_path)


def main() -> None:
    script_dir = Path(__file__).resolve().parent
    skill_dir = script_dir.parent
    package_dir = skill_dir / "assets" / "package"

    package_name, package_version = read_manifest(package_dir)
    package_root = read_typst_package_root()
    target_dir = package_root / "local" / package_name / package_version

    target_dir.parent.mkdir(parents=True, exist_ok=True)
    if target_dir.exists():
        shutil.rmtree(target_dir)
    shutil.copytree(package_dir, target_dir)

    print("Installed local Typst package:")
    print(f"  source: {package_dir}")
    print(f"  target: {target_dir}")
    print()
    print("Use it from projects as:")
    print(f'  #import "@local/{package_name}:{package_version}": template')


if __name__ == "__main__":
    main()
