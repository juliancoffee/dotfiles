---
name: tdd
description: Use when the user explicitly wants test-driven development, red-green-refactor, or test-first implementation. Do not trigger for every bugfix or feature request automatically.
---

# Test-Driven Development

Use a red-green-refactor loop with behavior-first tests.

## Core ideas

- Tests should verify observable behavior through public interfaces.
- Prefer integration-style tests over tests that lock onto internals.
- Avoid writing a giant batch of tests up front.
- Work in vertical slices: one failing test, one minimal implementation, then repeat.

## Workflow

1. Confirm the interface or behavior to test first.
2. Choose the highest-value behavior for the first tracer bullet.
3. Write one failing test.
4. Write the smallest amount of code to make it pass.
5. Repeat behavior by behavior.
6. Refactor only after the current slice is green.

## Rules

- One test at a time.
- Test behavior, not implementation detail.
- Do not use TDD as an excuse to over-design the future.
- If the repo already has strong testing conventions, follow them.

## Good prompts for this skill

- "let's do this with TDD"
- "red-green-refactor this"
- "write the test first"
