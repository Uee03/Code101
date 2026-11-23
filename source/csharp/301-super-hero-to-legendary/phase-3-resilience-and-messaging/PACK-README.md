# C# 301, Phase 3: Resilience and messaging

Source pack for lessons 06 to 08 of **C# 301 (Super Hero to Legendary)**. The optional originals are at https://github.com/Uee03/Code101 under `source/csharp/301-super-hero-to-legendary/phase-3-resilience-and-messaging/` (Code > Download ZIP, or git clone). Every file is also shown in full in the lesson.

**Status: written (not run).** Expected outputs were derived from the code and the documentation.

| Folder | Lesson | You build |
|---|---|---|
| `06-resilience-with-polly` | Resilience with Polly | Retry, timeout, circuit breaker, bulkhead and a combined Polly v8 pipeline against a flaky fake dependency; exercise: a fallback. |
| `07-background-services-outbox-and-sagas` | Background services, the outbox pattern and sagas | A transactional outbox on SQLite, a `BackgroundService` relay, an idempotent consumer and an orchestrated saga; exercise: a saga that fails at the last step. |
| `08-observability-with-opentelemetry` | Observability with OpenTelemetry | An instrumented minimal API plus a Docker Compose stack (Collector, Jaeger, Prometheus) with every configuration file; exercise: a latency histogram. |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/` | The finished project. |
| `exercise/starter/` | One file with TODO markers; add it to a copy of your finished lesson folder. |
| `exercise/solution/` | The answer. |
| `verify.json` | Maintainer check data. |

## How to run
1. Install the .NET SDK **11.0.100**. Docker with Compose is needed only for lesson 08.
2. Lessons 06 and 07: open a terminal in `code` and run `dotnet run --project . --nologo`. Lesson 07 leaves an `outbox.db` file in the folder; delete it afterwards.
3. Lesson 08: `docker compose up -d` and `docker compose ps` in `code`, then `dotnet run --nologo` in a second terminal, then the `curl` commands from the lesson. Look at Jaeger (http://localhost:16686) and Prometheus (http://localhost:9090). Finish with `docker compose down -v`. The stack publishes ports 4317, 4318, 9090 and 16686 on `127.0.0.1` only; the API uses 5308.

## Needs
.NET SDK 11.0.100 / net11.0. NuGet packages (internet for the first restore): Polly.Core 8.9.1 and Polly.RateLimiting 8.9.1 (06); Microsoft.Extensions.Hosting 11.0.0 and Microsoft.Data.Sqlite 11.0.0 (07); OpenTelemetry 1.21.0 packages (08). Images (08): `otel/opentelemetry-collector-contrib:0.165.0`, `jaegertracing/jaeger:2.23.0`, `prom/prometheus:v3.16.0`. No lockfiles are included.

## First-timer time
Lesson 06: 70-90 minutes; 07: 80-100; 08: 80-100.

Next: Phase 4, Production.
