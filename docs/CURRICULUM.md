# Curriculum map

Topic outline per track and level. Module names are placeholders for lesson lists written in each
track's `_BRIEF.md` during Wave 0/1. "Best-practice" sources are tier-1/2 links in [LINKS.md](LINKS.md).
Counts per track are in [PLAN.md](PLAN.md) section 4.

Every level 1 starts with "what is a computer, a program, a terminal" for non-technical learners and
uses analogies from other fields (cooking, accounting, biology, music, construction).

## Languages

### Python
- **101:** setup + venv, variables/types, control flow, functions, collections, files, errors, modules, classes basics, testing with pytest, a console app (todo / expense tracker).
- **201:** OOP + dataclasses, typing + mypy, iterators/generators, decorators, context managers, async/await, packaging (pyproject, uv), logging, **FastAPI + Uvicorn** (routing, Pydantic DTOs, response models, dependency injection, errors), SQLAlchemy + Alembic, stored procedures from Python, auth basics, Docker.
- **301:** clean/hexagonal architecture, SOLID in Python, concurrency (GIL, multiprocessing, free-threading), performance + profiling, background workers, caching, observability, security hardening, API versioning, plugin design, packaging/publishing, microservice and event-driven patterns.

### C#
- **101:** .NET SDK, types, control flow, methods, collections/LINQ intro, classes, null safety, exceptions, files, console app, unit tests (xUnit).
- **201:** OOP deep dive, generics, LINQ, async/await, DI, **ASP.NET Core** minimal APIs vs controllers vs **FastEndpoints (REPR)**, DTOs, response objects (Result pattern, ProblemDetails), FluentValidation, **EF Core** (migrations, relationships, querying), **stored procedures** (Dapper/EF raw), JWT auth, Swagger/Scalar, Docker.
- **301:** clean architecture + CQRS (MediatR alternatives), domain-driven design, performance (Span, benchmarks), caching, background services, outbox/sagas, observability (OpenTelemetry), resilience (Polly), Keycloak integration, modular monolith to microservices, AOT, analyzers/EditorConfig.

### C (desktop focus)
- **101:** toolchain, types, pointers, arrays/strings, functions, structs, memory (malloc/free), files, headers/Makefile/CMake, first console tools.
- **201:** data structures, error handling patterns, modules, undefined behavior, Valgrind/ASan, **desktop GUI** (SDL or GTK; Win32 on Windows), event loops, file formats, unit testing, static analysis.
- **301:** memory models, custom allocators, concurrency (threads, atomics), portability, performance, secure coding (CERT C), plugin ABIs, C interop (P/Invoke, Python ctypes), embedded-style constraints.

### C++ (desktop focus)
- **101:** toolchain + CMake, types, references/pointers, functions, `std::string`/`vector`/`map`, classes, RAII, files, console apps.
- **201:** modern C++ (17/20/23), smart pointers, templates, STL algorithms/ranges, move semantics, exceptions, **Qt or Dear ImGui desktop apps**, SQLite, unit tests (Catch2/GoogleTest), vcpkg/Conan, sanitizers.
- **301:** template metaprogramming + concepts, concurrency + memory model, coroutines, performance, ABI/interop, C++ Core Guidelines enforcement (clang-tidy), plugin architectures, packaging/installers, large-codebase design.

### Go
- **101:** install, packages, types, control flow, functions, slices/maps, structs/methods/interfaces, errors, testing, CLI app.
- **201:** goroutines/channels/context, `net/http`, routing (stdlib/chi), JSON DTOs, validation, Postgres with pgx/sqlc, migrations, auth (JWT/OIDC), config, logging (slog), Docker, **Flutter-friendly API design**.
- **301:** concurrency patterns, generics, profiling (pprof), clean architecture in Go, gRPC, observability, resilience, microservices, testing at scale, security, release engineering.

### Rust
- **101:** rustup/cargo, ownership + borrowing, types, enums/match, structs/traits, collections, error handling (`Result`), modules, tests, CLI app.
- **201:** lifetimes, generics + traits, iterators/closures, async (Tokio), **Axum** APIs, serde DTOs, SQLx + Postgres, auth, tracing, Docker, **Flutter-friendly API design**.
- **301:** unsafe + FFI, advanced traits/type-state, performance, concurrency (Send/Sync), macros, hexagonal architecture, gRPC, microservices, WASM, security (supply chain, `cargo audit`/`deny`).

### Web Foundations (HTML, CSS, TypeScript)
- **101:** HTML semantics + forms + accessibility, CSS box model/selectors/flex/grid/responsive, JavaScript essentials, TypeScript basics (types, interfaces, generics intro), DOM, fetch, a static site project.
- **201:** advanced CSS (custom properties, container queries, animations, architecture/BEM), TS advanced types, modules/bundlers (Vite), testing (Vitest), a11y audits, web performance, state patterns.
- **301:** TS type-level programming, design systems/tokens, monorepos, performance budgets, security (CSP, XSS), browser internals, build/CI, micro-frontends, API client generation from OpenAPI.

## Frameworks

### Angular and React (parallel lessons, same app)
- **101:** tooling, components/JSX or templates, props/inputs, events, state, lists/forms, routing, calling an API, styling.
- **201:** Angular: standalone components, **Signals**, RxJS, DI, forms, HTTP interceptors, guards, lazy routes, PrimeNG, testing. React: hooks, context, data fetching (TanStack Query), forms, router, state (Zustand/Redux Toolkit), testing. Both: auth with Keycloak (PKCE), generated API client, full-stack capstones C1/C2/C4/C5/C9.
- **301:** architecture at scale (feature slices, Nx), performance (change detection/zoneless, memoization/Server Components), SSR/hydration, accessibility, micro-frontends, design systems, observability, upgrade strategy, security.

### Flutter
- **101:** Dart, widgets, layout, state basics, navigation, forms, HTTP, local storage.
- **201:** architecture (MVVM, repositories), state (Riverpod/Bloc), generated API client, OIDC PKCE login, secure storage, offline-first + sync, testing, **designing the backend for Flutter** (links to Python/.NET/Go/Rust capstones).
- **301:** performance (Impeller, rebuild control), platform channels/FFI, modular packages, CI/CD + stores, accessibility/i18n, observability, security.

### Kotlin + Jetpack Compose
- **101:** Kotlin syntax, null safety, classes, collections/lambdas, Android Studio, Compose basics (layouts, state, lists, navigation).
- **201:** MVVM + clean architecture, coroutines/Flow, Hilt, Room, Retrofit/Ktor client, WorkManager, auth (OIDC), testing, Supabase client.
- **301:** Compose internals + recomposition performance, modularization, KMP intro, baseline profiles, security (Android best practices), CI/CD + Play release, accessibility.

### Unity
- **101:** editor, GameObjects/components, C# scripting, physics, input, UI, a small 2D and 3D game.
- **201:** ScriptableObjects, design patterns (existing Unity pattern skills), addressables, UI Toolkit, input system, Shader Graph + intro to HLSL shaders, testing.
- **301:** clean architecture, DOTS/ECS overview, netcode, optimization/profiling, VFX Graph, editor tooling, build pipelines.

## Data, platform, architecture

### Databases (PostgreSQL first)
- **101:** relational model, SQL (SELECT/JOIN/GROUP), DDL, keys, normalization, CRUD, transactions intro.
- **201:** indexing + EXPLAIN, constraints, views, functions, **stored procedures**, triggers, migrations, schema design, window functions/CTEs, JSONB, backups.
- **301:** query tuning, partitioning, replication + high availability, locking/isolation, connection pooling, row-level security, pgvector, multi-tenant designs, SQL Server/SQLite differences.

### Supabase
- **101:** project setup, tables, auth, client libraries, storage. **201:** RLS design + performance, edge functions, realtime, migrations/CLI, environments. **301:** production hardening, scaling, backups, multi-tenant, observability, self-hosting.

### Docker
- **101:** images/containers, Dockerfile, volumes, networks, Compose. **201:** multi-stage builds, healthchecks, secrets, dev containers, Compose profiles, CI builds. **301:** image security/scanning, orchestration concepts (Swarm/Kubernetes intro), registries, observability, hardening.

### Ollama
- **101:** install, pull/run models, prompting, REST API. **201:** Modelfile, embeddings, structured output, app integration (Python, C#, TS), GPU/AMD notes (existing skill). **301:** RAG with pgvector, evaluation, tool use, serving/scaling, privacy/guardrails.

### System Architecture (diagrams)
- **101:** what architecture is, client/server, layers, UML basics, Mermaid, C4 level 1 to 2. **201:** draw.io, sequence/ER/deployment diagrams, REST vs events, caching, queues, ADRs. **301:** scaling from zero to millions, CAP/consistency, microservices vs monolith trade-offs, resilience, observability, security architecture, documentation as code.

## Cross-cutting

### Design Patterns + SOLID
- **101:** SOLID with tiny examples, DRY/KISS/YAGNI, composition vs inheritance, UML class basics.
- **201:** all **creational** (Factory Method, Abstract Factory, Builder, Prototype, Singleton), **structural** (Adapter, Bridge, Composite, Decorator, Facade, Flyweight, Proxy), **behavioral** (Chain of Responsibility, Command, Iterator, Mediator, Memento, Observer, State, Strategy, Template Method, Visitor). Each pattern: problem, structure diagram, C# + Python + TypeScript examples.
- **301:** patterns in the wild (DI containers, repositories, unit of work, CQRS, specification), anti-patterns/code smells + refactoring, pattern selection trade-offs, enterprise patterns, pattern combinations.

## Taught inside capstones (no separate tracks)

Security, identity and API craft are chapters of the full-stack capstones (phases defined in the
`designing-capstones` skill). A topic finder (`docs/TOPIC-FINDER.md`, Wave 2) maps each topic to its chapter.

| Topic group | Taught in capstone phase | Content |
|-------------|--------------------------|---------|
| API craft | 1 Contract and skeleton | HTTP, REST, status codes, DTOs vs entities, response objects/`Result`, RFC 9457 problem details, validation, pagination/filtering, versioning, OpenAPI-first, idempotency, ETag/caching, rate limiting (hardening), contract tests (301) |
| Data security | 2 Data | parameterised queries, stored procedures, least-privilege DB user, transactions, RLS (Supabase capstone C9) |
| Identity | 3 Identity | authentication vs authorization, hashing basics, sessions vs tokens, OAuth2/OIDC, code + PKCE, JWT validation, **Keycloak** realms/clients/roles, protecting APIs and SPAs/mobile, **Authentik** appendix, token exchange and service-to-service auth (301) |
| Client security | 4 Client | token storage, CORS, XSS/CSP basics, generated API client |
| Hardening | 6 Hardening | OWASP API Top 10, threat modeling, secrets management, Keycloak production configuration, security headers, audit logging, backups and restore |

## Coverage matrix (your named topics -> where they land)

| Topic | Lands in |
|-------|----------|
| Console applications | 101 of Python, C#, C, C++, Go, Rust |
| APIs, DTOs, response objects | capstone phase 1 (all capstones), Python/C# 201, Go/Rust 201 |
| FastAPI + Uvicorn | Python 201, capstones C1 to C3 |
| ASP.NET + FastEndpoints | C# 201, capstones C4 to C6 |
| Entity Framework, stored procs | C# 201, Databases 201, Python 201 (SQLAlchemy), capstone phase 2 |
| Frontend frameworks | Angular, React, Flutter, Compose, Web Foundations |
| Authentication, Keycloak, Authentik | capstone phase 3 (all capstones), phase 6 for production |
| Design patterns, SOLID | Design Patterns track, referenced from every 201/301 |
| Microservices, monoliths | Architecture 301, capstones C11, C12 |
| Full stack (frontend + backend + DB + Docker) | Capstones C1 to C14 |
| C/C++ desktop | C and C++ 201/301, C14 |
| Shaders | Unity 201 (Shader Graph, HLSL intro) |
