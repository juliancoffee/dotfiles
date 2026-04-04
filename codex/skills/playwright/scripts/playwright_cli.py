#!/usr/bin/env python3

import contextlib
import json
import os
import platform
import shutil
import signal
import subprocess
import sys
import time
from pathlib import Path


def parse_session_and_command(
    args: list[str],
) -> tuple[bool, str | None, str | None]:
    has_session_flag = False
    session_name = os.environ.get("PLAYWRIGHT_CLI_SESSION")
    command_name = None
    expect_session_value = False

    for arg in args:
        if expect_session_value:
            has_session_flag = True
            session_name = arg
            expect_session_value = False
            continue

        if arg == "--session":
            has_session_flag = True
            expect_session_value = True
            continue

        if arg.startswith("--session="):
            has_session_flag = True
            session_name = arg.split("=", 1)[1]
            continue

        if not arg.startswith("-") and command_name is None:
            command_name = arg

    return has_session_flag, session_name, command_name


def daemon_base_dir() -> Path | None:
    override = os.environ.get("PLAYWRIGHT_DAEMON_SESSION_DIR")
    if override:
        return Path(override)

    system_name = platform.system()
    if system_name == "Darwin":
        return Path.home() / "Library" / "Caches" / "ms-playwright" / "daemon"
    if system_name == "Linux":
        cache_root_env = os.environ.get("XDG_CACHE_HOME")
        cache_root = (
            Path(cache_root_env) if cache_root_env else Path.home() / ".cache"
        )
        return cache_root / "ms-playwright" / "daemon"
    return None


def run_ps() -> list[tuple[int, str]]:
    completed = subprocess.run(
        ["ps", "-axo", "pid=,command="],
        capture_output=True,
        text=True,
        check=False,
    )
    results: list[tuple[int, str]] = []
    for line in completed.stdout.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        parts = stripped.split(None, 1)
        if len(parts) != 2:  # noqa: PLR2004
            continue
        try:
            pid = int(parts[0])
        except ValueError:
            continue
        results.append((pid, parts[1]))
    return results


def find_daemon_pids(session_name: str) -> list[int]:
    suffix = f"cli-daemon/program.js {session_name}"
    return [pid for pid, cmd in run_ps() if cmd.endswith(suffix)]


def find_process_pids_by_substring(needle: str) -> list[int]:
    return [pid for pid, cmd in run_ps() if needle in cmd]


def is_alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def kill_pids(pids: list[int], sig: int) -> None:
    for pid in pids:
        with contextlib.suppress(OSError):
            os.kill(pid, sig)


def first_session_file(base_dir: Path | None, session_name: str) -> Path | None:
    if base_dir is None or not base_dir.exists():
        return None
    for path in base_dir.rglob(f"{session_name}.session"):
        if path.is_file():
            return path
    return None


def read_session_metadata(session_file: Path | None) -> tuple[str, str]:
    if session_file is None:
        return "", ""
    try:
        data = json.loads(session_file.read_text())
    except (OSError, json.JSONDecodeError):
        return "", ""
    socket_path = str(data.get("socketPath") or "")
    browser = data.get("browser") or {}
    user_data_dir = str(browser.get("userDataDir") or "")
    return socket_path, user_data_dir


def force_close_session(session_name: str) -> bool:
    session_file = first_session_file(daemon_base_dir(), session_name)
    socket_path, user_data_dir = read_session_metadata(session_file)
    daemon_pids = find_daemon_pids(session_name)

    # Try a polite shutdown first, then escalate if the daemon is still alive.
    kill_pids(daemon_pids, signal.SIGTERM)
    time.sleep(0.2)
    kill_pids([pid for pid in daemon_pids if is_alive(pid)], signal.SIGKILL)

    # Browser helpers are tied to the user data dir, so this stays session-specific.
    if user_data_dir:
        kill_pids(find_process_pids_by_substring(user_data_dir), signal.SIGTERM)
        time.sleep(0.1)
        kill_pids(
            [
                pid
                for pid in find_process_pids_by_substring(user_data_dir)
                if is_alive(pid)
            ],
            signal.SIGKILL,
        )

    if socket_path:
        with contextlib.suppress(OSError):
            Path(socket_path).unlink()

    if session_file is not None:
        with contextlib.suppress(OSError):
            session_file.unlink()

    return not find_daemon_pids(session_name)


def main() -> int:
    args = sys.argv[1:]
    has_session_flag, session_name, command_name = parse_session_and_command(
        args
    )

    if shutil.which("npx") is None:
        print("Error: npx is required but not found on PATH.", file=sys.stderr)
        return 1

    cmd = ["npx", "--yes", "--package", "@playwright/cli", "playwright-cli"]
    if not has_session_flag and session_name:
        cmd.extend(["--session", session_name])
    cmd.extend(args)

    completed = subprocess.run(cmd, check=False)
    if command_name == "close" and session_name:
        remaining_daemons = find_daemon_pids(session_name)
        if completed.returncode != 0 or remaining_daemons:
            print(
                f"Warning: playwright-cli close did not fully stop session "
                f"'{session_name}'; forcing targeted cleanup.",
                file=sys.stderr,
            )
            if force_close_session(session_name):
                return 0
    return completed.returncode


if __name__ == "__main__":
    raise SystemExit(main())
