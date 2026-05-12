---
name: doctools
description: Use transient Python dependencies with `uv run --with ...` when Codex needs a library that is not installed, especially for inspecting, extracting, converting, or summarizing local files such as PDFs, DOCX, XLSX, legacy Office files, PPTX, archives, HTML, XML, and other structured documents. Use when shell tools or Python modules are missing and the right response is to enrich the command with ad hoc packages instead of stopping at `command not found` or a missing import.
---

# DocTools

## Overview

Treat missing local tooling as a prompt to enrich the command, not to give up. Prefer `uv run --with ... python - <<'PY'` for one-off file processing so the repo stays clean and the command remains reproducible.

## Workflow

1. Check whether a built-in tool already solves the task. Use it if it is present and clearly sufficient.
2. If the needed CLI or import is missing, switch immediately to `uv run --with ...` instead of stopping at the failure.
3. Keep the Python inline, task-specific, and short. Print extracted data to stdout unless the task clearly needs a file.
4. Add multiple `--with` flags when the task needs more than one dependency.
5. Pin versions only when compatibility matters or the command will be reused.
6. For repeated work in the same repo, consider turning the inline snippet into a script after the first successful run.

## Default Pattern

```bash
uv run --with <package> python - <<'PY'
# one-off code here
PY
```

Use multiple packages like this:

```bash
uv run --with pypdf --with pdfplumber python - <<'PY'
# code that uses both libraries
PY
```

## Rules

- Do not stop at `command not found` for tools like `pdftotext`, `xlsx2csv`, `antiword`, or similar utilities if Python libraries can handle the job.
- Do not add permanent dependencies to the current project just to inspect one local file.
- Prefer libraries that extract the actual structured content rather than scraping binary bytes with `strings`.
- Prefer emitting machine-readable output such as JSON, TSV, or plain text when another command will consume the result.
- If a binary Office format is awkward in pure Python, first try a conversion path such as `libreoffice --headless` if available; otherwise choose the best Python fallback from the reference sheet.

## Common Uses

### Read a PDF

```bash
uv run --with pypdf python - <<'PY'
from pathlib import Path
from pypdf import PdfReader

path = Path("file.pdf")
reader = PdfReader(path)
for i, page in enumerate(reader.pages, 1):
    text = page.extract_text() or ""
    print(f"--- page {i} ---")
    print(text[:4000])
PY
```

### Inspect an XLSX workbook

```bash
uv run --with openpyxl python - <<'PY'
from openpyxl import load_workbook

wb = load_workbook("book.xlsx", read_only=True, data_only=True)
print(wb.sheetnames)
ws = wb[wb.sheetnames[0]]
for row in ws.iter_rows(min_row=1, max_row=10, values_only=True):
    print(row)
PY
```

### Read a DOCX document

```bash
uv run --with python-docx python - <<'PY'
from docx import Document

doc = Document("file.docx")
for p in doc.paragraphs[:20]:
    if p.text.strip():
        print(p.text)
PY
```

## Reference

Read [references/file-types.md](references/file-types.md) for package choices and fallback order by file type.
