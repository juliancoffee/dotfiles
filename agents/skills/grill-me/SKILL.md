---
name: grill-me
description: Use when the user explicitly asks to be grilled, stress-test a plan, or pressure-test a design by answering focused questions one at a time. Do not trigger for ordinary planning.
---

# Grill Me

Interview the user rigorously about a plan or design until the shape is solid.

## Workflow

1. Understand the plan at a high level.
2. Ask one focused question at a time.
3. When useful, provide a recommended answer along with the question.
4. Resolve the design tree branch by branch: constraints, tradeoffs, edge cases, interfaces, rollout, and failure modes.
5. If a question can be answered by exploring the codebase, explore first instead of asking.

## Rules

- Ask one question at a time.
- Prefer questions that materially change the design.
- Do not drift into implementation unless the user wants that.
- Keep the pressure on the design, not on the person.
