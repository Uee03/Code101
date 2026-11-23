---
track: capstone
level: 201
phase: 3
phase_name: identity
lesson: 03
title: "Keycloak tokens, scopes and roles"
time: 90 min
prerequisites: [capstone-backend-dotnet-02, capstone-platform-03]
versions: { dotnet_sdk: "11.0.100", jwtbearer: "11.0.0", keycloak_image: "quay.io/keycloak/keycloak:26.8.2" }
verified: 2026-11-23 on Windows 11, .NET SDK 11.0.100, Docker 29.9.3, Compose 5.7.0, Python 3.15.2
source: capstones/backend-dotnet/source/phase-3-identity/03-identity/
assets: []
---

# 03. Keycloak tokens, scopes and roles

## Why it matters
A concert hall checks three different things at the door: the ticket is real (not forged), it is for tonight's show (not last week's) and for this hall (not another one). Then inside, an usher decides which seats and which backstage doors that ticket may use. A bearer access token is the ticket. The API must check the **signature, the issuer, the audience and the expiry** before it believes a single claim, and then apply two separate permission layers: what the *token* allows (scopes) and what the *user* is (roles and team membership). Getting this wrong is how APIs end up with "any signed-in user can read every team" (OWASP API1, API2 and API5).

## What you will build
Real token validation with `Microsoft.AspNetCore.Authentication.JwtBearer` against the platform's Keycloak realm: keys fetched once from the discovery document and cached, `RS256` only, issuer and audience checked, 30 seconds of clock skew. 401 and 403 problem documents that say what is missing. The stand-in identity of chapter 2 is deleted. Nothing else changes: the endpoints already asked for policies and the current user from the claims, so this chapter is mostly configuration.

Conformance after this chapter: **17 passed, 1 failed**. The only failing check is `me`, which wants the `RateLimit-*` headers of chapter 5.

## Before you start
- Chapter 02 done or its pack unzipped. The `code` folder holds the whole project and the platform files (not shown again: they are unchanged).
- Docker running, Python 3.10+, .NET SDK 11.0.100 or newer, ports 5432, 8180 and 8000 free.
- Source pack: unzip `backend-dotnet-phase-3-identity.zip` and open `03-identity/code`.

New terms (see the [glossary](../../GLOSSARY.md)): **bearer token**, **JWT**, **claim**, **audience**, **authorization policy**.

## Steps
### Step 1. Start Postgres and Keycloak
Folder: the solution folder (`code`). Skip the `.env` command if you still have the file from chapter 02; a pack unzipped fresh has none, and without it Postgres starts with an empty password and `--wait` fails.
```powershell
Copy-Item .env.example .env
docker compose -p bdn up -d --wait
```
On macOS and Linux use `cp .env.example .env`. Expected output ends with `Container bdn-db-1 Healthy` and `Container bdn-keycloak-1 Healthy`.

### Step 2. What is inside an access token
First a small helper that asks Keycloak for a token and prints its parts. A JWT is three base64url pieces separated by dots: header, claims, signature. The script decodes the first two; **it does not check the signature, so never use it as a validator**. Create `scripts/show_token.py`:

**File: `scripts/show_token.py`**
```python
#!/usr/bin/env python3
"""Show what is inside an access token. For learning only: it does not check the signature.

  python scripts/show_token.py bob

It asks Keycloak for a token (fake local password, client tasks-smoke) and prints the header and the claims.
"""
import base64
import json
import os
import sys
import urllib.parse
import urllib.request

KEYCLOAK_URL = os.environ.get("KEYCLOAK_URL", "http://127.0.0.1:8180")
PASSWORDS = {"alice": "alice-local-fake", "bob": "bob-local-fake", "carol": "carol-local-fake"}


def decode(part):
    return json.loads(base64.urlsafe_b64decode(part + "=" * (-len(part) % 4)))


def main():
    user = sys.argv[1] if len(sys.argv) > 1 else "alice"
    form = urllib.parse.urlencode({"grant_type": "password", "client_id": "tasks-smoke", "username": user,
                                   "password": PASSWORDS[user], "scope": "openid tasks:read tasks:write"}).encode()
    request = urllib.request.Request(f"{KEYCLOAK_URL}/realms/tasksteams/protocol/openid-connect/token", data=form)
    with urllib.request.urlopen(request, timeout=15) as response:
        token = json.load(response)["access_token"]
    header, claims, _signature = token.split(".")
    print("header:", json.dumps(decode(header)))
    for name, value in decode(claims).items():
        print(f"{name}: {json.dumps(value)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

Run it for bob:
```powershell
python scripts/show_token.py bob
```
Expected output (the times, `jti` and `sid` differ):
```text
header: {"alg": "RS256", "typ": "JWT", "kid": "wA7T4bhqQjUtI0I3m6OMR1Wmv6VS40wsfrGz-8OE9Lw"}
exp: 1795425761
iat: 1795425461
jti: "onrtro:5cb6aecb-0d5b-71b6-ce24-67ca6cb24312"
iss: "http://localhost:8180/realms/tasksteams"
aud: "tasks-api"
sub: "b0b00000-0000-4000-8000-000000000002"
typ: "Bearer"
azp: "tasks-smoke"
sid: "CcD62Y-hSs1vrBRQgvtwFfRz"
realm_access: {"roles": ["member"]}
scope: "openid tasks:write profile tasks:read tasks:admin email"
email_verified: true
name: "Bob Member"
preferred_username: "bob"
email: "bob@tasksteams.test"
```
Read it like a ticket: `alg` and `kid` say how it was signed and with which key; `iss` is who issued it; `aud` is the API it is for (a string here; with several audiences it becomes a list, and the API accepts both); `exp` is the expiry as seconds since 1970 (5 minutes after `iat`); `sub` is the user id, which is also `users.id` in the database; `realm_access.roles` holds bob's role `member`; `scope` lists what the client may do. Notice that bob's token **has** the scope `tasks:admin`: the smoke client was granted all three scopes. That is why "bob may not read the audit log" must be decided by his **role**, not only by the scope.

| Claim | Used for |
|-------|----------|
| `iss`, `aud`, `exp`, signature | validated by the JWT middleware before the request goes on |
| `sub` | `CurrentUser.Id`; the actor written to the audit trail |
| `scope` | policies: `tasks:read`, `tasks:write`, `tasks:admin` |
| `realm_access.roles` | policies and `TeamAccess`: `admin` or `member` |
| `preferred_username`, `email`, `name` | creating the `users` row on first use |

### Step 3. Add the JWT bearer package
Folder: the solution folder (`code`).
```powershell
cd src/TasksApi
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer --version 11.0.0
cd ../..
```
Expected result: `info : PackageReference for package 'Microsoft.AspNetCore.Authentication.JwtBearer' version '11.0.0' added to file '...TasksApi.csproj'.` The project file now has four packages:

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
    <PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="11.0.0" />
    <PackageReference Include="Microsoft.EntityFrameworkCore" Version="11.0.0" />
    <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="11.0.0" />
  </ItemGroup>

</Project>
```

### Step 4. Configuration: where to trust tokens from
Replace `src/TasksApi/appsettings.json`. Two addresses name the same realm on purpose. `Issuer` is the text the token carries in `iss`; Keycloak writes `http://localhost:8180/realms/tasksteams` because the platform sets `KC_HOSTNAME`. `MetadataAddress` is where **this process** can reach Keycloak to fetch the discovery document and the signing keys: `127.0.0.1:8180` on your host, `keycloak:8080` inside Docker (chapter 4). `RequireHttpsMetadata` is `false` only because the local Keycloak speaks plain http; a real deployment uses https and `true`.

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

### Step 5. The JWT setup
`JwtSetup.AddKeycloakJwt` registers the bearer scheme. Read the validation parameters one by one: each line closes one attack. `ValidAlgorithms` accepts only `RS256`, so a token claiming `alg: none` or a symmetric algorithm is rejected. `MapInboundClaims = false` keeps the claim names exactly as Keycloak writes them (`sub`, not a long Microsoft URI). `OnTokenValidated` adds one more rule: JwtBearer also trusts the issuer named in the discovery document, so we compare `iss` with exactly the configured value. `OnChallenge` runs when authentication is required but missing or failed; it writes the 401 problem and the `WWW-Authenticate` header, with `error="invalid_token"` only when a token was sent but refused.

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

### Step 6. The 403 handler
When the user is signed in but a policy fails, the default behaviour is an empty 403. `ProblemAuthorizationHandler` replaces it with the problem document, and uses the failure reason our `TokenRequirementHandler` recorded (for example "The 'admin' role is required.").

**File: `src/TasksApi/Security/ProblemAuthorizationHandler.cs`**
```csharp
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authorization.Policy;
using TasksApi.Common;

namespace TasksApi.Security;

// Writes the 403 as a problem that says which scope or role was missing. A 401 is left to the default handler,
// which asks the JWT scheme to challenge (see OnChallenge in JwtSetup).
public sealed class ProblemAuthorizationHandler : IAuthorizationMiddlewareResultHandler
{
    private readonly AuthorizationMiddlewareResultHandler _default = new();

    public async Task HandleAsync(RequestDelegate next, HttpContext context, AuthorizationPolicy policy,
        PolicyAuthorizationResult result)
    {
        if (result.Forbidden)
        {
            var reason = result.AuthorizationFailure?.FailureReasons.FirstOrDefault()?.Message
                         ?? "You are not allowed to do this.";
            await ProblemResponses.WriteAsync(context, StatusCodes.Status403Forbidden, reason);
            return;
        }
        await _default.HandleAsync(next, context, policy, result);
    }
}
```

### Step 7. `Program.cs`
Delete `src/TasksApi/Security/DevAuthenticationHandler.cs`, then replace `Program.cs`. The three authentication lines of chapter 2 become `AddKeycloakJwt` plus the result handler; the pipeline is unchanged (`UseAuthentication` before `UseAuthorization`).
```powershell
Remove-Item src/TasksApi/Security/DevAuthenticationHandler.cs
```
On macOS and Linux: `rm src/TasksApi/Security/DevAuthenticationHandler.cs`.

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

Every other file of chapter 02 is unchanged, including `Security/AccessPolicies.cs` and `Security/TeamAccess.cs`, the two files that decide what a valid token may do. They are not shown again; the lesson checker skips them.

#### The `.gitignore` of this chapter (unchanged from chapter 01)
Your `.env` now also holds the Keycloak settings, so it must stay out of Git. The `.gitignore` is the same file as in chapter 01; it is shown again so you can check your copy.

<details>
<summary><code>.gitignore</code> (same as chapter 01)</summary>

**File: `.gitignore`**
```text
bin/
obj/
.env
```

- `bin/`: compiled output (`dotnet build` writes it); rebuilt on every machine.
- `obj/`: intermediate build files and restore data with machine-specific paths.
- `.env`: your local settings and (in real projects) secrets. It is never committed; `.env.example` is the template that is.

`.git` itself is never listed: Git does not track its own folder.
</details>

## Run it
Build and start the API (the stack from step 1 is running). Folder: the solution folder (`code`):
```powershell
cd src/TasksApi
dotnet build --nologo
dotnet run
```
Expected output of the build (a first build also restores the packages):
```text
  Determining projects to restore...
  All projects are up-to-date for restore.
  TasksApi -> F:\...\code\src\TasksApi\bin\Debug\net11.0\TasksApi.dll

Build succeeded.
    0 Warning(s)
    0 Error(s)

Time Elapsed 00:00:00.50
```
Open a second terminal in the solution folder and check the health route, then run the conformance script:
```powershell
curl.exe -s http://127.0.0.1:8000/health
```
Expected output:
```text
{"status":"ok","version":"1.0.0","database":"up"}
```
```powershell
python scripts/conformance.py
```
Expected output (ids differ):
```text
PASS  keycloak discovery (issuer matches, PKCE S256 offered)
PASS  token for alice (iss, aud tasks-api, sub, role admin, three scopes)
PASS  token for bob (role member only)
PASS  postgres reachable (127.0.0.1:5432 answers the Postgres protocol)
PASS  health (200, status ok, no token needed)
FAIL  me: header RateLimit-Limit missing or not a number
PASS  create team (201, Location and ETag set, team bc6529aa-14da-4dd7-946f-86fa7dc258e6)
PASS  create project (201, project 01a20783-c669-7231-af94-1c814839109b)
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
17 passed, 1 failed
```
The three checks that failed in chapter 02 now pass, and the `me` header check is the one left. Now try the permission layers by hand. The helper `--as bob` signs in first.

**No token.** A 401 with a Bearer challenge:
```powershell
python scripts/call.py GET /v1/me
```
Expected output:
```text
HTTP 401 Unauthorized
WWW-Authenticate: Bearer realm="tasksteams"
Content-Type: application/problem+json

{"type":"https://code101.example/problems/unauthorized","title":"Unauthorized","status":401,"detail":"A bearer access token is required.","instance":"/v1/me","traceId":"306228463a98a65235f565c6f338e87e"}
```
**Bob, a member.** He may see his two teams, but not the admin-only routes (403 with the reason), and he may not create a project because only leads (and admins) do (403 from `TeamAccess`):
```powershell
python scripts/call.py --as bob GET /v1/me
python scripts/call.py --as bob GET /v1/audit-log
python scripts/call.py --as bob POST /v1/teams/7ea00000-0000-4000-8000-000000000001/projects key=BOB name="Not allowed"
```
Expected output:
```text
HTTP 200 OK
Content-Type: application/json; charset=utf-8

{"id":"b0b00000-0000-4000-8000-000000000002","username":"bob","email":"bob@tasksteams.test","displayName":"Bob Member","roles":["member"],"scopes":["email","openid","profile","tasks:admin","tasks:read","tasks:write"],"teams":[{"teamId":"7ea00000-0000-4000-8000-000000000002","name":"Mobile Team","role":"member"},{"teamId":"7ea00000-0000-4000-8000-000000000001","name":"Platform Team","role":"member"}]}
```
```text
HTTP 403 Forbidden
Content-Type: application/problem+json

{"type":"https://code101.example/problems/forbidden","title":"Forbidden","status":403,"detail":"The 'admin' role is required.","instance":"/v1/audit-log","traceId":"ed4c52176a8e62ed48206d9f6f7a37c5"}
```
```text
HTTP 403 Forbidden
Content-Type: application/problem+json

{"type":"https://code101.example/problems/forbidden","title":"Forbidden","status":403,"detail":"Only a team lead or an admin can do this.","instance":"/v1/teams/7ea00000-0000-4000-8000-000000000001/projects","traceId":"8aab0617420067b231b159ac23f761f7"}
```
**A team bob does not belong to is invisible (404, not 403).** The admin creates a team that has only alice as a member; bob asks for it by id:
```powershell
python scripts/call.py --as alice POST /v1/teams name="Secret Team" --idempotency-key secret-team-0001
python scripts/call.py --as bob GET /v1/teams/b90c92af-b60b-4a12-9b38-99692cdb4e1b
python scripts/call.py --as alice GET /v1/teams/b90c92af-b60b-4a12-9b38-99692cdb4e1b
```
Expected output (use the id of *your* team in the second and third command):
```text
HTTP 201 Created
ETag: "1"
Location: http://127.0.0.1:8000/v1/teams/b90c92af-b60b-4a12-9b38-99692cdb4e1b
Content-Type: application/json; charset=utf-8

{"id":"b90c92af-b60b-4a12-9b38-99692cdb4e1b","name":"Secret Team","description":"","memberCount":1,"createdBy":"a11ce000-0000-4000-8000-000000000001","version":1,"createdAt":"2026-11-23T09:17:43.029994+00:00","updatedAt":"2026-11-23T09:17:43.029994+00:00"}
```
```text
HTTP 404 Not Found
Content-Type: application/problem+json

{"type":"https://code101.example/problems/not-found","title":"Not found","status":404,"detail":"Team was not found.","instance":"/v1/teams/b90c92af-b60b-4a12-9b38-99692cdb4e1b","traceId":"4a901814f762297ea9379d86ba4d2839"}
```
```text
HTTP 200 OK
ETag: "1"
Content-Type: application/json; charset=utf-8

{"id":"b90c92af-b60b-4a12-9b38-99692cdb4e1b","name":"Secret Team","description":"","memberCount":1,"createdBy":"a11ce000-0000-4000-8000-000000000001","version":1,"createdAt":"2026-11-23T09:17:43.029994+00:00","updatedAt":"2026-11-23T09:17:43.029994+00:00"}
```
Alice, an admin who is not even a member, may see it. Delete it again: `python scripts/call.py --as alice DELETE /v1/teams/<id>` answers `HTTP 204 No Content`.

**A team lead.** Carol leads the Mobile Team, so she may reassign its tasks; bob, a plain member, may not (the second command is bob trying the same operation):
```powershell
python scripts/call.py --as carol POST /v1/tasks/7a500000-0000-4000-8000-000000000007/reassign assigneeId=b0b00000-0000-4000-8000-000000000002 --if-match 1
python scripts/call.py --as bob POST /v1/tasks/7a500000-0000-4000-8000-000000000007/reassign assigneeId=null --if-match 2
```
Expected output (the task answer is shortened to the first part; carol's call changes the assignee and the version to 2, bob's call is refused):
```text
HTTP 200 OK
ETag: "2"
Content-Type: application/json; charset=utf-8

{"id":"7a500000-0000-4000-8000-000000000007","projectId":"9a000000-0000-4000-8000-000000000003","title":"Sign in with PKCE","description":"Authorization code flow on a phone.","status":"in_progress","priority":"high","assigneeId":"b0b00000-0000-4000-8000-000000000002","dueDate":"2027-02-12","completedAt":null,"createdBy":"ca401000-0000-4000-8000-000000000003","version":2,"createdAt":"2026-11-23T09:17:12.718451+00:00","updatedAt":"2026-11-23T09:17:44.636648+00:00"}
```
```text
HTTP 403 Forbidden
Content-Type: application/problem+json

{"type":"https://code101.example/problems/forbidden","title":"Forbidden","status":403,"detail":"Only a team lead or an admin can do this.","instance":"/v1/tasks/7a500000-0000-4000-8000-000000000007/reassign","traceId":"c996eb1ab9e07bb268fe8b748dd5c8ed"}
```
**A refused token.** Stop the API (Ctrl+C) and start it again with the wrong audience and the authentication log turned on (the default level hides these lines). Bob's perfectly good token is now for the wrong API:
```powershell
${env:Auth__Audience} = "other-api"
${env:Logging__LogLevel__Microsoft.AspNetCore.Authentication} = "Information"
dotnet run
```
On macOS and Linux write the two variables in front of the command: `Auth__Audience=other-api Logging__LogLevel__Microsoft.AspNetCore.Authentication=Information dotnet run`. In the second terminal:
```powershell
python scripts/call.py --as bob GET /v1/me
```
Expected output, and the matching log lines:
```text
HTTP 401 Unauthorized
WWW-Authenticate: Bearer realm="tasksteams", error="invalid_token"
Content-Type: application/problem+json

{"type":"https://code101.example/problems/unauthorized","title":"Unauthorized","status":401,"detail":"The access token is invalid or has expired.","instance":"/v1/me","traceId":"effa76db4ded763661558b972a4e68fa"}
```
```text
Microsoft.IdentityModel.Tokens.SecurityTokenInvalidAudienceException: IDX10214: Audience validation failed. See https://aka.ms/identitymodel/app-context-switches
Bearer was not authenticated. Failure message: IDX10214: Audience validation failed. See https://aka.ms/identitymodel/app-context-switches
```
The client only learns "invalid token"; the reason is for the operator, in the log. Stop the API with Ctrl+C, remove the two variables (`Remove-Item env:Auth__Audience`, `Remove-Item "env:Logging__LogLevel__Microsoft.AspNetCore.Authentication"`) and remove the stack:
```powershell
docker compose -p bdn down -v --remove-orphans
```

## How it works
A signed-in request travels like this.

1. **Authentication middleware.** `UseAuthentication` finds `Authorization: Bearer <token>` and asks the JWT bearer handler to validate it. The first token triggers one download of the discovery document from `MetadataAddress` and of the signing keys it points to; the keys are cached, and an unknown `kid` makes the handler refresh them (key rotation). Validation checks the signature with the key named by `kid`, then `iss`, `aud`, `exp` and `nbf` with 30 seconds of skew. A token that fails is not an error page: the request simply continues as anonymous and the next step decides.
2. **Authorization middleware.** Each endpoint named a policy in `Configure()` (`Policies(AccessPolicies.Write)`). `TokenRequirementHandler` reads the claims with `CurrentUser.From`, and records `Fail(reason)` for a missing scope or role. Anonymous requests fail the policy's `RequireAuthenticatedUser()` first: that is a **challenge**, answered by `OnChallenge` as 401. An authenticated request that fails a requirement is **forbidden**: `ProblemAuthorizationHandler` answers 403 with the recorded reason.
3. **User provisioning.** After authorization `UserProvisioningMiddleware` makes sure the `users` row exists (the Keycloak `sub`, `preferred_username`, `email`, `name`).
4. **The endpoint.** It builds on `CurrentUser` (id, roles, scopes) and `TeamAccess` (membership), as in chapter 02.

Status codes, in the order the checks happen:

| Check | Fails with | Example |
|-------|-----------|---------|
| Token present and valid | 401 | no header, expired, wrong audience, wrong issuer, wrong signature |
| Scope and realm role of the policy | 403 | bob on `GET /v1/audit-log` |
| The caller can see the team | 404 | bob asks for a team he is not in |
| The caller has the team level the operation needs | 403 | bob creates a project (leads only) |
| Request is valid, state allows it | 400, 409, 412, 422, 428 | chapter 02 |

Scopes versus roles. A **scope** limits what the *client application* may do on the user's behalf; a **role** says what the *user* is. The effective permission is the intersection: the audit log needs the scope `tasks:admin` **and** the role `admin`. Bob's smoke token holds the scope, and he is still refused. Never decide permissions on a scope alone, and never on a role alone for a client that should be limited.

Why validate locally and not ask Keycloak on every request:

| Decision | Alternatives | Consequence |
|----------|--------------|-------------|
| Local JWT validation with cached keys | Token introspection call per request | No network hop per request; a revoked token stays valid until it expires (5 minutes here) |
| `RS256` only | Accept whatever the header says | Prevents algorithm confusion attacks such as `alg: none` |
| Audience check (`tasks-api`) | Trust any token from our realm | A token issued for another API of the same realm cannot be replayed here |
| Own issuer comparison in `OnTokenValidated` | Rely on `ValidIssuer` only | JwtBearer also accepts the issuer of the discovery document; the extra check keeps the contract's "iss must equal the configured issuer" exact |
| Roles from `realm_access` | Keycloak groups; client roles | The platform realm defines realm roles `admin` and `member` |

Authentik appendix (identity provider alternative, same code): replace `Auth:MetadataAddress` with the application's OpenID configuration URL (`http://<authentik>/application/o/<slug>/.well-known/openid-configuration`), `Auth:Issuer` with its `issuer` value, and `Auth:Audience` with the provider's client id; Authentik puts groups in a `groups` claim instead of `realm_access.roles`, so `CurrentUser.RealmRoles` would read `groups`. Nothing else in the API changes.

## Try it
Add `GET /v1/me/permissions` which tells the caller what the token allows, without touching the database: `{"id": "...", "isAdmin": false, "canWrite": true}`. The starter is an endpoint with empty methods.

1. Copy `exercise/starter/src/TasksApi/Features/Platform/PermissionsEndpoint.cs` into `Features/Platform` and follow the TODO.
2. Restart the API and call `python scripts/call.py --as bob GET /v1/me/permissions`. Expected: `isAdmin` false, `canWrite` true. For alice `isAdmin` is true.

Starter:

**File: `exercise/starter/src/TasksApi/Features/Platform/PermissionsEndpoint.cs`**
```csharp
using FastEndpoints;
using TasksApi.Security;

namespace TasksApi.Features.Platform;

public sealed record PermissionsResponse(Guid Id, bool IsAdmin, bool CanWrite);

// TODO: GET /v1/me/permissions tells the caller what the token allows, without a database call.
//   1. Configure(): Get the route above and require the Read policy (AccessPolicies.Read).
//   2. HandleAsync(): answer with user.Id, user.IsAdmin and whether user.Scopes contains "tasks:write".
public sealed class PermissionsEndpoint(CurrentUser user) : EndpointWithoutRequest<PermissionsResponse>
{
    public override void Configure()
    {
    }

    public override Task HandleAsync(CancellationToken ct) => Task.CompletedTask;
}
```

<details><summary>Solution</summary>

**File: `exercise/solution/src/TasksApi/Features/Platform/PermissionsEndpoint.cs`**
```csharp
using FastEndpoints;
using TasksApi.Security;

namespace TasksApi.Features.Platform;

public sealed record PermissionsResponse(Guid Id, bool IsAdmin, bool CanWrite);

// GET /v1/me/permissions: answered from the token's claims alone.
public sealed class PermissionsEndpoint(CurrentUser user) : EndpointWithoutRequest<PermissionsResponse>
{
    public override void Configure()
    {
        Get("/v1/me/permissions");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(CancellationToken ct) =>
        await Send.OkAsync(new PermissionsResponse(user.Id, user.IsAdmin, user.Scopes.Contains("tasks:write")), ct);
}
```

`CurrentUser` is injected through the constructor: it is built from the claims of the request, which is why no database call is needed. `Policies(AccessPolicies.Read)` makes the framework answer 401 and 403 before this code runs.

</details>

## Check yourself
1. A valid token for bob has the scope `tasks:admin`. Why does `GET /v1/audit-log` still answer 403? <details><summary>Answer</summary>The `AdminOnly` policy needs the scope **and** the realm role `admin`. Bob's role is `member`; the intersection is empty.</details>
2. Why does the API fetch keys from `http://127.0.0.1:8180` but compare `iss` with `http://localhost:8180/realms/tasksteams`? <details><summary>Answer</summary>The issuer is the name Keycloak writes into tokens (its configured hostname); the metadata address is only the route this process uses to reach Keycloak. They are different strings for the same server, especially inside Docker.</details>
3. What is the difference between a 401 and a 403 here? <details><summary>Answer</summary>401: the API does not know who you are (no or invalid token). 403: it knows you, and you may not do this.</details>
4. Why `ValidAlgorithms = [RS256]`? <details><summary>Answer</summary>A token's header says how it was signed. If the API believed the header, an attacker could choose a weak or no algorithm. The API decides which algorithm it accepts.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `git status` lists `.env`, `bin/` or `obj/` as new files, or a password appears in a commit | `.gitignore` is missing, or it was created after the files were already tracked | Create the `.gitignore` shown above; for files already tracked run `git rm --cached .env` (and `git rm -r --cached bin obj`), commit, and replace any real secret that was ever committed |
| Every request is a 500; the log says `System.InvalidOperationException: The MetadataAddress or Authority must use HTTPS unless disabled for development by setting RequireHttpsMetadata=false.` | `RequireHttpsMetadata` is `true` (the default) and `MetadataAddress` is an http address | Use an https address in production; locally set `Auth:RequireHttpsMetadata` to `false` |
| 401 with `WWW-Authenticate: ... error="invalid_token"` and the log says `IDX10214: Audience validation failed.` | The token was issued for another API; `Auth:Audience` does not appear in its `aud` | Request the token with the audience mapper of the `tasks-api-audience` scope (the realm already does this), or fix `Auth:Audience` |
| 401, and the log says `Bearer was not authenticated. Failure message: The token issuer is not the configured issuer.` | `Auth:Issuer` is not exactly the `iss` of the token (for example `127.0.0.1` instead of `localhost`) | Copy the `iss` value from `python scripts/show_token.py`; Keycloak writes its configured hostname |
| 401, and the log says `IDX10500: Signature validation failed. No security keys were provided to validate the signature.` | The API cannot reach Keycloak at `Auth:MetadataAddress`, so it has no keys | Check the address from the API's own point of view (`127.0.0.1:8180` on the host, `keycloak:8080` in Docker) and that Keycloak is healthy |

## Best practice
Validate tokens locally with a pinned algorithm, check issuer, audience and expiry, keep tokens out of logs, and give each operation the smallest scope and role it needs. Source: [RFC 8725 JSON Web Token Best Current Practices](https://www.rfc-editor.org/info/rfc8725); [RFC 9068 JWT Profile for OAuth 2.0 Access Tokens](https://www.rfc-editor.org/info/rfc9068); [ASP.NET Core authentication overview](https://learn.microsoft.com/aspnet/core/security/authentication/); [OWASP API Security Top 10 2023, API2 Broken Authentication](https://owasp.org/API-Security/editions/2023/en/0x11-t10/).

## Next lesson
04. Run and ship: put the API in a multi-stage Docker image that runs as a non-root user, add it to the platform stack with a Compose override on the network `tasksteams-net`, publish it on `127.0.0.1:8000` with a health check, and run the same conformance script against the container.
