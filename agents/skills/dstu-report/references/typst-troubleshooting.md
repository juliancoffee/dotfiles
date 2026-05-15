# Typst Troubleshooting

Use this when the problem is Typst behavior rather than DSTU wording.

The target of troubleshooting is normally the user's actual `.typ` document or Typst project, not the bundled example files.
Treat Typst itself as an external dependency whose exact behavior may be unclear, underdocumented, or changed from memory.

## Order

1. Read the target document or project first.
2. If the issue may come from shared template behavior, read the relevant helper in `assets/package/lib.typ` and the closest bundled example.
3. If the uncertainty is about Typst itself, check official Typst docs early.
4. If docs are incomplete or the behavior looks buggy, search Typst GitHub issues and discussions immediately.
5. Build a minimal repro in `/tmp` whenever a small isolated case will clarify the situation.
6. Compile the actual target document, or the minimal repro if you built one.

## Temporary repro pattern

Use `/tmp`, not the user's project tree, when you need a Typst-only repro.

Put the minimal files the repro needs into one scratch directory and compile that directory directly:

```bash
mkdir -p /tmp/typst-repro
cp -R assets/package /tmp/typst-repro/package
$EDITOR /tmp/typst-repro/main.typ
typst compile /tmp/typst-repro/main.typ /tmp/typst-repro/out.pdf
```

If the issue is visual, render a page to `/tmp/*.png` and inspect that image instead of guessing.

Prefer `uv run --with ...` for ad hoc PDF tooling instead of assuming a local Python dependency is already installed. If a PDF/image conversion dependency is missing, follow the `doctools` skill pattern.

Example page rasterization with PyMuPDF:

```bash
uv run --with pymupdf python - <<'PY'
import fitz

pdf = fitz.open("/tmp/typst-repro/out.pdf")
page = pdf[0]
pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
pix.save("/tmp/typst-repro/page-1.png")
PY
```

Render only the page or small page range under review.

## What to search first

1. Official Typst docs for the relevant construct:
   - `outline`
   - `label`
   - `link`
   - `counter`
   - `show`
   - `figure`
   - `table`
   - `raw`

2. Typst GitHub issues and discussions as soon as docs do not clarify real behavior.

## Suggested issue-search queries

Prefer targeted searches such as:

- `site:github.com/typst/typst/issues outline.entry link label`
- `site:github.com/typst/typst/issues counter at label`
- `site:github.com/typst/typst/issues figure caption label attach`
- `site:github.com/typst/typst/issues raw inline block`
- `site:github.com/typst/typst/issues ukrainian enum numbering`

If discussions are more relevant:

- `site:github.com/typst/typst/discussions outline clickable toc`
- `site:github.com/typst/typst/discussions label ref counter`

## When to trust issue search

Use issue results to understand:
- parser limitations
- label attachment rules
- rendering quirks
- known workarounds
- whether a behavior is intentional or a bug

Do not use issue results as a source for DSTU requirements. For DSTU rules, use the local standard copy.

## Typical mistakes to avoid

- Do not guess that a standalone `label(...)` is attached to the intended element.
- Do not assume a visual fix is correct without recompiling and checking the rendered page.
- Do not leave scratch render folders in the user's project; keep diagnostics in `/tmp`.
- Do not add per-document helper layers when the behavior should live in the shared package.
- Do not install persistent Python dependencies just to rasterize a PDF page; use `uv run --with ...`.
- Do not treat external Typst search as a reluctant last resort when the uncertainty is clearly about Typst itself.
