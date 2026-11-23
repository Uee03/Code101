# C# 301, Phase 2: Performance

Source pack for lessons 04 and 05 of **C# 301 (Super Hero to Legendary)**. The optional originals are at https://github.com/Uee03/Code101 under `source/csharp/301-super-hero-to-legendary/phase-2-performance/` (Code > Download ZIP, or git clone). Every file is also shown in full in the lesson.

**Status: written (not run).** Expected outputs were derived from the code and the documentation. **This phase contains no benchmark results on purpose**: timings depend on your machine, so the lesson gives you tables to fill in with your own measurements.

| Folder | Lesson | You build |
|---|---|---|
| `04-performance-fundamentals` | Performance fundamentals | BenchmarkDotNet benchmarks (`Split` vs `ReadOnlySpan<char>`, `Task` vs `ValueTask`), a correctness check and an allocation probe; exercise: a string-building benchmark. |
| `05-caching` | Caching | `IMemoryCache` vs `HybridCache` experiments (stampede, staleness, invalidation by key and tag) and an optional Redis compose file; exercise: tenant-safe cache keys. |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/` | The finished project. |
| `exercise/starter/` | One file with TODO markers; add it to a copy of your finished lesson folder. |
| `exercise/solution/` | The answer. |
| `verify.json` | Maintainer check data. |

## How to run
1. Install the .NET SDK **11.0.100**. Docker is only needed for the optional Redis part of lesson 05.
2. Open a terminal in the lesson's `code` folder.
3. Lesson 04: `dotnet run --project . -c Release --nologo -- --check`, then `-- --alloc`, then `-- --filter "*SumBenchmarks*"`. **Always use `-c Release` for anything you measure.**
4. Lesson 05: `dotnet run --project . --nologo`. For Redis: copy `.env.example` to `.env`, change the password, `docker compose up -d --wait`, set `REDIS_CONFIGURATION` as the lesson shows, run again, then `docker compose down -v`.

## Needs
.NET SDK 11.0.100 / net11.0. NuGet packages (internet for the first restore): BenchmarkDotNet 0.15.8 (lesson 04); Microsoft.Extensions.Hosting 11.0.0, Microsoft.Extensions.Caching.Memory 11.0.0, Microsoft.Extensions.Caching.Hybrid 11.0.1 and Microsoft.Extensions.Caching.StackExchangeRedis 11.0.0 (lesson 05). Redis image `redis:8.8-alpine` (optional). Benchmarks create a `BenchmarkDotNet.Artifacts` folder: do not commit it. No lockfiles are included.

## First-timer time
Lesson 04: 70-90 minutes (benchmark runs take minutes); lesson 05: 80-100 minutes.

Next: Phase 3, Resilience and messaging.
