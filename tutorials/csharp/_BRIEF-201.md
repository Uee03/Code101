# C# 201 (Hero to Super Hero): author brief

## Learner and outcome
Learners who finished C# 101 (`101-zero-to-hero/`) and have 1 to 2 years of experience. Eleven lessons in four downloadable phases lead from core language depth to a small, tested, containerised notes API.
Voice: assume 101; explain the why; "Why this, not that" tables; Mermaid diagrams; every lesson has outcomes, a recap, a predict-before-run step, a three-rung exercise (guided, change, stretch), common mistakes, a best-practice line with a source, going further, summary and next lesson. Phase 2, 3 and 4 end with a mixed review (04 for phase 1).
Security, identity and API craft stay inside capstones: this level stays minimal and links the dotnet capstone (`capstones/backend-dotnet`) instead of duplicating it.

## Version decision (2026-11-23, same pins as 101)
SDK 11.0.100 with `global.json` `latestPatch`, `TargetFramework` `net11.0`, nullable and implicit usings enabled. Package versions were read from NuGet on 2026-11-23:
FastEndpoints 9.0.0, FluentValidation(.DependencyInjectionExtensions) 12.2.0, Microsoft.AspNetCore.Authentication.JwtBearer 11.0.0, Microsoft.AspNetCore.OpenApi 11.0.0, Microsoft.EntityFrameworkCore.Design 11.0.0, Npgsql 11.0.0, Npgsql.EntityFrameworkCore.PostgreSQL 11.0.0, Dapper 2.1.100, Microsoft.Extensions.DependencyInjection 11.0.0, xunit.v3.mtp-v2 4.0.3, Microsoft.AspNetCore.Mvc.Testing 11.0.0, local tool dotnet-ef 11.0.0.
Images: `postgres:17-alpine`, `mcr.microsoft.com/dotnet/sdk:11.0.100-alpine3.24`, `mcr.microsoft.com/dotnet/aspnet:11.0.0-alpine3.24` (same tags as the dotnet capstone).
xUnit v3 with the Microsoft Testing Platform: `global.json` carries `"test": { "runner": "Microsoft.Testing.Platform" }`; tests are run with `dotnet test` from the test project folder. The test project uses the Web SDK, as the ASP.NET Core integration-test docs require.

## Lesson map
| Phase | Lesson | Main build / exercise |
|---|---|---|
| 1 core skills | 01 Interfaces, inheritance and polymorphism | discount engine / `ThresholdOff` |
| 1 core skills | 02 Generics and collections in depth | generic repository, collection tour / `UniqueQueue<T>` |
| 1 core skills | 03 LINQ | queries over orders, deferred execution / big spenders, top category, monthly totals |
| 1 core skills | 04 async/await and Task | sequential vs concurrent, cancellation, failures / `WhenAll` squares |
| 2 web APIs | 05 First ASP.NET Core API | one notes API in minimal API, controllers and FastEndpoints / `DELETE /notes/{id}` |
| 2 web APIs | 06 DTOs, validation, the Result pattern and ProblemDetails | validated notes API with problem responses / `Result.Map` and `Match` |
| 2 web APIs | 07 Dependency injection and configuration | lifetimes counter, validated options, overrides / console scopes |
| 3 data | 08 EF Core and PostgreSQL (Docker, compose and `.env.example` shown in full) | relations, migration, tracking vs no-tracking / `Priority` column and second migration |
| 3 data | 09 Stored procedures and raw SQL | function and procedure via Dapper and EF `SqlQuery`/`ExecuteSql`, SQL injection / three parameterized queries |
| 4 security and quality | 10 JWT bearer authentication and authorization policies | token validation, role/claim policies, ownership check / read policy, list, 404 instead of 403 |
| 4 security and quality | 11 Testing with xUnit and the notes API mini project | notes API tying 05-09 together, 12 tests, multi-stage non-root Dockerfile shown in full / test-first trimming |

## Sources (Tier 1)
- ASP.NET Core best practices: https://learn.microsoft.com/aspnet/core/fundamentals/best-practices
- Choose between controllers and minimal APIs: https://learn.microsoft.com/aspnet/core/fundamentals/apis
- FastEndpoints: https://fast-endpoints.com/docs/get-started and https://fast-endpoints.com/docs/validation
- Error handling in APIs: https://learn.microsoft.com/aspnet/core/fundamentals/error-handling-api
- Dependency injection and options: https://learn.microsoft.com/aspnet/core/fundamentals/dependency-injection , https://learn.microsoft.com/dotnet/core/extensions/options
- EF Core: https://learn.microsoft.com/ef/core/ (querying, tracking, migrations, SQL queries)
- JWT bearer and policies: https://learn.microsoft.com/aspnet/core/security/authentication/configure-jwt-bearer-authentication , https://learn.microsoft.com/aspnet/core/security/authorization/policies
- Integration tests: https://learn.microsoft.com/aspnet/core/test/integration-tests ; xUnit v3: https://xunit.net/docs/getting-started/v3/getting-started ; `dotnet test` modes: https://learn.microsoft.com/dotnet/core/testing/unit-testing-with-dotnet-test
- Language and collections: https://learn.microsoft.com/dotnet/csharp/ , https://learn.microsoft.com/dotnet/standard/collections/selecting-a-collection-class
- OWASP SQL injection prevention: https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html

## Delivery and verification (user policy 2026-11-23: no smoke tests)
Lessons and source were written **without running anything** (no builds, servers, tests or Docker). Every lesson carries the draft notice under its title and `verified: not yet run`. Only the static check ran: `python scripts\verify_labs.py --static csharp/201`. Expected output was derived by reading the code; error texts are marked "typical message" unless they come from the official docs.
Each lesson folder still has a `verify.json` so a later run can verify it. Steps use Windows `cmd` syntax (`set "VAR=value"&& command`, `-o NUL`); adjust for other shells. Docker lessons (08, 09, 11) need a running engine; web lessons start background servers on ports 5051-5053, 5061, 5071-5072, 5081-5082, 8085; databases use 5433, 5434, 5435.
Lessons 08 to 11 use an **overlay** exercise: `exercise/starter` and `exercise/solution` contain only the files the exercise changes; the verifier copies the solution over `code/` (or a copy of it).
Build the packs with `python scripts/build_packs.py csharp-201`. Edit only `tutorials/csharp/` and `source/csharp/201-hero-to-super-hero/`. No commits. Stop after two failed fixes to the same issue.
