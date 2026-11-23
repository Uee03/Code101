# Design Patterns + SOLID track state (level 101)

Last updated: 2026-11-23. Level 101: all 9 lessons **written (not run)**.

## Scope
- Track `patterns`, level 101 (`101-zero-to-hero`), 2 phases, 9 lessons. Python 3.10+ and C# on .NET 11 (`net11.0`) in every lesson. No packages, no art.
- Authoring policy: no smoke tests. Static check only (`python scripts/verify_labs.py --static patterns/101-zero-to-hero`): 9 of 9 lessons report `STATIC` (text contains every code line and every expected output; `verify.json` parses). Nothing has been executed.
- Level 201 is owned by another author in separate files.

## Lessons
| Lesson | Phase | Status | Notes |
|---|---|---|---|
| [01. Why design matters](101-zero-to-hero/phase-1-solid/01-why-design-matters.md) | 1 | written (not run) | coupling, cohesion, smells; flowchart instead of class diagram (no classes yet) |
| [02. Single Responsibility](101-zero-to-hero/phase-1-solid/02-single-responsibility.md) | 1 | written (not run) | Invoice split in four |
| [03. Open/Closed](101-zero-to-hero/phase-1-solid/03-open-closed.md) | 1 | written (not run) | introduces interface / ABC, polymorphism, dictionary lookup |
| [04. Liskov Substitution](101-zero-to-hero/phase-1-solid/04-liskov-substitution.md) | 1 | written (not run) | type hints; commented-out forbidden line |
| [05. Interface Segregation](101-zero-to-hero/phase-1-solid/05-interface-segregation.md) | 1 | written (not run) | silent stub bug |
| [06. Dependency Inversion and injection by hand](101-zero-to-hero/phase-1-solid/06-dependency-inversion.md) | 1 | written (not run) | composition root, fake, hand-made check; phase 1 mixed review |
| [07. DRY, KISS and YAGNI](101-zero-to-hero/phase-2-everyday-principles/07-dry-kiss-yagni.md) | 2 | written (not run) | includes "when DRY is wrong" (lookalikes) |
| [08. Composition over inheritance](101-zero-to-hero/phase-2-everyday-principles/08-composition-over-inheritance.md) | 2 | written (not run) | channel and tone parts; Strategy named |
| [09. Reading and drawing class diagrams, and a mixed review](101-zero-to-hero/phase-2-everyday-principles/09-class-diagrams-and-review.md) | 2 | written (not run) | Mermaid notation, read/draw, refactor review; two sittings |

## Open items
- Run `python scripts/verify_labs.py source/patterns/` when Python and .NET are available; compare every Expected output and every "typical message" in Common mistakes with the real tool output; then remove the draft notice and set `verified:`.
- Mermaid diagrams (about 20) were checked by reading against the official class diagram syntax, not rendered. Render them once (VS Code preview or `mermaid-cli`).
- C# points to confirm on the first real build: tuple alias `using Item = (...)` in each file, `string.Join("", IEnumerable<char>)` in lesson 07's starter, and the unused-local-function warning in the lesson 07 starter.
- A beginner walk-through has not been done (the `simulating-learners` skill); recommended for lessons 03 and 06 first, where the new vocabulary (interface, abstract base class, injection) is densest.
- Rung 3 exercises have no single answer by design.
