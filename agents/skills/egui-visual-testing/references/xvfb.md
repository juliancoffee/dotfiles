# Xvfb for eframe

Use this reference when the app is a native Linux `eframe` binary and the environment has no real display server.

## What Xvfb Is

`Xvfb` is a virtual framebuffer X server. It provides an X11 display in memory, so GUI apps that require a display can still start in a VM or CI runner with no physical screen.

For most unattended runs, the simplest entrypoint is `xvfb-run`, which starts `Xvfb`, sets up X authority, runs your command, and then tears the virtual display down.

## Installation

On Debian or Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y xvfb xauth
```

`xvfb-run` requires `xauth`.

## Basic Launch Pattern

```bash
xvfb-run --auto-servernum --server-args="-screen 0 1440x960x24" \
  ./target/debug/my_app --test-scenario validation-error
```

Good defaults:

- `--auto-servernum`: avoids display collisions
- `-screen 0 1440x960x24`: fixed size and 24-bit color for more stable screenshots

## With Cargo

```bash
xvfb-run --auto-servernum --server-args="-screen 0 1440x960x24" \
  cargo run --release -- --test-scenario validation-error --test-exit-after-capture
```

## Recommended eframe Test Mode

Combine `xvfb-run` with a deterministic app test mode:

- fixed window size
- fixed theme
- seeded data
- frozen time where relevant
- exit after screenshot capture

That lets the agent run:

1. app under `xvfb-run`
2. scenario loads
3. screenshot saved to output dir
4. agent inspects PNG

## Caveats

- `Xvfb` provides X11, not Wayland.
- Native Linux `eframe` apps that expect a display will usually work better under `Xvfb` than with no display at all.
- GPU acceleration may differ from a normal desktop session, so visual output can still vary slightly.
- If your app uses external dialogs, OS integrations, or special GPU paths, test those separately.

## Troubleshooting

If the app does not start:

- ensure `xvfb` and `xauth` are installed
- verify you are using `xvfb-run`, not just `Xvfb`
- confirm the app is actually the native Linux binary
- try a smaller fixed screen such as `1280x1024x24`

If screenshots are blank or missing:

- wait a few frames before capture
- request one more repaint after issuing the screenshot command
- make the app exit only after the screenshot event has been received and written

## When Not To Use This

Prefer another route if:

- you are targeting web and can drive the app in a browser instead
- you need true Wayland-specific behavior
- you need pixel-perfect parity with a specific desktop compositor

