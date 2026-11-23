# C# 201 track state

Last updated: 2026-11-23. All 11 lessons **written (not run)** under the no-smoke-test policy. Static check clean; packs built.

## Version and scope
- SDK 11.0.100 (`latestPatch`), `net11.0`; package and image versions are in [_BRIEF-201.md](_BRIEF-201.md).
- Only `tutorials/csharp/` and `source/csharp/201-hero-to-super-hero/` were edited. No code, build, server, test or Docker command was executed. NuGet and MCR tag listings and FastEndpoints / xUnit / ASP.NET docs were read to pin versions and check signatures.
- Level 201 links the dotnet capstone for Keycloak and the full platform; it does not duplicate it.

## Lessons
| Lesson | Phase | Status | Notes |
|---|---|---|---|
| [01. Interfaces, inheritance and polymorphism](201-hero-to-super-hero/phase-1-core-skills/01-interfaces-inheritance-polymorphism.md) | 1 | written (not run) | console |
| [02. Generics and collections in depth](201-hero-to-super-hero/phase-1-core-skills/02-generics-and-collections.md) | 1 | written (not run) | console |
| [03. LINQ](201-hero-to-super-hero/phase-1-core-skills/03-linq.md) | 1 | written (not run) | console |
| [04. async/await and Task](201-hero-to-super-hero/phase-1-core-skills/04-async-await-and-task.md) | 1 | written (not run) | console; timing comparison only |
| [05. First ASP.NET Core API](201-hero-to-super-hero/phase-2-web-apis/05-first-aspnet-core-api.md) | 2 | written (not run) | three web projects, curl; FastEndpoints 9.0.0 |
| [06. DTOs, validation, Result, ProblemDetails](201-hero-to-super-hero/phase-2-web-apis/06-dtos-validation-result-problemdetails.md) | 2 | written (not run) | web + console exercise |
| [07. Dependency injection and configuration](201-hero-to-super-hero/phase-2-web-apis/07-dependency-injection-and-options.md) | 2 | written (not run) | web + console exercise |
| [08. EF Core and PostgreSQL](201-hero-to-super-hero/phase-3-data/08-ef-core-and-postgres.md) | 3 | written (not run) | Docker; local `dotnet-ef` tool; overlay exercise |
| [09. Stored procedures and raw SQL](201-hero-to-super-hero/phase-3-data/09-stored-procedures-and-raw-sql.md) | 3 | written (not run) | Docker; `db/init.sql`; overlay exercise |
| [10. JWT authentication and authorization](201-hero-to-super-hero/phase-4-security-and-quality/10-jwt-authentication-and-authorization.md) | 4 | written (not run) | web; `verify/check*.py` scripts |
| [11. Testing with xUnit and the notes API](201-hero-to-super-hero/phase-4-security-and-quality/11-testing-and-notes-api.md) | 4 | written (not run) | 12 tests, Docker; overlay exercise |

## Static check
`python scripts\verify_labs.py --static csharp/201`: **11 static-checked, 0 failed.** Lesson text contains every non-blank line of every `code/` file (except the `skip_lesson_check` files, which are identical to an earlier lesson: global.json, .gitignore, and in lesson 11 `Result.cs`, `Mapping.cs`, `GlobalExceptionHandler.cs`, `CreateNoteValidator.cs`, `NotesOptions.cs`, `appsettings.json`) and every expected output.

## First real run: things to check (author assumptions, not yet confirmed)
1. **05**: `Send.CreatedAtAsync<GetNoteEndpoint>(new { id = ... }, created, cancellation: ct)` produces `Location: /notes/2`; FastEndpoints serialises camelCase and accepts a `sealed record` with `init` properties as the response type; `GET /notes/99` in the controller project returns a problem-details body.
2. **06**: `ValidationResult.ToDictionary()` returns the type `TypedResults.ValidationProblem` accepts; the JSON fragments in `verify.json` (`"errors":{"Title":[...]}`, `"code":"..."`) are contiguous in the real output; `UseStatusCodePages()` together with `AddProblemDetails()` is harmless for these routes.
3. **07**: counters `1/1/2` then `1/2/4`; `--Notes:PageSize=9` reaches the app through `dotnet run`; editing `appsettings.json` in the project folder reaches `IOptionsMonitor` (content root = project folder).
4. **08**: `dotnet ef migrations add` works from a console app with top-level statements and `OnConfiguring` reading `NOTES_CONNECTION`; `Entry(...).State` prints `Modified`; `psql \dt` table names (`NoteTag`, `__EFMigrationsHistory`); the second migration (`AddPriority`) applies through `MigrateAsync()`.
5. **09**: raw interpolated string `$"""..."""` converts to `FormattableString` for `SqlQuery`; aliases `AS "Id"` map to `NoteRow`; `CALL` with an integer parameter through Npgsql; `SqlQuery<int>` needs the column named `Value`.
6. **10**: with `MapInboundClaims = false`, `sub`, `role` and the repeated `permission` claim keep their names and array order; tampering with the last three characters of the signature yields `401`; `--environment Development` is accepted by `dotnet run`.
7. **11**: xUnit v3 (`xunit.v3.mtp-v2`) in a **Web SDK** test project builds and `dotnet test` (MTP mode via `global.json`) discovers 12 tests; `WebApplicationFactory<Program>` finds the content root; `docker compose up --build --wait` succeeds with `cap_drop: ALL` and `no-new-privileges`; the Alpine `wget` healthcheck works; `InvariantGlobalization` is enough for the Alpine runtime; `id -u` is not 0.
8. Version-specific API names that may have moved in .NET 11 / EF Core 11 / Npgsql 11: `AddAuthorizationBuilder`, `TypedResults.Problem(extensions:)`, `ExecuteUpdateAsync(SetProperty)`, `Database.SqlQuery<T>`, `ExecuteSqlAsync`, `JsonWebTokenHandler.CreateToken`, `JwtBearerOptions.MapInboundClaims`.
9. `verify.json` steps use Windows `cmd` syntax (`set "VAR=..."&&`, `-o NUL`, `dotnet ... --urls`): run on Windows, or adapt for other shells.

## Review status
Not yet reviewed or walked through by a learner persona. The intermediate walk-through (`/walkthrough`) is the next step; fix findings through the Tutorial Author.

## Packs
`python scripts\build_packs.py csharp-201` built after the static check passed:
```text
built csharp-201-phase-1-core-skills.zip (52 files)
built csharp-201-phase-2-web-apis.zip (66 files)
built csharp-201-phase-3-data.zip (26 files)
built csharp-201-phase-4-security-and-quality.zip (42 files)
built csharp-201-all.zip (4 phases)
```
Sizes: all 110,682 bytes; phases 25,270 / 33,076 / 17,680 / 30,630 bytes (limit 25 MB each).

## Decisions needed
None. Art: `assets: []` everywhere.
