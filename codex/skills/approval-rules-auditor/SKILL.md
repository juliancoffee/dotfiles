---
name: "approval-rules-auditor"
description: "Use when the user asks to inspect Codex allow rules, approval rules, or `~/.codex/rules/default.rules`, especially to find clunky one-off `prefix_rule` entries and propose broader common prefixes without rewriting rules automatically."
---

# Approval Rules Auditor

Audit Codex local approval rules and propose cleaner shared prefixes for repetitive `allow` entries.
Do not rewrite rules unless the user explicitly asks.

## When to use

Use this skill when the user wants to:

- inspect saved allow rules
- understand why approvals are noisy or repetitive
- find clunky one-off `prefix_rule(...)` entries
- propose broader common prefixes
- review `~/.codex/rules/default.rules`

## Default workflow

1. Read the current rules file:

```bash
sed -n '1,240p' ~/.codex/rules/default.rules
```

2. Run the audit script for a grouped summary:

```bash
python3 ~/.codex/skills/approval-rules-auditor/scripts/audit_rules.py
```

3. Show the user:

- the repetitive rule clusters
- the current common prefix found for each cluster
- a concrete proposed `prefix_rule(...)`
- the main tradeoff if the broader prefix is accepted

4. Only edit the rules file if the user explicitly asks.

## Notes

- The rules file is plain local state, not remote service state.
- Prefer proposing a broader prefix only when there are multiple repetitive rules with the same command family.
- If a proposed prefix becomes too broad to be safe, say so and keep the narrower rule.

## Output expectations

Keep the report short and concrete:

- `Current cluster`
- `Suggested prefix`
- `Why it helps`
- `Risk / broader scope`

