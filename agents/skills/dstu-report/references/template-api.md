# Template API

The bundled implementation lives in `assets/package/lib.typ`.

Use the bundled examples in `assets/examples/` as the primary reference patterns.

When working on a user's real project, do not copy the bundled package into that
project by default. Install it as a Typst local package with
`scripts/install_local_package.sh` and import it through `@local/...`.

## Main entrypoint

```typ
#import "@local/dstu-report:0.1.0": template
```

The main show rule pattern is:

```typ
#show: template.with(
  institution: [...],
  department: [...],
  document-type: [...],
  title: [...],
  author-block: [...],
  supervisor-block: [...],
  city: [...],
  year: 2026,
  auto-outline: false,
)
```

## Shared helpers

### Figures

```typ
#import "@local/dstu-report:0.1.0": dstu-image-figure, figure-ref

На #figure-ref("publication-years") показано ...

#dstu-image-figure(
  image("figures/publication-years.png", width: 100%),
  [Розподіл результатів за роками],
  key: "publication-years",
)
```

- `dstu-image-figure(...)` renders the image plus DSTU-style caption.
- `figure-ref("key")` links to that figure and prints the number with the default Ukrainian case.
- Override the word form with `form: [...]` when needed.
- The figure body can be `image(...)`, `svg(...)`, or another prepared visual block.
- If the document needs a chart that does not exist yet, generate the asset with a short script first and then include the resulting file here.

Example chart-generation flow:

```bash
uv run --with matplotlib python scripts/make_chart.py assets/examples/chart-data.csv /tmp/chart.png --title "Результати"
```

### Tables

```typ
#import "@local/dstu-report:0.1.0": dstu-table-figure, table-ref, report-table

У #table-ref("corpus-summary") наведено ...

#dstu-table-figure(
  [Підсумок експерименту],
  report-table[
    #table(...)
  ],
  key: "corpus-summary",
)
```

- `dstu-table-figure(...)` renders a DSTU-style table caption above the table.
- `table-ref("key")` links to that table and prints the number with the default Ukrainian case.
- `report-table[...]` is a formatting wrapper for dense report tables.

### Bibliography-style references

```typ
#import "@local/dstu-report:0.1.0": cite, ref-row, url-link, references

Твердження підтверджено #cite(2, 3, 5).

#references[
  #ref-row(2, [
    Автор. Назва. URL: #url-link("https://example.com") (дата звернення: 14.05.2026).
  ])
]
```

- `cite(...)` emits linked bracketed numeric references.
- `ref-row(...)` renders one numbered bibliography row and attaches the anchor label.
- `references[...]` emits the final `Перелік джерел посилання` section at the end of the document.
- `url-link(...)` renders a clickable literal URL.

## Examples to copy from

- `assets/examples/starter-report.typ`
  Use for a new report skeleton.
- `assets/examples/figures-and-tables.typ`
  Use for figures, tables, and cross-references.
- `assets/examples/references.typ`
  Use for linked numeric citations and bibliography rows.

## Code blocks

Prefer normal fenced code blocks for static code samples in report text.

```typ
```python
print("hello")
```
```

Do not hand-write manual raw-function calls for ordinary examples unless the
content is being generated programmatically or a fenced block cannot express
the needed Typst behavior.
