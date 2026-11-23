---
track: capstone
level: 201
phase: 2
phase_name: data
lesson: 02
title: "Data access with EF Core and stored functions"
time: 150 min
prerequisites: [capstone-backend-dotnet-01, capstone-platform-04, databases-101]
versions: { dotnet_sdk: "11.0.100", fastendpoints: "9.0.0", efcore: "11.0.0", npgsql_efcore: "11.0.0", postgres_image: "17-alpine", keycloak_image: "quay.io/keycloak/keycloak:26.8.2" }
verified: 2026-11-23 on Windows 11, .NET SDK 11.0.100, Docker 29.9.3, Compose 5.7.0, Python 3.15.2
source: capstones/backend-dotnet/source/phase-2-data/02-data-access/
assets: []
---

# 02. Data access with EF Core and stored functions

## Why it matters
A library has a card catalogue (fast lookups), a lending desk (rules: who may borrow what, how many days) and a librarian who knows both. The platform database is the lending desk: its constraints, triggers and three stored functions already enforce the rules. This chapter is the librarian: the API asks the database questions, hands over parameters safely, and translates the answers into the HTTP contract, including the parts of HTTP that are about *time*: "I read version 3, change it only if it is still version 3" (`ETag` and `If-Match`) and "I sent this create twice by mistake, make it count once" (`Idempotency-Key`).

## What you will build
The other 24 operations of the contract (27 endpoint classes in all): teams, members, projects, tasks, comments, users and the audit log, on top of EF Core 11 and Npgsql. Database first: you do **not** run EF migrations. Reads are EF queries projected to DTOs; simple writes use EF change tracking; `create_team`, `complete_task` and `reassign_task` are called as stored functions. Every write runs in a transaction that tells the audit trigger who is acting. You also add ETag with `If-Match`, keyset cursor pagination, task filters, JSON Merge Patch and idempotency keys.

Sign-in does not exist yet. A **stand-in identity** (`DevAuthenticationHandler`) treats every request as alice, the admin; chapter 3 deletes it. That is why the conformance script ends with **15 passed, 3 failed** in this chapter: `me` (rate-limit headers arrive in chapter 5), `401 without token` and `403 for member on admin route` (they need real tokens, chapter 3).

## Before you start
- Chapter 01 done or its pack unzipped. This chapter's `code` folder holds the whole project; the files that are new or changed are shown below (steps 1 and 3 to 20); files unchanged from chapter 01 are named at the end of "How it works".
- Docker running in Linux-container mode; Python 3.10+; host ports 5432 and 8180 free (and 8000 for the API).
- Source pack: unzip `backend-dotnet-phase-2-data.zip`, open `02-data-access/code`.

New terms (see the [glossary](../../GLOSSARY.md)): **database first**, **entity**, **DbContext**, **projection**, **stored function**, **SQLSTATE**, **optimistic concurrency**, **ETag and If-Match**, **keyset pagination**, **JSON Merge Patch**, **idempotency key**.

## Steps
### Step 1. Bring in the platform files
These files are **not written here**. They come from the platform capstone and are copied byte for byte from `capstones/platform/source/phase-4-conformance/04-conformance-script/code/`: the database (`db/schema.sql`, `db/seed.sql`), the Keycloak realm (`keycloak/realm-tasksteams.json`), the infrastructure Compose file (`docker-compose.yml`), the conformance script (`scripts/conformance.py`), the environment template (`.env.example`) and the contract (`openapi.yaml`, already copied in chapter 01). Platform chapters 02, 03 and 04 show each of them line by line; the lesson checker therefore skips them here. Do not edit them: a change to the contract is a change to the platform capstone.

Copy them into your solution folder so it looks like this (the pack has them already):
```text
code/
  .env.example
  docker-compose.yml
  db/schema.sql  db/seed.sql
  keycloak/realm-tasksteams.json
  scripts/conformance.py
```
Create your own `.env` from the template. It is Git-ignored and holds only fake local values.
```powershell
Copy-Item .env.example .env
```
On macOS and Linux: `cp .env.example .env`.

### Step 2. Start Postgres and Keycloak
Folder: the solution folder (`code`). The project name after `-p` keeps this stack's containers, network and volume together so one command removes them.
```powershell
docker compose -p bdn up -d --wait
```
Expected output (Keycloak needs about 30 seconds on a first start; `--wait` returns when both are healthy):
```text
 Network tasksteams-net Created
 Volume bdn_pg_data Created
 Container bdn-db-1 Created
 Container bdn-keycloak-1 Created
 Container bdn-db-1 Started
 Container bdn-keycloak-1 Started
 Container bdn-db-1 Waiting
 Container bdn-keycloak-1 Waiting
 Container bdn-db-1 Healthy
 Container bdn-keycloak-1 Healthy
```
The database container ran `db/schema.sql` and `db/seed.sql` once, when its volume was empty. Look at what is inside: the three seed users.
```powershell
docker compose -p bdn exec -T db psql -U tasks_admin -d tasksteams -tA -c "SELECT username FROM users ORDER BY username"
```
Expected output:
```text
alice
bob
carol
```
The API will not use the administrator account `tasks_admin`. It connects as `tasks_app`, a role created by `schema.sql` that may read and write rows and run the functions, but cannot change tables and cannot edit or delete audit entries (requirement R-23, least privilege).

### Step 3. Add the EF Core packages
Folder: the solution folder (`code`). EF Core is the object-relational mapper (it turns rows into objects); Npgsql is the PostgreSQL driver and its EF Core provider.
```powershell
cd src/TasksApi
dotnet add package Microsoft.EntityFrameworkCore --version 11.0.0
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL --version 11.0.0
cd ../..
```
Expected result: for each package `info : PackageReference for package '...' version '11.0.0' added to file '...TasksApi.csproj'.` (plus the usual download lines). The project file now lists three packages. There is no `Microsoft.EntityFrameworkCore.Design` and no `dotnet-ef` tool: those exist to create migrations, and we do not (see "How it works").

**File: `src/TasksApi/TasksApi.csproj`**
```xml
<Project Sdk="Microsoft.NET.Sdk.Web">

  <PropertyGroup>
    <TargetFramework>net11.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <InvariantGlobalization>true</InvariantGlobalization>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="FastEndpoints" Version="9.0.0" />
    <PackageReference Include="Microsoft.EntityFrameworkCore" Version="11.0.0" />
    <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="11.0.0" />
  </ItemGroup>

</Project>
```

### Step 4. Configuration: the connection string
Replace `src/TasksApi/appsettings.json`. `Timeout=5` makes opening a connection fail after 5 seconds instead of hanging. The password is the fake local one from `schema.sql`; a real system sets `ConnectionStrings__Default` from a secret store and removes it from the file.

**File: `src/TasksApi/appsettings.json`**
```json
{
  "Urls": "http://127.0.0.1:8000",
  "ConnectionStrings": {
    "Default": "Host=127.0.0.1;Port=5432;Database=tasksteams;Username=tasks_app;Password=tasks_app_local_only;Timeout=5"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning",
      "Microsoft.EntityFrameworkCore": "Critical"
    }
  },
  "AllowedHosts": "*"
}
```

### Step 5. Entities
Do not build until "Run it": the files of steps 5 to 19 refer to each other, so the compiler reports errors until the last one exists. Create the folder `src/TasksApi/Data`. An entity is a class that mirrors one table; the property names become the column names (`CreatedAt` is `created_at`, see the next step). The classes are plain on purpose: the rules live in the database.

**File: `src/TasksApi/Data/Entities.cs`**
```csharp
namespace TasksApi.Data;

// Plain classes that mirror the tables in db/schema.sql. The database owns the schema; EF Core only maps to it.

public interface ICreated
{
    Guid Id { get; }
    DateTimeOffset CreatedAt { get; }
}

public sealed class User
{
    public Guid Id { get; set; }
    public string Username { get; set; } = "";
    public string Email { get; set; } = "";
    public string DisplayName { get; set; } = "";
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
}

public sealed class Team : ICreated
{
    public Guid Id { get; set; }
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public Guid CreatedBy { get; set; }
    public int Version { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public List<TeamMember> Members { get; set; } = [];
}

public sealed class TeamMember
{
    public Guid TeamId { get; set; }
    public Guid UserId { get; set; }
    public string Role { get; set; } = "member";
    public DateTimeOffset JoinedAt { get; set; }
    public Team? Team { get; set; }
    public User? User { get; set; }
}

public sealed class Project : ICreated
{
    public Guid Id { get; set; }
    public Guid TeamId { get; set; }
    public string Key { get; set; } = "";
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public bool Archived { get; set; }
    public Guid CreatedBy { get; set; }
    public int Version { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
}

// Named TaskItem so it never clashes with System.Threading.Tasks.Task.
public sealed class TaskItem : ICreated
{
    public Guid Id { get; set; }
    public Guid ProjectId { get; set; }
    public string Title { get; set; } = "";
    public string Description { get; set; } = "";
    public string Status { get; set; } = "todo";
    public string Priority { get; set; } = "medium";
    public Guid? AssigneeId { get; set; }
    public DateOnly? DueDate { get; set; }
    public DateTimeOffset? CompletedAt { get; set; }
    public Guid CreatedBy { get; set; }
    public int Version { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public Project? Project { get; set; }
}

public sealed class Comment : ICreated
{
    public Guid Id { get; set; }
    public Guid TaskId { get; set; }
    public Guid AuthorId { get; set; }
    public string Body { get; set; } = "";
    public DateTimeOffset CreatedAt { get; set; }
    public TaskItem? TaskItem { get; set; }
    public User? Author { get; set; }
}

public sealed class AuditEntry
{
    public long Id { get; set; }
    public DateTimeOffset OccurredAt { get; set; }
    public Guid? ActorId { get; set; }
    public string Action { get; set; } = "";
    public string EntityType { get; set; } = "";
    public Guid EntityId { get; set; }
    public string Details { get; set; } = "{}";
}

public sealed class IdempotencyKey
{
    public Guid UserId { get; set; }
    public string Key { get; set; } = "";
    public string RequestHash { get; set; } = "";
    public int? StatusCode { get; set; }
    public string? ResponseBody { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset ExpiresAt { get; set; }
}
```

### Step 6. The `DbContext`
`TasksDbContext` maps the entities to the existing tables and tells EF Core which columns the database fills in. Read the comments: `ValueGeneratedOnAddOrUpdate` means "the database sets this (a default or a trigger); leave it out of INSERT and UPDATE and read the result back", and `IsConcurrencyToken` on `Version` makes every UPDATE of a team, project or task carry `WHERE version = <the version the caller saw>`. `BeginWriteAsync` is used by every write: it starts a transaction and sets `app.current_user_id` for that transaction only, which is what the audit trigger reads.

**File: `src/TasksApi/Data/TasksDbContext.cs`**
```csharp
using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;

namespace TasksApi.Data;

public sealed partial class TasksDbContext(DbContextOptions<TasksDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Team> Teams => Set<Team>();
    public DbSet<TeamMember> TeamMembers => Set<TeamMember>();
    public DbSet<Project> Projects => Set<Project>();
    public DbSet<TaskItem> Tasks => Set<TaskItem>();
    public DbSet<Comment> Comments => Set<Comment>();
    public DbSet<AuditEntry> AuditLog => Set<AuditEntry>();
    public DbSet<IdempotencyKey> IdempotencyKeys => Set<IdempotencyKey>();

    protected override void OnModelCreating(ModelBuilder model)
    {
        model.Entity<User>().ToTable("users");
        model.Entity<Team>().ToTable("teams");
        model.Entity<TeamMember>().ToTable("team_members").HasKey(m => new { m.TeamId, m.UserId });
        model.Entity<Project>().ToTable("projects");
        model.Entity<TaskItem>().ToTable("tasks");
        model.Entity<Comment>().ToTable("comments");
        model.Entity<AuditEntry>().ToTable("audit_log").Property(a => a.Details).HasColumnType("jsonb");
        model.Entity<IdempotencyKey>().ToTable("idempotency_keys").HasKey(k => new { k.UserId, k.Key });
        model.Entity<IdempotencyKey>().Property(k => k.ResponseBody).HasColumnType("jsonb");

        model.Entity<Comment>().HasOne(c => c.TaskItem).WithMany().HasForeignKey(c => c.TaskId);

        // Columns the database fills in (defaults and triggers). EF Core leaves them out of INSERT and UPDATE and reads the result back.
        // Version is also the concurrency token: UPDATE ... WHERE version = <the version the client saw>.
        foreach (var versioned in new[] { typeof(Team), typeof(Project), typeof(TaskItem) })
        {
            model.Entity(versioned).Property(nameof(Team.Version)).IsConcurrencyToken().ValueGeneratedOnAddOrUpdate();
            model.Entity(versioned).Property(nameof(Team.CreatedAt)).ValueGeneratedOnAdd();
            model.Entity(versioned).Property(nameof(Team.UpdatedAt)).ValueGeneratedOnAddOrUpdate();
        }
        model.Entity<TaskItem>().Property(t => t.CompletedAt).ValueGeneratedOnAddOrUpdate();
        model.Entity<Comment>().Property(c => c.CreatedAt).ValueGeneratedOnAdd();
        model.Entity<TeamMember>().Property(m => m.JoinedAt).ValueGeneratedOnAdd();

        // The tables use snake_case column names.
        foreach (var property in model.Model.GetEntityTypes().SelectMany(e => e.GetProperties()))
        {
            property.SetColumnName(SnakeCase().Replace(property.Name, "$1_$2").ToLowerInvariant());
        }
    }

    [GeneratedRegex("([a-z0-9])([A-Z])")]
    private static partial Regex SnakeCase();

    // Starts a transaction and tells the audit trigger who is acting; the setting lasts until the transaction ends.
    public async Task<IDbContextTransaction> BeginWriteAsync(Guid actorId, CancellationToken ct)
    {
        var transaction = await Database.BeginTransactionAsync(ct);
        await Database.ExecuteSqlAsync($"SELECT set_config('app.current_user_id', {actorId.ToString()}, true)", ct);
        return transaction;
    }
}
```

### Step 7. DTOs and request helpers
The response records for the other resources, named after the OpenAPI schemas, and the generic page wrapper. The name `Paged<T>` is not `Page<T>`: a record may not have a member named like itself (`Page` is the JSON member), see Common mistakes.

**File: `src/TasksApi/Contracts/Dtos.cs`**
```csharp
using System.Text.Json;

namespace TasksApi.Contracts;

public sealed record PageInfo(int Limit, string? NextCursor);

public sealed record Paged<T>(IReadOnlyList<T> Items, PageInfo Page);

public sealed record UserSummaryDto(Guid Id, string Username, string DisplayName);

public sealed record MemberDto(Guid UserId, string Username, string DisplayName, string Role, DateTimeOffset JoinedAt);

public sealed record ProjectDto(
    Guid Id,
    Guid TeamId,
    string Key,
    string Name,
    string Description,
    bool Archived,
    int Version,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

public sealed record TaskDto(
    Guid Id,
    Guid ProjectId,
    string Title,
    string Description,
    string Status,
    string Priority,
    Guid? AssigneeId,
    DateOnly? DueDate,
    DateTimeOffset? CompletedAt,
    Guid CreatedBy,
    int Version,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

public sealed record CommentDto(Guid Id, Guid TaskId, UserSummaryDto Author, string Body, DateTimeOffset CreatedAt);

public sealed record AuditEntryDto(
    long Id,
    DateTimeOffset OccurredAt,
    Guid? ActorId,
    string Action,
    string EntityType,
    Guid EntityId,
    JsonElement Details);
```

Requests that carry only ids from the route, and one request class for list operations that are nested under an id:

**File: `src/TasksApi/Contracts/Requests.cs`**
```csharp
namespace TasksApi.Contracts;

// Requests that carry only an id from the route.
public sealed class TeamIdRequest
{
    public Guid TeamId { get; set; }
}

public sealed class ProjectIdRequest
{
    public Guid ProjectId { get; set; }
}

public sealed class TaskIdRequest
{
    public Guid TaskId { get; set; }
}

public sealed class CommentIdRequest
{
    public Guid CommentId { get; set; }
}

// Route id plus the paging query parameters shared by the list operations.
public sealed class PagedRequest
{
    public Guid TeamId { get; set; }
    public Guid ProjectId { get; set; }
    public Guid TaskId { get; set; }
    public int? Limit { get; set; }
    public string? Cursor { get; set; }
}
```

### Step 8. Projections
A projection is a query that selects exactly the columns a DTO needs. Writing the mapping as an **expression tree** (`Expression<Func<Team, TeamDto>>`) lets EF Core translate it to SQL: `t.Members.Count` becomes a `count(*)` subquery, and no entity is loaded or tracked.

**File: `src/TasksApi/Data/Projections.cs`**
```csharp
using System.Linq.Expressions;
using TasksApi.Contracts;

namespace TasksApi.Data;

// Entity to DTO mappings written as expression trees, so EF Core turns them into a SELECT of just those columns.
public static class Projections
{
    public static readonly Expression<Func<Team, TeamDto>> ToTeam = t =>
        new TeamDto(t.Id, t.Name, t.Description, t.Members.Count, t.CreatedBy, t.Version, t.CreatedAt, t.UpdatedAt);

    public static readonly Expression<Func<TeamMember, MemberDto>> ToMember = m =>
        new MemberDto(m.UserId, m.User!.Username, m.User.DisplayName, m.Role, m.JoinedAt);

    public static readonly Expression<Func<Project, ProjectDto>> ToProject = p =>
        new ProjectDto(p.Id, p.TeamId, p.Key, p.Name, p.Description, p.Archived, p.Version, p.CreatedAt, p.UpdatedAt);

    public static readonly Expression<Func<TaskItem, TaskDto>> ToTask = t =>
        new TaskDto(t.Id, t.ProjectId, t.Title, t.Description, t.Status, t.Priority, t.AssigneeId, t.DueDate,
            t.CompletedAt, t.CreatedBy, t.Version, t.CreatedAt, t.UpdatedAt);

    public static readonly Expression<Func<Comment, CommentDto>> ToComment = c =>
        new CommentDto(c.Id, c.TaskId, new UserSummaryDto(c.Author!.Id, c.Author.Username, c.Author.DisplayName), c.Body,
            c.CreatedAt);

    public static readonly Expression<Func<User, UserSummaryDto>> ToUser = u =>
        new UserSummaryDto(u.Id, u.Username, u.DisplayName);
}
```

### Step 9. Problems from the database
`DbErrors` maps database errors to the problems of the contract: the four custom SQLSTATE codes our stored functions raise (`TS404`, `TS409`, `TS412`, `TS422`), the three constraint errors you will meet (`23505` unique, `23503` foreign key, `23514` check) and the EF Core concurrency exception. Create the folder files in `src/TasksApi/Common`.

**File: `src/TasksApi/Common/DbErrors.cs`**
```csharp
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace TasksApi.Common;

// Turns a database error into the problem the contract promises.
public static class DbErrors
{
    // Custom SQLSTATE codes raised by the stored functions in db/schema.sql.
    public const string NotFound = "TS404";
    public const string RuleViolated = "TS409";
    public const string StaleVersion = "TS412";
    public const string InvalidInput = "TS422";

    public static ProblemException? Map(Exception exception)
    {
        if (exception is DbUpdateConcurrencyException)
        {
            return ProblemException.PreconditionFailed("The resource changed since you read it. Fetch it again and retry.");
        }
        for (var inner = exception; inner is not null; inner = inner.InnerException)
        {
            if (inner is PostgresException pg)
            {
                return pg.SqlState switch
                {
                    // Our own functions write messages meant for callers; Postgres messages are not shown.
                    NotFound => new ProblemException(StatusCodes.Status404NotFound, pg.MessageText),
                    RuleViolated => ProblemException.Conflict(pg.MessageText),
                    StaleVersion => ProblemException.PreconditionFailed(pg.MessageText),
                    InvalidInput => ProblemException.Unprocessable(pg.MessageText),
                    PostgresErrorCodes.UniqueViolation => ProblemException.Conflict("A resource with the same name or key already exists."),
                    PostgresErrorCodes.ForeignKeyViolation => ProblemException.Unprocessable("A referenced resource does not exist."),
                    PostgresErrorCodes.CheckViolation => ProblemException.Unprocessable("A value breaks a rule of the database."),
                    _ => null,
                };
            }
        }
        return null;
    }
}
```

The exception handler from chapter 01 now asks `DbErrors.Map` before it falls back to 500. Replace the file.

**File: `src/TasksApi/Common/ProblemExceptionHandler.cs`**
```csharp
using Microsoft.AspNetCore.Diagnostics;

namespace TasksApi.Common;

public sealed class ProblemExceptionHandler(ILogger<ProblemExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext context, Exception exception, CancellationToken cancellationToken)
    {
        var problem = exception as ProblemException ?? DbErrors.Map(exception);
        if (problem is not null)
        {
            await ProblemResponses.WriteAsync(context, problem.Status, problem.Message, problem.Code);
        }
        else if (exception is BadHttpRequestException bad)
        {
            await ProblemResponses.WriteAsync(context, bad.StatusCode, "The request could not be read.");
        }
        else
        {
            logger.LogError(exception, "Unhandled exception for {Method} {Path}", context.Request.Method, context.Request.Path);
            await ProblemResponses.WriteAsync(context, StatusCodes.Status500InternalServerError, "An unexpected error occurred.");
        }
        return true;
    }
}
```

### Step 10. ETag, paging and merge patch helpers
`ETags` formats and checks the strong validator (the quoted row version) and answers the `If-Match` rules: missing is 428, not a quoted number is 400, a different number is 412.

**File: `src/TasksApi/Common/ETags.cs`**
```csharp
using System.Globalization;

namespace TasksApi.Common;

// A strong ETag is the quoted row version, for example "3". If-Match carries the version the client last saw.
public static class ETags
{
    public static string Format(int version) => $"\"{version}\"";

    public static void Set(HttpContext context, int version) => context.Response.Headers.ETag = Format(version);

    // Missing header: 428. Anything that is not a quoted number: 400.
    public static int RequireIfMatch(string? ifMatch)
    {
        if (string.IsNullOrWhiteSpace(ifMatch))
        {
            throw ProblemException.PreconditionRequired();
        }
        var text = ifMatch.Trim();
        if (text.Length > 2 && text[0] == '"' && text[^1] == '"'
            && int.TryParse(text.AsSpan(1, text.Length - 2), NumberStyles.None, CultureInfo.InvariantCulture, out var version))
        {
            return version;
        }
        throw ProblemException.BadRequest("If-Match must be an ETag from this API, for example \"3\".");
    }

    public static void EnsureCurrent(int current, int expected, string what)
    {
        if (current != expected)
        {
            throw ProblemException.PreconditionFailed($"The {what} changed since you read it (current version {current}).");
        }
    }

    // True when the client already holds this version (If-None-Match), so the server can answer 304.
    public static bool IsNotModified(string? ifNoneMatch, int version) =>
        ifNoneMatch is not null && ifNoneMatch.Split(',').Any(tag => tag.Trim() == Format(version));
}
```

`Paging` holds keyset pagination: `CheckLimit`, `CheckSort`, the opaque cursor (base64url JSON of the last sort value and id), the `WHERE` for "after the cursor", and `ToPageAsync`, which reads `limit + 1` rows so it knows whether a next page exists without a second query.

**File: `src/TasksApi/Common/Paging.cs`**
```csharp
using System.Globalization;
using System.Text.Json;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.EntityFrameworkCore;
using TasksApi.Contracts;
using TasksApi.Data;

namespace TasksApi.Common;

// What a cursor holds: the sort value of the last item (when the sort has one) and its id.
public sealed record CursorData(string? Value, string Id);

// Keyset pagination: "give me the rows after the last one you saw", which stays stable while rows are added.
public static class Paging
{
    public const int DefaultLimit = 25;
    public const int MaxLimit = 100;

    public static int CheckLimit(int? limit) => limit switch
    {
        null => DefaultLimit,
        >= 1 and <= MaxLimit => limit.Value,
        _ => throw ProblemException.BadRequest($"limit must be between 1 and {MaxLimit}."),
    };

    // sort is "-createdAt" (the default), "createdAt", or any value in extra.
    public static string CheckSort(string? sort, params string[] extra)
    {
        sort ??= "-createdAt";
        return sort is "-createdAt" or "createdAt" || extra.Contains(sort)
            ? sort
            : throw ProblemException.BadRequest("sort is not one of the allowed values.");
    }

    public static string Encode(string? value, string id) =>
        WebEncoders.Base64UrlEncode(JsonSerializer.SerializeToUtf8Bytes(new CursorData(value, id), JsonSerializerOptions.Web));

    public static CursorData Decode(string cursor)
    {
        try
        {
            var data = JsonSerializer.Deserialize<CursorData>(WebEncoders.Base64UrlDecode(cursor), JsonSerializerOptions.Web);
            return data is { Id.Length: > 0 } ? data : throw new FormatException();
        }
        catch (Exception ex) when (ex is FormatException or JsonException)
        {
            throw ProblemException.BadRequest("The cursor is not valid.");
        }
    }

    public static string FormatTime(DateTimeOffset value) => value.UtcDateTime.ToString("O", CultureInfo.InvariantCulture);

    public static string CreatedCursor(DateTimeOffset createdAt, Guid id) => Encode(FormatTime(createdAt), id.ToString());

    public static DateTimeOffset ParseTime(string? value) =>
        DateTimeOffset.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind, out var time)
            ? time
            : throw ProblemException.BadRequest("The cursor is not valid.");

    public static Guid ParseId(string id) =>
        Guid.TryParse(id, out var guid) ? guid : throw ProblemException.BadRequest("The cursor is not valid.");

    // Rows after the cursor in createdAt order, ties broken by id.
    public static IQueryable<T> AfterCreatedCursor<T>(this IQueryable<T> query, string? cursor, bool descending)
        where T : class, ICreated
    {
        if (cursor is null)
        {
            return query;
        }
        var data = Decode(cursor);
        var at = ParseTime(data.Value);
        var id = ParseId(data.Id);
        return descending
            ? query.Where(x => x.CreatedAt < at || (x.CreatedAt == at && x.Id.CompareTo(id) < 0))
            : query.Where(x => x.CreatedAt > at || (x.CreatedAt == at && x.Id.CompareTo(id) > 0));
    }

    public static IOrderedQueryable<T> OrderByCreated<T>(this IQueryable<T> query, bool descending)
        where T : class, ICreated =>
        descending
            ? query.OrderByDescending(x => x.CreatedAt).ThenByDescending(x => x.Id)
            : query.OrderBy(x => x.CreatedAt).ThenBy(x => x.Id);

    // Reads limit + 1 rows: the extra row only tells us whether another page exists.
    public static async Task<Paged<TDto>> ToPageAsync<TRow, TDto>(IQueryable<TRow> ordered, int limit,
        Func<TRow, string> cursorOf, Func<TRow, TDto> map, CancellationToken ct)
    {
        var rows = await ordered.Take(limit + 1).ToListAsync(ct);
        var next = rows.Count > limit ? cursorOf(rows[limit - 1]) : null;
        return new Paged<TDto>(rows.Take(limit).Select(map).ToList(), new PageInfo(limit, next));
    }

    public static Task<Paged<T>> ToPageAsync<T>(IQueryable<T> ordered, int limit, Func<T, string> cursorOf,
        CancellationToken ct) =>
        ToPageAsync(ordered, limit, cursorOf, row => row, ct);
}
```

`Optional<T>` is the answer to JSON Merge Patch (RFC 7396): in a PATCH body an **absent** field means "leave it" and a field set to **null** means "clear it". A normal `string?` property cannot tell them apart, so `PATCH` request classes use `Optional<string>`, which remembers whether the field was in the JSON.

**File: `src/TasksApi/Common/Optional.cs`**
```csharp
using System.Text.Json;
using System.Text.Json.Serialization;

namespace TasksApi.Common;

// JSON Merge Patch (RFC 7396) must tell "field absent" (leave it) from "field is null" (clear it).
// A plain nullable property cannot, so PATCH requests use Optional<T>: IsSet is true when the field was in the JSON.
[JsonConverter(typeof(OptionalConverterFactory))]
public readonly record struct Optional<T>(T? Value, bool IsSet);

public sealed class OptionalConverterFactory : JsonConverterFactory
{
    public override bool CanConvert(Type type) => type.IsGenericType && type.GetGenericTypeDefinition() == typeof(Optional<>);

    public override JsonConverter CreateConverter(Type type, JsonSerializerOptions options) =>
        (JsonConverter)Activator.CreateInstance(typeof(OptionalConverter<>).MakeGenericType(type.GetGenericArguments()[0]))!;

    private sealed class OptionalConverter<T> : JsonConverter<Optional<T>>
    {
        public override Optional<T> Read(ref Utf8JsonReader reader, Type type, JsonSerializerOptions options) =>
            new(JsonSerializer.Deserialize<T>(ref reader, options), true);

        public override void Write(Utf8JsonWriter writer, Optional<T> value, JsonSerializerOptions options) =>
            JsonSerializer.Serialize(writer, value.Value, options);
    }
}
```

`ResponseHeaders.Created` sets `Location`, `ETag` and `Idempotent-Replayed` on creates.

**File: `src/TasksApi/Common/ResponseHeaders.cs`**
```csharp
namespace TasksApi.Common;

public static class ResponseHeaders
{
    // Sets Location and, for versioned resources, ETag; adds Idempotent-Replayed when the answer is a replay.
    public static void Created(HttpContext http, string path, int? version, bool replayed)
    {
        http.Response.Headers.Location = $"{http.Request.Scheme}://{http.Request.Host}{path}";
        if (version is { } v)
        {
            ETags.Set(http, v);
        }
        if (replayed)
        {
            http.Response.Headers["Idempotent-Replayed"] = "true";
        }
    }
}
```

### Step 11. Idempotency and safe search
`Idempotency.RunAsync` wraps every create. With an `Idempotency-Key` it writes a key row **inside the same transaction** as the new resource, so either both exist or neither does. A second request with the same key either waits for the first one's transaction (the primary key is taken) and then replays its stored answer, or answers 422 when the body differs.

**File: `src/TasksApi/Data/Idempotency.cs`**
```csharp
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Security;

namespace TasksApi.Data;

// Idempotency-Key support for the create operations. The key row is written inside the same transaction as the new
// resource, so either both exist or neither does. A second request with the same key waits on the first one's row,
// then finds the stored response and replays it.
public sealed class Idempotency(TasksDbContext db, CurrentUser user)
{
    public async Task<(T Value, bool Replayed)> RunAsync<T>(HttpContext http, string? key, object request,
        Func<Task<T>> create, CancellationToken ct)
    {
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        if (key is not null)
        {
            var hash = Hash(http, request);
            var stored = await ReserveAsync(key, hash, ct);
            if (stored is not null)
            {
                return (JsonSerializer.Deserialize<T>(stored, JsonSerializerOptions.Web)!, true);
            }
            var created = await create();
            var body = JsonSerializer.Serialize(created, JsonSerializerOptions.Web);
            await db.Database.ExecuteSqlAsync(
                $"UPDATE idempotency_keys SET status_code = 201, response_body = {body}::jsonb WHERE user_id = {user.Id} AND key = {key}",
                ct);
            await transaction.CommitAsync(ct);
            return (created, false);
        }
        var value = await create();
        await transaction.CommitAsync(ct);
        return (value, false);
    }

    // Returns the stored response body for a replay, or null when this request is the first one with the key.
    private async Task<string?> ReserveAsync(string key, string hash, CancellationToken ct)
    {
        if (key.Length is < 8 or > 128)
        {
            throw ProblemException.Unprocessable("The Idempotency-Key must be 8 to 128 characters long.");
        }
        // A key whose 24 hours are over counts as new: the upsert resets it.
        var reserved = await db.Database.ExecuteSqlAsync(
            $"""
             INSERT INTO idempotency_keys (user_id, key, request_hash) VALUES ({user.Id}, {key}, {hash})
             ON CONFLICT (user_id, key) DO UPDATE
                SET request_hash = EXCLUDED.request_hash, status_code = NULL, response_body = NULL,
                    created_at = now(), expires_at = now() + interval '24 hours'
              WHERE idempotency_keys.expires_at < now()
             """, ct);
        if (reserved == 1)
        {
            return null;
        }
        var row = await db.IdempotencyKeys.AsNoTracking().SingleAsync(k => k.UserId == user.Id && k.Key == key, ct);
        if (row.RequestHash != hash)
        {
            throw ProblemException.Unprocessable("The Idempotency-Key was already used with a different request.");
        }
        return row.ResponseBody ?? throw ProblemException.Conflict("A request with this Idempotency-Key is still being processed.");
    }

    private static string Hash(HttpContext http, object request)
    {
        var text = $"{http.Request.Method} {http.Request.Path}\n{JsonSerializer.Serialize(request, request.GetType(), JsonSerializerOptions.Web)}";
        return Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(text)));
    }
}
```

`Like` escapes `%`, `_` and the backslash, so a user who types `100%` searches for that text and not for "anything".

**File: `src/TasksApi/Data/Like.cs`**
```csharp
namespace TasksApi.Data;

// Builds LIKE patterns from user text. Without escaping, a user could type % or _ and match more than they should.
// Pass EscapeChar as the third argument of EF.Functions.ILike, or the database ignores the backslashes.
public static class Like
{
    public const string EscapeChar = "\\";

    private static string Escape(string text) =>
        text.Replace("\\", "\\\\").Replace("%", "\\%").Replace("_", "\\_");

    public static string Prefix(string text) => Escape(text) + "%";

    public static string Contains(string text) => "%" + Escape(text) + "%";
}
```

### Step 12. The stand-in identity and the current user
Create the folder `src/TasksApi/Security`. `CurrentUser` reads who is calling from the **claims** of the signed-in principal, using the claim names Keycloak uses (`sub`, `scope`, `realm_access`). The stand-in handler fills those claims for alice, so the rest of the code is already what chapter 3 needs.

**File: `src/TasksApi/Security/CurrentUser.cs`**
```csharp
using System.Security.Claims;
using System.Text.Json;

namespace TasksApi.Security;

// The caller, read from the claims of the access token (or of the stand-in identity in chapter 2).
public sealed class CurrentUser
{
    public Guid Id { get; private init; }
    public string Username { get; private init; } = "";
    public string? Email { get; private init; }
    public string? DisplayName { get; private init; }
    public IReadOnlySet<string> Roles { get; private init; } = new HashSet<string>();
    public IReadOnlySet<string> Scopes { get; private init; } = new HashSet<string>();

    public bool IsAdmin => Roles.Contains("admin");

    public static CurrentUser From(ClaimsPrincipal principal)
    {
        var subject = principal.FindFirstValue("sub");
        return new CurrentUser
        {
            Id = Guid.TryParse(subject, out var id) ? id : Guid.Empty,
            Username = principal.FindFirstValue("preferred_username") ?? subject ?? "",
            Email = principal.FindFirstValue("email"),
            DisplayName = principal.FindFirstValue("name"),
            Roles = RealmRoles(principal.FindFirstValue("realm_access")),
            Scopes = (principal.FindFirstValue("scope") ?? "").Split(' ', StringSplitOptions.RemoveEmptyEntries).ToHashSet(),
        };
    }

    // Keycloak puts realm roles in the claim realm_access, a JSON object: {"roles":["admin"]}.
    private static HashSet<string> RealmRoles(string? realmAccess)
    {
        var roles = new HashSet<string>();
        if (string.IsNullOrEmpty(realmAccess))
        {
            return roles;
        }
        using var document = JsonDocument.Parse(realmAccess);
        if (document.RootElement.TryGetProperty("roles", out var list) && list.ValueKind == JsonValueKind.Array)
        {
            foreach (var role in list.EnumerateArray())
            {
                if (role.GetString() is { } name)
                {
                    roles.Add(name);
                }
            }
        }
        return roles;
    }
}
```

**File: `src/TasksApi/Security/DevAuthenticationHandler.cs`**
```csharp
using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;

namespace TasksApi.Security;

// A stand-in for real sign-in, used only in chapter 2: every request is alice, the admin, holding all three scopes.
// Chapter 3 deletes this class and validates real Keycloak tokens instead.
public sealed class DevAuthenticationHandler(IOptionsMonitor<AuthenticationSchemeOptions> options, ILoggerFactory logger,
    UrlEncoder encoder) : AuthenticationHandler<AuthenticationSchemeOptions>(options, logger, encoder)
{
    public const string SchemeName = "Dev";

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        var identity = new ClaimsIdentity(
        [
            new Claim("sub", "a11ce000-0000-4000-8000-000000000001"),
            new Claim("preferred_username", "alice"),
            new Claim("email", "alice@tasksteams.test"),
            new Claim("name", "Alice Admin"),
            new Claim("scope", "openid tasks:read tasks:write tasks:admin"),
            new Claim("realm_access", """{"roles":["admin"]}""", "JSON"),
        ], SchemeName);
        var ticket = new AuthenticationTicket(new ClaimsPrincipal(identity), SchemeName);
        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}
```

### Step 13. Policies
A policy is a named rule an endpoint requires. Effective permission is the **intersection** of the token's scope and the user's role: `AdminOnly` needs the scope `tasks:admin` *and* the realm role `admin`.

**File: `src/TasksApi/Security/AccessPolicies.cs`**
```csharp
using Microsoft.AspNetCore.Authorization;

namespace TasksApi.Security;

// Names of the authorization policies. Effective permission is the intersection of the token's scope and the user's role.
public static class AccessPolicies
{
    public const string Read = "TasksRead";
    public const string Write = "TasksWrite";
    public const string AdminWrite = "AdminWrite";
    public const string AdminOnly = "AdminOnly";

    public static void Add(AuthorizationOptions options)
    {
        options.AddPolicy(Read, p => p.RequireAuthenticatedUser().AddRequirements(new TokenRequirement("tasks:read")));
        options.AddPolicy(Write, p => p.RequireAuthenticatedUser().AddRequirements(new TokenRequirement("tasks:write")));
        options.AddPolicy(AdminWrite,
            p => p.RequireAuthenticatedUser().AddRequirements(new TokenRequirement("tasks:write", "admin")));
        options.AddPolicy(AdminOnly,
            p => p.RequireAuthenticatedUser().AddRequirements(new TokenRequirement("tasks:admin", "admin")));
    }
}

public sealed record TokenRequirement(string Scope, string? Role = null) : IAuthorizationRequirement;

public sealed class TokenRequirementHandler : AuthorizationHandler<TokenRequirement>
{
    protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, TokenRequirement requirement)
    {
        var user = CurrentUser.From(context.User);
        if (!user.Scopes.Contains(requirement.Scope))
        {
            context.Fail(new AuthorizationFailureReason(this, $"The scope '{requirement.Scope}' is required."));
        }
        else if (requirement.Role is not null && !user.Roles.Contains(requirement.Role))
        {
            context.Fail(new AuthorizationFailureReason(this, $"The '{requirement.Role}' role is required."));
        }
        else
        {
            context.Succeed(requirement);
        }
        return Task.CompletedTask;
    }
}
```

### Step 14. Team access: 404 or 403
`TeamAccess` answers one question for every operation: may this caller see (and change) this team's objects? A user who is not a member gets **404**, as if the team did not exist, so nobody can probe ids; a member who lacks the lead role gets **403**; an admin passes both checks. It is a `scoped` service: one instance per request, created with the request's `DbContext` and `CurrentUser`.

**File: `src/TasksApi/Security/TeamAccess.cs`**
```csharp
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Data;

namespace TasksApi.Security;

public enum TeamLevel
{
    Member,
    Lead,
}

// Object-level authorization. A user who cannot see a team gets 404 for everything in it, so ids cannot be probed;
// a member who may see it but not change it gets 403. Admins may do everything.
public sealed class TeamAccess(TasksDbContext db, CurrentUser user)
{
    public async Task RequireTeamAsync(Guid teamId, TeamLevel level, CancellationToken ct, string what = "Team")
    {
        var found = await db.Teams
            .Where(t => t.Id == teamId)
            .Select(t => new { Role = t.Members.Where(m => m.UserId == user.Id).Select(m => m.Role).FirstOrDefault() })
            .SingleOrDefaultAsync(ct);
        if (found is null || (found.Role is null && !user.IsAdmin))
        {
            throw ProblemException.NotFound(what);
        }
        if (level == TeamLevel.Lead && !user.IsAdmin && found.Role != "lead")
        {
            throw ProblemException.Forbidden("Only a team lead or an admin can do this.");
        }
    }

    public async Task<Guid> RequireProjectAsync(Guid projectId, TeamLevel level, CancellationToken ct)
    {
        var teamId = await db.Projects.Where(p => p.Id == projectId).Select(p => (Guid?)p.TeamId).SingleOrDefaultAsync(ct)
                     ?? throw ProblemException.NotFound("Project");
        await RequireTeamAsync(teamId, level, ct, "Project");
        return teamId;
    }

    public async Task<Guid> RequireTaskAsync(Guid taskId, TeamLevel level, CancellationToken ct)
    {
        var teamId = await db.Tasks.Where(t => t.Id == taskId).Select(t => (Guid?)t.Project!.TeamId).SingleOrDefaultAsync(ct)
                     ?? throw ProblemException.NotFound("Task");
        await RequireTeamAsync(teamId, level, ct, "Task");
        return teamId;
    }

    // A task may only be given to someone who belongs to the project's team.
    public async Task EnsureAssigneeAsync(Guid teamId, Guid? assigneeId, CancellationToken ct)
    {
        if (assigneeId is { } id && !await db.TeamMembers.AnyAsync(m => m.TeamId == teamId && m.UserId == id, ct))
        {
            throw ProblemException.Unprocessable("The assignee is not a member of the project's team.");
        }
    }
}
```

### Step 15. User provisioning
The first time a signed-in user calls the API, their `users` row may not exist yet (a new Keycloak user). This middleware inserts it with `ON CONFLICT DO NOTHING` and remembers the id in memory, so the database is asked only once per user and process.

**File: `src/TasksApi/Security/UserProvisioningMiddleware.cs`**
```csharp
using System.Collections.Concurrent;
using Microsoft.EntityFrameworkCore;
using TasksApi.Data;

namespace TasksApi.Security;

// Creates the users row the first time a signed-in user calls the API (R-03). Rows made for the three seed users already exist.
public sealed class UserProvisioningMiddleware(RequestDelegate next)
{
    private static readonly ConcurrentDictionary<Guid, bool> Known = new();

    public async Task InvokeAsync(HttpContext context, TasksDbContext db, CurrentUser user)
    {
        if (context.User.Identity?.IsAuthenticated == true && user.Id != Guid.Empty && !Known.ContainsKey(user.Id))
        {
            var username = Truncate(user.Username, 100);
            var email = user.Email ?? $"{user.Id}@users.invalid";
            var displayName = Truncate(user.DisplayName ?? user.Username, 120);
            await db.Database.ExecuteSqlAsync(
                $"""
                 INSERT INTO users (id, username, email, display_name)
                 VALUES ({user.Id}, {username}, {email}, {displayName})
                 ON CONFLICT DO NOTHING
                 """, context.RequestAborted);
            Known[user.Id] = true;
        }
        await next(context);
    }

    private static string Truncate(string value, int max) => value.Length <= max ? value : value[..max];
}
```

### Step 16. Platform, teams and members endpoints
Create the folders `src/TasksApi/Features/Teams`, `Members`, `Projects`, `Tasks`, `Comments` and `Audit` next to `Platform`. Every endpoint follows the same shape: `Configure()` names the route and the policy, `HandleAsync` checks access, does the work, shapes the response.

`Health` now checks the database; a failing `SELECT 1` answers 503 with `"database":"down"`:

**File: `src/TasksApi/Features/Platform/HealthEndpoint.cs`**
```csharp
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Data;

namespace TasksApi.Features.Platform;

public sealed record HealthResponse(string Status, string Version, string Database);

// GET /health: liveness plus a database check. Public, so Docker and load balancers can call it without a token.
public sealed class HealthEndpoint(TasksDbContext db) : EndpointWithoutRequest<HealthResponse>
{
    public override void Configure()
    {
        Get("/health");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var up = true;
        try
        {
            await db.Database.ExecuteSqlAsync($"SELECT 1", ct);
        }
        catch (Exception) when (!ct.IsCancellationRequested)
        {
            up = false;
        }
        await Send.ResponseAsync(new HealthResponse(up ? "ok" : "degraded", "1.0.0", up ? "up" : "down"),
            up ? StatusCodes.Status200OK : StatusCodes.Status503ServiceUnavailable, ct);
    }
}
```

`Me` reads the caller's row and teams:

**File: `src/TasksApi/Features/Platform/MeEndpoint.cs`**
```csharp
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Platform;

// GET /v1/me: who is calling, with the roles and scopes of the token and the teams the user belongs to.
public sealed class MeEndpoint(TasksDbContext db, CurrentUser user) : EndpointWithoutRequest<MeDto>
{
    public override void Configure()
    {
        Get("/v1/me");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var row = await db.Users.AsNoTracking()
            .Where(u => u.Id == user.Id)
            .Select(u => new { u.Username, u.Email, u.DisplayName })
            .SingleAsync(ct);
        var teams = await db.TeamMembers.AsNoTracking()
            .Where(m => m.UserId == user.Id)
            .OrderBy(m => m.Team!.Name)
            .Select(m => new MeTeamDto(m.TeamId, m.Team!.Name, m.Role))
            .ToListAsync(ct);
        var roles = user.Roles.Where(role => role is "admin" or "member").Order().ToList();
        await Send.OkAsync(new MeDto(user.Id, row.Username, row.Email, row.DisplayName, roles, user.Scopes.Order().ToList(), teams), ct);
    }
}
```

`ListUsers` pages by id. Notice how `Like.EscapeChar` is passed to `ILike`: without it Npgsql sends `ESCAPE ''` and the backslashes would be treated as ordinary characters.

**File: `src/TasksApi/Features/Platform/ListUsersEndpoint.cs`**
```csharp
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Platform;

public sealed class ListUsersRequest
{
    public string? Q { get; set; }
    public int? Limit { get; set; }
    public string? Cursor { get; set; }
}

// GET /v1/users: find users, for example to add a team member. Ordered by id, so the cursor is just the last id.
public sealed class ListUsersEndpoint(TasksDbContext db) : Endpoint<ListUsersRequest, Paged<UserSummaryDto>>
{
    public override void Configure()
    {
        Get("/v1/users");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(ListUsersRequest req, CancellationToken ct)
    {
        var limit = Paging.CheckLimit(req.Limit);
        var query = db.Users.AsNoTracking();
        if (!string.IsNullOrWhiteSpace(req.Q))
        {
            var pattern = Like.Prefix(req.Q.Trim());
            query = query.Where(u => EF.Functions.ILike(u.Username, pattern, Like.EscapeChar)
                                     || EF.Functions.ILike(u.DisplayName, pattern, Like.EscapeChar));
        }
        if (req.Cursor is not null)
        {
            var after = Paging.ParseId(Paging.Decode(req.Cursor).Id);
            query = query.Where(u => u.Id.CompareTo(after) > 0);
        }
        var page = await Paging.ToPageAsync(query.OrderBy(u => u.Id).Select(Projections.ToUser), limit,
            u => Paging.Encode(null, u.Id.ToString()), ct);
        await Send.OkAsync(page, ct);
    }
}
```

Teams. `CreateTeam` calls the stored function inside `Idempotency.RunAsync`:

**File: `src/TasksApi/Features/Teams/CreateTeamEndpoint.cs`**
```csharp
using FastEndpoints;
using FluentValidation;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;
using Microsoft.EntityFrameworkCore;

namespace TasksApi.Features.Teams;

public sealed class CreateTeamRequest
{
    public string Name { get; set; } = "";
    public string? Description { get; set; }
    public Guid? LeadUserId { get; set; }

    [FromHeader("Idempotency-Key", IsRequired = false)]
    public string? IdempotencyKey { get; set; }
}

public sealed class CreateTeamValidator : Validator<CreateTeamRequest>
{
    public CreateTeamValidator()
    {
        RuleFor(x => x.Name)
            .Must(name => name.Trim().Length is >= 1 and <= 80)
            .WithMessage("must be between 1 and 80 characters");
        RuleFor(x => x.Description)
            .MaximumLength(500)
            .WithMessage("must be at most 500 characters");
    }
}

// POST /v1/teams (admin): the stored function create_team inserts the team and its first lead in one step.
public sealed class CreateTeamEndpoint(TasksDbContext db, CurrentUser user, Idempotency idempotency)
    : Endpoint<CreateTeamRequest, TeamDto>
{
    public override void Configure()
    {
        Post("/v1/teams");
        Policies(AccessPolicies.AdminWrite);
    }

    public override async Task HandleAsync(CreateTeamRequest req, CancellationToken ct)
    {
        var (team, replayed) = await idempotency.RunAsync(HttpContext, req.IdempotencyKey, req, async () =>
        {
            var created = await db.Teams
                .FromSql($"SELECT * FROM create_team({req.Name.Trim()}, {req.Description ?? ""}, {req.LeadUserId ?? user.Id}, {user.Id})")
                .AsNoTracking()
                .ToListAsync(ct);
            return await db.Teams.AsNoTracking().Where(t => t.Id == created[0].Id).Select(Projections.ToTeam).SingleAsync(ct);
        }, ct);
        ResponseHeaders.Created(HttpContext, $"/v1/teams/{team.Id}", team.Version, replayed);
        await Send.ResponseAsync(team, StatusCodes.Status201Created, ct);
    }
}
```

**File: `src/TasksApi/Features/Teams/ListTeamsEndpoint.cs`**
```csharp
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Teams;

public sealed class ListTeamsRequest
{
    public string? Q { get; set; }
    public string? Sort { get; set; }
    public int? Limit { get; set; }
    public string? Cursor { get; set; }
}

// GET /v1/teams: the caller's teams (admins see every team), filtered by name prefix and paged by cursor.
public sealed class ListTeamsEndpoint(TasksDbContext db, CurrentUser user) : Endpoint<ListTeamsRequest, Paged<TeamDto>>
{
    public override void Configure()
    {
        Get("/v1/teams");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(ListTeamsRequest req, CancellationToken ct)
    {
        var limit = Paging.CheckLimit(req.Limit);
        var descending = Paging.CheckSort(req.Sort) == "-createdAt";
        var query = db.Teams.AsNoTracking();
        if (!user.IsAdmin)
        {
            query = query.Where(t => t.Members.Any(m => m.UserId == user.Id));
        }
        if (!string.IsNullOrWhiteSpace(req.Q))
        {
            var pattern = Like.Prefix(req.Q.Trim());
            query = query.Where(t => EF.Functions.ILike(t.Name, pattern, Like.EscapeChar));
        }
        var ordered = query.AfterCreatedCursor(req.Cursor, descending).OrderByCreated(descending);
        var page = await Paging.ToPageAsync(ordered.Select(Projections.ToTeam), limit,
            t => Paging.CreatedCursor(t.CreatedAt, t.Id), ct);
        await Send.OkAsync(page, ct);
    }
}
```

**File: `src/TasksApi/Features/Teams/GetTeamEndpoint.cs`**
```csharp
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Teams;

// GET /v1/teams/{teamId}: a team the caller belongs to (or any team for an admin), with its ETag.
public sealed class GetTeamEndpoint(TasksDbContext db, TeamAccess access) : Endpoint<TeamIdRequest, TeamDto>
{
    public override void Configure()
    {
        Get("/v1/teams/{teamId}");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(TeamIdRequest req, CancellationToken ct)
    {
        await access.RequireTeamAsync(req.TeamId, TeamLevel.Member, ct);
        var team = await db.Teams.AsNoTracking().Where(t => t.Id == req.TeamId).Select(Projections.ToTeam).SingleAsync(ct);
        ETags.Set(HttpContext, team.Version);
        await Send.OkAsync(team, ct);
    }
}
```

`UpdateTeam` is the model for every PATCH: access check, the `If-Match` rules, a write transaction, read the row, compare versions (a clear 412 message), apply only the fields that were sent, `SaveChanges` (which repeats the version check inside the UPDATE), read the new DTO, commit.

**File: `src/TasksApi/Features/Teams/UpdateTeamEndpoint.cs`**
```csharp
using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Teams;

public sealed class UpdateTeamRequest
{
    public Guid TeamId { get; set; }

    [FromHeader("If-Match", IsRequired = false)]
    public string? IfMatch { get; set; }

    public Optional<string> Name { get; set; }
    public Optional<string> Description { get; set; }
}

public sealed class UpdateTeamValidator : Validator<UpdateTeamRequest>
{
    public UpdateTeamValidator()
    {
        RuleFor(x => x).Must(x => x.Name.IsSet || x.Description.IsSet)
            .WithMessage("send at least one of name and description");
        When(x => x.Name.IsSet, () => RuleFor(x => x.Name.Value)
            .Must(name => name is not null && name.Trim().Length is >= 1 and <= 80)
            .OverridePropertyName("Name").WithMessage("must be between 1 and 80 characters"));
        When(x => x.Description.IsSet, () => RuleFor(x => x.Description.Value)
            .Must(text => text is not null && text.Length <= 500)
            .OverridePropertyName("Description").WithMessage("must be at most 500 characters"));
    }
}

// PATCH /v1/teams/{teamId} (lead or admin): JSON Merge Patch guarded by If-Match.
public sealed class UpdateTeamEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access)
    : Endpoint<UpdateTeamRequest, TeamDto>
{
    public override void Configure()
    {
        Patch("/v1/teams/{teamId}");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(UpdateTeamRequest req, CancellationToken ct)
    {
        await access.RequireTeamAsync(req.TeamId, TeamLevel.Lead, ct);
        var expected = ETags.RequireIfMatch(req.IfMatch);
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        var team = await db.Teams.SingleAsync(t => t.Id == req.TeamId, ct);
        ETags.EnsureCurrent(team.Version, expected, "team");
        if (req.Name.IsSet)
        {
            team.Name = req.Name.Value!.Trim();
        }
        if (req.Description.IsSet)
        {
            team.Description = req.Description.Value!;
        }
        await db.SaveChangesAsync(ct);
        var updated = await db.Teams.AsNoTracking().Where(t => t.Id == req.TeamId).Select(Projections.ToTeam).SingleAsync(ct);
        await transaction.CommitAsync(ct);
        ETags.Set(HttpContext, updated.Version);
        await Send.OkAsync(updated, ct);
    }
}
```

**File: `src/TasksApi/Features/Teams/DeleteTeamEndpoint.cs`**
```csharp
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Teams;

// DELETE /v1/teams/{teamId} (admin): the database cascades to members, projects, tasks and comments.
public sealed class DeleteTeamEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access) : Endpoint<TeamIdRequest>
{
    public override void Configure()
    {
        Delete("/v1/teams/{teamId}");
        Policies(AccessPolicies.AdminOnly);
    }

    public override async Task HandleAsync(TeamIdRequest req, CancellationToken ct)
    {
        await access.RequireTeamAsync(req.TeamId, TeamLevel.Lead, ct);
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        await db.Teams.Where(t => t.Id == req.TeamId).ExecuteDeleteAsync(ct);
        await transaction.CommitAsync(ct);
        await Send.NoContentAsync(ct);
    }
}
```

Members:

**File: `src/TasksApi/Features/Members/ListMembersEndpoint.cs`**
```csharp
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Members;

// GET /v1/teams/{teamId}/members: ordered by join time, then user id; the cursor holds both.
public sealed class ListMembersEndpoint(TasksDbContext db, TeamAccess access) : Endpoint<PagedRequest, Paged<MemberDto>>
{
    public override void Configure()
    {
        Get("/v1/teams/{teamId}/members");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(PagedRequest req, CancellationToken ct)
    {
        var limit = Paging.CheckLimit(req.Limit);
        await access.RequireTeamAsync(req.TeamId, TeamLevel.Member, ct);
        var query = db.TeamMembers.AsNoTracking().Where(m => m.TeamId == req.TeamId);
        if (req.Cursor is not null)
        {
            var data = Paging.Decode(req.Cursor);
            var joined = Paging.ParseTime(data.Value);
            var userId = Paging.ParseId(data.Id);
            query = query.Where(m => m.JoinedAt > joined || (m.JoinedAt == joined && m.UserId.CompareTo(userId) > 0));
        }
        var page = await Paging.ToPageAsync(query.OrderBy(m => m.JoinedAt).ThenBy(m => m.UserId).Select(Projections.ToMember),
            limit, m => Paging.Encode(Paging.FormatTime(m.JoinedAt), m.UserId.ToString()), ct);
        await Send.OkAsync(page, ct);
    }
}
```

**File: `src/TasksApi/Features/Members/PutMemberEndpoint.cs`**
```csharp
using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Members;

public sealed class PutMemberRequest
{
    public Guid TeamId { get; set; }

    public Guid UserId { get; set; }

    public string Role { get; set; } = "";
}

public sealed class PutMemberValidator : Validator<PutMemberRequest>
{
    public PutMemberValidator()
    {
        RuleFor(x => x.Role).Must(role => role is "lead" or "member").WithMessage("must be lead or member");
    }
}

// PUT /v1/teams/{teamId}/members/{userId} (lead or admin): adds the member (201) or changes the role (200).
public sealed class PutMemberEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access)
    : Endpoint<PutMemberRequest, MemberDto>
{
    public override void Configure()
    {
        Put("/v1/teams/{teamId}/members/{userId}");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(PutMemberRequest req, CancellationToken ct)
    {
        await access.RequireTeamAsync(req.TeamId, TeamLevel.Lead, ct);
        if (!await db.Users.AnyAsync(u => u.Id == req.UserId, ct))
        {
            throw ProblemException.NotFound("User");
        }
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        var member = await db.TeamMembers.SingleOrDefaultAsync(m => m.TeamId == req.TeamId && m.UserId == req.UserId, ct);
        var added = member is null;
        if (member is null)
        {
            db.TeamMembers.Add(new TeamMember { TeamId = req.TeamId, UserId = req.UserId, Role = req.Role });
        }
        else
        {
            if (member.Role == "lead" && req.Role != "lead" && !await HasAnotherLeadAsync(req.TeamId, req.UserId, ct))
            {
                throw ProblemException.Conflict("A team needs at least one lead.", "last_lead");
            }
            member.Role = req.Role;
        }
        await db.SaveChangesAsync(ct);
        var dto = await db.TeamMembers.AsNoTracking()
            .Where(m => m.TeamId == req.TeamId && m.UserId == req.UserId)
            .Select(Projections.ToMember)
            .SingleAsync(ct);
        await transaction.CommitAsync(ct);
        await Send.ResponseAsync(dto, added ? StatusCodes.Status201Created : StatusCodes.Status200OK, ct);
    }

    private Task<bool> HasAnotherLeadAsync(Guid teamId, Guid userId, CancellationToken ct) =>
        db.TeamMembers.AnyAsync(m => m.TeamId == teamId && m.Role == "lead" && m.UserId != userId, ct);
}
```

**File: `src/TasksApi/Features/Members/RemoveMemberEndpoint.cs`**
```csharp
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Members;

public sealed class RemoveMemberRequest
{
    public Guid TeamId { get; set; }
    public Guid UserId { get; set; }
}

// DELETE /v1/teams/{teamId}/members/{userId} (lead or admin): the last lead of a team cannot be removed.
public sealed class RemoveMemberEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access)
    : Endpoint<RemoveMemberRequest>
{
    public override void Configure()
    {
        Delete("/v1/teams/{teamId}/members/{userId}");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(RemoveMemberRequest req, CancellationToken ct)
    {
        await access.RequireTeamAsync(req.TeamId, TeamLevel.Lead, ct);
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        var member = await db.TeamMembers.SingleOrDefaultAsync(m => m.TeamId == req.TeamId && m.UserId == req.UserId, ct)
                     ?? throw ProblemException.NotFound("Member");
        if (member.Role == "lead"
            && !await db.TeamMembers.AnyAsync(m => m.TeamId == req.TeamId && m.Role == "lead" && m.UserId != req.UserId, ct))
        {
            throw ProblemException.Conflict("A team needs at least one lead.", "last_lead");
        }
        db.TeamMembers.Remove(member);
        await db.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);
        await Send.NoContentAsync(ct);
    }
}
```

### Step 17. Projects and tasks endpoints
Projects:

**File: `src/TasksApi/Features/Projects/ListProjectsEndpoint.cs`**
```csharp
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Projects;

public sealed class ListProjectsRequest
{
    public Guid TeamId { get; set; }
    public bool Archived { get; set; }
    public string? Sort { get; set; }
    public int? Limit { get; set; }
    public string? Cursor { get; set; }
}

// GET /v1/teams/{teamId}/projects: archived projects are hidden unless archived=true.
public sealed class ListProjectsEndpoint(TasksDbContext db, TeamAccess access)
    : Endpoint<ListProjectsRequest, Paged<ProjectDto>>
{
    public override void Configure()
    {
        Get("/v1/teams/{teamId}/projects");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(ListProjectsRequest req, CancellationToken ct)
    {
        var limit = Paging.CheckLimit(req.Limit);
        var descending = Paging.CheckSort(req.Sort) == "-createdAt";
        await access.RequireTeamAsync(req.TeamId, TeamLevel.Member, ct);
        var ordered = db.Projects.AsNoTracking()
            .Where(p => p.TeamId == req.TeamId && p.Archived == req.Archived)
            .AfterCreatedCursor(req.Cursor, descending)
            .OrderByCreated(descending);
        var page = await Paging.ToPageAsync(ordered.Select(Projections.ToProject), limit,
            p => Paging.CreatedCursor(p.CreatedAt, p.Id), ct);
        await Send.OkAsync(page, ct);
    }
}
```

**File: `src/TasksApi/Features/Projects/CreateProjectEndpoint.cs`**
```csharp
using System.Text.RegularExpressions;
using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Projects;

public sealed class CreateProjectRequest
{
    public Guid TeamId { get; set; }

    public string Key { get; set; } = "";
    public string Name { get; set; } = "";
    public string? Description { get; set; }

    [FromHeader("Idempotency-Key", IsRequired = false)]
    public string? IdempotencyKey { get; set; }
}

public sealed partial class CreateProjectValidator : Validator<CreateProjectRequest>
{
    public CreateProjectValidator()
    {
        RuleFor(x => x.Key).Matches(KeyPattern()).WithMessage("must be 2 to 10 characters: A to Z first, then A to Z or 0 to 9");
        RuleFor(x => x.Name).Must(name => name.Trim().Length is >= 1 and <= 120).WithMessage("must be between 1 and 120 characters");
        RuleFor(x => x.Description).MaximumLength(2000).WithMessage("must be at most 2000 characters");
    }

    [GeneratedRegex("^[A-Z][A-Z0-9]{1,9}$")]
    private static partial Regex KeyPattern();
}

// POST /v1/teams/{teamId}/projects (lead or admin): a duplicate key in the team is a 409 from the unique constraint.
public sealed class CreateProjectEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access, Idempotency idempotency)
    : Endpoint<CreateProjectRequest, ProjectDto>
{
    public override void Configure()
    {
        Post("/v1/teams/{teamId}/projects");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(CreateProjectRequest req, CancellationToken ct)
    {
        await access.RequireTeamAsync(req.TeamId, TeamLevel.Lead, ct);
        var (project, replayed) = await idempotency.RunAsync(HttpContext, req.IdempotencyKey, req, async () =>
        {
            var entity = new Project
            {
                TeamId = req.TeamId,
                Key = req.Key,
                Name = req.Name.Trim(),
                Description = req.Description ?? "",
                CreatedBy = user.Id,
            };
            db.Projects.Add(entity);
            await db.SaveChangesAsync(ct);
            return await db.Projects.AsNoTracking().Where(p => p.Id == entity.Id).Select(Projections.ToProject).SingleAsync(ct);
        }, ct);
        ResponseHeaders.Created(HttpContext, $"/v1/projects/{project.Id}", project.Version, replayed);
        await Send.ResponseAsync(project, StatusCodes.Status201Created, ct);
    }
}
```

**File: `src/TasksApi/Features/Projects/GetProjectEndpoint.cs`**
```csharp
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Projects;

// GET /v1/projects/{projectId}: a project of one of the caller's teams, with its ETag.
public sealed class GetProjectEndpoint(TasksDbContext db, TeamAccess access) : Endpoint<ProjectIdRequest, ProjectDto>
{
    public override void Configure()
    {
        Get("/v1/projects/{projectId}");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(ProjectIdRequest req, CancellationToken ct)
    {
        await access.RequireProjectAsync(req.ProjectId, TeamLevel.Member, ct);
        var project = await db.Projects.AsNoTracking().Where(p => p.Id == req.ProjectId).Select(Projections.ToProject).SingleAsync(ct);
        ETags.Set(HttpContext, project.Version);
        await Send.OkAsync(project, ct);
    }
}
```

**File: `src/TasksApi/Features/Projects/UpdateProjectEndpoint.cs`**
```csharp
using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Projects;

public sealed class UpdateProjectRequest
{
    public Guid ProjectId { get; set; }

    [FromHeader("If-Match", IsRequired = false)]
    public string? IfMatch { get; set; }

    public Optional<string> Name { get; set; }
    public Optional<string> Description { get; set; }
    public Optional<bool?> Archived { get; set; }
}

public sealed class UpdateProjectValidator : Validator<UpdateProjectRequest>
{
    public UpdateProjectValidator()
    {
        RuleFor(x => x).Must(x => x.Name.IsSet || x.Description.IsSet || x.Archived.IsSet)
            .WithMessage("send at least one of name, description and archived");
        When(x => x.Name.IsSet, () => RuleFor(x => x.Name.Value)
            .Must(name => name is not null && name.Trim().Length is >= 1 and <= 120)
            .OverridePropertyName("Name").WithMessage("must be between 1 and 120 characters"));
        When(x => x.Description.IsSet, () => RuleFor(x => x.Description.Value)
            .Must(text => text is not null && text.Length <= 2000)
            .OverridePropertyName("Description").WithMessage("must be at most 2000 characters"));
        When(x => x.Archived.IsSet, () => RuleFor(x => x.Archived.Value)
            .NotNull().OverridePropertyName("Archived").WithMessage("must be true or false"));
    }
}

// PATCH /v1/projects/{projectId} (lead or admin): rename, describe, archive or restore; guarded by If-Match.
public sealed class UpdateProjectEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access)
    : Endpoint<UpdateProjectRequest, ProjectDto>
{
    public override void Configure()
    {
        Patch("/v1/projects/{projectId}");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(UpdateProjectRequest req, CancellationToken ct)
    {
        await access.RequireProjectAsync(req.ProjectId, TeamLevel.Lead, ct);
        var expected = ETags.RequireIfMatch(req.IfMatch);
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        var project = await db.Projects.SingleAsync(p => p.Id == req.ProjectId, ct);
        ETags.EnsureCurrent(project.Version, expected, "project");
        if (req.Name.IsSet)
        {
            project.Name = req.Name.Value!.Trim();
        }
        if (req.Description.IsSet)
        {
            project.Description = req.Description.Value!;
        }
        if (req.Archived.IsSet)
        {
            project.Archived = req.Archived.Value!.Value;
        }
        await db.SaveChangesAsync(ct);
        var updated = await db.Projects.AsNoTracking().Where(p => p.Id == req.ProjectId).Select(Projections.ToProject).SingleAsync(ct);
        await transaction.CommitAsync(ct);
        ETags.Set(HttpContext, updated.Version);
        await Send.OkAsync(updated, ct);
    }
}
```

**File: `src/TasksApi/Features/Projects/DeleteProjectEndpoint.cs`**
```csharp
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Projects;

// DELETE /v1/projects/{projectId} (lead or admin): the database cascades to the project's tasks and comments.
public sealed class DeleteProjectEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access) : Endpoint<ProjectIdRequest>
{
    public override void Configure()
    {
        Delete("/v1/projects/{projectId}");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(ProjectIdRequest req, CancellationToken ct)
    {
        await access.RequireProjectAsync(req.ProjectId, TeamLevel.Lead, ct);
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        await db.Projects.Where(p => p.Id == req.ProjectId).ExecuteDeleteAsync(ct);
        await transaction.CommitAsync(ct);
        await Send.NoContentAsync(ct);
    }
}
```

Tasks. The allowed values first (they mirror the `CHECK` constraints of the table):

**File: `src/TasksApi/Features/Tasks/TaskRules.cs`**
```csharp
namespace TasksApi.Features.Tasks;

// The allowed values; they match the CHECK constraints on the tasks table.
public static class TaskRules
{
    public static readonly string[] Statuses = ["todo", "in_progress", "blocked", "done", "cancelled"];
    public static readonly string[] Priorities = ["low", "medium", "high", "urgent"];

    public static bool IsTitle(string? title) => title is not null && title.Trim().Length is >= 1 and <= 200;

    public static bool IsDescription(string? text) => text is not null && text.Length <= 10000;
}
```

`ListTasks` is the biggest query: filters are added only when the parameter was sent, and the sort decides which "after the cursor" condition applies. Undated tasks sort last for `dueDate`, so that order needs its own cursor rule.

**File: `src/TasksApi/Features/Tasks/ListTasksEndpoint.cs`**
```csharp
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Tasks;

public sealed class ListTasksRequest
{
    public Guid ProjectId { get; set; }
    public List<string>? Status { get; set; }
    public List<string>? Priority { get; set; }
    public Guid? AssigneeId { get; set; }
    public DateOnly? DueBefore { get; set; }
    public DateOnly? DueAfter { get; set; }
    public string? Q { get; set; }
    public string? Sort { get; set; }
    public int? Limit { get; set; }
    public string? Cursor { get; set; }
}

// GET /v1/projects/{projectId}/tasks: filters, three sort orders and keyset paging.
public sealed class ListTasksEndpoint(TasksDbContext db, TeamAccess access) : Endpoint<ListTasksRequest, Paged<TaskDto>>
{
    public override void Configure()
    {
        Get("/v1/projects/{projectId}/tasks");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(ListTasksRequest req, CancellationToken ct)
    {
        var limit = Paging.CheckLimit(req.Limit);
        var sort = Paging.CheckSort(req.Sort, "dueDate");
        var statuses = req.Status ?? [];
        var priorities = req.Priority ?? [];
        if (statuses.Any(s => !TaskRules.Statuses.Contains(s)) || priorities.Any(p => !TaskRules.Priorities.Contains(p)))
        {
            throw ProblemException.BadRequest("status or priority is not one of the allowed values.");
        }
        await access.RequireProjectAsync(req.ProjectId, TeamLevel.Member, ct);

        var query = db.Tasks.AsNoTracking().Where(t => t.ProjectId == req.ProjectId);
        if (statuses.Count > 0)
        {
            query = query.Where(t => statuses.Contains(t.Status));
        }
        if (priorities.Count > 0)
        {
            query = query.Where(t => priorities.Contains(t.Priority));
        }
        if (req.AssigneeId is { } assignee)
        {
            query = query.Where(t => t.AssigneeId == assignee);
        }
        if (req.DueBefore is { } before)
        {
            query = query.Where(t => t.DueDate <= before);
        }
        if (req.DueAfter is { } after)
        {
            query = query.Where(t => t.DueDate >= after);
        }
        if (!string.IsNullOrWhiteSpace(req.Q))
        {
            var pattern = Like.Contains(req.Q.Trim());
            query = query.Where(t => EF.Functions.ILike(t.Title, pattern, Like.EscapeChar));
        }

        var page = sort == "dueDate"
            ? await Paging.ToPageAsync(AfterDueCursor(query, req.Cursor)
                    .OrderBy(t => t.DueDate == null).ThenBy(t => t.DueDate).ThenBy(t => t.Id)
                    .Select(Projections.ToTask), limit,
                t => Paging.Encode(t.DueDate?.ToString("O"), t.Id.ToString()), ct)
            : await Paging.ToPageAsync(query.AfterCreatedCursor(req.Cursor, sort == "-createdAt")
                    .OrderByCreated(sort == "-createdAt")
                    .Select(Projections.ToTask), limit,
                t => Paging.CreatedCursor(t.CreatedAt, t.Id), ct);
        await Send.OkAsync(page, ct);
    }

    // Order is due date ascending with undated tasks last, so "after" the last undated task means only undated tasks.
    private static IQueryable<TaskItem> AfterDueCursor(IQueryable<TaskItem> query, string? cursor)
    {
        if (cursor is null)
        {
            return query;
        }
        var data = Paging.Decode(cursor);
        var id = Paging.ParseId(data.Id);
        if (data.Value is null)
        {
            return query.Where(t => t.DueDate == null && t.Id.CompareTo(id) > 0);
        }
        if (!DateOnly.TryParseExact(data.Value, "O", out var due))
        {
            throw ProblemException.BadRequest("The cursor is not valid.");
        }
        return query.Where(t => t.DueDate == null || t.DueDate > due || (t.DueDate == due && t.Id.CompareTo(id) > 0));
    }
}
```

**File: `src/TasksApi/Features/Tasks/CreateTaskEndpoint.cs`**
```csharp
using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Tasks;

public sealed class CreateTaskRequest
{
    public Guid ProjectId { get; set; }

    public string Title { get; set; } = "";
    public string? Description { get; set; }
    public string? Priority { get; set; }
    public Guid? AssigneeId { get; set; }
    public DateOnly? DueDate { get; set; }

    [FromHeader("Idempotency-Key", IsRequired = false)]
    public string? IdempotencyKey { get; set; }
}

public sealed class CreateTaskValidator : Validator<CreateTaskRequest>
{
    public CreateTaskValidator()
    {
        RuleFor(x => x.Title).Must(TaskRules.IsTitle).WithMessage("must be between 1 and 200 characters");
        RuleFor(x => x.Description).Must(text => text is null || TaskRules.IsDescription(text))
            .WithMessage("must be at most 10000 characters");
        RuleFor(x => x.Priority).Must(p => p is null || TaskRules.Priorities.Contains(p))
            .WithMessage("must be low, medium, high or urgent");
    }
}

// POST /v1/projects/{projectId}/tasks (any member): an archived project accepts no new tasks.
public sealed class CreateTaskEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access, Idempotency idempotency)
    : Endpoint<CreateTaskRequest, TaskDto>
{
    public override void Configure()
    {
        Post("/v1/projects/{projectId}/tasks");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(CreateTaskRequest req, CancellationToken ct)
    {
        var teamId = await access.RequireProjectAsync(req.ProjectId, TeamLevel.Member, ct);
        if (await db.Projects.AnyAsync(p => p.Id == req.ProjectId && p.Archived, ct))
        {
            throw ProblemException.Conflict("The project is archived.", "project_archived");
        }
        await access.EnsureAssigneeAsync(teamId, req.AssigneeId, ct);
        var (task, replayed) = await idempotency.RunAsync(HttpContext, req.IdempotencyKey, req, async () =>
        {
            var entity = new TaskItem
            {
                ProjectId = req.ProjectId,
                Title = req.Title.Trim(),
                Description = req.Description ?? "",
                Priority = req.Priority ?? "medium",
                AssigneeId = req.AssigneeId,
                DueDate = req.DueDate,
                CreatedBy = user.Id,
            };
            db.Tasks.Add(entity);
            await db.SaveChangesAsync(ct);
            return await db.Tasks.AsNoTracking().Where(t => t.Id == entity.Id).Select(Projections.ToTask).SingleAsync(ct);
        }, ct);
        ResponseHeaders.Created(HttpContext, $"/v1/tasks/{task.Id}", task.Version, replayed);
        await Send.ResponseAsync(task, StatusCodes.Status201Created, ct);
    }
}
```

`GetTask` answers 304 with no body when the client's `If-None-Match` is the current ETag:

**File: `src/TasksApi/Features/Tasks/GetTaskEndpoint.cs`**
```csharp
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Tasks;

public sealed class GetTaskRequest
{
    public Guid TaskId { get; set; }

    [FromHeader("If-None-Match", IsRequired = false)]
    public string? IfNoneMatch { get; set; }
}

// GET /v1/tasks/{taskId}: answers 304 with no body when the client's If-None-Match is still the current ETag.
public sealed class GetTaskEndpoint(TasksDbContext db, TeamAccess access) : Endpoint<GetTaskRequest, TaskDto>
{
    public override void Configure()
    {
        Get("/v1/tasks/{taskId}");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(GetTaskRequest req, CancellationToken ct)
    {
        await access.RequireTaskAsync(req.TaskId, TeamLevel.Member, ct);
        var task = await db.Tasks.AsNoTracking().Where(t => t.Id == req.TaskId).Select(Projections.ToTask).SingleAsync(ct);
        ETags.Set(HttpContext, task.Version);
        if (ETags.IsNotModified(req.IfNoneMatch, task.Version))
        {
            HttpContext.Response.StatusCode = StatusCodes.Status304NotModified;
            await HttpContext.Response.CompleteAsync();
            return;
        }
        await Send.OkAsync(task, ct);
    }
}
```

**File: `src/TasksApi/Features/Tasks/UpdateTaskEndpoint.cs`**
```csharp
using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Tasks;

public sealed class UpdateTaskRequest
{
    public Guid TaskId { get; set; }

    [FromHeader("If-Match", IsRequired = false)]
    public string? IfMatch { get; set; }

    public Optional<string> Title { get; set; }
    public Optional<string> Description { get; set; }
    public Optional<string> Status { get; set; }
    public Optional<string> Priority { get; set; }
    public Optional<Guid?> AssigneeId { get; set; }
    public Optional<DateOnly?> DueDate { get; set; }
}

public sealed class UpdateTaskValidator : Validator<UpdateTaskRequest>
{
    public UpdateTaskValidator()
    {
        RuleFor(x => x)
            .Must(x => x.Title.IsSet || x.Description.IsSet || x.Status.IsSet || x.Priority.IsSet || x.AssigneeId.IsSet || x.DueDate.IsSet)
            .WithMessage("send at least one field to change");
        When(x => x.Title.IsSet, () => RuleFor(x => x.Title.Value).Must(TaskRules.IsTitle)
            .OverridePropertyName("Title").WithMessage("must be between 1 and 200 characters"));
        When(x => x.Description.IsSet, () => RuleFor(x => x.Description.Value).Must(TaskRules.IsDescription)
            .OverridePropertyName("Description").WithMessage("must be at most 10000 characters"));
        When(x => x.Status.IsSet, () => RuleFor(x => x.Status.Value)
            .Must(s => s is not null && TaskRules.Statuses.Contains(s))
            .OverridePropertyName("Status").WithMessage("must be todo, in_progress, blocked, done or cancelled"));
        When(x => x.Priority.IsSet, () => RuleFor(x => x.Priority.Value)
            .Must(p => p is not null && TaskRules.Priorities.Contains(p))
            .OverridePropertyName("Priority").WithMessage("must be low, medium, high or urgent"));
    }
}

// PATCH /v1/tasks/{taskId} (any member): JSON Merge Patch. A field that is absent stays; null clears assigneeId and dueDate.
// If-Match is checked twice: against the row we just read (a clear 412) and again by the UPDATE itself (version = expected).
public sealed class UpdateTaskEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access)
    : Endpoint<UpdateTaskRequest, TaskDto>
{
    public override void Configure()
    {
        Patch("/v1/tasks/{taskId}");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(UpdateTaskRequest req, CancellationToken ct)
    {
        var teamId = await access.RequireTaskAsync(req.TaskId, TeamLevel.Member, ct);
        var expected = ETags.RequireIfMatch(req.IfMatch);
        if (req.AssigneeId.IsSet)
        {
            await access.EnsureAssigneeAsync(teamId, req.AssigneeId.Value, ct);
        }
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        var task = await db.Tasks.SingleAsync(t => t.Id == req.TaskId, ct);
        ETags.EnsureCurrent(task.Version, expected, "task");
        if (req.Title.IsSet)
        {
            task.Title = req.Title.Value!.Trim();
        }
        if (req.Description.IsSet)
        {
            task.Description = req.Description.Value!;
        }
        if (req.Status.IsSet)
        {
            task.Status = req.Status.Value!;
        }
        if (req.Priority.IsSet)
        {
            task.Priority = req.Priority.Value!;
        }
        if (req.AssigneeId.IsSet)
        {
            task.AssigneeId = req.AssigneeId.Value;
        }
        if (req.DueDate.IsSet)
        {
            task.DueDate = req.DueDate.Value;
        }
        await db.SaveChangesAsync(ct);
        var updated = await db.Tasks.AsNoTracking().Where(t => t.Id == req.TaskId).Select(Projections.ToTask).SingleAsync(ct);
        await transaction.CommitAsync(ct);
        ETags.Set(HttpContext, updated.Version);
        await Send.OkAsync(updated, ct);
    }
}
```

**File: `src/TasksApi/Features/Tasks/DeleteTaskEndpoint.cs`**
```csharp
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Tasks;

public sealed class DeleteTaskRequest
{
    public Guid TaskId { get; set; }

    [FromHeader("If-Match", IsRequired = false)]
    public string? IfMatch { get; set; }
}

// DELETE /v1/tasks/{taskId} (lead or admin): If-Match is optional here; when sent, the DELETE itself checks the version.
public sealed class DeleteTaskEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access) : Endpoint<DeleteTaskRequest>
{
    public override void Configure()
    {
        Delete("/v1/tasks/{taskId}");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(DeleteTaskRequest req, CancellationToken ct)
    {
        await access.RequireTaskAsync(req.TaskId, TeamLevel.Lead, ct);
        int? expected = req.IfMatch is null ? null : ETags.RequireIfMatch(req.IfMatch);
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        var deleted = await db.Tasks
            .Where(t => t.Id == req.TaskId && (expected == null || t.Version == expected))
            .ExecuteDeleteAsync(ct);
        if (deleted == 0)
        {
            throw expected is null
                ? ProblemException.NotFound("Task")
                : ProblemException.PreconditionFailed("The task changed since you read it.");
        }
        await transaction.CommitAsync(ct);
        await Send.NoContentAsync(ct);
    }
}
```

`Complete` and `Reassign` call the stored functions with the version the client sent, so the check and the change happen under the function's row lock:

**File: `src/TasksApi/Features/Tasks/CompleteTaskEndpoint.cs`**
```csharp
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Tasks;

public sealed class CompleteTaskRequest
{
    public Guid TaskId { get; set; }

    [FromHeader("If-Match", IsRequired = false)]
    public string? IfMatch { get; set; }
}

// POST /v1/tasks/{taskId}/complete (any member): the stored function locks the row, checks the version and the rules.
public sealed class CompleteTaskEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access)
    : Endpoint<CompleteTaskRequest, TaskDto>
{
    public override void Configure()
    {
        Post("/v1/tasks/{taskId}/complete");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(CompleteTaskRequest req, CancellationToken ct)
    {
        await access.RequireTaskAsync(req.TaskId, TeamLevel.Member, ct);
        var expected = ETags.RequireIfMatch(req.IfMatch);
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        await db.Tasks
            .FromSql($"SELECT * FROM complete_task({req.TaskId}, {user.Id}, {expected})")
            .AsNoTracking()
            .ToListAsync(ct);
        var task = await db.Tasks.AsNoTracking().Where(t => t.Id == req.TaskId).Select(Projections.ToTask).SingleAsync(ct);
        await transaction.CommitAsync(ct);
        ETags.Set(HttpContext, task.Version);
        await Send.OkAsync(task, ct);
    }
}
```

**File: `src/TasksApi/Features/Tasks/ReassignTaskEndpoint.cs`**
```csharp
using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Tasks;

public sealed class ReassignTaskRequest
{
    public Guid TaskId { get; set; }

    [FromHeader("If-Match", IsRequired = false)]
    public string? IfMatch { get; set; }

    // Optional<T> so that a missing assigneeId (an error) differs from an explicit null (unassign).
    public Optional<Guid?> AssigneeId { get; set; }
}

public sealed class ReassignTaskValidator : Validator<ReassignTaskRequest>
{
    public ReassignTaskValidator()
    {
        RuleFor(x => x.AssigneeId.IsSet).Equal(true).OverridePropertyName("AssigneeId")
            .WithMessage("is required; send null to unassign");
    }
}

// POST /v1/tasks/{taskId}/reassign (lead or admin): the stored function also checks the new assignee is in the team.
public sealed class ReassignTaskEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access)
    : Endpoint<ReassignTaskRequest, TaskDto>
{
    public override void Configure()
    {
        Post("/v1/tasks/{taskId}/reassign");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(ReassignTaskRequest req, CancellationToken ct)
    {
        await access.RequireTaskAsync(req.TaskId, TeamLevel.Lead, ct);
        var expected = ETags.RequireIfMatch(req.IfMatch);
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        await db.Tasks
            .FromSql($"SELECT * FROM reassign_task({req.TaskId}, {req.AssigneeId.Value}, {user.Id}, {expected})")
            .AsNoTracking()
            .ToListAsync(ct);
        var task = await db.Tasks.AsNoTracking().Where(t => t.Id == req.TaskId).Select(Projections.ToTask).SingleAsync(ct);
        await transaction.CommitAsync(ct);
        ETags.Set(HttpContext, task.Version);
        await Send.OkAsync(task, ct);
    }
}
```

### Step 18. Comments and the audit log
**File: `src/TasksApi/Features/Comments/ListCommentsEndpoint.cs`**
```csharp
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Comments;

// GET /v1/tasks/{taskId}/comments: oldest first, so a conversation reads from the top.
public sealed class ListCommentsEndpoint(TasksDbContext db, TeamAccess access) : Endpoint<PagedRequest, Paged<CommentDto>>
{
    public override void Configure()
    {
        Get("/v1/tasks/{taskId}/comments");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(PagedRequest req, CancellationToken ct)
    {
        var limit = Paging.CheckLimit(req.Limit);
        await access.RequireTaskAsync(req.TaskId, TeamLevel.Member, ct);
        var ordered = db.Comments.AsNoTracking()
            .Where(c => c.TaskId == req.TaskId)
            .AfterCreatedCursor(req.Cursor, descending: false)
            .OrderByCreated(descending: false);
        var page = await Paging.ToPageAsync(ordered.Select(Projections.ToComment), limit,
            c => Paging.CreatedCursor(c.CreatedAt, c.Id), ct);
        await Send.OkAsync(page, ct);
    }
}
```

**File: `src/TasksApi/Features/Comments/CreateCommentEndpoint.cs`**
```csharp
using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Comments;

public sealed class CreateCommentRequest
{
    public Guid TaskId { get; set; }

    public string Body { get; set; } = "";

    [FromHeader("Idempotency-Key", IsRequired = false)]
    public string? IdempotencyKey { get; set; }
}

public sealed class CreateCommentValidator : Validator<CreateCommentRequest>
{
    public CreateCommentValidator()
    {
        RuleFor(x => x.Body).Must(body => body.Trim().Length is >= 1 and <= 2000)
            .WithMessage("must be between 1 and 2000 characters");
    }
}

// POST /v1/tasks/{taskId}/comments (any member): the author is always the caller.
public sealed class CreateCommentEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access, Idempotency idempotency)
    : Endpoint<CreateCommentRequest, CommentDto>
{
    public override void Configure()
    {
        Post("/v1/tasks/{taskId}/comments");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(CreateCommentRequest req, CancellationToken ct)
    {
        await access.RequireTaskAsync(req.TaskId, TeamLevel.Member, ct);
        var (comment, replayed) = await idempotency.RunAsync(HttpContext, req.IdempotencyKey, req, async () =>
        {
            var entity = new Comment { TaskId = req.TaskId, AuthorId = user.Id, Body = req.Body.Trim() };
            db.Comments.Add(entity);
            await db.SaveChangesAsync(ct);
            return await db.Comments.AsNoTracking().Where(c => c.Id == entity.Id).Select(Projections.ToComment).SingleAsync(ct);
        }, ct);
        ResponseHeaders.Created(HttpContext, $"/v1/comments/{comment.Id}", null, replayed);
        await Send.ResponseAsync(comment, StatusCodes.Status201Created, ct);
    }
}
```

**File: `src/TasksApi/Features/Comments/DeleteCommentEndpoint.cs`**
```csharp
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Comments;

// DELETE /v1/comments/{commentId}: the author may delete their own comment; otherwise a team lead or an admin is needed.
public sealed class DeleteCommentEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access) : Endpoint<CommentIdRequest>
{
    public override void Configure()
    {
        Delete("/v1/comments/{commentId}");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(CommentIdRequest req, CancellationToken ct)
    {
        var comment = await db.Comments.AsNoTracking()
            .Where(c => c.Id == req.CommentId)
            .Select(c => new { c.AuthorId, TeamId = c.TaskItem!.Project!.TeamId })
            .SingleOrDefaultAsync(ct) ?? throw ProblemException.NotFound("Comment");
        await access.RequireTeamAsync(comment.TeamId, comment.AuthorId == user.Id ? TeamLevel.Member : TeamLevel.Lead, ct, "Comment");
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        await db.Comments.Where(c => c.Id == req.CommentId).ExecuteDeleteAsync(ct);
        await transaction.CommitAsync(ct);
        await Send.NoContentAsync(ct);
    }
}
```

**File: `src/TasksApi/Features/Audit/ListAuditEndpoint.cs`**
```csharp
using System.Text.Json;
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Audit;

public sealed class ListAuditRequest
{
    public string? EntityType { get; set; }
    public Guid? EntityId { get; set; }
    public Guid? ActorId { get; set; }
    public DateTimeOffset? From { get; set; }
    public DateTimeOffset? To { get; set; }
    public int? Limit { get; set; }
    public string? Cursor { get; set; }
}

// GET /v1/audit-log (admin): newest first. The trigger on each table wrote these rows; the API never writes them.
public sealed class ListAuditEndpoint(TasksDbContext db) : Endpoint<ListAuditRequest, Paged<AuditEntryDto>>
{
    private static readonly string[] EntityTypes = ["team", "member", "project", "task", "comment"];

    public override void Configure()
    {
        Get("/v1/audit-log");
        Policies(AccessPolicies.AdminOnly);
    }

    public override async Task HandleAsync(ListAuditRequest req, CancellationToken ct)
    {
        var limit = Paging.CheckLimit(req.Limit);
        if (req.EntityType is not null && !EntityTypes.Contains(req.EntityType))
        {
            throw ProblemException.BadRequest("entityType is not one of the allowed values.");
        }
        var query = db.AuditLog.AsNoTracking().AsQueryable();
        if (req.EntityType is not null)
        {
            query = query.Where(a => a.EntityType == req.EntityType);
        }
        if (req.EntityId is { } entityId)
        {
            query = query.Where(a => a.EntityId == entityId);
        }
        if (req.ActorId is { } actorId)
        {
            query = query.Where(a => a.ActorId == actorId);
        }
        if (req.From is { } from)
        {
            query = query.Where(a => a.OccurredAt >= from);
        }
        if (req.To is { } to)
        {
            query = query.Where(a => a.OccurredAt < to);
        }
        if (req.Cursor is not null)
        {
            if (!long.TryParse(Paging.Decode(req.Cursor).Id, out var before))
            {
                throw ProblemException.BadRequest("The cursor is not valid.");
            }
            query = query.Where(a => a.Id < before);
        }
        var page = await Paging.ToPageAsync(query.OrderByDescending(a => a.Id), limit, a => Paging.Encode(null, a.Id.ToString()),
            a => new AuditEntryDto(a.Id, a.OccurredAt, a.ActorId, a.Action, a.EntityType, a.EntityId,
                JsonDocument.Parse(a.Details).RootElement.Clone()), ct);
        await Send.OkAsync(page, ct);
    }
}
```

### Step 19. `Program.cs`
Replace it. New: the `DbContext`, the scoped services, the stand-in authentication and the authorization policies, and in the pipeline `UseAuthentication`, `UseAuthorization` and the provisioning middleware, in that order.

**File: `src/TasksApi/Program.cs`**
```csharp
using System.Security.Claims;
using System.Text.Json.Serialization;
using FastEndpoints;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Data;
using TasksApi.Security;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<TasksDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("Default")));

builder.Services.AddHttpContextAccessor();
// FastEndpoints creates every endpoint once at startup, when there is no request yet, so the user may be missing here.
builder.Services.AddScoped(services =>
    CurrentUser.From(services.GetRequiredService<IHttpContextAccessor>().HttpContext?.User ?? new ClaimsPrincipal()));
builder.Services.AddScoped<TeamAccess>();
builder.Services.AddScoped<Idempotency>();

builder.Services.AddAuthentication(DevAuthenticationHandler.SchemeName)
    .AddScheme<AuthenticationSchemeOptions, DevAuthenticationHandler>(DevAuthenticationHandler.SchemeName, null);
builder.Services.AddAuthorization(AccessPolicies.Add);
builder.Services.AddSingleton<IAuthorizationHandler, TokenRequirementHandler>();

builder.Services.AddFastEndpoints();
builder.Services.AddExceptionHandler<ProblemExceptionHandler>();
builder.Services.AddProblemDetails();

var app = builder.Build();

app.UseExceptionHandler();
app.UseStatusCodePages(ProblemResponses.WriteStatusCodeAsync);
app.UseAuthentication();
app.UseAuthorization();
app.UseMiddleware<UserProvisioningMiddleware>();
app.UseFastEndpoints(config =>
{
    config.Errors.StatusCode = StatusCodes.Status422UnprocessableEntity;
    config.Errors.ContentType = "application/problem+json";
    config.Errors.ResponseBuilder = ProblemResponses.ValidationProblem;
    config.Serializer.Options.UnmappedMemberHandling = JsonUnmappedMemberHandling.Disallow;
});

app.Run();
```

### Step 20. A small helper to call the API
`scripts/call.py` prints the status line, the interesting headers and the JSON body, and builds the JSON from `key=value` pairs, so the lessons need no shell-specific quoting. It also signs in (`--as bob`) when you ask, which chapter 3 uses.

**File: `scripts/call.py`**
```python
#!/usr/bin/env python3
"""Call the Tasks and Teams API and print the answer. Standard library only.

  python scripts/call.py GET /v1/teams
  python scripts/call.py --as bob GET /v1/me
  python scripts/call.py POST /v1/teams name="Ops Team" --idempotency-key 11111111-aaaa
  python scripts/call.py PATCH /v1/tasks/<id> status=in_progress --if-match 1

key=value pairs make the JSON body; a value that is valid JSON (true, 5, null) keeps its type, anything else is text.
--body-file sends a file as the body instead. --as alice|bob|carol first asks Keycloak for an access token (fake local passwords, client tasks-smoke).
"""
import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

BASE_URL = os.environ.get("BASE_URL", "http://127.0.0.1:8000").rstrip("/")
KEYCLOAK_URL = os.environ.get("KEYCLOAK_URL", "http://127.0.0.1:8180")
PASSWORDS = {"alice": "alice-local-fake", "bob": "bob-local-fake", "carol": "carol-local-fake"}
SHOWN = ("ETag", "Location", "Idempotent-Replayed", "RateLimit-Limit", "RateLimit-Remaining", "RateLimit-Reset",
         "Retry-After", "WWW-Authenticate", "Content-Type")


def token_for(user, scope):
    form = urllib.parse.urlencode({"grant_type": "password", "client_id": "tasks-smoke", "username": user,
                                   "password": PASSWORDS[user], "scope": scope}).encode()
    request = urllib.request.Request(f"{KEYCLOAK_URL}/realms/tasksteams/protocol/openid-connect/token", data=form)
    with urllib.request.urlopen(request, timeout=15) as response:
        return json.load(response)["access_token"]


def parse_pair(pair):
    key, _, value = pair.partition("=")
    try:
        return key, json.loads(value)
    except json.JSONDecodeError:
        return key, value


def main():
    parser = argparse.ArgumentParser(description="Call the Tasks and Teams API.")
    parser.add_argument("method")
    parser.add_argument("path")
    parser.add_argument("fields", nargs="*", help="key=value pairs for the JSON body")
    parser.add_argument("--as", dest="user", choices=sorted(PASSWORDS), help="sign in as this user first")
    parser.add_argument("--token", help="send this text as the bearer token (to try a wrong one)")
    parser.add_argument("--scope", default="openid tasks:read tasks:write tasks:admin")
    parser.add_argument("--if-match", help="version number, sent as If-Match")
    parser.add_argument("--if-none-match", help="version number, sent as If-None-Match")
    parser.add_argument("--idempotency-key")
    parser.add_argument("--body-file", help="send this file as the JSON body")
    parser.add_argument("--pretty", action="store_true", help="indent the JSON answer")
    args = parser.parse_args()

    headers = {"Accept": "application/json"}
    if args.user:
        headers["Authorization"] = "Bearer " + token_for(args.user, args.scope)
    if args.token:
        headers["Authorization"] = "Bearer " + args.token
    if args.if_match:
        headers["If-Match"] = f'"{args.if_match}"'
    if args.if_none_match:
        headers["If-None-Match"] = f'"{args.if_none_match}"'
    if args.idempotency_key:
        headers["Idempotency-Key"] = args.idempotency_key
    data = None
    if args.fields:
        data = json.dumps(dict(parse_pair(pair) for pair in args.fields)).encode()
    if args.body_file:
        with open(args.body_file, "rb") as body_file:
            data = body_file.read()
    if data is not None:
        headers["Content-Type"] = "application/merge-patch+json" if args.method.upper() == "PATCH" else "application/json"

    request = urllib.request.Request(BASE_URL + args.path, data=data, headers=headers, method=args.method.upper())
    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            status, reason, received, body = response.status, response.reason, response.headers, response.read()
    except urllib.error.HTTPError as error:
        status, reason, received, body = error.code, error.reason, error.headers, error.read()

    print(f"HTTP {status} {reason}")
    for name in SHOWN:
        if received.get(name):
            print(f"{name}: {received[name]}")
    if body:
        print()
        try:
            print(json.dumps(json.loads(body), indent=2 if args.pretty else None, separators=None if args.pretty else (",", ":")))
        except json.JSONDecodeError:
            print(body.decode(errors="replace"))
    return 0 if status < 400 else 1


if __name__ == "__main__":
    sys.exit(main())
```

#### The `.gitignore` of this chapter (unchanged from chapter 01)
This chapter creates your own `.env` (Step 1), so the `.gitignore` matters now. It is the same file as in chapter 01; it is shown again so you can check your copy.

<details>
<summary><code>.gitignore</code> (same as chapter 01)</summary>

**File: `.gitignore`**
```text
bin/
obj/
.env
```

- `bin/`: compiled output (`dotnet build` writes it). It is rebuilt on every machine and would only bloat the repository.
- `obj/`: intermediate build files and restore data (`project.assets.json`) with machine-specific paths.
- `.env`: your local copy of the platform settings. Even with fake practice values, the habit matters: real secrets never go into Git.

`.git` itself is never listed: Git does not track its own folder.
</details>

## Run it
Postgres and Keycloak from step 2 are still running. Folder: the solution folder (`code`). Build the API; expected output (a first build also restores the packages and takes longer):
```powershell
cd src/TasksApi
dotnet build --nologo
```
```text
  Determining projects to restore...
  All projects are up-to-date for restore.
  TasksApi -> F:\...\code\src\TasksApi\bin\Debug\net11.0\TasksApi.dll

Build succeeded.
    0 Warning(s)
    0 Error(s)

Time Elapsed 00:00:00.50
```
Start it:
```powershell
dotnet run
```
Expected output of `dotnet run` (the endpoint count is the proof that all 27 operations are registered):
```text
info: FastEndpoints.StartupTimer[1]
      Registered 27 endpoints in 151 milliseconds.
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://127.0.0.1:8000
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
info: Microsoft.Hosting.Lifetime[0]
      Hosting environment: Production
info: Microsoft.Hosting.Lifetime[0]
      Content root path: F:\...\code\src\TasksApi
```
Open a second terminal in the solution folder and run the conformance script once:
```powershell
python scripts/conformance.py
```
Expected output (the ids in the three `create` lines differ on your machine). The three failures are the ones announced above:
```text
PASS  keycloak discovery (issuer matches, PKCE S256 offered)
PASS  token for alice (iss, aud tasks-api, sub, role admin, three scopes)
PASS  token for bob (role member only)
PASS  postgres reachable (127.0.0.1:5432 answers the Postgres protocol)
PASS  health (200, status ok, no token needed)
FAIL  me: header RateLimit-Limit missing or not a number
PASS  create team (201, Location and ETag set, team b276d26d-b9b1-4c8f-9801-8aa846a52117)
PASS  create project (201, project 01a2077c-5337-777a-975a-38e25000c9b6)
PASS  create task with Idempotency-Key (created once, replay returned the same task, other body gave 422)
PASS  get task with ETag (ETag "1", If-None-Match gave 304)
PASS  update with If-Match (200, version 1 -> 2)
PASS  stale If-Match gives 412 (stale If-Match gave 412, missing If-Match gave 428)
PASS  cursor pagination (2 + 1 tasks, no overlap, last page has nextCursor null)
FAIL  401 without token: expected HTTP 401, got 200: {"id":"a11ce000-0000-4000-8000-000000000001","username":"alice","email":"alice@tasksteams.test","displayName":"Alice Admin","roles":["admin"],"scopes":["openid","tasks:admin","tasks:read","tasks:write
FAIL  403 for member on admin route: expected HTTP 403, got 200: {"items":[{"id":28,"occurredAt":"2026-11-23T08:18:38.409286+00:00","actorId":"a11ce000-0000-4000-8000-000000000001","action":"create","entityType":"task","entityId":"01a2077c-54c9-789a-ab40-a5550c9413
PASS  problem details shape (422 with errors[/name], 404 with type, title and status)
PASS  audit log (task create and update are in the audit trail)
PASS  cleanup (team deleted, then 404)
15 passed, 3 failed
```
Now use the helper to look at what you built. Each block is one command and its real output (ids, times and trace ids differ on your machine; the lab checks the conformance lines, the health answer and the 404 problem, and your own run is the check for the rest). The API is still the stand-in alice, the admin.

**Health and the caller**
```powershell
python scripts/call.py GET /health
python scripts/call.py GET /v1/me
```
Expected output:
```text
HTTP 200 OK
Content-Type: application/json; charset=utf-8

{"status":"ok","version":"1.0.0","database":"up"}
HTTP 200 OK
Content-Type: application/json; charset=utf-8

{"id":"a11ce000-0000-4000-8000-000000000001","username":"alice","email":"alice@tasksteams.test","displayName":"Alice Admin","roles":["admin"],"scopes":["openid","tasks:admin","tasks:read","tasks:write"],"teams":[{"teamId":"7ea00000-0000-4000-8000-000000000001","name":"Platform Team","role":"lead"}]}
```
**Cursor pagination.** Ask for one team per page, then pass the `nextCursor` of the answer back unchanged:
```powershell
python scripts/call.py GET "/v1/teams?limit=1"
```
Expected output:
```text
HTTP 200 OK
Content-Type: application/json; charset=utf-8

{"items":[{"id":"7ea00000-0000-4000-8000-000000000002","name":"Mobile Team","description":"Builds the phone apps.","memberCount":2,"createdBy":"a11ce000-0000-4000-8000-000000000001","version":1,"createdAt":"2026-11-23T09:13:20.062642+00:00","updatedAt":"2026-11-23T09:13:20.062642+00:00"}],"page":{"limit":1,"nextCursor":"eyJ2YWx1ZSI6IjIwMjYtMTEtMjNUMDk6MTM6MjAuMDYyNjQyMFoiLCJpZCI6IjdlYTAwMDAwLTAwMDAtNDAwMC04MDAwLTAwMDAwMDAwMDAwMiJ9"}}
```
```powershell
python scripts/call.py GET "/v1/teams?limit=1&cursor=eyJ2YWx1ZSI6IjIwMjYtMTEtMjNUMDk6MTM6MjAuMDYyNjQyMFoiLCJpZCI6IjdlYTAwMDAwLTAwMDAtNDAwMC04MDAwLTAwMDAwMDAwMDAwMiJ9"
```
Expected output (the last page: `nextCursor` is `null`):
```text
HTTP 200 OK
Content-Type: application/json; charset=utf-8

{"items":[{"id":"7ea00000-0000-4000-8000-000000000001","name":"Platform Team","description":"Builds and runs the shared platform.","memberCount":3,"createdBy":"a11ce000-0000-4000-8000-000000000001","version":1,"createdAt":"2026-11-23T09:13:20.062642+00:00","updatedAt":"2026-11-23T09:13:20.062642+00:00"}],"page":{"limit":1,"nextCursor":null}}
```
The cursor is base64url text of `{"value":"<createdAt of the last team>","id":"<its id>"}`: paste it into any base64 decoder to see. Clients must never build or read it.

**Create a team, twice.** The key makes the second call a replay: same status, same body, plus the header `Idempotent-Replayed: true`. The same key with another body is refused with 422.
```powershell
python scripts/call.py POST /v1/teams name="Ops Team" description="Runs the servers." --idempotency-key 11111111-aaaa
python scripts/call.py POST /v1/teams name="Ops Team" description="Runs the servers." --idempotency-key 11111111-aaaa
python scripts/call.py POST /v1/teams name="Another Team" --idempotency-key 11111111-aaaa
python scripts/call.py POST /v1/teams name="ops team"
```
Expected output (first call; the second is identical plus `Idempotent-Replayed: true`):
```text
HTTP 201 Created
ETag: "1"
Location: http://127.0.0.1:8000/v1/teams/cf252758-ca78-495b-b27e-6cb0e2fb2e45
Content-Type: application/json; charset=utf-8

{"id":"cf252758-ca78-495b-b27e-6cb0e2fb2e45","name":"Ops Team","description":"Runs the servers.","memberCount":1,"createdBy":"a11ce000-0000-4000-8000-000000000001","version":1,"createdAt":"2026-11-23T09:13:27.141649+00:00","updatedAt":"2026-11-23T09:13:27.141649+00:00"}
```
```text
HTTP 201 Created
ETag: "1"
Location: http://127.0.0.1:8000/v1/teams/cf252758-ca78-495b-b27e-6cb0e2fb2e45
Idempotent-Replayed: true
Content-Type: application/json; charset=utf-8

{"id":"cf252758-ca78-495b-b27e-6cb0e2fb2e45","name":"Ops Team","description":"Runs the servers.","memberCount":1,"createdBy":"a11ce000-0000-4000-8000-000000000001","version":1,"createdAt":"2026-11-23T09:13:27.141649+00:00","updatedAt":"2026-11-23T09:13:27.141649+00:00"}
```
Expected output of the third call (same key, other body) and the fourth (a name that already exists; the database's unique index is on `lower(name)`):
```text
HTTP 422 Unprocessable Entity
Content-Type: application/problem+json

{"type":"https://code101.example/problems/validation-error","title":"Validation failed","status":422,"detail":"The Idempotency-Key was already used with a different request.","instance":"/v1/teams","traceId":"17679aedebad104c464a8f3851d5b334"}
```
```text
HTTP 409 Conflict
Content-Type: application/problem+json

{"type":"https://code101.example/problems/conflict","title":"Conflict","status":409,"detail":"A resource with the same name or key already exists.","instance":"/v1/teams","traceId":"23a729f06d78e307d283c376d2fe77ce"}
```
**ETag and `If-Match`.** Use the id of the team you created. A change without `If-Match` is refused (428), a change with a wrong version is refused (412), the right version works and returns the next ETag:
```powershell
python scripts/call.py PATCH /v1/teams/cf252758-ca78-495b-b27e-6cb0e2fb2e45 description="New text"
python scripts/call.py PATCH /v1/teams/cf252758-ca78-495b-b27e-6cb0e2fb2e45 description="New text" --if-match 9
python scripts/call.py PATCH /v1/teams/cf252758-ca78-495b-b27e-6cb0e2fb2e45 description="New text" --if-match 1
```
Expected output (one block per call):
```text
HTTP 428 Precondition Required
Content-Type: application/problem+json

{"type":"https://code101.example/problems/precondition-required","title":"Precondition required","status":428,"detail":"The If-Match header is required for this request.","instance":"/v1/teams/cf252758-ca78-495b-b27e-6cb0e2fb2e45","traceId":"e916642258b629cf458fbb8c2f93d318"}
```
```text
HTTP 412 Precondition Failed
Content-Type: application/problem+json

{"type":"https://code101.example/problems/precondition-failed","title":"Precondition failed","status":412,"detail":"The team changed since you read it (current version 1).","instance":"/v1/teams/cf252758-ca78-495b-b27e-6cb0e2fb2e45","traceId":"907b2b34a95caa38f63e0c16b74583d8"}
```
```text
HTTP 200 OK
ETag: "2"
Content-Type: application/json; charset=utf-8

{"id":"cf252758-ca78-495b-b27e-6cb0e2fb2e45","name":"Ops Team","description":"New text","memberCount":1,"createdBy":"a11ce000-0000-4000-8000-000000000001","version":2,"createdAt":"2026-11-23T09:13:27.141649+00:00","updatedAt":"2026-11-23T09:13:28.15269+00:00"}
```
**Filters, `If-None-Match`, and the stored functions.**
```powershell
python scripts/call.py GET "/v1/projects/9a000000-0000-4000-8000-000000000001/tasks?status=todo&status=blocked&limit=5"
python scripts/call.py GET /v1/tasks/7a500000-0000-4000-8000-000000000004 --if-none-match 1
python scripts/call.py POST /v1/tasks/7a500000-0000-4000-8000-000000000004/complete --if-match 7
python scripts/call.py POST /v1/tasks/7a500000-0000-4000-8000-000000000004/complete --if-match 1
```
Expected output (the first call returns two tasks, one `blocked` and one `todo`; shown shortened to the first answer line):
```text
HTTP 200 OK
Content-Type: application/json; charset=utf-8

{"items":[{"id":"7a500000-0000-4000-8000-000000000005","projectId":"9a000000-0000-4000-8000-000000000001","title":"Add rate limiting","description":"RateLimit headers and 429 responses.","status":"blocked","priority":"medium","assigneeId":"b0b00000-0000-4000-8000-000000000002","dueDate":null,"completedAt":null,"createdBy":"a11ce000-0000-4000-8000-000000000001","version":1,"createdAt":"2026-11-23T09:13:20.073364+00:00","updatedAt":"2026-11-23T09:13:20.073364+00:00"},{"id":"7a500000-0000-4000-8000-000000000004","projectId":"9a000000-0000-4000-8000-000000000001","title":"Run the conformance script","description":"All checks green on every backend.","status":"todo","priority":"medium","assigneeId":null,"dueDate":"2027-02-19","completedAt":null,"createdBy":"b0b00000-0000-4000-8000-000000000002","version":1,"createdAt":"2026-11-23T09:13:20.073364+00:00","updatedAt":"2026-11-23T09:13:20.073364+00:00"}],"page":{"limit":5,"nextCursor":null}}
```
The second call (the client already holds version 1) is answered without a body:
```text
HTTP 304 Not Modified
ETag: "1"
```
The third call carries a stale version; the stored function `complete_task` raises `TS412` and the API turns it into a 412. The fourth completes the task:
```text
HTTP 412 Precondition Failed
Content-Type: application/problem+json

{"type":"https://code101.example/problems/precondition-failed","title":"Precondition failed","status":412,"detail":"task changed (current version 1)","instance":"/v1/tasks/7a500000-0000-4000-8000-000000000004/complete","traceId":"e8cc5c47f39fb63571c40f45261351a5"}
```
```text
HTTP 200 OK
ETag: "2"
Content-Type: application/json; charset=utf-8

{"id":"7a500000-0000-4000-8000-000000000004","projectId":"9a000000-0000-4000-8000-000000000001","title":"Run the conformance script","description":"All checks green on every backend.","status":"done","priority":"medium","assigneeId":null,"dueDate":"2027-02-19","completedAt":"2026-11-23T09:13:29.134739+00:00","createdBy":"b0b00000-0000-4000-8000-000000000002","version":2,"createdAt":"2026-11-23T09:13:20.073364+00:00","updatedAt":"2026-11-23T09:13:29.134739+00:00"}
```
The `completedAt` value was written by the database trigger, and the audit trigger recorded alice as the actor because `BeginWriteAsync` set `app.current_user_id` first:
```powershell
python scripts/call.py GET "/v1/audit-log?entityType=task&limit=2"
```
Expected output (two entries; yours differ in ids and times):
```text
HTTP 200 OK
Content-Type: application/json; charset=utf-8

{"items":[{"id":26,"occurredAt":"2026-11-23T09:13:29.472075+00:00","actorId":"a11ce000-0000-4000-8000-000000000001","action":"update","entityType":"task","entityId":"7a500000-0000-4000-8000-000000000005","details":{"assignee_id":"ca401000-0000-4000-8000-000000000003"}},{"id":25,"occurredAt":"2026-11-23T09:13:29.134739+00:00","actorId":"a11ce000-0000-4000-8000-000000000001","action":"update","entityType":"task","entityId":"7a500000-0000-4000-8000-000000000004","details":{"status":"done","completed_at":"2026-11-23T09:13:29.134739+00:00"}}],"page":{"limit":2,"nextCursor":"eyJ2YWx1ZSI6bnVsbCwiaWQiOiIyNSJ9"}}
```
**Not found and bad input.**
```powershell
python scripts/call.py GET /v1/teams/7ea00000-0000-4000-8000-0000000000ff
python scripts/call.py GET /v1/teams/not-a-guid
python scripts/call.py GET "/v1/teams?limit=500"
```
Expected output:
```text
HTTP 404 Not Found
Content-Type: application/problem+json

{"type":"https://code101.example/problems/not-found","title":"Not found","status":404,"detail":"Team was not found.","instance":"/v1/teams/7ea00000-0000-4000-8000-0000000000ff","traceId":"9eb9da32638ea2ce2d95a2b7b7ee6f36"}
```
```text
HTTP 400 Bad Request
Content-Type: application/problem+json; charset=utf-8

{"type":"https://code101.example/problems/bad-request","title":"Bad request","status":400,"detail":"The request could not be read: the JSON is malformed, or a field, path value or query value is unknown or has the wrong type.","instance":"/v1/teams/not-a-guid","traceId":"9224588b00ac953f4c142553c346a00c","errors":[{"pointer":"/teamId","detail":"is unknown or has the wrong type"}]}
```
```text
HTTP 400 Bad Request
Content-Type: application/problem+json

{"type":"https://code101.example/problems/bad-request","title":"Bad request","status":400,"detail":"limit must be between 1 and 100.","instance":"/v1/teams","traceId":"82f6a9b28385ad48f7d008c87542d40b"}
```
Finally delete the team you made (204), and again (404, it is gone):
```powershell
python scripts/call.py DELETE /v1/teams/cf252758-ca78-495b-b27e-6cb0e2fb2e45
python scripts/call.py DELETE /v1/teams/cf252758-ca78-495b-b27e-6cb0e2fb2e45
```
Expected output:
```text
HTTP 204 No Content
```
```text
HTTP 404 Not Found
Content-Type: application/problem+json

{"type":"https://code101.example/problems/not-found","title":"Not found","status":404,"detail":"Team was not found.","instance":"/v1/teams/cf252758-ca78-495b-b27e-6cb0e2fb2e45","traceId":"e012424b480e7a551fc6b8ece317931c"}
```
**See the SQL.** EF Core logs every command at the level `Information` in the category `Microsoft.EntityFrameworkCore.Database.Command`. Stop the API (Ctrl+C), turn that category on for one run, repeat the `PATCH` with the right version, the `complete` call and a team create, and read the log. In PowerShell:
```powershell
${env:Logging__LogLevel__Microsoft.EntityFrameworkCore.Database.Command} = "Information"
dotnet run
```
On macOS and Linux: `Logging__LogLevel__Microsoft.EntityFrameworkCore.Database.Command=Information dotnet run`. Expected log lines (shortened to the SQL; the parameter lists are left out):
```text
SELECT set_config('app.current_user_id', @p0, true)
SELECT * FROM create_team(@p0, @p1, @p2, @p3)
UPDATE teams SET description = @p0
WHERE id = @p1 AND version = @p2
RETURNING updated_at, version;
SELECT * FROM complete_task(@p0, @p1, @p2)
INSERT INTO idempotency_keys (user_id, key, request_hash) VALUES (@p0, @p1, @p2)
```
The `UPDATE` is the heart of optimistic concurrency: `AND version = @p2` makes the database refuse the change if anybody changed the row after we read it, and `RETURNING updated_at, version` brings back the two columns the triggers changed. Unset the variable afterwards (`Remove-Item env:Logging__LogLevel__Microsoft.EntityFrameworkCore.Database.Command`).

When you are done, stop the API with Ctrl+C and remove the stack:
```powershell
docker compose -p bdn down -v --remove-orphans
```
Expected output ends with:
```text
 Volume bdn_pg_data Removed
 Network tasksteams-net Removed
```

## How it works
Follow `PATCH /v1/tasks/{id}` with `If-Match: "1"` through the code, then the other ideas of the chapter.

1. **Authorization first.** The policy `Write` (scope `tasks:write`) passed in the pipeline. `UpdateTaskEndpoint` calls `access.RequireTaskAsync`: one query finds the task's team, `RequireTeamAsync` answers 404 for a non-member and 403 for the wrong team level. Only then does the code reveal anything about the task (OWASP API1).
2. **Preconditions.** `ETags.RequireIfMatch` turns `"1"` into the number 1, or throws 428 (header missing) or 400 (not an ETag).
3. **One write transaction.** `db.BeginWriteAsync(user.Id)` begins a transaction and runs `SELECT set_config('app.current_user_id', <id>, true)`. The third argument `true` limits the setting to this transaction, so a pooled connection never carries one request's user into the next. The audit trigger `audit_row_change` reads that setting and writes the actor into `audit_log`.
4. **Read, compare, apply.** The task is loaded as a tracked entity. `ETags.EnsureCurrent` compares the loaded version with the one the client sent: a mismatch is a clear 412 with the current version. Then only the fields that were in the JSON (`IsSet`) are copied onto the entity.
5. **Optimistic concurrency, atomically.** `SaveChangesAsync` sends `UPDATE tasks SET ... WHERE id = @p AND version = @expected RETURNING updated_at, version`. Between step 4 and step 5 another request could have changed the row; then the `WHERE` matches no row, EF Core throws `DbUpdateConcurrencyException`, and `DbErrors` turns it into the same 412. The trigger `bump_version` set `version` to 2, `set_updated_at` and `sync_completed_at` did their work, and the audit trigger wrote the row; EF Core read the generated values back from `RETURNING`.
6. **Read model after the write.** The endpoint queries the DTO with the projection (still inside the transaction), commits, sets `ETag: "2"` and answers 200.

The other ideas:

| Idea | How it is done here | Why |
|------|---------------------|-----|
| Database first | `db/schema.sql` owns the schema; the entities only map to it; no `dotnet ef migrations` | EF migrations create tables from the model. Here the tables, triggers, functions and grants already exist and are shared by four backends; a migration of ours would fight them. A schema change is a numbered SQL file in the platform capstone |
| EF Core versus raw SQL | EF for reads and simple writes; `FromSql` for `create_team`, `complete_task`, `reassign_task`; `ExecuteSql` for `set_config` and the idempotency upsert | The functions hold atomic rules (row lock, version check, membership check) that must exist once. `FromSql($"... {value}")` turns each `{value}` into a **parameter**, never into text, so it is safe from SQL injection (only `FromSqlRaw` with string concatenation is not) |
| Stored function errors | The function raises `TS404`, `TS409`, `TS412`, `TS422`; `DbErrors` reads `PostgresException.SqlState` | One mapping table for every backend, written in the platform TDD |
| 404 versus 403 | `TeamAccess` | A 403 tells an outsider "this id exists"; a 404 does not |
| Projections | `Expression<Func<Entity, Dto>>` with `Select` | One lean SELECT; no change tracking for reads (`AsNoTracking`) |
| Keyset paging | `WHERE (created_at, id) is after the cursor ORDER BY created_at, id LIMIT n + 1` | Fast on the `(created_at, id)` index and stable when rows are inserted while paging; offset paging skips or repeats rows |
| Merge patch | `Optional<T>` fields | `{"assigneeId": null}` clears the assignee; `{}` changes nothing; a plain nullable cannot tell them apart |
| Idempotency | key row inside the create transaction | The replay returns the stored response; two simultaneous requests with the same key serialize on the primary key |
| `LIKE` search | `Like.Contains` escapes `%`, `_`, `\`; `ILike(..., "\\")` | Otherwise user text acts as a pattern |

Unchanged on purpose: `Common/ProblemException.cs`, `Common/ProblemResponses.cs`, `Contracts/TeamDto.cs` and `Contracts/MeDto.cs` are exactly as in chapter 01 and are not repeated here; the lesson checker skips them.

## Try it
Add `GET /v1/teams/{teamId}/task-stats`, which answers how many tasks the team has in each status, for example `{"byStatus":{"blocked":1,"done":2,"in_progress":1,"todo":2}}`, using one `GROUP BY` query. The starter is an endpoint whose methods are empty; the solution is the finished file.

1. Copy `exercise/starter/src/TasksApi/Features/Teams/TeamStatsEndpoint.cs` into your `Features/Teams` folder and follow the TODO comment.
2. Restart the API and call `python scripts/call.py GET /v1/teams/7ea00000-0000-4000-8000-000000000001/task-stats`. The log must say `Registered 28 endpoints`.

Starter:

**File: `exercise/starter/src/TasksApi/Features/Teams/TeamStatsEndpoint.cs`**
```csharp
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Teams;

public sealed record TeamStatsResponse(IReadOnlyDictionary<string, int> ByStatus);

// TODO: GET /v1/teams/{teamId}/task-stats answers how many tasks the team has in each status,
// for example {"byStatus":{"todo":2,"done":1}}.
//   1. Configure(): Get the route above and require the Read policy (AccessPolicies.Read).
//   2. HandleAsync(): call access.RequireTeamAsync(req.TeamId, TeamLevel.Member, ct) first, so a non-member gets 404.
//   3. Query db.Tasks (AsNoTracking) for tasks whose Project.TeamId is req.TeamId, GroupBy Status,
//      Select the key and g.Count(), and ToListAsync(ct).
//   4. Send the rows as a dictionary with Send.OkAsync.
public sealed class TeamStatsEndpoint(TasksDbContext db, TeamAccess access) : Endpoint<TeamIdRequest, TeamStatsResponse>
{
    public override void Configure()
    {
    }

    public override Task HandleAsync(TeamIdRequest req, CancellationToken ct) => Task.CompletedTask;
}
```

<details><summary>Solution</summary>

**File: `exercise/solution/src/TasksApi/Features/Teams/TeamStatsEndpoint.cs`**
```csharp
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Teams;

public sealed record TeamStatsResponse(IReadOnlyDictionary<string, int> ByStatus);

// GET /v1/teams/{teamId}/task-stats: one GROUP BY query, so the counting happens in the database.
public sealed class TeamStatsEndpoint(TasksDbContext db, TeamAccess access) : Endpoint<TeamIdRequest, TeamStatsResponse>
{
    public override void Configure()
    {
        Get("/v1/teams/{teamId}/task-stats");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(TeamIdRequest req, CancellationToken ct)
    {
        await access.RequireTeamAsync(req.TeamId, TeamLevel.Member, ct);
        var rows = await db.Tasks.AsNoTracking()
            .Where(t => t.Project!.TeamId == req.TeamId)
            .GroupBy(t => t.Status)
            .Select(g => new { Status = g.Key, Count = g.Count() })
            .ToListAsync(ct);
        await Send.OkAsync(new TeamStatsResponse(rows.ToDictionary(r => r.Status, r => r.Count)), ct);
    }
}
```

`GroupBy(t => t.Status)` followed by `Select(g => new { g.Key, Count = g.Count() })` is translated to `SELECT status, count(*) ... GROUP BY status`: the counting happens in the database, not in memory. The access check comes first so a non-member gets 404. On the seed data the answer for the Platform Team is `{"byStatus":{"blocked":1,"done":2,"in_progress":1,"todo":2}}`.

</details>

## Check yourself
1. What exactly makes `If-Match` safe against two people changing the same task at once? <details><summary>Answer</summary>The `UPDATE` carries `WHERE version = @expected`. Whoever commits first bumps the version, so the second `UPDATE` matches no row and fails with a concurrency exception, which becomes 412. The check and the change are one atomic statement, unlike "read, compare in C#, write".</details>
2. Why does `set_config('app.current_user_id', ..., true)` use `true`? <details><summary>Answer</summary>It makes the setting local to the current transaction. A pooled connection is reused by other requests; a session-wide setting would leak the previous user into the audit trail.</details>
3. A user is not a member of a team and asks for `GET /v1/teams/{id}`. Which status, and why not 403? <details><summary>Answer</summary>404. A 403 would confirm the id exists, which helps an attacker enumerate teams.</details>
4. What goes wrong if two clients create a task with the same `Idempotency-Key` at the same moment? <details><summary>Answer</summary>Nothing wrong: the second `INSERT INTO idempotency_keys` waits on the first transaction's primary key row. After the first commits, the second finds the stored response and replays it; if the first rolls back, the second proceeds and creates the task.</details>
5. Why are `Version`, `CreatedAt` and `UpdatedAt` marked `ValueGenerated...` in the `DbContext`? <details><summary>Answer</summary>The database sets them (default values and triggers). EF Core must not send its own values; it leaves them out of INSERT and UPDATE and reads them back.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `git status` lists `.env`, `bin/` or `obj/` as new files, or a password appears in a commit | `.gitignore` is missing, or it was created after the files were already tracked | Create the `.gitignore` shown above; for files already tracked run `git rm --cached .env` (and `git rm -r --cached bin obj`), commit, and replace any real secret that was ever committed |
| `error CS0542: 'Page': member names cannot be the same as their enclosing type` | A record named `Page<T>` with a member `Page`, which the JSON needs | Name the type `Paged<T>`; the property keeps the name `Page` |
| `error CS1061: 'DatabaseFacade' does not contain a definition for 'ExecuteSqlAsync' and no accessible extension method 'ExecuteSqlAsync' ...` | `ExecuteSqlAsync` is an extension method of EF Core | Add `using Microsoft.EntityFrameworkCore;` |
| `error CS0411: The type arguments for method 'RelationalQueryableExtensions.FromSql<TEntity>(DbSet<TEntity>, FormattableString)' cannot be inferred from the usage.` | `FromSql` was called after `AsNoTracking()`, which returns a plain query; `FromSql` only exists on a `DbSet` | Call it on the set first: `db.Teams.FromSql(...).AsNoTracking()` |
| `error CS1061: 'bool' does not contain a definition for 'Value' ...` after `req.Archived.Value` | `Optional<bool>` has a plain `bool Value`; a null from the JSON cannot be told apart | Use `Optional<bool?>` and `.Value!.Value` after the validator checked it |
| `Unhandled exception. System.NullReferenceException: Object reference not set to an instance of an object.` at `Program.<>c.<<Main>$>b__0_1(IServiceProvider services)` before the first request | FastEndpoints creates every endpoint once at startup, when there is no `HttpContext`; the `CurrentUser` factory used `HttpContext!.User` | Use `HttpContext?.User ?? new ClaimsPrincipal()` as in `Program.cs` |
| Every request answers 500, the log says `System.InvalidOperationException: The ConnectionString property has not been initialized.` | The API was started from the wrong folder, so `appsettings.json` was not found | Start it from `src/TasksApi` (or set `ConnectionStrings__Default`) |
| `/health` answers 503 with `{"status":"degraded","version":"1.0.0","database":"down"}`, other calls 500 | Postgres is stopped or unreachable | `docker compose -p bdn ps`, then `docker compose -p bdn up -d --wait db` |
| 500 and the log says `Npgsql.PostgresException (0x80004005): 28P01: password authentication failed for user "tasks_app"` | The password in `ConnectionStrings__Default` is not the one `schema.sql` set | Use `tasks_app_local_only` for this lab, or fix the environment variable |
| `docker compose` prints `The "POSTGRES_PASSWORD" variable is not set. Defaulting to a blank string.` | There is no `.env` file | `Copy-Item .env.example .env` (macOS and Linux: `cp`) |
| Error `Bind for 127.0.0.1:5432 failed: port is already allocated` | Another Postgres, or another lab's stack, uses the port | Stop it (`docker ps`), or finish the other lab first |

## Best practice
Let the database enforce what it can (constraints, triggers, functions) and let the API translate, never duplicate, those rules; pass every value as a parameter, never as text in SQL; and protect concurrent updates with a version checked **inside** the `UPDATE`. Source: [EF Core: SQL queries (FromSql and ExecuteSql use parameters)](https://learn.microsoft.com/ef/core/querying/sql-queries); [EF Core: concurrency tokens](https://learn.microsoft.com/ef/core/saving/concurrency); [RFC 9110 section 13.1.1 If-Match](https://www.rfc-editor.org/info/rfc9110); [Best practices for ASP.NET Core](https://learn.microsoft.com/aspnet/core/fundamentals/best-practices).

## Next lesson
03. Identity: replace the stand-in with real Keycloak sign-in checks. The API validates the bearer token (signature, issuer, audience, expiry), requires a scope and a realm role for each operation, and answers 401, 403 and 404 as the contract says. The conformance result rises to 17 passed.
