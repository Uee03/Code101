# Design Patterns 301 (Super Hero to Legendary): author brief

## Learner and outcome
Learners who finished Patterns 101 (SOLID, everyday principles) and Patterns 201 (the 22-pattern catalogue; read-only here, linked by lesson id in each lesson's "Before you start"). Ten lessons in three phases teach **judgement**: application-level patterns (container and composition root, repository and unit of work, specification and query object, CQRS and mediator, domain events with outbox and saga), a smells-and-refactoring phase (smell catalogue with measurements, refactoring with a golden-master safety net, anti-patterns with before and after) and a judgement phase (a decision framework with a realistic Tasks and Teams service, then architecture styles with a fitness function and a design review). Every example exists in **Python and C#** (the learner follows one and compares). Voice 301: trade-offs, failure modes, "when not to use", measurements to take (never invented numbers), ADR per lesson with a revisit trigger.
Time: 60 to 90 minutes per lesson for one language (add about 30 minutes for both).

## Version decision (2026-11-23)
- Python 3.10 or newer, standard library only (`ast`, `dataclasses`, `copy`, `abc`, `inspect`).
- .NET SDK 11, `net11.0`, `ImplicitUsings` and `Nullable` enabled, one `Lesson.csproj` shown in full in every lesson. C# 12+ features (primary constructors, collection expressions, raw string literals) used; top-level statements first, types after them in the same file.
- Only one NuGet package: `Microsoft.Extensions.DependencyInjection` **11.0.0** (lesson 01; checked on api.nuget.org: stable 11.0.0 exists). No lock files are shipped; `dotnet restore` creates `obj/project.assets.json`.
- Type naming: the domain type is `TaskItem` (Python and C#), never `Task`, because `System.Threading.Tasks.Task` is brought in by implicit usings.
- Money is whole cents (`int`), dates are ISO text, so output is identical in both languages. Outputs that differ by language are called out (lesson 06 line counts).

## Lesson map
| Phase | Lesson | Main build / exercise |
|---|---|---|
| 1 application-patterns | 01 DI containers and composition roots | 30-line container with lifetimes and start-up validation (Python), `Microsoft.Extensions.DependencyInjection` with `ValidateScopes`/`ValidateOnBuild` (C#) / hand-built composition root |
| 1 | 02 Repository and Unit of Work (and when an ORM already is one) | pending-change repository, rollback on a failed write / unit of work with rollback |
| 1 | 03 Specification and Query Object | composable specs with in-memory and SQL interpreters, safe query object / add `NOT` |
| 1 | 04 CQRS and the mediator in practice | hand-written mediator with behaviours, lagging read model / add a behaviour |
| 1 | 05 Domain events, outbox and saga | outbox, crashing relay, idempotent consumers, choreography, orchestrated saga / idempotent scoreboard |
| 2 smells-and-refactoring | 06 Code smells catalog | smelly module plus scanner (`ast` in Python, regex heuristic in C#) / add a branch-count check |
| 2 | 07 Refactoring moves with tests | 216-case golden master, four moves, one broken move caught / introduce a parameter object |
| 2 | 08 Anti-patterns before and after | god object, anemic model, golden hammer, service locator, singleton abuse / singleton to injected counter |
| 3 judgement | 09 Choosing patterns in one service | five-question framework; Tasks and Teams "complete task" with 8 types / add `reassign` without a new type |
| 3 | 10 Architecture-level patterns and design review | hexagonal mini app, dependency-rule fitness function, five-style trade-offs table, design review with answer key / add the application rule |

## Sources (Tier 1/2, paraphrased, never copied)
- Smells and refactoring catalogue: https://refactoring.guru/refactoring/smells and https://refactoring.guru/refactoring/catalog (cross-check https://sourcemaking.com/refactoring/smells)
- Patterns of Enterprise Application Architecture (Tier 2): https://martinfowler.com/eaaCatalog/ (repository, unit of work, query object), https://martinfowler.com/bliki/CQRS.html, https://martinfowler.com/bliki/AnemicDomainModel.html, https://martinfowler.com/bliki/MonolithFirst.html, https://martinfowler.com/bliki/Yagni.html, https://martinfowler.com/articles/injection.html, https://martinfowler.com/articles/microservices.html
- Microsoft Learn architecture guides: dependency injection guidelines https://learn.microsoft.com/dotnet/core/extensions/dependency-injection/guidelines ; CQRS https://learn.microsoft.com/azure/architecture/patterns/cqrs ; Saga https://learn.microsoft.com/azure/architecture/patterns/saga ; architecture styles https://learn.microsoft.com/azure/architecture/guide/architecture-styles/ ; persistence layer https://learn.microsoft.com/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/infrastructure-persistence-layer-design
- Outbox (Tier 2): https://microservices.io/patterns/data/transactional-outbox.html ; hexagonal architecture: https://alistair.cockburn.us/hexagonal-architecture/ ; OWASP query parameterization (lesson 03).
- Capstone link: `capstones/platform` (Tasks and Teams; tasks, teams, leads, audit trail, optimistic concurrency).

## Delivery and verification (policy of 2026-11-23: no smoke tests)
- Only author `tutorials/patterns/301-super-hero-to-legendary/` and `source/patterns/301-super-hero-to-legendary/`, plus this file, `_STATE-301.md` and `GLOSSARY-301.md`. No art (`assets: []`).
- The code was **not executed**. Every lesson carries the verbatim "Draft: written but not yet run" notice directly under the H1 and `verified: not yet run`. Expected output was derived by reading the code (hand counts checked twice for lessons 06, 07 and 09). Common-mistakes tables say "typical message" where the exact text was not observed.
- Allowed checks: `python scripts/verify_labs.py --static patterns/301` (executes nothing) and `python scripts/build_packs.py patterns-301`.
- Later: run `python scripts/verify_labs.py source/patterns/301-super-hero-to-legendary/` once Python and .NET are available, compare every Expected output with real output, then remove the draft notice and set `verified:`.
