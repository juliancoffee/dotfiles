# `scripts/proctrace`: snapshot-first macOS process explorer

## Summary
Build a new isolated `uv` project at `scripts/proctrace` as a library-first, snapshot-first diagnostic tool for macOS. V1 should optimize for reproducible inspection of current system state, JSON export, and CLI reports that answer the same questions from the Firefox debugging session: which processes and trees are heavy, which ones carry swapped-out memory, what their parents are, and how aggregate trees compare across the whole machine.

The implementation should be test-driven around stable dataclasses, backend adapters, and fixture-based validation against real command output. The main consumer is expected to be an agent or engineer doing system diagnosis, so JSON shape and CLI subcommands should be designed for downstream analysis first. `vmmap` enrichment should be sampled by default because swap visibility matters, but one `vmmap` subprocess per PID is expensive enough that full-machine enrichment is not a practical default.

## Implementation Changes
- Create a standalone nested `uv` package under `scripts/proctrace` with its own `pyproject.toml`, `uv.lock`, `src/`, and `tests/`, following the existing nested-project pattern in this repo rather than touching the root Python project.
- Structure the package around reusable library modules:
  - `models.py`
    - dataclasses for `ProcessIdentity(pid, create_time)`, `ProcessInfo`, `TreeNode`, `VmmapSummary`, `SnapshotConfig`, `ProcessSnapshot`, `TreeSummary`, `SystemSnapshot`
  - `backends/psutil_backend.py`
    - current process enumeration
    - parent/child relationships
    - core counters and memory fields from `psutil`
  - `backends/macos_vmmap.py`
    - wrapper for `/usr/bin/vmmap -summary`
    - parser for a deliberately tiny field set: physical footprint, resident, swapped
    - graceful failure when `vmmap` is missing, denied, or unparsable
    - one subprocess per selected PID, with bounded parallelism
  - `tree.py`
    - process-tree construction from PID/PPID relationships
    - ancestor walking and root detection
    - aggregation by subtree roots that stop below `launchd` / `kernel_task`
  - `snapshot.py`
    - one-shot system capture orchestration
    - sampled `vmmap` enrichment for the top RSS processes
    - optional focused capture for selected PIDs
  - `report.py`
    - ranking helpers and summary generation
    - human-readable tree rendering sorted by `rss + swap`
    - JSON serialization
  - `cli.py`
    - thin CLI wrapper around the library
- Keep live polling architecture out of scope for v1 except for internal seams that make it possible later. The library should expose snapshot operations cleanly enough that future sampling can compose repeated snapshots without changing the data model.
- Reuse the key bencher lesson only where it still matters:
  - tree-based aggregation is first-class
  - process identity should include creation time to avoid PID reuse problems
  - no long-lived descendant cache in v1 because this is snapshot-first, not streaming-first

## Public Interfaces
- CLI v1 should be snapshot-oriented and JSON-first:
  - `proctrace snapshot system`
    - capture the full current process graph
  - `proctrace snapshot pid <pid>`
    - capture one PID, its ancestors, descendants, and aggregated subtree
  - `proctrace snapshot top`
    - print the heaviest trees in the current system snapshot as an indented tree view
  - Common flags:
  - `--json-out <path>` write full structured snapshot JSON
  - `--pretty-json` pretty-print JSON
  - `--vmmap-mode <top|none>`
    - `top`: enrich only the top `--top-n` processes by RSS
    - `none`: `psutil` only
  - default for v1: `top`
  - `--top-n <int>` number of trees to render, and also the number of PIDs sampled by `vmmap` in `top` mode; default `20`
- JSON v1 should be designed as a reusable diagnostic artifact:
  - `system`
    - host metadata, timestamp, platform, capture mode
  - `processes`
    - keyed by process identity, with PID, PPID, command, executable, create time, psutil memory/cpu fields, optional vmmap fields, and parent/root references
  - `trees`
    - aggregated subtree summaries including process count, cumulative RSS, cumulative CPU, cumulative physical footprint if available, cumulative swapped if available
  - `rankings`
    - top processes by RSS
    - top processes by physical footprint
    - top processes by swapped bytes
    - top trees by the same metrics
  - `focus`
    - when capturing a PID, include the selected process, its ancestor chain, and its root-tree summary explicitly
- CLI text output should mirror the Firefox debugging workflow:
  - top trees sorted by `rss + swap`
  - indented descendants ordered by subtree memory
  - per-node `total`, `rss`, and `swap`
  - parent chain for a focused PID
  - explanation lines when a metric is unavailable because `vmmap` was not sampled or failed for a process

## Test Plan
- Unit tests:
  - process identity construction using `(pid, create_time)`
  - tree construction and root aggregation from synthetic process tables
  - ranking logic for processes versus aggregated trees
  - JSON serialization stability and field presence
  - `vmmap -summary` parser against saved fixtures
- Fixture-driven integration tests:
  - saved `ps`/`psutil`-like process tables plus saved `vmmap` outputs that reproduce the Firefox investigation patterns:
    - Firefox multi-process tree with moderate RSS but heavy group footprint
    - a process with low current RSS but large swapped-out memory
    - a child process whose parent chain explains where it came from
    - a top-heavy non-Firefox process that competes for swap
  - verify the tool surfaces the same conclusions we reached manually:
    - heavy swapped-out processes can differ from top-RSS processes
    - aggregated trees can be more important than single-process rankings
    - parent-chain inspection identifies origin of suspicious workers
- Manual acceptance checks:
  - run `snapshot system` and compare its heaviest trees against manual `top`, `ps`, and `vmmap` spot checks
  - run `snapshot pid <firefox-pid>` and confirm the subtree and heavy descendants match manual Firefox inspection
  - run `snapshot pid <basedpyright-node-pid>` and confirm the ancestor chain points back to the JupyterLab launch path
- V1 should be considered done when the tool can replace the ad hoc manual flow we used:
  - `ps`
  - `top`
  - `memory_pressure`
  - `vmmap`
  - parent-chain tracing

## Assumptions And Defaults
- V1 is macOS-first and intentionally uses `/usr/bin/vmmap` as an external tool rather than trying to reimplement its privileged inspection.
- The primary deliverable is reusable JSON plus trustworthy CLI snapshots, not live updating.
- `vmmap` enrichment is sampled by default for the top RSS processes to keep snapshots usable in real interactive diagnostics.
- `vmmap` inspection cost is proportional to the number of selected PIDs because the tool shells out once per PID.
- Tree aggregation is intentionally macOS-biased toward user-meaningful app/service subtrees instead of literal system roots under `launchd`.
- The library should be structured so a later live sampler can be added by repeatedly invoking the same snapshot primitives rather than redesigning the model.
