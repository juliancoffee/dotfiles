from __future__ import annotations

import argparse
from pathlib import Path

from proctrace.models import SnapshotConfig, VmmapMode
from proctrace.report import (
    render_focus_text,
    render_system_text,
    snapshot_to_json,
    write_json_report,
)
from proctrace.snapshot import (
    SnapshotError,
    capture_pid_snapshot,
    capture_system_snapshot,
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="proctrace",
        description="Snapshot-first macOS process explorer",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    snapshot = subparsers.add_parser("snapshot", help="Capture process snapshots")
    snapshot_subparsers = snapshot.add_subparsers(
        dest="snapshot_command", required=True
    )

    common_parent = argparse.ArgumentParser(add_help=False)
    common_parent.add_argument(
        "--json-out",
        type=Path,
        help="Write the full structured report to a JSON file",
    )
    common_parent.add_argument(
        "--pretty-json",
        action="store_true",
        help="Pretty-print JSON output",
    )
    common_parent.add_argument(
        "--vmmap-mode",
        choices=[mode.value for mode in VmmapMode],
        default=VmmapMode.TOP.value,
        help="How aggressively to enrich with vmmap; top samples one vmmap subprocess per selected PID (default: top)",
    )
    common_parent.add_argument(
        "--top-n",
        type=int,
        default=20,
        help="How many trees to show, and how many PIDs to sample with vmmap in top mode (default: 20)",
    )

    snapshot_subparsers.add_parser(
        "system",
        parents=[common_parent],
        help="Capture the full current process graph",
    )
    pid_parser = snapshot_subparsers.add_parser(
        "pid",
        parents=[common_parent],
        help="Capture one PID and its subtree",
    )
    pid_parser.add_argument("pid", type=int)
    snapshot_subparsers.add_parser(
        "top",
        parents=[common_parent],
        help="Capture the system and print the heaviest trees",
    )

    return parser


def snapshot_config_from_args(args: argparse.Namespace) -> SnapshotConfig:
    return SnapshotConfig(
        vmmap_mode=VmmapMode(args.vmmap_mode),
        top_n=args.top_n,
    )


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    config = snapshot_config_from_args(args)

    try:
        if args.snapshot_command == "system":
            snapshot = capture_system_snapshot(config)
            print(render_system_text(snapshot))
        elif args.snapshot_command == "top":
            snapshot = capture_system_snapshot(config, command_name="snapshot top")
            print(render_system_text(snapshot))
        elif args.snapshot_command == "pid":
            snapshot = capture_pid_snapshot(args.pid, config)
            print(render_focus_text(snapshot))
        else:
            raise SnapshotError("unsupported command")
    except SnapshotError as exc:
        raise SystemExit(str(exc)) from exc

    if args.json_out is not None:
        write_json_report(snapshot, args.json_out, pretty=args.pretty_json)
    elif args.pretty_json:
        print(snapshot_to_json(snapshot, pretty=True))
