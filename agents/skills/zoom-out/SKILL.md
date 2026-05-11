---
name: zoom-out
description: Use when the user explicitly asks for a higher-level map, broader context, or a zoomed-out explanation of how a part of the codebase fits together. Do not use for ordinary code questions.
---

# Zoom Out

Use this skill when the user wants orientation rather than local implementation detail.

## What to do

1. Go up one or two layers of abstraction.
2. Map the relevant modules, callers, and responsibilities.
3. Explain how the current area fits into the larger system.
4. Point out the main seams, dependencies, and data flow.
5. Keep implementation detail secondary unless it is needed to explain the map.

## Output style

- Start with the big picture.
- Name the important modules or areas.
- Explain who calls whom and why.
- End with the one or two places the user should inspect next.
