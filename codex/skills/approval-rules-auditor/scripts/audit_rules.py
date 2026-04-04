#!/usr/bin/env python3
"""Inspect Codex approval rules and suggest broader common prefixes."""

from __future__ import annotations

import argparse
import ast
import os
import re
import sys
from collections import defaultdict
from dataclasses import dataclass


RULE_RE = re.compile(
    r'^prefix_rule\(pattern=(\[[^\n]*\]), decision="([^"]+)"\)\s*$'
)


@dataclass
class Rule:
    lineno: int
    pattern: list[str]
    decision: str


def parse_rules(path: str) -> list[Rule]:
    rules: list[Rule] = []
    with open(path, "r", encoding="utf-8") as handle:
        for lineno, line in enumerate(handle, start=1):
            text = line.strip()
            if not text or text.startswith("#"):
                continue
            match = RULE_RE.match(text)
            if not match:
                continue
            pattern = ast.literal_eval(match.group(1))
            decision = match.group(2)
            if isinstance(pattern, list) and all(isinstance(item, str) for item in pattern):
                rules.append(Rule(lineno=lineno, pattern=pattern, decision=decision))
    return rules


def longest_common_prefix(patterns: list[list[str]]) -> list[str]:
    if not patterns:
        return []
    prefix: list[str] = []
    for items in zip(*patterns):
        first = items[0]
        if all(item == first for item in items[1:]):
            prefix.append(first)
        else:
            break
    return prefix


def quoted_command_prefix(shell_payloads: list[str]) -> str | None:
    extracted: list[str] = []
    for payload in shell_payloads:
        text = payload.strip()
        if not text.startswith('"'):
            return None
        parts = text.split('"')
        if len(parts) < 3 or not parts[1]:
            return None
        extracted.append(parts[1])
    first = extracted[0]
    if all(item == first for item in extracted[1:]):
        return f'"{first}"'
    return None


def smarter_common_prefix(patterns: list[list[str]]) -> list[str]:
    prefix = longest_common_prefix(patterns)
    if len(prefix) >= 3:
        return prefix
    if all(len(pattern) >= 3 and pattern[:2] == ["/bin/zsh", "-lc"] for pattern in patterns):
        shell_prefix = quoted_command_prefix([pattern[2] for pattern in patterns])
        if shell_prefix is not None:
            return ["/bin/zsh", "-lc", shell_prefix]
    return prefix


def command_family(pattern: list[str]) -> str:
    if not pattern:
        return "<empty>"
    first = pattern[0]
    if len(pattern) >= 3 and pattern[:2] == ["/bin/zsh", "-lc"]:
        shell_payload = pattern[2]
        shell_payload = shell_payload.strip()
        if shell_payload.startswith('"'):
            parts = shell_payload.split('"')
            if len(parts) >= 3 and parts[1]:
                return parts[1]
        return "/bin/zsh -lc"
    return first


def format_rule(pattern: list[str]) -> str:
    rendered = ", ".join(repr(item) for item in pattern)
    return f'prefix_rule(pattern=[{rendered}], decision="allow")'


def pattern_covers(base: list[str], target: list[str]) -> bool:
    if len(base) > len(target):
        return False
    if len(base) < len(target):
        return all(base_item == target_item for base_item, target_item in zip(base, target))
    if not base:
        return False
    if any(base_item != target_item for base_item, target_item in zip(base[:-1], target[:-1])):
        return False
    return target[-1] == base[-1] or target[-1].startswith(base[-1])


def find_covering_rule(prefix: list[str], rules: list[Rule], family_rules: list[Rule]) -> Rule | None:
    family_line_numbers = {rule.lineno for rule in family_rules}
    for rule in rules:
        if rule.lineno in family_line_numbers:
            continue
        if rule.decision != "allow":
            continue
        if pattern_covers(rule.pattern, prefix):
            return rule
    return None


def should_propose(prefix: list[str], rules: list[Rule]) -> bool:
    if len(rules) < 2 or not prefix:
        return False
    if all(rule.pattern == prefix for rule in rules):
        return False
    return True


def audit(path: str) -> int:
    rules = [rule for rule in parse_rules(path) if rule.decision == "allow"]
    groups: dict[str, list[Rule]] = defaultdict(list)
    for rule in rules:
        groups[command_family(rule.pattern)].append(rule)

    redundant_clusters = []
    proposal_clusters = []
    for family, family_rules in groups.items():
        if len(family_rules) < 2:
            continue
        patterns = [rule.pattern for rule in family_rules]
        prefix = smarter_common_prefix(patterns)
        if not should_propose(prefix, family_rules):
            continue
        covering_rule = find_covering_rule(prefix, rules, family_rules)
        if covering_rule is not None:
            redundant_clusters.append((family, family_rules, prefix, covering_rule))
            continue
        proposal_clusters.append((family, family_rules, prefix))

    if not redundant_clusters and not proposal_clusters:
        print("No clunky repetitive allow-rule clusters found.")
        return 0

    print(f"Rules file: {path}")
    print("")
    for family, family_rules, prefix, covering_rule in sorted(
        redundant_clusters, key=lambda item: (-len(item[1]), item[0])
    ):
        print(f"Cluster already covered: {family}")
        print(f"Rule count: {len(family_rules)}")
        print("Redundant lines: " + ", ".join(str(rule.lineno) for rule in family_rules))
        print(f"Covered by existing line: {covering_rule.lineno}")
        print("Existing broader rule:")
        print("  " + format_rule(covering_rule.pattern))
        print("")

    for family, family_rules, prefix in sorted(
        proposal_clusters, key=lambda item: (-len(item[1]), item[0])
    ):
        print(f"Cluster: {family}")
        print(f"Rule count: {len(family_rules)}")
        print("Current lines: " + ", ".join(str(rule.lineno) for rule in family_rules))
        print("Suggested prefix:")
        print("  " + format_rule(prefix))
        print("Examples in cluster:")
        for rule in family_rules[:5]:
            print("  - " + format_rule(rule.pattern))
        if len(family_rules) > 5:
            print(f"  - ... {len(family_rules) - 5} more")
        print("")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    default_path = os.path.expanduser("~/.codex/rules/default.rules")
    parser.add_argument("path", nargs="?", default=default_path)
    args = parser.parse_args()
    return audit(os.path.expanduser(args.path))


if __name__ == "__main__":
    sys.exit(main())
