---
name: obsidian-vault
description: Use when the user explicitly wants to find, create, edit, or organize notes in an Obsidian vault. Do not trigger for ordinary markdown editing. If the vault root is not already known from context or local environment, ask the user for it.
---

# Obsidian Vault

Work with notes inside an Obsidian vault without assuming a fixed vault path.

## Vault root

Before doing note work, determine the vault root.

Use this order:

1. If the user gave the vault path, use it.
2. If the current project clearly contains an Obsidian vault marker such as `.obsidian/`, use that.
3. If there is one obvious local vault candidate, confirm it in your own reasoning and use it.
4. Otherwise, ask the user for the vault root instead of guessing.

Do not hardcode a machine-specific vault location into output or instructions.

## What to do

Use this skill when the user wants to:

- find notes
- create notes
- reorganize notes
- add or fix links between notes
- build or update index notes

## Conventions

- Prefer Obsidian `[[wikilinks]]` when linking notes.
- Preserve the user’s existing vault conventions if they are obvious.
- If conventions are not obvious, use simple note titles and link related notes explicitly.

## Workflow

1. Resolve the vault root.
2. Search by filename and content before creating duplicates.
3. If creating a note, choose a clear note title and add links to related notes when helpful.
4. If reorganizing, prefer small edits over large restructures unless the user asked for a broader cleanup.

## Useful commands

Search by filename:

```bash
find "$VAULT_ROOT" -name "*.md" | grep -i "keyword"
```

Search by content:

```bash
grep -rl "keyword" "$VAULT_ROOT" --include="*.md"
```

Find backlinks:

```bash
grep -rl "\\[\\[Note Title\\]\\]" "$VAULT_ROOT" --include="*.md"
```

## Rules

- Ask for the vault root when it is not safely discoverable.
- Do not invent a vault path.
- Do not create duplicate notes when an existing one already covers the topic.
