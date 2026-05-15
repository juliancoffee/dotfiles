#let default-font = "Libertinus Serif"
#let default-mono-font = "DejaVu Sans Mono"
#let dstu-image-counter = counter("dstu-image")
#let dstu-table-counter = counter("dstu-table")

#let appendix-label(n) = {
  let letters = (
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
    "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
  )

  if n <= letters.len() {
    letters.at(n - 1)
  } else {
    str(n)
  }
}

#let dstu-title-page(
  ministry: none,
  institution: [],
  faculty: none,
  department: none,
  title: [],
  subtitle: none,
  document-type: [Звіт],
  author: none,
  author-block: none,
  author-label: [Виконав(-ла)],
  supervisor: none,
  supervisor-block: none,
  supervisor-label: [Керівник],
  subject: none,
  city: [],
  year: none,
) = {
  set align(center)
  set text(size: 14pt)
  set text(hyphenate: false)
  set par(justify: false, first-line-indent: 0pt)

  v(0pt, weak: true)
  if ministry != none {
    strong(upper(ministry))
    v(6pt)
  }
  strong(upper(institution))
  if faculty != none {
    v(8pt)
    faculty
  }
  if department != none {
    v(8pt)
    department
  }

  v(4.5cm)
  strong(upper(document-type))
  if subject != none {
    v(14pt)
    [з дисципліни «#subject»]
  }
  v(18pt)
  strong(title)

  if subtitle != none {
    v(12pt)
    subtitle
  }

  v(2.5cm)
  let author-group = if author != none {
    author.at("group", default: none)
  } else {
    none
  }
  align(left)[
    #block(width: 9cm, align(left)[
      #if author-block != none [
        #author-label: \
        #author-block
      ] else if author != none [
        #author-label: #author.name \
        #if author-group != none [Група #author-group]
      ]
      #if (author-block != none or author != none) and (supervisor-block != none or supervisor != none) [
        \
      ]
      #if supervisor-block != none [
        #supervisor-label: \
        #supervisor-block
      ] else if supervisor != none [
        #supervisor-label: #supervisor
      ]
    ])
  ]

  v(1fr)
  city
  if year != none {
    [ #year ]
  }
  pagebreak()
}

#let dstu-section-prefix() = context {
  let nums = counter(heading).get()
  if nums.len() > 0 {
    str(nums.at(0))
  } else {
    "1"
  }
}

#let dstu-image-number() = context {
  dstu-section-prefix() + "." + str(dstu-image-counter.get().first())
}

#let dstu-table-number() = context {
  dstu-section-prefix() + "." + str(dstu-table-counter.get().first())
}

#let dstu-section-prefix-at(key) = context {
  let nums = counter(heading).at(label(key))
  if nums.len() > 0 {
    str(nums.at(0))
  } else {
    "1"
  }
}

#let dstu-image-number-at(key) = context {
  dstu-section-prefix-at(key) + "." + str(dstu-image-counter.at(label(key)).first())
}

#let dstu-table-number-at(key) = context {
  dstu-section-prefix-at(key) + "." + str(dstu-table-counter.at(label(key)).first())
}

#let figure-ref(key, form: [рисунку]) = context {
  link(label(key))[#form #dstu-image-number-at(key)]
}

#let table-ref(key, form: [таблиці]) = context {
  link(label(key))[#form #dstu-table-number-at(key)]
}

#let cite(sep: [, ], ..nums) = {
  let raw = nums.pos()
  let ns = if raw.len() == 1 and type(raw.at(0)) == array {
    raw.at(0)
  } else {
    raw
  }

  text("[")
  for i in range(ns.len()) {
    if i > 0 {
      sep
    }
    let n = ns.at(i)
    link(label("ref-" + str(n)))[#str(n)]
  }
  text("]")
}

#let ref-row(n, txt) = table(
  columns: (10mm, 1fr),
  stroke: none,
  gutter: 4pt,
  inset: 0pt,
  align: (left, left),
  [#n.],
  [#txt #label("ref-" + str(n))],
)

#let url-link(url) = link(url)[#url]

#let references(body) = [
  #pagebreak(weak: true)
  #heading(level: 1, numbering: none)[Перелік джерел посилання]
  #body
]

#let report-table(body) = block(width: 100%)[
  #set par(justify: false, first-line-indent: 0pt, leading: 1.2em)
  #set text(hyphenate: false)
  #body
]

#let dstu-image-figure(body, caption, width: 100%, key: none) = context [
  #dstu-image-counter.step()
  #let caption-line = [Рисунок #dstu-image-number() -- #caption]
  #align(center)[#box(width: width, body)]
  #v(6pt)
  #align(center)[
    #if key != none {
      [#caption-line #label(key)]
    } else {
      caption-line
    }
  ]
  #v(6pt)
]

#let dstu-table-figure(caption, body, key: none) = context [
  #dstu-table-counter.step()
  #let caption-line = [Таблиця #dstu-table-number() -- #caption]
  #par(first-line-indent: 0pt, justify: false)[
    #if key != none {
      [#caption-line #label(key)]
    } else {
      caption-line
    }
  ]
  #v(6pt)
  #body
]

#let dstu-report(
  title: [],
  ministry: none,
  institution: [],
  faculty: none,
  department: none,
  document-type: [Звіт],
  subtitle: none,
  author: none,
  author-block: none,
  author-label: [Виконав(-ла)],
  supervisor: none,
  supervisor-block: none,
  supervisor-label: [Керівник],
  subject: none,
  city: [],
  year: none,
  abstract: none,
  keywords: (),
  appendix-prefix: [Додаток],
  auto-outline: true,
  body,
) = {
  set page(
    paper: "a4",
    margin: (
      left: 30mm,
      right: 10mm,
      top: 20mm,
      bottom: 20mm,
    ),
    numbering: none,
    header: context {
      let page-num = counter(page).get().first()
      if page-num > 1 {
        align(right, str(page-num))
      }
    },
  )

  set text(
    lang: "uk",
    font: default-font,
    size: 14pt,
    fill: rgb("#000000"),
  )
  set par(
    justify: true,
    first-line-indent: 1.25cm,
    leading: 0.75em,
  )
  set heading(numbering: "1.1")
  set figure(numbering: "1.1")
  set list(
    indent: 1.25cm,
    body-indent: 0.75cm,
    marker: [--],
  )
  set terms(indent: 1.25cm, hanging-indent: 0.75cm)

  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    v(0pt, weak: true)
    set align(center)
    set text(weight: "bold")
    set text(hyphenate: false)
    set par(first-line-indent: 0pt)
    dstu-image-counter.update(0)
    dstu-table-counter.update(0)
    if it.numbering == none {
      upper(it.body)
    } else {
      let num = counter(heading).display(it.numbering)
      [#num #upper(it.body)]
    }
    v(2em)
  }

  show heading.where(level: 2): it => {
    v(2em)
    set text(weight: "bold")
    set text(hyphenate: false)
    set par(first-line-indent: 1.25cm, justify: false)
    block(width: 100%)[#it]
    v(2em)
  }

  show heading.where(level: 3): it => {
    set text(weight: "bold")
    it
  }

  show ref: it => {
    set text(style: "italic")
    it
  }

  // Issue #1595 Fix: Non-latin enumerations (lists) are cursed
  let enum-depth = state("enum-depth", 0)
  show enum: it => {
    enum-depth.update(d => d + 1)
    it
    enum-depth.update(d => d - 1)
  }
  set enum(
    indent: 1.25cm,
    numbering: n => context {
      let d = enum-depth.get()
      if d == 1 {
        // Apparently, DSTU 3008:95 doesn't allow certain letters
        // https://www.dnu.dp.ua/docs/ndc/standarts/DSTU_3008-95.pdf
        let alphabet = (
          "а", "б", "в", "г", "д", "е", "ж", "з", "и", "к", "л", "м",
          "н", "п", "р", "с", "т", "у", "ф", "х", "ц", "ш", "щ", "ю",
          "я",
        )
        if n <= alphabet.len() {
          alphabet.at(n - 1) + ")"
        } else {
          str(n) + ")"
        }
      } else if d == 2 {
        str(n) + ")"
      } else {
        [---]
      }
    },
  )

  show raw: it => {
    if it.block {
      set par(justify: false, first-line-indent: 0pt, leading: 1.2em)
      set text(font: default-mono-font, size: 10pt, fill: rgb("#000000"))
      block(
        stroke: 0.5pt,
        inset: 8pt,
        width: 100%,
        breakable: true,
        it,
      )
    } else {
      box(
        inset: (x: 2pt, y: 0pt),
        radius: 2pt,
        text(font: default-mono-font, size: 0.95em, it.text),
      )
    }
  }

  dstu-title-page(
    ministry: ministry,
    institution: institution,
    faculty: faculty,
    department: department,
    title: title,
    subtitle: subtitle,
    document-type: document-type,
    author: author,
    author-block: author-block,
    author-label: author-label,
    supervisor: supervisor,
    supervisor-block: supervisor-block,
    supervisor-label: supervisor-label,
    subject: subject,
    city: city,
    year: year,
  )

  if abstract != none {
    heading(level: 1, numbering: none)[Реферат]
    par(first-line-indent: 0pt)[#abstract]
    if keywords.len() > 0 {
      par(first-line-indent: 0pt)[
        *Ключові слова:* #keywords.join(", ")
      ]
    }
  }

  if auto-outline {
    outline(title: [Зміст])
    pagebreak()
  }
  body
}

#let dstu-appendix(title, index: 1, prefix: [Додаток], body) = [
  #pagebreak(weak: true)
  #set align(center)
  *#prefix #appendix-label(index)* \
  *#title*

  #set align(left)
  #body
]

#let template = dstu-report
