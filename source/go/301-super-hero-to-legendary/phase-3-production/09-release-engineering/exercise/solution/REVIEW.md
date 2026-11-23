# Review of the starter service against the production checklist

Item IDs refer to the checklist in lesson 09. Severity: **High** can lead to a breach or an outage; **Medium** weakens operations; **Low** is hygiene.

## `main.go`

| # | Finding | Severity | Checklist | Fix |
|---|---------|----------|-----------|-----|
| 1 | Password is a string constant in source code | High | S1 | read it from a mounted secret file or the secret store; rotate it, because it is already in Git history |
| 2 | The handler logs the password on every request | High | S1, O1 | never log secrets; use a `Secret` type that redacts itself (lesson 07) |
| 3 | The `name` query parameter is written into HTML unescaped (cross-site scripting) | High | X2 | `html.EscapeString`, or `html/template`; set a `Content-Type` |
| 4 | `http.ListenAndServe` has no timeouts: a slow client holds a connection forever | High | R1 | use an `http.Server` with `ReadHeaderTimeout`, `ReadTimeout`, `WriteTimeout`, `IdleTimeout` |
| 5 | `import _ "net/http/pprof"` registers profiling endpoints on the default mux, which is served on every interface | High | X3 | register pprof on a separate loopback or admin listener only (lesson 03) |
| 6 | The error from `ListenAndServe` is ignored and there is no graceful shutdown: a deploy cuts requests in flight | Medium | C4 | `Serve` in a goroutine, `signal.NotifyContext`, `Shutdown` with a timeout |
| 7 | No liveness or readiness endpoint | Medium | C3 | add `/healthz` and `/readyz` |
| 8 | Hard-coded `:8080` listens on all interfaces | Medium | C5, S2 | configurable address, default `127.0.0.1:8080`; containers set `0.0.0.0` explicitly |

## `Dockerfile`

| # | Finding | Severity | Checklist | Fix |
|---|---------|----------|-----------|-----|
| 9 | `FROM golang:latest`: the toolchain changes without a commit | Medium | B1 | pin an exact tag (and a digest in production) |
| 10 | One stage: the compiler, sources and caches ship in the runtime image | Medium | B6 | multi-stage build; runtime on `distroless/static` |
| 11 | `COPY . .` before dependencies, and no `.dockerignore`: `.git` and `.env` enter the image and every code change invalidates the dependency cache | High | S1, B6 | copy `go.mod` first, `go mod download`, then the source; add `.dockerignore` |
| 12 | `ENV DB_PASSWORD=hunter2`: the secret is stored in an image layer for ever | High | S1 | no secrets in images; mount at run time |
| 13 | No `USER`: the process runs as root | High | C1 | `USER nonroot:nonroot` |
| 14 | Shell-form `CMD ./app`: a shell becomes process 1 and does not forward `SIGTERM`, so shutdown is a hard kill after the grace period | Medium | C4 | exec form `ENTRYPOINT ["/app"]` |
| 15 | No `-trimpath`, no version stamp, `CGO_ENABLED` not set: the binary is not reproducible, not traceable to a commit and may link the C library | Medium | B2, B4 | `CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -X ...Version=..."` |

## `compose.yaml`

| # | Finding | Severity | Checklist | Fix |
|---|---------|----------|-----------|-----|
| 16 | `image: myorg/app:latest`: not a version, cannot be rolled back precisely | Medium | B1, B6, P1 | immutable version tag, deploy by digest |
| 17 | `"8080:8080"` publishes on every host interface | Medium | C5 | `"127.0.0.1:8080:8080"` (or an explicit interface) |
| 18 | The password is in the compose file (and so in version control) | High | S1 | `secrets:` or an untracked `.env`/secret store |
| 19 | `privileged: true` gives the container nearly the host's power | High | C1 | remove it; drop capabilities instead |
| 20 | No memory, CPU or process limits | Medium | C2 | `mem_limit`, `cpus`, `pids_limit` from measurement |
| 21 | No `read_only`, `cap_drop`, `no-new-privileges` | Medium | C1 | add them (and `tmpfs` for `/tmp` if needed) |
| 22 | No `healthcheck` | Medium | C3 | `healthcheck` using the binary's own `-healthcheck` flag |
| 23 | No `stop_grace_period` | Low | C4 | longer than the application's shutdown timeout |
| 24 | `restart: always` restarts a crash-looping container forever and hides the failure | Low | P4 | `unless-stopped` with an alert on restarts, or `on-failure` with a limit |

## Summary
24 findings: 10 High, 12 Medium, 2 Low. The fixed `main.go` in this folder addresses findings 1 to 8; the fixes for the Dockerfile and compose file are the files shown in the lesson (`Dockerfile` and `compose.yaml` of the code folder). Two follow-ups are needed outside this repository: the leaked password must be **rotated** (findings 1, 12 and 18), and the image history should be scanned for other secrets.
