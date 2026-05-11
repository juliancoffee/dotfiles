---
name: design-an-interface
description: Use when the user explicitly wants interface or API design help, wants multiple competing shapes, or asks to compare different module boundaries. Do not trigger for every implementation discussion.
---

# Design an Interface

Do not settle on the first interface idea. Generate multiple genuinely different designs, then compare them.

## Workflow

1. Understand:
   - what problem the interface solves
   - who the callers are
   - key operations
   - important constraints
2. Produce multiple interface options with different tradeoffs.
3. For each option, show:
   - interface shape
   - example usage
   - what complexity it hides
   - main tradeoffs
4. Compare the options in prose.
5. Help the user choose or synthesize a final design.

## Evaluation criteria

- interface simplicity
- fit for likely callers
- flexibility versus focus
- depth: how much complexity stays behind the interface
- ease of correct use versus ease of misuse

## Rules

- The options should be meaningfully different, not cosmetic variations.
- Stay at interface level unless the user asks for implementation.
- Prefer 2-4 strong options over a huge brainstorm.
