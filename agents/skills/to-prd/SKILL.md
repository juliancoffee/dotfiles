---
name: to-prd
description: Use when the user explicitly wants to turn the current conversation or feature idea into a PRD. Do not trigger for ordinary planning or implementation chat.
---

# To PRD

Turn the current conversation and codebase understanding into a product requirements document.

## Workflow

1. Explore the repo enough to understand current behavior and constraints.
2. Synthesize what is already known instead of re-interviewing the user unless something critical is missing.
3. Write a PRD that focuses on user-facing problem and behavior, not file paths or code snippets.
4. If the user wants, turn that PRD into a GitHub issue or markdown file.

## PRD shape

Include:

- Problem statement
- Solution summary
- User stories
- Implementation decisions
- Testing decisions
- Out of scope
- Open questions or further notes

## Rules

- Prefer stable behavior descriptions over code-level detail.
- Do not include file paths unless the user explicitly wants implementation notes tied to files.
- Be concrete enough that the PRD is actionable.
