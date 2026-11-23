# Design Patterns 201 (Hero to Super Hero): author brief

## Learner and outcome
Learners who finished Design Patterns + SOLID 101 (SOLID, DRY/KISS/YAGNI, composition over inheritance, class diagrams) plus Python 101 and C# 101. Twelve lessons in four downloadable phases teach **all 22 patterns of the refactoring.guru catalogue** (5 creational, 7 structural, 10 behavioral) and then how to **choose, combine and refactor toward** them. Every lesson follows the same arc: the problem shown as bad code, the structure as a Mermaid class diagram, the solution in **Python and C#** (plus a short TypeScript sketch in the text only), a pattern card per pattern (use when, do not use when, real-world uses, related patterns, pitfalls), a predict-before-run step, a three-rung exercise (guided, change, stretch), check-yourself questions, a mixed review and common mistakes.
Time: 45 to 60 minutes per lesson for one language (add about half as much again for both); lessons 11 and 12 about 80 minutes in two sittings.

## Version decision (2026-11-23)
- Python 3.10 or newer (`list[str]`, `tuple[str, ...]`, `typing.Optional`, `abc`, `dataclasses`). No packages.
- .NET SDK 11 with `net11.0`, `ImplicitUsings` and `Nullable` enabled, the same minimal `Lesson.csproj` shown in full in every lesson (identical to level 101). Top-level statements in `Program.cs`; one `.cs` file per pattern with a file-scoped namespace (`FactoryMethodDemo`, `BuilderDemo`, ...) and a `Demo.Run()` entry. No packages, no `global.json`. The DI-container snippet in lesson 03 needs `Microsoft.Extensions.DependencyInjection` and is **reading only**.
- Python layout: one module per pattern (`factory_method.py`, `builder.py`, ...) with `demo()`, and `main.py` that imports and runs them. Output is identical in Python and C# so one expected output serves both.
- Money and quantities are whole numbers (cents, grams) so there are no rounding differences between the languages.
- TypeScript appears only as a short snippet in the lesson text (no project, no run).

## Lesson map
| Phase | Lesson | Patterns | Main build / exercise |
|---|---|---|---|
| 1 creational | 01 Factory Method and Abstract Factory | Factory Method, Abstract Factory | delivery planner, themed widgets / printer formatters |
| 1 creational | 02 Builder and Prototype | Builder, Prototype | computer builder with validation, unit clone and shallow-copy bug / email builder |
| 1 creational | 03 Singleton and why dependency injection is usually better | Singleton | singleton settings vs constructor injection; phase 1 mixed review / replace a singleton logger |
| 2 structural | 04 Adapter and Facade | Adapter, Facade | Fahrenheit sensor adapter, home-theater facade / SMS notifier adapter |
| 2 structural | 05 Decorator and Proxy | Decorator, Proxy | stacked sinks (order matters), caching and protection proxy / price decorators |
| 2 structural | 06 Composite and Flyweight | Composite, Flyweight | folder tree sizes, shared tree types / product bundles |
| 2 structural | 07 Bridge | Bridge | messages by channel; structural decision table; phase 2 mixed review / push channel and reminder |
| 3 behavioral | 08 Strategy and State | Strategy, State | shipping strategies, document workflow / traffic light |
| 3 behavioral | 09 Observer and Mediator | Observer, Mediator | price feed, signup form / freeze warning listener |
| 3 behavioral | 10 Command and Memento | Command, Memento | undoable editor, game snapshots / multiply command |
| 3 behavioral | 11 Iterator, Template Method, Visitor and Chain of Responsibility | Iterator, Template Method, Visitor, Chain of Responsibility | playlist, two reports, shape visitors, approval chain; behavioral decision table / password check chain |
| 4 choosing-patterns | 12 Choosing, combining and refactoring toward patterns | all 22 | decision table, flowchart, anti-patterns; refactor a messy `checkout` with a same-as-before check / ticket pricing refactor |

All 22 catalogue patterns are covered: Factory Method, Abstract Factory, Builder, Prototype, Singleton (01 to 03); Adapter, Facade, Decorator, Proxy, Composite, Flyweight, Bridge (04 to 07); Strategy, State, Observer, Mediator, Command, Memento, Iterator, Template Method, Visitor, Chain of Responsibility (08 to 11).
Lesson 11 holds four patterns (below the limit of five ideas); it is marked "two sittings" with a break after Step 5.

## Sources (Tier 2, paraphrased, never copied)
- Catalogue of design patterns (every pattern page was used for intent, applicability, pros and cons): https://refactoring.guru/design-patterns/catalog
- Cross-check: https://sourcemaking.com/design_patterns
- Refactoring techniques and code smells: https://refactoring.guru/refactoring and https://refactoring.guru/refactoring/smells
- Mermaid class and state diagrams (Tier 1): https://mermaid.js.org/syntax/classDiagram.html and https://mermaid.js.org/syntax/stateDiagram.html
- Python `abc`, `dataclasses`, `copy` (Tier 1): https://docs.python.org/3/library/abc.html, https://docs.python.org/3/library/dataclasses.html, https://docs.python.org/3/library/copy.html
- C# records, events, iterators and dependency injection (Tier 1): https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/record, https://learn.microsoft.com/dotnet/csharp/events-overview, https://learn.microsoft.com/dotnet/csharp/iterators, https://learn.microsoft.com/dotnet/core/extensions/dependency-injection
- Style of the notes (workflow, DO NOT list, "baseline first"): the Unity design patterns skill in the workspace templates.

## Delivery and verification (policy of 2026-11-23: no smoke tests)
- Authored only in `tutorials/patterns/201-hero-to-super-hero/` and `source/patterns/201-hero-to-super-hero/` plus this brief, `_STATE-201.md` and `GLOSSARY-201.md`. The level 101 files were not edited. No art (`assets: []`).
- The code was **not executed**. Every lesson carries the verbatim "Draft: written but not yet run" notice directly under the H1 and `verified: not yet run`. Expected output was derived by reading the code; Common-mistakes tables say "typical messages, not yet reproduced".
- Allowed checks: `python scripts/verify_labs.py --static patterns/201-hero-to-super-hero` (executes nothing) and `python scripts/build_packs.py patterns-201`.
- Later: run `python scripts/verify_labs.py source/patterns/201-hero-to-super-hero` once Python and .NET are available, fix any difference between text and real output, remove the draft notice and set `verified:` to the real date.
