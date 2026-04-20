from proctrace.models import (
    ProcessIdentity,
    ProcessInfo,
    ProcessSnapshot,
    RankingEntry,
    SnapshotConfig,
    SystemMetadata,
    SystemSnapshot,
    TreeSummary,
    VmmapMode,
    VmmapSummary,
)
from proctrace.report import build_rankings, snapshot_to_json
from proctrace.report import render_system_text


def make_snapshot() -> SystemSnapshot:
    firefox_identity = ProcessIdentity(100, 100.0)
    firefox = ProcessSnapshot(
        info=ProcessInfo(
            identity=firefox_identity,
            ppid=None,
            name="Firefox",
            exe=None,
            cmdline=(),
            status=None,
            username=None,
            num_threads=None,
        ),
        rss_bytes=500,
        vms_bytes=1000,
        cpu_user_time_seconds=2.0,
        cpu_system_time_seconds=1.0,
        root_key=firefox_identity.key,
        vmmap=VmmapSummary(
            process_name="Firefox",
            physical_footprint_bytes=900,
            resident_bytes=700,
            swapped_bytes=300,
        ),
    )
    codex_identity = ProcessIdentity(200, 200.0)
    codex = ProcessSnapshot(
        info=ProcessInfo(
            identity=codex_identity,
            ppid=None,
            name="Codex",
            exe=None,
            cmdline=(),
            status=None,
            username=None,
            num_threads=None,
        ),
        rss_bytes=400,
        vms_bytes=800,
        cpu_user_time_seconds=1.0,
        cpu_system_time_seconds=1.0,
        root_key=codex_identity.key,
        vmmap=VmmapSummary(
            process_name="Codex",
            physical_footprint_bytes=1200,
            resident_bytes=800,
            swapped_bytes=100,
        ),
    )
    snapshot = SystemSnapshot(
        system=SystemMetadata(
            captured_at_utc="2026-01-01T00:00:00+00:00",
            hostname="host",
            platform="macOS",
            command="snapshot system",
        ),
        config=SnapshotConfig(vmmap_mode=VmmapMode.TOP),
        processes={
            firefox_identity.key: firefox,
            codex_identity.key: codex,
        },
        trees={
            firefox_identity.key: TreeSummary(
                root_key=firefox_identity.key,
                root_pid=100,
                root_name="Firefox",
                process_keys=(firefox_identity.key,),
                process_count=1,
                cumulative_rss_bytes=500,
                cumulative_vms_bytes=1000,
                cumulative_cpu_user_time_seconds=2.0,
                cumulative_cpu_system_time_seconds=1.0,
                cumulative_physical_footprint_bytes=900,
                cumulative_resident_bytes=700,
                cumulative_swapped_bytes=300,
            ),
            codex_identity.key: TreeSummary(
                root_key=codex_identity.key,
                root_pid=200,
                root_name="Codex",
                process_keys=(codex_identity.key,),
                process_count=1,
                cumulative_rss_bytes=400,
                cumulative_vms_bytes=800,
                cumulative_cpu_user_time_seconds=1.0,
                cumulative_cpu_system_time_seconds=1.0,
                cumulative_physical_footprint_bytes=1200,
                cumulative_resident_bytes=800,
                cumulative_swapped_bytes=100,
            ),
        },
        rankings={},
    )
    snapshot.rankings = build_rankings(snapshot)
    return snapshot


def test_rankings_prefer_swapped_processes() -> None:
    snapshot = make_snapshot()
    swapped = snapshot.rankings["processes_by_swapped_bytes"][0]
    footprint = snapshot.rankings["processes_by_physical_footprint"][0]

    assert isinstance(swapped, RankingEntry)
    assert swapped.label.startswith("Firefox")
    assert footprint.label.startswith("Codex")


def test_snapshot_json_contains_processes_trees_and_rankings() -> None:
    payload = snapshot_to_json(make_snapshot(), pretty=True)
    assert '"processes"' in payload
    assert '"trees"' in payload
    assert '"rankings"' in payload


def test_render_system_text_shows_tree_view_sorted_by_rss_plus_swap() -> None:
    rendered = render_system_text(make_snapshot())

    assert "Trees by rss + swap" in rendered
    assert "Firefox [100] tree=800 B" in rendered
    assert "Codex [200] tree=500 B" in rendered
