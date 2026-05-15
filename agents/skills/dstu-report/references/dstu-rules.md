# DSTU Rules

Use this file when the question is about document rules rather than Typst mechanics.

This is a compact working summary for report authoring and template use. It is not a full reproduction of the standard.

## Page setup

- Main text size: `14pt`.
- Title page counts as page 1, but its page number is not printed.
- Other page numbers go in the upper-right corner.

## Structural elements

These are normally unnumbered:

- `ЗМІСТ`
- `ВСТУП`
- `ВИСНОВКИ`
- `ПЕРЕЛІК ДЖЕРЕЛ ПОСИЛАННЯ`
- `ДОДАТКИ`

Ordinary sections and subsections are numbered with Arabic numerals.

## Headings

- Number ordinary sections like `1`, `2`, `3`.
- Do not add a trailing dot after the section number.
- Keep structure consistent in the table of contents and the body.

## Lists

- If the preceding sentence introduces a list, end that sentence with a colon.
- Use ordinary dash lists for unreferenced lists.
- Use referenced enumerations when the surrounding text refers to items explicitly.
- Referenced enumerations follow this pattern:
  - first level: `а)`
  - second level: `1)`
  - deeper levels: dash lists
- When the list continues the sentence, items normally start with lowercase and use `;` between items, with `.` on the last item.

## Figures

- Mention the figure in the text before or near the figure itself.
- Place the caption below the figure.
- Use a caption shape like `Рисунок 2.1 -- Назва`.

## Tables

- Mention the table in the text before or near the table itself.
- Place the caption above the table.
- Use a caption shape like `Таблиця 3.2 -- Назва`.

## References

- Keep bibliography numbering consistent with in-text numeric citations.
- Use linked bracketed citations like `[4]`, `[7]`, `[12]`.
- Keep URLs literal and clickable when the source is online.
