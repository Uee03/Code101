# C# 301 (Super Hero to Legendary): author brief

## Learner and outcome
Developers who finished C# 201 (OOP, generics, LINQ, async/await, DI, ASP.NET Core with FastEndpoints, EF Core, JWT, Docker) and the backend-dotnet capstone. Ten lessons in four phases teach how to design, measure, operate and ship a .NET 11 service. Voice 301: trade-offs, failure modes, "when not to use this", measurements to take (never invented numbers), production checklists, ADR-style decisions, security and operations. Each lesson is 60-120 minutes including the exercise, has an ADR, a "When not to use this" section, a failure-mode list, a "Measurements to take" section and a production checklist.

## Version decision (2026-11-23)
SDK 11.0.100, `net11.0`, `global.json` with `rollForward: latestFeature`. FastEndpoints 9.0.0 (as the capstone). Packages were checked against NuGet on 2026-11-23: BenchmarkDotNet 0.15.8, Microsoft.Extensions.Caching.Hybrid 11.0.1, Microsoft.Extensions.Caching.StackExchangeRedis 11.0.0, Polly.Core and Polly.RateLimiting 8.9.1, Microsoft.Data.Sqlite 11.0.0, OpenTelemetry packages 1.21.0, Microsoft.AspNetCore.Authentication.JwtBearer 11.0.0. Image tags checked on Docker Hub the same day: `redis:8.8-alpine`, `otel/opentelemetry-collector-contrib:0.165.0`, `jaegertracing/jaeger:2.23.0`, `prom/prometheus:v3.16.0`; Keycloak `26.8.2` and the Alpine SDK/runtime tags are copied from the verified backend-dotnet capstone (the `runtime-deps` tag is assumed to follow the same pattern).

## Assumed C# 201 knowledge (C# 201 now exists; each lesson links the lessons it needs)
FastEndpoints REPR endpoints ([C# 201 lesson 05](201-hero-to-super-hero/phase-2-web-apis/05-first-aspnet-core-api.md)), dependency injection lifetimes ([lesson 07](201-hero-to-super-hero/phase-2-web-apis/07-dependency-injection-and-options.md)), async/await and cancellation tokens ([lesson 04](201-hero-to-super-hero/phase-1-core-skills/04-async-await-and-task.md)), generics ([lesson 02](201-hero-to-super-hero/phase-1-core-skills/02-generics-and-collections.md)), LINQ ([lesson 03](201-hero-to-super-hero/phase-1-core-skills/03-linq.md)), EF Core basics ([lesson 08](201-hero-to-super-hero/phase-3-data/08-ef-core-and-postgres.md)), JWT bearer authentication ([lesson 10](201-hero-to-super-hero/phase-4-security-and-quality/10-jwt-authentication-and-authorization.md)), records ([C# 101 lesson 11](101-zero-to-hero/phase-3-real-programs/11-null-safety-and-records.md)), Docker and Compose basics ([Docker 101 lesson 06](../docker/101-zero-to-hero/phase-2-compose/06-networks-and-compose.md)). Each 301 lesson lists the ones it needs by id and link under "Before you start" and in its front matter `prerequisites`.

## Lesson map
| Phase | Lesson | Main build / exercise |
|---|---|---|
| 1 architecture | 01 Clean architecture and vertical slices | Domain project with no references + FastEndpoints slices, ADR / add a `ListOrders` slice |
| 1 architecture | 02 CQRS without ceremony | Command and query handler interfaces, logging decorator, no mediator library / `ListOutOfStock` query |
| 1 architecture | 03 Domain-driven design essentials | `Money` value object, `Order` aggregate, domain events / `Sku` value object |
| 2 performance | 04 Performance fundamentals | BenchmarkDotNet, `Span<T>`, `ValueTask`, correctness check and allocation probe; no published timings / string-building benchmark |
| 2 performance | 05 Caching | `IMemoryCache` vs `HybridCache`, stampede, staleness, tags, optional Redis compose / tenant-safe keys |
| 3 resilience and messaging | 06 Resilience with Polly | Retry, timeout, circuit breaker, bulkhead, ordering / fallback |
| 3 resilience and messaging | 07 Background services, the outbox pattern and sagas | SQLite outbox, `BackgroundService` relay, inbox, saga / late-failing saga |
| 3 resilience and messaging | 08 Observability with OpenTelemetry | Traces, metrics, logs; Collector + Jaeger + Prometheus compose / latency histogram |
| 4 production | 09 Modular monolith to microservices | Module behind a contract, in-process vs HTTP, Keycloak client credentials with audience and role / `aud` claim parser, PR review |
| 4 production | 10 Native AOT, analyzers/EditorConfig and a production readiness review | AOT minimal API, `Directory.Build.props`, `.editorconfig`, hardened Dockerfile and compose, checklist / review a flawed service |

## Sources (Tier 1)
- ASP.NET Core best practices: https://learn.microsoft.com/aspnet/core/fundamentals/best-practices
- Common web application architectures: https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures
- CQRS and Saga patterns (Azure Architecture Center): https://learn.microsoft.com/azure/architecture/patterns/cqrs and https://learn.microsoft.com/azure/architecture/patterns/saga
- DDD with microservices: https://learn.microsoft.com/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/
- BenchmarkDotNet: https://benchmarkdotnet.org/articles/overview.html
- HybridCache and caching overview: https://learn.microsoft.com/aspnet/core/performance/caching/hybrid
- Polly: https://www.pollydocs.org/ and https://learn.microsoft.com/dotnet/core/resilience/http-resilience
- Hosted services: https://learn.microsoft.com/aspnet/core/fundamentals/host/hosted-services
- OpenTelemetry .NET and Collector: https://opentelemetry.io/docs/languages/dotnet/ and https://opentelemetry.io/docs/collector/
- Native AOT: https://learn.microsoft.com/aspnet/core/fundamentals/native-aot and https://learn.microsoft.com/dotnet/core/deploying/native-aot/
- Code analysis: https://learn.microsoft.com/dotnet/fundamentals/code-analysis/overview
- Microservices architecture: https://learn.microsoft.com/azure/architecture/microservices/
- Keycloak documentation: https://www.keycloak.org/documentation

## Delivery and verification (policy of 2026-11-23: no smoke tests)
Lessons and source were written without running any code, compiler, package manager, server or Docker. Every lesson carries the verbatim draft notice under its H1 and `verified: not yet run`; `_STATE-301.md` status is `written (not run)`. The only checks run: `python scripts\verify_labs.py --static csharp/301-super-hero-to-legendary` and `python scripts\build_packs.py csharp-301`. Expected output was derived by reading the code; lessons say "not yet run". Benchmark results are never published, only the method and tables to fill in.
Folder layout: tutorials/csharp/301-super-hero-to-legendary/phase-N-slug/NN-slug.md and source/csharp/301-super-hero-to-legendary/phase-N-slug/NN-slug/{code,exercise/starter,exercise/solution,verify.json} with a PACK-README.md per phase. Art: none (`assets: []`). Lockfiles cannot be created without running tools; none are included.
