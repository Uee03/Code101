---
track: capstone
level: 201
phase: 4
phase_name: run-and-ship
lesson: 04
title: "Run and ship: a non-root image and one Compose command"
time: 60 min
prerequisites: [capstone-backend-python-03, docker-101]
versions: { python_image: "python:3.14.10-slim-trixie", python_host: "3.12 or newer (author run: 3.15.2)", docker: "29.9.3", compose: "5.7.0" }
verified: 2026-11-23 on Windows 11, Docker 29.9.3, Compose 5.7.0
source: capstones/backend-python/source/phase-4-run-and-ship/04-run-and-ship/
assets: []
---

# 04. Run and ship: a non-root image and one Compose command

## Why it matters
Goods travel the world in standard steel containers: the same box fits a ship, a train and a truck, and nobody opens it on the way. A container image does the same for software: what ran on your laptop runs the same on the test server. But a box is only as safe as its contents and its lock. A careless image ships compilers, caches and a root user; a careful one ships only what runs, as a user who can do almost nothing.

## What you will build
A `Dockerfile` with two stages (build the Python packages, then copy only the result), a `.dockerignore`, and a `docker-compose.override.yml` that adds the API as a service to the platform stack. One command, `docker compose up -d --build --wait`, then starts Postgres, Keycloak and the API on the network `tasksteams-net`, and publishes only `127.0.0.1:8000`. The application code does not change at all.

Conformance state at the end of this chapter: **17 passed, 1 failed** (`me`, the rate-limit headers of chapter 05).

```mermaid
flowchart LR
    subgraph build["Stage 1: builder (thrown away)"]
        B1["python:3.14.10-slim-trixie"] --> B2["python -m venv /opt/venv"]
        B2 --> B3["pip install --only-binary=:all: -r requirements.txt"]
    end
    subgraph run["Stage 2: runtime (the image you ship)"]
        R1["python:3.14.10-slim-trixie"] --> R2["user app, uid 10001"]
        R2 --> R3["COPY /opt/venv from builder"]
        R3 --> R4["COPY app/"]
    end
    B3 -->|"only the finished venv"| R3
    R4 --> RUN["uvicorn app.main:app on 0.0.0.0:8000, HEALTHCHECK /health"]
```

## Before you start
- Chapter 03 done, or unzip `backend-python-phase-4-run-and-ship.zip` and open `04-run-and-ship/code`. Files unchanged from earlier chapters are not repeated.
- Docker running; host ports 5432, 8180 and 8000 free (stop the API you started with Uvicorn in chapter 03, and `docker compose down -v` any older stack).

## Steps
### Step 1. Choose the Python version of the image
Your own computer may run a very new Python (the author's runs 3.15.2), but the **container** should run the newest version for which every dependency ships a prebuilt **wheel** (a ready-made package file). Without a wheel pip must compile C code, which needs compilers in the image and can fail. Ask pip which wheels exist for Python 3.14 on 64-bit Linux, without installing anything:

```text
tasksteams-api> python -m pip download -q --only-binary=:all: --python-version 3.14 --platform manylinux2014_x86_64 --implementation cp -r requirements.txt --dest wheels-check
```

The compiled packages it found (the rest are pure Python):

```text
cffi-2.1.1-cp314-cp314-manylinux2014_x86_64.manylinux_2_17_x86_64.whl
cryptography-50.0.2-cp311-abi3-manylinux2014_x86_64.manylinux_2_17_x86_64.whl
psycopg_binary-3.3.9-cp314-cp314-manylinux2014_x86_64.manylinux_2_17_x86_64.whl
pydantic_core-2.50.5-cp314-cp314-manylinux2014_x86_64.manylinux_2_17_x86_64.whl
sqlalchemy-2.1.9-cp314-cp314-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl
```

Every compiled dependency (`cffi`, `cryptography`, `psycopg_binary`, `pydantic_core`, `sqlalchemy`) has a `cp314` wheel (`cryptography` uses the stable `abi3` form that works for any Python from 3.11), so `python:3.14.10-slim-trixie` works. `slim` is Debian "trixie" without extras, small but with the standard `glibc` the wheels were built for. We avoid Alpine, which uses another C library (`musl`) and would need other wheels or a compiler. The tag names the exact patch version `3.14.10`, so a rebuild next month gives the same Python; to pin even the bytes, append the image digest (`docker buildx imagetools inspect python:3.14.10-slim-trixie` prints it). Delete the check folder: `wheels-check`.

### Step 2. The Dockerfile
Create `Dockerfile` (no extension) in the project folder:

**File: `Dockerfile`**
```dockerfile
# syntax=docker/dockerfile:1

# Stage 1 (builder): create a virtual environment with every dependency. Only wheels are allowed, so no compiler is needed.
FROM python:3.14.10-slim-trixie AS builder
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1
RUN python -m venv /opt/venv
COPY requirements.txt /tmp/requirements.txt
RUN /opt/venv/bin/pip install --only-binary=:all: -r /tmp/requirements.txt

# Stage 2 (runtime): the same Python, the finished virtual environment and our code. No pip, no build tools, no cache.
FROM python:3.14.10-slim-trixie AS runtime
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"
RUN groupadd --system --gid 10001 app \
 && useradd --uid 10001 --gid app --no-create-home --home-dir /nonexistent --shell /usr/sbin/nologin app
COPY --from=builder /opt/venv /opt/venv
WORKDIR /srv
COPY app ./app
USER 10001:10001
EXPOSE 8000
HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=5 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2)"]
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--no-server-header"]
```

| Line | What it does, and what happens if you change it |
|------|-------------------------------------------------|
| `# syntax=docker/dockerfile:1` | selects the current Dockerfile language version |
| `FROM python:3.14.10-slim-trixie AS builder` | the first stage, named `builder`. Everything installed here is discarded unless a later stage copies it |
| `ENV PIP_DISABLE_PIP_VERSION_CHECK=1 PIP_NO_CACHE_DIR=1` | pip stays quiet and keeps no download cache (smaller layers) |
| `RUN python -m venv /opt/venv` | a virtual environment in a fixed folder we can copy as one piece |
| `COPY requirements.txt` before `RUN pip install` | Docker caches each step: as long as `requirements.txt` is unchanged, the slow install is reused even when you edit the code |
| `pip install --only-binary=:all:` | forbids compiling; if a wheel is missing the build **fails loudly** instead of silently needing a compiler |
| `FROM ... AS runtime` | the second stage starts again from a clean Python image |
| `ENV PYTHONDONTWRITEBYTECODE=1` | no `.pyc` files, so the file system can be read-only (chapter 05) |
| `ENV PYTHONUNBUFFERED=1` | log lines are written at once, not buffered |
| `ENV PATH="/opt/venv/bin:$PATH"` | `python` and `uvicorn` now come from the copied environment |
| `groupadd`, `useradd` | a group and a user `app` with the fixed id 10001, no home folder, no login shell. A fixed numeric id lets an orchestrator verify "runs as non-root" without looking inside the image |
| `COPY --from=builder /opt/venv /opt/venv` | the only thing taken from stage 1: the finished packages |
| `WORKDIR /srv`, `COPY app ./app` | our code, owned by root, so the running user cannot modify it |
| `USER 10001:10001` | from here on, and when the container runs, the process is **not root** |
| `EXPOSE 8000` | documentation only: the port the app listens on |
| `HEALTHCHECK ... CMD ["python", "-c", ...]` | every 10 seconds the image asks its own `/health`; a non-200 answer makes the check fail, five failures mark the container `unhealthy`. It uses Python's standard library because the slim image has no `curl` |
| `CMD ["uvicorn", ...]` | the start command in **exec form** (a JSON list), so Uvicorn is process 1 and receives the stop signal directly. `--host 0.0.0.0` listens on all interfaces **inside** the container; the outside is restricted by Compose. `--no-server-header` stops Uvicorn from announcing its name |

### Step 3. What stays out of the image
Create `.dockerignore`. It lists what Docker must not send to the builder (the **build context**): smaller, faster builds, and no `.env` with secrets inside an image layer.

**File: `.dockerignore`**
```text
.git
.gitignore
.venv
**/__pycache__
**/*.pyc
.env
.env.example
Dockerfile
.dockerignore
docker-compose.yml
docker-compose.override.yml
db
keycloak
scripts
requests
pyproject.toml
```

`**/__pycache__` uses `**` because a plain `__pycache__` would only match the top folder. The patterns also keep `db`, `keycloak`, `scripts` and the request files out: the image needs only `requirements.txt` and `app/`.

### Step 4. Add the API to the stack
Create `docker-compose.override.yml`. Compose automatically merges a file with this name into `docker-compose.yml` when both are in the folder, so the platform file stays **unchanged** and our service is added on top:

**File: `docker-compose.override.yml`**
```yaml
# Adds the API to the platform stack. Compose merges this file into docker-compose.yml automatically,
# so one command starts Postgres, Keycloak and the API on the same network (tasksteams-net).
services:
  api:
    build:
      context: .
    environment:
      DATABASE_URL: postgresql+psycopg://tasks_app:${TASKS_APP_PASSWORD:-tasks_app_local_only}@db:5432/${POSTGRES_DB:-tasksteams}
      TOKEN_ISSUER: http://localhost:${KEYCLOAK_PORT:-8180}/realms/tasksteams
      TOKEN_AUDIENCE: tasks-api
      JWKS_URL: http://keycloak:8080/realms/tasksteams/protocol/openid-connect/certs
      PUBLIC_BASE_URL: http://localhost:8000
      LOG_LEVEL: INFO
      ENABLE_DOCS: "true"
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "127.0.0.1:8000:8000"
    networks:
      - tasksteams
    restart: unless-stopped
```

| Part | Meaning |
|------|---------|
| `build.context: .` | build the image from the `Dockerfile` in this folder |
| `DATABASE_URL` | the host name is the **service name** `db` (Compose gives containers DNS names on the network); the user is the limited role `tasks_app`. `${TASKS_APP_PASSWORD:-...}` takes the value from `.env`, or the default after `:-` |
| `TOKEN_ISSUER` | still `localhost:8180`: the **name written in the token**, which Keycloak builds from its `KC_HOSTNAME`, not an address our container can reach |
| `JWKS_URL` | `http://keycloak:8080/...`: where our container **can** reach Keycloak (service name, container port). This is why issuer and key address are two settings |
| `PUBLIC_BASE_URL` | what clients outside use in `Location` headers |
| `depends_on ... service_healthy` | start the API after Postgres reports healthy |
| `ports: "127.0.0.1:8000:8000"` | publish on your own computer only, never on the network |
| `networks: [tasksteams]` | join the network that `docker-compose.yml` defines (its real name is `tasksteams-net`) |
| `restart: unless-stopped` | restart after a crash, but not after you stopped it |

### Step 5. One new setting
The override reads `TASKS_APP_PASSWORD`. Replace `.env.example` with the version below (a new block in the middle) and copy it over your `.env`:

**File: `.env.example`**
```text
# Disposable local practice only. Copy to .env (Git ignores it). Never put real secrets in this file.

# Platform infrastructure (read by docker-compose.yml)
POSTGRES_DB=tasksteams
POSTGRES_USER=tasks_admin
POSTGRES_PASSWORD=tasks_admin_local_only
POSTGRES_PORT=5432
KEYCLOAK_ADMIN=kcadmin
KEYCLOAK_ADMIN_PASSWORD=kcadmin_local_only
KEYCLOAK_PORT=8180
TASKS_NETWORK=tasksteams-net

# Read by docker-compose.override.yml when the API runs in a container (the database role is created by db/schema.sql)
TASKS_APP_PASSWORD=tasks_app_local_only

# The API, when it runs on your computer with uvicorn (read by app/config.py; the container gets its own values from the override file)
DATABASE_URL=postgresql+psycopg://tasks_app:tasks_app_local_only@127.0.0.1:5432/tasksteams
LOG_LEVEL=INFO
PUBLIC_BASE_URL=http://localhost:8000
ENABLE_DOCS=true

# Token validation. TOKEN_ISSUER must equal the `iss` claim character for character; JWKS_URL is where the keys are fetched.
TOKEN_ISSUER=http://localhost:8180/realms/tasksteams
TOKEN_AUDIENCE=tasks-api
JWKS_URL=http://127.0.0.1:8180/realms/tasksteams/protocol/openid-connect/certs
TOKEN_LEEWAY_SECONDS=30
```

```powershell
# Windows PowerShell
Copy-Item .env.example .env -Force
```

```bash
# macOS and Linux
cp .env.example .env
```

## Run it
Build and start everything. The first build downloads the Python image and the packages; the end of the output is what matters (the lines before it are the build steps):

```text
tasksteams-api> docker compose up -d --build --wait
```

```text
 Volume tasksteams-api_pg_data Created 
 Volume tasksteams-api_pg_data Created 
 Network tasksteams-net Created 
 Network tasksteams-net Created 
 Container tasksteams-api-keycloak-1 Creating 
 Container tasksteams-api-db-1 Creating 
 Container tasksteams-api-db-1 Created 
 Container tasksteams-api-api-1 Creating 
 Container tasksteams-api-keycloak-1 Created 
 Container tasksteams-api-api-1 Created 
 Container tasksteams-api-keycloak-1 Starting 
 Container tasksteams-api-db-1 Starting 
 Container tasksteams-api-keycloak-1 Started 
 Container tasksteams-api-db-1 Started 
 Container tasksteams-api-db-1 Waiting 
 Container tasksteams-api-db-1 Healthy 
 Container tasksteams-api-api-1 Starting 
 Container tasksteams-api-api-1 Started 
 Container tasksteams-api-keycloak-1 Waiting 
 Container tasksteams-api-api-1 Waiting 
 Container tasksteams-api-db-1 Waiting 
 Container tasksteams-api-db-1 Healthy 
 Container tasksteams-api-api-1 Healthy 
 Container tasksteams-api-keycloak-1 Healthy 
```

`--wait` returns only when every service with a health check is healthy. Check the state:

```text
NAME                        IMAGE                              COMMAND                  SERVICE    CREATED          STATUS                    PORTS
tasksteams-api-api-1        tasksteams-api-api                 "uvicorn app.main:ap…"   api        26 seconds ago   Up 20 seconds (healthy)   127.0.0.1:8000->8000/tcp
tasksteams-api-db-1         postgres:17-alpine                 "docker-entrypoint.s…"   db         26 seconds ago   Up 25 seconds (healthy)   127.0.0.1:5432->5432/tcp
tasksteams-api-keycloak-1   quay.io/keycloak/keycloak:26.8.2   "/opt/keycloak/bin/k…"   keycloak   26 seconds ago   Up 25 seconds (healthy)   127.0.0.1:8180->8080/tcp
```

```text
tasksteams-api> python scripts/call.py GET /health
```

```text
HTTP/1.1 200 OK
date: Mon, 23 Nov 2026 08:45:37 GMT
content-length: 49
content-type: application/json
x-trace-id: 41c2523cbccc46d28d6ad6b0ff106a7a

{"status":"ok","version":"1.0.0","database":"up"}
```

The API in the container reaches the database by name. Now look at what you shipped (`exec` runs a command inside the running container; `-T` switches off the terminal so the output stays clean):

```text
tasksteams-api> docker compose exec -T api id
```

```text
uid=10001(app) gid=10001(app) groups=10001(app)
```

The process runs as user 10001, not root. The code folder is not writable for it:

```text
tasksteams-api> docker compose exec -T api sh -c "touch /srv/x"
```

```text
touch: cannot touch '/srv/x': Permission denied
```

```text
Python 3.14.10
```

```text
REPOSITORY           TAG       SIZE
tasksteams-api-api   latest    304MB
```

The image has Python 3.14.10 and is about 300 MB (the slim Python image plus the packages; no compilers). The log goes to the container's output, which Docker collects. The latest lines are the health checks calling `/health` every 10 seconds:

```text
tasksteams-api> docker compose logs api --no-log-prefix --tail 3
```

```text
{"time": "2026-11-23T08:45:22.641+00:00", "level": "INFO", "logger": "tasksteams.access", "message": "request", "traceId": "a1d3357a15bb48c095f351e277acec6d", "method": "GET", "path": "/health", "status": 200, "durationMs": 41.9, "userId": null}
{"time": "2026-11-23T08:45:32.888+00:00", "level": "INFO", "logger": "tasksteams.access", "message": "request", "traceId": "b32c71e1ccfb4aac84ba42054bec0fd4", "method": "GET", "path": "/health", "status": 200, "durationMs": 2.1, "userId": null}
{"time": "2026-11-23T08:45:37.974+00:00", "level": "INFO", "logger": "tasksteams.access", "message": "request", "traceId": "41c2523cbccc46d28d6ad6b0ff106a7a", "method": "GET", "path": "/health", "status": 200, "durationMs": 2.1, "userId": null}
```

Run the conformance script against the containerized API. It is the same black-box script as before:

```text
tasksteams-api> python scripts/conformance.py
```

```text
PASS  keycloak discovery (issuer matches, PKCE S256 offered)
PASS  token for alice (iss, aud tasks-api, sub, role admin, three scopes)
PASS  token for bob (role member only)
PASS  postgres reachable (127.0.0.1:5432 answers the Postgres protocol)
PASS  health (200, status ok, no token needed)
FAIL  me: header RateLimit-Limit missing or not a number
PASS  create team (201, Location and ETag set, team 85ad98d5-743f-4ea7-be32-269333d40686)
PASS  create project (201, project 54fb7405-8638-4762-8bcc-367ec296720f)
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

Stop and remove everything, including the database volume, when you are done:

```text
tasksteams-api> docker compose down -v --remove-orphans --rmi local
```

`--rmi local` also deletes the image that was built here, so nothing stays behind.

## How it works
`docker compose up --build` reads `docker-compose.yml`, merges `docker-compose.override.yml` over it (maps are merged key by key, lists are extended), builds the image, creates the network `tasksteams-net`, and starts the three services in dependency order. Inside the network each service is reachable by its name (`db`, `keycloak`, `api`). Only the three published ports are reachable from your computer, and only on `127.0.0.1`.

**Layers and cache.** Each Dockerfile instruction makes a layer. Putting `requirements.txt` first means a code change rebuilds only the last two layers (a second), while a dependency change rebuilds the install layer. **Multi-stage** means the compilers and caches of the builder never reach the runtime image.

**Where do migrations go?** The schema comes from the platform `db/schema.sql`, which Postgres runs once when the volume is empty. For a real system you would adopt it as the baseline migration of a migration tool (for example Alembic with `alembic stamp`) and add numbered migrations that run before the new image starts (a Compose service that exits, or a pipeline step). We do not add that here because the contract owns the schema (TDD decision D4).

New terms: **image** (a read-only template of a file system plus a start command); **container** (a running instance of an image); **layer** (one cached step of a build); **multi-stage build** (several `FROM` stages, only the last one ships); **build context** (the files sent to the builder); **wheel** (a prebuilt Python package); **exec form** (the JSON list form of `CMD`); **health check** (a command Docker runs to decide `healthy` or `unhealthy`).

Why this, not that:

| Choice | Alternative | Why we chose this |
|--------|-------------|-------------------|
| Override file | One big Compose file, or editing the platform file | The platform file stays byte-identical for all four backends; each backend adds only its own service |
| venv copied between stages | `pip install --user`, or installing into the system Python | One folder to copy, the same path in both stages, and nothing from the build leaks |
| `python:3.14.10-slim-trixie` | `-alpine`, `-bookworm`, distroless | Debian slim has wheels for everything we use and a shell for debugging; Alpine lacks wheels, distroless has no shell for the health check and `id` |
| Health check with Python | `curl` | No extra package in the image |
| Fixed uid 10001 | `useradd` with a free id | Predictable, and above the ids the host usually uses |

## Try it
Exercise: **a Dockerfile checker.** Copy `exercise/starter/check_dockerfile.py` into a folder of your own. It already checks that base images are pinned (not `latest`, tag present) and that the build is multi-stage. Finish `non_root_user` (the last `USER` instruction must not be `root` or `0`) and `has_healthcheck`. Run it against your own Dockerfile: `python check_dockerfile.py path/to/Dockerfile`. All four checks must pass.

**File: `exercise/starter/check_dockerfile.py`**
```python
"""Exercise 4: check a Dockerfile for the four rules of chapter 04.

Finish checks 3 and 4. Run:  python check_dockerfile.py            (checks ../../code/Dockerfile)
                             python check_dockerfile.py path/to/Dockerfile
"""
import sys
from pathlib import Path


def instructions(text):
    """The instruction lines (FROM, USER, ...) without comments and blank lines."""
    return [line.strip() for line in text.splitlines() if line.strip() and not line.strip().startswith("#")]


def pinned_images(lines):
    images = [line.split()[1] for line in lines if line.upper().startswith("FROM ")]
    return bool(images) and all(":" in image and not image.endswith(":latest") for image in images)


def multi_stage(lines):
    return sum(1 for line in lines if line.upper().startswith("FROM ")) >= 2


def non_root_user(lines):
    # TODO 3: collect the argument of every USER instruction; True when there is at least one
    # and the LAST one is not "root" and not "0" (a number or name may be followed by :group)
    raise NotImplementedError


def has_healthcheck(lines):
    # TODO 4: True when some instruction starts with HEALTHCHECK
    raise NotImplementedError


CHECKS = [
    ("pinned base images", pinned_images),
    ("multi-stage build", multi_stage),
    ("runs as a non-root user", non_root_user),
    ("has a health check", has_healthcheck),
]

if __name__ == "__main__":
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[2] / "code" / "Dockerfile"
    lines = instructions(path.read_text(encoding="utf-8"))
    passed = 0
    for name, check in CHECKS:
        ok = check(lines)
        passed += ok
        print(("PASS" if ok else "FAIL"), name)
    print(f"{passed} of {len(CHECKS)} checks passed")
```

<details><summary>Solution</summary>

**File: `exercise/solution/check_dockerfile.py`**
```python
"""Exercise 4: check a Dockerfile for the four rules of chapter 04 (solution).

Run:  python check_dockerfile.py            (checks ../../code/Dockerfile)
      python check_dockerfile.py path/to/Dockerfile
"""
import sys
from pathlib import Path


def instructions(text):
    """The instruction lines (FROM, USER, ...) without comments and blank lines."""
    return [line.strip() for line in text.splitlines() if line.strip() and not line.strip().startswith("#")]


def pinned_images(lines):
    images = [line.split()[1] for line in lines if line.upper().startswith("FROM ")]
    return bool(images) and all(":" in image and not image.endswith(":latest") for image in images)


def multi_stage(lines):
    return sum(1 for line in lines if line.upper().startswith("FROM ")) >= 2


def non_root_user(lines):
    users = [line.split(None, 1)[1].split(":")[0] for line in lines if line.upper().startswith("USER ")]
    return bool(users) and users[-1] not in ("root", "0")


def has_healthcheck(lines):
    return any(line.upper().startswith("HEALTHCHECK") for line in lines)


CHECKS = [
    ("pinned base images", pinned_images),
    ("multi-stage build", multi_stage),
    ("runs as a non-root user", non_root_user),
    ("has a health check", has_healthcheck),
]

if __name__ == "__main__":
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[2] / "code" / "Dockerfile"
    lines = instructions(path.read_text(encoding="utf-8"))
    passed = 0
    for name, check in CHECKS:
        ok = check(lines)
        passed += ok
        print(("PASS" if ok else "FAIL"), name)
    print(f"{passed} of {len(CHECKS)} checks passed")
```

Run from `exercise/solution` it checks `../../code/Dockerfile`:

```text
PASS pinned base images
PASS multi-stage build
PASS runs as a non-root user
PASS has a health check
4 of 4 checks passed
```

Only the **last** `USER` counts, because an image can switch users several times and the process runs as the final one.

</details>

## Check yourself
1. Why can the container not use `127.0.0.1:5432` for the database? <details><summary>Answer</summary>Inside the container `127.0.0.1` is the container itself. The database is another container, reachable by its service name `db` on the shared network.</details>
2. What do you gain from `--only-binary=:all:`? <details><summary>Answer</summary>The build fails when a wheel is missing instead of trying to compile, so you notice immediately that the Python version or the platform is wrong, and the runtime image needs no compiler.</details>
3. The API runs as uid 10001 and `/srv` belongs to root. Why is that good? <details><summary>Answer</summary>If an attacker finds a flaw in the app, they cannot change the application code or install tools; they run as an unprivileged user in a container.</details>
4. Why are `ENV PYTHONUNBUFFERED=1` and logging to stdout the right pair for containers? <details><summary>Answer</summary>Docker collects what a process writes to stdout and stderr; unbuffered writes appear at once, and the platform decides where to store logs, so the app needs no log files.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Error response from daemon: ports are not available: exposing port TCP 127.0.0.1:8000 -> 127.0.0.1:0: listen tcp4 127.0.0.1:8000: bind: Only one usage of each socket address (protocol/network address/port) is normally permitted.` | Another program, often the Uvicorn of chapter 03 or another backend, uses port 8000 | Stop it (Ctrl+C), then `docker compose up -d --wait api` again |
| `level=warning msg="The \"POSTGRES_DB\" variable is not set. Defaulting to a blank string."` (five lines like it) and a database that does not start | There is no `.env` file next to `docker-compose.yml` | `cp .env.example .env` (PowerShell: `Copy-Item .env.example .env`) |
| `docker compose ps` shows the API as `unhealthy` or restarting | The app fails to start (wrong `DATABASE_URL`, no `JWKS_URL`) or `/health` answers 503 because Postgres is down | `docker compose logs api` shows the reason; fix the setting in the override file and run `up -d --build --wait` again |
| The image keeps old code after an edit | `docker compose up` without `--build` reuses the image | Add `--build` |
| Every request answers 503 `The sign-in keys cannot be fetched right now.` | `JWKS_URL` uses `127.0.0.1` inside the container | Use `http://keycloak:8080/realms/tasksteams/protocol/openid-connect/certs` |

## Best practice
Build small images from pinned bases in stages, run as a non-root user, keep secrets out of the image and the build context, and give every service a health check. Source: Docker documentation, Building best practices https://docs.docker.com/build/building/best-practices/ and Multi-stage builds https://docs.docker.com/build/building/multi-stage/

## Next lesson
05. Hardening: rate limits and `RateLimit-*` headers (which turns the last conformance check green), security headers, CORS, a request size limit, security logging, a read-only container, the OWASP API Top 10 walk-through and a backup and restore.
