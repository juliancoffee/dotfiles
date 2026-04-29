---
name: command-name-ideas
description: Use when the user asks for CLI, terminal app, package, tool, or subcommand name ideas, wants candidate names compared, or wants naming feedback where typing feel matters. Generate or evaluate names, then use the bundled worddistance script to score awkwardness so uncomfortable patterns like bottom-row stretches and row-bounce redirects are penalized.
metadata:
  short-description: Generate and compare command names with ergonomic scoring
---

# Command Name Ideas

Use this skill when the user is naming a command-line tool, package, alias, or
subcommand and typing ergonomics should influence the answer.

## Workflow

1. Start with semantics first: what the tool does, tone, ecosystem norms,
   discoverability, and likely abbreviations.
2. Generate a candidate set or take the user's shortlist.
3. Score candidate names with the bundled script:

```sh
./scripts/worddistance.py candidate1 candidate2 candidate3
```

If there are many candidates, put one name per line in a temp file and run:

```sh
./scripts/worddistance.py --file candidates.txt
```

4. Use the score as a decision aid, not the only criterion. Prefer names that
   are both clear and comfortable.

## Interpretation

- Low score: easier or more routine to type.
- High score: more awkward or interruption-prone.
- Pay special attention to short names and common repeated keystrokes.
- Worry less about long hyphenated commands than about short commands people
  will type constantly.
- Still call out obviously awkward clusters such as harsh bottom-row spans,
  same-finger jumps, or row-bounce redirects.

## Response Style

- If the user wants ideas, return a short shortlist, not a giant brainstorm.
- If the user gave candidates, rank them and mention the ergonomic tradeoffs.
- Mention the score only when it helps the decision.
- Do not recommend a semantically weak name just because it scores well.
