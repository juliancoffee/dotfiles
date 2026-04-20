from __future__ import annotations

from dataclasses import dataclass, field
from enum import StrEnum


class VmmapMode(StrEnum):
    TOP = "top"
    NONE = "none"


@dataclass(frozen=True, order=True, slots=True)
class ProcessIdentity:
    pid: int
    create_time: float

    @property
    def key(self) -> str:
        return f"{self.pid}@{self.create_time:.6f}"


@dataclass(slots=True)
class ProcessInfo:
    identity: ProcessIdentity
    ppid: int | None
    name: str
    exe: str | None
    cmdline: tuple[str, ...]
    status: str | None
    username: str | None
    num_threads: int | None


@dataclass(slots=True)
class VmmapSummary:
    process_name: str | None = None
    physical_footprint_bytes: int | None = None
    resident_bytes: int | None = None
    swapped_bytes: int | None = None
    error: str | None = None


@dataclass(slots=True)
class ProcessSnapshot:
    info: ProcessInfo
    rss_bytes: int
    vms_bytes: int
    cpu_user_time_seconds: float
    cpu_system_time_seconds: float
    parent_key: str | None = None
    root_key: str | None = None
    children_keys: tuple[str, ...] = ()
    vmmap: VmmapSummary | None = None


@dataclass(slots=True)
class TreeSummary:
    root_key: str
    root_pid: int
    root_name: str
    process_keys: tuple[str, ...]
    process_count: int
    cumulative_rss_bytes: int
    cumulative_vms_bytes: int
    cumulative_cpu_user_time_seconds: float
    cumulative_cpu_system_time_seconds: float
    cumulative_physical_footprint_bytes: int | None
    cumulative_resident_bytes: int | None
    cumulative_swapped_bytes: int | None
    vmmap_missing_count: int = 0


@dataclass(slots=True)
class RankingEntry:
    kind: str
    key: str
    label: str
    metric: str
    value: int | float | None


@dataclass(slots=True)
class FocusSnapshot:
    target_key: str
    root_key: str
    ancestor_chain_keys: tuple[str, ...]
    descendant_keys: tuple[str, ...]
    root_tree_process_keys: tuple[str, ...]


@dataclass(slots=True)
class SnapshotConfig:
    vmmap_mode: VmmapMode = VmmapMode.TOP
    top_n: int = 20
    vmmap_timeout_seconds: float = 10.0
    vmmap_workers: int = 4


@dataclass(slots=True)
class SystemMetadata:
    captured_at_utc: str
    hostname: str
    platform: str
    command: str


@dataclass(slots=True)
class SystemSnapshot:
    system: SystemMetadata
    config: SnapshotConfig
    processes: dict[str, ProcessSnapshot]
    trees: dict[str, TreeSummary]
    rankings: dict[str, list[RankingEntry]]
    focus: FocusSnapshot | None = None
    notes: list[str] = field(default_factory=list)
