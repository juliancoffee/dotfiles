from pathlib import Path

from proctrace.backends.macos_vmmap import parse_vmmap_summary


def test_parse_vmmap_summary_fixture() -> None:
    fixture = Path(__file__).with_name("fixtures") / "vmmap_node_summary.txt"
    summary = parse_vmmap_summary(fixture.read_text())

    assert summary.process_name == "node"
    assert summary.physical_footprint_bytes == 1610612736
    assert summary.resident_bytes == 225234124
    assert summary.swapped_bytes == 1503238553
