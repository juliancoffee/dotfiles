---
name: dstu-report
description: "Use when Codex needs to create, revise, review, or troubleshoot Ukrainian Typst documents that should follow `dstu-report` conventions. Trigger for creating a new report, migrating an existing Typst file to the template, fixing headings/lists/figures/tables/references, wiring citations with the shared helpers, or resolving Typst behavior that needs official docs or Typst GitHub issues/discussions."
---

# DSTU Report

Work on the user's actual `.typ` document or Typst project.

This skill is self-contained. Everything it needs lives inside the skill:

- `assets/package/`: bundled `dstu-report` package files
- `assets/examples/`: bundled example documents that show how to use the package
- `references/`: bundled API notes, DSTU rules, and Typst troubleshooting guidance

## Typical Requests

- "Create a new Typst report in DSTU style."
- "Take this existing Typst file and make it follow the template."
- "Fix the title page, headings, and page numbering."
- "Convert manual figure/table references to shared helpers."
- "Fix citations and bibliography links."
- "Why is this Typst label/counter/ref behavior broken?"

## Quick Workflow

1. Read the user's target `.typ` file first.
2. If the user is starting from scratch, begin from `assets/examples/starter-report.typ`.
3. Read `references/template-api.md` for the shared helper surface.
4. Read `references/dstu-rules.md` when the question is about document rules rather than Typst mechanics.
5. Edit the user's actual target.
6. Recompile the user's actual target document.
7. When layout matters, inspect the rendered result instead of guessing.

Keep scratch PDFs and rendered images in `/tmp`, not in the user's project tree.
For visual checks, render only the pages you need.

## Shared Helpers

Reach for these before inventing local `#let` glue:

- `template`
- `dstu-image-figure(...)`
- `dstu-table-figure(...)`
- `figure-ref(...)`
- `table-ref(...)`
- `cite(...)`
- `ref-row(...)`
- `references[...]`
- `url-link(...)`
- `report-table[...]`

Read `references/template-api.md` for usage snippets taken from the bundled examples.

## Bibliography Rules

- Bibliography entries may only be built from external papers or URL-addressable sources.
- Do not create bibliography entries from local repo files, local PDFs, disk paths, or other on-disk project artifacts.
- If the available material is only a local file on disk and no proper external source or URL exists, omit it from the bibliography instead of fabricating a citation.

## Creation

For a new document, do **not** copy `assets/package/` into the user's project.
The bundled package is reference material owned by the skill, not something to
spray into arbitrary repos.

Instead:

1. install the bundled package into Typst's local package directory with
   `python3 scripts/install_local_package.py`;
2. create the user's actual `.typ` file where the user wants it;
3. have the document import the package through Typst's local package
   mechanism, not through direct file paths.

Then start from `assets/examples/starter-report.typ`, adapt its structure to the
user's real document, and keep the canonical entrypoint form:

```typ
#import "@local/dstu-report:0.1.0": template
```

Apply the template with `#show: template.with(...)`.

Projects using this skill must import the template through `@local/...` package
imports. Do not copy the package into the project, do not symlink it into the
project, and do not use machine-specific absolute paths inside the Typst
source.

## When To Use Examples

Use the bundled examples as references for:

- title-page structure
- figure and table helpers
- bibliography rows and linked citations
- code blocks
- long-form report structure

Examples live here:

- `assets/examples/starter-report.typ`
- `assets/examples/figures-and-tables.typ`
- `assets/examples/references.typ`

## Code Blocks

Prefer normal fenced code blocks for static examples:

```typ
```python
print("hello")
```
```

Do not hand-write manual raw-function calls for ordinary code samples in user
documents.

Use explicit raw-function calls only when the raw content is being generated
programmatically or when a Typst-specific constraint makes a fenced block
insufficient.

## Images And Charts

You are allowed to prepare supporting visual assets when the document needs them.

- Include existing images, diagrams, SVGs, or screenshots when the report needs figures.
- If a chart or other data visualization is missing, write a small script that generates it instead of drawing it by hand in Typst.
- Use `uv run --with ...` for one-off plotting or image-processing dependencies instead of assuming they are preinstalled.
- Write generated charts or converted images to a scratch or project-local assets directory, then include them from Typst with `image(...)` and wrap them with `dstu-image-figure(...)`.

Typical chart-generation shape:

```bash
uv run --with matplotlib python scripts/make_chart.py assets/examples/chart-data.csv /tmp/chart.png --title "Результати"
```

Typical Typst usage after generation:

```typ
#dstu-image-figure(
  image("figures/chart.png", width: 100%),
  [Назва рисунка],
  key: "chart",
)
```

## Typst Uncertainty

If the uncertainty is about Typst itself rather than DSTU wording:

1. Check the bundled helper or example closest to the problem.
2. Check official Typst docs early.
3. If docs are incomplete, ambiguous, or the behavior looks buggy, search Typst GitHub issues and discussions immediately.
4. Build a minimal repro in `/tmp` when that will clarify the behavior faster.

Read `references/typst-troubleshooting.md` for the search posture and repro pattern.

## Visual Validation

When a fix is visual, do not just trust the source diff. Recompile and inspect the rendered page image.

For PDF page extraction or rasterization, use `uv run --with ...` instead of assuming the needed Python package is already installed. If the environment is missing a document-processing dependency, use the `doctools` skill pattern.

Typical command shape:

```bash
uv run --with pymupdf python - <<'PY'
import fitz

pdf = fitz.open("/tmp/out.pdf")
page = pdf[1]
pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
pix.save("/tmp/out-page-2.png")
PY
```

Render only the page or small page set you actually need to review.

## Extra References

- `references/template-api.md`: shared helper usage
- `references/dstu-rules.md`: DSTU rules that affect template use
- `references/typst-troubleshooting.md`: Typst docs/issues search guidance
