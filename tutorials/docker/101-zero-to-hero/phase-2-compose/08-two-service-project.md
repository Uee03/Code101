---
track: docker
level: 101
phase: 2
phase_name: compose
lesson: 08
title: Project: a two-service app
time: 75 min (two sittings)
prerequisites: [101.2.07]
versions: { docker: "29.9.3", desktop: "4.99.0", compose: "5.7.0", wsl: "3.0.5 / Ubuntu-26.04" }
verified: 2026-11-23 on Windows 11, Docker 29.9.3, Compose v5.7.0
source: source/docker/101-zero-to-hero/phase-2-compose/08-two-service-project/
assets: []
---

# 08. Project: a two-service app

## Why it matters
A museum has a front desk and a ledger kept in a back office. You will build a front-desk web API and a Postgres ledger that remembers visits. Replacing the front desk must not throw away the ledger.

## What you will build
A two-service visitor-counting API: / increments a persisted count, /health checks readiness without incrementing it, and database data survives ordinary shutdown.

## Before you start
- Complete lesson 07. Docker must be running: docker info must show a Server section.
- Author baseline: Windows 11, CLI/Engine 29.9.3, Desktop 4.99.0, Compose v5.7.0, WSL2 Ubuntu-26.04, 2026-11-23.
  Windows labs actually ran. macOS/Linux installation routes are official-docs checked, not machine-tested.
  WSL integration is off on the author machine; use PowerShell with Desktop rather than installing a second engine in Ubuntu.
- Time: about 75 minutes in two sittings (about 5 minutes per new idea plus setup; Docker is already installed). The marked break comes before "Run it": the first sitting is typing and reading the files, the second is running, the exercise and cleanup.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/docker/101-zero-to-hero/phase-2-compose/08-two-service-project/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Image tags were confirmed by successful pulls on **2026-11-23**. Explicit version-family tags can receive patches:
  `python:3.13-slim`, `postgres:17-alpine`, `nginx:1.28-alpine`, `alpine:3.22`.
  `hello-world:latest` is the official diagnostic exception, not a production choice.
- Windows uses PowerShell 5.1. Docker commands are identical on macOS/Linux unless noted. Use `curl.exe` on Windows
  (bare curl is a PowerShell alias); replace it with `curl` on macOS/Linux. Ubuntu Engine users: prefix every Docker command
  with `sudo`. Desktop users: do not use sudo. No host Python installation is needed.

## Steps

### Step 1. Make your working folder
A **terminal** is a window for typed commands. Windows: Start > type PowerShell > **Windows PowerShell**.
macOS: Applications > Utilities > **Terminal**. Linux: open **Terminal** from the application menu.
Do not type the prompt (`PS ...>` or `$`); type only each command, then press Enter.

Windows, from any folder:

**Commands — folder: `any folder`**
```powershell
New-Item -ItemType Directory -Force "$HOME\code101\docker\lesson08" | Out-Null
Set-Location "$HOME\code101\docker\lesson08"
```
macOS/Linux, from any folder:

**Commands — folder: `any folder`**
```bash
mkdir -p ~/code101/docker/lesson08
cd ~/code101/docker/lesson08
```

Expected result: your terminal is inside `lesson08`. The prompt usually shows the folder; check with `Get-Location`
(Windows) or `pwd` (macOS/Linux). If lost, the Set-Location/cd line above returns here. All subsequent commands run here
unless marked otherwise. Stop other Docker lessons before using port 8080.

Create each file in a plain-text editor: **File > New**, paste its full contents, **File > Save As**, save in this folder.
Windows Notepad: **Save as type: All files**, encoding **UTF-8**, exact filename. In File Explorer enable
**View > Show > File name extensions** to catch accidental `.txt` suffixes. macOS TextEdit: **Format > Make Plain Text**;
disable automatic `.txt` extension when saving. Linux: use your plain-text editor. Save before running;
a dot on an editor tab usually means unsaved changes.
### Step 2. Create the supplied web app
Copy this complete Python program into app.py. It is a supplied program for learning Docker; no host Python install is needed.

**File: `app.py`**
```python
import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
import psycopg


def connect():
    return psycopg.connect(
        host=os.environ["DB_HOST"],
        dbname=os.environ["POSTGRES_DB"],
        user=os.environ["POSTGRES_USER"],
        password=os.environ["POSTGRES_PASSWORD"],
        connect_timeout=3,
    )


class Page(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            with connect() as connection:
                if self.path == "/health":
                    connection.execute("SELECT 1")
                    result = {"status": "ready"}
                elif self.path == "/":
                    connection.execute("CREATE TABLE IF NOT EXISTS counter "
                                       "(id INTEGER PRIMARY KEY, visits INTEGER NOT NULL)")
                    visits = connection.execute(
                        "INSERT INTO counter VALUES (1, 1) "
                        "ON CONFLICT (id) DO UPDATE SET visits = counter.visits + 1 "
                        "RETURNING visits"
                    ).fetchone()[0]
                    result = {"message": os.environ["GREETING"], "visits": visits}
                else:
                    self.send_response(404)
                    self.end_headers()
                    return
            self.send_response(200)
        except psycopg.OperationalError:
            result = {"error": "Database is not ready; try again"}
            self.send_response(503)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write((json.dumps(result) + "\n").encode())


print("Code101 API listening on 8000", flush=True)
HTTPServer(("0.0.0.0", 8000), Page).serve_forever()
```
A **database** stores structured information; Postgres is the database program. **SQL** means Structured Query Language,
used to work with tables. psycopg is a Python library (reusable code) that talks to Postgres.
connect() reads database settings and opens a connection, with a three-second timeout. The `with` block closes it afterward,
committing successful changes. Page handles a browser GET; it sends JSON (named values as text) on success,
or a 503 response if the database is not yet reachable. The server listens on container port 8000; -u makes logs immediate.
`/health` runs SELECT 1, proving a connection works without changing the count. `/` creates a counter table if needed,
inserts row 1 on first visit, otherwise increments it using ON CONFLICT, and returns the count. RETURNING retrieves the new value.
Unknown paths get 404 (not found). JSON is a text exchange format for named values, lists and objects, not a picture or web page.
The context manager commits the counter update before returning the response; real applications need fuller error handling.

### Step 3. Create the image files

**File: `requirements.txt`**
```text
psycopg[binary]==3.2.9
```

| Line | Explanation (changing a path/value requires matching its consumer) |
|---|---|
| 1 | Pin the Postgres Python driver to 3.2.9; [binary] requests the bundled binary option, == means exactly this version. |

**File: `Dockerfile`**
```dockerfile
FROM python:3.13-slim
LABEL code101.owner="docker-101"
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
CMD ["python", "-u", "app.py"]
```

| Line | Explanation (changing a path/value requires matching its consumer) |
|---|---|
| 1 | Start with this tagged Python/Linux image; changing it changes the runtime. The slim variant has fewer extra tools. |
| 2 | Attach course ownership metadata. Labels are not a secret store. |
| 3 | Make /app the folder for later instructions and the running command. |
| 4 | Copy the dependency list from the build context into /app (the dot). |
| 5 | Install the pinned driver during the build; -r reads the list, --no-cache-dir omits the pip download cache. |
| 6 | Copy the app into /app; host edits require a rebuild. |
| 7 | Default startup command as a JSON list. -u sends logs immediately; app.py must match the copied filename. |

**File: `.dockerignore`**
```text
__pycache__/
*.pyc
.git/
.env
.env.*
secrets/
```

| Line | Explanation (changing a path/value requires matching its consumer) |
|---|---|
| 1 | Exclude generated Python bytecode folders from the build context. |
| 2 | Exclude individual bytecode files; * matches any name. |
| 3 | Exclude version-history files from the image build. |
| 4 | Exclude local runtime settings; Compose can still read them on the host. |
| 5 | Exclude alternate environment files, including .env.example, from the build. |
| 6 | Exclude the entire host secrets directory from images. |

The Dockerfile instructions are not terminal commands. Its build context is this folder; COPY takes only the app and dependency list.
RUN installs dependencies during the build, while CMD starts the finished container. Changing .env does not need a build;
changing app.py or requirements.txt does.

### Step 4. Create local settings and the safe example
Create these as **two separate files** in your lesson folder. The second is safe to share; the first is where local values belong.
The password below is deliberately public and disposable. Never reuse it on a real service or replace it with a real secret in shared files.

**File: `.env.example`**
```dotenv
POSTGRES_USER=learner
POSTGRES_PASSWORD=local-demo-only
POSTGRES_DB=workshop
GREETING=Hello from the visitor counter
```

| Line | Explanation (changing a path/value requires matching its consumer) |
|---|---|
| 1 | Initial database user on an empty volume; changing this does not rename an existing user. |
| 2 | PUBLIC, throwaway classroom password, never a real secret. Changing it does not rotate an existing database password. |
| 3 | Initial database name on an empty volume; changing this does not rename an existing database. |
| 4 | Public displayed message. Changing this requires recreation, not an image rebuild. Spaces belong to the value. |

**File: `.env`**
```dotenv
POSTGRES_USER=learner
POSTGRES_PASSWORD=local-demo-only
POSTGRES_DB=workshop
GREETING=Hello from the visitor counter
```

| Line | Explanation (changing a path/value requires matching its consumer) |
|---|---|
| 1 | Initial database user on an empty volume; changing this does not rename an existing user. |
| 2 | PUBLIC, throwaway classroom password, never a real secret. Changing it does not rotate an existing database password. |
| 3 | Initial database name on an empty volume; changing this does not rename an existing database. |
| 4 | Public displayed message. Changing this requires recreation, not an image rebuild. Spaces belong to the value. |

An **environment variable** is a named value passed to a process. A real **secret** is a password/token that must not be shared.
.env is plain text, not encryption. Compose reads .env for `${NAME}` substitution; the service must also specify environment/env_file
for values to reach its process. A host environment variable can override the .env interpolation value; use a fresh terminal if results differ.
If you take the files from the optional pack instead, note that it ships `.env.example`, not `.env`: copy it to `.env` first (Windows PowerShell: `Copy-Item .env.example .env`; macOS and Linux: `cp .env.example .env`). Your own project should track only the safe `.env.example` and keep the real `.env` out of Git.

### Step 5. Ignore local files in Git
**Git** records project-file changes. If you later use Git, create this full .gitignore first:

**File: `.gitignore`**
```gitignore
.env
.env.*
!.env.example
secrets/
__pycache__/
```

| Line | Explanation (changing a path/value requires matching its consumer) |
|---|---|
| 1 | Do not track local settings in Git. This does not remove files already tracked. |
| 2 | Also ignore alternate environment files. |
| 3 | The ! exception allows the safe example to be tracked; order after the broad rule matters. |
| 4 | Do not track secret files; this is not encryption. |
| 5 | Do not track generated Python bytecode. |

Never commit real .env files or secrets. An ignore file does not undo an earlier commit; if a real secret was shared,
rotate/revoke it rather than assuming deletion makes it safe. We intentionally do not require Git installed for this lesson.

### Step 6. Create the complete Compose configuration
**Compose** starts related containers from a configuration. **YAML** is the text format it reads: indentation groups settings.
A **service** is a named container configuration. Use spaces, never tabs; child keys are two spaces deeper than their parent.
Save docker-compose.yml next to Dockerfile and .env:

**File: `docker-compose.yml`**
```yaml
services:
  web:
    image: "${COMPOSE_PROJECT_NAME}-web:demo"
    build: .
    ports:
      - "127.0.0.1:8080:8000"
    environment:
      DB_HOST: db
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
      GREETING: ${GREETING}
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2)"]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 5s
    depends_on:
      db:
        condition: service_healthy
  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      interval: 2s
      timeout: 3s
      retries: 20
      start_period: 5s
volumes:
  db_data:
```

| Line | Explanation (changing a path/value requires matching its consumer) |
|---|---|
| 1 | Group named container configurations in this project. |
| 2 | Name the web service; peers can reach it as web. |
| 3 | Name the built image with the project prefix. Compose sets COMPOSE_PROJECT_NAME automatically from -p; demo is the tag. |
| 4 | Build the Dockerfile from this folder; the dot selects the build context. |
| 5 | Group host-to-container port mappings. |
| 6 | Bind host loopback only: host port 8080 forwards to web port 8000. Change the middle number if occupied. |
| 7 | Pass these named values to the process at runtime, not into the image. |
| 8 | Use internal service-name lookup. localhost here would point to web itself, not Postgres. |
| 9 | Fill this value from .env (or an overriding host environment variable), then inject it into this service. Classroom credentials only. |
| 10 | Fill this value from .env (or an overriding host environment variable), then inject it into this service. Classroom credentials only. |
| 11 | Fill this value from .env (or an overriding host environment variable), then inject it into this service. Classroom credentials only. |
| 12 | Fill this value from .env (or an overriding host environment variable), then inject it into this service. Classroom credentials only. |
| 13 | Group a repeated readiness command and its timing. |
| 14 | Run Python directly (no shell) to check web on its own port 8000. /health checks db without counting a visit. |
| 15 | Time between checks; larger values detect readiness/failure more slowly. |
| 16 | Maximum duration per check; exceeding this fails the check. |
| 17 | Consecutive failures before unhealthy; not the number of times you retry the request yourself. |
| 18 | Startup grace period: failures do not count yet; a successful check can still establish health. |
| 19 | Group prerequisites. Short form controls start order, not readiness. |
| 20 | Name the database service (or the dependency); web reaches it as db. |
| 21 | Wait for db to pass its healthcheck before starting web. This gates startup only, not recovery. |
| 22 | Name the database service (or the dependency); web reaches it as db. |
| 23 | Use the checked Postgres 17 Alpine tag; there is no published host database port. |
| 24 | Pass these named values to the process at runtime, not into the image. |
| 25 | Fill this value from .env (or an overriding host environment variable), then inject it into this service. Classroom credentials only. |
| 26 | Fill this value from .env (or an overriding host environment variable), then inject it into this service. Classroom credentials only. |
| 27 | Fill this value from .env (or an overriding host environment variable), then inject it into this service. Classroom credentials only. |
| 28 | Under db: attach storage. At the left edge: declare project-owned volumes. Indentation changes the meaning. |
| 29 | Mount named storage at the Postgres 17 data directory. Another volume name selects different data; Postgres 18 has a different layout. |
| 30 | Group a repeated readiness command and its timing. |
| 31 | Use a container shell to run pg_isready; $$ defers expansion to the container. -U selects user, -d database. This checks acceptance, not schema/authentication. |
| 32 | Time between checks; larger values detect readiness/failure more slowly. |
| 33 | Maximum duration per check; exceeding this fails the check. |
| 34 | Consecutive failures before unhealthy; not the number of times you retry the request yourself. |
| 35 | Startup grace period: failures do not count yet; a successful check can still establish health. |
| 36 | Under db: attach storage. At the left edge: declare project-owned volumes. Indentation changes the meaning. |
| 37 | Declare default volume options; Compose prefixes its name with the project name. |
The longer depends_on waits for db's healthcheck before starting web. The double-dollar signs belong in YAML:
Compose sends a literal dollar onward, so the container shell reads its own POSTGRES_USER and POSTGRES_DB.
A healthcheck does not automatically restart a failed container. Startup order is not a complete availability strategy.
There is intentionally **no ports section under db**. The default project network connects web to db privately;
5432/tcp in status means an internal port, not host publication. Host port 5432 belongs to the Databases track.

### Step 7. Connect your IDE
An **API** (application programming interface) is a way for programs to exchange requests and responses; here it is web addresses
returning **JSON** (named values expressed as text). An **IDE** (integrated development environment) is an editor with programming
and sometimes database tools. For editing, use the IDE's **File > Open Folder** and select your lesson folder; app.py,
Dockerfile and docker-compose.yml are ordinary text files. After changing app.py, save and run the same up -d --build command
in Run it; after changing only .env, up -d is sufficient to recreate changed settings.

For database tools, distinguish two addresses:
- **Containers:** this Python app connects to `db:5432`; localhost inside web refers to web itself.
- **Host IDE:** the **Databases track** publishes Postgres on **127.0.0.1:5432**. There, localhost means your host computer,
  and the published host port forwards into its database container. Use that track's database credentials.
- **This Docker 101 project does not publish Postgres.** A host IDE cannot connect to it at localhost:5432.
  Do not add a database ports section to this file; host port 5432 is reserved for the Databases track.
  A connection you happen to see on 5432 may belong to another running track, not to this project.

A full **example** host IDE profile, for a Databases-track database configured with these classroom values:

| Setting | Example value | Meaning |
|---|---|---|
| Connection type / driver | PostgreSQL | Use the Postgres driver, not MySQL or SQLite. |
| Profile name | Code101 local workshop | A label in your IDE, not the server/database name. |
| Host | 127.0.0.1 | Host loopback; localhost is an equivalent local name here. |
| Port | 5432 | The Databases track's published host port, not web port 8080. |
| Database | workshop | Must match POSTGRES_DB in that track's .env. |
| User | learner | Must match POSTGRES_USER in that track's .env. |
| Password | local-demo-only | Public demo value only; use the actual local password set in that track. |
| SSL mode | disable (local classroom only) | No transport encryption for this loopback-only demonstration; remote systems need appropriate TLS settings. |
| URL (if requested) | jdbc:postgresql://127.0.0.1:5432/workshop | Java-driver connection URL; password belongs in its separate password field, never a saved URL. |

SSL/TLS means Secure Sockets Layer / Transport Layer Security: encrypted connection protocols; modern remote systems use TLS.
A URL (Uniform Resource Locator) is a destination address.

For example, in JetBrains DataGrip after installing/opening it: **Database > + > Data Source > PostgreSQL**,
fill the **General** fields from your Databases lesson, select **Download missing driver files** if offered, then **Test Connection**,
**Apply**, **OK**. These IDE UI steps are explanatory, not a claimed IDE test on the author machine.
Do **not** test the example profile against this Docker lab: it has no host database route. The Databases lessons give the full
published database setup. Use their actual values if they differ from this illustrative profile; leave this Compose configuration unchanged.

> **Break point: end of the first sitting.** All files are saved. You can stop here. When you return, open a terminal, move to your lesson folder with the `Set-Location` or `cd` line from Step 1 and start "Run it".

## Run it
From your lesson folder, start this throwaway project. `-p` supplies a project name that groups its containers, network and volumes;
`up` creates/starts services, `-d` detaches, `--build` builds the web image. Keep the same project name for every command.

**Commands — folder: `your lesson folder`**
```powershell
docker compose -p code101-verify-08-two-service-project up -d --build
```
Expected output, **excerpt** (progress is longer):

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
#11 naming to docker.io/library/code101-verify-08-two-service-project-web:demo done
 Volume code101-verify-08-two-service-project_db_data Created 
 Volume code101-verify-08-two-service-project_db_data Created 
 Network code101-verify-08-two-service-project_default Created 
 Network code101-verify-08-two-service-project_default Created 
 Container code101-verify-08-two-service-project-db-1 Created 
 Container code101-verify-08-two-service-project-web-1 Created 
 Container code101-verify-08-two-service-project-db-1 Started 
 Container code101-verify-08-two-service-project-db-1 Healthy 
 Container code101-verify-08-two-service-project-web-1 Started
```
Check status; fields are name, state, health, ports. Web may briefly say starting until its first healthcheck; wait a few seconds and rerun this status command. This is not a failed startup:

**Commands — folder: `your lesson folder`**
```powershell
docker compose -p code101-verify-08-two-service-project ps --format "{{.Name}} | {{.State}} | {{.Health}} | {{.Ports}}"
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
code101-verify-08-two-service-project-db-1 | running | healthy | 5432/tcp
code101-verify-08-two-service-project-web-1 | running | starting | 127.0.0.1:8080->8000/tcp
```
Also check which services are running:

**Commands — folder: `your lesson folder`**
```powershell
docker compose -p code101-verify-08-two-service-project ps --services --status running
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
db
web
```
Open `http://127.0.0.1:8080` or send a terminal request:

**Commands — folder: `your lesson folder`**
```powershell
curl.exe -fsS http://127.0.0.1:8080/
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
{"message": "Hello from the visitor counter", "visits": 1}
```
If the first request arrives before readiness, wait a few seconds and try again. Read web logs (the container's printed output, not a secret dump):

**Commands — folder: `your lesson folder`**
```powershell
docker compose -p code101-verify-08-two-service-project logs --no-color --tail 3 web
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
web-1  | Code101 API listening on 8000
web-1  | 172.18.0.1 - - [23/Nov/2026 06:19:00] "GET / HTTP/1.1" 200 -
```
Check Postgres acceptance inside its own container:

**Commands — folder: `your lesson folder`**
```powershell
docker compose -p code101-verify-08-two-service-project exec -T db pg_isready -U learner -d workshop
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
/run/postgresql:5432 - accepting connections
```
Check the API readiness route (this does not count as a visit):

**Commands — folder: `your lesson folder`**
```powershell
curl.exe -fsS http://127.0.0.1:8080/health
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
{"status": "ready"}
```
Preserve the data while removing the services:

**Commands — folder: `your lesson folder`**
```powershell
docker compose -p code101-verify-08-two-service-project down --remove-orphans
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Container code101-verify-08-two-service-project-web-1 Stopping 
 Container code101-verify-08-two-service-project-web-1 Stopped 
 Container code101-verify-08-two-service-project-web-1 Removing 
 Container code101-verify-08-two-service-project-web-1 Removed 
 Container code101-verify-08-two-service-project-db-1 Stopping 
 Container code101-verify-08-two-service-project-db-1 Stopped 
 Container code101-verify-08-two-service-project-db-1 Removing 
 Container code101-verify-08-two-service-project-db-1 Removed 
 Network code101-verify-08-two-service-project_default Removing 
 Network code101-verify-08-two-service-project_default Removed
```

**Commands — folder: `your lesson folder`**
```powershell
docker compose -p code101-verify-08-two-service-project up -d
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Network code101-verify-08-two-service-project_default Creating 
 Network code101-verify-08-two-service-project_default Creating 
 Network code101-verify-08-two-service-project_default Created 
 Network code101-verify-08-two-service-project_default Created 
 Container code101-verify-08-two-service-project-db-1 Creating 
 Container code101-verify-08-two-service-project-db-1 Created 
 Container code101-verify-08-two-service-project-web-1 Creating 
 Container code101-verify-08-two-service-project-web-1 Created 
 Container code101-verify-08-two-service-project-db-1 Starting 
 Container code101-verify-08-two-service-project-db-1 Started 
 Container code101-verify-08-two-service-project-db-1 Waiting 
 Container code101-verify-08-two-service-project-db-1 Healthy 
 Container code101-verify-08-two-service-project-web-1 Starting 
 Container code101-verify-08-two-service-project-web-1 Started
```
Request the counter again after it is ready:

**Commands — folder: `your lesson folder`**
```powershell
curl.exe -fsS http://127.0.0.1:8080/
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
{"message": "Hello from the visitor counter", "visits": 2}
```
The count is 2 rather than 1 because the named volume survived. Browser visits also increase it;
if you opened the page before the terminal probe, your numbers will be higher. Health requests do not increment it.
Stop and remove this project when finished. **Warning:** `-v` deletes its declared named volumes and all data inside them.
For valuable data, omit -v and take a backup first. `--remove-orphans` also removes services from this project no longer present in the file.

**Commands — folder: `your lesson folder`**
```powershell
docker compose -p code101-verify-08-two-service-project down -v --remove-orphans
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Container code101-verify-08-two-service-project-web-1 Stopping 
 Container code101-verify-08-two-service-project-web-1 Stopped 
 Container code101-verify-08-two-service-project-web-1 Removing 
 Container code101-verify-08-two-service-project-web-1 Removed 
 Container code101-verify-08-two-service-project-db-1 Stopping 
 Container code101-verify-08-two-service-project-db-1 Stopped 
 Container code101-verify-08-two-service-project-db-1 Removing 
 Container code101-verify-08-two-service-project-db-1 Removed 
 Volume code101-verify-08-two-service-project_db_data Removing 
 Network code101-verify-08-two-service-project_default Removing 
 Volume code101-verify-08-two-service-project_db_data Removed 
 Network code101-verify-08-two-service-project_default Removed
```
Remove just your built web image (the downloaded base images/build cache are separate):

**Commands — folder: `your lesson folder`**
```powershell
docker image rm code101-verify-08-two-service-project-web:demo
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Untagged: code101-verify-08-two-service-project-web:demo
Deleted: sha256:f56e06a5d379445e2026c572448fde56b325ebc3036caa01f601c4aaf61f3ef8
```

## How it works
Compose waits for db acceptance, then starts web. Web has its own healthcheck that calls /health from inside the container on port 8000. The first request to / creates/increments a row and returns visits: 1; ordinary down/up preserves that row, so another visit becomes 2. The code opens a database connection for each request and commits successful updates. This is a small local demo: no authentication, TLS termination or production process management is claimed.

New terms for this lesson (also in the track glossary):

- **API**: A way for programs to exchange requests and responses; here, web addresses that return JSON.
- **JSON**: Named values written as text.
- **IDE**: Integrated development environment: an editor with programming and sometimes database tools.
- **SSL/TLS**: Encryption protocols for network connections.
- **URL**: Uniform Resource Locator, a destination address.
- **healthcheck**: A command Docker runs repeatedly to see whether a service is ready (see lesson 07).
- **named volume**: Docker-managed storage that outlives containers; it holds the visit count.
- **persisted**: Saved so that it survives restarting the containers.

## Try it
Stop/clean up your lesson first. Make a new folder `practice` inside your lesson folder and copy every file of your finished lesson into it, including the dotfiles (`.env`, `.env.example`, `.gitignore`, `.dockerignore`) (not `practice` itself). This is the finished baseline from the Steps. Open a terminal inside practice:

**Commands — folder: `your lesson folder`**
```powershell
Set-Location practice
```

**Commands — folder: `your lesson folder`**
```bash
cd practice
```
Expected result: you are inside `practice`, working on your own copy.
**Exercise:** make the project welcome library visitors by greeting them with `Welcome to the library`. Decide which files hold that setting. Keep /health free of side effects, retain the named volume, and keep the database private.
<details><summary>Solution</summary>

**File: `practice/.env`**
```dotenv
POSTGRES_USER=learner
POSTGRES_PASSWORD=local-demo-only
POSTGRES_DB=workshop
GREETING=Welcome to the library
```

**File: `practice/.env.example`**
```dotenv
POSTGRES_USER=learner
POSTGRES_PASSWORD=local-demo-only
POSTGRES_DB=workshop
GREETING=Welcome to the library
```
All other files are genuinely identical to the full Steps versions; keep their exact filenames and contents.
From practice repeat the same startup/status/logs/cleanup procedure in Run it: the only folder difference is practice,
and the same project name is reused after the original has been removed. Here are start and response for this exact solution:

**Commands — folder: `practice`**
```powershell
docker compose -p code101-verify-08-two-service-project up -d --build
```
Expected output, **excerpt** (progress is longer):

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
#11 naming to docker.io/library/code101-verify-08-two-service-project-web:demo done
 Volume code101-verify-08-two-service-project_db_data Created 
 Volume code101-verify-08-two-service-project_db_data Created 
 Network code101-verify-08-two-service-project_default Created 
 Network code101-verify-08-two-service-project_default Created 
 Container code101-verify-08-two-service-project-db-1 Created 
 Container code101-verify-08-two-service-project-web-1 Created 
 Container code101-verify-08-two-service-project-db-1 Started 
 Container code101-verify-08-two-service-project-db-1 Healthy 
 Container code101-verify-08-two-service-project-web-1 Started
```

**Commands — folder: `practice`**
```powershell
curl.exe -fsS http://127.0.0.1:8080/
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
{"message": "Welcome to the library", "visits": 1}
```
Check status and logs in practice with the identical commands from Run it (same project name).
Then clean up **from practice** using the exact final commands below:

**Commands — folder: `practice`**
```powershell
docker compose -p code101-verify-08-two-service-project down -v --remove-orphans
docker image rm code101-verify-08-two-service-project-web:demo
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Container code101-verify-08-two-service-project-web-1 Stopping 
 Container code101-verify-08-two-service-project-web-1 Stopped 
 Container code101-verify-08-two-service-project-web-1 Removing 
 Container code101-verify-08-two-service-project-web-1 Removed 
 Container code101-verify-08-two-service-project-db-1 Stopping 
 Container code101-verify-08-two-service-project-db-1 Stopped 
 Container code101-verify-08-two-service-project-db-1 Removing 
 Container code101-verify-08-two-service-project-db-1 Removed 
 Volume code101-verify-08-two-service-project_db_data Removing 
 Network code101-verify-08-two-service-project_default Removing 
 Volume code101-verify-08-two-service-project_db_data Removed 
 Network code101-verify-08-two-service-project_default Removed
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Untagged: code101-verify-08-two-service-project-web:demo
Deleted: sha256:aa273806cb93d9beedea95cd330a10a3eec7054068d0fc8cbe54bbe000200843
```
On macOS/Linux the Docker commands are identical; use curl instead of curl.exe. Ubuntu: sudo before Docker.
</details>


## Check yourself
1. Why does /health not increase visits?
   <details><summary>Answer</summary>Healthchecks run repeatedly and should not mutate business data.</details>
2. Which command destroys the count?
   <details><summary>Answer</summary>docker compose down -v deletes the named database volume.</details>
3. What database address does web use?
   <details><summary>Answer</summary>db on internal port 5432.</details>
4. What address does a host IDE use in the Databases track?
   <details><summary>Answer</summary>127.0.0.1 (or localhost) on published host port 5432; no such host route is published here.</details>

## Common mistakes
Rows marked typical message were not captured here; the others were deliberately triggered. IDs vary. Never remove an unfamiliar container to fix a conflict.

| Error text | Cause | Fix |
|---|---|---|
| `Bind for 127.0.0.1:8080 failed: port is already allocated` | Another running container owns host port 8080 | Run docker ps; stop only your earlier container, or change host 8080 to 8081 (leave the container port unchanged). |
| `did not find expected key` | ports indented 3 spaces instead of 4 | Use spaces, align ports with image under web, restore the full file, then docker compose config --quiet. |
| `check if the path is correct and if the daemon is running` | No reachable engine endpoint; author used a nonexistent pipe without stopping Desktop | Start Desktop and wait for Engine running; on Ubuntu use sudo systemctl start docker. Inspect docker context ls; do not change a working context blindly. |
| `no configuration file provided: not found` (typical message) | You ran `docker compose` in the wrong folder, one without `docker-compose.yml` | Move to your lesson folder (the `Set-Location` or `cd` line in Step 1) and repeat the command. |
| `env file` ... `.env not found: stat` ... `no such file or directory` (typical message) | `.env` is missing, for example only `.env.example` exists | Create `.env` (Step 4) or run the copy command shown there, then run `up` again. |

## Best practice
Make readiness checks lightweight and side-effect free, and preserve valuable volumes during routine shutdown. Source: Docker Compose startup order https://docs.docker.com/compose/how-tos/startup-order/

## Next lesson
You have finished Docker 101. Continue with the Databases track for SQL and host IDE connections; this track leaves Postgres unexposed.
