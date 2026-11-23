---
track: docker
level: 101
phase: 2
phase_name: compose
lesson: 06
title: Networks and Compose basics
time: 40 min
prerequisites: [101.2.05]
versions: { docker: "29.9.3", desktop: "4.99.0", compose: "5.7.0", wsl: "3.0.5 / Ubuntu-26.04" }
verified: 2026-11-23 on Windows 11, Docker 29.9.3, Compose v5.7.0
source: source/docker/101-zero-to-hero/phase-2-compose/06-networks-and-compose/
assets: []
---

# 06. Networks and Compose basics

## Why it matters
A cafe counter asks its stockroom for supplies by name, not by the cafe street address. Containers also communicate by service name. Compose is your floor plan: it starts a web counter and a Postgres stockroom in the same private communication space.

## What you will build
A Python web app on 127.0.0.1:8080 that connects to Postgres by the service name db. Postgres is not published to the host.

## Before you start
- Complete lesson 05. Docker must be running: docker info must show a Server section.
- Author baseline: Windows 11, CLI/Engine 29.9.3, Desktop 4.99.0, Compose v5.7.0, WSL2 Ubuntu-26.04, 2026-11-23.
  Windows labs actually ran. macOS/Linux installation routes are official-docs checked, not machine-tested.
  WSL integration is off on the author machine; use PowerShell with Desktop rather than installing a second engine in Ubuntu.
- Time: about 40 minutes (about 5 minutes per new idea plus setup; Docker is already installed).
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/docker/101-zero-to-hero/phase-2-compose/06-networks-and-compose/` (on that page choose **Code, Download ZIP**, or run
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
New-Item -ItemType Directory -Force "$HOME\code101\docker\lesson06" | Out-Null
Set-Location "$HOME\code101\docker\lesson06"
```
macOS/Linux, from any folder:

**Commands — folder: `any folder`**
```bash
mkdir -p ~/code101/docker/lesson06
cd ~/code101/docker/lesson06
```

Expected result: your terminal is inside `lesson06`. The prompt usually shows the folder; check with `Get-Location`
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
                name = connection.execute("SELECT current_database()").fetchone()[0]
            body = json.dumps({"message": os.environ["GREETING"],
                               "database": name, "host": os.environ["DB_HOST"]})
            self.send_response(200)
        except psycopg.OperationalError:
            body = json.dumps({"error": "Database is not ready; try again"})
            self.send_response(503)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write((body + "\n").encode())


print("Code101 web listening on 8000", flush=True)
HTTPServer(("0.0.0.0", 8000), Page).serve_forever()
```
A **database** stores structured information; Postgres is the database program. **SQL** means Structured Query Language,
used to work with tables. psycopg is a Python library (reusable code) that talks to Postgres.
connect() reads database settings and opens a connection, with a three-second timeout. The `with` block closes it afterward,
committing successful changes. Page handles a browser GET; it sends JSON (named values as text) on success,
or a 503 response if the database is not yet reachable. The server listens on container port 8000; -u makes logs immediate.
`SELECT current_database()` asks Postgres which database is connected; fetchone()[0] reads the returned name.

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
GREETING=Hello from Compose
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
GREETING=Hello from Compose
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
    depends_on:
      - db
  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - db_data:/var/lib/postgresql/data
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
| 13 | Group prerequisites. Short form controls start order, not readiness. |
| 14 | Start db before web; db may still be initializing. |
| 15 | Name the database service (or the dependency); web reaches it as db. |
| 16 | Use the checked Postgres 17 Alpine tag; there is no published host database port. |
| 17 | Pass these named values to the process at runtime, not into the image. |
| 18 | Fill this value from .env (or an overriding host environment variable), then inject it into this service. Classroom credentials only. |
| 19 | Fill this value from .env (or an overriding host environment variable), then inject it into this service. Classroom credentials only. |
| 20 | Fill this value from .env (or an overriding host environment variable), then inject it into this service. Classroom credentials only. |
| 21 | Under db: attach storage. At the left edge: declare project-owned volumes. Indentation changes the meaning. |
| 22 | Mount named storage at the Postgres 17 data directory. Another volume name selects different data; Postgres 18 has a different layout. |
| 23 | Under db: attach storage. At the left edge: declare project-owned volumes. Indentation changes the meaning. |
| 24 | Declare default volume options; Compose prefixes its name with the project name. |
The short-form depends_on starts db before web, but does **not** wait for database readiness. If the first page says
Database is not ready; try again, wait a few seconds and request it again. Lesson 07 replaces this timing guess with health-based order.
There is intentionally **no ports section under db**. The default project network connects web to db privately;
5432/tcp in status means an internal port, not host publication. Host port 5432 belongs to the Databases track.

### Step 7. Trace the network addresses
A **network** is a communication space connecting containers. Compose creates a default network for this project.
**DNS** (Domain Name System) translates a name into a network address. Docker's internal DNS lets web find db by the service name.
Do not save a container's numerical address: it can change when that container is recreated.

| Who is connecting? | Address to use | Why |
|---|---|---|
| Browser or terminal on your host | http://127.0.0.1:8080 | This is the published host web port. |
| Python inside web connecting to Postgres | db, port 5432 | db is the service name on the project network; 5432 is its internal database port. |
| A container referring to localhost | Itself | Containers have separate loopback addresses. localhost inside web is web, not your host and not db. |
| Host IDE trying localhost:5432 in this lesson | No connection route is published | This track deliberately leaves Postgres private; the Databases track supplies a host route. |

The web environment has DB_HOST: db. Both services get matching database name/user/password settings;
only web receives GREETING. The named db_data volume keeps database files across ordinary down/up cycles.
This is a beginner-local environment, not a production network isolation or credential-management design.
## Run it
From your lesson folder, start this throwaway project. `-p` supplies a project name that groups its containers, network and volumes;
`up` creates/starts services, `-d` detaches, `--build` builds the web image. Keep the same project name for every command.

**Commands — folder: `your lesson folder`**
```powershell
docker compose -p code101-verify-06-networks-and-compose up -d --build
```
Expected output, **excerpt** (progress is longer):

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
#11 naming to docker.io/library/code101-verify-06-networks-and-compose-web:demo done
 Volume code101-verify-06-networks-and-compose_db_data Created 
 Volume code101-verify-06-networks-and-compose_db_data Created 
 Network code101-verify-06-networks-and-compose_default Created 
 Network code101-verify-06-networks-and-compose_default Created 
 Container code101-verify-06-networks-and-compose-db-1 Created 
 Container code101-verify-06-networks-and-compose-web-1 Created 
 Container code101-verify-06-networks-and-compose-db-1 Started 
 Container code101-verify-06-networks-and-compose-web-1 Started
```
Check status; fields are name, state, health, ports:

**Commands — folder: `your lesson folder`**
```powershell
docker compose -p code101-verify-06-networks-and-compose ps --format "{{.Name}} | {{.State}} | {{.Health}} | {{.Ports}}"
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
code101-verify-06-networks-and-compose-db-1 | running |  | 5432/tcp
code101-verify-06-networks-and-compose-web-1 | running |  | 127.0.0.1:8080->8000/tcp
```
Also check which services are running:

**Commands — folder: `your lesson folder`**
```powershell
docker compose -p code101-verify-06-networks-and-compose ps --services --status running
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
{"message": "Hello from Compose", "database": "workshop", "host": "db"}
```
If the first request arrives before readiness, wait a few seconds and try again. Read web logs (the container's printed output, not a secret dump):

**Commands — folder: `your lesson folder`**
```powershell
docker compose -p code101-verify-06-networks-and-compose logs --no-color --tail 3 web
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
web-1  | Code101 web listening on 8000
web-1  | 172.18.0.1 - - [23/Nov/2026 06:18:13] "GET / HTTP/1.1" 200 -
```
Stop and remove this project when finished. **Warning:** `-v` deletes its declared named volumes and all data inside them.
For valuable data, omit -v and take a backup first. `--remove-orphans` also removes services from this project no longer present in the file.

**Commands — folder: `your lesson folder`**
```powershell
docker compose -p code101-verify-06-networks-and-compose down -v --remove-orphans
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Container code101-verify-06-networks-and-compose-web-1 Stopping 
 Container code101-verify-06-networks-and-compose-web-1 Stopped 
 Container code101-verify-06-networks-and-compose-web-1 Removing 
 Container code101-verify-06-networks-and-compose-web-1 Removed 
 Container code101-verify-06-networks-and-compose-db-1 Stopping 
 Container code101-verify-06-networks-and-compose-db-1 Stopped 
 Container code101-verify-06-networks-and-compose-db-1 Removing 
 Container code101-verify-06-networks-and-compose-db-1 Removed 
 Volume code101-verify-06-networks-and-compose_db_data Removing 
 Network code101-verify-06-networks-and-compose_default Removing 
 Volume code101-verify-06-networks-and-compose_db_data Removed 
 Network code101-verify-06-networks-and-compose_default Removed
```
Remove just your built web image (the downloaded base images/build cache are separate):

**Commands — folder: `your lesson folder`**
```powershell
docker image rm code101-verify-06-networks-and-compose-web:demo
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Untagged: code101-verify-06-networks-and-compose-web:demo
Deleted: sha256:e52c293a2fd80dc811d679b19054754254be2fc6c4263e23483937e75a78ba94
```

## How it works
Compose builds web, starts db, attaches both to its default network, and provides service-name DNS. Web handles a request by connecting to db on internal port 5432; Postgres reports current_database(). The successful response names workshop. Short-form depends_on does not establish readiness, so the handler can return a temporary 503 until db is ready.

New terms for this lesson (also in the track glossary):

- **network**: A communication space connecting containers; Compose creates a default one per project.
- **DNS**: Domain Name System; here, Docker's internal lookup that turns a service name such as `db` into an address.
- **database**: A program that stores structured information; Postgres is the one used here.
- **SQL**: Structured Query Language, used to work with database tables.
- **volume**: Docker-managed storage that outlives a container (here `db_data`).
- **localhost**: The computer a program runs on; inside a container it means that container itself.
- **depends_on**: A Compose setting that orders container startup; in its short form it does not wait for readiness.

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
**Exercise:** make the networked app greet with `Hello from the network`. Decide which files hold that setting; leave the database host as it is and keep Postgres private (no host port for it).
Everything else stays as in the Steps.
<details><summary>Solution</summary>

**File: `practice/.env`**
```dotenv
POSTGRES_USER=learner
POSTGRES_PASSWORD=local-demo-only
POSTGRES_DB=workshop
GREETING=Hello from the network
```

**File: `practice/.env.example`**
```dotenv
POSTGRES_USER=learner
POSTGRES_PASSWORD=local-demo-only
POSTGRES_DB=workshop
GREETING=Hello from the network
```
All other files are genuinely identical to the full Steps versions; keep their exact filenames and contents.
From practice repeat the same startup/status/logs/cleanup procedure in Run it: the only folder difference is practice,
and the same project name is reused after the original has been removed. Here are start and response for this exact solution:

**Commands — folder: `practice`**
```powershell
docker compose -p code101-verify-06-networks-and-compose up -d --build
```
Expected output, **excerpt** (progress is longer):

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
#11 naming to docker.io/library/code101-verify-06-networks-and-compose-web:demo done
 Volume code101-verify-06-networks-and-compose_db_data Created 
 Volume code101-verify-06-networks-and-compose_db_data Created 
 Network code101-verify-06-networks-and-compose_default Created 
 Network code101-verify-06-networks-and-compose_default Created 
 Container code101-verify-06-networks-and-compose-db-1 Created 
 Container code101-verify-06-networks-and-compose-web-1 Created 
 Container code101-verify-06-networks-and-compose-db-1 Started 
 Container code101-verify-06-networks-and-compose-web-1 Started
```

**Commands — folder: `practice`**
```powershell
curl.exe -fsS http://127.0.0.1:8080/
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
{"message": "Hello from the network", "database": "workshop", "host": "db"}
```
Check status and logs in practice with the identical commands from Run it (same project name).
Then clean up **from practice** using the exact final commands below:

**Commands — folder: `practice`**
```powershell
docker compose -p code101-verify-06-networks-and-compose down -v --remove-orphans
docker image rm code101-verify-06-networks-and-compose-web:demo
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Container code101-verify-06-networks-and-compose-web-1 Stopping 
 Container code101-verify-06-networks-and-compose-web-1 Stopped 
 Container code101-verify-06-networks-and-compose-web-1 Removing 
 Container code101-verify-06-networks-and-compose-web-1 Removed 
 Container code101-verify-06-networks-and-compose-db-1 Stopping 
 Container code101-verify-06-networks-and-compose-db-1 Stopped 
 Container code101-verify-06-networks-and-compose-db-1 Removing 
 Container code101-verify-06-networks-and-compose-db-1 Removed 
 Network code101-verify-06-networks-and-compose_default Removing 
 Volume code101-verify-06-networks-and-compose_db_data Removing 
 Volume code101-verify-06-networks-and-compose_db_data Removed 
 Network code101-verify-06-networks-and-compose_default Removed
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Untagged: code101-verify-06-networks-and-compose-web:demo
Deleted: sha256:47399586a2a8209b9aeb62d4571b44f51d2c7e9e3a86a743b4eadb1a44c366c6
```
On macOS/Linux the Docker commands are identical; use curl instead of curl.exe. Ubuntu: sudo before Docker.
</details>


## Check yourself
1. What does localhost mean inside web?
   <details><summary>Answer</summary>The web container itself.</details>
2. Does 5432/tcp in status mean Postgres is published on the host?
   <details><summary>Answer</summary>No. A host publication includes a host address/port arrow, which db does not have.</details>
3. Why use db rather than a container IP address?
   <details><summary>Answer</summary>Service-name lookup follows a recreated container; its numeric address can change.</details>
4. Does depends_on short form wait for Postgres queries to work?
   <details><summary>Answer</summary>No: only for container startup. Lesson 07 adds a health condition.</details>

## Common mistakes
The YAML error was triggered using a temporary Compose file with ports indented by three spaces instead of four, then checked with `docker compose config`.
Restore the complete docker-compose.yml in Step 6; do not patch random spaces until an error disappears.
These error excerpts were deliberately triggered, except the rows marked typical message. IDs vary. Never remove an unfamiliar container to fix a conflict.

| Error text | Cause | Fix |
|---|---|---|
| `did not find expected key` | ports indented 3 spaces instead of 4 | Use spaces, align ports with image under web, restore the full file, then docker compose config --quiet. |
| `Bind for 127.0.0.1:8080 failed: port is already allocated` | Another running container owns host port 8080 | Run docker ps; stop only your earlier container, or change host 8080 to 8081 (leave the container port unchanged). |
| `no configuration file provided: not found` (typical message) | You ran `docker compose` in the wrong folder, one without `docker-compose.yml` | Move to your lesson folder (the `Set-Location` or `cd` line in Step 1) and repeat the command. |
| `env file` ... `.env not found: stat` ... `no such file or directory` (typical message) | `.env` is missing, for example only `.env.example` exists | Create `.env` (Step 4) or run the copy command shown there, then run `up` again. |
| `check if the path is correct and if the daemon is running` (captured in lesson 01; the full line varies by system) | Docker Desktop is not running | Start Docker Desktop, wait for **Engine running**, then repeat the command. |

## Best practice
Use service names for container-to-container communication and publish only the service the host needs. Source: Docker Compose reference https://docs.docker.com/reference/compose-file/

## Next lesson
**07. Healthchecks, logs and cleaning up:** wait for the database to become ready.
