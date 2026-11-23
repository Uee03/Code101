---
track: capstone
level: 201
phase: 5
phase_name: hardening
lesson: 05
title: "Hardening: the OWASP API Top 10 in your own code"
time: 75 min
prerequisites: [capstone-backend-dotnet-04]
versions: { dotnet_sdk: "11.0.100", dotnet_runtime: "11.0.0", docker: "29.9.3", owasp_api_top10: "2023" }
verified: 2026-11-23 on Windows 11, Docker 29.9.3, Compose 5.7.0, Python 3.15.2
source: capstones/backend-dotnet/source/phase-5-hardening/05-hardening/
assets: []
---

# 05. Hardening: the OWASP API Top 10 in your own code

## Why it matters
A bank branch has a front door that locks, a guard who counts how many people enter, cameras that film faces but never record PIN codes, and a rule that nobody carries a truck of paper to the counter. None of it makes the vault rules better; it limits what one bad day can cost. This chapter adds those four things to the API (limits, counting, careful logging, strict headers) and walks the **OWASP API Security Top 10** (2023) against your code so each risk points at the file that answers it.

## What you will build
A rate limiter with the `RateLimit-Limit`, `RateLimit-Remaining` and `RateLimit-Reset` headers and a 429 answer with `Retry-After`; security headers on every response; request-size, header and timeout limits; CORS for the two local web clients and the `AllowedHosts` rule; one JSON log line per request with the user id and trace id but never a token or a body; warnings for refused tokens, 403s and 429s. Then the walk-through table. The conformance script prints **18 passed, 0 failed**: the last check, `me`, needed the rate-limit headers.

## Before you start
- Chapter 04 done or its pack unzipped. Docker running; Python 3.10+; .NET SDK 11.0.100 or newer 11.0.x (only for the exercise build and the dependency check at the end of "Run it"); host ports 5432, 8180 and 8000 free.
- Source pack: unzip `backend-dotnet-phase-5-hardening.zip` and open `05-hardening/code`.

New terms (see the [glossary](../../GLOSSARY.md)): **fixed-window rate limit**, **security header**, **CORS**.

## Steps
### Step 1. Read the map first: the OWASP API Security Top 10 (2023) against this code
Every row names the risk, what the API does, the file where that happens and a command that shows it (all of them are in the "Run it" section).

| Risk | What this API does | Where | See it work |
|------|--------------------|-------|-------------|
| API1 Broken object level authorization | Every operation that takes a team, project, task or comment id first asks `TeamAccess`; a non-member gets 404 | `Security/TeamAccess.cs`, all `Features/*` | chapter 03: bob asks for a team he is not in |
| API2 Broken authentication | Signature, issuer, audience, expiry, `RS256` only; no passwords in the API; refused tokens logged by reason, never the token | `Security/JwtSetup.cs` | a garbage token gives 401 and a warning |
| API3 Broken object property level authorization | Request classes list only writable fields; unknown fields are 400; `Optional<T>` changes only the fields sent; `id`, `version`, times and `createdBy` are never read from a body | `Features/*/…Request`, `Program.cs` (`UnmappedMemberHandling.Disallow`) | chapter 01: `unknown.json` |
| API4 Unrestricted resource consumption | `limit` at most 100; body 1 MB; headers 32 KB and 15 s to send them; field length rules; the rate limiter | `Program.cs` (Kestrel), `Common/Paging.cs`, `Security/RateLimitMiddleware.cs` | a 1.2 MB body gives 413; the 31st anonymous call in one minute gives 429 |
| API5 Broken function level authorization | Policies per operation: scope and role; the team level (member, lead) in `TeamAccess` | `Security/AccessPolicies.cs` | bob gets 403 on the audit log |
| API6 Unrestricted access to sensitive business flows | Creating teams is admin only; `Idempotency-Key` stops a retry creating two; archived projects take no tasks; the limiter slows scripts | `Features/Teams/CreateTeamEndpoint.cs`, `Data/Idempotency.cs` | chapter 02 |
| API7 Server-side request forgery | The only outgoing call is the key fetch from `Auth:MetadataAddress`, set by the operator; no URL ever comes from a request | `Security/JwtSetup.cs` | nothing to call: there is no such feature |
| API8 Security misconfiguration | Security headers; no `Server` header; no stack traces; exact CORS origins; `AllowedHosts`; non-root, read-only container; loopback ports; `RequireHttpsMetadata` off **only** for local http | `Security/SecurityHeadersMiddleware.cs`, `appsettings.json`, `Dockerfile` | the headers below; a wrong `Host` gets 400 |
| API9 Improper inventory management | One contract file, 27 endpoint classes, the startup log counts them, every path under `/v1` | `openapi.yaml`, `Features/` | `Registered 27 endpoints` |
| API10 Unsafe consumption of APIs | Tokens are trusted only from the configured issuer; every incoming JSON is validated before it is used | `Security/JwtSetup.cs`, validators | chapter 03: a refused token gives 401 |

### Step 2. Request logging
One line per request: method, **path without the query string**, status, time, user id and trace id. It logs after the response is written, so the status is the final one, even for errors. Never log headers, bodies, tokens or query strings: they carry secrets and personal data. Create `src/TasksApi/Common/RequestLoggingMiddleware.cs`.

**File: `src/TasksApi/Common/RequestLoggingMiddleware.cs`**
```csharp
using System.Diagnostics;
using System.Security.Claims;

namespace TasksApi.Common;

// One log line per request, as structured fields: method, path, status, time, user id and trace id.
// It logs the path but never the query string, headers or body, so tokens, search terms and personal data stay out of the logs.
public sealed class RequestLoggingMiddleware(RequestDelegate next, ILogger<RequestLoggingMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        var started = Stopwatch.GetTimestamp();
        try
        {
            await next(context);
        }
        finally
        {
            logger.LogInformation("{Method} {Path} {Status} {ElapsedMs}ms user={UserId} trace={TraceId}",
                context.Request.Method, context.Request.Path.Value, context.Response.StatusCode,
                (long)Stopwatch.GetElapsedTime(started).TotalMilliseconds,
                context.User.FindFirstValue("sub") ?? "-", Activity.Current?.TraceId.ToString() ?? context.TraceIdentifier);
        }
    }
}
```

### Step 3. Security headers
Create `src/TasksApi/Security/SecurityHeadersMiddleware.cs`. `OnStarting` registers a function that runs just before the response headers are sent, so the headers are present on every answer, including errors written by other middleware.

**File: `src/TasksApi/Security/SecurityHeadersMiddleware.cs`**
```csharp
namespace TasksApi.Security;

// Adds the browser-facing protections to every response, including errors (OnStarting runs when the response begins).
public sealed class SecurityHeadersMiddleware(RequestDelegate next)
{
    public Task InvokeAsync(HttpContext context)
    {
        context.Response.OnStarting(() =>
        {
            var headers = context.Response.Headers;
            headers.XContentTypeOptions = "nosniff";
            headers.XFrameOptions = "DENY";
            headers.ContentSecurityPolicy = "default-src 'none'; frame-ancestors 'none'";
            headers["Referrer-Policy"] = "no-referrer";
            headers.CacheControl = "no-store";
            if (context.Request.IsHttps)
            {
                headers.StrictTransportSecurity = "max-age=31536000; includeSubDomains";
            }
            return Task.CompletedTask;
        });
        return next(context);
    }
}
```

| Header | Meaning |
|--------|---------|
| `X-Content-Type-Options: nosniff` | a browser must not guess a different content type |
| `X-Frame-Options: DENY` and CSP `frame-ancestors 'none'` | the answer may not be shown in a frame (clickjacking) |
| `Content-Security-Policy: default-src 'none'` | an API answer loads nothing and runs nothing |
| `Referrer-Policy: no-referrer` | no referrer is leaked when a link is followed |
| `Cache-Control: no-store` | proxies and browsers do not keep API answers |
| `Strict-Transport-Security` | only sent over https: tells the browser to use https for a year |

### Step 4. Rate limiting
Create `src/TasksApi/Security/RateLimitMiddleware.cs`. It counts requests per window and per caller: the user id (`sub`) when signed in, otherwise the client address. It runs **after** authentication (so it knows the user) and **before** authorization (so even refused requests count). It sets the three headers on every answer and answers 429 with `Retry-After` when a caller is over the limit. `/health` is exempt so probes are never throttled.

**File: `src/TasksApi/Security/RateLimitMiddleware.cs`**
```csharp
using System.Collections.Concurrent;
using System.Security.Claims;
using Microsoft.Extensions.Options;
using TasksApi.Common;

namespace TasksApi.Security;

public sealed class RateLimitOptions
{
    public int AuthenticatedLimit { get; init; } = 100;
    public int AnonymousLimit { get; init; } = 30;
    public int WindowSeconds { get; init; } = 60;
}

// A fixed-window limiter: 100 requests per 60 seconds per signed-in user, 30 per client address when anonymous (R-14).
// ASP.NET Core also ships a limiter (AddRateLimiter), but it cannot tell us how many requests are left or when the
// window ends, and the contract wants RateLimit-Limit, RateLimit-Remaining and RateLimit-Reset on every response.
// The counters live in memory, so with several API instances each one counts separately; use a shared store then.
public sealed class RateLimitMiddleware(RequestDelegate next, IOptions<RateLimitOptions> options,
    ILogger<RateLimitMiddleware> logger, TimeProvider time)
{
    private sealed class Window(DateTimeOffset start)
    {
        public DateTimeOffset Start = start;
        public int Count;
    }

    private readonly RateLimitOptions _options = options.Value;
    private readonly ConcurrentDictionary<string, Window> _windows = new();
    private long _requests;

    public async Task InvokeAsync(HttpContext context)
    {
        if (context.Request.Path == "/health")
        {
            await next(context);
            return;
        }
        var subject = context.User.FindFirstValue("sub");
        var key = subject is null ? $"ip:{context.Connection.RemoteIpAddress}" : $"user:{subject}";
        var limit = subject is null ? _options.AnonymousLimit : _options.AuthenticatedLimit;
        var span = TimeSpan.FromSeconds(_options.WindowSeconds);
        var now = time.GetUtcNow();
        SweepSometimes(now, span);

        var window = _windows.GetOrAdd(key, _ => new Window(now));
        int count;
        DateTimeOffset start;
        lock (window)
        {
            if (now - window.Start >= span)
            {
                window.Start = now;
                window.Count = 0;
            }
            count = ++window.Count;
            start = window.Start;
        }
        var reset = Math.Max(1, (int)Math.Ceiling((start + span - now).TotalSeconds));
        var remaining = Math.Max(0, limit - count);
        context.Response.OnStarting(() =>
        {
            var headers = context.Response.Headers;
            headers["RateLimit-Limit"] = limit.ToString();
            headers["RateLimit-Remaining"] = remaining.ToString();
            headers["RateLimit-Reset"] = reset.ToString();
            if (count > limit)
            {
                headers.RetryAfter = reset.ToString();
            }
            return Task.CompletedTask;
        });

        if (count > limit)
        {
            logger.LogWarning("Rate limit exceeded for {Key} on {Method} {Path}", key, context.Request.Method, context.Request.Path);
            await ProblemResponses.WriteAsync(context, StatusCodes.Status429TooManyRequests,
                $"Too many requests. Try again in {reset} seconds.");
            return;
        }
        await next(context);
    }

    // Forget windows that ended long ago, so one-off visitors do not fill the dictionary forever.
    private void SweepSometimes(DateTimeOffset now, TimeSpan span)
    {
        if (Interlocked.Increment(ref _requests) % 1000 != 0)
        {
            return;
        }
        foreach (var (key, window) in _windows)
        {
            if (now - window.Start > span * 2)
            {
                _windows.TryRemove(key, out _);
            }
        }
    }
}
```

### Step 5. Log the security events
When a token is refused or a policy says no, the operator needs to know why; the client only learns "401" or "403". Replace `JwtSetup.cs` (the new part is `OnAuthenticationFailed`, which logs the **type** of the exception, such as `SecurityTokenExpiredException`, never the token) and `ProblemAuthorizationHandler.cs` (a warning with user id, method, path and reason).

**File: `src/TasksApi/Security/JwtSetup.cs`**
```csharp
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using TasksApi.Common;

namespace TasksApi.Security;

public sealed class AuthOptions
{
    public string Issuer { get; init; } = "";
    public string MetadataAddress { get; init; } = "";
    public string Audience { get; init; } = "tasks-api";
    public bool RequireHttpsMetadata { get; init; } = true;
}

public static class JwtSetup
{
    // Validates Keycloak access tokens: signature (keys fetched and cached from the discovery document), issuer, audience, lifetime.
    public static IServiceCollection AddKeycloakJwt(this IServiceCollection services, IConfiguration configuration)
    {
        var auth = configuration.GetSection("Auth").Get<AuthOptions>() ?? new AuthOptions();
        services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(options =>
        {
            options.MetadataAddress = auth.MetadataAddress;
            options.RequireHttpsMetadata = auth.RequireHttpsMetadata;
            options.MapInboundClaims = false;
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidIssuer = auth.Issuer,
                ValidateAudience = true,
                ValidAudience = auth.Audience,
                ValidateLifetime = true,
                RequireExpirationTime = true,
                ClockSkew = TimeSpan.FromSeconds(30),
                RequireSignedTokens = true,
                ValidateIssuerSigningKey = true,
                ValidAlgorithms = [SecurityAlgorithms.RsaSha256],
            };
            options.Events = new JwtBearerEvents
            {
                // JwtBearer also trusts the issuer written in the discovery document. We want exactly the configured one.
                OnTokenValidated = context =>
                {
                    if (context.Principal?.FindFirstValue("iss") != auth.Issuer)
                    {
                        context.Fail("The token issuer is not the configured issuer.");
                    }
                    return Task.CompletedTask;
                },
                // Logs why a token was refused (expired, wrong audience, ...) by exception type only; never the token itself.
                OnAuthenticationFailed = context =>
                {
                    context.HttpContext.RequestServices.GetRequiredService<ILoggerFactory>().CreateLogger("TasksApi.Auth")
                        .LogWarning("Access token rejected: {Reason}", context.Exception.GetType().Name);
                    return Task.CompletedTask;
                },
                OnChallenge = async context =>
                {
                    context.HandleResponse();
                    var invalid = context.AuthenticateFailure is not null;
                    context.Response.Headers.WWWAuthenticate = invalid
                        ? "Bearer realm=\"tasksteams\", error=\"invalid_token\""
                        : "Bearer realm=\"tasksteams\"";
                    await ProblemResponses.WriteAsync(context.HttpContext, StatusCodes.Status401Unauthorized,
                        invalid ? "The access token is invalid or has expired." : "A bearer access token is required.");
                },
            };
        });
        return services;
    }
}
```

**File: `src/TasksApi/Security/ProblemAuthorizationHandler.cs`**
```csharp
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authorization.Policy;
using TasksApi.Common;

namespace TasksApi.Security;

// Writes the 403 as a problem that says which scope or role was missing. A 401 is left to the default handler,
// which asks the JWT scheme to challenge (see OnChallenge in JwtSetup).
public sealed class ProblemAuthorizationHandler(ILogger<ProblemAuthorizationHandler> logger) : IAuthorizationMiddlewareResultHandler
{
    private readonly AuthorizationMiddlewareResultHandler _default = new();

    public async Task HandleAsync(RequestDelegate next, HttpContext context, AuthorizationPolicy policy,
        PolicyAuthorizationResult result)
    {
        if (result.Forbidden)
        {
            var reason = result.AuthorizationFailure?.FailureReasons.FirstOrDefault()?.Message
                         ?? "You are not allowed to do this.";
            logger.LogWarning("Access denied for user {UserId} on {Method} {Path}: {Reason}",
                context.User.FindFirstValue("sub"), context.Request.Method, context.Request.Path.Value, reason);
            await ProblemResponses.WriteAsync(context, StatusCodes.Status403Forbidden, reason);
            return;
        }
        await _default.HandleAsync(next, context, policy, result);
    }
}
```

A body larger than the limit makes Kestrel throw `BadHttpRequestException` with status 413. The exception handler gets a clear text for it:

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
            await ProblemResponses.WriteAsync(context, bad.StatusCode,
                bad.StatusCode == StatusCodes.Status413PayloadTooLarge
                    ? "The request body is larger than the 1 MB limit."
                    : "The request could not be read.");
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

### Step 6. Configuration: limits, CORS, allowed hosts
Replace `src/TasksApi/appsettings.json`. `RateLimit` holds the numbers of requirement R-14 (100 per minute for a user, 30 for an anonymous address). `Cors.Origins` lists the browser origins that may call the API. `AllowedHosts` makes the server answer only for those `Host` header values: `localhost` and `127.0.0.1` (port numbers are ignored); add the names your deployment uses.

**File: `src/TasksApi/appsettings.json`**
```json
{
  "Urls": "http://127.0.0.1:8000",
  "ConnectionStrings": {
    "Default": "Host=127.0.0.1;Port=5432;Database=tasksteams;Username=tasks_app;Password=tasks_app_local_only;Timeout=5"
  },
  "Auth": {
    "Issuer": "http://localhost:8180/realms/tasksteams",
    "MetadataAddress": "http://127.0.0.1:8180/realms/tasksteams/.well-known/openid-configuration",
    "Audience": "tasks-api",
    "RequireHttpsMetadata": false
  },
  "RateLimit": {
    "AuthenticatedLimit": 100,
    "AnonymousLimit": 30,
    "WindowSeconds": 60
  },
  "Cors": {
    "Origins": [ "http://localhost:4200", "http://localhost:5173" ]
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning",
      "Microsoft.AspNetCore.DataProtection": "Error",
      "Microsoft.EntityFrameworkCore": "Critical"
    }
  },
  "AllowedHosts": "localhost;127.0.0.1"
}
```

### Step 7. `Program.cs`
Replace it. New: JSON logging, Kestrel limits, the options and `TimeProvider`, the CORS policy and four middleware in the pipeline. The order matters and is explained in "How it works".

**File: `src/TasksApi/Program.cs`**
```csharp
using System.Security.Claims;
using System.Text.Json.Serialization;
using FastEndpoints;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Data;
using TasksApi.Security;

var builder = WebApplication.CreateBuilder(args);

// Logs as one JSON object per line, easy for a log collector to read. Request logging adds the user id and trace id.
builder.Logging.ClearProviders();
builder.Logging.AddJsonConsole();

// Limits that stop one client from using all the server's memory or connections (OWASP API4).
builder.WebHost.ConfigureKestrel(kestrel =>
{
    kestrel.AddServerHeader = false;
    kestrel.Limits.MaxRequestBodySize = 1_048_576;
    kestrel.Limits.MaxRequestHeadersTotalSize = 32 * 1024;
    kestrel.Limits.RequestHeadersTimeout = TimeSpan.FromSeconds(15);
});

builder.Services.AddDbContext<TasksDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("Default")));

builder.Services.AddHttpContextAccessor();
// FastEndpoints creates every endpoint once at startup, when there is no request yet, so the user may be missing here.
builder.Services.AddScoped(services =>
    CurrentUser.From(services.GetRequiredService<IHttpContextAccessor>().HttpContext?.User ?? new ClaimsPrincipal()));
builder.Services.AddScoped<TeamAccess>();
builder.Services.AddScoped<Idempotency>();

builder.Services.AddKeycloakJwt(builder.Configuration);
builder.Services.AddAuthorization(AccessPolicies.Add);
builder.Services.AddSingleton<IAuthorizationHandler, TokenRequirementHandler>();
builder.Services.AddSingleton<IAuthorizationMiddlewareResultHandler, ProblemAuthorizationHandler>();

builder.Services.Configure<RateLimitOptions>(builder.Configuration.GetSection("RateLimit"));
builder.Services.AddSingleton(TimeProvider.System);

// Only the two local web clients may call the API from a browser.
builder.Services.AddCors(cors => cors.AddDefaultPolicy(policy => policy
    .WithOrigins(builder.Configuration.GetSection("Cors:Origins").Get<string[]>() ?? [])
    .WithMethods("GET", "POST", "PUT", "PATCH", "DELETE")
    .WithHeaders("Authorization", "Content-Type", "If-Match", "If-None-Match", "Idempotency-Key")
    .WithExposedHeaders("ETag", "Location", "RateLimit-Limit", "RateLimit-Remaining", "RateLimit-Reset", "Retry-After",
        "Idempotent-Replayed")));

builder.Services.AddFastEndpoints();
builder.Services.AddExceptionHandler<ProblemExceptionHandler>();
builder.Services.AddProblemDetails();

var app = builder.Build();

app.UseMiddleware<RequestLoggingMiddleware>();
app.UseExceptionHandler();
app.UseStatusCodePages(ProblemResponses.WriteStatusCodeAsync);
app.UseMiddleware<SecurityHeadersMiddleware>();
app.UseCors();
app.UseAuthentication();
app.UseMiddleware<RateLimitMiddleware>();
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

### Step 8. The Docker files, unchanged
They are part of the project at this point and repeated so this chapter's pack is complete. Nothing changes in them.

**File: `Dockerfile`**
```dockerfile
# syntax=docker/dockerfile:1

# Stage 1: build with the SDK image (compiler, NuGet, about 1 GB). Nothing from this stage ships except the published output.
FROM mcr.microsoft.com/dotnet/sdk:11.0.100-alpine3.24 AS build
WORKDIR /src

# Restore first, on its own layer: it only re-runs when the project file or the SDK pin changes.
COPY global.json ./
COPY src/TasksApi/TasksApi.csproj src/TasksApi/
RUN dotnet restore src/TasksApi/TasksApi.csproj

COPY src/TasksApi/ src/TasksApi/
RUN dotnet publish src/TasksApi/TasksApi.csproj -c Release --no-restore -o /app/publish /p:UseAppHost=false

# Stage 2: run on the small ASP.NET runtime image (no SDK, no compiler, no shell tools beyond Alpine's busybox).
FROM mcr.microsoft.com/dotnet/aspnet:11.0.0-alpine3.24 AS runtime
WORKDIR /app
COPY --from=build /app/publish ./

# Listen on all interfaces inside the container; Compose decides what the host can reach (127.0.0.1:8000 only).
# The key is Urls, the same key appsettings.json uses: a setting in appsettings.json beats ASPNETCORE_URLS.
ENV Urls=http://0.0.0.0:8000 \
    DOTNET_EnableDiagnostics=0
EXPOSE 8000

# The base image defines the unprivileged user "app" and sets APP_UID; never run the service as root.
USER $APP_UID
ENTRYPOINT ["dotnet", "TasksApi.dll"]
```

**File: `docker-compose.override.yml`**
```yaml
services:
  api:
    build:
      context: .
    image: code101/tasksteams-backend-dotnet:1.0
    environment:
      ConnectionStrings__Default: "Host=db;Port=5432;Database=${POSTGRES_DB};Username=tasks_app;Password=${TASKS_APP_PASSWORD};Timeout=5"
      Auth__Issuer: "http://localhost:${KEYCLOAK_PORT:-8180}/realms/tasksteams"
      Auth__MetadataAddress: "http://keycloak:8080/realms/tasksteams/.well-known/openid-configuration"
      Auth__RequireHttpsMetadata: "false"
    ports:
      - "127.0.0.1:${API_PORT:-8000}:8000"
    depends_on:
      db:
        condition: service_healthy
      keycloak:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "-q", "-O", "/dev/null", "http://127.0.0.1:8000/health"]
      interval: 5s
      timeout: 3s
      retries: 12
      start_period: 5s
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    restart: unless-stopped
    networks:
      - tasksteams
```

**File: `.env.example`**
```text
# Disposable local practice only. Never reuse these values for a real system.
POSTGRES_DB=tasksteams
POSTGRES_USER=tasks_admin
POSTGRES_PASSWORD=tasks_admin_local_only
POSTGRES_PORT=5432
KEYCLOAK_ADMIN=kcadmin
KEYCLOAK_ADMIN_PASSWORD=kcadmin_local_only
KEYCLOAK_PORT=8180
TASKS_NETWORK=tasksteams-net
API_PORT=8000
TASKS_APP_PASSWORD=tasks_app_local_only
```

Every other file is unchanged from the earlier chapters and is not shown again. The two ignore files are shown below so you can check your copies; they are the files of chapters 04 and 01.

#### `.dockerignore` and `.gitignore` of this chapter (unchanged)
Both files keep secrets and build output out of places they must not go: `.dockerignore` out of the image build context, `.gitignore` out of Git.

<details>
<summary><code>.dockerignore</code> (same as chapter 04)</summary>

**File: `.dockerignore`**
```text
**/bin/
**/obj/
.env
.git
.gitignore
*.md
Dockerfile
docker-compose*.yml
db/
keycloak/
scripts/
openapi.yaml
```

- `**/bin/` and `**/obj/`: build output in any folder. The image builds its own inside the `build` stage; sending yours would shadow it and slow the upload.
- `.env`: the local secrets file must never enter the build context, so it can never end up in an image layer.
- `.git`: the repository history (it can contain old secrets) is not needed to build.
- `.gitignore`, `*.md`, `Dockerfile`, `docker-compose*.yml`: files that only matter to Git, to readers or to Compose, not to the compiled service.
- `db/`, `keycloak/`, `scripts/`: the database scripts, the realm file and the helper scripts belong to the platform stack, not to the API image.
- `openapi.yaml`: the contract is documentation here; the API does not read it at run time.
</details>

<details>
<summary><code>.gitignore</code> (same as chapter 01)</summary>

**File: `.gitignore`**
```text
bin/
obj/
.env
```

- `bin/`: compiled output; rebuilt on every machine.
- `obj/`: intermediate build files with machine-specific paths.
- `.env`: your local settings. It is never committed; `.env.example` is the committed template.

`.git` itself is never listed: Git does not track its own folder.
</details>

## Run it
Folder: `05-hardening/code`.
```powershell
Copy-Item .env.example .env
docker compose -p backend up -d --build --wait
python scripts/conformance.py
```
On macOS and Linux use `cp .env.example .env`. Expected output of the conformance script (ids differ):
```text
PASS  keycloak discovery (issuer matches, PKCE S256 offered)
PASS  token for alice (iss, aud tasks-api, sub, role admin, three scopes)
PASS  token for bob (role member only)
PASS  postgres reachable (127.0.0.1:5432 answers the Postgres protocol)
PASS  health (200, status ok, no token needed)
PASS  me (alice is admin, RateLimit headers present)
PASS  create team (201, Location and ETag set, team de49014c-dd3c-457b-ad5f-5df74d01d952)
PASS  create project (201, project 01a20786-9b98-7afa-8297-32dc00e1f297)
PASS  create task with Idempotency-Key (created once, replay returned the same task, other body gave 422)
PASS  get task with ETag (ETag "1", If-None-Match gave 304)
PASS  update with If-Match (200, version 1 -> 2)
PASS  stale If-Match gives 412 (stale If-Match gave 412, missing If-Match gave 428)
PASS  cursor pagination (2 + 1 tasks, no overlap, last page has nextCursor null)
PASS  401 without token (401 problem details with a Bearer challenge)
PASS  403 for member on admin route (bob (member) gets 403 on the audit log and on creating a team)
PASS  problem details shape (422 with errors[/name], 404 with type, title and status)
PASS  audit log (task create and update are in the audit trail)
PASS  cleanup (team deleted, then 404)
18 passed, 0 failed
```
All 18 checks pass: this backend is conformant with the platform contract. The conformance script is checked by the lab on every run; the other outputs below come from a real run, and the lab checks their key lines (status lines and headers); ids, dates, trace ids and the `RateLimit-Remaining` numbers differ on your machine. Now look at what you added.

**Health first.** The route is still public and still reports the database:
```powershell
curl.exe -s http://127.0.0.1:8000/health
```
Expected output:
```text
{"status":"ok","version":"1.0.0","database":"up"}
```

**Headers on an anonymous call** (30 requests per minute for an address; the answer is a 401, and it still carries every protective header):
```powershell
curl.exe -s -i http://127.0.0.1:8000/v1/me
```
Expected output:
```text
HTTP/1.1 401 Unauthorized
Content-Type: application/problem+json
Date: Mon, 23 Nov 2026 09:40:31 GMT
Cache-Control: no-store
Transfer-Encoding: chunked
WWW-Authenticate: Bearer realm="tasksteams"
RateLimit-Limit: 30
RateLimit-Remaining: 29
RateLimit-Reset: 60
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
Referrer-Policy: no-referrer

{"type":"https://code101.example/problems/unauthorized","title":"Unauthorized","status":401,"detail":"A bearer access token is required.","instance":"/v1/me","traceId":"9b75d5fd719322dfc6d77966333830b5"}
```
There is no `Server` header any more. **Signed in** the limit is 100:
```powershell
python scripts/call.py --as bob GET /v1/me
```
Expected output:
```text
HTTP 200 OK
RateLimit-Limit: 100
RateLimit-Remaining: 99
RateLimit-Reset: 60
Content-Type: application/json; charset=utf-8

{"id":"b0b00000-0000-4000-8000-000000000002","username":"bob","email":"bob@tasksteams.test","displayName":"Bob Member","roles":["member"],"scopes":["email","openid","profile","tasks:admin","tasks:read","tasks:write"],"teams":[{"teamId":"7ea00000-0000-4000-8000-000000000002","name":"Mobile Team","role":"member"},{"teamId":"7ea00000-0000-4000-8000-000000000001","name":"Platform Team","role":"member"}]}
```
**A token that is not a token.** The API refuses it with a 401, still counts the call, and logs why (the type of the failure, never the token):
```powershell
python scripts/call.py --token abc.def.ghi GET /v1/teams
```
Expected output:
```text
HTTP 401 Unauthorized
RateLimit-Limit: 30
RateLimit-Remaining: 29
RateLimit-Reset: 60
WWW-Authenticate: Bearer realm="tasksteams", error="invalid_token"
Content-Type: application/problem+json

{"type":"https://code101.example/problems/unauthorized","title":"Unauthorized","status":401,"detail":"The access token is invalid or has expired.","instance":"/v1/teams","traceId":"76bb9cd076eaf8f509727b89a57c4ac0"}
```
**The 429.** Call an endpoint more often than 30 times in one minute without a token. The counter also counted the anonymous calls you made a moment ago (the conformance script makes one), so the first 429 comes at call 28 to 31, not exactly at the 31st. In PowerShell:
```powershell
1..31 | ForEach-Object { curl.exe -s -o NUL -w "$_ %{http_code}`n" http://127.0.0.1:8000/v1/me } | Select-Object -Last 3
curl.exe -s -i http://127.0.0.1:8000/v1/me
```
(On macOS and Linux: `for i in $(seq 1 31); do curl -s -o /dev/null -w "$i %{http_code}\n" http://127.0.0.1:8000/v1/me; done | tail -3`.) Expected output: the last calls are 429, and the answer says when to come back (the `Retry-After` seconds):
```text
29 429
30 429
31 429
```
```text
HTTP/1.1 429 Too Many Requests
Content-Type: application/problem+json
Date: Mon, 23 Nov 2026 09:40:32 GMT
Cache-Control: no-store
Retry-After: 59
Transfer-Encoding: chunked
RateLimit-Limit: 30
RateLimit-Remaining: 0
RateLimit-Reset: 59
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
Referrer-Policy: no-referrer

{"type":"https://code101.example/problems/rate-limited","title":"Too many requests","status":429,"detail":"Too many requests. Try again in 59 seconds.","instance":"/v1/me","traceId":"4fae8fdfd4539e9bd3337fb79348a0ea"}
```
`/health` is exempt, so Docker and load balancers are never throttled:
```powershell
curl.exe -s http://127.0.0.1:8000/health
```
Expected output:
```text
{"status":"ok","version":"1.0.0","database":"up"}
```
**The size limit.** Make a 1.2 MB JSON body and send it as alice (the helper's `--body-file` sends a file):
```powershell
python -c "import json; print(json.dumps({'name': 'x' * 1200000}))" | Set-Content big.json -Encoding ascii
python scripts/call.py --as alice POST /v1/teams --body-file big.json
Remove-Item big.json
```
On macOS and Linux redirect with `> big.json` and remove with `rm big.json`. Expected output:
```text
HTTP 413 Payload Too Large
RateLimit-Limit: 100
RateLimit-Remaining: 99
RateLimit-Reset: 60
Content-Type: application/problem+json

{"type":"https://code101.example/problems/payload-too-large","title":"Payload too large","status":413,"detail":"The request body is larger than the 1 MB limit.","instance":"/v1/teams","traceId":"74dc2f39d46924265f9c848e07c903a7"}
```
**CORS.** A browser first asks (a "preflight" `OPTIONS` request) whether its origin may call the API. The allowed origin gets the `Access-Control-Allow-*` headers; any other origin gets none, and the browser then refuses to send the real request:
```powershell
curl.exe -s -i -X OPTIONS http://127.0.0.1:8000/v1/teams -H "Origin: http://localhost:4200" -H "Access-Control-Request-Method: GET"
curl.exe -s -i -X OPTIONS http://127.0.0.1:8000/v1/teams -H "Origin: http://evil.example" -H "Access-Control-Request-Method: GET"
```
Expected output of the first call, then of the second (it has no `Access-Control-...` header):
```text
HTTP/1.1 204 No Content
Date: Mon, 23 Nov 2026 09:40:33 GMT
Access-Control-Allow-Headers: Authorization,Content-Type,If-Match,If-None-Match,Idempotency-Key
Access-Control-Allow-Methods: GET,POST,PUT,PATCH,DELETE
Access-Control-Allow-Origin: http://localhost:4200
Cache-Control: no-store
Vary: Origin
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
Referrer-Policy: no-referrer
```
```text
HTTP/1.1 204 No Content
Date: Mon, 23 Nov 2026 09:40:33 GMT
Cache-Control: no-store
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
Referrer-Policy: no-referrer
```
**A wrong `Host` header** is refused before any of our code runs (`AllowedHosts`):
```powershell
curl.exe -s -i http://127.0.0.1:8000/health -H "Host: evil.example"
```
Expected output:
```text
HTTP/1.1 400 Bad Request
Content-Length: 334
Content-Type: text/html
Date: Mon, 23 Nov 2026 09:40:33 GMT

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN""http://www.w3.org/TR/html4/strict.dtd">
<HTML><HEAD><TITLE>Bad Request</TITLE>
<META HTTP-EQUIV="Content-Type" Content="text/html; charset=us-ascii"></ HEAD >
<BODY><h2>Bad Request - Invalid Hostname</h2>
<hr><p>HTTP Error 400. The request hostname is invalid.</p>
</BODY></HTML>
```
**The log.** One JSON object per line. Request lines carry the user id (`-` for an anonymous call) and the trace id (the same `traceId` the client got in the problem) and never a token. Warnings explain refusals:
```powershell
docker compose -p backend logs api --no-log-prefix --tail 400
```
Expected lines among the output (shortened to the `Message`; each is a full JSON object with `State` fields):
```text
{"EventId":0,"LogLevel":"Warning","Category":"TasksApi.Auth","Message":"Access token rejected: ArgumentException",...}
{"EventId":0,"LogLevel":"Warning","Category":"TasksApi.Security.ProblemAuthorizationHandler","Message":"Access denied for user b0b00000-0000-4000-8000-000000000002 on GET /v1/audit-log: The \u0027admin\u0027 role is required.",...}
{"EventId":0,"LogLevel":"Warning","Category":"TasksApi.Security.RateLimitMiddleware","Message":"Rate limit exceeded for ip:172.18.0.1 on GET /v1/me",...}
{"EventId":0,"LogLevel":"Information","Category":"TasksApi.Common.RequestLoggingMiddleware","Message":"GET /v1/me 401 0ms user=- trace=e762056a2992b13efcf5e6e031179a46",...}
{"EventId":0,"LogLevel":"Information","Category":"TasksApi.Common.RequestLoggingMiddleware","Message":"GET /v1/me 200 430ms user=b0b00000-0000-4000-8000-000000000002 trace=9b6e58bc5ff9decc4ad3c8f4acfc4059",...}
{"EventId":0,"LogLevel":"Information","Category":"TasksApi.Common.RequestLoggingMiddleware","Message":"POST /v1/teams 413 23ms user=a11ce000-0000-4000-8000-000000000001 trace=74dc2f39d46924265f9c848e07c903a7",...}
{"EventId":0,"LogLevel":"Information","Category":"TasksApi.Common.RequestLoggingMiddleware","Message":"GET /v1/audit-log 403 1ms user=b0b00000-0000-4000-8000-000000000002 trace=00375e7687dfd9177f0137ee3c9fc951",...}
```
The first warning is the garbage token `abc.def.ghi` we sent to `/v1/teams`; the second is bob on the audit log (the same text the client got in the 403). Notice the address `172.18.0.1` in the rate-limit line: inside Docker, the API sees the bridge gateway, not your real address (see "How it works").

**Dependencies.** Known-vulnerable packages are a risk of their own (OWASP also lists it under API8). This check needs the .NET SDK on the host. Check both directions:
```powershell
cd src/TasksApi
dotnet list package --vulnerable --include-transitive
dotnet list package --outdated
```
Expected output of each on 2026-11-23 (the first lines `Determining projects to restore...` are left out; the second answer changes as soon as a newer package version is published, then it lists the updates):
```text
The given project `TasksApi` has no vulnerable packages given the current sources.
```
```text
The given project `TasksApi` has no updates given the current sources.
```
Clean up:
```powershell
cd ../..
docker compose -p backend down -v --remove-orphans
docker image rm code101/tasksteams-backend-dotnet:1.0
```
Expected output ends with:
```text
 Volume backend_pg_data Removed
 Network tasksteams-net Removed
Untagged: code101/tasksteams-backend-dotnet:1.0
```

## How it works
**The pipeline order** is a security design. The numbers are the order a request meets the steps:

| # | Middleware | Why here |
|---|------------|----------|
| 1 | request logging | outermost: it sees the final status of every request, including errors and 429 |
| 2 | exception handler | catches what the steps below throw; turns it into a problem |
| 3 | status code pages | gives bodiless 404, 405, 415 a problem body |
| 4 | security headers | headers on every answer, set with `OnStarting` so the exception handler cannot clear them |
| 5 | CORS | answers browser preflight requests early, before authentication (a preflight carries no token) |
| 6 | authentication | reads the token, sets the user |
| 7 | rate limit | after authentication so it counts per user; before authorization so refused calls count too |
| 8 | authorization | scope and role policies |
| 9 | user provisioning | creates the `users` row for a new user |
| 10 | endpoint | binds, validates, handles |

**Why not the built-in rate limiter?** ASP.NET Core ships `AddRateLimiter`. It is good at refusing, but it cannot tell the client how many requests are left or when the window ends on a successful request, and the contract wants `RateLimit-Remaining` and `RateLimit-Reset` on every answer. The class here is a fixed window per key held in a dictionary, with a lock per counter and a sweep every 1000 requests that forgets old windows. Its limits are honest ones:

| Limit | What it means | Production answer |
|-------|---------------|-------------------|
| In memory | Each API instance counts alone, so N instances allow N times the limit; a restart resets all counters | a shared store (Redis) or the gateway in front |
| Fixed window | A caller can send the limit at the end of one window and again at the start of the next (twice the rate for a moment) | a sliding window or token bucket |
| Key by client address when anonymous | Behind a reverse proxy every anonymous caller shares the proxy's address (here `172.18.0.1`) | configure forwarded headers with the proxy's address, then key on the real client |

**CORS** is a browser rule, not a security feature of the server: it stops *other web pages* from reading your API's answers with the visitor's credentials. Curl and mobile apps ignore it. That is why the exact origin list is short and the allowed methods and headers are listed one by one (no `*`).

**Logging.** Structured JSON lines (`AddJsonConsole`) can be read by any log collector. The trace id in the line equals the `traceId` in the problem document, so a customer's error report finds the line. What is never logged: the `Authorization` header, request bodies, query strings (a search term can be personal data) and exception messages of rejected tokens. The database audit trail (`audit_log`) records who changed what; the application log records who called what and what was refused.

**Production checklist** (what this local setup does not do):

| Item | Local lab | Real deployment |
|------|-----------|-----------------|
| TLS | plain http on loopback | terminate https at a reverse proxy (Caddy, Nginx, a cloud load balancer); then HSTS is sent and `RequireHttpsMetadata` must be `true` |
| Secrets | fake values in `.env` and `appsettings.json` | injected by a secret store; never in the image or in Git |
| Keycloak | `start-dev`, http | production mode with a hostname, https and a real database |
| Rate limit store | memory | shared |
| Dependencies | `dotnet list package --vulnerable` by hand | run in CI on every change; add image scanning |
| Backups | none | scheduled `pg_dump` or the database service's backups, with a restore test |
| Alerts | log lines | alerts on bursts of 401, 403 and 429 |

## Try it
Add a `Permissions-Policy` header that switches off browser features this API never uses. The starter is `SecurityHeadersMiddleware.cs` with a TODO comment; the solution adds one line.

1. Replace your `Security/SecurityHeadersMiddleware.cs` with the starter and follow the TODO.
2. Check that it compiles: in `src/TasksApi` run `dotnet build --nologo`. Expected output:
   ```text
     Determining projects to restore...
     All projects are up-to-date for restore.
     TasksApi -> F:\...\code\src\TasksApi\bin\Debug\net11.0\TasksApi.dll

   Build succeeded.
       0 Warning(s)
       0 Error(s)
   ```
3. Rebuild the image (`docker compose -p backend up -d --build --wait`) and look for the header: `curl.exe -s -i http://127.0.0.1:8000/health`.

Starter:

**File: `exercise/starter/src/TasksApi/Security/SecurityHeadersMiddleware.cs`**
```csharp
namespace TasksApi.Security;

// Adds the browser-facing protections to every response, including errors (OnStarting runs when the response begins).
public sealed class SecurityHeadersMiddleware(RequestDelegate next)
{
    public Task InvokeAsync(HttpContext context)
    {
        context.Response.OnStarting(() =>
        {
            var headers = context.Response.Headers;
            headers.XContentTypeOptions = "nosniff";
            headers.XFrameOptions = "DENY";
            headers.ContentSecurityPolicy = "default-src 'none'; frame-ancestors 'none'";
            headers["Referrer-Policy"] = "no-referrer";
            headers.CacheControl = "no-store";
            // TODO: also send  Permissions-Policy: geolocation=(), camera=(), microphone=()
            //       so a browser never lets this origin use those features.
            if (context.Request.IsHttps)
            {
                headers.StrictTransportSecurity = "max-age=31536000; includeSubDomains";
            }
            return Task.CompletedTask;
        });
        return next(context);
    }
}
```

<details><summary>Solution</summary>

**File: `exercise/solution/src/TasksApi/Security/SecurityHeadersMiddleware.cs`**
```csharp
namespace TasksApi.Security;

// Adds the browser-facing protections to every response, including errors (OnStarting runs when the response begins).
public sealed class SecurityHeadersMiddleware(RequestDelegate next)
{
    public Task InvokeAsync(HttpContext context)
    {
        context.Response.OnStarting(() =>
        {
            var headers = context.Response.Headers;
            headers.XContentTypeOptions = "nosniff";
            headers.XFrameOptions = "DENY";
            headers.ContentSecurityPolicy = "default-src 'none'; frame-ancestors 'none'";
            headers["Referrer-Policy"] = "no-referrer";
            headers.CacheControl = "no-store";
            headers["Permissions-Policy"] = "geolocation=(), camera=(), microphone=()";
            if (context.Request.IsHttps)
            {
                headers.StrictTransportSecurity = "max-age=31536000; includeSubDomains";
            }
            return Task.CompletedTask;
        });
        return next(context);
    }
}
```

The answer to `/health` now contains `Permissions-Policy: geolocation=(), camera=(), microphone=()`. An empty list `()` means "no origin may use this feature".

</details>

## Check yourself
1. Why is the rate limiter placed after authentication and before authorization? <details><summary>Answer</summary>After authentication so it can count per user instead of per address; before authorization so that refused (401, 403) requests also count, which limits password-guessing and probing.</details>
2. Why does `/health` skip the limiter? <details><summary>Answer</summary>Probes run every few seconds from the same address; throttling them would make a healthy service look dead and trigger restarts.</details>
3. A customer reports a failing call and sends the `traceId` of the error. What do you do? <details><summary>Answer</summary>Search the log for `trace=<that id>`: the request line has the method, path, status, time and user id.</details>
4. Why does the log write the path but not the query string? <details><summary>Answer</summary>Query strings carry search terms and filters that can be personal data or secrets; the path identifies the operation well enough.</details>
5. Which OWASP risk does the `limit` maximum of 100 answer? <details><summary>Answer</summary>API4, unrestricted resource consumption: one request cannot ask for an unbounded list.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `git status` lists `.env`, `bin/` or `obj/` as new files, or `docker history` shows secrets in a layer | `.gitignore` or `.dockerignore` is missing, or created after the files were already tracked or copied | Create both files as shown above; for files already tracked run `git rm --cached .env` (and `git rm -r --cached bin obj`), commit, and replace any real secret that was ever committed |
| `HTTP Error 400. The request hostname is invalid.` (a small HTML page, not a problem document) | `AllowedHosts` does not list the `Host` value of the request | Add the name to `AllowedHosts` (`localhost;127.0.0.1;api`, or the environment variable `AllowedHosts`) |
| A browser app says the request is blocked by CORS, and the preflight answer has no `Access-Control-Allow-Origin` | The page's origin is not in `Cors:Origins` (a different port counts as a different origin) | Add the exact origin, for example `http://localhost:4200`; no trailing slash, no wildcard |
| `HTTP 413 Payload Too Large` for a JSON file you thought was small | The limit is 1 MB (`MaxRequestBodySize`) | Send less, or raise the limit consciously for one endpoint |
| `HTTP 429 Too Many Requests` while testing from a script | More than 100 calls a minute for a user, or 30 for an anonymous address | Wait for `Retry-After` seconds; do not raise limits to fit a test script |
| All anonymous callers behind a proxy get 429 together | The limiter keys on the proxy's address | Configure forwarded headers (and `KnownProxies`), then key on the real address |
| The request log shows `user=-` | The call had no valid token | Expected for `/health`, 401 and CORS preflight |
| `docker compose` reports `The "TASKS_APP_PASSWORD" variable is not set. Defaulting to a blank string.` | `.env` is missing or old | `Copy-Item .env.example .env` |

## Best practice
Treat limits and logging as part of the API, test them like any feature, and write the threat you are answering next to each control (the table in step 1). Source: [OWASP API Security Top 10 2023](https://owasp.org/API-Security/editions/2023/en/0x11-t10/); [ASP.NET Core security overview](https://learn.microsoft.com/aspnet/core/security/); [Best practices for ASP.NET Core](https://learn.microsoft.com/aspnet/core/fundamentals/best-practices); [OWASP REST Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html); [RFC 6585 (429 Too Many Requests)](https://www.rfc-editor.org/info/rfc6585).

## Next lesson
This was the last chapter of the capstone. Next: pick a client capstone (`web-angular` or `web-react`), or run the same conformance script against another backend and compare how each language does the same job.
