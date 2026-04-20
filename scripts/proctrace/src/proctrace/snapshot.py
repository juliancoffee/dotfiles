from __future__ import annotations

import platform
import socket
from concurrent.futures import ThreadPoolExecutor
from datetime import UTC, datetime

from proctrace.backends import PsutilBackend, VmmapBackend
from proctrace.models import (
    FocusSnapshot,
    ProcessSnapshot,
    SnapshotConfig,
    SystemMetadata,
    SystemSnapshot,
    VmmapMode,
)
from proctrace.report import build_rankings
from proctrace.tree import (
    aggregate_trees,
    ancestor_chain_keys,
    attach_relationships,
    descendant_keys,
)


class SnapshotError(RuntimeError):
    pass


def capture_system_snapshot(
    config: SnapshotConfig,
    *,
    process_backend: PsutilBackend | None = None,
    vmmap_backend: VmmapBackend | None = None,
    command_name: str = "snapshot system",
) -> SystemSnapshot:
    process_backend = process_backend or PsutilBackend()
    vmmap_backend = vmmap_backend or VmmapBackend()

    processes = process_backend.capture_processes()
    attach_relationships(processes)
    _apply_vmmap(processes, config, vmmap_backend)
    trees = aggregate_trees(processes)
    snapshot = SystemSnapshot(
        system=_system_metadata(command_name),
        config=config,
        processes=processes,
        trees=trees,
        rankings={},
    )
    snapshot.rankings = build_rankings(snapshot)
    snapshot.notes.extend(_vmmap_notes(processes))
    return snapshot


def capture_pid_snapshot(
    pid: int,
    config: SnapshotConfig,
    *,
    process_backend: PsutilBackend | None = None,
    vmmap_backend: VmmapBackend | None = None,
    command_name: str = "snapshot pid",
) -> SystemSnapshot:
    process_backend = process_backend or PsutilBackend()
    vmmap_backend = vmmap_backend or VmmapBackend()

    processes = process_backend.capture_processes()
    attach_relationships(processes)

    target_key = _find_process_key_by_pid(processes, pid)
    if target_key is None:
        raise SnapshotError(f"PID {pid} not found")

    root_key = processes[target_key].root_key
    assert root_key is not None
    full_ancestor_chain = ancestor_chain_keys(processes, target_key)
    tree_keys = {
        key
        for key, process in processes.items()
        if process.root_key == root_key
    }
    relevant_keys = tree_keys | set(full_ancestor_chain)
    relevant = {key: processes[key] for key in relevant_keys}
    attach_relationships(relevant)
    _apply_vmmap(relevant, config, vmmap_backend)
    trees = aggregate_trees(relevant)
    focus = FocusSnapshot(
        target_key=target_key,
        root_key=root_key,
        ancestor_chain_keys=full_ancestor_chain,
        descendant_keys=descendant_keys(relevant, target_key),
        root_tree_process_keys=tuple(sorted(tree_keys)),
    )
    snapshot = SystemSnapshot(
        system=_system_metadata(f"{command_name} {pid}"),
        config=config,
        processes=relevant,
        trees=trees,
        rankings={},
        focus=focus,
    )
    snapshot.rankings = build_rankings(snapshot)
    snapshot.notes.extend(_vmmap_notes(relevant))
    return snapshot


def _system_metadata(command_name: str) -> SystemMetadata:
    return SystemMetadata(
        captured_at_utc=datetime.now(UTC).isoformat(),
        hostname=socket.gethostname(),
        platform=platform.platform(),
        command=command_name,
    )


def _find_process_key_by_pid(
    processes: dict[str, ProcessSnapshot], pid: int
) -> str | None:
    for key, process in processes.items():
        if process.info.identity.pid == pid:
            return key
    return None


def _apply_vmmap(
    processes: dict[str, ProcessSnapshot],
    config: SnapshotConfig,
    vmmap_backend: VmmapBackend,
) -> None:
    if config.vmmap_mode is VmmapMode.NONE:
        return

    target_keys = _select_vmmap_targets(processes, config)

    def enrich(key: str) -> tuple[str, object]:
        summary = vmmap_backend.capture(
            processes[key].info.identity.pid,
            timeout_seconds=config.vmmap_timeout_seconds,
        )
        return key, summary

    workers = max(1, config.vmmap_workers)
    with ThreadPoolExecutor(max_workers=workers) as executor:
        for key, summary in executor.map(enrich, target_keys):
            processes[key].vmmap = summary


def _select_vmmap_targets(
    processes: dict[str, ProcessSnapshot], config: SnapshotConfig
) -> list[str]:
    if config.vmmap_mode is VmmapMode.TOP:
        ranked = sorted(
            processes.values(),
            key=lambda item: item.rss_bytes,
            reverse=True,
        )[: config.top_n]
        return [item.info.identity.key for item in ranked]

    return []


def _vmmap_notes(processes: dict[str, ProcessSnapshot]) -> list[str]:
    notes = []
    failed = [
        process
        for process in processes.values()
        if process.vmmap is not None and process.vmmap.error is not None
    ]
    if failed:
        notes.append(f"vmmap failed for {len(failed)} process(es)")
    return notes
