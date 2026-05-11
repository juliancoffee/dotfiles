#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shlex
import subprocess
from pathlib import Path


TIME_PROFILE_XPATH = '//trace-toc[1]/run[1]/data[1]/table[@schema="time-profile"]'


def run(cmd: list[str]) -> None:
    subprocess.run(cmd, check=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output-prefix', required=True, type=Path)
    parser.add_argument('--root-suffix')
    parser.add_argument('--depth', type=int, default=4)
    parser.add_argument('--limit', type=int, default=10)
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()

    command = args.command
    if command and command[0] == '--':
        command = command[1:]
    if not command:
        raise SystemExit('Missing bench command after --')

    prefix = args.output_prefix
    prefix.parent.mkdir(parents=True, exist_ok=True)
    trace = prefix.with_suffix('.trace')
    stdout = prefix.with_suffix('.stdout')
    xml = prefix.with_suffix('.xctrace.xml')
    folded = prefix.with_suffix('.folded')

    run([
        'xctrace', 'record',
        '--template', 'Time Profiler',
        '--output', str(trace),
        '--target-stdout', str(stdout),
        '--launch', '--',
        *command,
    ])
    run([
        'xctrace', 'export',
        '--input', str(trace),
        '--output', str(xml),
        '--xpath', TIME_PROFILE_XPATH,
    ])
    with folded.open('w') as out:
        subprocess.run([
            str(Path.home() / '.cargo/bin/inferno-collapse-xctrace'),
            str(xml),
        ], check=True, stdout=out)

    print(f'command: {shlex.join(command)}')
    print(f'trace: {trace}')
    print(f'stdout: {stdout}')
    print(f'xml: {xml}')
    print(f'folded: {folded}')

    tree_cmd = [
        'python3',
        str(Path(__file__).with_name('folded_tree.py')),
        str(folded),
        '--depth', str(args.depth),
        '--limit', str(args.limit),
    ]
    if args.root_suffix:
        tree_cmd.extend(['--root-suffix', args.root_suffix])
    print('\nHot tree:')
    subprocess.run(tree_cmd, check=True)


if __name__ == '__main__':
    main()
