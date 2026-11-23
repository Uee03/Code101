# Design Patterns 301 glossary

Definitions for Design Patterns 301 (Super Hero to Legendary). Lesson links point to the first introduction. Terms from levels 101 and 201 are in `GLOSSARY.md`.

| Term | Meaning | Lesson |
|---|---|---|
| Composition root | The one place near program start where objects are created and connected; the only code that may know the container. | [01](301-super-hero-to-legendary/phase-1-application-patterns/01-di-containers-and-composition-roots.md) |
| DI container | A tool that builds objects and their dependencies from registrations. | [01](301-super-hero-to-legendary/phase-1-application-patterns/01-di-containers-and-composition-roots.md) |
| Lifetime (singleton, scoped, transient) | How long an instance lives: whole program, one unit of work (often one request), or a new one every time. | [01](301-super-hero-to-legendary/phase-1-application-patterns/01-di-containers-and-composition-roots.md) |
| Captive dependency | A long-lived object holding a shorter-lived one (a singleton holding a scoped service), keeping stale state alive. | [01](301-super-hero-to-legendary/phase-1-application-patterns/01-di-containers-and-composition-roots.md) |
| Repository | A collection-like interface in domain words that hides how data is stored. | [02](301-super-hero-to-legendary/phase-1-application-patterns/02-repository-and-unit-of-work.md) |
| Unit of work | Tracks the changes of one business action and commits or rolls them back together. | [02](301-super-hero-to-legendary/phase-1-application-patterns/02-repository-and-unit-of-work.md) |
| Aggregate | A cluster of objects changed together and saved through one repository. | [02](301-super-hero-to-legendary/phase-1-application-patterns/02-repository-and-unit-of-work.md) |
| Read-your-writes | Code inside one action sees its own uncommitted changes. | [02](301-super-hero-to-legendary/phase-1-application-patterns/02-repository-and-unit-of-work.md) |
| Specification | An object that says whether an item satisfies a rule and can be combined with and, or, not. | [03](301-super-hero-to-legendary/phase-1-application-patterns/03-specification-and-query-object.md) |
| Query object | An object that carries a request's filters, sort and page size and turns them into a safe query. | [03](301-super-hero-to-legendary/phase-1-application-patterns/03-specification-and-query-object.md) |
| Placeholder (bound parameter) | A `?` in SQL text whose value travels separately, so it can never become SQL. | [03](301-super-hero-to-legendary/phase-1-application-patterns/03-specification-and-query-object.md) |
| Allow-list | A fixed list of accepted values, used for identifiers such as sort columns that cannot be parameters. | [03](301-super-hero-to-legendary/phase-1-application-patterns/03-specification-and-query-object.md) |
| CQRS | Command Query Responsibility Segregation: a different model for changing data than for reading it. | [04](301-super-hero-to-legendary/phase-1-application-patterns/04-cqrs-and-the-mediator.md) |
| Command / query | A request to change state (may fail) / a request to read state (changes nothing). | [04](301-super-hero-to-legendary/phase-1-application-patterns/04-cqrs-and-the-mediator.md) |
| Mediator | One object that routes each request to its single handler. | [04](301-super-hero-to-legendary/phase-1-application-patterns/04-cqrs-and-the-mediator.md) |
| Pipeline behaviour | A wrapper around handlers for a cross-cutting concern (logging, validation); the first added is the outermost. | [04](301-super-hero-to-legendary/phase-1-application-patterns/04-cqrs-and-the-mediator.md) |
| Read model / projection | A data shape built from events for fast reads / the code that builds it. | [04](301-super-hero-to-legendary/phase-1-application-patterns/04-cqrs-and-the-mediator.md) |
| Eventual consistency | A read model or another service is briefly behind and then catches up. | [04](301-super-hero-to-legendary/phase-1-application-patterns/04-cqrs-and-the-mediator.md) |
| Domain event | A fact in the past tense, in business words (`TaskCompleted`). | [05](301-super-hero-to-legendary/phase-1-application-patterns/05-domain-events-outbox-and-saga.md) |
| Transactional outbox | A table written in the same transaction as the state change; its rows are published later. | [05](301-super-hero-to-legendary/phase-1-application-patterns/05-domain-events-outbox-and-saga.md) |
| Relay | The process that reads unpublished outbox rows, sends them and marks them. | [05](301-super-hero-to-legendary/phase-1-application-patterns/05-domain-events-outbox-and-saga.md) |
| At-least-once delivery | Every event is delivered one or more times; duplicates are possible, losses are not. | [05](301-super-hero-to-legendary/phase-1-application-patterns/05-domain-events-outbox-and-saga.md) |
| Idempotent | Doing it twice has the same effect as doing it once. | [05](301-super-hero-to-legendary/phase-1-application-patterns/05-domain-events-outbox-and-saga.md) |
| Saga | A business action across several local transactions, with compensations instead of a distributed transaction. | [05](301-super-hero-to-legendary/phase-1-application-patterns/05-domain-events-outbox-and-saga.md) |
| Compensation | A step that undoes the business effect of an earlier step (a refund, a cancel), not a database rollback. | [05](301-super-hero-to-legendary/phase-1-application-patterns/05-domain-events-outbox-and-saga.md) |
| Orchestration / choreography | A coordinator calls the steps / services react to each other's events. | [05](301-super-hero-to-legendary/phase-1-application-patterns/05-domain-events-outbox-and-saga.md) |
| Pivot step | The irreversible step of a saga; place it last. | [05](301-super-hero-to-legendary/phase-1-application-patterns/05-domain-events-outbox-and-saga.md) |
| Bloaters, object-orientation abusers, change preventers, dispensables, couplers | The five groups of the smell catalogue. | [06](301-super-hero-to-legendary/phase-2-smells-and-refactoring/06-code-smells-catalog.md) |
| Long method, large class, long parameter list, data clumps, primitive obsession | Bloater smells. | [06](301-super-hero-to-legendary/phase-2-smells-and-refactoring/06-code-smells-catalog.md) |
| Divergent change / shotgun surgery | One class changes for many reasons / one reason changes many classes. | [06](301-super-hero-to-legendary/phase-2-smells-and-refactoring/06-code-smells-catalog.md) |
| Feature envy, message chain, middle man, inappropriate intimacy | Coupler smells. | [06](301-super-hero-to-legendary/phase-2-smells-and-refactoring/06-code-smells-catalog.md) |
| Threshold (team agreement) | A measured limit chosen by a team from its own code, never a universal law. | [06](301-super-hero-to-legendary/phase-2-smells-and-refactoring/06-code-smells-catalog.md) |
| Characterization test / golden master | A test that records what legacy code does today and compares new code with it. | [07](301-super-hero-to-legendary/phase-2-smells-and-refactoring/07-refactoring-moves-with-tests.md) |
| Extract function, introduce parameter object, replace conditional with polymorphism, move method | The four refactoring moves of the lesson. | [07](301-super-hero-to-legendary/phase-2-smells-and-refactoring/07-refactoring-moves-with-tests.md) |
| Anti-pattern | A common solution that looks reasonable but usually does more harm than good. | [08](301-super-hero-to-legendary/phase-2-smells-and-refactoring/08-anti-patterns-before-and-after.md) |
| God object / anemic domain model / golden hammer / service locator / singleton abuse | The five anti-patterns of the lesson. | [08](301-super-hero-to-legendary/phase-2-smells-and-refactoring/08-anti-patterns-before-and-after.md) |
| ADR (architecture decision record) | A short record of a decision: context, decision, consequences, and a revisit trigger. | [01](301-super-hero-to-legendary/phase-1-application-patterns/01-di-containers-and-composition-roots.md) |
| Revisit trigger | A measurable event that makes a team reopen a decision. | [09](301-super-hero-to-legendary/phase-3-judgement/09-choosing-patterns-in-one-service.md) |
| Cost of abstraction | What a pattern adds: types, hops, concepts, start-up checks. | [09](301-super-hero-to-legendary/phase-3-judgement/09-choosing-patterns-in-one-service.md) |
| Ports and adapters (hexagonal architecture) | The core defines ports; adapters at the edge implement them for databases, web or console. | [10](301-super-hero-to-legendary/phase-3-judgement/10-architecture-level-patterns-and-design-review.md) |
| Dependency rule | Source dependencies point inward, towards the domain. | [10](301-super-hero-to-legendary/phase-3-judgement/10-architecture-level-patterns-and-design-review.md) |
| Fitness function | An automatic check of an architectural property. | [10](301-super-hero-to-legendary/phase-3-judgement/10-architecture-level-patterns-and-design-review.md) |
| Modular monolith | One deployable with strict module boundaries and per-module data. | [10](301-super-hero-to-legendary/phase-3-judgement/10-architecture-level-patterns-and-design-review.md) |
| Microservices | Independently deployable services around business capabilities, each owning its data. | [10](301-super-hero-to-legendary/phase-3-judgement/10-architecture-level-patterns-and-design-review.md) |
| Event-driven architecture | Components communicate by publishing and reacting to events. | [10](301-super-hero-to-legendary/phase-3-judgement/10-architecture-level-patterns-and-design-review.md) |
| Distributed monolith | Services that must be deployed together or share a database: the cost of microservices without the benefits. | [10](301-super-hero-to-legendary/phase-3-judgement/10-architecture-level-patterns-and-design-review.md) |
| Design review | A structured critique of a design document using a checklist, with severity-rated findings. | [10](301-super-hero-to-legendary/phase-3-judgement/10-architecture-level-patterns-and-design-review.md) |
