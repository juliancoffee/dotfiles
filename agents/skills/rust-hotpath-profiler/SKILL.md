---
name: rust-hotpath-profiler
description: Use when optimizing Rust performance on macOS and the task needs a direct release bench, request latency numbers, or a folded-stack hotspot tree. Prefer this skill when you can isolate one hot function or one request path into a dedicated bench binary and want reproducible p50/p95/max timings plus xctrace-based call trees.
---

# Rust Hotpath Profiler

## Overview

Use this skill to benchmark and profile Rust hot paths on macOS. Prefer a tiny release bench binary over profiling the full app whenever you can isolate the expensive function or request path.

## Choose The Mode

Use a direct bench binary when the user cares about one indexing step, parser pass, allocator-heavy helper, or similar internal hot path.

Use a request harness when the user cares about actual LSP/API request latency and wants p50/p95/max for end-to-end requests.

## Direct Bench Workflow

1. Isolate the hot path behind a dedicated release bench binary under `src/bin/`.
2. Make the bench call the hot function directly, not RPC or editor plumbing, unless the user explicitly wants end-to-end latency.
3. Keep the workload fixed and explicit: fixture path, generated workspace shape, repeat count.
4. Build with `cargo build --release --bin <bench-bin>`.
5. Run the bench once without profiling to get timing numbers.
6. If a tree is needed, run `scripts/profile_direct_bench.py` on that bench command.
7. Read the generated folded stacks with `scripts/folded_tree.py` and report the hottest branches.

## Request Latency Workflow

1. Use an existing request harness if the repo already has one.
2. Build the server and request bench in release mode.
3. Run the harness and report p50/p95/max per request type.
4. If one request class is slow, only then consider extracting its internal hot path into a direct bench.

## Rules

- Prefer direct bench binaries for profiling internal work.
- Do not default to SVG output. The folded stack file and text tree are the primary outputs.
- Record exact commands, workload shape, and whether numbers are cold or steady.
- When profiling, keep the command single-purpose and deterministic.
- If you create a new bench binary, keep it small and committed separately from unrelated product changes when possible.

## Scripts

- `scripts/profile_direct_bench.py`
  Runs a command under macOS Time Profiler, exports the `time-profile` table, collapses it to folded stacks, and optionally prints a tree.
- `scripts/folded_tree.py`
  Prints an inclusive percentage tree from an Inferno folded stack file.

## Typical Commands

Direct bench timing:

```bash
cargo build --release --bin my-hotpath-bench
./target/release/my-hotpath-bench --repeats 4
```

Direct bench profile + tree:

```bash
python3 scripts/profile_direct_bench.py   --output-prefix /tmp/my-hotpath   --root-suffix my_crate::hot_function   -- ./target/release/my-hotpath-bench --repeats 4
```

Request latency run:

```bash
cargo build --release --bin my-request-bench --bin my-server
./target/release/my-request-bench /tmp/request-bench.json ./target/release/my-server
```
