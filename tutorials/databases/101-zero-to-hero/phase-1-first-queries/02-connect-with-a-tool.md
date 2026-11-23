---
track: databases
level: 101
phase: 1
phase_name: first-queries
lesson: 02
title: "Connect with a tool"
time: 25 min
prerequisites: [101.1.01]
versions: { docker: "29.9.3", compose: "5.7.0", postgres_image: "17-alpine" }
verified: 2026-11-23 on Windows 11, Docker CLI/Engine 29.9.3, Compose 5.7.0
source: source/databases/101-zero-to-hero/phase-1-first-queries/02-connect-with-a-tool/
assets: []
---

# 02. Connect with a tool

## Why it matters
A telephone number needs an area code and the right person at the other end. A database connection similarly needs an address, port, database name and login. A graphical editor and psql dial the same server in different ways.

## What you will build
One verified connection using psql, then an optional IDE connection using exact local settings.

## Before you start
- Docker installed and running in Linux-container mode. Follow [Docker 101 lesson 01](../../../docker/101-zero-to-hero/phase-1-containers/01-what-is-a-container.md) first if needed. No system-wide PostgreSQL or psql install, and no host programming language needed.
- Author baseline: Windows 11, Docker CLI/Engine 29.9.3, Compose 5.7.0, official postgres:17-alpine. A plain-text editor is enough (Notepad on Windows works); optional IDE setup is in lesson 02.
- Time: about 25 minutes (about 5 minutes per new idea plus setup); installing the optional IDE adds about 10.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/databases/101-zero-to-hero/phase-1-first-queries/02-connect-with-a-tool/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`). Either way, keep a `code` folder and an `exercise` folder side by side: Compose mounts both.
- Work on **one database lesson at a time**. Finish the previous lesson's stop/cleanup before starting this one: every lab deliberately uses host port 5432.
- All data and credentials here are disposable local examples. The SQL reset scripts remove their sample schema; never point them at your own or an employer's data. Do not share the tutorial password with a real service.

## Steps
### Step 1. Make your lesson folder and open a terminal
1. Your home folder is `C:\Users\<your-name>` on Windows (open File Explorer and type `%USERPROFILE%` in its address bar), `/Users/<your-name>` on macOS, or `/home/<your-name>` on Linux. A terminal is a window in which you type commands and press Enter. Do not type a prompt's `>` or `$` character.
2. Open a terminal: on Windows press Start, type **Windows PowerShell** and open it. On macOS open Terminal; on Linux open your terminal application.
3. Create the lesson folder `code101/databases-101-phase-1-first-queries/02-connect-with-a-tool/` with a `code` folder and, beside it, an `exercise/starter` folder. (If you downloaded the optional pack, copy the `02-connect-with-a-tool` folder from the repository's `source/databases/101-zero-to-hero/phase-1-first-queries/` into `code101/databases-101-phase-1-first-queries/` instead, and skip the commands below.)

**Terminal (PowerShell; folder: any)**
```powershell
New-Item -ItemType Directory -Force "$HOME\code101\databases-101-phase-1-first-queries\02-connect-with-a-tool\code","$HOME\code101\databases-101-phase-1-first-queries\02-connect-with-a-tool\exercise\starter" | Out-Null
```

**Terminal (macOS/Linux alternative; folder: any)**
```bash
mkdir -p "$HOME/code101/databases-101-phase-1-first-queries/02-connect-with-a-tool/code" "$HOME/code101/databases-101-phase-1-first-queries/02-connect-with-a-tool/exercise/starter"
```

4. The prompt shows the current folder before `>` or `$`. If it is not the code folder, move there with the appropriate command below. Keep this terminal in that folder for the entire lesson.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/02-connect-with-a-tool/code`)**
```powershell
Set-Location "$HOME\code101\databases-101-phase-1-first-queries\02-connect-with-a-tool\code"
```

**Terminal (macOS/Linux; folder: `databases-101-phase-1-first-queries/02-connect-with-a-tool/code`)**
```bash
cd "$HOME/code101/databases-101-phase-1-first-queries/02-connect-with-a-tool/code"
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

This is **identical** to [lesson 01, Step 2](01-what-a-database-is.md#step-2-read-the-full-docker-configuration), including the loopback port, named volume, both read-only mounts and healthcheck. Repeat those same configuration steps; the concrete differences are the current lesson folder `02-connect-with-a-tool` and command project name `code101-db02` instead of `code101-db01`. There are **no changed configuration lines**. `-p` prefixes this lesson's container, volume and network names. No Dockerfile or .dockerignore is needed because nothing is built.

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

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/02-connect-with-a-tool/code`)**
```powershell
Copy-Item .env.example .env
```

**Terminal (macOS/Linux alternative; folder: `databases-101-phase-1-first-queries/02-connect-with-a-tool/code`)**
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
A **connection** is the communication channel from client to server. A **connection string** packs settings into one piece of text. A **driver** is a client library that speaks the server protocol. An **IDE** is an integrated development environment: an editor with extra development tools. **Authentication** means checking who is connecting. **SSL/TLS** is encryption for network traffic; it is deliberately disabled for this loopback-only practice server, not a recommendation for remote servers.

`current_database()` is a **function**, a built-in operation that returns a value; the empty parentheses mean it needs no arguments. `current_user` is the SQL expression for the current role name. The aliases make the headings friendly. psql inside the container connects through a local socket, an internal connection that does not need the published host port. IDEs on your computer connect over the published network port and must supply the password.

Lines beginning with a backslash are **psql commands**, interpreted by the client, not SQL sent to the server. `\set ON_ERROR_STOP on` stops a script on its first error. `\pset null '(none)'` makes missing values visible. `\ir` reads another file relative to the including script, or at the shown absolute container path. Run these whole files with psql, not an IDE SQL runner; an IDE can run the SQL statements alone.

**File: `code/lesson.sql`**
```sql
\set ON_ERROR_STOP on
\pset null '(none)'
SELECT current_database() AS database, current_user AS username;
SELECT 'Connection works' AS message;
```

### Step 5. Start and inspect PostgreSQL
In this code folder, keep Docker Desktop open. `-p` chooses a project name; use this same name for all commands in this lesson. `up` creates/starts the service, `-d` leaves it in the background, and `--wait` waits for the healthcheck. The first run downloads the image if necessary.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/02-connect-with-a-tool/code`)**
```powershell
docker compose -p code101-db02 up -d --wait
```

**Captured output (timestamps and progress ordering can vary)**
```text
 Network code101-db02_default Creating 
 Network code101-db02_default Creating 
 Volume code101-db02_pg_data Creating 
 Volume code101-db02_pg_data Creating 
 Volume code101-db02_pg_data Created 
 Volume code101-db02_pg_data Created 
 Network code101-db02_default Created 
 Network code101-db02_default Created 
 Container code101-db02-db-1 Creating 
 Container code101-db02-db-1 Created 
 Container code101-db02-db-1 Starting 
 Container code101-db02-db-1 Started 
 Container code101-db02-db-1 Waiting 
 Container code101-db02-db-1 Healthy 
```

Check status. The format prints service name, running state and health, without variable IDs or uptime. The quoted format works in PowerShell and macOS/Linux shells.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/02-connect-with-a-tool/code`)**
```powershell
docker compose -p code101-db02 ps --format "{{.Service}} {{.State}} {{.Health}}"
```

**Captured status output**
```text
db running healthy
```

Read the last two log lines (`--no-log-prefix` hides the Compose service prefix; `--tail 2` avoids a wall of text). Times and process numbers will differ; look for readiness.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/02-connect-with-a-tool/code`)**
```powershell
docker compose -p code101-db02 logs --no-log-prefix --tail 2 db
```

**Captured log output (your timestamps and process numbers differ)**
```text
2026-11-23 06:12:16.312 UTC [57] LOG:  database system was shut down at 2026-11-23 06:12:16 UTC
2026-11-23 06:12:16.317 UTC [1] LOG:  database system is ready to accept connections
```

Open the client **inside** the already-running container. `exec` means execute a command in that service. The PGUSER and PGDATABASE settings supply the defaults; without the -p option, the basic form is `docker compose exec db psql`. Keep -p here so it targets this lab.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/02-connect-with-a-tool/code`)**
```powershell
docker compose -p code101-db02 exec db psql
```

You enter psql rather than your operating-system shell. Type the SQL below, including its semicolon, and press Enter.

**psql session (not a file)**
```sql
SELECT current_database() AS database, current_user AS username;
SELECT 'Connection works' AS message;
```

**Captured query output (psql startup banner omitted)**
```text
 database | username 
----------+----------
 code101  | learner
(1 row)

     message      
------------------
 Connection works
(1 row)
```

Type `\q` and press Enter to leave psql and return to the PowerShell/terminal prompt. Commands beginning docker belong in that terminal, never inside psql. The scripted form in Run it gives the same query results without staying in an interactive session.

### Step 6. Connect from your IDE

An IDE is an editor with development tools. Choose **one** optional route below; psql is the supported baseline, so no IDE is required. Do not install a system-wide PostgreSQL server or client. UI directions were checked against the vendors' documentation on 2026-11-23, not by clicking through the IDEs, so menu names may differ slightly in your version.

All local connection fields (if you changed .env, substitute its values):

| Field | Exact value |
|---|---|
| Host / Server name | `localhost` |
| Port | `5432` |
| Database / Database name | `code101` |
| User / User name | `learner` |
| Password | `learn_local_only` |
| Authentication | Password / User & Password |
| SSL mode | Disable / off |
| SSH tunnel | off |
| Display / Connection name | `Code101 local` |

**JetBrains DataGrip, or an IDE with the Database tool window**

1. Open **View > Tool Windows > Database** (DataGrip calls its main window **Database Explorer**).
2. Select **+ > Data Source > PostgreSQL**; alternatively **File > New > Data Source > PostgreSQL**.
3. In **General**, leave the default PostgreSQL driver and connection type, set authentication to **User & Password**, then fill Host, Port, Database, User and Password from the table.
4. If offered, click **Download missing driver files**. This downloads a client driver, not a local PostgreSQL server.
5. In **SSH/SSL**, leave the SSH tunnel off and uncheck **Use SSL**. If your version shows an SSL mode selector instead, select **disable**. Back on General the JDBC URL should describe localhost:5432/code101, not another database.
6. Click **Test Connection**, then **OK**. Right-click **Code101 local > New > Query Console**.
7. Copy only the SELECT statements from lesson.sql (not lines starting with a backslash). Select the statements and run **Ctrl+Enter** (Windows/Linux) or **Cmd+Enter** (macOS). The result grids contain code101 / learner and Connection works, matching the psql tables in Run it.

**VS Code: Microsoft's PostgreSQL extension**

1. Open **Extensions** (Ctrl+Shift+X on Windows/Linux, Cmd+Shift+X on macOS). Search for **PostgreSQL**, choose publisher **Microsoft**, extension id **ms-ossdata.vscode-pgsql**, and click **Install**. No Azure account is needed for this local server.
2. Open the **PostgreSQL** activity-bar view. Hover **Connections**, click **+ / Add New Connection** and keep the **Parameters** tab.
3. Fill **Server name**, **Authentication Type: Password**, **User name**, **Password**, **Database name** and **Connection Name** from the table.
4. Click **Advanced**. Set **Scope: User**, **Port: 5432**. Expand **SSL**, set **SSL mode: Disable**, and leave **SSH Tunnel** disabled. Close the advanced drawer.
5. Choose **Save Password** only if you want the local operating-system credential store to remember this disposable password. Click **Test Connection**, then **Save & Connect**.
6. Right-click the connected server and choose **New Query**. Confirm the editor's database is **code101**. Paste only the SELECT statements from lesson.sql, select them, and press **Ctrl+Shift+E** (Windows/Linux) or **Cmd+Shift+E** (macOS). Compare the Results grids with Run it.

**Visual Studio (not VS Code)**

Visual Studio's built-in SQL Server Object Explorer is not a PostgreSQL tool. Adding the Npgsql NuGet library to a project does **not** by itself install a PostgreSQL Server Explorer provider. Provider availability depends on separately installed tooling; this lesson does not require one or claim a supported built-in provider. If your existing PostgreSQL provider offers a connection dialog, use every field in the table, including SSL off. Otherwise use DataGrip, the VS Code route above, or **View > Terminal** in Visual Studio and the psql command from Step 5. No Npgsql or .NET install is needed for this lesson.

For a later .NET application, the equivalent **Npgsql connection string** is `Host=localhost;Port=5432;Database=code101;Username=learner;Password=learn_local_only;SSL Mode=Disable`. This is a settings example, not a new program to build. Keep real credentials out of source control.

The equivalent PostgreSQL URI is `postgresql://learner:learn_local_only@localhost:5432/code101?sslmode=disable`. Inside another container, localhost points to that container, **not** your host: containers on this Compose network use `db:5432`. This is why the host and service names are not interchangeable. If an IPv6 localhost lookup fails, use `127.0.0.1` with our IPv4-only mapping.

Official directions: [JetBrains](https://www.jetbrains.com/help/datagrip/postgresql.html), [VS Code](https://learn.microsoft.com/en-us/azure/postgresql/development/vs-code-extension/quickstart-connect-query), [VS Code connection fields](https://learn.microsoft.com/en-us/azure/postgresql/development/vs-code-extension/connections), [Npgsql](https://www.npgsql.org/doc/basic-usage.html).

## Run it
Run the entry script once from this lesson code folder. `-T` avoids an interactive terminal, `-X` ignores personal psql startup settings, `-q` suppresses routine command tags, `-v ON_ERROR_STOP=1` stops on an SQL error, `-U` chooses the user, `-d` the database, and `-f` the file **inside** the container. Every later lesson uses this identical command pattern with its own project and filename.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/02-connect-with-a-tool/code`)**
```powershell
docker compose -p code101-db02 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

**Expected psql output (captured from these files)**
```text
 database | username 
----------+----------
 code101  | learner
(1 row)

     message      
------------------
 Connection works
(1 row)
```

Notices about a schema being absent (first run) or dependent objects being dropped (repeat reset) go to a separate diagnostic stream. They do not change these result tables. Quiet mode hides CREATE/INSERT/BEGIN command tags, not errors.

## How it works
The Compose service starts first. psql reads lesson.sql, applies its client display/error settings, includes setup.sql if present, and sends the SQL statements in file order. SQL semicolons, not line breaks, separate statements. The server returns the result tables above.

New terms for this lesson (also in the track glossary):

- **connection**: A communication channel between client and server.
- **connection string**: Connection settings expressed in one string.
- **driver**: A client library that communicates with a database server.
- **IDE**: Integrated development environment: an editor plus development tools.
- **authentication**: Checking who is connecting.
- **SSL/TLS**: Encryption protocols for network connections.
- **function**: A named operation that returns a result.
- **socket**: An internal communication endpoint; psql can use a local Unix socket inside the container.

## Try it
Ask for `current_user` in a column named `connected_as`. This confirms whose permissions your session uses.

1. Keep db running. Create `exercise.sql` in this code folder: copy the starter (with the optional pack) or type the contents shown in step 2.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/02-connect-with-a-tool/code`)**
```powershell
Copy-Item ..\exercise\starter\exercise.sql .\exercise.sql
```

**Terminal (macOS/Linux alternative; folder: `databases-101-phase-1-first-queries/02-connect-with-a-tool/code`)**
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

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/02-connect-with-a-tool/code`)**
```powershell
docker compose -p code101-db02 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/exercise.sql
```

An answer matching the supplied solution produces:

**Expected exercise output (captured from solution)**
```text
 connected_as 
--------------
 learner
(1 row)
```

<details><summary>Solution</summary>

4. If stuck, replace your entire code/exercise.sql with this file, save, then run the same exercise command in step 3. The copy in exercise/solution is the same answer; you do not need a separate server for it.

**File: `code/exercise.sql` (solution; supplied at `exercise/solution/exercise.sql`)**
```sql
\set ON_ERROR_STOP on
\pset null '(none)'
SELECT current_user AS connected_as;
```

The setup runs again first, then only the exercise changes or query, which is why the result does not depend on a previous attempt.

</details>

### Finish: stop, inspect, then remove this disposable lab
`stop` stops the server **without deleting saved data**. A later up command with the same project and .env starts it again with that data. Run these commands only after finishing the query, exercise and any backup work.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/02-connect-with-a-tool/code`)**
```powershell
docker compose -p code101-db02 stop
```

**Captured output (timestamps and progress ordering can vary)**
```text
 Container code101-db02-db-1 Stopping 
 Container code101-db02-db-1 Stopped 
```

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/02-connect-with-a-tool/code`)**
```powershell
docker compose -p code101-db02 ps --all --format "{{.Service}} {{.State}} {{.Health}}"
```

**Captured stopped status output**
```text
db exited 
```

For this disposable course lab, now delete the container, its project network and **its saved volume**. `-v` is destructive; never use it on data you want to keep. `--remove-orphans` also removes leftover services belonging to this project, not unrelated projects. This frees 5432 for the next lesson.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/02-connect-with-a-tool/code`)**
```powershell
docker compose -p code101-db02 down -v --remove-orphans
```

**Captured output (timestamps and progress ordering can vary)**
```text
 Container code101-db02-db-1 Stopping 
 Container code101-db02-db-1 Stopped 
 Container code101-db02-db-1 Removing 
 Container code101-db02-db-1 Removed 
 Volume code101-db02_pg_data Removing 
 Network code101-db02_default Removing 
 Volume code101-db02_pg_data Removed 
 Network code101-db02_default Removed 
```

## Check yourself
1. What host does an IDE on your computer use?
   <details><summary>Answer</summary>localhost, not the Compose service name db.</details>
2. What port does this course publish?
   <details><summary>Answer</summary>5432, bound only to 127.0.0.1.</details>
3. Does installing the VS Code extension install our server?
   <details><summary>Answer</summary>No. The server stays in Docker.</details>

## Common mistakes
| Symptom or real error text | Cause | Fix |
|---|---|---|
| `Bind for 127.0.0.1:5432 failed: port is already allocated` | Another container or program already owns 5432 | Stop your previous database lab from its own code folder. Inspect Docker Desktop Containers or docker ps to identify it; do not kill unrelated services or change the course port. |
| `Connection refused` | The database container is stopped, or the host/port is wrong | In this lesson code folder run the up command in Step 5, then confirm db running healthy. An IDE uses localhost, not db. |
| `FATAL:  password authentication failed for user "learner"` | Wrong password for the saved database volume | Use learn_local_only for this unchanged lab. Editing .env does not reset an existing database password. For disposable data only, down -v then up initialises again. |
| `ERROR:  syntax error at or near "SELEC"` | Deliberately typed SELEC rather than SELECT | Correct the keyword, keep text in single quotes, save the file, and rerun. In interactive psql a missing semicolon means it is still waiting; add it. |
| `no configuration file provided: not found` (typical message) | You ran `docker compose` in the wrong folder, one without `docker-compose.yml` | Move to this lesson's `code` folder (the `Set-Location` or `cd` command in Step 1) and run the command again. |
| `error during connect` or `failed to connect to the docker API` ... `check if the path is correct and if the daemon is running` (typical message) | Docker Desktop is not running | Start Docker Desktop, wait until it says the engine is running, then repeat the command. |
| `The "POSTGRES_PASSWORD" variable is not set. Defaulting to a blank string.` (typical message), then the container exits | You forgot to copy `.env.example` to `.env` in the code folder | Run the copy command from the `.env` step in the code folder, then `docker compose -p code101-db02 down -v` and the up command again. |

These error strings (apart from the three marked typical message, which were not captured here) were deliberately triggered, not reconstructed from memory. The refused-connection capture used a temporary Docker client pointed at host.docker.internal while the server was down; an IDE on your computer calls that same destination localhost. Local socket or loopback access *inside* the official image can be trusted without a password, so a successful local psql session is not proof your IDE password is correct.

## Best practice
Keep credentials out of saved connection URLs in shared files; use a tool credential store when appropriate. Source: [JetBrains PostgreSQL connections](https://www.jetbrains.com/help/datagrip/postgresql.html).

## Next lesson
[03. Tables and data types](03-tables-and-data-types.md): A four-row book catalogue with text, whole numbers, exact decimal prices, yes/no values and dates.
