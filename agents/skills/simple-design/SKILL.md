---
name: simple-design
description: Create restrained, production-grade frontend interfaces with strong hierarchy and minimal visual noise. Use this skill for default web UI design work when the user wants something clean, simple, or well-designed. Do not use this skill for requests that explicitly call for exotic, highly expressive, or visually maximalist design.
license: Complete terms in LICENSE.txt
---

This skill guides creation of restrained, production-grade frontend interfaces with strong attention to clarity, spacing, typography, and visual discipline. Implement real working code without unnecessary decorative flourish.

The user provides frontend requirements: a component, page, application, or interface to build. They may include context about the purpose, audience, or technical constraints.

## Design Thinking

Before coding, understand the context and keep the design direction simple and disciplined:
- **Purpose**: What problem does this interface solve? Who uses it?
- **Tone**: Default to restrained minimalism with a mild brutalist bias unless the user clearly asks for something else.
- **Constraints**: Technical requirements (framework, performance, accessibility).
- **Hierarchy**: Make the structure obvious through spacing, grouping, and typography rather than decoration.

Then implement working code (HTML/CSS/JS, React, Vue, etc.) that is:
- Production-grade and functional
- Calm and legible
- Cohesive and intentionally minimal
- Meticulously refined in spacing, contrast, and hierarchy

## Anti-Filler Rules

- Do not add UI just to make the layout feel "complete".
- Every visible element should earn its place through content, navigation, feedback, or interaction.
- Prefer fewer sections with stronger hierarchy over many shallow sections.
- Avoid placeholder marketing copy, fake metrics, decorative badges, empty icons, and other content-lite filler unless the user explicitly wants mock content.
- If a page feels sparse, improve spacing, typography, grouping, or alignment before adding more components.
- Prefer direct layouts over wrapping every piece of content in its own container.
- Do not default to card grids. Use cards only when they clarify repeated, independent items.
- If plain text, lists, tables, or simple sections communicate the content better than cards, use those instead.

## Frontend Aesthetics Guidelines

Focus on:
- **Typography**: Prefer simple, readable sans-serifs or restrained serif pairings. Typography should support clarity first. Strong, slightly severe typography is welcome.
- **Color & Theme**: Default to near-black, white, and gray. Introduce color only when it serves a clear product purpose.
- **Motion**: Keep motion minimal. Use it to clarify state changes or hierarchy, not to decorate.
- **Spatial Composition**: Prefer clean grids, strong alignment, generous whitespace, and unapologetically direct layout decisions.
- **Backgrounds & Visual Details**: Default to plain backgrounds, visible structure, and simple borders. Add texture or effects only when there is a strong reason.

Avoid pushing the interface toward loud visual concepts by default. Do not add accents, unusual layouts, decorative textures, or expressive motion unless the user clearly wants them.

When in doubt, lean slightly brutalist rather than soft or playful:

- high contrast over soft gradients
- clear borders over floating surfaces
- direct structure over decorative polish
- strong hierarchy over ornamental detail

**IMPORTANT**: Match implementation complexity to the visual goal. For a minimalist interface, favor restraint, precision, contrast, and spacing over flourish.
