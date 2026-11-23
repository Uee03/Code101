# Design Patterns 301 track state

Last updated: 2026-11-23. Level 301: all 10 lessons **written (not run)**.

## Scope
- Track `patterns`, level 301 (`301-super-hero-to-legendary`), 3 phases, 10 lessons. Python 3.10+ and C# on .NET 11 (`net11.0`) in every lesson. One package: `Microsoft.Extensions.DependencyInjection` 11.0.0 (lesson 01, C#). No art.
- Authoring policy: no smoke tests. Static check only (`python scripts/verify_labs.py --static patterns/301`): 10 of 10 lessons report `STATIC` (text contains every code line and every expected output; `verify.json` parses). Nothing has been executed.
- Levels 101 and 201 are owned by other files; not edited here.

## Lessons
| Lesson | Phase | Status | Notes |
|---|---|---|---|
| [01. DI containers and composition roots](301-super-hero-to-legendary/phase-1-application-patterns/01-di-containers-and-composition-roots.md) | 1 | written (not run) | Python hand-made container, C# real container; same 11 output lines |
| [02. Repository and Unit of Work](301-super-hero-to-legendary/phase-1-application-patterns/02-repository-and-unit-of-work.md) | 1 | written (not run) | in-memory store with failing write; ORM comparison table |
| [03. Specification and Query Object](301-super-hero-to-legendary/phase-1-application-patterns/03-specification-and-query-object.md) | 1 | written (not run) | prints SQL, nothing executed |
| [04. CQRS and the mediator](301-super-hero-to-legendary/phase-1-application-patterns/04-cqrs-and-the-mediator.md) | 1 | written (not run) | hand-written mediator, no library |
| [05. Domain events, outbox and saga](301-super-hero-to-legendary/phase-1-application-patterns/05-domain-events-outbox-and-saga.md) | 1 | written (not run) | longest program of phase 1 |
| [06. Code smells catalog](301-super-hero-to-legendary/phase-2-smells-and-refactoring/06-code-smells-catalog.md) | 2 | written (not run) | outputs differ by language (22 vs 44 lines); scanner reads its own sample file |
| [07. Refactoring moves with tests](301-super-hero-to-legendary/phase-2-smells-and-refactoring/07-refactoring-moves-with-tests.md) | 2 | written (not run) | 216-case golden master; 81 differences for the broken step derived by hand |
| [08. Anti-patterns before and after](301-super-hero-to-legendary/phase-2-smells-and-refactoring/08-anti-patterns-before-and-after.md) | 2 | written (not run) | five pairs, ten output lines |
| [09. Choosing patterns in one service](301-super-hero-to-legendary/phase-3-judgement/09-choosing-patterns-in-one-service.md) | 3 | written (not run) | "types in this design: 8" counted by reflection in both languages |
| [10. Architecture-level patterns and design review](301-super-hero-to-legendary/phase-3-judgement/10-architecture-level-patterns-and-design-review.md) | 3 | written (not run) | fitness function reads its own layer folders; design review with answer key |

## Open items
- Run `python scripts/verify_labs.py source/patterns/301-super-hero-to-legendary/` when Python and .NET 11 are available. Compare every Expected output; then remove the draft notices and set `verified:`.
- C# points to confirm on the first real build: `ServiceProviderOptions` validation throws `AggregateException` (lesson 01); `Statuses: ["todo", ...]` collection expression into `string[]?` (03); collection expression with a method group (`[notifier.Handle]`, 05 and 09); static local functions whose parameters share a name with a top-level local (02, 04, 05, 09); raw string literal in a tuple (06 exercise); `Enumerable.Reverse` and `array.Contains` under the newest C# language version (04, 10); the reflection type count in lesson 09 (8 types in namespace `TasksService`).
- Lesson 06 scanner counts (22 lines Python, 44 lines C#, nesting 3, 6 methods in `OrderManager`) were counted by hand against the files; run once to confirm.
- Mermaid diagrams (about 20) were checked by reading, not rendered.
- Lessons link Patterns 201 by lesson id in "Before you start" (for example [lesson 09, observer and mediator](201-hero-to-super-hero/phase-3-behavioral/09-observer-and-mediator.md)); the 201 numbering is final.
- A senior walk-through (`Learner: Senior`) has not been done; recommended first for lessons 05, 07 and 10.
- Rung 3 exercises have no single answer by design; lesson 10 rung 3 has an answer key.
