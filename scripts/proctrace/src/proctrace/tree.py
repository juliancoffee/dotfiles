from __future__ import annotations

from collections import defaultdict, deque

from proctrace.models import ProcessSnapshot, TreeSummary


def _is_system_root_pid(pid: int) -> bool:
    return pid <= 1


def _resolve_parent_key(
    processes: dict[str, ProcessSnapshot],
    pid_to_key: dict[int, str],
    key: str,
) -> str | None:
    snapshot = processes[key]
    ppid = snapshot.info.ppid

    # On macOS, root-style processes like launchd commonly report PPID 0.
    # Treat non-positive and self-parent references as having no parent.
    if ppid is None or ppid <= 0 or ppid == snapshot.info.identity.pid:
        return None

    return pid_to_key.get(ppid)


def attach_relationships(
    processes: dict[str, ProcessSnapshot],
) -> dict[str, ProcessSnapshot]:
    pid_to_key = {snapshot.info.identity.pid: key for key, snapshot in processes.items()}
    children_map: dict[str, list[str]] = defaultdict(list)

    for key, snapshot in processes.items():
        parent_key = _resolve_parent_key(processes, pid_to_key, key)
        snapshot.parent_key = parent_key
        if parent_key is not None:
            children_map[parent_key].append(key)

    for key, snapshot in processes.items():
        snapshot.children_keys = tuple(sorted(children_map.get(key, [])))
        snapshot.root_key = resolve_root_key(processes, key)

    return processes


def resolve_root_key(
    processes: dict[str, ProcessSnapshot], key: str
) -> str:
    current = key
    seen: set[str] = set()

    while True:
        if current in seen:
            return current
        seen.add(current)
        parent_key = processes[current].parent_key
        if parent_key is None or parent_key not in processes:
            return current
        parent_pid = processes[parent_key].info.identity.pid
        if _is_system_root_pid(parent_pid):
            return current
        current = parent_key


def ancestor_chain_keys(
    processes: dict[str, ProcessSnapshot], key: str
) -> tuple[str, ...]:
    chain: list[str] = []
    current: str | None = key
    while current is not None and current in processes:
        chain.append(current)
        current = processes[current].parent_key
    chain.reverse()
    return tuple(chain)


def descendant_keys(
    processes: dict[str, ProcessSnapshot], key: str
) -> tuple[str, ...]:
    queue: deque[str] = deque(processes[key].children_keys)
    descendants: list[str] = []

    while queue:
        current = queue.popleft()
        descendants.append(current)
        queue.extend(processes[current].children_keys)

    return tuple(descendants)


def aggregate_trees(
    processes: dict[str, ProcessSnapshot],
) -> dict[str, TreeSummary]:
    grouped: dict[str, list[ProcessSnapshot]] = defaultdict(list)
    for snapshot in processes.values():
        assert snapshot.root_key is not None
        grouped[snapshot.root_key].append(snapshot)

    trees: dict[str, TreeSummary] = {}
    for root_key, members in grouped.items():
        root = processes[root_key]
        footprints = [
            member.vmmap.physical_footprint_bytes
            for member in members
            if member.vmmap is not None
            and member.vmmap.physical_footprint_bytes is not None
        ]
        residents = [
            member.vmmap.resident_bytes
            for member in members
            if member.vmmap is not None and member.vmmap.resident_bytes is not None
        ]
        swapped = [
            member.vmmap.swapped_bytes
            for member in members
            if member.vmmap is not None and member.vmmap.swapped_bytes is not None
        ]
        vmmap_missing_count = sum(1 for member in members if member.vmmap is None)
        trees[root_key] = TreeSummary(
            root_key=root_key,
            root_pid=root.info.identity.pid,
            root_name=root.info.name,
            process_keys=tuple(sorted(member.info.identity.key for member in members)),
            process_count=len(members),
            cumulative_rss_bytes=sum(member.rss_bytes for member in members),
            cumulative_vms_bytes=sum(member.vms_bytes for member in members),
            cumulative_cpu_user_time_seconds=sum(
                member.cpu_user_time_seconds for member in members
            ),
            cumulative_cpu_system_time_seconds=sum(
                member.cpu_system_time_seconds for member in members
            ),
            cumulative_physical_footprint_bytes=None
            if not footprints
            else sum(footprints),
            cumulative_resident_bytes=None if not residents else sum(residents),
            cumulative_swapped_bytes=None if not swapped else sum(swapped),
            vmmap_missing_count=vmmap_missing_count,
        )

    return trees
