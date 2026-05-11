---
name: improve-codebase-architecture
description: Use when the user explicitly wants architectural review, refactoring opportunities, codebase-structure improvement, or ideas for making a system more testable and navigable. Do not trigger for ordinary bugfixes.
---

# Improve Codebase Architecture

Surface architectural friction and propose deeper, cleaner module shapes.

## What to look for

- shallow modules whose interface is almost as complex as their implementation
- concepts spread across too many files
- code that is hard to test through current interfaces
- seams that leak too much detail
- places where one concept requires bouncing across many modules to understand

## Workflow

1. Read any obvious context docs or ADRs first when they exist.
2. Explore the codebase and note where understanding feels expensive.
3. Apply a deletion test to suspected abstractions:
   - if deleting it removes real complexity, it was useful
   - if deleting it just removes a pass-through layer, it was shallow
4. Present a small numbered list of improvement candidates.
5. For each candidate, explain:
   - current problem
   - proposed deeper shape
   - why it improves locality, leverage, or testability
6. Ask which candidate the user wants to explore further before going deep.

## Rules

- Use the project’s own domain terms where possible.
- Do not start by demanding architecture docs that do not exist.
- Prefer a few strong candidates over a giant refactor wishlist.
