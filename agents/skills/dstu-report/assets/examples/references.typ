#import "../package/lib.typ": template, cite, ref-row, url-link, references

#show: template.with(
  institution: [Назва закладу вищої освіти],
  department: [Назва кафедри],
  document-type: [Звіт],
  title: [Приклад посилань],
  author: (
    name: [Ім'я Прізвище],
    group: [ІП-01],
  ),
  supervisor: [Проф. Ім'я Прізвище],
  city: [Київ],
  year: 2026,
)

= Основна частина
Підхід спирається на документацію та обговорення типових помилок #cite(1, 2).
Зовнішні джерела оформлюйте єдиним стилем #cite(3).

#references[
  #ref-row(1, [
    Typst Documentation. URL: #url-link("https://typst.app/docs/")
    (дата звернення: 14.05.2026).
  ])
  #ref-row(2, [
    Typst GitHub Issues. URL: #url-link("https://github.com/typst/typst/issues")
    (дата звернення: 14.05.2026).
  ])
  #ref-row(3, [
    OpenAI. URL: #url-link("https://openai.com")
    (дата звернення: 14.05.2026).
  ])
]
