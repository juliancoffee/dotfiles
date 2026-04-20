from __future__ import annotations

import json
from dataclasses import asdict, is_dataclass
from pathlib import Path
from typing import Any

from proctrace.models import (
    ProcessIdentity,
    ProcessSnapshot,
    RankingEntry,
    SystemSnapshot,
    TreeSummary,
)


def build_rankings(
    snapshot: SystemSnapshot,
) -> dict[str, list[RankingEntry]]:
    processes = list(snapshot.processes.values())
    trees = list(snapshot.trees.values())

    def proc_label(snapshot_key: str) -> str:
        process = snapshot.processes[snapshot_key]
        return f"{process.info.name} [{process.info.identity.pid}]"

    rankings = {
        "processes_by_rss": [
            RankingEntry(
                kind="process",
                key=process.info.identity.key,
                label=proc_label(process.info.identity.key),
                metric="rss_bytes",
                value=process.rss_bytes,
            )
            for process in sorted(
                processes,
                key=lambda item: item.rss_bytes,
                reverse=True,
            )[: snapshot.config.top_n]
        ],
        "processes_by_physical_footprint": [
            RankingEntry(
                kind="process",
                key=process.info.identity.key,
                label=proc_label(process.info.identity.key),
                metric="physical_footprint_bytes",
                value=None
                if process.vmmap is None
                else process.vmmap.physical_footprint_bytes,
            )
            for process in sorted(
                processes,
                key=lambda item: -1
                if item.vmmap is None
                or item.vmmap.physical_footprint_bytes is None
                else item.vmmap.physical_footprint_bytes,
                reverse=True,
            )[: snapshot.config.top_n]
        ],
        "processes_by_swapped_bytes": [
            RankingEntry(
                kind="process",
                key=process.info.identity.key,
                label=proc_label(process.info.identity.key),
                metric="swapped_bytes",
                value=None
                if process.vmmap is None
                else process.vmmap.swapped_bytes,
            )
            for process in sorted(
                processes,
                key=lambda item: -1
                if item.vmmap is None or item.vmmap.swapped_bytes is None
                else item.vmmap.swapped_bytes,
                reverse=True,
            )[: snapshot.config.top_n]
        ],
        "trees_by_rss": _tree_rankings(
            trees, "cumulative_rss_bytes", snapshot.config.top_n
        ),
        "trees_by_physical_footprint": _tree_rankings(
            trees,
            "cumulative_physical_footprint_bytes",
            snapshot.config.top_n,
        ),
        "trees_by_swapped_bytes": _tree_rankings(
            trees, "cumulative_swapped_bytes", snapshot.config.top_n
        ),
    }
    return rankings


def _tree_rankings(
    trees: list[TreeSummary], metric: str, top_n: int
) -> list[RankingEntry]:
    ranked = sorted(
        trees,
        key=lambda item: -1 if getattr(item, metric) is None else getattr(item, metric),
        reverse=True,
    )[:top_n]
    return [
        RankingEntry(
            kind="tree",
            key=tree.root_key,
            label=f"{tree.root_name} [{tree.root_pid}]",
            metric=metric,
            value=getattr(tree, metric),
        )
        for tree in ranked
    ]


def to_jsonable(value: Any) -> Any:
    if isinstance(value, ProcessIdentity):
        return {
            "pid": value.pid,
            "create_time": value.create_time,
            "key": value.key,
        }
    if is_dataclass(value):
        return {key: to_jsonable(val) for key, val in asdict(value).items()}
    if isinstance(value, dict):
        return {key: to_jsonable(val) for key, val in value.items()}
    if isinstance(value, (list, tuple)):
        return [to_jsonable(item) for item in value]
    return value


def snapshot_to_json(snapshot: SystemSnapshot, *, pretty: bool) -> str:
    data = to_jsonable(snapshot)
    if pretty:
        return json.dumps(data, indent=2, sort_keys=True)
    return json.dumps(data, separators=(",", ":"), sort_keys=True)


def write_json_report(
    snapshot: SystemSnapshot, output_path: Path, *, pretty: bool
) -> None:
    output_path.write_text(snapshot_to_json(snapshot, pretty=pretty) + "\n")


def format_bytes(value: int | float | None) -> str:
    if value is None:
        return "n/a"

    size = float(value)
    suffixes = ["B", "KiB", "MiB", "GiB", "TiB"]
    index = 0
    while size >= 1024 and index < len(suffixes) - 1:
        size /= 1024
        index += 1
    if index == 0:
        return f"{int(size)} {suffixes[index]}"
    return f"{size:.1f} {suffixes[index]}"


def format_top_table(entries: list[RankingEntry]) -> str:
    lines = []
    for idx, entry in enumerate(entries, start=1):
        metric = (
            format_bytes(entry.value)
            if entry.metric.endswith("_bytes")
            else str(entry.value)
        )
        lines.append(f"{idx:>2}. {entry.label:<28} {metric}")
    return "\n".join(lines)


def _process_swap_bytes(process: ProcessSnapshot) -> int | None:
    if process.vmmap is None:
        return None
    return process.vmmap.swapped_bytes


def _process_combined_memory_bytes(process: ProcessSnapshot) -> int:
    swap_bytes = _process_swap_bytes(process)
    return process.rss_bytes + (0 if swap_bytes is None else swap_bytes)


def _tree_combined_memory_bytes(tree: TreeSummary) -> int:
    return tree.cumulative_rss_bytes + (
        0 if tree.cumulative_swapped_bytes is None else tree.cumulative_swapped_bytes
    )


def _format_process_total(process: ProcessSnapshot) -> str:
    suffix = "+" if _process_swap_bytes(process) is None else ""
    return f"{format_bytes(_process_combined_memory_bytes(process))}{suffix}"


def _format_tree_total(tree: TreeSummary) -> str:
    suffix = "+" if tree.vmmap_missing_count > 0 else ""
    return f"{format_bytes(_tree_combined_memory_bytes(tree))}{suffix}"


def _subtree_combined_memory_bytes(
    snapshot: SystemSnapshot, key: str, cache: dict[str, int]
) -> int:
    cached = cache.get(key)
    if cached is not None:
        return cached

    process = snapshot.processes[key]
    total = _process_combined_memory_bytes(process)
    for child_key in process.children_keys:
        if child_key not in snapshot.processes:
            continue
        total += _subtree_combined_memory_bytes(snapshot, child_key, cache)

    cache[key] = total
    return total


def _render_process_branch(
    snapshot: SystemSnapshot,
    key: str,
    prefix: str,
    *,
    is_last: bool,
    subtree_cache: dict[str, int],
) -> list[str]:
    process = snapshot.processes[key]
    connector = "`- " if is_last else "|- "
    lines = [
        (
            f"{prefix}{connector}{process.info.name} [{process.info.identity.pid}] "
            f"total={_format_process_total(process)} "
            f"rss={format_bytes(process.rss_bytes)} "
            f"swap={format_bytes(_process_swap_bytes(process))}"
        )
    ]

    child_keys = [child for child in process.children_keys if child in snapshot.processes]
    child_keys.sort(
        key=lambda child_key: (
            _subtree_combined_memory_bytes(snapshot, child_key, subtree_cache),
            snapshot.processes[child_key].rss_bytes,
            snapshot.processes[child_key].info.identity.pid,
        ),
        reverse=True,
    )

    child_prefix = f"{prefix}{'   ' if is_last else '|  '}"
    for index, child_key in enumerate(child_keys):
        lines.extend(
            _render_process_branch(
                snapshot,
                child_key,
                child_prefix,
                is_last=index == len(child_keys) - 1,
                subtree_cache=subtree_cache,
            )
        )
    return lines


def render_system_text(snapshot: SystemSnapshot) -> str:
    ranked_trees = sorted(
        snapshot.trees.values(),
        key=_tree_combined_memory_bytes,
        reverse=True,
    )[: snapshot.config.top_n]
    subtree_cache: dict[str, int] = {}

    lines = [
        f"Snapshot: {snapshot.system.command}",
        f"Captured: {snapshot.system.captured_at_utc}",
        f"Processes: {len(snapshot.processes)}",
        f"Trees: {len(snapshot.trees)}",
        "",
        "Trees by rss + swap",
        "Note: '+' means swap is missing, so the total is a lower bound.",
    ]
    for idx, tree in enumerate(ranked_trees, start=1):
        root = snapshot.processes[tree.root_key]
        lines.extend(
            [
                "",
                (
                    f"{idx:>2}. {tree.root_name} [{tree.root_pid}] "
                    f"tree={_format_tree_total(tree)} "
                    f"rss={format_bytes(tree.cumulative_rss_bytes)} "
                    f"swap={format_bytes(tree.cumulative_swapped_bytes)} "
                    f"procs={tree.process_count}"
                ),
                (
                    f"   {root.info.name} [{root.info.identity.pid}] "
                    f"total={_format_process_total(root)} "
                    f"rss={format_bytes(root.rss_bytes)} "
                    f"swap={format_bytes(_process_swap_bytes(root))}"
                ),
            ]
        )
        child_keys = [child for child in root.children_keys if child in snapshot.processes]
        child_keys.sort(
            key=lambda child_key: (
                _subtree_combined_memory_bytes(snapshot, child_key, subtree_cache),
                snapshot.processes[child_key].rss_bytes,
                snapshot.processes[child_key].info.identity.pid,
            ),
            reverse=True,
        )
        for child_index, child_key in enumerate(child_keys):
            lines.extend(
                _render_process_branch(
                    snapshot,
                    child_key,
                    "   ",
                    is_last=child_index == len(child_keys) - 1,
                    subtree_cache=subtree_cache,
                )
            )
    if snapshot.notes:
        lines.extend(["", "Notes", *snapshot.notes])
    return "\n".join(lines)


def render_focus_text(snapshot: SystemSnapshot) -> str:
    assert snapshot.focus is not None
    focus = snapshot.focus
    target = snapshot.processes[focus.target_key]
    root_tree = snapshot.trees[focus.root_key]

    ancestor_lines = []
    for key in focus.ancestor_chain_keys:
        process = snapshot.processes[key]
        ancestor_lines.append(
            f"- {process.info.name} [{process.info.identity.pid}]"
        )

    descendant_entries = [
        snapshot.processes[key] for key in focus.descendant_keys
    ]
    descendant_entries.sort(
        key=lambda item: -1
        if item.vmmap is None or item.vmmap.swapped_bytes is None
        else item.vmmap.swapped_bytes,
        reverse=True,
    )
    descendant_lines = [
        f"- {entry.info.name} [{entry.info.identity.pid}] "
        f"swap={format_bytes(None if entry.vmmap is None else entry.vmmap.swapped_bytes)} "
        f"rss={format_bytes(entry.rss_bytes)}"
        for entry in descendant_entries[:10]
    ]

    return "\n".join(
        [
            f"Focused PID: {target.info.identity.pid}",
            f"Target: {target.info.name}",
            f"Root tree: {root_tree.root_name} [{root_tree.root_pid}]",
            f"Tree swap: {format_bytes(root_tree.cumulative_swapped_bytes)}",
            f"Tree footprint: {format_bytes(root_tree.cumulative_physical_footprint_bytes)}",
            "",
            "Ancestor chain",
            *ancestor_lines,
            "",
            "Top descendants by swapped bytes",
            *descendant_lines,
        ]
    )
