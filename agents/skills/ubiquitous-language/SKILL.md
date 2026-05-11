---
name: ubiquitous-language
description: Use when the user explicitly wants to define domain terms, build a glossary, harden terminology, or establish a DDD-style ubiquitous language. Do not trigger just because a conversation contains domain words.
---

# Ubiquitous Language

Extract and normalize domain terminology from the current conversation and codebase context.

## Workflow

1. Gather the domain-relevant nouns, verbs, and concepts from the conversation and any obvious repo docs.
2. Identify ambiguities:
   - one word used for different concepts
   - different words used for the same concept
   - vague or overloaded terms
3. Propose a canonical glossary with clear preferred terms.
4. Flag aliases to avoid.
5. If the user wants persistence, write the glossary to `UBIQUITOUS_LANGUAGE.md` in the working directory.

## Output format

Prefer:

- grouped term tables when natural clusters exist
- short definitions
- a short list of important relationships
- a "flagged ambiguities" section

## Rules

- Be opinionated when choosing canonical terms.
- Focus on domain language, not generic programming jargon.
- If the user did not ask to write a file, keep it inline.
