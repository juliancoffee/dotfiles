## What
Yes, shamefully vibecoded tool to better understand the memory usage.

## proctrace

Snapshot-first macOS process explorer with tree aggregation and `vmmap`
enrichment.

Examples:

```sh
uv run proctrace snapshot top
uv run proctrace snapshot pid 12345 --pretty-json
uv run proctrace snapshot system --json-out snapshot.json
```

`vmmap` enrichment is sampled by default using `--vmmap-mode top`, which
limits `vmmap` calls to the top `--top-n` processes by RSS. Use
`--vmmap-mode none` for a fast `psutil`-only snapshot.

In `top` mode, `proctrace` shells out to `/usr/bin/vmmap -summary <pid>`
once per selected process. That makes swap inspection much more expensive
than basic process enumeration, so the CLI defaults to sampling instead of
walking the whole machine.

Text output is tree-oriented and sorted by `rss + swap` at the subtree
level. On macOS, tree roots are chosen as the first ancestor below
`launchd` or `kernel_task`, so app/service subtrees like Firefox, Codex,
and Chrome show up as separate trees instead of being collapsed under a
system root.

In the tree view, `total` means `rss + swap`, and a trailing `+` means the
value is a lower bound because swap data was not collected for that process
or subtree.
