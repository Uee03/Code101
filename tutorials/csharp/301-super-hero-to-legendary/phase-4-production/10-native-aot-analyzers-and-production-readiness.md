---
track: csharp
level: 301
phase: 4
phase_name: production
lesson: 10
title: "Native AOT, analyzers, EditorConfig and a production readiness review"
time: 90-120 min
prerequisites: [csharp 301.4.09, csharp 301.3.08, csharp 201.2.05, docker 101.1.03]
versions: { dotnet_sdk: "11.0.100", target_framework: "net11.0", sdk_image: "mcr.microsoft.com/dotnet/sdk:11.0.100-alpine3.24", runtime_deps_image: "mcr.microsoft.com/dotnet/runtime-deps:11.0.0-alpine3.24" }
verified: not yet run
source: source/csharp/301-super-hero-to-legendary/phase-4-production/10-native-aot-analyzers-and-production-readiness/
assets: []
---

# 10. Native AOT, analyzers, EditorConfig and a production readiness review

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- Publish a minimal API with Native AOT, say what you gain and lose, and list the measurements that decide whether it is worth it.
- Make the compiler enforce team rules with `Directory.Build.props`, analyzers and `.editorconfig`.
- Build and run a hardened container (non-root, read-only, no capabilities, health check) for an AOT service.
- Review a service against a production checklist and rank findings by severity.

## Recap
1. (Lesson 08) Which signal tells you *where* time went in a slow request?
   <details><summary>Answer</summary>A trace: a tree of timed spans across the services involved.</details>
2. (Lesson 09) Why does a valid signature not make a service call authorized?
   <details><summary>Answer</summary>Signature proves who issued the token. Audience says the token is meant for this service, and a role or scope says the caller may perform this operation.</details>

## Why it matters
Most production incidents come from things that were never about the algorithm: a secret in an image, a missing timeout, a container running as root, an analyzer warning someone ignored, a dependency with a known vulnerability. This lesson is the "last mile": make the build reject known-bad code automatically, shrink and harden what you ship, and review the whole service with a checklist so that "ready" is a decision with evidence.

## What you will build
A small `Inventory.Api` (two endpoints) configured for **Native AOT**, with team-wide build rules in `Directory.Build.props` and `.editorconfig`, a multi-stage `Dockerfile`, a locked-down `docker-compose.yml`, and a `PRODUCTION-CHECKLIST.md`. Then you review a deliberately flawed service and rank its problems.

## Before you start
- **Prerequisites:** C# 301 lessons [08, observability with OpenTelemetry](../phase-3-resilience-and-messaging/08-observability-with-opentelemetry.md) and [09, modular monolith to microservices](09-modular-monolith-to-microservices.md); [C# 201 lesson 05, first ASP.NET Core API](../../201-hero-to-super-hero/phase-2-web-apis/05-first-aspnet-core-api.md); [Docker 101 lesson 03, your first Dockerfile](../../../docker/101-zero-to-hero/phase-1-containers/03-your-first-dockerfile.md).
- Tools: .NET SDK **11.0.100**; Docker with Compose for the container part; `curl`. For a **local** Native AOT publish you also need the C++ toolchain for your OS (Windows: Visual Studio with the "Desktop development with C++" workload; Linux: `clang`; macOS: Xcode command line tools). See the Native AOT prerequisites page linked in Going further. The Docker route needs none of that on your machine.
- Time: 90-120 minutes in two sittings; break after Step 8. A first AOT publish takes noticeably longer than a normal build.
- Ports: **5310** (local run) and **8310** (container).
- Folder: create `lesson10` as in lesson 01 Step 1 (only `lesson10`, plus `src\Inventory.Api` inside it).
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/csharp/301-super-hero-to-legendary/phase-4-production/10-native-aot-analyzers-and-production-readiness/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

## Steps
### Step 1. Create the folder and pin the SDK
PowerShell: `mkdir $HOME\code101\csharp301\lesson10\src\Inventory.Api` then `cd $HOME\code101\csharp301\lesson10`. bash or zsh: `mkdir -p ~/code101/csharp301/lesson10/src/Inventory.Api && cd ~/code101/csharp301/lesson10`. Every command below runs in `lesson10`.

**File: `global.json`**
```json
{
  "sdk": {
    "rollForward": "latestFeature",
    "version": "11.0.100"
  }
}
```
The same pin as lesson 01. The Dockerfile copies it too, so the SDK in the image and the SDK on your machine must agree.

### Step 2. Team build rules for every project
**File: `Directory.Build.props`**
```xml
<Project>

  <PropertyGroup>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <LangVersion>latest</LangVersion>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <AnalysisLevel>latest-recommended</AnalysisLevel>
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
    <InvariantGlobalization>true</InvariantGlobalization>
    <Deterministic>true</Deterministic>
    <NuGetAuditMode>all</NuGetAuditMode>
  </PropertyGroup>

</Project>
```
MSBuild reads a file named `Directory.Build.props` from the project's folder or any parent and applies it to **every project below it**, so rules live in one place. Line by line:
- `Nullable` and `ImplicitUsings`: the settings every project in this course uses.
- `TreatWarningsAsErrors`: a warning that does not fail the build is a suggestion that will be ignored within a month. The cost is that upgrading the SDK or a package can break the build on new warnings; that is a feature, if you budget time for it.
- `AnalysisLevel` `latest-recommended`: enables the .NET code analysis rules that Microsoft recommends as warnings, for the **latest** analyzer set. Use a fixed version such as `11.0-recommended` if you want upgrades to be a separate decision.
- `EnforceCodeStyleInBuild`: makes the `IDE...` style rules (naming, namespaces, usings) run during `dotnet build`, not only in the editor. Without it, style violations pass CI and appear only on some machines.
- `InvariantGlobalization`: no ICU culture data; smaller image and no culture surprises (do not use it if you need real culture-specific formatting or sorting).
- `Deterministic`: the compiler produces the same bytes for the same inputs, which is a basis for reproducible builds.
- `NuGetAuditMode` `all`: NuGet's built-in vulnerability audit also checks **transitive** packages during restore and reports them as warnings (NU1901 to NU1904). Combined with `TreatWarningsAsErrors`, a known-vulnerable dependency fails the build.

### Step 3. Style and analyzer severities
**File: `.editorconfig`**
```text
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
indent_style = space
indent_size = 4
trim_trailing_whitespace = true

[*.{csproj,props,json,yml,yaml}]
indent_size = 2

[*.cs]
csharp_style_namespace_declarations = file_scoped:warning
csharp_style_var_for_built_in_types = true:suggestion
dotnet_sort_system_directives_first = true

# Analyzer severities: raise the few rules that matter to this team and silence the ones that do not apply.
# CA2007 (ConfigureAwait) is noise in ASP.NET Core, which has no synchronization context.
dotnet_diagnostic.CA2007.severity = none
dotnet_diagnostic.CA1852.severity = warning
dotnet_diagnostic.CA2016.severity = warning
dotnet_analyzer_diagnostic.category-Security.severity = warning
```
An `.editorconfig` applies to the editor, `dotnet format` and the compiler's analyzers. Read it top to bottom:
- `root = true` stops the search for settings in parent folders.
- The `[*]` block is about text files: UTF-8, LF line endings, a final newline, spaces, no trailing whitespace. These stop whitespace-only diffs. (Git can normalize line endings too; pick one mechanism.)
- `[*.cs]` rules: `file_scoped:warning` means a block-scoped `namespace X { }` is a **warning**, which `TreatWarningsAsErrors` turns into a build error. A `:suggestion` suffix only shows a hint in the editor.
- `dotnet_diagnostic.<ID>.severity` sets one rule: `CA2007` off, `CA1852` (seal types that are not inherited) and `CA2016` (forward the `CancellationToken` you received) as warnings. These two are cheap wins: sealed classes are faster to call and easier to reason about; a dropped token turns cancellation and timeouts into no-ops.
- `dotnet_analyzer_diagnostic.category-Security.severity = warning` raises **every** security-category rule at once.
A rule that nobody can explain in a sentence does not belong here; each severity should have a reason in a comment or a pull request.

### Step 4. The AOT project
**File: `src/Inventory.Api/Inventory.Api.csproj`**
```xml
<Project Sdk="Microsoft.NET.Sdk.Web">

  <PropertyGroup>
    <TargetFramework>net11.0</TargetFramework>
    <PublishAot>true</PublishAot>
  </PropertyGroup>

</Project>
```
Everything else comes from `Directory.Build.props`. `PublishAot` does two things: it makes `dotnet publish` compile to a native executable, and (importantly) it turns on the **AOT and trimming analyzers** during ordinary builds, so incompatible code is flagged while you write it. With `TreatWarningsAsErrors`, such warnings stop the build. There are no package references: nothing to patch or audit.

### Step 5. The program
**File: `src/Inventory.Api/Program.cs`**
```csharp
using System.Text.Json.Serialization;

var builder = WebApplication.CreateSlimBuilder(args);

// Native AOT cannot generate serialization code at run time, so the serializer uses code generated at build time.
builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.TypeInfoResolverChain.Insert(0, AppJsonContext.Default);
});

var app = builder.Build();

var stock = new Dictionary<int, StockItem>
{
    [1] = new(1, "Pen", 120),
    [2] = new(2, "Cup", 0),
};

// Liveness: the process answers. Do not check dependencies here, or one outage restarts every instance.
app.MapGet("/healthz", () => Results.Text("ok"));

app.MapGet("/stock/{id:int}", (int id) =>
    stock.TryGetValue(id, out var item) ? Results.Ok(item) : Results.NotFound());

app.Run();

public sealed record StockItem(int Id, string Name, int Quantity);

[JsonSourceGenerationOptions(PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase)]
[JsonSerializable(typeof(StockItem))]
internal sealed partial class AppJsonContext : JsonSerializerContext
{
}
```
What changes compared with an ordinary minimal API:
- `CreateSlimBuilder` creates the host with only the essential features (configuration, logging, Kestrel without HTTPS or HTTP/3 by default). HTTPS is normally terminated at a proxy or ingress in container deployments.
- **JSON source generation.** The default `System.Text.Json` path uses reflection at run time, which Native AOT cannot rely on. `AppJsonContext` is a **context** whose members the compiler's source generator writes at build time for the types listed in `[JsonSerializable]`. You insert it first in `TypeInfoResolverChain` so the framework finds your types there. `PropertyNamingPolicy` is set in the attribute so the output is `camelCase` at build time, independent of runtime options. Every type you return or accept must be listed; a missing one fails at run time with an exception about missing type information, not at build time.
- The health endpoint is **liveness** only. A readiness endpoint, which checks dependencies, is a separate concern and decides whether traffic is sent to an instance.
- The `stock` dictionary is read-only after startup, so it is safe to share between requests.

### Step 6. Local settings
**File: `src/Inventory.Api/appsettings.json`**
```json
{
  "Urls": "http://127.0.0.1:5310",
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "localhost;127.0.0.1"
}
```
### Step 7. The Dockerfile
**File: `Dockerfile`**
```dockerfile
# syntax=docker/dockerfile:1

# Stage 1: the SDK image plus the C toolchain that Native AOT needs to link the executable.
FROM mcr.microsoft.com/dotnet/sdk:11.0.100-alpine3.24 AS build
RUN apk add --no-cache clang build-base zlib-dev
WORKDIR /src

# Restore first, on its own layer: it only re-runs when the project, the SDK pin or the build settings change.
COPY global.json Directory.Build.props .editorconfig ./
COPY src/Inventory.Api/Inventory.Api.csproj src/Inventory.Api/
RUN dotnet restore src/Inventory.Api/Inventory.Api.csproj -r linux-musl-x64

COPY src/Inventory.Api/ src/Inventory.Api/
RUN dotnet publish src/Inventory.Api/Inventory.Api.csproj -c Release -r linux-musl-x64 --no-restore -o /app/publish

# Stage 2: only what a native executable needs to run (musl libc and a few libraries; no .NET runtime, no SDK).
FROM mcr.microsoft.com/dotnet/runtime-deps:11.0.0-alpine3.24 AS runtime
WORKDIR /app
COPY --from=build /app/publish/Inventory.Api ./

# Listen on all interfaces inside the container; Compose decides what the host can reach.
ENV Urls=http://0.0.0.0:8080
EXPOSE 8080

# The base image defines the unprivileged user "app" and sets APP_UID; never run the service as root.
USER $APP_UID
ENTRYPOINT ["./Inventory.Api"]
```
Line by line:
- `FROM ...sdk:11.0.100-alpine3.24 AS build`: the SDK image, with the exact SDK patch that `global.json` pins, on Alpine Linux (musl libc). Always use exact tags you have checked exist; if a tag is not found, look up the current tag on the Microsoft Container Registry and keep the SDK and the runtime on the same Alpine version.
- `RUN apk add --no-cache clang build-base zlib-dev`: Native AOT links with the system C toolchain (this is the Alpine package list from the Microsoft documentation). `--no-cache` keeps the layer small. This only exists in the build stage and never ships.
- `COPY global.json Directory.Build.props .editorconfig ./` before the project: your build rules must be present at restore and build time, or the container build would be **less strict** than your local build.
- `RUN dotnet restore ... -r linux-musl-x64`: restores for the target runtime identifier (RID). `linux-musl-x64` is the RID for Alpine on x86-64; on an ARM host use `linux-musl-arm64`. A native binary only runs on the platform and C library it was built for.
- `dotnet publish ... --no-restore`: the AOT compile (the slow step). The output folder holds the native executable `Inventory.Api` and the `appsettings.json`.
- `FROM ...runtime-deps:11.0.0-alpine3.24 AS runtime`: the base image with only the native libraries a .NET app needs and **no .NET runtime**. The image is small because the runtime is inside your executable. Check that this tag exists for your version.
- `COPY --from=build /app/publish/Inventory.Api ./`: copies **only the executable**. `appsettings.json` is intentionally not copied: the container is configured through environment variables, and a file compiled into the image cannot be changed without a rebuild.
- `ENV Urls=http://0.0.0.0:8080`: listen on all interfaces **inside** the container. A configuration value named `Urls` overrides the file setting, which is why the file could not stay.
- `USER $APP_UID`: the base image defines a non-root user and sets the `APP_UID` variable; running as root inside the container makes a container escape much worse.
- `ENTRYPOINT ["./Inventory.Api"]` in the exec form (JSON array) so the process receives signals directly and can shut down gracefully.

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
```
The ignore file keeps build output, local secrets (`.env`), version-control data, documentation and the Docker files themselves out of the build context. A smaller context builds faster and cannot leak what it never receives.

### Step 8. The hardened compose file
**File: `docker-compose.yml`**
```yaml
services:
  inventory:
    build:
      context: .
    image: inventory-api:local
    ports:
      - "127.0.0.1:8310:8080"
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    mem_limit: 128m
    pids_limit: 100
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "-q", "-O", "-", "http://127.0.0.1:8080/healthz"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
```
Line by line:
- `build.context: .` builds the image from the `Dockerfile` in this folder; `image: inventory-api:local` names the result.
- `ports: "127.0.0.1:8310:8080"`: host loopback port 8310 maps to container port 8080. Without `127.0.0.1:` every machine that can reach your host could call the service.
- `read_only: true` makes the container's root file system read-only, so a compromised process cannot drop files or change the binary. `tmpfs: /tmp` gives it a small in-memory writable folder, because some libraries need one.
- `cap_drop: ALL` removes all Linux capabilities (the fine-grained root powers); this service needs none. `no-new-privileges` stops a process from gaining privileges through setuid binaries.
- `mem_limit: 128m` and `pids_limit: 100` bound memory and process count so one bug cannot take the host. The values are examples; **set yours from measurement** (see below), and watch for the container being killed when it exceeds the limit.
- `restart: unless-stopped` restarts after a crash or reboot, but not after you stop it on purpose. A restart loop hides a bug, so pair it with an alert on restart count.
- `healthcheck` runs `wget` (present in Alpine's BusyBox) against `/healthz` inside the container. `start_period` gives it 5 seconds before failures count. Compose reports the container as `healthy` or `unhealthy`; an orchestrator such as Kubernetes uses its own probes instead.

### Step 9. The checklist
**File: `PRODUCTION-CHECKLIST.md`**
```markdown
# Production readiness checklist

Copy this file into your repository and tick every line with evidence (a link, a command output, a dashboard), not with a feeling.

## Build and supply chain
- [ ] The SDK is pinned (`global.json`) and the base images use exact tags that match it.
- [ ] Package versions are central and locked; the restore runs in locked mode in CI.
- [ ] `TreatWarningsAsErrors` is on and the NuGet audit reports no known vulnerabilities.
- [ ] The image is built from a clean checkout in CI, not from a laptop; the build is reproducible.
- [ ] Images are scanned and signed or have a provenance record.

## Configuration and secrets
- [ ] No secret in the repository, the image or `appsettings.json`; secrets come from a store or the platform.
- [ ] Configuration differs only by environment variables or mounted files, not by code.
- [ ] Every setting has a safe default and the service refuses to start on invalid configuration.

## Security
- [ ] Every endpoint declares its authentication and authorization; anonymous is explicit.
- [ ] Tokens are validated for signature, issuer, audience and lifetime; roles are checked per operation.
- [ ] Input is validated at the edge; output never contains stack traces or internal details.
- [ ] CORS, security headers and rate limits are set deliberately; request size limits exist.
- [ ] The container runs as a non-root user with a read-only file system and no extra capabilities.

## Reliability
- [ ] Every outbound call has a timeout, safe retries, a circuit breaker and a bulkhead.
- [ ] Side effects use an outbox and idempotent consumers; non-idempotent requests carry idempotency keys.
- [ ] Liveness and readiness probes exist and check different things.
- [ ] The service shuts down gracefully within the platform's termination period.
- [ ] A load test and a failure test (dependency down, slow, restarting) have been run and recorded.

## Observability
- [ ] Logs are structured, carry the trace id and contain no secrets or personal data.
- [ ] Metrics cover rate, errors and duration, plus saturation of pools and queues.
- [ ] Traces cross every service boundary and the message broker.
- [ ] Alerts exist for symptoms users feel, each with an owner and a runbook.

## Performance and capacity
- [ ] The performance budget is written down and measured, not guessed.
- [ ] Memory and CPU limits are set from measurements and the service is tested at those limits.
- [ ] Caches have staleness budgets, bounded size and a cold-start plan.

## Data
- [ ] Migrations are backward compatible (expand, migrate, contract) and tested on a copy of production-sized data.
- [ ] Backups are taken and a restore has been rehearsed.
- [ ] Retention and deletion rules exist for personal data.

## Operations
- [ ] A rollback takes minutes and has been rehearsed.
- [ ] Deployments are gradual (canary or rolling) with an automatic stop on error rate.
- [ ] On-call knows the service, the dashboards and the runbook.
- [ ] Dependencies and their owners are listed, with the expected behavior when each one fails.
```
The checklist is a file in the repository, so changes to it go through review like code. Items that say "locked" and "central" refer to two NuGet features this lesson shows only as settings: **central package management** (a `Directory.Packages.props` with `ManagePackageVersionsCentrally` set to `true` and one `PackageVersion` per package) and **lock files** (`RestorePackagesWithLockFile` creates `packages.lock.json`; CI then restores with `dotnet restore --locked-mode`, which fails if the resolved versions differ from the lock file). This project has no packages, so there is nothing to lock yet.

## Run it
**Predict first.** Which of these will fail the build under the settings above: (a) a block-scoped `namespace Shop { ... }`, (b) a `using` that is never used, (c) a package reference with a known vulnerability?

**1. Build with the rules and run locally** (in `lesson10`):
```text
dotnet build src/Inventory.Api -c Release
dotnet run --project src/Inventory.Api -c Release --no-build
```
Answers: (a) fails (warning promoted to error by the editorconfig and `TreatWarningsAsErrors`); (b) does **not** fail, because the unused-using rule is not set to warning in this file (add it deliberately if you want it); (c) fails when the NuGet audit reports it, since the audit result is a warning. In a second terminal (`curl.exe` on Windows PowerShell):
```text
curl -s http://127.0.0.1:5310/stock/1
```
Expected output (not yet run; derived from the code):
```text
{"id":1,"name":"Pen","quantity":120}
```
Check the other cases yourself: `/stock/2` returns `{"id":2,"name":"Cup","quantity":0}`, `/stock/99` returns HTTP 404 with an empty body, and `/healthz` returns `ok`. Stop the run with Ctrl+C.

**2. Prove the analyzers bite.** Create a file `src/Inventory.Api/Bad.cs` with the content below, build, read the error, then delete the file:
```csharp
namespace Bad
{
    internal sealed class Unused
    {
    }
}
```
Expected (typical, not captured): the build fails and, among the errors, one for the namespace declaration style (rule `IDE0161`, "use file-scoped namespace") is reported. Read the error text in your terminal and note the rule id; that id is what you would change in `.editorconfig` to alter the rule. Other rules may also fire on this throw-away class; the point is that **a style rule just stopped the build**.

**3. Publish a native executable locally (needs the C++ toolchain).** Replace `win-x64` by your RID (`linux-x64`, `osx-arm64`, ...):
```text
dotnet publish src/Inventory.Api -c Release -r win-x64
```
The output folder is `src/Inventory.Api/bin/Release/net11.0/win-x64/publish/` (the path uses `\` on Windows). Run the executable there and call `/stock/1` again. Any AOT warnings are printed during publish: **an app that publishes with AOT warnings may not work correctly**, so fix them rather than suppress them.

**4. Build and run the container** (needs Docker; the first build downloads images and compiles natively, so it takes a while):
```text
docker compose up -d --build --wait
docker compose ps
curl -s http://127.0.0.1:8310/stock/1
```
Expected: the service is `running (healthy)` and the `curl` prints the same JSON as step 1. Inspect what is inside and how it runs:
```text
docker compose exec inventory id
docker image ls inventory-api
```
`id` should show a non-zero user id (not root) and `docker image ls` shows the image size. **Write both down.** Clean up with:
```text
docker compose down --rmi local
```

## How it works
**What Native AOT is.** Normal .NET compiles to intermediate language (IL), and a just-in-time (JIT) compiler turns it into machine code **while the program runs**. Native AOT (ahead of time) compiles everything to machine code **at publish time**, trims what is unused, and links the runtime into one executable. According to the ASP.NET Core documentation the benefits are a smaller disk footprint, faster startup and lower memory demand, which matters most when you run many instances or scale from zero.

**What you give up.**
- **Dynamic features:** anything that needs to discover or generate code at run time (reflection over arbitrary types, `Assembly.Load`, `System.Reflection.Emit`, runtime-generated expression compilation) is restricted. Libraries must be **AOT-compatible**; check each dependency's documentation. Reflection-heavy frameworks may not work. Some ASP.NET Core features are not supported (for example MVC, Blazor Server and session; minimal APIs have partial support).
- **Build cost:** publishing is slower and needs a C toolchain.
- **Portability:** one binary per OS, architecture and C library.
- **Peak throughput:** a JIT can optimize hot code using run-time information. A long-running, CPU-heavy service can run as fast or faster with the JIT; **measure it** before you assume otherwise.
- **Diagnostics:** some tools that rely on runtime features behave differently; test your observability setup with the AOT build.

**Alternatives that keep most of the benefit with fewer limits:** ReadyToRun (pre-compiled code that the JIT can still improve), trimming without AOT, and simply right-sizing a normal container.

**Analyzers, in one paragraph.** The .NET SDK includes analyzers: **CA** rules (code quality, performance, security) and **IDE** rules (style). Each rule has an id and a severity (`none`, `suggestion`, `warning`, `error`). Defaults are lenient. `AnalysisLevel` chooses which rules are on; `.editorconfig` tunes individual severities; `TreatWarningsAsErrors` makes warnings gate the build. `dotnet format --verify-no-changes` in CI checks formatting without changing files. The goal is **few rules, all enforced**, not many rules, mostly ignored.

**Misconception:** "Native AOT makes any .NET app faster." It improves startup and memory for apps that fit its restrictions. For a database-bound API with a few long-lived instances, you may gain very little and pay in compatibility and build time.

### ADR-010: Use Native AOT only for the small, scale-out services
| Field | Content |
|---|---|
| Context | The platform runs many short-lived instances of small HTTP services and scales to zero overnight; cold start and memory dominate cost. A larger service depends on reflection-heavy libraries. |
| Decision | Build the small stateless services (like `Inventory.Api`) with Native AOT and `CreateSlimBuilder`. Keep the large service on the JIT with ReadyToRun. Adopt the AOT build only after the startup, memory, image-size and throughput numbers from the checklist are recorded for each service. |
| Consequences | + Lower memory and faster start where it counts. - Two build pipelines. - AOT warnings must be fixed, not suppressed. |
| Revisit when | The larger service's dependencies become AOT-compatible, or measurements show no gain. |

## When not to use this
- **Reflection-heavy frameworks or plugin systems:** if a dependency is not AOT-compatible, the choice is made for you.
- **A single long-lived instance** where startup time is irrelevant: a normal build is simpler to debug and iterate on.
- **Teams without a measured need:** AOT adds build cost and constraints. "Smaller and faster" must be a number you recorded, not a hope.
- **Strict analyzers on day one for a large legacy code base:** turning on `TreatWarningsAsErrors` with `latest-recommended` can produce thousands of errors. Ratchet instead: fix by category, or use a baseline, and tighten over weeks.

## Failure modes
- **Missing serializer context entry:** works in the JIT build and fails only in the AOT build. Test the AOT binary, not just `dotnet run`.
- **Suppressed AOT or trim warnings:** `[UnconditionalSuppressMessage]` and `#pragma warning disable` hide a crash that appears in production.
- **Image tag drift:** `latest` or a floating tag changes the OS or libc under you. Pin exact tags and update them on purpose.
- **Binary and base image mismatch:** an executable built for musl (Alpine) does not run on a glibc image and the reverse; the error looks like a missing file although the file exists.
- **Analyzer noise:** a build that always fails on rules nobody believes in trains people to disable analyzers entirely.
- **Warnings-as-errors on upgrades:** an SDK upgrade introduces new warnings and blocks the pipeline. Upgrade in its own pull request.
- **Container limits guessed:** a 128 MB limit that is too low gets the process killed under load. A limit that is too high wastes money and hides leaks.
- **Health check that checks too much:** a liveness check that calls the database restarts every instance during a database outage.
- **Read-only file system surprises:** libraries that write to temp folders or caches fail at the worst time. Test with `read_only: true` in a staging environment.

## Measurements to take
Record these for **both** the normal JIT build and the AOT build of the same service, on the same machine, and keep the table in your pull request. Do not copy anyone else's numbers.

| Metric | How to measure | JIT build | AOT build |
|---|---|---|---|
| Image size | `docker image ls` | | |
| Time to first successful request | Start the container and poll `/healthz`, note elapsed time | | |
| Memory after the first request and under load | `docker stats --no-stream` | | |
| Steady-state throughput and p99 latency | A load test with a fixed duration and concurrency | | |
| Publish time | Time the `docker build` with a cold and a warm cache | | |

Decide with a rule you wrote **before** measuring (for example "use AOT only if cold start is at least 2x better and p99 is not worse by more than 10 percent"); otherwise the numbers will be bent to the preferred answer.

## Production checklist
Use `PRODUCTION-CHECKLIST.md` from Step 9 as the production checklist for this lesson and for every service you ship. Two additions specific to AOT: (1) the **AOT binary** is what runs in the integration tests and in staging; (2) AOT and trim warnings are zero, with no suppressions.

## Try it
A review exercise. Below is a deliberately flawed order service. Imagine it was handed to you in a pull request. Spend 20 minutes and write your findings as a table: **finding, severity (blocker, should-fix, nit), concrete fix**. Do not open the solution before you have written yours.

1. **Guided.** Read these three files (they are in `exercise/starter/review/` of the source pack) and list at least **eight** findings, covering all three files.

**File: `Program.cs`**
```csharp
using Microsoft.AspNetCore.Mvc;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddCors(o => o.AddDefaultPolicy(p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();
app.UseDeveloperExceptionPage();
app.UseCors();

const string connectionString = "Host=db;Database=shop;Username=postgres;Password=postgres";

app.MapGet("/debug/config", (IConfiguration configuration) =>
    configuration.AsEnumerable().ToDictionary(pair => pair.Key, pair => pair.Value));

app.MapPost("/orders", async (HttpRequest request, ILogger<Program> logger) =>
{
    using var reader = new StreamReader(request.Body);
    var body = await reader.ReadToEndAsync();
    logger.LogInformation("Order received: {Body} from {Authorization}", body, request.Headers.Authorization);

    var client = new HttpClient();
    var response = client.PostAsync("https://payments.internal/charge", new StringContent(body)).Result;
    for (var attempt = 0; attempt < 10 && !response.IsSuccessStatusCode; attempt++)
    {
        response = client.PostAsync("https://payments.internal/charge", new StringContent(body)).Result;
    }

    return Results.Ok(await response.Content.ReadAsStringAsync());
});

app.Run();
```
**File: `Dockerfile`**
```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:latest
WORKDIR /app
COPY . .
ENV ASPNETCORE_ENVIRONMENT=Development
ENV ConnectionStrings__Default="Host=db;Database=shop;Username=postgres;Password=postgres"
EXPOSE 5000
CMD ["dotnet", "run", "--urls", "http://0.0.0.0:5000"]
```
**File: `docker-compose.yml`**
```yaml
services:
  api:
    build: .
    ports:
      - "5000:5000"
    privileged: true
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    restart: always
  db:
    image: postgres:latest
    environment:
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
```
2. **Change.** Pick the **three** blockers you consider most dangerous and rewrite those lines. Then tick `PRODUCTION-CHECKLIST.md` for your fixed version: which lines can you tick with evidence, and which can you not?
3. **Stretch.** Write a `Directory.Packages.props` for a service with three packages, turn on `RestorePackagesWithLockFile`, and describe the exact CI command that fails the build when someone changes a version without updating the lock file.

<details><summary>Solution (review findings)</summary>

The full table (29 findings with severity and fix) is in `exercise/solution/FINDINGS.md` of the source pack. The highest-ranked blockers, grouped:
- **Secrets and configuration:** the connection string password is in source (`Program.cs`), baked into the image (`ENV ConnectionStrings__Default`) and in the compose file (`POSTGRES_PASSWORD`); `ASPNETCORE_ENVIRONMENT=Development` is set in the image. Fix: inject secrets at run time from a store; rotate the exposed ones; remove the environment override.
- **Access control:** no authentication on `/orders`; `/debug/config` dumps every configuration value anonymously; CORS allows any origin. Fix: `RequireAuthorization` with a policy, delete the debug endpoint, allow exact origins.
- **Leaks:** the developer exception page and logging of the request body and the `Authorization` header. Fix: Development-only exception page, ProblemDetails in production, log ids and outcomes only.
- **Container escape and exposure:** `privileged: true`, the Docker socket mounted, a database published on all interfaces with a default password, running as root. Fix: remove the first two, do not publish the database, add `USER`, drop capabilities.
- **Reliability:** a retry loop of ten attempts on a non-idempotent POST with no delay, `new HttpClient()` per request, blocking `.Result`, no timeouts. Fix: a typed client with the resilience handler from lesson 06 and an idempotency key.

Ranking matters: a reviewer who lists 29 items of equal weight has not helped the author decide what to fix first.
</details>

## Check yourself
1. Why does the Dockerfile copy `Directory.Build.props` and `.editorconfig` before restoring?
   <details><summary>Answer</summary>So the container build applies the same rules as the local build. Without them the image could build code that your pipeline rejects locally.</details>
2. **Find the bug.** The service works with `dotnet run` but throws at the first request in the AOT build, mentioning missing JSON type information. What is the likely cause?
   <details><summary>Answer</summary>A returned or received type is not listed in `[JsonSerializable]` on the source-generated context, so no serialization metadata exists at run time.</details>
3. Why is `/healthz` a bad place to check the database?
   <details><summary>Answer</summary>A liveness check that fails during a database outage makes the orchestrator restart every instance, turning a dependency outage into a total outage. Use a separate readiness check.</details>
4. What does `read_only: true` protect against and what must you test when you turn it on?
   <details><summary>Answer</summary>It stops a compromised process from writing files or modifying the binary. Test that the service does not need to write anywhere except the allowed temp folder.</details>
5. Why record the decision rule before measuring AOT against JIT?
   <details><summary>Answer</summary>To avoid choosing thresholds after seeing the numbers, which bends the result toward the answer you already wanted.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `dotnet publish` fails with a message that a native linker or `clang` was not found (typical wording) | The C toolchain prerequisite for Native AOT is missing. | Install the prerequisites for your OS (see Going further), or publish inside the Docker build. |
| The build fails with a warning shown as an error for a rule id such as `IDE0161` or `CA1852` (typical) | `TreatWarningsAsErrors` promoted a rule from `.editorconfig`. | Read the id, fix the code; change the severity in `.editorconfig` only with a reason. |
| Docker reports that an image tag was not found (typical wording) | The pinned tag does not exist for your version or Alpine release. | Look up the current tags on the Microsoft Container Registry and update the Dockerfile; keep the SDK and runtime images on the same Alpine version. |
| The container starts and stops immediately, or reports that a file was not found although it exists | A binary built for glibc is running on musl (or the reverse), or the architecture differs. | Build with the RID that matches the runtime image (`linux-musl-x64` here). |
| `docker compose ps` shows `unhealthy` | The health check cannot reach `/healthz`: the app listens on another port, or `wget` is not available in the image. | `docker compose logs inventory`; check `ENV Urls` and the command in the health check. |
| `curl` to port 8310 is refused | The container is not up, or another service uses 8310. | `docker compose ps`; change the host port in the compose file. |

## Best practice
Make the compiler and the pipeline enforce your rules, ship the smallest and least-privileged image you can measure and justify, and review every service against a written checklist with evidence. Source: ASP.NET Core support for Native AOT https://learn.microsoft.com/aspnet/core/fundamentals/native-aot and ASP.NET Core best practices https://learn.microsoft.com/aspnet/core/fundamentals/best-practices

## Going further
- Native AOT deployment overview and prerequisites: https://learn.microsoft.com/dotnet/core/deploying/native-aot/
- Fix AOT and trimming warnings: https://learn.microsoft.com/dotnet/core/deploying/trimming/fixing-warnings
- Code analysis rules overview and configuration: https://learn.microsoft.com/dotnet/fundamentals/code-analysis/overview
- Central package management: https://learn.microsoft.com/nuget/consume-packages/central-package-management
- The backend-dotnet capstone's Dockerfile, compose file and hardening chapter: `capstones/backend-dotnet/tutorials/phase-4-run-and-ship/04-run-and-ship.md` and `capstones/backend-dotnet/tutorials/phase-5-hardening/05-hardening.md`.
- **End of C# 301.** Continue with the capstones: build the platform contract end to end, or take a practice capstone from `capstones/_practice/`.

## Summary
- You enabled Native AOT, source-generated JSON, and listed what it costs and what to measure.
- You moved team rules into `Directory.Build.props` and `.editorconfig` so the build enforces them.
- You built and read a hardened container configuration line by line.
- You reviewed a flawed service against a production checklist, ranking findings by severity.

## Next lesson
End of C# 301 (Super Hero to Legendary). Continue with the capstones; the 301 levels of the other tracks are written too, for example [Architecture 301 lesson 01, scaling to millions](../../../architecture/301-super-hero-to-legendary/phase-1-scale/01-scaling-to-millions.md).
