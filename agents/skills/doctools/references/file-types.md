# File Type Guide

Use this reference when a local tool is missing and the task should continue via `uv run --with`.

## Package Selection

| Format | First choice | Alternatives | Notes |
| --- | --- | --- | --- |
| `.pdf` | `pypdf` | `pdfplumber`, `pymupdf` | Start with `pypdf` for text extraction and metadata. Use `pdfplumber` for layout-aware extraction. Use `pymupdf` for stubborn PDFs or page rendering. |
| `.docx` | `python-docx` | `docx2txt`, `mammoth` | `python-docx` is best for paragraphs, tables, and structure. `docx2txt` is lighter for plain text. `mammoth` is useful when converting to HTML. |
| `.xlsx` | `openpyxl` | `pandas`, `pyxlsb` | `openpyxl` is the default for workbook inspection. Add `pandas` when table reshaping helps. Use `pyxlsb` for `.xlsb`. |
| `.xls` | `pandas` + `xlrd` | `python-calamine` | Legacy binary Excel is less pleasant. If pure Python is messy, try converting with LibreOffice first. |
| `.doc` | conversion first | `textract`, `olefile` | Legacy Word `.doc` support is weaker. Prefer `libreoffice --headless --convert-to docx` when available, then read the `.docx`. Use Python only as fallback. |
| `.pptx` | `python-pptx` | `zipfile` + XML parsing | Use `python-pptx` for slide text, shapes, and notes. |
| `.csv` / `.tsv` | built-in `csv` | `pandas` | No extra deps needed unless the file is large or messy. |
| `.json` / `.jsonl` | built-in `json` | `orjson` | No extra deps needed in most cases. |
| `.xml` / `.html` | `beautifulsoup4` | `lxml` | `lxml` is useful for XPath-heavy work. |
| archives | built-in `zipfile`, `tarfile` | `py7zr`, `rarfile` | Add a package only for unsupported archive types. |

## Quick Commands

### PDF to text

```bash
uv run --with pypdf python - <<'PY'
from pypdf import PdfReader
reader = PdfReader("file.pdf")
print("\n".join(page.extract_text() or "" for page in reader.pages))
PY
```

### PDF with layout-sensitive extraction

```bash
uv run --with pdfplumber python - <<'PY'
import pdfplumber
with pdfplumber.open("file.pdf") as pdf:
    for page in pdf.pages:
        print(page.extract_text() or "")
PY
```

### XLSX sheet preview

```bash
uv run --with openpyxl python - <<'PY'
from openpyxl import load_workbook
wb = load_workbook("file.xlsx", read_only=True, data_only=True)
for name in wb.sheetnames:
    print(name)
PY
```

### DOCX plain text

```bash
uv run --with python-docx python - <<'PY'
from docx import Document
doc = Document("file.docx")
print("\n".join(p.text for p in doc.paragraphs if p.text.strip()))
PY
```

### PPTX slide text

```bash
uv run --with python-pptx python - <<'PY'
from pptx import Presentation
prs = Presentation("deck.pptx")
for i, slide in enumerate(prs.slides, 1):
    print(f"--- slide {i} ---")
    for shape in slide.shapes:
        if hasattr(shape, "text") and shape.text.strip():
            print(shape.text)
PY
```

## Fallback Order

1. Try an existing local CLI if it is already installed and clearly suitable.
2. Switch to `uv run --with ... python`.
3. For awkward legacy formats, try a local conversion tool such as LibreOffice if available.
4. Only stop when both native tools and Python paths are unreasonable or the file is encrypted/corrupted.
