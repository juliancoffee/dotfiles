#!/usr/bin/env python3
from __future__ import annotations

import argparse
from collections import Counter
from pathlib import Path


def load_folded(path: Path):
    counts = Counter()
    children = Counter()
    total = 0
    for raw in path.read_text().splitlines():
        line = raw.strip()
        if not line:
            continue
        stack, count_s = line.rsplit(' ', 1)
        count = int(count_s)
        total += count
        frames = tuple(stack.split(';'))
        for i in range(len(frames)):
            prefix = frames[: i + 1]
            counts[prefix] += count
            if i + 1 < len(frames):
                children[(prefix, frames[i + 1])] += count
    return total, counts, children


def choose_root(counts, suffix: str | None):
    paths = list(counts)
    if suffix:
        matches = [path for path in paths if path[-1].endswith(suffix)]
        if not matches:
            raise SystemExit(f'No frame ends with: {suffix}')
        return max(matches, key=lambda path: counts[path])
    roots = [path for path in paths if len(path) == 1]
    return max(roots, key=lambda path: counts[path])


def print_tree(root, counts, children, total, depth, limit, indent=0):
    pct = counts[root] * 100.0 / total
    print(f"{'  ' * indent}{root[-1]} {pct:.1f}%")
    if indent >= depth:
        return
    child_rows = [
        (count, child)
        for (parent, child), count in children.items()
        if parent == root
    ]
    child_rows.sort(reverse=True)
    for _, child in child_rows[:limit]:
        print_tree(root + (child,), counts, children, total, depth, limit, indent + 1)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('folded', type=Path)
    parser.add_argument('--root-suffix')
    parser.add_argument('--depth', type=int, default=4)
    parser.add_argument('--limit', type=int, default=10)
    args = parser.parse_args()

    total, counts, children = load_folded(args.folded)
    root = choose_root(counts, args.root_suffix)
    print_tree(root, counts, children, total, args.depth, args.limit)


if __name__ == '__main__':
    main()
