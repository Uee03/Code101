# C# 301 state

Updated: 2026-11-23. Status: **written (not run)**. Ten lessons, four phases. C# 101 files and `_STATE.md` are unchanged; C# 201 now exists and each 301 lesson links the 201 lessons it needs ("Before you start" and front matter use lesson ids).

| Lesson | Phase | Status | Evidence |
|---|---|---|---|
| 01-clean-architecture-and-vertical-slices | phase-1-architecture | written (not run) | Source and lesson authored; JSON bodies derived from the code; static check clean. |
| 02-cqrs-without-ceremony | phase-1-architecture | written (not run) | Console output derived from the handlers; static check clean. |
| 03-domain-driven-design-essentials | phase-1-architecture | written (not run) | Console output derived from the aggregate rules; static check clean. |
| 04-performance-fundamentals | phase-2-performance | written (not run) | Only `--check` output is stated; no timings, allocations or ratios are published, tables are blank for the learner. |
| 05-caching | phase-2-performance | written (not run) | HybridCache lines derived from the documentation (single-flight, tags); the IMemoryCache stampede count is explicitly variable. |
| 06-resilience-with-polly | phase-3-resilience-and-messaging | written (not run) | Output derived from the Polly v8 documentation (circuit breaker opens at MinimumThroughput; concurrency limiter permit/queue). |
| 07-background-services-outbox-and-sagas | phase-3-resilience-and-messaging | written (not run) | Counts derived by tracing the relay ticks (2 failures, 3 deliveries, 2 handled). |
| 08-observability-with-opentelemetry | phase-3-resilience-and-messaging | written (not run) | JSON bodies derived; Jaeger, Prometheus and Collector output described, never claimed as seen. |
| 09-modular-monolith-to-microservices | phase-4-production | written (not run) | In-process and remote outputs derived; Keycloak flow not executed. |
| 10-native-aot-analyzers-and-production-readiness | phase-4-production | written (not run) | JSON derived; analyzer error described as typical; no size, startup or memory numbers published. |

## Scope and honesty
- Every lesson has the mandatory draft notice directly under the H1 and `verified: not yet run`. Static checking never upgrades the status.
- Nothing was executed: no compiler, `dotnet`, package manager, server, Docker, Redis, Keycloak, collector, benchmark or AOT publish. Only reading files, NuGet and Docker Hub version lookups, documentation lookups, the static check and the pack build were done.
- **No invented measurements.** Lessons 04, 08 and 10 give the method and blank tables. Error messages in "Common mistakes" are exact only where the text is a known compiler or MSBuild message; everything else is marked "typical".
- Exercises are overlays: the starter and solution contain only the files to add or change, to be placed in a copy of the finished lesson folder (lesson 09 uses a small standalone project; lesson 10 is a file-review exercise whose solution is `FINDINGS.md`).
- Lockfiles cannot be created without running tools; none are included. Lesson 10 explains `RestorePackagesWithLockFile` and `dotnet restore --locked-mode`.

## Pending runtime review (what is most likely to need a fix on the first real run)
1. **BenchmarkDotNet 0.15.8 on net11.0:** whether this version recognizes the net11.0 moniker (lesson 04 mentions `--inProcess` as a fallback).
2. **Lesson 05:** `HybridCache` factory/overload resolution with `tags:` and `cancellationToken:` named arguments; `RemoveByTagAsync` behavior with and without Redis; `AddStackExchangeRedisCache` picked up automatically as L2; exact "IMemoryCache parallel" count (variable by design).
3. **Lesson 06:** Polly v8 API details (`PredicateBuilder` conversions, `OnRetry` argument names, `CircuitBreakerStateProvider.CircuitState` values after a break, `AddConcurrencyLimiter` queue semantics giving 3 completed and 2 rejected).
4. **Lesson 07:** `BackgroundService` shutdown with `PeriodicTimer`, SQLite `RETURNING` through `ExecuteScalar`, locking between the relay and the main thread, `File.Delete` of the database with pooled connections.
5. **Lesson 08:** OpenTelemetry package APIs (`SetResourceBuilder` on logger options, `AddOtlpExporter` overloads), collector exporter name `otlp/jaeger` (newer collectors also call the component `otlp_grpc`), Jaeger v2 default OTLP listener, Prometheus metric names.
6. **Lesson 09:** Keycloak realm import (the `${ORDERS_CLIENT_SECRET}` placeholder substitution, service-account user import, client role claims in `resource_access`), issuer and hostname settings with `KC_HOSTNAME`, JwtBearer claim shape with `MapInboundClaims = false`.
7. **Lesson 10:** the `mcr.microsoft.com/dotnet/runtime-deps:11.0.0-alpine3.24` tag (assumed to follow the aspnet tag pattern), the Alpine package list for the AOT link, `latest-recommended` analyzer severities against the sample code under `TreatWarningsAsErrors`, `wget` health check under `read_only`.
8. **Ports used:** 5301, 5308, 5309, 5310, 5319 (APIs), 8180 (Keycloak, shared with the capstone), 8310 (container), 6379 (Redis), 4317, 4318, 9090, 16686 (telemetry). None of the other 301 labs run at the same time as the capstone stack.

## Static and packaging evidence
Run on 2026-11-23, repository root:
```text
python scripts\verify_labs.py --static csharp/301-super-hero-to-legendary
python scripts\build_packs.py csharp-301
```
Results are recorded below after the final run.

- Static check: `0 passed, 10 static-checked (not run), 0 failed, 0 unverified`.
- Pack build: `csharp-301-phase-1-architecture.zip` (39 files), `csharp-301-phase-2-performance.zip` (16), `csharp-301-phase-3-resilience-and-messaging.zip` (28), `csharp-301-phase-4-production.zip` (41) and `csharp-301-all.zip` (4 phases) in `dist\packs\`.
- Hygiene: all 10 lessons carry the draft notice and `verified: not yet run`; no UTF-8 BOM in any new file; no `bin` or `obj` folders under `source\csharp\301-super-hero-to-legendary`.
