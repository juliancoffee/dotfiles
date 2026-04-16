---
name: egui-visual-testing
description: Use when building or evaluating agent-observable UI tests for Rust egui or eframe apps, especially when the goal is to render deterministic scenarios, save screenshots, and let a model judge whether the UI behaves as intended rather than relying on pixel-perfect diffs.
---

# egui Visual Testing

Use this skill when the user wants screenshot-based or agent-judged UI testing for an `egui` or `eframe` app.

The goal is not strict visual regression. The goal is to make the app easy for an agent to:

- boot into a known scenario
- perform a small interaction flow
- save one or more screenshots
- optionally save semantic/debug state
- judge whether the UI looks and behaves correct

## Default Approach

Prefer a small in-app test harness over a large shell wrapper.

Good shape:

1. Add a dedicated test mode to the Rust app.
2. Let the app load a named scenario or fixture.
3. Render deterministically enough for screenshots to be legible.
4. Save screenshots to a caller-provided output directory.
5. Exit after capture.

Usually the most useful contract is:

- input: scenario name, output dir, window size, seed, fixed time
- output: one or more `.png` files
- optional output: `manifest.json` or debug tree

## What To Optimize For

- Semantic correctness over pixel perfection
- Stable window size, fonts, theme, and mock data
- Short scenarios with obvious success/failure states
- Easy agent review from screenshots alone
- Optional semantic artifacts when visuals are ambiguous

## What To Avoid

- Brittle exact-pixel assertions as the primary check
- Randomized data, wall-clock time, or flaky async loading in screenshots
- Huge Bash orchestration unless the user explicitly wants it
- Mixing acceptance scenarios with low-level unit-test concerns

## Recommended App Contract

When editing an app, prefer environment variables or CLI flags such as:

- `--test-scenario <name>`
- `--test-output-dir <path>`
- `--test-window-size 1440x960`
- `--test-seed <value>`
- `--test-time <iso8601>`
- `--test-exit-after-capture`

If the app already has a config system, use that instead of inventing a second one.

## Agent Workflow

1. Add or reuse a deterministic scenario.
2. Launch the app in test mode.
3. Wait for a small fixed number of frames or a ready condition.
4. Capture screenshot artifacts.
5. Review visually.
6. If useful, compare the screenshot with semantic state or a manifest.

## Good Scenario Types

- empty state
- validation error
- success confirmation
- long text wrapping
- disabled or loading state
- compact window layout
- populated list or detail view

## When To Read More

- For `eframe` harness guidance and suggested Rust shapes, read [references/eframe-harness.md](references/eframe-harness.md).
- For a concrete Rust example of scenario-driven screenshot capture, read [references/example-eframe-test-harness.rs](references/example-eframe-test-harness.rs). A minimal Cargo project that compiles this exact file lives at [references/example-eframe-test-harness/Cargo.toml](references/example-eframe-test-harness/Cargo.toml).
- For headless Linux or VM execution with a virtual display, read [references/xvfb.md](references/xvfb.md).
