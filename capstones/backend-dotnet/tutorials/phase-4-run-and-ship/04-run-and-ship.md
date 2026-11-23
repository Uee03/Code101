---
track: capstone
level: 201
phase: 4
phase_name: run-and-ship
lesson: 04
title: "Docker image and Compose"
time: 75 min
prerequisites: [capstone-backend-dotnet-03, docker-101]
versions: { dotnet_sdk_image: "mcr.microsoft.com/dotnet/sdk:11.0.100-alpine3.24", aspnet_image: "mcr.microsoft.com/dotnet/aspnet:11.0.0-alpine3.24", compose: "5.7.0", docker: "29.9.3" }
verified: 2026-11-23 on Windows 11, Docker 29.9.3, Compose 5.7.0, Python 3.15.2
source: capstones/backend-dotnet/source/phase-4-run-and-ship/04-run-and-ship/
assets: []
---

# 04. Docker image and Compose

## Why it matters
A food truck serves from a clean, standard kitchen that fits in the truck: it does not matter whose house the truck parks at. A container image is that kitchen. It holds the compiled API and exactly the runtime it needs, so "it works on my machine" becomes "it works in the image". Two rules make it safe to ship: build in one big workshop and move **only the finished product** into a small image (a multi-stage build), and never run the service as the administrator of its own container (a non-root user).

## What you will build
A `Dockerfile` with two stages and pinned images, a `.dockerignore`, a Compose **override file** that adds an `api` service to the platform stack (same network `tasksteams-net`, published on `127.0.0.1:8000`, health check, read-only file system, no Linux capabilities), and an extended `.env.example`. After this chapter `docker compose up -d --build --wait` starts Postgres, Keycloak and the API, and the conformance script runs against the container: **17 passed, 1 failed** (the `me` headers arrive in chapter 5). The API code is unchanged except one logging setting.

## Before you start
- Chapter 03 done or its pack unzipped. The .NET SDK is not needed on the host in this chapter: the build happens in the image.
- Docker running in Linux-container mode. The first build downloads about 1 GB of base images (the SDK image is large; it is not part of what you ship).
- Host ports 5432, 8180 and 8000 free.
- Source pack: unzip `backend-dotnet-phase-4-run-and-ship.zip` and open `04-run-and-ship/code`.

New terms (see the [glossary](../../GLOSSARY.md)): **multi-stage build**, **non-root user**.

## Steps
### Step 1. Check which images exist
Never guess a tag. On 2026-11-23 the Microsoft Artifact Registry lists `mcr.microsoft.com/dotnet/sdk:11.0.100-alpine3.24` and `mcr.microsoft.com/dotnet/aspnet:11.0.0-alpine3.24` (the tag lists are at `https://mcr.microsoft.com/v2/dotnet/sdk/tags/list` and `.../aspnet/tags/list`). We pin the exact patch version, so a build next year produces the same result, and choose **Alpine**, a Linux with a tiny base (the final image is about 195 MB). The SDK `11.0.100` matches `global.json`; the runtime `11.0.0` is the matching ASP.NET Core 11 release. Update both numbers together, deliberately, when a new patch is out ([.NET container images](https://learn.microsoft.com/dotnet/core/docker/introduction)).

### Step 2. `.dockerignore`
The build sends the folder `code` to Docker as the "build context". The file `.dockerignore` lists what must not be sent: build output (it would shadow the container's own), the local secrets file `.env`, Git data, and everything the image does not need (the database scripts, the realm, the docs). A smaller context builds faster and keeps `.env` out of the image. (`appsettings.json` still goes in and holds the fake local database password: in real use the password comes from a secret store through an environment variable.)

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

### Step 3. `Dockerfile`
Read it top to bottom. Stage `build` has the SDK; stage `runtime` has only the ASP.NET Core runtime and the **published output** copied from the first stage. The restore step comes first and copies only `TasksApi.csproj`: Docker caches each step as a layer, so a code change does not download the packages again.

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

Line by line:

| Line | What it does | If you change it |
|------|--------------|------------------|
| `# syntax=docker/dockerfile:1` | selects the current Dockerfile syntax | nothing visible; keeps features predictable |
| `FROM ...sdk:11.0.100-alpine3.24 AS build` | starts stage 1 from the SDK image and names it | a different tag changes the compiler |
| `COPY global.json ./` | the SDK pin is needed so `dotnet` uses the same SDK as on your machine | without it the container's SDK is chosen by default |
| `COPY src/TasksApi/TasksApi.csproj ...` then `RUN dotnet restore ...` | downloads the NuGet packages into their own layer | copying all files first re-runs the restore for every edit |
| `RUN dotnet publish ... -c Release --no-restore -o /app/publish /p:UseAppHost=false` | compiles in Release mode into `/app/publish`; `UseAppHost=false` skips the native launcher we do not use | `Debug` would ship slower, bigger code |
| `FROM ...aspnet:11.0.0-alpine3.24 AS runtime` | starts stage 2: no SDK, no compiler | using the SDK image here would make the image several times bigger and give an attacker a compiler |
| `COPY --from=build /app/publish ./` | brings only the finished output over | |
| `ENV Urls=http://0.0.0.0:8000 DOTNET_EnableDiagnostics=0` | listen on all interfaces **inside** the container; turn off the diagnostic IPC channel | see "Common mistakes": `ASPNETCORE_URLS` would be overridden by `appsettings.json` |
| `USER $APP_UID` | the base image defines user `app` (uid 1654) and sets `APP_UID`; every later command and the service run as it | without it the API runs as root |
| `ENTRYPOINT ["dotnet", "TasksApi.dll"]` | the command the container runs; the JSON array form makes `dotnet` the main process (PID 1) so it receives stop signals | the shell form would put a shell in front |

### Step 4. The environment template
`.env.example` gains two lines: the port the API is published on and the password of the database role `tasks_app` (the fake one that `db/schema.sql` creates). Replace the file; the first nine lines (a comment and eight settings) are the platform's.

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

### Step 5. The Compose override
Compose reads `docker-compose.yml` (the platform: `db`, `keycloak`) **and** `docker-compose.override.yml` automatically and merges them. The override adds one service and joins it to the platform network. Read the keys:

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

| Key | Meaning |
|-----|---------|
| `build.context: .` | build the image from this folder with the `Dockerfile` |
| `image:` | the name and tag of the built image, so the verification can remove it again |
| `environment` | settings by the same names as `appsettings.json` (`__` stands for `:`): the database host is `db`, the metadata address is `keycloak:8080` (Docker's own network), the issuer stays `localhost:8180` as in the token |
| `ports: 127.0.0.1:8000:8000` | published on the loopback address only: other computers cannot reach it |
| `depends_on ... service_healthy` | start the API after Postgres and Keycloak are healthy |
| `healthcheck` | every 5 seconds `wget` calls `/health` inside the container; `--wait` returns when it passes |
| `read_only: true` and `tmpfs: /tmp` | the container's file system cannot be written, except a memory-backed `/tmp` |
| `cap_drop: [ALL]` | removes every Linux capability |
| `security_opt: no-new-privileges` | a process cannot gain more rights |
| `restart: unless-stopped` | Docker restarts the API after a crash |
| `networks: [tasksteams]` | the key `tasksteams` is the network defined in the platform file; its real name is `tasksteams-net` |

### Step 6. Logging noise and `appsettings.json`
The Data Protection system of ASP.NET Core logs a warning at startup in a container without a user profile ("Using an ephemeral key repository"). This API stores no protected data, so the warning is noise. Replace `src/TasksApi/appsettings.json`; the only change is the `Microsoft.AspNetCore.DataProtection` line.

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
      "Microsoft.AspNetCore.DataProtection": "Error",
      "Microsoft.EntityFrameworkCore": "Critical"
    }
  },
  "AllowedHosts": "*"
}
```

Every other file is unchanged from chapter 03 (the C# files, the platform files, the helper scripts) and is not shown again.

#### The `.gitignore` of this chapter (unchanged from chapter 01)
The `.dockerignore` above is for Docker; Git has its own file. It is the same `.gitignore` as in chapter 01, shown again so you can check your copy.

<details>
<summary><code>.gitignore</code> (same as chapter 01)</summary>

**File: `.gitignore`**
```text
bin/
obj/
.env
```

- `bin/`: compiled output; rebuilt on every machine (and inside the image by the `build` stage).
- `obj/`: intermediate build files with machine-specific paths.
- `.env`: the Compose settings of this chapter (database password, ports). Never commit it; `.env.example` is the committed template.

`.git` itself is never listed: Git does not track its own folder.
</details>

## Run it
Folder: `04-run-and-ship/code`. Create the environment file, then build and start everything. The project name `backend` groups the containers.
```powershell
Copy-Item .env.example .env
docker compose -p backend up -d --build --wait
```
On macOS and Linux use `cp .env.example .env`. Expected output (the BuildKit lines above these differ; the first build prints many `#nn` lines):
```text
 Image code101/tasksteams-backend-dotnet:1.0 Built
 Network tasksteams-net Created
 Volume backend_pg_data Created
 Container backend-db-1 Created
 Container backend-keycloak-1 Created
 Container backend-api-1 Created
 Container backend-keycloak-1 Started
 Container backend-db-1 Started
 Container backend-db-1 Healthy
 Container backend-keycloak-1 Healthy
 Container backend-api-1 Started
 Container backend-api-1 Healthy
```
Check the three services, the user inside the container, the processes, and that the file system is read-only:
```powershell
docker compose -p backend ps
docker compose -p backend exec -T api id
docker compose -p backend exec -T api ps
docker compose -p backend exec -T api sh -c "touch /app/x"
```
Expected output:
```text
NAME                 IMAGE                                   COMMAND                  SERVICE    CREATED          STATUS                    PORTS
backend-api-1        code101/tasksteams-backend-dotnet:1.0   "dotnet TasksApi.dll"    api        27 seconds ago   Up 5 seconds (healthy)    127.0.0.1:8000->8000/tcp
backend-db-1         postgres:17-alpine                      "docker-entrypoint.s…"   db         27 seconds ago   Up 26 seconds (healthy)   127.0.0.1:5432->5432/tcp
backend-keycloak-1   quay.io/keycloak/keycloak:26.8.2        "/opt/keycloak/bin/k…"   keycloak   27 seconds ago   Up 26 seconds (healthy)   127.0.0.1:8180->8080/tcp
```
```text
uid=1654(app) gid=1654(app) groups=1654(app)
```
```text
PID   USER     TIME  COMMAND
    1 app       0:01 dotnet TasksApi.dll
   48 app       0:00 ps
```
```text
touch: /app/x: Read-only file system
```
The API is process 1, owned by `app`, and it cannot even create a file in its own folder. Now the health endpoint, the image size, and the network members:
```powershell
curl.exe -s http://127.0.0.1:8000/health
docker image ls code101/tasksteams-backend-dotnet --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"
docker network inspect tasksteams-net --format "{{range .Containers}}{{.Name}} {{end}}"
```
Expected output:
```text
{"status":"ok","version":"1.0.0","database":"up"}
```
```text
REPOSITORY:TAG                          SIZE
code101/tasksteams-backend-dotnet:1.0   195MB
```
```text
backend-keycloak-1 backend-api-1 backend-db-1
```
Run the conformance script against the container:
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
PASS  create team (201, Location and ETag set, team bbae76cc-b181-4816-a1db-83750f3f5f06)
PASS  create project (201, project 01a207c0-1c54-78f3-8d78-0b20e4e7bea2)
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
Read the API log and then stop the database to see what the health check says:
```powershell
docker compose -p backend logs api --no-log-prefix --tail 6
docker compose -p backend stop db
curl.exe -s -i http://127.0.0.1:8000/health
```
Expected output of the log (the last six lines; there is one JSON line per request in chapter 5):
```text
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
info: Microsoft.Hosting.Lifetime[0]
      Hosting environment: Production
info: Microsoft.Hosting.Lifetime[0]
      Content root path: /app
```
Expected output of the health call after `stop db` (the service tells the truth; Docker marks the container `unhealthy` after the health check fails 12 times in a row):
```text
HTTP/1.1 503 Service Unavailable
Content-Type: application/json; charset=utf-8
Date: Mon, 23 Nov 2026 09:32:57 GMT
Server: Kestrel
Transfer-Encoding: chunked

{"status":"degraded","version":"1.0.0","database":"down"}
```
Clean up everything this chapter created, including the database volume and the image you built:
```powershell
docker compose -p backend down -v --remove-orphans
docker image rm code101/tasksteams-backend-dotnet:1.0
```
Expected output ends with:
```text
 Volume backend_pg_data Removed
 Network tasksteams-net Removed
Untagged: code101/tasksteams-backend-dotnet:1.0
```
The base images (`sdk` and `aspnet`) stay in Docker's cache so the next build is fast; `docker image rm` them too if you need the disk space.

## How it works
1. **Build.** `docker compose up --build` runs the Dockerfile. Stage 1 restores, compiles and publishes (`dotnet publish` produces the DLLs, `appsettings.json` and the dependency list in `/app/publish`). Stage 2 starts again from the small runtime image and copies only that folder. The SDK, the source code and the NuGet cache stay in stage 1 and are not in the shipped image.
2. **Merge.** Compose merges `docker-compose.yml` and `docker-compose.override.yml`. The `api` service refers to the network key `tasksteams`; the platform file defines it as the network named `tasksteams-net`, so the API reaches `db` and `keycloak` by their service names (Docker's DNS) and the host reaches the API on `127.0.0.1:8000`.
3. **Start order.** `depends_on` with `service_healthy` waits for the health checks of Postgres and Keycloak; `--wait` finally waits for the API's own check.
4. **Configuration.** `appsettings.json` is inside the image with the local defaults. The `environment` block overrides the keys that differ in Docker (`ConnectionStrings__Default` points at the host `db`, `Auth__MetadataAddress` at `keycloak:8080`). Environment variables beat `appsettings.json`: the same image runs anywhere with different settings (twelve-factor config).
5. **Two addresses for Keycloak.** The API fetches keys from `http://keycloak:8080/...` (its own Docker network) while tokens carry `iss: http://localhost:8180/realms/tasksteams` (the address a browser or phone uses). Keycloak is started with `KC_HOSTNAME` and `KC_HOSTNAME_BACKCHANNEL_DYNAMIC` so it answers both and keeps the issuer fixed.
6. **Hardening of the container.** `USER $APP_UID` (the unprivileged user `app`, not root), `read_only`, `cap_drop: ALL`, `no-new-privileges`, loopback-only port: if the API had a remote code execution bug, the attacker would start with almost no rights and no place to write.

| Decision | Alternatives | Why this one |
|----------|--------------|--------------|
| Alpine runtime image | Debian (`noble`) image; chiseled Ubuntu | About 195 MB and few packages; needs `InvariantGlobalization` (no ICU) |
| Pin the exact patch tags | `11.0` or `latest` | Reproducible builds; updates are a visible commit. Remember to take security patches |
| Compose override file | One big compose file; a separate project | The platform file stays byte-identical, the backend only adds its service. The platform network is shared |
| Build inside Docker | Build on the host and copy `bin` | The image does not depend on the host SDK or OS; the CI does the same |
| `wget` health check | `curl` (not in Alpine); a .NET health check tool | `wget` is part of busybox in the image; no extra package |

## Try it
Limit what a runaway or compromised API container may use: 256 MB of memory and 200 processes. The starter is the override file with a TODO comment; the solution adds two lines.

1. Copy `exercise/starter/docker-compose.override.yml` over your override file and follow the TODO.
2. Check the merged result with `docker compose -p backend config`: it must contain `mem_limit` and `pids_limit: 200`.

Starter:

**File: `exercise/starter/docker-compose.override.yml`**
```yaml
services:
  api:
    # TODO: limit what a runaway or compromised API container can use:
    #   - mem_limit: 256m
    #   - pids_limit: 200
    #   Add them under api, next to read_only. Then run:  docker compose config
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

<details><summary>Solution</summary>

**File: `exercise/solution/docker-compose.override.yml`**
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
    mem_limit: 256m
    pids_limit: 200
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

`docker compose config` prints the merged file, and writes the memory limit in bytes:
```text
    mem_limit: "268435456"
    pids_limit: 200
```
`mem_limit` makes Docker kill the container if it uses more memory than that (it is then restarted by `restart: unless-stopped`). `pids_limit` stops a fork bomb.

</details>

## Check yourself
1. Why is the restore step before `COPY src/TasksApi/ ...` in the Dockerfile? <details><summary>Answer</summary>Docker caches layers. Package restore depends only on the project file, so it stays cached until the packages change. Copying the source first would invalidate the layer on every code change.</details>
2. What is the benefit of two stages? <details><summary>Answer</summary>The final image has the runtime only: no SDK, compiler or source. It is smaller and has less an attacker could use.</details>
3. Why publish the port as `127.0.0.1:8000:8000` and not `8000:8000`? <details><summary>Answer</summary>`8000:8000` listens on every network interface of the computer. The loopback form accepts only connections from the same machine.</details>
4. The API inside the container cannot create files. Why is that good? <details><summary>Answer</summary>A compromised process cannot drop tools or change the application files. The service does not need to write, so the permission is removed.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `git status` lists `.env`, `bin/` or `obj/` as new files, or `docker history` shows secrets in a layer | `.gitignore` or `.dockerignore` is missing, or created after the files were already tracked or copied | Create both files as shown above; for files already tracked run `git rm --cached .env` (and `git rm -r --cached bin obj`), commit, and replace any real secret that was ever committed |
| The container is `healthy` but every call from the host fails with `Remote end closed connection without response`; the log says `Overriding HTTP_PORTS '8080' and HTTPS_PORTS ''. Binding to values defined by URLS instead 'http://127.0.0.1:8000'.` | `appsettings.json` has `Urls: http://127.0.0.1:8000`, which beats the environment variable `ASPNETCORE_URLS`; the API listens on the container's own loopback, which the published port cannot reach | Set `Urls` (the same key) in the image: `ENV Urls=http://0.0.0.0:8000`. The `Overriding HTTP_PORTS` line stays, it only says which setting won |
| `docker compose` prints `The "TASKS_APP_PASSWORD" variable is not set. Defaulting to a blank string.` and the API cannot connect | There is no `.env` file, or it is the old one from chapter 02 without the two new lines | `Copy-Item .env.example .env` again |
| `touch: /app/x: Read-only file system` when you try to write inside the container | `read_only: true` is doing its job | Write only to `/tmp` (a tmpfs), or add a volume if the service really needs a folder |
| `Bind for 127.0.0.1:5432 failed: port is already allocated` (or 8000, or 8180) | Another container or program, for example another lab's stack, uses the port | Stop the other one (`docker ps` shows which container publishes it), then run `up` again |
| Warnings `Using an ephemeral key repository` and `No XML encryptor configured` at every start | ASP.NET Core Data Protection finds no profile folder in a container | Harmless for this API; the setting `Microsoft.AspNetCore.DataProtection: Error` hides them. If you ever store protected data, persist the keys |

## Best practice
Build in one image, ship in another; pin versions; never run as root; drop capabilities and make the root file system read-only; publish ports to loopback only unless something must be reachable. Source: [Docker: multi-stage builds](https://docs.docker.com/build/building/multi-stage/); [Docker: building best practices](https://docs.docker.com/build/building/best-practices/); [Containerize a .NET app](https://learn.microsoft.com/dotnet/core/docker/build-container); [Compose: merge multiple files](https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/); [OWASP API Security Top 10 2023, API8](https://owasp.org/API-Security/editions/2023/en/0x11-t10/).

## Next lesson
05. Hardening: walk through the OWASP API Security Top 10 against your own code, add a rate limiter with the `RateLimit-*` headers and 429, security headers, request size limits, CORS, and request logging that never contains a secret. The conformance result reaches 18 passed, 0 failed.
