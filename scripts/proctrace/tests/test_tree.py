from proctrace.models import ProcessIdentity, ProcessInfo, ProcessSnapshot
from proctrace.tree import aggregate_trees, ancestor_chain_keys, attach_relationships, descendant_keys


def make_process(pid: int, ppid: int | None, name: str, rss: int) -> ProcessSnapshot:
    return ProcessSnapshot(
        info=ProcessInfo(
            identity=ProcessIdentity(pid=pid, create_time=float(pid)),
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
        cpu_user_time_seconds=pid / 10,
        cpu_system_time_seconds=pid / 20,
    )


def test_attach_relationships_and_aggregation() -> None:
    processes = {
        proc.info.identity.key: proc
        for proc in [
            make_process(100, None, "Firefox", 1000),
            make_process(101, 100, "plugin-container", 500),
            make_process(102, 100, "plugin-container", 300),
            make_process(200, None, "Codex", 700),
        ]
    }

    attach_relationships(processes)
    trees = aggregate_trees(processes)

    firefox_key = ProcessIdentity(100, 100.0).key
    codex_key = ProcessIdentity(200, 200.0).key

    assert processes[ProcessIdentity(101, 101.0).key].parent_key == firefox_key
    assert ancestor_chain_keys(processes, ProcessIdentity(102, 102.0).key) == (
        firefox_key,
        ProcessIdentity(102, 102.0).key,
    )
    assert descendant_keys(processes, firefox_key) == (
        ProcessIdentity(101, 101.0).key,
        ProcessIdentity(102, 102.0).key,
    )

    firefox_tree = trees[firefox_key]
    assert firefox_tree.process_count == 3
    assert firefox_tree.cumulative_rss_bytes == 1800
    assert trees[codex_key].process_count == 1


def test_attach_relationships_treats_ppid_zero_as_root() -> None:
    processes = {
        proc.info.identity.key: proc
        for proc in [
            make_process(0, 0, "kernel_task", 100),
            make_process(1, 0, "launchd", 80),
            make_process(100, 1, "Firefox", 60),
            make_process(101, 100, "plugin-container", 40),
        ]
    }

    attach_relationships(processes)
    trees = aggregate_trees(processes)

    kernel_key = ProcessIdentity(0, 0.0).key
    launchd_key = ProcessIdentity(1, 1.0).key
    firefox_key = ProcessIdentity(100, 100.0).key

    assert processes[kernel_key].parent_key is None
    assert processes[launchd_key].parent_key is None
    assert processes[firefox_key].parent_key == launchd_key
    assert processes[firefox_key].root_key == firefox_key
    assert set(trees) == {kernel_key, launchd_key, firefox_key}
    assert trees[launchd_key].process_count == 1
    assert trees[firefox_key].process_count == 2
