from proctrace.models import (
    ProcessIdentity,
    ProcessInfo,
    ProcessSnapshot,
    SnapshotConfig,
    VmmapSummary,
)
from proctrace.snapshot import capture_pid_snapshot, capture_system_snapshot


class FakeProcessBackend:
    def capture_processes(self) -> dict[str, ProcessSnapshot]:
        rows = [
            (1, None, "tmux", 40),
            (2, 1, "zsh", 30),
            (3, 2, "uv", 35),
            (4, 3, "jupyter-lab", 60),
            (5, 4, "basedpyright-langserver", 25),
            (6, 5, "node", 10),
            (10, None, "Firefox", 200),
            (11, 10, "plugin-container", 150),
            (12, 10, "plugin-container", 140),
            (20, None, "Codex", 220),
        ]
        processes = {}
        for pid, ppid, name, rss in rows:
            identity = ProcessIdentity(pid=pid, create_time=float(pid))
            processes[identity.key] = ProcessSnapshot(
                info=ProcessInfo(
                    identity=identity,
                    ppid=ppid,
                    name=name,
                    exe=None,
                    cmdline=(),
                    status=None,
                    username=None,
                    num_threads=None,
                ),
                rss_bytes=rss,
                vms_bytes=rss * 2,
                cpu_user_time_seconds=float(pid),
                cpu_system_time_seconds=float(pid) / 2,
            )
        return processes


class FakeVmmapBackend:
    def __init__(self) -> None:
        self.calls: list[int] = []

    def capture(self, pid: int, *, timeout_seconds: float) -> VmmapSummary:
        del timeout_seconds
        self.calls.append(pid)
        if pid in {6, 11, 12}:
            return VmmapSummary(
                process_name=f"proc-{pid}",
                physical_footprint_bytes=pid * 100,
                resident_bytes=pid * 10,
                swapped_bytes=pid * 1000,
            )
        return VmmapSummary(
            process_name=f"proc-{pid}",
            physical_footprint_bytes=pid * 10,
            resident_bytes=pid * 5,
            swapped_bytes=pid,
        )


def test_system_snapshot_surfaces_tree_and_swap_rankings() -> None:
    vmmap = FakeVmmapBackend()
    snapshot = capture_system_snapshot(
        SnapshotConfig(top_n=5),
        process_backend=FakeProcessBackend(),
        vmmap_backend=vmmap,
    )

    assert snapshot.rankings["processes_by_swapped_bytes"][0].label.startswith(
        "plugin-container"
    )
    assert snapshot.rankings["trees_by_swapped_bytes"][0].label.startswith(
        "Firefox"
    )
    assert sorted(vmmap.calls) == [4, 10, 11, 12, 20]


def test_pid_snapshot_preserves_parent_chain_for_basedpyright_node() -> None:
    vmmap = FakeVmmapBackend()
    snapshot = capture_pid_snapshot(
        6,
        SnapshotConfig(top_n=5),
        process_backend=FakeProcessBackend(),
        vmmap_backend=vmmap,
    )

    assert snapshot.focus is not None
    chain_names = [
        snapshot.processes[key].info.name for key in snapshot.focus.ancestor_chain_keys
    ]
    assert chain_names == [
        "tmux",
        "zsh",
        "uv",
        "jupyter-lab",
        "basedpyright-langserver",
        "node",
    ]
    assert sorted(vmmap.calls) == [1, 2, 3, 4, 5]
