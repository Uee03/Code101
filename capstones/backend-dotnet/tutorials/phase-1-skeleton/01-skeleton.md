---
track: capstone
level: 201
phase: 1
phase_name: skeleton
lesson: 01
title: "The ASP.NET Core skeleton"
time: 90 min
prerequisites: [csharp-101, capstone-platform-04]
versions: { dotnet_sdk: "11.0.100", target_framework: "net11.0", fastendpoints: "9.0.0", fluentvalidation: "12.2.0 (comes with FastEndpoints)" }
verified: 2026-11-23 on Windows 11, .NET SDK 11.0.100, FastEndpoints 9.0.0
source: capstones/backend-dotnet/source/phase-1-skeleton/01-skeleton/
assets: []
---

# 01. The ASP.NET Core skeleton

## Why it matters
A restaurant needs a front door, a menu and a polite way to say "sorry, we are out of that" before it needs a kitchen. This chapter builds the front door of the Tasks and Teams API: a web server that starts, answers `GET /health`, has the shape of `/v1/me` and `POST /v1/teams`, and, most important, says **no** in one consistent, machine-readable way. Every error in this API is an RFC 9457 problem document (one exception, met in chapter 5: a request with a forbidden `Host` header is refused by the framework before our code runs), whether it comes from a bad JSON body, an unknown address or a bug. Getting that right on day one means the web, mobile and test clients of the other capstones never have to guess.

## What you will build
A solution with one ASP.NET Core project, `TasksApi`, on .NET 11 with FastEndpoints. Three working endpoints (health, a stub for `/v1/me`, a stub for `POST /v1/teams`), a global exception handler, problem details for 400, 404, 405, 415, 422 and 500, and a validation error shape that points at the bad field with a JSON Pointer. There is no database and no sign-in yet: chapters 2 and 3 add them.

Conformance so far (see [the platform chapter 04](../../../platform/tutorials/phase-4-conformance/04-conformance-script.md)): this chapter does not run `scripts/conformance.py`, because the script needs Keycloak for every check. You check `health` by hand with `curl`. **0 of the 18 checks are run, and `health` is answered correctly.**

## Before you start
- The platform capstone is finished or at least read (the [TDD](../../TDD.md) of this capstone links to it). You do not need Docker in this chapter.
- .NET SDK 11.0.100 or newer 11.0.x: run `dotnet --version`. .NET 11 is a Standard Term Support release published on 10 November 2026 and supported until 14 November 2028 ([.NET support policy](https://dotnet.microsoft.com/platform/support/policy/dotnet-core)). The C# 101 track explains the SDK and `global.json`.
- A terminal: PowerShell on Windows, Terminal on macOS or Linux. `curl` is part of Windows 10 and later, macOS and most Linux. **In Windows PowerShell write `curl.exe`, never `curl`** (see Common mistakes). The commands below show `curl.exe`; on macOS and Linux write `curl`.
- Source pack: unzip `backend-dotnet-phase-1-skeleton.zip` and open folder `01-skeleton/code`. You can follow the steps by typing the files yourself and compare with the pack at the end.

New terms (also in the [glossary](../../GLOSSARY.md)): **endpoint** (one address plus one HTTP method that does one thing), **REPR** (Request, Endpoint, Response: one class per operation), **DTO** (a plain object that only carries data in or out), **validator** (a class that checks a request before it is used), **problem details** (the standard JSON error format of RFC 9457), **middleware** (a step every request passes through), **dependency injection** (the framework hands a class the objects it needs).

## Steps
### Step 1. Create the solution and the project
Folder: anywhere you keep code, for example `~/code101`. Create the folder for the whole capstone and pin the SDK, create a solution, create an empty web project in `src/TasksApi`, add the project to the solution and add the FastEndpoints package.

```powershell
mkdir tasksteams-api
cd tasksteams-api
dotnet new globaljson --sdk-version 11.0.100 --roll-forward latestFeature
dotnet new sln --name TasksApi
dotnet new web --name TasksApi --output src/TasksApi
dotnet sln add src/TasksApi
dotnet add src/TasksApi package FastEndpoints --version 9.0.0
```
Expected result (the package command prints many `info :` lines about the NuGet download; the important ones are shown, the rest is replaced by `...`):
```text
The template "global.json file" was created successfully.

The template "Solution File" was created successfully.

The template "ASP.NET Core Empty" was created successfully.

Processing post-creation actions...
Restoring C:\...\tasksteams-api\src\TasksApi\TasksApi.csproj:
  Determining projects to restore...
  Restored C:\...\tasksteams-api\src\TasksApi\TasksApi.csproj (in 61 ms).
Restore succeeded.


Project `src\TasksApi\TasksApi.csproj` added to the solution.
info : Adding PackageReference for package 'FastEndpoints' into project 'C:\...\tasksteams-api\src\TasksApi\TasksApi.csproj'.
...
info : Installed FastEndpoints 9.0.0 from https://api.nuget.org/v3/index.json to C:\Users\you\.nuget\packages\fastendpoints\9.0.0 with content hash ...
info : Package 'FastEndpoints' is compatible with all the specified frameworks in project 'C:\...\tasksteams-api\src\TasksApi\TasksApi.csproj'.
info : PackageReference for package 'FastEndpoints' version '9.0.0' added to file 'C:\...\tasksteams-api\src\TasksApi\TasksApi.csproj'.
```
You now have this (the `obj` folder is build output and is not listed):
```text
tasksteams-api/
  global.json
  TasksApi.slnx
  src/TasksApi/
    Program.cs
    TasksApi.csproj
    appsettings.json
    appsettings.Development.json
    Properties/launchSettings.json
```
FastEndpoints brought FluentValidation 12.2.0 with it (a validation library, used in step 8). On .NET 11 `dotnet new sln` writes a `.slnx` file, the new XML solution format, instead of the old `.sln`.

### Step 2. Pin the SDK: `global.json`
`dotnet new globaljson` already created it. Open it and check that it matches. `version` is the oldest SDK that may build the project; `latestFeature` lets any newer 11.0 SDK (11.0.101, 11.0.200, ...) build it but refuses another major or minor version, so everyone on the team gets the same language and framework. The Docker build in chapter 4 uses the SDK image `11.0.100`.

**File: `global.json`**
```json
{
  "sdk": {
    "rollForward": "latestFeature",
    "version": "11.0.100"
  }
}
```
Expected result: nothing to type if the file is the same. If it is not, replace the content.

### Step 3. The solution file
Also created by the template. A solution is a list of projects that build together; this one has one.

**File: `TasksApi.slnx`**
```xml
<Solution>
  <Folder Name="/src/">
    <Project Path="src/TasksApi/TasksApi.csproj" />
  </Folder>
</Solution>
```

### Step 4. The project file `src/TasksApi/TasksApi.csproj`
The project file says what kind of program this is. Replace the content with the version below; the only change from the template is `InvariantGlobalization` (explained under "How it works").

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
  </ItemGroup>

</Project>
```

### Step 5. Configuration: `appsettings.json`
Replace `src/TasksApi/appsettings.json`. `Urls` is where the server listens: port 8000 on the loopback address, as the platform contract says. `Logging` sets how chatty the logs are.

**File: `src/TasksApi/appsettings.json`**
```json
{
  "Urls": "http://127.0.0.1:8000",
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

Delete the two things this API does not need, then check the folder:
```powershell
Remove-Item src/TasksApi/appsettings.Development.json
Remove-Item -Recurse src/TasksApi/Properties
```
On macOS and Linux use `rm src/TasksApi/appsettings.Development.json` and `rm -r src/TasksApi/Properties`. `launchSettings.json` would choose another port and an environment name for `dotnet run`; the API must always use the port in `appsettings.json`, so it goes.

### Step 6. Problem details: three files in `src/TasksApi/Common`
Create the folder `src/TasksApi/Common`. All errors leave the API through these three files.

`ProblemException` is how code anywhere in a request says "stop and answer with this status". The static helpers (`NotFound`, `Conflict`, and so on) give each status a short name; chapter 2 uses all of them.

**File: `src/TasksApi/Common/ProblemException.cs`**
```csharp
namespace TasksApi.Common;

// Thrown from anywhere in the request pipeline; ProblemExceptionHandler turns it into an RFC 9457 response.
public sealed class ProblemException(int status, string detail, string? code = null) : Exception(detail)
{
    public int Status { get; } = status;
    public string? Code { get; } = code;

    public static ProblemException BadRequest(string detail) => new(StatusCodes.Status400BadRequest, detail);
    public static ProblemException NotFound(string what) => new(StatusCodes.Status404NotFound, $"{what} was not found.");
    public static ProblemException Forbidden(string detail) => new(StatusCodes.Status403Forbidden, detail);
    public static ProblemException Conflict(string detail, string? code = null) => new(StatusCodes.Status409Conflict, detail, code);
    public static ProblemException Unprocessable(string detail) => new(StatusCodes.Status422UnprocessableEntity, detail);
    public static ProblemException PreconditionFailed(string detail) => new(StatusCodes.Status412PreconditionFailed, detail);
    public static ProblemException PreconditionRequired() =>
        new(StatusCodes.Status428PreconditionRequired, "The If-Match header is required for this request.");
}
```

`ProblemResponses` builds and writes the problem document: the members `type`, `title`, `status`, `detail`, `instance` (the request path) and `traceId`, plus `code` and `errors` when they are known. It also turns FastEndpoints validation failures into the contract's shape. Read the comments in the file; each method is explained in "How it works".

**File: `src/TasksApi/Common/ProblemResponses.cs`**
```csharp
using System.Diagnostics;
using System.Text.Json;
using System.Text.Json.Serialization;
using FluentValidation.Results;
using Microsoft.AspNetCore.Diagnostics;

namespace TasksApi.Common;

public sealed record FieldError(string Pointer, string Detail);

// RFC 9457 problem details. Null members are left out of the JSON.
public sealed record ProblemBody(
    string Type,
    string Title,
    int Status,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] string? Detail,
    string Instance,
    string TraceId,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] string? Code,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] IReadOnlyList<FieldError>? Errors);

public static class ProblemResponses
{
    private const string TypeBase = "https://code101.example/problems/";
    private const string ContentType = "application/problem+json";
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    private static (string Slug, string Title) Describe(int status) => status switch
    {
        400 => ("bad-request", "Bad request"),
        401 => ("unauthorized", "Unauthorized"),
        403 => ("forbidden", "Forbidden"),
        404 => ("not-found", "Not found"),
        409 => ("conflict", "Conflict"),
        412 => ("precondition-failed", "Precondition failed"),
        405 => ("bad-request", "Method not allowed"),
        413 => ("payload-too-large", "Payload too large"),
        415 => ("bad-request", "Unsupported media type"),
        422 => ("validation-error", "Validation failed"),
        428 => ("precondition-required", "Precondition required"),
        429 => ("rate-limited", "Too many requests"),
        >= 500 => ("internal-error", "Internal server error"),
        _ => ("bad-request", "Request failed"),
    };

    public static ProblemBody Build(HttpContext context, int status, string? detail = null, string? code = null,
        IReadOnlyList<FieldError>? errors = null)
    {
        var (slug, title) = Describe(status);
        var traceId = Activity.Current?.TraceId.ToString() ?? context.TraceIdentifier;
        return new ProblemBody(TypeBase + slug, title, status, detail, context.Request.Path, traceId, code, errors);
    }

    public static Task WriteAsync(HttpContext context, int status, string? detail = null, string? code = null,
        IReadOnlyList<FieldError>? errors = null)
    {
        context.Response.StatusCode = status;
        return context.Response.WriteAsJsonAsync(Build(context, status, detail, code, errors), Json, ContentType,
            context.RequestAborted);
    }

    // Called for responses that have a status code but no body, for example an unknown route (404).
    public static Task WriteStatusCodeAsync(StatusCodeContext context)
    {
        var http = context.HttpContext;
        return WriteAsync(http, http.Response.StatusCode);
    }

    // Plugged into FastEndpoints. A rule of ours that fails becomes a 422 with errors[]. A failure without an error code
    // did not come from our rules: the JSON, a route value or a query value could not be read, which is a 400.
    public static object ValidationProblem(List<ValidationFailure> failures, HttpContext context, int status)
    {
        if (failures.All(f => string.IsNullOrEmpty(f.ErrorCode)))
        {
            status = StatusCodes.Status400BadRequest;
            context.Response.StatusCode = status;
        }
        var errors = failures
            .Where(f => f.PropertyName != "SerializerErrors")
            .Select(f => new FieldError(ToPointer(f.PropertyName),
                status == StatusCodes.Status400BadRequest ? "is unknown or has the wrong type" : f.ErrorMessage))
            .ToList();
        var detail = status == StatusCodes.Status400BadRequest
            ? "The request could not be read: the JSON is malformed, or a field, path value or query value is unknown or has the wrong type."
            : "One or more fields are invalid.";
        return Build(context, status, detail, errors: errors.Count == 0 ? null : errors);
    }

    // "Name" becomes "/name", "Items[0].Title" becomes "/items[0]/title"; a failure about the whole body has no name and becomes "".
    private static string ToPointer(string propertyName) =>
        propertyName.Length == 0
            ? ""
            : "/" + string.Join('/', propertyName.Split('.').Select(JsonNamingPolicy.CamelCase.ConvertName));
}
```

`ProblemExceptionHandler` is the last safety net. It turns a `ProblemException` into its problem, a bad request into a 4xx problem, and **anything else** into a 500 whose detail never says what went wrong (the real exception goes to the log only).

**File: `src/TasksApi/Common/ProblemExceptionHandler.cs`**
```csharp
using Microsoft.AspNetCore.Diagnostics;

namespace TasksApi.Common;

public sealed class ProblemExceptionHandler(ILogger<ProblemExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext context, Exception exception, CancellationToken cancellationToken)
    {
        switch (exception)
        {
            case ProblemException problem:
                await ProblemResponses.WriteAsync(context, problem.Status, problem.Message, problem.Code);
                break;
            case BadHttpRequestException bad:
                await ProblemResponses.WriteAsync(context, bad.StatusCode, "The request could not be read.");
                break;
            default:
                logger.LogError(exception, "Unhandled exception for {Method} {Path}", context.Request.Method, context.Request.Path);
                await ProblemResponses.WriteAsync(context, StatusCodes.Status500InternalServerError, "An unexpected error occurred.");
                break;
        }
        return true;
    }
}
```

### Step 7. The response DTOs: `src/TasksApi/Contracts`
Create the folder `src/TasksApi/Contracts`. These records are the JSON the API sends, named after the schemas in `openapi.yaml`: `Team` and `Me`. A `record` is a short way to write a class that only holds values.

**File: `src/TasksApi/Contracts/TeamDto.cs`**
```csharp
namespace TasksApi.Contracts;

public sealed record TeamDto(
    Guid Id,
    string Name,
    string Description,
    int MemberCount,
    Guid CreatedBy,
    int Version,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);
```

**File: `src/TasksApi/Contracts/MeDto.cs`**
```csharp
namespace TasksApi.Contracts;

public sealed record MeTeamDto(Guid TeamId, string Name, string Role);

public sealed record MeDto(
    Guid Id,
    string Username,
    string Email,
    string DisplayName,
    IReadOnlyList<string> Roles,
    IReadOnlyList<string> Scopes,
    IReadOnlyList<MeTeamDto> Teams);
```

### Step 8. The three endpoints: `src/TasksApi/Features`
FastEndpoints groups code by **feature**, not by technical layer: each operation is one class, next to its request, response and validator. Create the folders `src/TasksApi/Features/Platform` and `src/TasksApi/Features/Teams`.

`GET /health` answers without a token, so the load balancer and Docker can ask whether the service is alive.

**File: `src/TasksApi/Features/Platform/HealthEndpoint.cs`**
```csharp
using FastEndpoints;

namespace TasksApi.Features.Platform;

public sealed record HealthResponse(string Status, string Version);

// GET /health: liveness. Public, so Docker and load balancers can call it without a token.
public sealed class HealthEndpoint : EndpointWithoutRequest<HealthResponse>
{
    public override void Configure()
    {
        Get("/health");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CancellationToken ct) =>
        await Send.OkAsync(new HealthResponse("ok", "1.0.0"), ct);
}
```

`GET /v1/me` is a stub that always answers as alice. Chapter 3 replaces it with the real caller.

**File: `src/TasksApi/Features/Platform/MeEndpoint.cs`**
```csharp
using FastEndpoints;
using TasksApi.Contracts;

namespace TasksApi.Features.Platform;

// GET /v1/me: a stub that always answers as alice. Chapter 3 reads the caller from the access token instead.
public sealed class MeEndpoint : EndpointWithoutRequest<MeDto>
{
    public override void Configure()
    {
        Get("/v1/me");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CancellationToken ct) =>
        await Send.OkAsync(new MeDto(
            Guid.Parse("a11ce000-0000-4000-8000-000000000001"),
            "alice",
            "alice@tasksteams.test",
            "Alice Admin",
            ["admin"],
            ["tasks:read", "tasks:write", "tasks:admin"],
            []), ct);
}
```

`POST /v1/teams` shows the whole REPR pattern: a request class (`CreateTeamRequest`), a validator (`CreateTeamValidator`) and the endpoint. It does not save anything yet; it returns what a saved team would look like, with the `201 Created`, `Location` and `ETag` the contract requires.

**File: `src/TasksApi/Features/Teams/CreateTeamEndpoint.cs`**
```csharp
using FastEndpoints;
using FluentValidation;
using TasksApi.Contracts;

namespace TasksApi.Features.Teams;

public sealed class CreateTeamRequest
{
    public string Name { get; set; } = "";
    public string? Description { get; set; }
    public Guid? LeadUserId { get; set; }
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

// POST /v1/teams: a stub that validates the body and answers as if the team was saved. Chapter 2 stores it.
public sealed class CreateTeamEndpoint : Endpoint<CreateTeamRequest, TeamDto>
{
    public override void Configure()
    {
        Post("/v1/teams");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CreateTeamRequest req, CancellationToken ct)
    {
        var now = DateTimeOffset.UtcNow;
        var team = new TeamDto(Guid.NewGuid(), req.Name.Trim(), req.Description ?? "", 1,
            Guid.Parse("a11ce000-0000-4000-8000-000000000001"), 1, now, now);
        HttpContext.Response.Headers.ETag = $"\"{team.Version}\"";
        HttpContext.Response.Headers.Location = $"/v1/teams/{team.Id}";
        await Send.ResponseAsync(team, StatusCodes.Status201Created, ct);
    }
}
```

### Step 9. `Program.cs`: put it together
Replace the template's `Program.cs`. Read it from top to bottom: first the services the app needs, then `Build()`, then the **pipeline** of middleware in the order a request meets them.

**File: `src/TasksApi/Program.cs`**
```csharp
using System.Text.Json.Serialization;
using FastEndpoints;
using TasksApi.Common;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddFastEndpoints();
builder.Services.AddExceptionHandler<ProblemExceptionHandler>();
builder.Services.AddProblemDetails();

var app = builder.Build();

app.UseExceptionHandler();
app.UseStatusCodePages(ProblemResponses.WriteStatusCodeAsync);
app.UseFastEndpoints(config =>
{
    config.Errors.StatusCode = StatusCodes.Status422UnprocessableEntity;
    config.Errors.ContentType = "application/problem+json";
    config.Errors.ResponseBuilder = ProblemResponses.ValidationProblem;
    config.Serializer.Options.UnmappedMemberHandling = JsonUnmappedMemberHandling.Disallow;
});

app.Run();
```

### Step 10. Test requests, the contract and `.gitignore`
Two tiny JSON files are request bodies for `curl`. Create the folder `requests` next to `global.json`.

**File: `requests/empty-team.json`**
```json
{ "name": "" }
```

**File: `requests/new-team.json`**
```json
{ "name": "Ops Team", "description": "Runs the servers." }
```

Git must not store build output or local secrets.

**File: `.gitignore`**
```text
bin/
obj/
.env
```

Finally copy the platform contract next to your code so you can open it while you work. It comes from the platform capstone and is not changed here: copy `capstones/platform/source/phase-4-conformance/04-conformance-script/code/openapi.yaml` to `openapi.yaml` in the root of your solution folder. (The pack already contains it. The lesson checker skips this file because chapter 01 of the platform capstone shows it in full.)

Check the final layout of this chapter's code:
```text
code/
  .gitignore
  TasksApi.slnx
  global.json
  openapi.yaml
  requests/empty-team.json, new-team.json
  src/TasksApi/
    TasksApi.csproj, Program.cs, appsettings.json
    Common/        ProblemException.cs, ProblemExceptionHandler.cs, ProblemResponses.cs
    Contracts/     MeDto.cs, TeamDto.cs
    Features/Platform/  HealthEndpoint.cs, MeEndpoint.cs
    Features/Teams/     CreateTeamEndpoint.cs
```

## Run it
Folder: the solution folder (the one with `global.json`). Build once. Warnings are fine; errors are not.
```powershell
dotnet build --nologo
```
Expected output:
```text
  Determining projects to restore...
  All projects are up-to-date for restore.
  TasksApi -> F:\...\code\src\TasksApi\bin\Debug\net11.0\TasksApi.dll

Build succeeded.
    0 Warning(s)
    0 Error(s)

Time Elapsed 00:00:00.50
```
On a first build `Determining projects to restore...` is followed by the restore of the packages and the times are longer. Now start the API from the **project** folder, because `appsettings.json` is looked up in the current folder:
```powershell
cd src/TasksApi
dotnet run
```
Expected output (the path in the last line is your folder):
```text
info: FastEndpoints.StartupTimer[1]
      Registered 3 endpoints in 97 milliseconds.
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://127.0.0.1:8000
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
info: Microsoft.Hosting.Lifetime[0]
      Hosting environment: Production
info: Microsoft.Hosting.Lifetime[0]
      Content root path: F:\...\code\src\TasksApi
```
Leave it running and open a **second** terminal in the solution folder. Call the three endpoints:
```powershell
curl.exe -s http://127.0.0.1:8000/health
```
Expected output:
```text
{"status":"ok","version":"1.0.0"}
```
```powershell
curl.exe -s http://127.0.0.1:8000/v1/me
```
Expected output:
```text
{"id":"a11ce000-0000-4000-8000-000000000001","username":"alice","email":"alice@tasksteams.test","displayName":"Alice Admin","roles":["admin"],"scopes":["tasks:read","tasks:write","tasks:admin"],"teams":[]}
```
Now send a valid team (`-i` prints the status line and headers; `--data-binary @file` sends the file as the body):
```powershell
curl.exe -s -i -X POST http://127.0.0.1:8000/v1/teams -H "Content-Type: application/json" --data-binary "@requests/new-team.json"
```
Expected output (the id and the times differ on your machine):
```text
HTTP/1.1 201 Created
Content-Type: application/json; charset=utf-8
Date: Mon, 23 Nov 2026 08:34:40 GMT
Server: Kestrel
ETag: "1"
Location: /v1/teams/1b080cfa-7703-49c1-a718-ec87c107328f
Transfer-Encoding: chunked

{"id":"1b080cfa-7703-49c1-a718-ec87c107328f","name":"Ops Team","description":"Runs the servers.","memberCount":1,"createdBy":"a11ce000-0000-4000-8000-000000000001","version":1,"createdAt":"2026-11-23T08:34:40.8220998+00:00","updatedAt":"2026-11-23T08:34:40.8220998+00:00"}
```
Now the important part: the **errors**. An empty name breaks the validator rule:
```powershell
curl.exe -s -i -X POST http://127.0.0.1:8000/v1/teams -H "Content-Type: application/json" --data-binary "@requests/empty-team.json"
```
Expected output:
```text
HTTP/1.1 422 Unprocessable Entity
Content-Type: application/problem+json; charset=utf-8
Date: Mon, 23 Nov 2026 08:34:40 GMT
Server: Kestrel
Transfer-Encoding: chunked

{"type":"https://code101.example/problems/validation-error","title":"Validation failed","status":422,"detail":"One or more fields are invalid.","instance":"/v1/teams","traceId":"b6e544472efdeffad2a2327d53a46123","errors":[{"pointer":"/name","detail":"must be between 1 and 80 characters"}]}
```
An address that does not exist is also a problem document, with the same `type` list as the contract:
```powershell
curl.exe -s -i http://127.0.0.1:8000/nope
```
Expected output:
```text
HTTP/1.1 404 Not Found
Content-Type: application/problem+json
Date: Mon, 23 Nov 2026 08:34:40 GMT
Server: Kestrel
Transfer-Encoding: chunked

{"type":"https://code101.example/problems/not-found","title":"Not found","status":404,"instance":"/nope","traceId":"37aadb6039459a0cf5703b6cb1a4f4cc"}
```
Three more mistakes a client can make. Create two small files in the solution folder: `bad.json` with the single line `{bad`, and `unknown.json` with the line `{ "name": "Ops", "color": "red" }`. Then send them, and also try the wrong method and the wrong content type:
```powershell
curl.exe -s -X POST http://127.0.0.1:8000/v1/teams -H "Content-Type: application/json" --data-binary "@bad.json"
curl.exe -s -X POST http://127.0.0.1:8000/v1/teams -H "Content-Type: application/json" --data-binary "@unknown.json"
curl.exe -s -X DELETE http://127.0.0.1:8000/health
curl.exe -s -X POST http://127.0.0.1:8000/v1/teams -H "Content-Type: text/plain" -d "hello"
```
Expected output (one line each; broken JSON and an unknown field are 400, the wrong method is 405, the wrong content type is 415):
```text
{"type":"https://code101.example/problems/bad-request","title":"Bad request","status":400,"detail":"The request could not be read: the JSON is malformed, or a field, path value or query value is unknown or has the wrong type.","instance":"/v1/teams","traceId":"0ac1bd567f262e919e1ef76f8e1fb316"}
{"type":"https://code101.example/problems/bad-request","title":"Bad request","status":400,"detail":"The request could not be read: the JSON is malformed, or a field, path value or query value is unknown or has the wrong type.","instance":"/v1/teams","traceId":"1cd6606f8780fd56ee196976b66ad505","errors":[{"pointer":"/color","detail":"is unknown or has the wrong type"}]}
{"type":"https://code101.example/problems/bad-request","title":"Method not allowed","status":405,"instance":"/health","traceId":"715ca7dea3ef8478812e2a999278efd9"}
{"type":"https://code101.example/problems/bad-request","title":"Unsupported media type","status":415,"instance":"/v1/teams","traceId":"f9f3a38f4d3a7a33b4377064b3db991d"}
```
Stop the API with Ctrl+C in the first terminal and delete `bad.json` and `unknown.json`.

## How it works
Follow one request, `POST /v1/teams` with an empty name, through the code in the order it runs.

1. **Startup.** `WebApplication.CreateBuilder` reads `appsettings.json` (and environment variables, which win) and sets up logging and the web server, Kestrel. `AddFastEndpoints()` finds every class that derives from `Endpoint<,>` or `EndpointWithoutRequest<>` and registers its route; the log line "Registered 3 endpoints" confirms it. `AddExceptionHandler<ProblemExceptionHandler>()` registers our handler for unhandled exceptions. `AddProblemDetails()` registers the framework's own problem-details service, which the exception handler middleware uses as its fallback; we write the bodies ourselves.
2. **The pipeline.** Each `app.Use...` line adds one middleware, and a request passes them top to bottom: the exception handler (outermost, so it can catch everything below), the status code pages (give empty 404, 405 and 415 responses a problem body through `ProblemResponses.WriteStatusCodeAsync`), then FastEndpoints, which holds the routes.
3. **Routing and binding.** FastEndpoints matches `POST /v1/teams` to `CreateTeamEndpoint`, reads the JSON body into a new `CreateTeamRequest` with System.Text.Json (`UnmappedMemberHandling.Disallow` makes a field the DTO does not have an error, which matches `additionalProperties: false` in the contract), and finds the validator class for that request type by itself.
4. **Validation.** `CreateTeamValidator` derives from `Validator<CreateTeamRequest>` (FluentValidation). `RuleFor(x => x.Name).Must(...)` runs; an empty name fails, so `HandleAsync` never runs. FastEndpoints calls the function in `config.Errors.ResponseBuilder`, our `ProblemResponses.ValidationProblem`, with the list of failures, and sends the object it returns with the content type `application/problem+json`.
5. **The status code split.** Two kinds of failure reach that function. A rule that **we** wrote has an error code (`PredicateValidator`): "well-formed request, wrong value", a **422** with `errors[]`. A failure **without** an error code did not come from our rules: the JSON was malformed, a route value such as an id was not a GUID, or a query value such as `limit=abc` was not a number. That is a **400**. The code sets `context.Response.StatusCode` itself for that case.
6. **JSON Pointer.** `errors[].pointer` follows RFC 6901. The validator's property name `Name` becomes `/name` through `JsonNamingPolicy.CamelCase`, which is the name the client sent.
7. **The handler.** For a valid body `HandleAsync` runs, builds a `TeamDto` and sends `201 Created` with `ETag` (the quoted `version`) and `Location`. The ETag is a strong validator: chapter 2 uses it for `If-Match`.
8. **Exceptions.** If any code throws `ProblemException`, the exception handler middleware catches it and `ProblemExceptionHandler` writes the matching problem. Any other exception becomes a 500 with the neutral text "An unexpected error occurred." and the full exception goes to the log. The client never sees a stack trace (OWASP API8, security misconfiguration).

Why these choices:

| Decision | Alternatives | Why this one |
|----------|--------------|--------------|
| FastEndpoints (REPR) | Controllers; Minimal APIs with route groups | One class per operation keeps request, validator and handler together; no controller classes that grow. Do not mix styles in one API |
| FluentValidation for input rules | Data annotations | FastEndpoints is built around it; rules are code, so they can use any C# |
| Our own `ProblemResponses` | The built-in `ProblemDetails` class and `AddProblemDetails` defaults | The contract fixes the `type` URIs and the `errors[]` shape; owning 90 lines is simpler than bending the defaults |
| Strings for `status` and `priority` | C# enums | The database stores text with CHECK constraints; the DTOs stay equal to the JSON with no converters |
| `InvariantGlobalization` | Full ICU globalization | Alpine images used in chapter 4 have no ICU libraries, and an API that returns UTC dates and fixed formats does not need culture data |
| Single project, folders per feature | Several class libraries (Domain, Application, Infrastructure) | The domain is CRUD plus three database functions; extra projects would only add ceremony. The dependency direction still holds: `Features` use `Data`, `Data` knows nothing about `Features` |

## Try it
Add a fourth endpoint, `GET /v1/ping`, that answers `{"pong":true}` to anyone. The starter is a class with three TODO comments; the solution is the finished file.

1. Copy `exercise/starter/src/TasksApi/Features/Platform/PingEndpoint.cs` into your `src/TasksApi/Features/Platform` folder.
2. Follow the TODOs in the file.
3. Run `dotnet run` in `src/TasksApi` and call `curl.exe -s http://127.0.0.1:8000/v1/ping`. The log line must now say "Registered 4 endpoints".

Starter:

**File: `exercise/starter/src/TasksApi/Features/Platform/PingEndpoint.cs`**
```csharp
using FastEndpoints;

namespace TasksApi.Features.Platform;

public sealed record PingResponse(bool Pong);

// TODO 1: make this class an endpoint that has no request body and answers with a PingResponse
//         (derive from EndpointWithoutRequest<PingResponse>).
// TODO 2: add Configure(): answer GET /v1/ping and let anonymous callers in (AllowAnonymous).
// TODO 3: add HandleAsync(): send 200 OK with new PingResponse(true).
public sealed class PingEndpoint
{
}
```

<details><summary>Solution</summary>

**File: `exercise/solution/src/TasksApi/Features/Platform/PingEndpoint.cs`**
```csharp
using FastEndpoints;

namespace TasksApi.Features.Platform;

public sealed record PingResponse(bool Pong);

// GET /v1/ping: the smallest possible endpoint.
public sealed class PingEndpoint : EndpointWithoutRequest<PingResponse>
{
    public override void Configure()
    {
        Get("/v1/ping");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CancellationToken ct) =>
        await Send.OkAsync(new PingResponse(true), ct);
}
```

`EndpointWithoutRequest<PingResponse>` means no request body and a `PingResponse` answer. `AllowAnonymous()` is needed from chapter 3 on; today nothing is protected yet, but writing it now says what you mean.

</details>

## Check yourself
1. Why does a missing `name` give 422 while malformed JSON gives 400? <details><summary>Answer</summary>Malformed JSON cannot be read at all, so the server does not understand the request (400). A readable body with a bad value is understood but not acceptable (422). The platform contract uses both so a client can tell "fix your code" from "fix your input".</details>
2. What does `instance` hold in a problem document and why? <details><summary>Answer</summary>The path of the request that failed, so a client or a log reader can see which call produced the problem without matching it to the request.</details>
3. Why is the exception handler the first middleware? <details><summary>Answer</summary>A middleware can only catch exceptions thrown by the middlewares after it. Placed first it catches errors from everything below, including endpoints.</details>
4. What would a client see if the code threw `new InvalidOperationException("password is wrong")`? <details><summary>Answer</summary>A 500 problem with the detail "An unexpected error occurred." The message stays in the server log.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `error CS0246: The type or namespace name 'StatusCodeContext' could not be found (are you missing a using directive or an assembly reference?)` | `ProblemResponses.cs` lacks `using Microsoft.AspNetCore.Diagnostics;` | Add the line at the top of the file. Types of the web framework live in many namespaces; the error names the type, the editor offers the `using` |
| `curl -s http://127.0.0.1:8000/health` prints `Invoke-WebRequest : Cannot process command because of one or more missing mandatory parameters: Uri.` | In Windows PowerShell 5.1 `curl` is an alias of `Invoke-WebRequest`, which has other parameters | Write `curl.exe` (macOS and Linux: `curl`) |
| `System.IO.IOException: Failed to bind to address http://127.0.0.1:8000: address already in use.` | Another program, or a second copy of this API, already listens on port 8000 | Stop the other program (Ctrl+C in its terminal) or find it with `netstat -ano` on Windows and `lsof -i :8000` on macOS and Linux |
| `Couldn't find a project to run. Ensure a project exists in <folder>, or pass the path to the project using --project.` | `dotnet run` was started in the solution folder, which has no `.csproj` | `cd src/TasksApi` first |
| `The command could not be loaded, possibly because: ... A compatible .NET SDK was not found.` | `global.json` asks for an SDK version that is not installed | Install the SDK named in the message, or fix the `version` in `global.json` to one that `dotnet --list-sdks` shows |
| A 415 problem: `"title":"Unsupported media type","status":415` | The body was sent with another `Content-Type`; `curl -d` alone sends a form content type | Add `-H "Content-Type: application/json"` |

## Best practice
Return one error format everywhere, never leak exception messages or stack traces, and include a correlation id (`traceId`) so a support request can be matched to a log line. Source: [RFC 9457 Problem Details for HTTP APIs](https://www.rfc-editor.org/info/rfc9457); [Best practices for ASP.NET Core](https://learn.microsoft.com/aspnet/core/fundamentals/best-practices); [OWASP API Security Top 10 2023, API8 Security Misconfiguration](https://owasp.org/API-Security/editions/2023/en/0xa8-security-misconfiguration/).

## Next lesson
02. Data access: connect to the platform's Postgres database with EF Core, read and write through the entities, call the stored functions `create_team`, `complete_task` and `reassign_task`, and add ETag with `If-Match`, cursor pagination, filtering and `Idempotency-Key`. The other 24 operations of the contract arrive there.
