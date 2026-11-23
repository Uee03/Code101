# Design Patterns 201 track state

Last updated: 2026-11-23. Level 201: all 12 lessons **written (not run)**.

## Scope
- Track `patterns`, level 201 (`201-hero-to-super-hero`), 4 phases, 12 lessons, all 22 catalogue patterns. Python 3.10+ and C# on .NET 11 (`net11.0`) in every lesson, a TypeScript sketch in the text only. No packages, no art.
- Authoring policy: no smoke tests. Static check only (`python scripts/verify_labs.py --static patterns/201-hero-to-super-hero`): 12 of 12 lessons report `STATIC` (text contains every code line of `code/` and every expected output; `verify.json` parses). Nothing has been executed. Packs built with `python scripts/build_packs.py patterns-201`.
- The level 101 files (`_BRIEF.md`, `_STATE.md`, `GLOSSARY.md`, `101-zero-to-hero/`) are not touched by this level.

## Lessons
| Lesson | Phase | Status | Notes |
|---|---|---|---|
| [01. Factory Method and Abstract Factory](201-hero-to-super-hero/phase-1-creational/01-factory-method-and-abstract-factory.md) | 1 | written (not run) | introduces the three pattern families; csproj explained line by line |
| [02. Builder and Prototype](201-hero-to-super-hero/phase-1-creational/02-builder-and-prototype.md) | 1 | written (not run) | shallow vs deep copy shown in the output |
| [03. Singleton and why dependency injection is usually better](201-hero-to-super-hero/phase-1-creational/03-singleton-and-dependency-injection.md) | 1 | written (not run) | hidden-state output; DI container snippet is reading only; phase 1 mixed review |
| [04. Adapter and Facade](201-hero-to-super-hero/phase-2-structural/04-adapter-and-facade.md) | 2 | written (not run) | wrapper comparison table |
| [05. Decorator and Proxy](201-hero-to-super-hero/phase-2-structural/05-decorator-and-proxy.md) | 2 | written (not run) | order-dependent output; caching and protection proxy |
| [06. Composite and Flyweight](201-hero-to-super-hero/phase-2-structural/06-composite-and-flyweight.md) | 2 | written (not run) | shared-object proof (`same object: True`) |
| [07. Bridge](201-hero-to-super-hero/phase-2-structural/07-bridge.md) | 2 | written (not run) | structural decision table; phase 2 mixed review |
| [08. Strategy and State](201-hero-to-super-hero/phase-3-behavioral/08-strategy-and-state.md) | 3 | written (not run) | introduces the behavioral family; Mermaid state diagram |
| [09. Observer and Mediator](201-hero-to-super-hero/phase-3-behavioral/09-observer-and-mediator.md) | 3 | written (not run) | C# `event` snippet is reading only |
| [10. Command and Memento](201-hero-to-super-hero/phase-3-behavioral/10-command-and-memento.md) | 3 | written (not run) | undo by inverse vs by snapshot |
| [11. Iterator, Template Method, Visitor and Chain of Responsibility](201-hero-to-super-hero/phase-3-behavioral/11-iterator-template-method-visitor-chain.md) | 3 | written (not run) | four patterns, two sittings; behavioral decision table; phase 3 mixed review |
| [12. Choosing, combining and refactoring toward patterns](201-hero-to-super-hero/phase-4-choosing-patterns/12-choosing-combining-refactoring.md) | 4 | written (not run) | decision table for all 22, anti-patterns, same-as-before refactoring; course-wide mixed review |

## Open items
- Run `python scripts/verify_labs.py source/patterns/201-hero-to-super-hero` when Python and .NET are available; compare every Expected output and every "typical message" in Common mistakes with the real tool output; then remove the draft notice and set `verified:`.
- Mermaid diagrams (about 30 class, state and flow diagrams) were checked by reading against the official syntax, not rendered. Render them once (VS Code preview or `mermaid-cli`).
- C# points to confirm on the first real build: `using System.Collections;` with the explicit `IEnumerator IEnumerable.GetEnumerator()` in lesson 11 `Iterator.cs`; the tuple-array parameter `Render((string Name, int Quantity)[] rows)` called with `(string, int)[]` in lesson 11 `TemplateMethod.cs`; the global-namespace `Item` record shared by the `Before` and `After` namespaces in lesson 12; the local function and `kinds.All(kind => ...)` in the lesson 12 solution; `Catalog.Discounts.TryGetValue(..., out IDiscount? discountRule)` nullable flow.
- Python points to confirm: module names `decorator`, `iterator`, `proxy`, `state`, `strategy` do not clash with packages installed on the learner's machine (the script folder comes first on the path, so they should not); `dict[tuple[str, str], TreeType]` as an attribute annotation (3.9+).
- Python and C# outputs were made identical by construction (whole numbers, `True` and `False` with capitals); confirm `bool` printing in both languages.
- No beginner, intermediate or senior walk-through has been done (the `simulating-learners` skill); recommended order: lesson 01, 05, 11, 12.
- Rung 3 exercises have no single answer by design.
- Level 301 for this track (patterns in the wild) is written: see [_STATE-301.md](_STATE-301.md). Lesson 12 links to [Patterns 301 lesson 01](301-super-hero-to-legendary/phase-1-application-patterns/01-di-containers-and-composition-roots.md).
