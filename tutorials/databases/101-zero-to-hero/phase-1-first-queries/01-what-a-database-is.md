---
track: databases
level: 101
phase: 1
phase_name: first-queries
lesson: 01
title: "What a database is"
time: 45 min
prerequisites: [docker.101.1.01]
versions: { docker: "29.9.3", compose: "5.7.0", postgres_image: "17-alpine" }
verified: 2026-11-23 on Windows 11, Docker CLI/Engine 29.9.3, Compose 5.7.0
source: source/databases/101-zero-to-hero/phase-1-first-queries/01-what-a-database-is/
assets: []
---

# 01. What a database is

## Why it matters
A database is a very organised filing cabinet: each fact has a place, and you can ask for just the facts you need. Think of a spreadsheet that does not lose its saved work when you close the window. It still needs backups, just as a real filing cabinet needs protection from fire.

## What you will build
A PostgreSQL database running inside Docker, with its saved data in a named volume and a first message returned by SQL.

## Before you start
- Docker installed and running in Linux-container mode. Follow [Docker 101 lesson 01](../../../docker/101-zero-to-hero/phase-1-containers/01-what-is-a-container.md) first if needed. No system-wide PostgreSQL or psql install, and no host programming language needed.
- Author baseline: Windows 11, Docker CLI/Engine 29.9.3, Compose 5.7.0, official postgres:17-alpine. A plain-text editor is enough (Notepad on Windows works); optional IDE setup is in lesson 02.
- Time: about 45 minutes (about 5 minutes per new idea plus setup). Docker must already be installed.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/databases/101-zero-to-hero/phase-1-first-queries/01-what-a-database-is/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`). Either way, keep a `code` folder and an `exercise` folder side by side: Compose mounts both.
- Work on **one database lesson at a time**. Finish the previous lesson's stop/cleanup before starting this one: every lab deliberately uses host port 5432.
- All data and credentials here are disposable local examples. The SQL reset scripts remove their sample schema; never point them at your own or an employer's data. Do not share the tutorial password with a real service.

## Steps
### Step 1. Make your lesson folder and open a terminal
1. Your home folder is `C:\Users\<your-name>` on Windows (open File Explorer and type `%USERPROFILE%` in its address bar), `/Users/<your-name>` on macOS, or `/home/<your-name>` on Linux. A terminal is a window in which you type commands and press Enter. Do not type a prompt's `>` or `$` character.
2. Open a terminal: on Windows press Start, type **Windows PowerShell** and open it. On macOS open Terminal; on Linux open your terminal application.
3. Create the lesson folder `code101/databases-101-phase-1-first-queries/01-what-a-database-is/` with a `code` folder and, beside it, an `exercise/starter` folder. (If you downloaded the optional pack, copy the `01-what-a-database-is` folder from the repository's `source/databases/101-zero-to-hero/phase-1-first-queries/` into `code101/databases-101-phase-1-first-queries/` instead, and skip the commands below.)

**Terminal (PowerShell; folder: any)**
```powershell
New-Item -ItemType Directory -Force "$HOME\code101\databases-101-phase-1-first-queries\01-what-a-database-is\code","$HOME\code101\databases-101-phase-1-first-queries\01-what-a-database-is\exercise\starter" | Out-Null
```

**Terminal (macOS/Linux alternative; folder: any)**
```bash
mkdir -p "$HOME/code101/databases-101-phase-1-first-queries/01-what-a-database-is/code" "$HOME/code101/databases-101-phase-1-first-queries/01-what-a-database-is/exercise/starter"
```

4. The prompt shows the current folder before `>` or `$`. If it is not the code folder, move there with the appropriate command below. Keep this terminal in that folder for the entire lesson.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/01-what-a-database-is/code`)**
```powershell
Set-Location "$HOME\code101\databases-101-phase-1-first-queries\01-what-a-database-is\code"
```

**Terminal (macOS/Linux; folder: `databases-101-phase-1-first-queries/01-what-a-database-is/code`)**
```bash
cd "$HOME/code101/databases-101-phase-1-first-queries/01-what-a-database-is/code"
```

Open this code folder in your editor. Create each file shown below: choose **File > New**, type the shown contents, then **Save As** in this code folder with the exact filename, not a trailing .txt (with the optional pack the files already exist; open each one to compare). Enable **View > Show > File name extensions** in Windows Explorer to check. Save after each change (Ctrl+S, or Cmd+S on macOS); a dot on an editor tab often means unsaved changes.

### Step 2. Read the full Docker configuration
The indentation below uses spaces. Keep every line in this file.

**File: `code/docker-compose.yml`**
```yaml
services:
  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      PGDATABASE: ${POSTGRES_DB}
      PGUSER: ${POSTGRES_USER}
    ports:
      - "127.0.0.1:5432:5432"
    volumes:
      - pg_data:/var/lib/postgresql/data
      - .:/scripts:ro
      - ../exercise:/exercises:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"]
      interval: 2s
      timeout: 3s
      retries: 30
      start_period: 5s
volumes:
  pg_data:
```

An **image** is a packaged starting point; a **container** is its running instance. **Compose** starts named **services** from a **YAML** file (a text format whose indentation describes nesting). Our only service is `db`. An **environment variable** is a named setting. A **port** is a numbered entrance to a program. The **host** is your computer; **localhost** points back to the computer where the client runs. A **named volume** is Docker-managed storage that survives a container. A **bind mount** exposes a host folder inside a container. A **healthcheck** asks whether the service is ready, not just running.

Every configuration line, in file order:

| Line or setting | Meaning; what changing it changes |
|---|---|
| `services:` | Start the list of application services. Keep its child lines indented with spaces, not tabs. |
| `db:` | Name this service db; use the same name in every exec command. |
| `image: postgres:17-alpine` | Use the official PostgreSQL major-17 image on Alpine Linux. No host database install. Do not replace it with latest. |
| `environment:` | Supply settings inside the container. |
| `POSTGRES_DB: ${POSTGRES_DB}` | Read the database name from .env; create it on first initialisation. |
| `POSTGRES_USER: ${POSTGRES_USER}` | Read the initial administrative login name from .env. |
| `POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}` | Read that login's password from .env; this is local practice only. |
| `PGDATABASE: ${POSTGRES_DB}` | Let psql inside the container default to this database. |
| `PGUSER: ${POSTGRES_USER}` | Let psql default to this user, so plain docker compose exec db psql works. |
| `ports:` | Start the host-to-container port mappings. |
| `127.0.0.1:5432:5432` | Only your host loopback address, host port 5432, container port 5432, in that order. Removing 127.0.0.1 can expose it to other machines. |
| service `volumes:` | Start the container's storage mappings. |
| `pg_data:/var/lib/postgresql/data` | Save major-17 database files in a named volume, outside the container lifetime. Do not substitute a different major version on this volume. |
| `.:/scripts:ro` | Mount this code folder at /scripts, read-only (ro). Saved edits are immediately visible, not automatically executed. |
| `../exercise:/exercises:ro` | Mount the sibling exercise folder read-only. Keep code and exercise under the same lesson folder. |
| `healthcheck:` | Configure the readiness check. |
| `test: [...]` | CMD-SHELL runs pg_isready with the user and database. Double dollars defer variable expansion to the container shell, not Compose. It checks readiness, not whether your password is correct. |
| `interval: 2s` | Check every two seconds; longer intervals can delay readiness detection. |
| `timeout: 3s` | Allow three seconds per check. |
| `retries: 30` | Tolerate thirty failed checks before unhealthy. |
| `start_period: 5s` | Give initial startup five seconds before counting failures. |
| top-level `volumes:` | Declare Docker-managed named storage. It is not indented under db. |
| `pg_data:` | Declare this volume; Compose prefixes its actual name with the project name. |

There is no Dockerfile: we run the official image unchanged. There is no .dockerignore: we do not build an image. The tag `postgres:17-alpine` was checked on [Docker Hub](https://hub.docker.com/v2/repositories/library/postgres/tags/17-alpine) on **2026-11-23** and pulled successfully. It pins the major version and flavour, not future patch updates. The captured image digest was `sha256:f9cf3e1f0066f0eb0c48707d864f0ac5941e9ff454a072077d97a4d278d07d73`.

### Step 3. Create the local environment file
First open the example. A leading `#` makes a comment, not a setting.

**File: `code/.env.example`**
```dotenv
# Disposable local practice only. Never reuse this password elsewhere.
POSTGRES_DB=code101
POSTGRES_USER=learner
POSTGRES_PASSWORD=learn_local_only
```

`POSTGRES_DB` names the initial database; `POSTGRES_USER` names its initial administrative login; `POSTGRES_PASSWORD` is the disposable local password. Compose reads these from a file literally named `.env` in this code folder. Changing the template alone does not change it.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/01-what-a-database-is/code`)**
```powershell
Copy-Item .env.example .env
```

**Terminal (macOS/Linux alternative; folder: `databases-101-phase-1-first-queries/01-what-a-database-is/code`)**
```bash
cp .env.example .env
```

The copy succeeds without printing text. The complete generated file is:

**File: `code/.env` (created locally; not shipped)**
```dotenv
# Disposable local practice only. Never reuse this password elsewhere.
POSTGRES_DB=code101
POSTGRES_USER=learner
POSTGRES_PASSWORD=learn_local_only
```

These initialisation settings apply only when the data volume is empty. Editing the password later does not change an existing database login. For this disposable practice only, cleaning with down -v and then starting again creates a fresh volume; it destroys saved data.

**File: `code/.gitignore`**
```gitignore
.env
*.dump
```

This tells Git not to record the local .env file or dump archives. It does not encrypt anything; never put real credentials in the template.

### Step 4. Read and save the SQL files
A **database** is an organised collection of saved facts. A **database server** is the program that stores those facts and answers requests. **PostgreSQL**, also called **Postgres**, is our server. **SQL** (Structured Query Language) is the language we use to ask it questions. A **query** is one request written in SQL.

`SELECT` asks for a result. Single quotes surround literal text, `AS message` names the result column, and `;` finishes the statement. Keywords are uppercase for readability; the spelling of your text stays unchanged. `psql` is the text-based client (the program that sends requests) bundled inside the image. You are not installing it on your computer.

Lines beginning with a backslash are **psql commands**, interpreted by the client, not SQL sent to the server. `\set ON_ERROR_STOP on` stops a script on its first error. `\pset null '(none)'` makes missing values visible. `\ir` reads another file relative to the including script, or at the shown absolute container path. Run these whole files with psql, not an IDE SQL runner; an IDE can run the SQL statements alone.

**File: `code/lesson.sql`**
```sql
\set ON_ERROR_STOP on
\pset null '(none)'
SELECT 'PostgreSQL is ready' AS message;
```

### Step 5. Start and inspect PostgreSQL
In this code folder, keep Docker Desktop open. `-p` chooses a project name; use this same name for all commands in this lesson. `up` creates/starts the service, `-d` leaves it in the background, and `--wait` waits for the healthcheck. The first run downloads the image if necessary.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/01-what-a-database-is/code`)**
```powershell
docker compose -p code101-db01 up -d --wait
```

**Captured output (timestamps and progress ordering can vary)**
```text
 Network code101-db01_default Creating 
 Volume code101-db01_pg_data Creating 
 Volume code101-db01_pg_data Creating 
 Network code101-db01_default Creating 
 Volume code101-db01_pg_data Created 
 Volume code101-db01_pg_data Created 
 Network code101-db01_default Created 
 Network code101-db01_default Created 
 Container code101-db01-db-1 Creating 
 Container code101-db01-db-1 Created 
 Container code101-db01-db-1 Starting 
 Container code101-db01-db-1 Started 
 Container code101-db01-db-1 Waiting 
 Container code101-db01-db-1 Healthy 
```

Check status. The format prints service name, running state and health, without variable IDs or uptime. The quoted format works in PowerShell and macOS/Linux shells.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/01-what-a-database-is/code`)**
```powershell
docker compose -p code101-db01 ps --format "{{.Service}} {{.State}} {{.Health}}"
```

**Captured status output**
```text
db running healthy
```

Read the last two log lines (`--no-log-prefix` hides the Compose service prefix; `--tail 2` avoids a wall of text). Times and process numbers will differ; look for readiness.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/01-what-a-database-is/code`)**
```powershell
docker compose -p code101-db01 logs --no-log-prefix --tail 2 db
```

**Captured log output (your timestamps and process numbers differ)**
```text
2026-11-23 06:12:08.001 UTC [57] LOG:  database system was shut down at 2026-11-23 06:12:07 UTC
2026-11-23 06:12:08.006 UTC [1] LOG:  database system is ready to accept connections
```

Open the client **inside** the already-running container. `exec` means execute a command in that service. The PGUSER and PGDATABASE settings supply the defaults; without the -p option, the basic form is `docker compose exec db psql`. Keep -p here so it targets this lab.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/01-what-a-database-is/code`)**
```powershell
docker compose -p code101-db01 exec db psql
```

You enter psql rather than your operating-system shell. Type the SQL below, including its semicolon, and press Enter.

**psql session (not a file)**
```sql
SELECT 'PostgreSQL is ready' AS message;
```

**Captured query output (psql startup banner omitted)**
```text
       message       
---------------------
 PostgreSQL is ready
(1 row)
```

Type `\q` and press Enter to leave psql and return to the PowerShell/terminal prompt. Commands beginning docker belong in that terminal, never inside psql. The scripted form in Run it gives the same query results without staying in an interactive session.

## Run it
Run the entry script once from this lesson code folder. `-T` avoids an interactive terminal, `-X` ignores personal psql startup settings, `-q` suppresses routine command tags, `-v ON_ERROR_STOP=1` stops on an SQL error, `-U` chooses the user, `-d` the database, and `-f` the file **inside** the container. Every later lesson uses this identical command pattern with its own project and filename.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/01-what-a-database-is/code`)**
```powershell
docker compose -p code101-db01 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

**Expected psql output (captured from these files)**
```text
       message       
---------------------
 PostgreSQL is ready
(1 row)
```

Notices about a schema being absent (first run) or dependent objects being dropped (repeat reset) go to a separate diagnostic stream. They do not change these result tables. Quiet mode hides CREATE/INSERT/BEGIN command tags, not errors.

## How it works
The Compose service starts first. psql reads lesson.sql, applies its client display/error settings, includes setup.sql if present, and sends the SQL statements in file order. SQL semicolons, not line breaks, separate statements. The server returns the result tables above.

New terms for this lesson (also in the track glossary):

- **database**: An organised collection of saved facts.
- **database server**: A program that stores data and answers client requests.
- **PostgreSQL (Postgres)**: The relational database server used in this track.
- **SQL**: Structured Query Language, used to read and change relational data.
- **query**: A request written in SQL.
- **client**: A program that sends requests to a server.
- **psql**: The text-based PostgreSQL client, run inside Docker here.
- **image**: A packaged starting point for a container.
- **container**: An isolated running instance of an image.
- **Compose**: Docker tool that starts services described in a YAML file.
- **YAML**: The indentation-based file format used by Compose.
- **service**: A named application component in Compose, here db.
- **port**: A numbered network entrance to a program.
- **host**: The computer running Docker, or a connection address field.
- **localhost**: A name for the machine on which the client is running.
- **named volume**: Docker-managed storage that outlives a container.
- **bind mount**: A host folder made visible inside a container.
- **healthcheck**: A repeated readiness check on a running service.
- **environment variable**: A named setting supplied to a program.
- **literal**: A value written directly in a query.
- **result column alias**: An output heading assigned using AS.

## Try it
Make the database return the text `A place for facts` in a column named `message`.

1. Keep db running. Create `exercise.sql` in this code folder: copy the starter (with the optional pack) or type the contents shown in step 2.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/01-what-a-database-is/code`)**
```powershell
Copy-Item ..\exercise\starter\exercise.sql .\exercise.sql
```

**Terminal (macOS/Linux alternative; folder: `databases-101-phase-1-first-queries/01-what-a-database-is/code`)**
```bash
cp ../exercise/starter/exercise.sql ./exercise.sql
```

2. Open exercise.sql. Its complete starting contents are:

**File: `code/exercise.sql` (copied starter)**
```sql
\set ON_ERROR_STOP on
\pset null '(none)'
-- TODO: replace this SELECT with the exercise described in the lesson.
SELECT 'Try the exercise' AS next_step;
```

The initialisation include, where present, resets the sample; leave it in place. Replace the TODO comment and placeholder SELECT with your answer and save. This reset makes the exercise independent of writes in Run it. If you run the unchanged starter, it prints:

**Captured unchanged starter output**
```text
    next_step     
------------------
 Try the exercise
(1 row)
```

3. Run your saved exercise from the same code folder:

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/01-what-a-database-is/code`)**
```powershell
docker compose -p code101-db01 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/exercise.sql
```

An answer matching the supplied solution produces:

**Expected exercise output (captured from solution)**
```text
      message      
-------------------
 A place for facts
(1 row)
```

<details><summary>Solution</summary>

4. If stuck, replace your entire code/exercise.sql with this file, save, then run the same exercise command in step 3. The copy in exercise/solution is the same answer; you do not need a separate server for it.

**File: `code/exercise.sql` (solution; supplied at `exercise/solution/exercise.sql`)**
```sql
\set ON_ERROR_STOP on
\pset null '(none)'
SELECT 'A place for facts' AS message;
```

The setup runs again first, then only the exercise changes or query, which is why the result does not depend on a previous attempt.

</details>

### Finish: stop, inspect, then remove this disposable lab
`stop` stops the server **without deleting saved data**. A later up command with the same project and .env starts it again with that data. Run these commands only after finishing the query, exercise and any backup work.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/01-what-a-database-is/code`)**
```powershell
docker compose -p code101-db01 stop
```

**Captured output (timestamps and progress ordering can vary)**
```text
 Container code101-db01-db-1 Stopping 
 Container code101-db01-db-1 Stopped 
```

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/01-what-a-database-is/code`)**
```powershell
docker compose -p code101-db01 ps --all --format "{{.Service}} {{.State}} {{.Health}}"
```

**Captured stopped status output**
```text
db exited 
```

For this disposable course lab, now delete the container, its project network and **its saved volume**. `-v` is destructive; never use it on data you want to keep. `--remove-orphans` also removes leftover services belonging to this project, not unrelated projects. This frees 5432 for the next lesson.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/01-what-a-database-is/code`)**
```powershell
docker compose -p code101-db01 down -v --remove-orphans
```

**Captured output (timestamps and progress ordering can vary)**
```text
 Container code101-db01-db-1 Stopping 
 Container code101-db01-db-1 Stopped 
 Container code101-db01-db-1 Removing 
 Container code101-db01-db-1 Removed 
 Volume code101-db01_pg_data Removing 
 Network code101-db01_default Removing 
 Volume code101-db01_pg_data Removed 
 Network code101-db01_default Removed 
```

## Check yourself
1. Does stopping a container delete its named volume?
   <details><summary>Answer</summary>No. Removing the volume explicitly does.</details>
2. Where is PostgreSQL installed for this course?
   <details><summary>Answer</summary>Only in a Docker container, never as a system service.</details>
3. What ends a SQL statement?
   <details><summary>Answer</summary>A semicolon (;).</details>

## Common mistakes
| Symptom or real error text | Cause | Fix |
|---|---|---|
| `Bind for 127.0.0.1:5432 failed: port is already allocated` | Another container or program already owns 5432 | Stop your previous database lab from its own code folder. Inspect Docker Desktop Containers or docker ps to identify it; do not kill unrelated services or change the course port. |
| `Connection refused` | The database container is stopped, or the host/port is wrong | In this lesson code folder run the up command in Step 5, then confirm db running healthy. An IDE uses localhost, not db. |
| `FATAL:  password authentication failed for user "learner"` | Wrong password for the saved database volume | Use learn_local_only for this unchanged lab. Editing .env does not reset an existing database password. For disposable data only, down -v then up initialises again. |
| `ERROR:  syntax error at or near "SELEC"` | Deliberately typed SELEC rather than SELECT | Correct the keyword, keep text in single quotes, save the file, and rerun. In interactive psql a missing semicolon means it is still waiting; add it. |
| `no configuration file provided: not found` (typical message) | You ran `docker compose` in the wrong folder, one without `docker-compose.yml` | Move to this lesson's `code` folder (the `Set-Location` or `cd` command in Step 1) and run the command again. |
| `error during connect` or `failed to connect to the docker API` ... `check if the path is correct and if the daemon is running` (typical message) | Docker Desktop is not running | Start Docker Desktop, wait until it says the engine is running, then repeat the command. |
| `The "POSTGRES_PASSWORD" variable is not set. Defaulting to a blank string.` (typical message), then the container exits | You forgot to copy `.env.example` to `.env` in the code folder | Run the copy command from Step 3 in the code folder, then `docker compose -p code101-db01 down -v` and the up command again. |

These error strings (apart from the three marked typical message, which were not captured here) were deliberately triggered, not reconstructed from memory. The refused-connection capture used a temporary Docker client pointed at host.docker.internal while the server was down; an IDE on your computer calls that same destination localhost. Local socket or loopback access *inside* the official image can be trusted without a password, so a successful local psql session is not proof your IDE password is correct.

## Best practice
Bind this practice database to the loopback address, not every network interface. Source: [Docker Compose services reference](https://docs.docker.com/reference/compose-file/services/).

## Next lesson
[02. Connect with a tool](02-connect-with-a-tool.md): One verified connection using psql, then an optional IDE connection using exact local settings.
