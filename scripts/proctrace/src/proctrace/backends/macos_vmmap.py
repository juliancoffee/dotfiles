from __future__ import annotations

import re
import subprocess
from pathlib import Path

from proctrace.models import VmmapSummary

VMMAP_BIN = Path("/usr/bin/vmmap")
PROCESS_RE = re.compile(r"^Process:\s+(?P<name>.+?)\s+\[(?P<pid>\d+)\]$")
FOOTPRINT_RE = re.compile(r"^Physical footprint:\s+(?P<value>\S+)$")
TOTAL_RE = re.compile(
    r"^TOTAL(?:, minus reserved VM space)?\s+"
    r"(?P<virtual>\S+)\s+"
    r"(?P<resident>\S+)\s+"
    r"(?P<dirty>\S+)\s+"
    r"(?P<swapped>\S+)"
)


def parse_byte_size(raw: str) -> int:
    raw = raw.strip()
    if raw in {"", "-", "—"}:
        return 0

    units = {
        "K": 1024,
        "M": 1024**2,
        "G": 1024**3,
        "T": 1024**4,
    }
    suffix = raw[-1]
    if suffix in units:
        return int(float(raw[:-1]) * units[suffix])
    return int(float(raw))


def parse_vmmap_summary(text: str) -> VmmapSummary:
    process_name: str | None = None
    physical_footprint_bytes: int | None = None
    resident_bytes: int | None = None
    swapped_bytes: int | None = None

    for line in text.splitlines():
        stripped = line.strip()
        if not stripped:
            continue

        process_match = PROCESS_RE.match(stripped)
        if process_match is not None:
            process_name = process_match.group("name")
            continue

        footprint_match = FOOTPRINT_RE.match(stripped)
        if footprint_match is not None:
            physical_footprint_bytes = parse_byte_size(
                footprint_match.group("value")
            )
            continue

        total_match = TOTAL_RE.match(stripped)
        if total_match is not None and resident_bytes is None:
            resident_bytes = parse_byte_size(total_match.group("resident"))
            swapped_bytes = parse_byte_size(total_match.group("swapped"))

    if (
        process_name is None
        and physical_footprint_bytes is None
        and resident_bytes is None
        and swapped_bytes is None
    ):
        raise ValueError("failed to parse vmmap summary")

    return VmmapSummary(
        process_name=process_name,
        physical_footprint_bytes=physical_footprint_bytes,
        resident_bytes=resident_bytes,
        swapped_bytes=swapped_bytes,
    )


class VmmapBackend:
    def __init__(self, binary: Path = VMMAP_BIN) -> None:
        self.binary = binary

    def capture(self, pid: int, *, timeout_seconds: float) -> VmmapSummary:
        if not self.binary.exists():
            return VmmapSummary(error=f"{self.binary} not found")

        try:
            completed = subprocess.run(
                [str(self.binary), "-summary", str(pid)],
                capture_output=True,
                text=True,
                timeout=timeout_seconds,
                check=False,
            )
        except subprocess.TimeoutExpired:
            return VmmapSummary(error="vmmap timed out")
        except OSError as exc:
            return VmmapSummary(error=str(exc))

        if completed.returncode != 0:
            stderr = completed.stderr.strip()
            stdout = completed.stdout.strip()
            return VmmapSummary(
                error=stderr or stdout or f"vmmap failed ({completed.returncode})"
            )

        try:
            return parse_vmmap_summary(completed.stdout)
        except ValueError as exc:
            return VmmapSummary(error=str(exc))
