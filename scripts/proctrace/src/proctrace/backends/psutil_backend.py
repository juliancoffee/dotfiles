from __future__ import annotations

from typing import Callable, TypeVar

import psutil

from proctrace.models import ProcessIdentity, ProcessInfo, ProcessSnapshot

T = TypeVar("T")


def _safe(call: Callable[[], T], default: T) -> T:
    try:
        return call()
    except (psutil.AccessDenied, psutil.NoSuchProcess, psutil.ZombieProcess):
        return default


class PsutilBackend:
    def capture_processes(self) -> dict[str, ProcessSnapshot]:
        snapshots: dict[str, ProcessSnapshot] = {}

        for proc in psutil.process_iter():
            try:
                with proc.oneshot():
                    identity = ProcessIdentity(
                        pid=proc.pid,
                        create_time=_safe(proc.create_time, 0.0),
                    )
                    memory = _safe(proc.memory_info, None)
                    cpu_times = _safe(proc.cpu_times, None)
                    info = ProcessInfo(
                        identity=identity,
                        ppid=_safe(proc.ppid, None),
                        name=_safe(proc.name, f"pid-{proc.pid}"),
                        exe=_safe(proc.exe, None),
                        cmdline=tuple(_safe(proc.cmdline, [])),
                        status=_safe(proc.status, None),
                        username=_safe(proc.username, None),
                        num_threads=_safe(proc.num_threads, None),
                    )
            except (psutil.AccessDenied, psutil.NoSuchProcess, psutil.ZombieProcess):
                continue

            snapshots[identity.key] = ProcessSnapshot(
                info=info,
                rss_bytes=0 if memory is None else int(memory.rss),
                vms_bytes=0 if memory is None else int(memory.vms),
                cpu_user_time_seconds=0.0
                if cpu_times is None
                else float(cpu_times.user),
                cpu_system_time_seconds=0.0
                if cpu_times is None
                else float(cpu_times.system),
            )

        return snapshots
