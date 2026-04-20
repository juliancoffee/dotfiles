# Manual Workflow

This is the exact diagnostic flow I used during the Codex thread `Review current Firefox commit`.

I did not reconstruct this from memory. I pulled it from the Codex session log:

- `~/.codex/session_index.jsonl`
- `~/.codex/sessions/2026/04/18/rollout-2026-04-18T20-34-31-019da1a8-8dc2-7e71-bd59-938bba00c5cd.jsonl`

The goal was to answer a few concrete questions:

1. Is Firefox actually still running?
2. How big is the Firefox process tree as a whole?
3. Is the machine under memory pressure or deep into swap?
4. Which processes are actually carrying the swap burden?
5. Where did suspicious child processes come from?

## 1. Check whether Firefox is really running

I first checked for obvious Firefox processes and agents:

```bash
ps aux | rg -i 'firefox|mozilla|crashreporter|updater|default-browser-agent'
pgrep -fl 'Firefox|firefox|Mozilla|crashreporter|updater|default-browser-agent'
launchctl list | rg -i 'firefox|mozilla'
```

This established that Firefox was still alive even when it looked "closed" from the user point of view.

## 2. Measure the live Firefox tree

Once I had the main Firefox PID, I inspected the parent and direct children:

```bash
ps -o pid,ppid,%cpu,rss,etime,command -p 36660,$(pgrep -P 36660 | paste -sd, -)
```

Then I used a small Python helper to sum the Firefox root plus all direct children:

```python
import subprocess

pids = subprocess.check_output(["pgrep", "-P", "36660"], text=True).split()
cmd = ["ps", "-o", "pid=,rss=,%cpu=,comm=", "-p", ",".join(["36660", *pids])]
out = subprocess.check_output(cmd, text=True)
rows = []
for line in out.splitlines():
    parts = line.split(None, 3)
    if len(parts) == 4:
        pid, rss, cpu, comm = parts
        rows.append((int(pid), int(rss), float(cpu), comm))

print("processes", len(rows))
print("total_rss_mb", round(sum(r for _, r, _, _ in rows) / 1024, 1))
print("total_cpu_percent", round(sum(c for *_, c, _ in rows), 1))
for pid, rss, cpu, comm in sorted(rows, key=lambda x: (-x[1], -x[2]))[:12]:
    print(pid, round(rss / 1024, 1), cpu, comm)
```

That gave the first "big picture" Firefox number:

- `processes 32`
- `total_rss_mb 1251.6`
- `total_cpu_percent 6.4`

Later, after restart and config changes, I repeated the tree/process counting with:

```bash
pgrep -fl '/Applications/Firefox.app/Contents/MacOS/firefox|Firefox GPU Helper|plugin-container|keepassxc-proxy|crashhelper'
```

and another Python summarizer over the matching PIDs.

## 3. Check system-wide memory pressure and swap

To understand whether the machine was genuinely under pressure, I used:

```bash
vm_stat
memory_pressure
sysctl vm.swapusage hw.memsize
```

The important takeaways came from:

- `vm.swapusage` for total/used/free swap
- `hw.memsize` for physical RAM
- `memory_pressure` for the system-wide free percentage and pressure state

Two notable snapshots from the session:

Better post-restart state:

- `vm.swapusage: total = 6144.00M  used = 4964.12M  free = 1179.88M`
- `System-wide memory free percentage: 32%`

Worse later state:

- `vm.swapusage: total = 9216.00M  used = 8737.94M  free = 478.06M`
- `System-wide memory free percentage: 50%`

That mismatch is part of the reason this workflow needs both swap inspection and ordinary memory-pressure checks: swap staying high does not always mean the currently active process is still the main offender.

## 4. Check top memory users across the whole machine

Once it became clear Firefox was not the whole story, I ranked heavy processes with:

```bash
ps axo pid,ppid,%cpu,rss,state,comm | sort -k4 -nr | head -n 25
top -l 1 -o mem -stats pid,command,cpu,mem,threads,state | head -n 35
```

This was useful for surfacing unexpected contenders like:

- a `node` process
- `Telegram`
- Codex renderer/helper processes
- `rust-analyzer`
- `WindowServer`

At this stage, `top` was useful for a broad "who looks huge?" pass, but not enough by itself to explain swap.

## 5. Drill into suspicious processes with `ps`

When `top` pointed at `node` and `Telegram`, I inspected them directly:

```bash
ps -p 90998,21328 -o pid,ppid,%cpu,rss,vsz,state,comm,args
```

This was the first clue that plain RSS was not telling the whole story:

- Telegram RSS was only about `64 MB`
- node RSS was only about `1.4 MB`

So the next step was `vmmap`.

## 6. Use `vmmap -summary` to inspect per-process footprint and swap

This was the key step for identifying swap-heavy processes:

```bash
vmmap -summary 90998 | sed -n '1,120p'
vmmap -summary 21328 | sed -n '1,120p'
```

From those summaries:

For `node`:

- `Physical footprint: 1.5G`
- `resident: 214.8M`
- `swapped: 1.4G`

For `Telegram`:

- `Physical footprint: 1.0G`
- `resident: 355.4M`
- `swapped: 990.0M`

This is how I concluded that those processes were carrying a lot of swapped-out memory even though their live RSS did not look huge.

## 7. Find where a suspicious child process came from

After identifying the large `node` process, I looked at it and its immediate parent:

```bash
ps -p 90998,90997 -o pid,ppid,user,etime,comm,args
```

That showed:

- `90997`: Python wrapper running `.../.venv/bin/basedpyright-langserver --stdio`
- `90998`: Node running `.../basedpyright/langserver.index.js --stdio`

To find the full ancestry, I walked the parent chain with Python:

```python
import subprocess

pid = "90998"
seen = []
while pid and pid != "0":
    out = subprocess.check_output(
        ["ps", "-p", pid, "-o", "pid=,ppid=,comm=,args="],
        text=True,
    ).strip()
    if not out:
        break
    parts = out.split(None, 3)
    if len(parts) < 4:
        break
    cpid, ppid, comm, args = parts
    print(f"{cpid}\tparent={ppid}\t{comm}\t{args}")
    if ppid in seen:
        break
    seen.append(cpid)
    pid = ppid
```

That produced the ancestry chain:

- `node`
- `basedpyright-langserver`
- `jupyter-lab`
- `uv run jupyter-lab`
- `zsh`
- `tmux`
- `launchd`

So the process did not come from an editor like VS Code or Zed. It came from a JupyterLab session launched with `uv run jupyter-lab`.

## 8. Confirm the working directory / ownership context

To tie that back to the actual project, I checked open files and cwd for the Python wrapper:

```bash
lsof -p 90997 | rg -i 'cwd|txt|DRAISS|basedpyright|nodejs_wheel|vscode|cursor|zed|nvim|emacs|python'
```

That showed the cwd was:

```text
/Users/illiadenysenko/Workspace/repos/DRAISS
```

So the node process belonged to the `DRAISS` Jupyter workflow.

## What This Workflow Actually Established

This chain of commands let me answer:

1. Firefox was still running.
2. Firefox as a group was large, but later it was not the only memory problem.
3. The machine was deep into swap.
4. Some processes with small current RSS still had very large swapped-out footprints.
5. `vmmap -summary` was the crucial tool for finding that.
6. Parent-chain tracing explained where odd child processes came from.

## Minimal Repeatable Workflow

If I had to compress the workflow to the smallest useful version, it would be:

```bash
pgrep -fl 'Firefox|firefox|plugin-container|Firefox GPU Helper'
sysctl vm.swapusage hw.memsize
memory_pressure
top -l 1 -o mem -stats pid,command,cpu,mem,threads,state | head -n 35
ps -p <pid> -o pid,ppid,%cpu,rss,vsz,state,comm,args
vmmap -summary <pid> | sed -n '1,120p'
```

And when the parentage matters:

```bash
ps -p <pid> -o pid,ppid,user,etime,comm,args
lsof -p <pid> | rg -i 'cwd|txt'
```

## Why This Exists In `proctrace`

This is the manual baseline that `proctrace` is meant to replace or compress:

- top processes by live memory
- top processes by swapped-out memory
- aggregate heavy trees, not just single PIDs
- explain parent chains for suspicious workers
- emit stable JSON so the same reasoning can be automated later
