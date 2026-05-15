#import "../package/lib.typ": template, dstu-image-figure, dstu-table-figure, figure-ref, table-ref, report-table

#show: template.with(
  institution: [Назва закладу вищої освіти],
  department: [Назва кафедри],
  document-type: [Звіт],
  title: [Приклад рисунків і таблиць],
  author: (
    name: [Ім'я Прізвище],
    group: [ІП-01],
  ),
  supervisor: [Проф. Ім'я Прізвище],
  city: [Київ],
  year: 2026,
)

= Основна частина
На #figure-ref("scheme") показано спрощену схему процесу. У #table-ref("results")
наведено приклад підсумкових значень.

#dstu-image-figure(
  rect(width: 90%, height: 5cm, stroke: 0.8pt),
  [Схема оброблення даних],
  key: "scheme",
)

#dstu-table-figure(
  [Підсумкові значення],
  report-table[
    #table(
      columns: (2fr, 1fr),
      inset: 6pt,
      stroke: 0.6pt,
      table.header([Показник], [Значення]),
      [Кількість документів], [42],
      [Кількість рисунків], [1],
      [Кількість таблиць], [1],
    )
  ],
  key: "results",
)
