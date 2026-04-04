#!/usr/bin/env python3

import argparse
import os
import shlex
import subprocess
import sys
from pathlib import Path
from urllib.parse import urlparse


SCRIPT_DIR = Path(__file__).resolve().parent
PWCLI_PATH = SCRIPT_DIR / "playwright_cli.py"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Capture a screenshot through playwright-cli without depending on "
            "any runtime other than npx @playwright/cli."
        )
    )
    parser.add_argument(
        "target",
        help="URL or local file path to open before capturing.",
    )
    parser.add_argument(
        "-o",
        "--output",
        help=(
            "Output image path. Defaults to /tmp/playwright/<session>.png. "
            "Relative paths are rooted under /tmp."
        ),
    )
    parser.add_argument(
        "--session",
        help="Optional session name. Must be 16 characters or fewer.",
    )
    parser.add_argument(
        "--browser",
        choices=("chrome", "firefox", "webkit", "msedge"),
        help="Browser/channel to pass through to playwright-cli open.",
    )
    parser.add_argument(
        "--selector",
        help="Optional selector or snapshot ref to pass to screenshot.",
    )
    parser.add_argument(
        "--delay-ms",
        type=int,
        default=0,
        help="Optional wait after open before capture.",
    )
    parser.add_argument(
        "--full-page",
        action="store_true",
        help="Capture the full scrollable page.",
    )
    parser.add_argument(
        "--headed",
        action="store_true",
        help="Open the browser in headed mode.",
    )
    parser.add_argument(
        "--config",
        help="Optional playwright-cli config path for the open command.",
    )
    parser.add_argument(
        "--print-commands",
        action="store_true",
        help="Print the underlying playwright-cli commands before running.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the commands that would run and exit.",
    )
    return parser


def is_url(value: str) -> bool:
    parsed = urlparse(value)
    return bool(parsed.scheme and parsed.netloc) or parsed.scheme in {
        "about",
        "data",
        "file",
    }


def normalize_target(target: str) -> str:
    if is_url(target):
        return target
    return Path(target).expanduser().resolve().as_uri()


def validate_args(args: argparse.Namespace) -> None:
    if args.session and len(args.session) > 16:
        raise SystemExit("--session must be 16 characters or fewer")
    if args.delay_ms < 0:
        raise SystemExit("--delay-ms must be 0 or greater")


def derive_session(target: str) -> str:
    parsed = urlparse(target)
    if parsed.scheme == "file":
        stem = Path(parsed.path).stem or "shot"
    else:
        host = parsed.netloc.split(":", 1)[0]
        stem = host.split(".", 1)[0] if host else "shot"

    safe = "".join(ch for ch in stem.lower() if ch.isalnum()) or "shot"
    return f"{safe[:9]}-{os.getpid() % 1000000:06d}"[:16]


def resolve_output_path(args: argparse.Namespace, session: str) -> Path:
    if args.output:
        candidate = Path(args.output).expanduser()
        if candidate.is_absolute():
            return Path(os.path.realpath(candidate))
        return Path(os.path.realpath(Path("/tmp") / candidate))

    return Path(os.path.realpath(Path("/tmp/playwright") / f"{session}.png"))


def build_commands(
    args: argparse.Namespace,
) -> tuple[list[list[str]], Path, Path]:
    target = normalize_target(args.target)
    session = args.session or derive_session(target)
    output_path = resolve_output_path(args, session)
    workspace_dir = output_path.parent
    base = [sys.executable, str(PWCLI_PATH), "--session", session]

    open_cmd = [*base, "open", target]
    if args.browser:
        open_cmd.extend(["--browser", args.browser])
    if args.headed:
        open_cmd.append("--headed")
    if args.config:
        open_cmd.extend(["--config", args.config])

    commands = [open_cmd]
    if args.delay_ms:
        commands.append(
            [
                *base,
                "run-code",
                f"await page.waitForTimeout({args.delay_ms})",
            ]
        )

    screenshot_cmd = [*base, "screenshot"]
    if args.selector:
        screenshot_cmd.append(args.selector)
    screenshot_cmd.extend(["--filename", str(output_path)])
    if args.full_page:
        screenshot_cmd.append("--full-page")
    commands.append(screenshot_cmd)
    commands.append([*base, "close"])
    return commands, workspace_dir, output_path


def render_command(command: list[str]) -> str:
    return shlex.join(command)


def run_command(command: list[str], cwd: Path) -> int:
    completed = subprocess.run(command, check=False, cwd=str(cwd))
    return completed.returncode


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    validate_args(args)
    commands, workspace_dir, output_path = build_commands(args)

    if args.print_commands or args.dry_run:
        print(f"# cwd: {workspace_dir}")
        for command in commands:
            print(render_command(command))
    if args.dry_run:
        return 0

    workspace_dir.mkdir(parents=True, exist_ok=True)

    open_ok = False
    for index, command in enumerate(commands):
        return_code = run_command(command, workspace_dir)
        if index == 0 and return_code == 0:
            open_ok = True
        if return_code != 0:
            if open_ok and command[-1] != "close":
                run_command(commands[-1], workspace_dir)
            return return_code
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
