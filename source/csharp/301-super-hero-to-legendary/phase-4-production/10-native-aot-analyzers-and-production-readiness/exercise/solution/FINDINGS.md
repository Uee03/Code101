# Review findings: the flawed order service

Severity: **B** = blocker (fix before any deployment), **S** = should fix, **N** = nit.

## Program.cs
| # | Line | Finding | Sev | Fix |
|---|---|---|---|---|
| 1 | `AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()` | CORS open to every website | B | `WithOrigins(...)` with the exact front-end origins, and only the methods and headers needed |
| 2 | `UseDeveloperExceptionPage()` | Stack traces and source paths leak to callers | B | Only in Development; otherwise `UseExceptionHandler` with ProblemDetails |
| 3 | `connectionString` constant | Password in source control | B | Read from configuration supplied by the platform or a secret store; rotate the exposed password |
| 4 | `/debug/config` | Dumps all configuration including secrets, anonymously | B | Delete it; if diagnostics are needed, a protected endpoint that shows no values |
| 5 | No authentication or authorization on `/orders` | Anyone can create orders | B | `RequireAuthorization` with a policy (lessons 09 and the capstone) |
| 6 | Logging `{Body}` and `Authorization` | Tokens and personal data written to logs | B | Log ids and outcome only; never credentials or full bodies |
| 7 | `new HttpClient()` per request | Socket exhaustion, no DNS refresh | S | Typed client from `IHttpClientFactory` |
| 8 | `.Result` inside an async handler | Blocks a thread-pool thread; under load this starves the pool (ASP.NET Core has no synchronization context, so a classic deadlock is unlikely, but blocking still hurts) | S | `await` |
| 9 | Retry loop of 10 on any failure, no delay | Retry storm; POST may charge twice | B | Resilience handler (lesson 06): timeout, retries only for transient and idempotent calls with jitter, idempotency key |
| 10 | No timeout, no cancellation token | A slow dependency hangs requests indefinitely | S | Timeout on the client and pass `HttpContext.RequestAborted` |
| 11 | No request size limit, no validation of `body` | Memory abuse and garbage in | S | Bind to a typed request, validate, and cap `MaxRequestBodySize` |
| 12 | No health endpoints | The platform cannot tell if it is alive or ready | S | `/healthz` (liveness) and a readiness check of required dependencies |
| 13 | No telemetry | An incident cannot be diagnosed | S | OpenTelemetry (lesson 08) |
| 14 | `Results.Ok(await ...ReadAsStringAsync())` of the upstream body | Upstream errors and internals are passed through to the caller | S | Map upstream failures to your own error contract |

## Dockerfile
| # | Line | Finding | Sev | Fix |
|---|---|---|---|---|
| 15 | `FROM ...sdk:latest` | Unpinned, huge, and the SDK ships to production | B | Multi-stage build; exact tags for the SDK and the runtime image |
| 16 | `COPY . .` | `.env`, `.git`, `bin/` and secrets can enter the image | S | `.dockerignore` and targeted `COPY` lines |
| 17 | `ENV ASPNETCORE_ENVIRONMENT=Development` | Enables developer behavior in production | B | Remove; set by the environment |
| 18 | `ENV ConnectionStrings__Default=...Password=postgres` | Secret baked into every layer | B | Inject at run time |
| 19 | `CMD ["dotnet", "run"]` | Compiles at start-up, needs the SDK, slow and fragile | S | `ENTRYPOINT` with the published output |
| 20 | No `USER` | Runs as root | B | `USER $APP_UID` (the base image provides an unprivileged user) |

## docker-compose.yml
| # | Line | Finding | Sev | Fix |
|---|---|---|---|---|
| 21 | `privileged: true` | Container can control the host | B | Remove; add only the capabilities you need (usually none) |
| 22 | `/var/run/docker.sock` mounted | Container compromise is host compromise | B | Remove |
| 23 | `"5432:5432"` on all interfaces | Database reachable from the network with a known password | B | Do not publish it, or `127.0.0.1:5432:5432` for local use |
| 24 | `POSTGRES_PASSWORD: postgres` | Default credential in a file | B | `${POSTGRES_PASSWORD:?...}` from `.env` (not committed) |
| 25 | `postgres:latest` | A major-version upgrade can happen on a pull | S | Pin the major or exact version |
| 26 | `"5000:5000"` on all interfaces | Service exposed beyond the machine | S | `127.0.0.1:5000:5000` or a reverse proxy |
| 27 | No `healthcheck`, no limits, no `read_only` | Cannot detect failure; one bug can take the host's memory | S | Add `healthcheck`, `mem_limit`, `pids_limit`, `read_only: true`, `cap_drop: [ALL]` |
| 28 | `restart: always` without a health check | A crash loop restarts forever and hides the problem | N | `unless-stopped` plus alerts on restart count |
| 29 | No named volume for the database | Data lost with the container | S | A named volume (and a backup plan) |

Twenty-nine findings, about half of them blockers. A review is successful when **every blocker** is found and each finding names a concrete fix; do not expect to find all 29 in 20 minutes, and rank before you polish.
