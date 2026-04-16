# eframe Harness Pattern

Use this reference when the task is specifically about implementing the Rust side of the screenshot harness.

## Preferred Architecture

Keep the testing surface inside the app:

- `AppScenario`: enum or string-backed fixture selector
- `TestConfig`: window size, seed, time, output dir, capture options
- `TestArtifacts`: screenshot paths plus optional debug metadata

Good separation:

- domain logic decides state
- scenario loader creates deterministic app state
- UI renders that state
- capture code saves artifacts and exits

## Minimal Shape

Typical pieces:

- parse `std::env::args()` or env vars into `TestConfig`
- if test mode is enabled, build the app from a named scenario
- after a few frames or a ready flag, save screenshot(s)
- optionally write `manifest.json`
- exit

## Suggested Rust Interfaces

```rust
pub struct TestConfig {
    pub scenario: String,
    pub output_dir: PathBuf,
    pub width: u32,
    pub height: u32,
    pub seed: Option<u64>,
    pub fixed_time: Option<String>,
    pub exit_after_capture: bool,
}

pub trait ScenarioLoader {
    fn load(&self, name: &str, cfg: &TestConfig) -> anyhow::Result<AppState>;
}

pub struct TestArtifacts {
    pub screenshots: Vec<PathBuf>,
    pub manifest_path: Option<PathBuf>,
}
```

There is also a minimal checkable crate for the full example at [example-eframe-test-harness/Cargo.toml](example-eframe-test-harness/Cargo.toml), with `src/main.rs` including the sibling reference file so the documented example and the compiled example stay in sync.

## Determinism Checklist

- fixed window size
- fixed scale factor if possible
- bundled or pinned fonts
- fixed theme
- seeded sample data
- frozen clock where relevant
- avoid network fetches in screenshot mode
- avoid animations unless the frame to capture is explicit

## Review Strategy

The model should answer questions like:

- Is the intended UI visible?
- Is the success or error state obvious?
- Is text clipped, overlapping, or missing?
- Are the primary actions enabled or disabled correctly?
- Does the layout still make sense at this size?

Do not rely only on "command exited 0".

## Useful Extras

- write a small manifest with scenario name and created files
- emit a debug tree or compact JSON state dump
- include stable labels for important controls
- allow multi-step flows to save `01-start.png`, `02-after-submit.png`, etc.

## If Capture Is Hard

If direct in-process framebuffer capture is awkward with the current backend, a fallback is acceptable:

- run the real desktop window
- capture the window externally
- still keep scenarios deterministic

But prefer in-app capture when feasible, because it is easier to automate and less OS-specific.
