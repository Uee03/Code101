---
track: capstone
level: 201
phase: 2
phase_name: data
lesson: 02
title: "Data: repositories, stored functions, ETag, cursors and idempotency"
time: 180 min
prerequisites: [capstone-backend-python-01, capstone-platform-04, databases-101]
versions: { python: "3.12 or newer (author run: 3.15.2)", fastapi: "0.165.0", sqlalchemy: "2.1.9", psycopg: "3.3.9", postgres_image: "17-alpine", keycloak_image: "quay.io/keycloak/keycloak:26.8.2" }
verified: 2026-11-23 on Windows 11, Python 3.15.2, Docker 29.9.3, Compose 5.7.0
source: capstones/backend-python/source/phase-2-data/02-data/
assets: []
---

# 02. Data: repositories, stored functions, ETag, cursors and idempotency

## Why it matters
Think of a restaurant. The waiter (the HTTP layer) takes orders and serves plates but never walks into the pantry. A storekeeper (the repository) is the only person who fetches ingredients, and always with a written slip (a bound parameter), never by shouting free text into the pantry. Some dishes follow a recipe the kitchen keeps in its own book (a stored function) so that every cook, in every restaurant of the chain, makes them the same way. This chapter builds the storekeepers, uses the recipe book, and adds the manners of a polite waiter: "this plate has changed since you ordered" (ETag), "page two, please" (cursor) and "I already served that order" (idempotency key).

## What you will build
All 27 operations of the contract on top of the platform Postgres: teams, members, projects, tasks, comments, the audit log, users and a real `/health` and `/v1/me`. Writes run in a transaction that first tells the database who the caller is, so the audit trail names them. The caller is identified by a **stand-in**: the API reads the claims of the bearer token **without checking its signature**. That is only acceptable while you develop. Chapter 03 replaces it with real token validation, and shows why you must.

Conformance state at the end of this chapter: **17 passed, 1 failed**. The failing check is `me` because the `RateLimit-*` headers arrive in chapter 05. Everything else, including the idempotency, ETag, pagination, 401, 403, problem-details and audit checks, passes.

```mermaid
flowchart LR
    R["router (HTTP)"] -->|"1. Principal from the bearer token"| A["authenticate()"]
    R -->|"2. open transaction as the caller"| DB["Database.transaction(actor)"]
    R -->|"3. may this caller see the team?"| AC["access.py"]
    R -->|"4. SQL with bound parameters"| RP["repositories/*"]
    RP --> PG[("Postgres: tables, triggers, functions")]
    PG -->|"SQLSTATE TS404, TS409, TS412, TS422, 23505"| ER["db_errors.py: problem details"]
```

## Before you start
- Chapter 01 done, or unzip `backend-python-phase-2-data.zip` and open `02-data/code`. The pack holds the whole project at the end of this chapter. Files unchanged from chapter 01 (`app/logging_config.py`, `app/middleware.py`, `app/errors.py`, `app/schemas.py`, `.gitignore`, `requests/team-valid.json`, `requests/team-invalid.json`) are not repeated here: they are shown in full in chapter 01.
- Docker running (`docker info` prints server details). Host ports 5432 and 8180 must be free; the Databases track labs and other backends use them too, one at a time.
- The platform capstone chapters 02 to 04 (schema, stored functions, realm, conformance script). Their files are **copied unchanged** into this project, so this chapter shows only what is new.
- Terminal in the project folder `tasksteams-api` with the virtual environment active, as in chapter 01.

## Steps
### Step 1. Bring in the platform files
The platform capstone owns the database schema, the seed data, the Keycloak realm, the Compose file and the conformance script. Copy these five files from its final pack (`capstones/platform/source/phase-4-conformance/04-conformance-script/code`, or the unzipped `platform-phase-4-conformance.zip`) into your project, keeping the folder names. They must stay byte for byte identical: a backend never edits the contract.

```powershell
# Windows PowerShell, from the project folder; adjust the first line to where the platform pack is
$platform = "..\platform-phase-4-conformance\04-conformance-script\code"
mkdir db, keycloak, scripts
Copy-Item $platform\docker-compose.yml .
Copy-Item $platform\db\schema.sql, $platform\db\seed.sql db\
Copy-Item $platform\keycloak\realm-tasksteams.json keycloak\
Copy-Item $platform\scripts\conformance.py scripts\
```

```bash
# macOS and Linux
platform=../platform-phase-4-conformance/04-conformance-script/code
mkdir -p db keycloak scripts
cp "$platform/docker-compose.yml" .
cp "$platform/db/schema.sql" "$platform/db/seed.sql" db/
cp "$platform/keycloak/realm-tasksteams.json" keycloak/
cp "$platform/scripts/conformance.py" scripts/
```

`db/schema.sql`, `db/seed.sql`, `keycloak/realm-tasksteams.json` and `scripts/conformance.py` are long files that are shown in the platform chapters 02, 03 and 04; they are not repeated here. The Compose file is short and you will run it now, so here it is in full:

**File: `docker-compose.yml`**
```yaml
services:
  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "127.0.0.1:${POSTGRES_PORT:-5432}:5432"
    volumes:
      - pg_data:/var/lib/postgresql/data
      - ./db/schema.sql:/docker-entrypoint-initdb.d/01-schema.sql:ro
      - ./db/seed.sql:/docker-entrypoint-initdb.d/02-seed.sql:ro
      - ./db:/scripts:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -h 127.0.0.1 -U $$POSTGRES_USER -d $$POSTGRES_DB"]
      interval: 3s
      timeout: 3s
      retries: 30
      start_period: 5s
    networks:
      - tasksteams
  keycloak:
    image: quay.io/keycloak/keycloak:26.8.2
    command: ["start-dev", "--import-realm"]
    environment:
      KC_BOOTSTRAP_ADMIN_USERNAME: ${KEYCLOAK_ADMIN}
      KC_BOOTSTRAP_ADMIN_PASSWORD: ${KEYCLOAK_ADMIN_PASSWORD}
      KC_HOSTNAME: http://localhost:${KEYCLOAK_PORT:-8180}
      KC_HOSTNAME_BACKCHANNEL_DYNAMIC: "true"
      KC_HEALTH_ENABLED: "true"
    ports:
      - "127.0.0.1:${KEYCLOAK_PORT:-8180}:8080"
    volumes:
      - ./keycloak/realm-tasksteams.json:/opt/keycloak/data/import/realm-tasksteams.json:ro
    healthcheck:
      test: ["CMD", "bash", "-c", "exec 3<>/dev/tcp/127.0.0.1/9000 && printf 'GET /health/ready HTTP/1.1\\r\\nHost: localhost\\r\\nConnection: close\\r\\n\\r\\n' >&3 && grep -q UP <&3"]
      interval: 5s
      timeout: 5s
      retries: 60
      start_period: 30s
    networks:
      - tasksteams
networks:
  tasksteams:
    name: ${TASKS_NETWORK:-tasksteams-net}
volumes:
  pg_data:
```

| Part | What it does and what happens if you change it |
|------|-----------------------------------------------|
| `services.db` | Postgres 17. Its credentials come from `.env`. `127.0.0.1:` in the port means only your own computer can connect; without it the database is reachable from your network |
| `volumes` of `db` | `pg_data` keeps the data. The two `docker-entrypoint-initdb.d` files run **once**, on an empty volume: schema first, then seed (file names sort). Edit the SQL later and nothing changes until `down -v` deletes the volume |
| `healthcheck` of `db` | `pg_isready` every 3 seconds; `--wait` blocks until it passes |
| `services.keycloak` | Keycloak 26.8.2 in development mode. `--import-realm` loads the realm file on first start. `KC_HOSTNAME` fixes the issuer that goes into every token: `http://localhost:8180/realms/tasksteams` |
| `KC_HOSTNAME_BACKCHANNEL_DYNAMIC` | lets other containers (our API, from chapter 04) call Keycloak by its service name while tokens still carry `localhost` |
| `networks` | both services join the network `tasksteams-net`; the name is fixed so backends can join it too |

The Compose file reads its values from a `.env` file next to it. The platform `.env.example` is extended by our settings. Replace the content of `.env.example`:

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

# The API, when it runs on your computer with uvicorn (read by app/config.py)
DATABASE_URL=postgresql+psycopg://tasks_app:tasks_app_local_only@127.0.0.1:5432/tasksteams
LOG_LEVEL=INFO
PUBLIC_BASE_URL=http://localhost:8000
ENABLE_DOCS=true
```

Then create your own copy and start the infrastructure:

```powershell
# Windows PowerShell
Copy-Item .env.example .env
docker compose up -d --wait
docker compose ps
```

```bash
# macOS and Linux
cp .env.example .env
docker compose up -d --wait
docker compose ps
```

Expected output of `docker compose up -d --wait` (the first start downloads images and Keycloak needs about half a minute):

```text
 Volume tasksteams-api_pg_data Creating 
 Volume tasksteams-api_pg_data Creating 
 Network tasksteams-net Creating 
 Network tasksteams-net Creating 
 Volume tasksteams-api_pg_data Created 
 Volume tasksteams-api_pg_data Created 
 Network tasksteams-net Created 
 Network tasksteams-net Created 
 Container tasksteams-api-keycloak-1 Creating 
 Container tasksteams-api-db-1 Creating 
 Container tasksteams-api-keycloak-1 Created 
 Container tasksteams-api-db-1 Created 
 Container tasksteams-api-keycloak-1 Starting 
 Container tasksteams-api-db-1 Starting 
 Container tasksteams-api-keycloak-1 Started 
 Container tasksteams-api-db-1 Started 
 Container tasksteams-api-db-1 Waiting 
 Container tasksteams-api-keycloak-1 Waiting 
 Container tasksteams-api-db-1 Healthy 
 Container tasksteams-api-keycloak-1 Healthy 
```

Expected output of `docker compose ps`:

```text
NAME                        IMAGE                              COMMAND                  SERVICE    CREATED          STATUS                    PORTS
tasksteams-api-db-1         postgres:17-alpine                 "docker-entrypoint.s…"   db         26 seconds ago   Up 25 seconds (healthy)   127.0.0.1:5432->5432/tcp
tasksteams-api-keycloak-1   quay.io/keycloak/keycloak:26.8.2   "/opt/keycloak/bin/k…"   keycloak   26 seconds ago   Up 26 seconds (healthy)   127.0.0.1:8180->8080/tcp
```

Both services say `healthy`. The project name `tasksteams-api` is the folder name; Compose prefixes container names with it.

### Step 2. Add the database packages
Replace `requirements.txt` and `pyproject.toml` (two new lines each):

**File: `requirements.txt`**
```text
fastapi==0.165.0
uvicorn==0.54.0
pydantic==2.14.4
pydantic-settings==2.16.3
SQLAlchemy==2.1.9
psycopg[binary]==3.3.9
```

**File: `pyproject.toml`**
```toml
[project]
name = "tasksteams-api"
version = "1.0.0"
description = "Tasks and Teams API, the Python backend of the Code101 capstones"
requires-python = ">=3.12"
dependencies = [
    "fastapi>=0.165,<0.166",
    "uvicorn>=0.54,<0.55",
    "pydantic>=2.14,<3",
    "pydantic-settings>=2.16,<3",
    "SQLAlchemy>=2.1,<2.2",
    "psycopg[binary]>=3.3,<3.4",
]
```

`SQLAlchemy` is the toolkit; we use only its **Core** (connections, transactions, `text()` queries). `psycopg[binary]` is the Postgres driver version 3 with the precompiled library, so no C compiler is needed. Install:

```text
(.venv) tasksteams-api> python -m pip install -r requirements.txt
```

### Step 3. Settings and the database connection
Replace `app/config.py` (three new settings; `database_url` has no default, so the application refuses to start without it):

**File: `app/config.py`**
```python
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Every setting comes from an environment variable of the same name (DATABASE_URL, LOG_LEVEL, ...)."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    service_version: str = "1.0.0"
    log_level: str = "INFO"
    public_base_url: str = "http://localhost:8000"
    enable_docs: bool = True
    database_url: str
    db_pool_size: int = 10
    db_max_overflow: int = 10


@lru_cache
def get_settings() -> Settings:
    return Settings()
```

Create `app/db.py`:

**File: `app/db.py`**
```python
from collections.abc import Iterator
from contextlib import contextmanager
from uuid import UUID

from sqlalchemy import Connection, Engine, create_engine, text
from sqlalchemy.exc import SQLAlchemyError


class Database:
    """Owns the connection pool. Every request borrows a connection for the length of one transaction."""

    def __init__(self, url: str, pool_size: int, max_overflow: int) -> None:
        self.engine: Engine = create_engine(
            url,
            pool_size=pool_size,
            max_overflow=max_overflow,
            pool_timeout=5,
            pool_pre_ping=True,
            connect_args={"connect_timeout": 3},
        )

    @contextmanager
    def transaction(self, actor_id: UUID | None = None) -> Iterator[Connection]:
        """Commit when the block ends, roll back when it raises.

        With an actor, the first statement stores the user id in a transaction-local setting.
        The audit trigger and the stored functions read it, so every audit row names the caller.
        """
        with self.engine.begin() as conn:
            if actor_id is not None:
                conn.execute(text("SELECT set_config('app.current_user_id', :actor, true)"), {"actor": str(actor_id)})
            yield conn

    def ping(self) -> bool:
        try:
            with self.engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            return True
        except SQLAlchemyError:
            return False

    def dispose(self) -> None:
        self.engine.dispose()
```

`create_engine` builds the connection **pool**: a few connections opened once and lent to requests. `pool_size=10` plus `max_overflow=10` allows 20 at once; a request that waits more than `pool_timeout=5` seconds gets an error instead of hanging. `pool_pre_ping` tests a connection before lending it. `transaction()` is the heart of every write: `engine.begin()` opens a transaction that commits when the `with` block ends normally and rolls back when it raises, and with an `actor_id` its first statement runs `set_config('app.current_user_id', ..., true)`. The `true` means "local to this transaction", so the value cannot leak to the next request that reuses the connection. The audit trigger and the stored functions of the schema read that setting.

### Step 4. SQL helpers and the repositories
A **repository** is a module that hides the SQL of one kind of data behind plain Python functions. Rules for every function below: SQL text is constant, every value travels as a **bound parameter** (`:name`), so SQL injection is impossible by construction, and nothing here knows about HTTP.

Create the folder `app/repositories`, an empty `app/repositories/__init__.py`, and `app/repositories/sql.py`:

**File: `app/repositories/sql.py`**
```python
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, text

from app.errors import ProblemError, not_found

Row = dict[str, Any]


def fetch_one(conn: Connection, sql: str, params: dict[str, Any]) -> Row | None:
    row = conn.execute(text(sql), params).mappings().first()
    return dict(row) if row is not None else None


def fetch_all(conn: Connection, sql: str, params: dict[str, Any]) -> list[Row]:
    return [dict(row) for row in conn.execute(text(sql), params).mappings().all()]


def like_escape(value: str) -> str:
    """Make %, _ and the backslash itself match literally inside a LIKE pattern (used with ESCAPE '\\')."""
    return value.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")


def lock_and_check(conn: Connection, table: str, row_id: UUID, expected_version: int | None, label: str) -> None:
    """Lock the row until the transaction ends, then compare its version with the caller's If-Match.

    `table` is always a literal from our own code, never a request value.
    """
    current = conn.execute(text(f"SELECT version FROM {table} WHERE id = :id FOR UPDATE"), {"id": row_id}).scalar()
    if current is None:
        raise not_found()
    if expected_version is not None and current != expected_version:
        raise ProblemError(412, f"The {label} changed since you read it (current version {current}).")


def update_columns(conn: Connection, table: str, row_id: UUID, changes: dict[str, Any], allowed: frozenset[str]) -> None:
    """UPDATE only the named columns. Column names are checked against an allow-list; values are always bound."""
    unknown = set(changes) - allowed
    if unknown:
        raise ValueError(f"column not allowed: {sorted(unknown)}")
    if not changes:
        return
    assignments = ", ".join(f"{column} = :{column}" for column in changes)
    conn.execute(text(f"UPDATE {table} SET {assignments} WHERE id = :id"), {**changes, "id": row_id})
```

- `fetch_one` and `fetch_all` run a query and return dictionaries (column name to value).
- `like_escape` makes `%`, `_` and `\` literal, so a search for `100%` does not match everything.
- `lock_and_check` is optimistic concurrency in two lines of SQL: `SELECT version ... FOR UPDATE` locks the row until the transaction ends and returns its version; if the caller's `If-Match` version differs the function raises **412**. The table name is formatted into the text, which is safe only because every caller passes a literal.
- `update_columns` builds `UPDATE ... SET a = :a, b = :b`. Column names are checked against an allow-list first (they come from DTO field names, which a client influences), values are bound.

Create `app/repositories/users.py`:

**File: `app/repositories/users.py`**
```python
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, text

from app.repositories.sql import Row, fetch_all, fetch_one


def ensure_user(conn: Connection, user_id: UUID, username: str, email: str, display_name: str) -> None:
    """First sight of a Keycloak user: store the row the foreign keys point to. Existing rows stay untouched."""
    conn.execute(
        text("INSERT INTO users (id, username, email, display_name) VALUES (:id, :username, :email, :display_name) "
             "ON CONFLICT DO NOTHING"),
        {"id": user_id, "username": username, "email": email, "display_name": display_name},
    )


def get_user(conn: Connection, user_id: UUID) -> Row | None:
    return fetch_one(conn, "SELECT id, username, email, display_name FROM users WHERE id = :id", {"id": user_id})


def list_users(conn: Connection, prefix: str | None, limit: int, after: list[Any] | None) -> list[Row]:
    return fetch_all(
        conn,
        """
        SELECT id, username, display_name FROM users
        WHERE (CAST(:prefix AS text) IS NULL
               OR starts_with(lower(username), lower(:prefix)) OR starts_with(lower(display_name), lower(:prefix)))
          AND (CAST(:after_name AS text) IS NULL OR (username, id) > (CAST(:after_name AS text), CAST(:after_id AS uuid)))
        ORDER BY username, id
        LIMIT :limit
        """,
        {"prefix": prefix, "after_name": after[0] if after else None, "after_id": after[1] if after else None, "limit": limit},
    )
```

`ensure_user` stores the row that foreign keys point to the first time a Keycloak user appears. `ON CONFLICT DO NOTHING` makes it safe when two requests race. `list_users` shows the **keyset pagination** pattern used everywhere: `(username, id) > (:after_name, :after_id)` compares two columns as one tuple, in the same order as `ORDER BY username, id`. `CAST(:x AS text) IS NULL` is how a parameter that may be absent is switched off; the cast is needed because Postgres cannot guess the type of a bare `NULL` parameter.

Create `app/repositories/teams.py`:

**File: `app/repositories/teams.py`**
```python
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, text

from app.repositories.sql import Row, fetch_all, fetch_one, like_escape, update_columns

TEAM_SELECT = """
    SELECT t.id, t.name, t.description, t.created_by, t.version, t.created_at, t.updated_at,
           (SELECT count(*) FROM team_members m WHERE m.team_id = t.id) AS member_count
      FROM teams t
"""


def get_team(conn: Connection, team_id: UUID) -> Row | None:
    return fetch_one(conn, TEAM_SELECT + " WHERE t.id = :id", {"id": team_id})


def get_access(conn: Connection, team_id: UUID, user_id: UUID) -> Row | None:
    """None when the team does not exist; otherwise the caller's team role (None when the caller is not a member)."""
    return fetch_one(
        conn,
        "SELECT t.id, m.role FROM teams t LEFT JOIN team_members m ON m.team_id = t.id AND m.user_id = :user_id "
        "WHERE t.id = :team_id",
        {"team_id": team_id, "user_id": user_id},
    )


def list_teams(conn: Connection, user_id: UUID, all_teams: bool, prefix: str | None, newest_first: bool,
               limit: int, after: list[Any] | None) -> list[Row]:
    """Keyset pagination: continue after the (created_at, id) pair of the last row of the previous page."""
    comparison, direction = ("<", "DESC") if newest_first else (">", "ASC")
    return fetch_all(
        conn,
        TEAM_SELECT + f"""
        WHERE (:all_teams OR EXISTS (SELECT 1 FROM team_members m WHERE m.team_id = t.id AND m.user_id = :user_id))
          AND (CAST(:prefix AS text) IS NULL OR lower(t.name) LIKE :pattern ESCAPE '\\')
          AND (CAST(:after_created AS timestamptz) IS NULL
               OR (t.created_at, t.id) {comparison} (CAST(:after_created AS timestamptz), CAST(:after_id AS uuid)))
        ORDER BY t.created_at {direction}, t.id {direction}
        LIMIT :limit
        """,
        {
            "all_teams": all_teams,
            "user_id": user_id,
            "prefix": prefix,
            "pattern": like_escape(prefix.lower()) + "%" if prefix else None,
            "after_created": after[0] if after else None,
            "after_id": after[1] if after else None,
            "limit": limit,
        },
    )


def create_team(conn: Connection, name: str, description: str, lead_id: UUID, actor_id: UUID) -> UUID:
    """The stored function inserts the team and its first lead in one step (and sets the audit actor)."""
    return conn.execute(
        text("SELECT id FROM create_team(:name, :description, :lead_id, :actor_id)"),
        {"name": name, "description": description, "lead_id": lead_id, "actor_id": actor_id},
    ).scalar_one()


def update_team(conn: Connection, team_id: UUID, changes: dict[str, Any]) -> None:
    update_columns(conn, "teams", team_id, changes, frozenset({"name", "description"}))


def delete_team(conn: Connection, team_id: UUID) -> None:
    conn.execute(text("DELETE FROM teams WHERE id = :id"), {"id": team_id})
```

`create_team` does not insert anything itself. It calls the **stored function** `create_team(...)`, which inserts the team and its first lead in one step and also sets the audit actor. The function returns a row of type `teams`; we select only `id` and read the full team (with `member_count`) afterwards. `get_access` is the one query behind "may this caller see this team": it returns nothing when the team does not exist, and a row with `role` NULL when it exists but the caller is not a member.

Create `app/repositories/members.py`:

**File: `app/repositories/members.py`**
```python
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, text

from app.repositories.sql import Row, fetch_all, fetch_one


def get_membership(conn: Connection, team_id: UUID, user_id: UUID) -> str | None:
    """The team role of a user ('lead' or 'member'), or None when the user is not in the team."""
    return conn.execute(
        text("SELECT role FROM team_members WHERE team_id = :team_id AND user_id = :user_id"),
        {"team_id": team_id, "user_id": user_id},
    ).scalar()


def teams_of(conn: Connection, user_id: UUID) -> list[Row]:
    return fetch_all(
        conn,
        "SELECT t.id AS team_id, t.name, m.role FROM team_members m JOIN teams t ON t.id = m.team_id "
        "WHERE m.user_id = :user_id ORDER BY t.name",
        {"user_id": user_id},
    )


def list_members(conn: Connection, team_id: UUID, limit: int, after: list[Any] | None) -> list[Row]:
    return fetch_all(
        conn,
        """
        SELECT m.user_id, u.username, u.display_name, m.role, m.joined_at
          FROM team_members m JOIN users u ON u.id = m.user_id
         WHERE m.team_id = :team_id
           AND (CAST(:after_joined AS timestamptz) IS NULL
                OR (m.joined_at, m.user_id) > (CAST(:after_joined AS timestamptz), CAST(:after_id AS uuid)))
         ORDER BY m.joined_at, m.user_id
         LIMIT :limit
        """,
        {"team_id": team_id, "after_joined": after[0] if after else None, "after_id": after[1] if after else None, "limit": limit},
    )


def get_member(conn: Connection, team_id: UUID, user_id: UUID) -> Row | None:
    return fetch_one(
        conn,
        "SELECT m.user_id, u.username, u.display_name, m.role, m.joined_at "
        "FROM team_members m JOIN users u ON u.id = m.user_id WHERE m.team_id = :team_id AND m.user_id = :user_id",
        {"team_id": team_id, "user_id": user_id},
    )


def lock_leads(conn: Connection, team_id: UUID) -> list[UUID]:
    """Lock the lead rows so two requests cannot remove the last two leads at the same time."""
    rows = conn.execute(
        text("SELECT user_id FROM team_members WHERE team_id = :team_id AND role = 'lead' FOR UPDATE"),
        {"team_id": team_id},
    )
    return [row[0] for row in rows]


def put_member(conn: Connection, team_id: UUID, user_id: UUID, role: str) -> bool:
    """Insert or change the role. Returns True when the member is new (xmax is 0 only for a fresh row)."""
    return conn.execute(
        text("INSERT INTO team_members (team_id, user_id, role) VALUES (:team_id, :user_id, :role) "
             "ON CONFLICT (team_id, user_id) DO UPDATE SET role = EXCLUDED.role RETURNING (xmax = 0)"),
        {"team_id": team_id, "user_id": user_id, "role": role},
    ).scalar_one()


def delete_member(conn: Connection, team_id: UUID, user_id: UUID) -> None:
    conn.execute(text("DELETE FROM team_members WHERE team_id = :team_id AND user_id = :user_id"),
                 {"team_id": team_id, "user_id": user_id})
```

`lock_leads` locks the lead rows so that two admins cannot remove the last two leads of a team in parallel. `put_member` is an **upsert**: `INSERT ... ON CONFLICT DO UPDATE` and `RETURNING (xmax = 0)`. In Postgres the system column `xmax` is 0 for a row that was just inserted and not 0 for one that was updated by the conflict clause, which lets the API answer 201 or 200 from one statement.

Create `app/repositories/projects.py`:

**File: `app/repositories/projects.py`**
```python
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, text

from app.repositories.sql import Row, fetch_all, fetch_one, update_columns

PROJECT_COLUMNS = "id, team_id, key, name, description, archived, version, created_at, updated_at"


def get_project(conn: Connection, project_id: UUID) -> Row | None:
    return fetch_one(conn, f"SELECT {PROJECT_COLUMNS} FROM projects WHERE id = :id", {"id": project_id})


def list_projects(conn: Connection, team_id: UUID, archived: bool, newest_first: bool, limit: int,
                  after: list[Any] | None) -> list[Row]:
    comparison, direction = ("<", "DESC") if newest_first else (">", "ASC")
    return fetch_all(
        conn,
        f"""
        SELECT {PROJECT_COLUMNS} FROM projects
         WHERE team_id = :team_id AND archived = :archived
           AND (CAST(:after_created AS timestamptz) IS NULL
                OR (created_at, id) {comparison} (CAST(:after_created AS timestamptz), CAST(:after_id AS uuid)))
         ORDER BY created_at {direction}, id {direction}
         LIMIT :limit
        """,
        {"team_id": team_id, "archived": archived, "after_created": after[0] if after else None,
         "after_id": after[1] if after else None, "limit": limit},
    )


def create_project(conn: Connection, team_id: UUID, key: str, name: str, description: str, actor_id: UUID) -> Row:
    row = fetch_one(
        conn,
        f"INSERT INTO projects (team_id, key, name, description, created_by) "
        f"VALUES (:team_id, :key, :name, :description, :actor_id) RETURNING {PROJECT_COLUMNS}",
        {"team_id": team_id, "key": key, "name": name, "description": description, "actor_id": actor_id},
    )
    assert row is not None
    return row


def update_project(conn: Connection, project_id: UUID, changes: dict[str, Any]) -> None:
    update_columns(conn, "projects", project_id, changes, frozenset({"name", "description", "archived"}))


def delete_project(conn: Connection, project_id: UUID) -> None:
    conn.execute(text("DELETE FROM projects WHERE id = :id"), {"id": project_id})
```

Create `app/repositories/tasks.py`. This is the richest repository: filtering, three sort orders with matching cursors, and the two stored functions.

**File: `app/repositories/tasks.py`**
```python
from datetime import date
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, text

from app.repositories.sql import Row, fetch_all, fetch_one, like_escape, update_columns

TASK_SELECT = """
    SELECT t.id, t.project_id, t.title, t.description, t.status, t.priority, t.assignee_id, t.due_date,
           t.completed_at, t.created_by, t.version, t.created_at, t.updated_at, p.team_id
      FROM tasks t JOIN projects p ON p.id = t.project_id
"""
TASK_COLUMNS = ("id, project_id, title, description, status, priority, assignee_id, due_date, "
                "completed_at, created_by, version, created_at, updated_at")


def get_task(conn: Connection, task_id: UUID) -> Row | None:
    """The row carries team_id as well (not part of the API), so the caller can check team access."""
    return fetch_one(conn, TASK_SELECT + " WHERE t.id = :id", {"id": task_id})


def list_tasks(conn: Connection, project_id: UUID, *, statuses: list[str], priorities: list[str], assignee_id: UUID | None,
               due_before: date | None, due_after: date | None, title_contains: str | None, sort: str,
               limit: int, after: list[Any] | None) -> list[Row]:
    """Every filter is optional; a filter that is not used is switched off by its NULL parameter."""
    keyset, order = KEYSETS[sort]
    return fetch_all(
        conn,
        TASK_SELECT + f"""
        WHERE t.project_id = :project_id
          AND (cardinality(CAST(:statuses AS text[])) = 0 OR t.status = ANY(CAST(:statuses AS text[])))
          AND (cardinality(CAST(:priorities AS text[])) = 0 OR t.priority = ANY(CAST(:priorities AS text[])))
          AND (CAST(:assignee_id AS uuid) IS NULL OR t.assignee_id = CAST(:assignee_id AS uuid))
          AND (CAST(:due_before AS date) IS NULL OR t.due_date <= CAST(:due_before AS date))
          AND (CAST(:due_after AS date) IS NULL OR t.due_date >= CAST(:due_after AS date))
          AND (CAST(:pattern AS text) IS NULL OR t.title ILIKE :pattern ESCAPE '\\')
          AND ({keyset})
        ORDER BY {order}
        LIMIT :limit
        """,
        {
            "project_id": project_id,
            "statuses": statuses,
            "priorities": priorities,
            "assignee_id": assignee_id,
            "due_before": due_before,
            "due_after": due_after,
            "pattern": f"%{like_escape(title_contains)}%" if title_contains else None,
            "after_created": after[0] if after and sort != "dueDate" else None,
            "after_due": after[0] if after and sort == "dueDate" else None,
            "after_id": after[1] if after else None,
            "after_given": after is not None,
            "limit": limit,
        },
    )


# sort value -> (condition that skips everything up to the cursor, ORDER BY). Ties always break on id.
KEYSETS = {
    "-createdAt": (
        "NOT :after_given OR (t.created_at, t.id) < (CAST(:after_created AS timestamptz), CAST(:after_id AS uuid))",
        "t.created_at DESC, t.id DESC",
    ),
    "createdAt": (
        "NOT :after_given OR (t.created_at, t.id) > (CAST(:after_created AS timestamptz), CAST(:after_id AS uuid))",
        "t.created_at ASC, t.id ASC",
    ),
    "dueDate": (
        """NOT :after_given
           OR (CAST(:after_due AS date) IS NOT NULL
               AND (t.due_date > CAST(:after_due AS date)
                    OR (t.due_date = CAST(:after_due AS date) AND t.id > CAST(:after_id AS uuid))
                    OR t.due_date IS NULL))
           OR (CAST(:after_due AS date) IS NULL AND t.due_date IS NULL AND t.id > CAST(:after_id AS uuid))""",
        "t.due_date ASC NULLS LAST, t.id ASC",
    ),
}


def create_task(conn: Connection, project_id: UUID, title: str, description: str, priority: str,
                assignee_id: UUID | None, due_date: date | None, actor_id: UUID) -> Row:
    row = fetch_one(
        conn,
        f"INSERT INTO tasks (project_id, title, description, priority, assignee_id, due_date, created_by) "
        f"VALUES (:project_id, :title, :description, :priority, :assignee_id, :due_date, :actor_id) RETURNING {TASK_COLUMNS}",
        {"project_id": project_id, "title": title, "description": description, "priority": priority,
         "assignee_id": assignee_id, "due_date": due_date, "actor_id": actor_id},
    )
    assert row is not None
    return row


def update_task(conn: Connection, task_id: UUID, changes: dict[str, Any]) -> None:
    update_columns(conn, "tasks", task_id, changes,
                   frozenset({"title", "description", "status", "priority", "assignee_id", "due_date"}))


def delete_task(conn: Connection, task_id: UUID) -> None:
    conn.execute(text("DELETE FROM tasks WHERE id = :id"), {"id": task_id})


def complete_task(conn: Connection, task_id: UUID, actor_id: UUID, expected_version: int) -> None:
    """The stored function locks the row, checks the version and the rules, and sets status done in one step."""
    conn.execute(text("SELECT id FROM complete_task(:task_id, :actor_id, :version)"),
                 {"task_id": task_id, "actor_id": actor_id, "version": expected_version})


def reassign_task(conn: Connection, task_id: UUID, assignee_id: UUID | None, actor_id: UUID, expected_version: int) -> None:
    conn.execute(text("SELECT id FROM reassign_task(:task_id, :assignee_id, :actor_id, :version)"),
                 {"task_id": task_id, "assignee_id": assignee_id, "actor_id": actor_id, "version": expected_version})
```

How `list_tasks` works: every filter is "on" only when its parameter is not NULL (or the array not empty), so one fixed SQL text serves all combinations and nothing is pasted together from user input. `KEYSETS` maps the `sort` value to two pieces of SQL: a condition that skips everything up to the cursor, and the `ORDER BY`. The `dueDate` order puts tasks without a due date last (`NULLS LAST`), so its cursor needs the three-way logic you see: after a dated row continue with later dates **or** the same date and a larger id **or** any undated row; after an undated row continue with undated rows of larger id. `ILIKE ... ESCAPE '\'` is a case-insensitive substring search that can use the trigram index of the schema. `complete_task` and `reassign_task` call the stored functions, which lock the row, compare the version and apply the business rules inside Postgres.

Create `app/repositories/comments.py`:

**File: `app/repositories/comments.py`**
```python
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, text

from app.repositories.sql import Row, fetch_all, fetch_one

COMMENT_SELECT = """
    SELECT c.id, c.task_id, c.body, c.created_at,
           u.id AS author_id, u.username AS author_username, u.display_name AS author_display_name
      FROM comments c JOIN users u ON u.id = c.author_id
"""


def shape(row: Row) -> Row:
    """Nest the author columns the way the Comment DTO expects them."""
    return {
        "id": row["id"], "task_id": row["task_id"], "body": row["body"], "created_at": row["created_at"],
        "author": {"id": row["author_id"], "username": row["author_username"], "display_name": row["author_display_name"]},
    }


def list_comments(conn: Connection, task_id: UUID, limit: int, after: list[Any] | None) -> list[Row]:
    rows = fetch_all(
        conn,
        COMMENT_SELECT + """
        WHERE c.task_id = :task_id
          AND (CAST(:after_created AS timestamptz) IS NULL
               OR (c.created_at, c.id) > (CAST(:after_created AS timestamptz), CAST(:after_id AS uuid)))
        ORDER BY c.created_at, c.id
        LIMIT :limit
        """,
        {"task_id": task_id, "after_created": after[0] if after else None, "after_id": after[1] if after else None, "limit": limit},
    )
    return [shape(row) for row in rows]


def get_comment(conn: Connection, comment_id: UUID) -> Row | None:
    row = fetch_one(conn, COMMENT_SELECT + " WHERE c.id = :id", {"id": comment_id})
    return None if row is None else shape(row)


def get_owner(conn: Connection, comment_id: UUID) -> Row | None:
    """Who wrote the comment and which team it belongs to: the two facts the delete rule needs."""
    return fetch_one(
        conn,
        "SELECT c.author_id, p.team_id FROM comments c JOIN tasks t ON t.id = c.task_id "
        "JOIN projects p ON p.id = t.project_id WHERE c.id = :id",
        {"id": comment_id},
    )


def create_comment(conn: Connection, task_id: UUID, author_id: UUID, body: str) -> UUID:
    return conn.execute(
        text("INSERT INTO comments (task_id, author_id, body) VALUES (:task_id, :author_id, :body) RETURNING id"),
        {"task_id": task_id, "author_id": author_id, "body": body},
    ).scalar_one()


def delete_comment(conn: Connection, comment_id: UUID) -> None:
    conn.execute(text("DELETE FROM comments WHERE id = :id"), {"id": comment_id})
```

Create `app/repositories/audit.py`:

**File: `app/repositories/audit.py`**
```python
from datetime import datetime
from typing import Any
from uuid import UUID

from sqlalchemy import Connection

from app.repositories.sql import Row, fetch_all


def list_audit(conn: Connection, *, entity_type: str | None, entity_id: UUID | None, actor_id: UUID | None,
               occurred_from: datetime | None, occurred_to: datetime | None, limit: int, after: list[Any] | None) -> list[Row]:
    """Newest first. The cursor is (occurred_at, id) of the last entry on the previous page."""
    return fetch_all(
        conn,
        """
        SELECT id, occurred_at, actor_id, action, entity_type, entity_id, details
          FROM audit_log
         WHERE (CAST(:entity_type AS text) IS NULL OR entity_type = :entity_type)
           AND (CAST(:entity_id AS uuid) IS NULL OR entity_id = CAST(:entity_id AS uuid))
           AND (CAST(:actor_id AS uuid) IS NULL OR actor_id = CAST(:actor_id AS uuid))
           AND (CAST(:occurred_from AS timestamptz) IS NULL OR occurred_at >= CAST(:occurred_from AS timestamptz))
           AND (CAST(:occurred_to AS timestamptz) IS NULL OR occurred_at < CAST(:occurred_to AS timestamptz))
           AND (CAST(:after_occurred AS timestamptz) IS NULL
                OR (occurred_at, id) < (CAST(:after_occurred AS timestamptz), CAST(:after_id AS bigint)))
         ORDER BY occurred_at DESC, id DESC
         LIMIT :limit
        """,
        {
            "entity_type": entity_type,
            "entity_id": entity_id,
            "actor_id": actor_id,
            "occurred_from": occurred_from,
            "occurred_to": occurred_to,
            "after_occurred": after[0] if after else None,
            "after_id": after[1] if after else None,
            "limit": limit,
        },
    )
```

### Step 5. Pagination, ETag helpers and idempotency
Create `app/pagination.py`:

**File: `app/pagination.py`**
```python
import base64
import json
from collections.abc import Callable
from datetime import date, datetime
from typing import Annotated, Any, Literal
from uuid import UUID

from fastapi import Query

from app.errors import bad_request
from app.schemas import Page, PageInfo

Limit = Annotated[int, Query(ge=1, le=100, description="Page size.")]
Cursor = Annotated[str | None, Query(min_length=1, max_length=512, description="Copied from page.nextCursor.")]
SortCreated = Annotated[Literal["-createdAt", "createdAt"], Query()]


def encode_cursor(values: list[Any]) -> str:
    """The values that identify the last row on the page, as JSON, then base64url without padding."""
    raw = json.dumps([v.isoformat() if isinstance(v, (date, datetime)) else str(v) if isinstance(v, UUID) else v
                      for v in values], separators=(",", ":"))
    return base64.urlsafe_b64encode(raw.encode()).rstrip(b"=").decode()


def decode_cursor(cursor: str, parsers: list[Callable[[Any], Any]]) -> list[Any]:
    """Parse and check every value; any failure is the client's fault, so it becomes a 400."""
    try:
        values = json.loads(base64.urlsafe_b64decode(cursor + "=" * (-len(cursor) % 4)))
        if not isinstance(values, list) or len(values) != len(parsers):
            raise ValueError("wrong shape")
        return [parse(value) for parse, value in zip(parsers, values)]
    except (ValueError, TypeError, AttributeError):
        raise bad_request("The cursor is not valid.") from None


def as_timestamp(value: Any) -> datetime:
    parsed = datetime.fromisoformat(value)
    if parsed.tzinfo is None:
        raise ValueError("timestamp without a zone")
    return parsed


def as_uuid(value: Any) -> UUID:
    if not isinstance(value, str):
        raise ValueError("not a string")
    return UUID(value)


def as_text(value: Any) -> str:
    if not isinstance(value, str):
        raise ValueError("not a string")
    return value


def as_int(value: Any) -> int:
    if not isinstance(value, int) or isinstance(value, bool):
        raise ValueError("not an integer")
    return value


def as_optional_date(value: Any) -> date | None:
    return None if value is None else date.fromisoformat(value)


def make_page[T](rows: list[dict[str, Any]], limit: int, model: type[T], cursor_of: Callable[[dict[str, Any]], list[Any]]) -> Page[T]:
    """Queries fetch limit + 1 rows: the extra row only proves that another page exists."""
    items = rows[:limit]
    next_cursor = encode_cursor(cursor_of(items[-1])) if len(rows) > limit else None
    return Page[model](items=[model.model_validate(row) for row in items], page=PageInfo(limit=limit, next_cursor=next_cursor))
```

A cursor is the position of the last row of a page: its sort values and its id. We encode them as JSON and **base64url** (a URL-safe text form) so the client treats the string as opaque. `decode_cursor` checks the shape and the type of every value with a small parser per value and turns any failure into a 400, never a 500. We do not sign cursors: whatever position a forged cursor names, every query still repeats the authorization condition, so it cannot show rows the caller may not see (TDD decision D10). `make_page` relies on the repositories fetching **one row more** than the limit: if that extra row exists there is a next page, and the cursor is built from the last row that is returned.

Create `app/http.py`:

**File: `app/http.py`**
```python
import re
from typing import Annotated, Any
from uuid import UUID

from fastapi import Header
from fastapi.responses import JSONResponse

from app.config import Settings
from app.errors import ProblemError, bad_request
from app.schemas import ApiModel

IfMatch = Annotated[str | None, Header(description='The ETag being changed, for example "3".')]
IdempotencyKey = Annotated[str | None, Header(min_length=8, max_length=128)]


def make_etag(version: int) -> str:
    return f'"{version}"'


def parse_if_match(value: str | None, *, required: bool = True) -> int | None:
    """Read the version out of one strong ETag. A missing header is 428; anything else that is not an ETag is 400."""
    if value is None:
        if required:
            raise ProblemError(428, "The If-Match header is required. Read the resource first and send its ETag.")
        return None
    match = re.fullmatch(r'"(\d{1,9})"', value.strip())
    if match is None:
        raise bad_request('If-Match must be one strong ETag such as "3".')
    return int(match.group(1))


def etag_matches(if_none_match: str | None, version: int) -> bool:
    """If-None-Match uses the weak comparison: W/"3" matches "3"; * matches any existing resource."""
    if if_none_match is None:
        return False
    candidates = [part.strip().removeprefix("W/") for part in if_none_match.split(",")]
    return "*" in candidates or make_etag(version) in candidates


def resource_url(settings: Settings, path: str, resource_id: UUID | str) -> str:
    return f"{settings.public_base_url.rstrip('/')}{path}/{resource_id}"


def to_json(model: type[ApiModel], row: dict[str, Any]) -> dict[str, Any]:
    """A database row as the JSON body of the API (camelCase, dates as text). This is what idempotency stores."""
    return model.model_validate(row).model_dump(mode="json", by_alias=True)


def json_with_etag(model: type[ApiModel], row: dict[str, Any]) -> JSONResponse:
    """200 with the resource as JSON and its ETag (the quoted version)."""
    return JSONResponse(to_json(model, row), headers={"ETag": make_etag(row["version"])})


def created(body: dict[str, Any], location: str, *, replayed: bool = False) -> JSONResponse:
    """201 with Location and ETag; a replay of an Idempotency-Key adds Idempotent-Replayed: true."""
    headers = {"Location": location}
    if "version" in body:
        headers["ETag"] = make_etag(body["version"])
    if replayed:
        headers["Idempotent-Replayed"] = "true"
    return JSONResponse(body, status_code=201, headers=headers)
```

`parse_if_match` accepts exactly one strong ETag such as `"3"`; a missing header is 428, anything else 400. `etag_matches` implements the weak comparison that `If-None-Match` uses (RFC 9110). `created` builds a 201 response with `Location` and `ETag`, plus `Idempotent-Replayed: true` for a replay. `Location` comes from the `PUBLIC_BASE_URL` setting and never from the request's `Host` header, which a client controls.

Create `app/idempotency.py`:

**File: `app/idempotency.py`**
```python
import hashlib
import json
from collections.abc import Callable
from typing import Any
from uuid import UUID

from pydantic import BaseModel
from sqlalchemy import Connection, text

from app.errors import ProblemError, conflict


def fingerprint(method: str, path: str, body: BaseModel) -> str:
    """Two requests are 'the same' when method, path and the JSON body (key order ignored) are equal."""
    canonical = json.dumps(body.model_dump(mode="json", by_alias=True), sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(f"{method} {path} {canonical}".encode()).hexdigest()


def run_idempotent(conn: Connection, user_id: UUID, key: str | None, request_hash: str,
                   create: Callable[[], dict[str, Any]]) -> tuple[dict[str, Any], bool]:
    """Run `create` once per (user, key). Returns the response body and whether it is a replay.

    The key row and the new resource are written in ONE transaction. A second request with the same key
    waits on the unique index until the first one commits, then replays its stored body. If `create`
    fails, the whole transaction rolls back, so the key is free again and the client may retry.
    """
    if key is None:
        return create(), False
    params = {"user_id": user_id, "key": key, "hash": request_hash}
    conn.execute(text("DELETE FROM idempotency_keys WHERE user_id = :user_id AND key = :key AND expires_at < now()"), params)
    claimed = conn.execute(
        text("INSERT INTO idempotency_keys (user_id, key, request_hash) VALUES (:user_id, :key, :hash) "
             "ON CONFLICT DO NOTHING RETURNING 1"),
        params,
    ).first()
    if claimed:
        body = create()
        conn.execute(
            text("UPDATE idempotency_keys SET status_code = 201, response_body = CAST(:body AS jsonb) "
                 "WHERE user_id = :user_id AND key = :key"),
            {**params, "body": json.dumps(body)},
        )
        return body, False
    stored = conn.execute(
        text("SELECT request_hash, status_code, response_body FROM idempotency_keys WHERE user_id = :user_id AND key = :key"),
        params,
    ).mappings().one()
    if stored["request_hash"] != request_hash:
        raise ProblemError(422, "This Idempotency-Key was already used with a different request.")
    if stored["status_code"] is None:
        raise conflict("A request with this Idempotency-Key is still being processed.")
    return stored["response_body"], True
```

An **idempotency key** makes a create safe to repeat: a network error after the server created the task must not make the client create it twice. The trick is to use the database as the arbiter. In one transaction we insert the key row (`ON CONFLICT DO NOTHING`), and if we won the insert we create the resource and store the response body on the key row. A second request with the same key blocks on the unique index until the first one commits, then finds the stored row and replays it. A different request body under the same key (different hash) is a 422. If creating fails, the transaction rolls back and the key row disappears with it, so the client may simply retry. The status 409 "still in progress" cannot normally occur with this design; it remains as a defensive branch.

### Step 6. Who is calling, and may they?
Create `app/dependencies.py`. A **dependency** is a function FastAPI calls for you and whose result it passes to the route:

**File: `app/dependencies.py`**
```python
from typing import Annotated

from fastapi import Depends, Request

from app.config import Settings, get_settings
from app.db import Database


def get_db(request: Request) -> Database:
    return request.app.state.db


Db = Annotated[Database, Depends(get_db)]
AppSettings = Annotated[Settings, Depends(get_settings)]
```

`Db` and `AppSettings` are `Annotated` shortcuts, so a route can simply write `db: Db`. Now create `app/auth.py`:

**File: `app/auth.py`**
```python
import base64
import json
import logging
from dataclasses import dataclass
from typing import Annotated, Any
from uuid import UUID

from fastapi import Depends, Request, Security
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer, SecurityScopes

from app.db import Database
from app.dependencies import get_db
from app.errors import forbidden, unauthorized
from app.repositories import users

logger = logging.getLogger("tasksteams.auth")
bearer_scheme = HTTPBearer(auto_error=False)
KNOWN_ROLES = {"admin", "member"}
_known_users: set[UUID] = set()  # ids already stored in this process, so most requests skip the INSERT


@dataclass(frozen=True)
class Principal:
    """Who is calling, as the rest of the code sees it. Nothing below the HTTP layer knows about tokens."""

    user_id: UUID
    username: str
    email: str
    display_name: str
    roles: frozenset[str]
    scopes: frozenset[str]

    @property
    def is_admin(self) -> bool:
        return "admin" in self.roles


def read_claims(token: str) -> dict[str, Any]:
    """DEVELOPMENT ONLY (phase 2): reads the payload and trusts it. Phase 3 replaces this with real validation."""
    try:
        payload = token.split(".")[1]
        claims = json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))
        if not isinstance(claims, dict):
            raise ValueError("payload is not an object")
        return claims
    except (IndexError, ValueError):
        raise unauthorized("The access token is malformed.") from None


def principal_from_claims(claims: dict[str, Any]) -> Principal:
    try:
        user_id = UUID(str(claims["sub"]))
    except (KeyError, ValueError):
        raise unauthorized("The access token has no valid subject.") from None
    username = str(claims.get("preferred_username") or user_id)
    roles = claims.get("realm_access", {}).get("roles", [])
    return Principal(
        user_id=user_id,
        username=username,
        email=str(claims.get("email") or f"{username}@users.invalid"),
        display_name=str(claims.get("name") or username),
        roles=frozenset(role for role in roles if role in KNOWN_ROLES),
        scopes=frozenset(str(claims.get("scope", "")).split()),
    )


def authenticate(
    security_scopes: SecurityScopes,
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Database = Depends(get_db),
) -> Principal:
    """Dependency for every protected route: 401 without a usable token, 403 without the required scopes."""
    if credentials is None:
        raise unauthorized("A bearer access token is required.")
    principal = principal_from_claims(read_claims(credentials.credentials))
    missing = [scope for scope in security_scopes.scopes if scope not in principal.scopes]
    if missing:
        raise forbidden(f"The scope {missing[0]} is required.")
    if principal.user_id not in _known_users:
        with db.transaction() as conn:
            users.ensure_user(conn, principal.user_id, principal.username, principal.email, principal.display_name)
        _known_users.add(principal.user_id)
    request.state.user_id = str(principal.user_id)
    return principal


def require_admin(principal: Principal = Security(authenticate)) -> Principal:
    if not principal.is_admin:
        raise forbidden("The admin role is required.")
    return principal


# Route parameters: `principal: Reader` means "signed in, with scope tasks:read". The scope decides what the
# CLIENT may do, the role decides what the USER may do, and a request needs both.
Reader = Annotated[Principal, Security(authenticate, scopes=["tasks:read"])]
Writer = Annotated[Principal, Security(authenticate, scopes=["tasks:write"])]
AdminWriter = Annotated[Principal, Security(require_admin, scopes=["tasks:write"])]
AdminOnly = Annotated[Principal, Security(require_admin, scopes=["tasks:admin"])]
```

Read the stand-in carefully. `read_claims` decodes the middle part of the token and **believes it**. Everything after it is final code and stays: `principal_from_claims` builds a `Principal` (user id, roles, scopes), `authenticate` checks the scopes the route declares and makes sure the user row exists, and `Reader`, `Writer`, `AdminWriter` and `AdminOnly` are ready-made parameter types that name the required scope and role. The scope belongs to the **client** (what the app may do for the user), the role to the **user** (what they may do at all); a request needs both. Only `read_claims` changes in chapter 03.

Create `app/access.py`:

**File: `app/access.py`**
```python
from dataclasses import dataclass
from uuid import UUID

from sqlalchemy import Connection

from app.auth import Principal
from app.errors import ProblemError, forbidden, not_found
from app.repositories import comments, projects, tasks, teams
from app.repositories.sql import Row


@dataclass(frozen=True)
class Access:
    """What the caller may do inside one team: 'admin' (everything), 'lead' (manage) or 'member' (work)."""

    team_id: UUID
    level: str

    @property
    def can_manage(self) -> bool:
        return self.level in ("admin", "lead")

    def require_manage(self, action: str) -> None:
        if not self.can_manage:
            raise forbidden(f"Only a team lead or an admin may {action}.")


def team_access(conn: Connection, principal: Principal, team_id: UUID) -> Access:
    """404 for a team that does not exist AND for a team the caller does not belong to, so ids cannot be probed."""
    row = teams.get_access(conn, team_id, principal.user_id)
    if row is None or (row["role"] is None and not principal.is_admin):
        raise not_found("The team was not found.")
    return Access(team_id, "admin" if principal.is_admin else row["role"])


def project_access(conn: Connection, principal: Principal, project_id: UUID) -> tuple[Row, Access]:
    project = projects.get_project(conn, project_id)
    if project is None:
        raise not_found("The project was not found.")
    try:
        return project, team_access(conn, principal, project["team_id"])
    except ProblemError:
        raise not_found("The project was not found.") from None


def task_access(conn: Connection, principal: Principal, task_id: UUID) -> tuple[Row, Access]:
    task = tasks.get_task(conn, task_id)
    if task is None:
        raise not_found("The task was not found.")
    try:
        return task, team_access(conn, principal, task["team_id"])
    except ProblemError:
        raise not_found("The task was not found.") from None


def comment_access(conn: Connection, principal: Principal, comment_id: UUID) -> tuple[Row, Access]:
    owner = comments.get_owner(conn, comment_id)
    if owner is None:
        raise not_found("The comment was not found.")
    try:
        return owner, team_access(conn, principal, owner["team_id"])
    except ProblemError:
        raise not_found("The comment was not found.") from None
```

This file is the object-level authorization of the API (OWASP API1). Every object (project, task, comment) belongs to a team, and `team_access` answers **404 for a team the caller does not belong to, exactly as for a team that does not exist**, so nobody can learn which ids exist. Inside a team the role decides: a member may work, only a lead or an admin may `require_manage`, which answers **403** because the caller already knows the object exists.

### Step 7. Map database errors to problem details
Create `app/db_errors.py`:

**File: `app/db_errors.py`**
```python
import logging

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from sqlalchemy.exc import DBAPIError
from sqlalchemy.exc import TimeoutError as PoolTimeoutError

from app.errors import problem_response

logger = logging.getLogger("tasksteams.db")

# SQLSTATE -> HTTP status. TS404, TS409, TS412 and TS422 are raised by the stored functions in schema.sql.
SQLSTATE_STATUS = {
    "TS404": 404,
    "TS409": 409,
    "TS412": 412,
    "TS422": 422,
    "23505": 409,  # unique_violation: duplicate team name or project key
    "23503": 422,  # foreign_key_violation
    "23514": 422,  # check_violation
    "22P02": 400,  # invalid_text_representation
}

# Only the messages written by our own functions (TS...) are safe to show; the rest get a fixed text.
FIXED_DETAIL = {
    "23505": "A resource with the same name or key already exists.",
    "23503": "A referenced resource does not exist.",
    "23514": "A value breaks a data rule.",
    "22P02": "A value has the wrong format.",
}


async def handle_database_error(request: Request, exc: DBAPIError) -> JSONResponse:
    sqlstate = getattr(exc.orig, "sqlstate", None)
    status = SQLSTATE_STATUS.get(sqlstate or "")
    path = request.url.path
    if status is None:
        if sqlstate is None or sqlstate.startswith(("08", "53", "57")):  # connection, resources, shutdown
            logger.error("database unavailable: %s", type(exc.orig).__name__)
            return problem_response(path, 503, "The database is not available.", headers={"Retry-After": "5"})
        logger.error("unexpected database error %s", sqlstate, exc_info=exc)
        return problem_response(path, 500, "An unexpected error occurred.")
    if sqlstate.startswith("TS"):
        detail = exc.orig.diag.message_primary or "The request cannot be completed."
    else:
        detail = FIXED_DETAIL[sqlstate]
    return problem_response(path, status, detail, code="duplicate" if sqlstate == "23505" else None)


async def handle_pool_timeout(request: Request, exc: PoolTimeoutError) -> JSONResponse:
    logger.error("connection pool exhausted")
    return problem_response(request.url.path, 503, "The server is busy, try again.", headers={"Retry-After": "2"})


def register_database_handlers(app: FastAPI) -> None:
    app.add_exception_handler(DBAPIError, handle_database_error)
    app.add_exception_handler(PoolTimeoutError, handle_pool_timeout)
```

The stored functions signal problems with custom SQLSTATE codes (`TS404`, `TS409`, `TS412`, `TS422`); Postgres itself uses codes such as `23505` (unique violation). This one handler turns them into the right problem details. Only messages we wrote ourselves (the `TS...` ones) are shown to the client; everything else gets a fixed sentence, so a constraint or table name never leaks. A database that cannot be reached has no SQLSTATE at all: that becomes **503** with `Retry-After`, not 500.

### Step 8. The routers
Replace `app/routers/health.py`. It now asks the database:

**File: `app/routers/health.py`**
```python
from fastapi import APIRouter, Response

from app.dependencies import AppSettings, Db
from app.schemas import Health

router = APIRouter(tags=["Platform"])


@router.get("/health", response_model=Health, response_model_exclude_none=True)
def get_health(response: Response, db: Db, settings: AppSettings) -> Health:
    if db.ping():
        return Health(status="ok", version=settings.service_version, database="up")
    response.status_code = 503
    return Health(status="degraded", version=settings.service_version, database="down")
```

Replace `app/routers/me.py`. The stub is gone; the caller comes from the token, the details from the database:

**File: `app/routers/me.py`**
```python
from fastapi import APIRouter

from app.auth import Reader
from app.dependencies import Db
from app.repositories import members, users
from app.schemas import Me, TeamRef

router = APIRouter(prefix="/v1", tags=["Platform"])


@router.get("/me", response_model=Me)
def get_me(principal: Reader, db: Db) -> Me:
    with db.transaction() as conn:
        user = users.get_user(conn, principal.user_id)
        teams = members.teams_of(conn, principal.user_id)
    assert user is not None  # authenticate() stored the row on first use
    return Me(
        id=user["id"],
        username=user["username"],
        email=user["email"],
        display_name=user["display_name"],
        roles=sorted(principal.roles),
        scopes=sorted(principal.scopes),
        teams=[TeamRef.model_validate(team) for team in teams],
    )
```

Create `app/routers/users.py`:

**File: `app/routers/users.py`**
```python
from typing import Annotated

from fastapi import APIRouter, Query

from app.auth import Reader
from app.dependencies import Db
from app.pagination import Cursor, Limit, as_text, as_uuid, decode_cursor, make_page
from app.repositories import users
from app.schemas import Page, UserSummary

router = APIRouter(prefix="/v1/users", tags=["Platform"])


@router.get("", response_model=Page[UserSummary])
def list_users(principal: Reader, db: Db, q: Annotated[str | None, Query(min_length=1, max_length=100)] = None,
               limit: Limit = 25, cursor: Cursor = None) -> Page[UserSummary]:
    after = decode_cursor(cursor, [as_text, as_uuid]) if cursor else None
    with db.transaction() as conn:
        rows = users.list_users(conn, q, limit + 1, after)
    return make_page(rows, limit, UserSummary, lambda row: [row["username"], row["id"]])
```

Replace `app/routers/teams.py`:

**File: `app/routers/teams.py`**
```python
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Query, Response

from app.access import team_access
from app.auth import AdminOnly, AdminWriter, Reader, Writer
from app.dependencies import AppSettings, Db
from app.http import IdempotencyKey, IfMatch, created, make_etag, parse_if_match, resource_url, to_json
from app.idempotency import fingerprint, run_idempotent
from app.pagination import Cursor, Limit, SortCreated, as_timestamp, as_uuid, decode_cursor, make_page
from app.repositories import teams
from app.repositories.sql import lock_and_check
from app.schemas import Page, Team, TeamCreate, TeamUpdate

router = APIRouter(prefix="/v1/teams", tags=["Teams"])


@router.get("", response_model=Page[Team])
def list_teams(principal: Reader, db: Db, q: Annotated[str | None, Query(min_length=1, max_length=100)] = None,
               sort: SortCreated = "-createdAt", limit: Limit = 25, cursor: Cursor = None) -> Page[Team]:
    after = decode_cursor(cursor, [as_timestamp, as_uuid]) if cursor else None
    with db.transaction() as conn:
        rows = teams.list_teams(conn, principal.user_id, principal.is_admin, q, sort == "-createdAt", limit + 1, after)
    return make_page(rows, limit, Team, lambda row: [row["created_at"], row["id"]])


@router.post("", response_model=Team, status_code=201)
def create_team(body: TeamCreate, principal: AdminWriter, db: Db, settings: AppSettings, idempotency_key: IdempotencyKey = None):
    request_hash = fingerprint("POST", "/v1/teams", body)
    with db.transaction(principal.user_id) as conn:
        def create() -> dict:
            team_id = teams.create_team(conn, body.name, body.description, body.lead_user_id or principal.user_id, principal.user_id)
            return to_json(Team, teams.get_team(conn, team_id))

        data, replayed = run_idempotent(conn, principal.user_id, idempotency_key, request_hash, create)
    return created(data, resource_url(settings, "/v1/teams", data["id"]), replayed=replayed)


@router.get("/{team_id}", response_model=Team)
def get_team(team_id: UUID, response: Response, principal: Reader, db: Db) -> Team:
    with db.transaction() as conn:
        team_access(conn, principal, team_id)
        row = teams.get_team(conn, team_id)
    response.headers["ETag"] = make_etag(row["version"])
    return Team.model_validate(row)


@router.patch("/{team_id}", response_model=Team)
def update_team(team_id: UUID, body: TeamUpdate, response: Response, principal: Writer, db: Db, if_match: IfMatch = None) -> Team:
    expected_version = parse_if_match(if_match)
    with db.transaction(principal.user_id) as conn:
        team_access(conn, principal, team_id).require_manage("change the team")
        lock_and_check(conn, "teams", team_id, expected_version, "team")
        teams.update_team(conn, team_id, body.model_dump(exclude_unset=True))
        row = teams.get_team(conn, team_id)
    response.headers["ETag"] = make_etag(row["version"])
    return Team.model_validate(row)


@router.delete("/{team_id}", status_code=204)
def delete_team(team_id: UUID, principal: AdminOnly, db: Db) -> Response:
    with db.transaction(principal.user_id) as conn:
        team_access(conn, principal, team_id)
        teams.delete_team(conn, team_id)
    return Response(status_code=204)
```

Look at `create_team`: `run_idempotent` receives a small inner function `create` that does the real work, so the same code path serves "no key", "first time" and "replay". `update_team` shows the order of checks for every `PATCH`: header (428), access (404 or 403), version (412), update, read back, answer with the new ETag. `delete_team` uses the `AdminOnly` type: scope `tasks:admin` and the `admin` role.

Create `app/routers/members.py`:

**File: `app/routers/members.py`**
```python
from uuid import UUID

from fastapi import APIRouter, Response

from app.access import team_access
from app.auth import Reader, Writer
from app.dependencies import Db
from app.errors import conflict, not_found
from app.pagination import Cursor, Limit, as_timestamp, as_uuid, decode_cursor, make_page
from app.repositories import members, users
from app.schemas import Member, MemberPut, Page

router = APIRouter(prefix="/v1/teams/{team_id}/members", tags=["Members"])


@router.get("", response_model=Page[Member])
def list_members(team_id: UUID, principal: Reader, db: Db, limit: Limit = 25, cursor: Cursor = None) -> Page[Member]:
    after = decode_cursor(cursor, [as_timestamp, as_uuid]) if cursor else None
    with db.transaction() as conn:
        team_access(conn, principal, team_id)
        rows = members.list_members(conn, team_id, limit + 1, after)
    return make_page(rows, limit, Member, lambda row: [row["joined_at"], row["user_id"]])


@router.put("/{user_id}", response_model=Member)
def put_member(team_id: UUID, user_id: UUID, body: MemberPut, response: Response, principal: Writer, db: Db) -> Member:
    with db.transaction(principal.user_id) as conn:
        team_access(conn, principal, team_id).require_manage("manage members")
        if users.get_user(conn, user_id) is None:
            raise not_found("The user was not found.")
        if body.role != "lead" and members.lock_leads(conn, team_id) == [user_id]:
            raise conflict("A team needs at least one lead.", code="last_lead")
        inserted = members.put_member(conn, team_id, user_id, body.role)
        row = members.get_member(conn, team_id, user_id)
    response.status_code = 201 if inserted else 200
    return Member.model_validate(row)


@router.delete("/{user_id}", status_code=204)
def remove_member(team_id: UUID, user_id: UUID, principal: Writer, db: Db) -> Response:
    with db.transaction(principal.user_id) as conn:
        team_access(conn, principal, team_id).require_manage("manage members")
        if members.get_member(conn, team_id, user_id) is None:
            raise not_found("The user is not a member of this team.")
        if members.lock_leads(conn, team_id) == [user_id]:
            raise conflict("The last lead cannot be removed.", code="last_lead")
        members.delete_member(conn, team_id, user_id)
    return Response(status_code=204)
```

Create `app/routers/projects.py`:

**File: `app/routers/projects.py`**
```python
from uuid import UUID

from fastapi import APIRouter, Response

from app.access import project_access, team_access
from app.auth import Reader, Writer
from app.dependencies import AppSettings, Db
from app.http import IdempotencyKey, IfMatch, created, make_etag, parse_if_match, resource_url, to_json
from app.idempotency import fingerprint, run_idempotent
from app.pagination import Cursor, Limit, SortCreated, as_timestamp, as_uuid, decode_cursor, make_page
from app.repositories import projects
from app.repositories.sql import lock_and_check
from app.schemas import Page, Project, ProjectCreate, ProjectUpdate

router = APIRouter(tags=["Projects"])


@router.get("/v1/teams/{team_id}/projects", response_model=Page[Project])
def list_projects(team_id: UUID, principal: Reader, db: Db, archived: bool = False, sort: SortCreated = "-createdAt",
                  limit: Limit = 25, cursor: Cursor = None) -> Page[Project]:
    after = decode_cursor(cursor, [as_timestamp, as_uuid]) if cursor else None
    with db.transaction() as conn:
        team_access(conn, principal, team_id)
        rows = projects.list_projects(conn, team_id, archived, sort == "-createdAt", limit + 1, after)
    return make_page(rows, limit, Project, lambda row: [row["created_at"], row["id"]])


@router.post("/v1/teams/{team_id}/projects", response_model=Project, status_code=201)
def create_project(team_id: UUID, body: ProjectCreate, principal: Writer, db: Db, settings: AppSettings,
                   idempotency_key: IdempotencyKey = None):
    request_hash = fingerprint("POST", f"/v1/teams/{team_id}/projects", body)
    with db.transaction(principal.user_id) as conn:
        team_access(conn, principal, team_id).require_manage("create projects")

        def create() -> dict:
            return to_json(Project, projects.create_project(conn, team_id, body.key, body.name, body.description, principal.user_id))

        data, replayed = run_idempotent(conn, principal.user_id, idempotency_key, request_hash, create)
    return created(data, resource_url(settings, "/v1/projects", data["id"]), replayed=replayed)


@router.get("/v1/projects/{project_id}", response_model=Project)
def get_project(project_id: UUID, response: Response, principal: Reader, db: Db) -> Project:
    with db.transaction() as conn:
        project, _ = project_access(conn, principal, project_id)
    response.headers["ETag"] = make_etag(project["version"])
    return Project.model_validate(project)


@router.patch("/v1/projects/{project_id}", response_model=Project)
def update_project(project_id: UUID, body: ProjectUpdate, response: Response, principal: Writer, db: Db,
                   if_match: IfMatch = None) -> Project:
    expected_version = parse_if_match(if_match)
    with db.transaction(principal.user_id) as conn:
        _, access = project_access(conn, principal, project_id)
        access.require_manage("change the project")
        lock_and_check(conn, "projects", project_id, expected_version, "project")
        projects.update_project(conn, project_id, body.model_dump(exclude_unset=True))
        project = projects.get_project(conn, project_id)
    response.headers["ETag"] = make_etag(project["version"])
    return Project.model_validate(project)


@router.delete("/v1/projects/{project_id}", status_code=204)
def delete_project(project_id: UUID, principal: Writer, db: Db) -> Response:
    with db.transaction(principal.user_id) as conn:
        _, access = project_access(conn, principal, project_id)
        access.require_manage("delete the project")
        projects.delete_project(conn, project_id)
    return Response(status_code=204)
```

Create `app/routers/tasks.py`:

**File: `app/routers/tasks.py`**
```python
from datetime import date
from typing import Annotated, Literal
from uuid import UUID

from fastapi import APIRouter, Header, Query, Response
from sqlalchemy import Connection

from app.access import project_access, task_access
from app.auth import Reader, Writer
from app.dependencies import AppSettings, Db
from app.errors import ProblemError
from app.http import (IdempotencyKey, IfMatch, created, etag_matches, json_with_etag, make_etag, parse_if_match,
                      resource_url, to_json)
from app.idempotency import fingerprint, run_idempotent
from app.pagination import Cursor, Limit, as_optional_date, as_timestamp, as_uuid, decode_cursor, make_page
from app.repositories import members, tasks
from app.repositories.sql import lock_and_check
from app.schemas import Page, ReassignRequest, Task, TaskCreate, TaskPriority, TaskStatus, TaskUpdate

router = APIRouter(tags=["Tasks"])
TaskSort = Annotated[Literal["-createdAt", "createdAt", "dueDate"], Query()]


def require_team_member(conn: Connection, team_id: UUID, assignee_id: UUID | None) -> None:
    """An assignee must belong to the project's team. This is a field problem, so it is a 422 with a pointer."""
    if assignee_id is not None and members.get_membership(conn, team_id, assignee_id) is None:
        raise ProblemError(422, "One or more fields are invalid.",
                           errors=[{"pointer": "/assigneeId", "detail": "must be a member of the project's team"}])


@router.get("/v1/projects/{project_id}/tasks", response_model=Page[Task])
def list_tasks(
    project_id: UUID, principal: Reader, db: Db,
    status: Annotated[list[TaskStatus] | None, Query(description="Repeat to match several statuses.")] = None,
    priority: Annotated[list[TaskPriority] | None, Query()] = None,
    assignee_id: Annotated[UUID | None, Query(alias="assigneeId")] = None,
    due_before: Annotated[date | None, Query(alias="dueBefore")] = None,
    due_after: Annotated[date | None, Query(alias="dueAfter")] = None,
    q: Annotated[str | None, Query(min_length=1, max_length=100)] = None,
    sort: TaskSort = "-createdAt", limit: Limit = 25, cursor: Cursor = None,
) -> Page[Task]:
    parsers = [as_optional_date, as_uuid] if sort == "dueDate" else [as_timestamp, as_uuid]
    after = decode_cursor(cursor, parsers) if cursor else None
    with db.transaction() as conn:
        project_access(conn, principal, project_id)
        rows = tasks.list_tasks(conn, project_id, statuses=status or [], priorities=priority or [], assignee_id=assignee_id,
                                due_before=due_before, due_after=due_after, title_contains=q, sort=sort,
                                limit=limit + 1, after=after)
    key = "due_date" if sort == "dueDate" else "created_at"
    return make_page(rows, limit, Task, lambda row: [row[key], row["id"]])


@router.post("/v1/projects/{project_id}/tasks", response_model=Task, status_code=201)
def create_task(project_id: UUID, body: TaskCreate, principal: Writer, db: Db, settings: AppSettings,
                idempotency_key: IdempotencyKey = None):
    request_hash = fingerprint("POST", f"/v1/projects/{project_id}/tasks", body)
    with db.transaction(principal.user_id) as conn:
        _, access = project_access(conn, principal, project_id)
        require_team_member(conn, access.team_id, body.assignee_id)

        def create() -> dict:
            row = tasks.create_task(conn, project_id, body.title, body.description, body.priority,
                                    body.assignee_id, body.due_date, principal.user_id)
            return to_json(Task, row)

        data, replayed = run_idempotent(conn, principal.user_id, idempotency_key, request_hash, create)
    return created(data, resource_url(settings, "/v1/tasks", data["id"]), replayed=replayed)


@router.get("/v1/tasks/{task_id}", response_model=Task)
def get_task(task_id: UUID, principal: Reader, db: Db, if_none_match: Annotated[str | None, Header()] = None):
    with db.transaction() as conn:
        task, _ = task_access(conn, principal, task_id)
    etag = make_etag(task["version"])
    if etag_matches(if_none_match, task["version"]):
        return Response(status_code=304, headers={"ETag": etag})
    return json_with_etag(Task, task)


@router.patch("/v1/tasks/{task_id}", response_model=Task)
def update_task(task_id: UUID, body: TaskUpdate, principal: Writer, db: Db, if_match: IfMatch = None):
    expected_version = parse_if_match(if_match)
    changes = body.model_dump(exclude_unset=True)
    with db.transaction(principal.user_id) as conn:
        _, access = task_access(conn, principal, task_id)
        require_team_member(conn, access.team_id, changes.get("assignee_id"))
        lock_and_check(conn, "tasks", task_id, expected_version, "task")
        tasks.update_task(conn, task_id, changes)
        task = tasks.get_task(conn, task_id)
    return json_with_etag(Task, task)


@router.delete("/v1/tasks/{task_id}", status_code=204)
def delete_task(task_id: UUID, principal: Writer, db: Db, if_match: IfMatch = None) -> Response:
    expected_version = parse_if_match(if_match, required=False)
    with db.transaction(principal.user_id) as conn:
        _, access = task_access(conn, principal, task_id)
        access.require_manage("delete tasks")
        lock_and_check(conn, "tasks", task_id, expected_version, "task")
        tasks.delete_task(conn, task_id)
    return Response(status_code=204)


@router.post("/v1/tasks/{task_id}/complete", response_model=Task)
def complete_task(task_id: UUID, principal: Writer, db: Db, if_match: IfMatch = None):
    expected_version = parse_if_match(if_match)
    with db.transaction(principal.user_id) as conn:
        task_access(conn, principal, task_id)
        tasks.complete_task(conn, task_id, principal.user_id, expected_version)
        task = tasks.get_task(conn, task_id)
    return json_with_etag(Task, task)


@router.post("/v1/tasks/{task_id}/reassign", response_model=Task)
def reassign_task(task_id: UUID, body: ReassignRequest, principal: Writer, db: Db, if_match: IfMatch = None):
    expected_version = parse_if_match(if_match)
    with db.transaction(principal.user_id) as conn:
        _, access = task_access(conn, principal, task_id)
        access.require_manage("reassign tasks")
        tasks.reassign_task(conn, task_id, body.assignee_id, principal.user_id, expected_version)
        task = tasks.get_task(conn, task_id)
    return json_with_etag(Task, task)
```

`PATCH /v1/tasks/{id}` applies **JSON Merge Patch**: `body.model_dump(exclude_unset=True)` contains exactly the fields the client sent, and an explicit `null` for `assigneeId` or `dueDate` clears them. `complete` and `reassign` do not update rows themselves; they call the stored functions and let Postgres decide, which is why the error text for a cancelled task comes from the database.

Create `app/routers/comments.py`:

**File: `app/routers/comments.py`**
```python
from uuid import UUID

from fastapi import APIRouter, Response

from app.access import comment_access, task_access
from app.auth import Reader, Writer
from app.dependencies import AppSettings, Db
from app.errors import forbidden
from app.http import IdempotencyKey, created, resource_url, to_json
from app.idempotency import fingerprint, run_idempotent
from app.pagination import Cursor, Limit, as_timestamp, as_uuid, decode_cursor, make_page
from app.repositories import comments
from app.schemas import Comment, CommentCreate, Page

router = APIRouter(tags=["Comments"])


@router.get("/v1/tasks/{task_id}/comments", response_model=Page[Comment])
def list_comments(task_id: UUID, principal: Reader, db: Db, limit: Limit = 25, cursor: Cursor = None) -> Page[Comment]:
    after = decode_cursor(cursor, [as_timestamp, as_uuid]) if cursor else None
    with db.transaction() as conn:
        task_access(conn, principal, task_id)
        rows = comments.list_comments(conn, task_id, limit + 1, after)
    return make_page(rows, limit, Comment, lambda row: [row["created_at"], row["id"]])


@router.post("/v1/tasks/{task_id}/comments", response_model=Comment, status_code=201)
def create_comment(task_id: UUID, body: CommentCreate, principal: Writer, db: Db, settings: AppSettings,
                   idempotency_key: IdempotencyKey = None):
    request_hash = fingerprint("POST", f"/v1/tasks/{task_id}/comments", body)
    with db.transaction(principal.user_id) as conn:
        task_access(conn, principal, task_id)

        def create() -> dict:
            comment_id = comments.create_comment(conn, task_id, principal.user_id, body.body)
            return to_json(Comment, comments.get_comment(conn, comment_id))

        data, replayed = run_idempotent(conn, principal.user_id, idempotency_key, request_hash, create)
    return created(data, resource_url(settings, "/v1/comments", data["id"]), replayed=replayed)


@router.delete("/v1/comments/{comment_id}", status_code=204)
def delete_comment(comment_id: UUID, principal: Writer, db: Db) -> Response:
    with db.transaction(principal.user_id) as conn:
        owner, access = comment_access(conn, principal, comment_id)
        if not access.can_manage and owner["author_id"] != principal.user_id:
            raise forbidden("Only the author, a team lead or an admin may delete a comment.")
        comments.delete_comment(conn, comment_id)
    return Response(status_code=204)
```

Create `app/routers/audit.py`:

**File: `app/routers/audit.py`**
```python
from datetime import datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Query

from app.auth import AdminOnly
from app.dependencies import Db
from app.pagination import Cursor, Limit, as_int, as_timestamp, decode_cursor, make_page
from app.repositories import audit
from app.schemas import AuditEntityType, AuditEntry, Page

router = APIRouter(prefix="/v1/audit-log", tags=["Audit"])


@router.get("", response_model=Page[AuditEntry])
def list_audit_log(
    principal: AdminOnly, db: Db,
    entity_type: Annotated[AuditEntityType | None, Query(alias="entityType")] = None,
    entity_id: Annotated[UUID | None, Query(alias="entityId")] = None,
    actor_id: Annotated[UUID | None, Query(alias="actorId")] = None,
    occurred_from: Annotated[datetime | None, Query(alias="from")] = None,
    occurred_to: Annotated[datetime | None, Query(alias="to")] = None,
    limit: Limit = 25, cursor: Cursor = None,
) -> Page[AuditEntry]:
    after = decode_cursor(cursor, [as_timestamp, as_int]) if cursor else None
    with db.transaction() as conn:
        rows = audit.list_audit(conn, entity_type=entity_type, entity_id=entity_id, actor_id=actor_id,
                                occurred_from=occurred_from, occurred_to=occurred_to, limit=limit + 1, after=after)
    return make_page(rows, limit, AuditEntry, lambda row: [row["occurred_at"], row["id"]])
```

Replace `app/main.py`. It now creates the database pool when the application starts (the **lifespan**) and closes it when it stops:

**File: `app/main.py`**
```python
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.config import get_settings
from app.db import Database
from app.db_errors import register_database_handlers
from app.errors import register_error_handlers
from app.logging_config import configure_logging
from app.middleware import RequestContextMiddleware
from app.routers import audit, comments, health, me, members, projects, tasks, teams, users


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    app.state.db = Database(settings.database_url, settings.db_pool_size, settings.db_max_overflow)
    yield
    app.state.db.dispose()


def create_app() -> FastAPI:
    settings = get_settings()
    configure_logging(settings.log_level)
    app = FastAPI(
        title="Tasks and Teams API",
        version=settings.service_version,
        lifespan=lifespan,
        docs_url="/docs" if settings.enable_docs else None,
        redoc_url=None,
        openapi_url="/openapi.json" if settings.enable_docs else None,
    )
    app.add_middleware(RequestContextMiddleware)
    register_error_handlers(app)
    register_database_handlers(app)
    for module in (health, me, users, teams, members, projects, tasks, comments, audit):
        app.include_router(module.router)
    return app


app = create_app()
```

### Step 9. Helper script and request files
Typing tokens and headers into curl differs a lot between shells (PowerShell 5.1 even rewrites double quotes inside arguments), so the project carries one small script that does the same everywhere. Create `scripts/call.py`:

**File: `scripts/call.py`**
```python
#!/usr/bin/env python3
"""Send one request to the API and print the answer the way `curl -i` would. Works the same in every shell.

  python scripts/call.py GET /health
  python scripts/call.py GET /v1/me --user bob
  python scripts/call.py POST /v1/projects/<id>/tasks --user bob --body requests/task-create.json --idempotency-key demo-key-0001
  python scripts/call.py PATCH /v1/tasks/<id> --user bob --body requests/task-patch.json --if-match 1
  python scripts/call.py token alice          prints only the access token, for use with curl

--user alice|bob|carol fetches a token from Keycloak (the tasks-smoke client, fake local users only).
"""
import argparse
import http.client
import json
import os
import sys
import urllib.parse
import urllib.request
from pathlib import Path

API_URL = os.environ.get("API_URL", "http://127.0.0.1:8000")
KEYCLOAK_URL = os.environ.get("KEYCLOAK_URL", "http://127.0.0.1:8180")
PASSWORDS = {"alice": "alice-local-fake", "bob": "bob-local-fake", "carol": "carol-local-fake"}


def get_token(username: str) -> str:
    form = urllib.parse.urlencode({
        "grant_type": "password",
        "client_id": "tasks-smoke",
        "username": username,
        "password": PASSWORDS[username],
        "scope": "openid tasks:read tasks:write tasks:admin",
    }).encode()
    url = f"{KEYCLOAK_URL}/realms/tasksteams/protocol/openid-connect/token"
    with urllib.request.urlopen(urllib.request.Request(url, data=form), timeout=15) as response:
        return json.load(response)["access_token"]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("method", help="GET, POST, PUT, PATCH, DELETE, or the word token")
    parser.add_argument("target", help="the path, for example /v1/me; or the user name after the word token")
    parser.add_argument("--user", choices=sorted(PASSWORDS), help="send a bearer token for this user")
    parser.add_argument("--token", help="send this bearer token as it is (for example a forged one)")
    parser.add_argument("--body", help="file with the JSON request body")
    parser.add_argument("--if-match", help="version number; sent as the strong ETag \"N\"")
    parser.add_argument("--if-none-match", help="version number; sent as \"N\"")
    parser.add_argument("--idempotency-key")
    parser.add_argument("--header", action="append", default=[], help="extra header as 'Name: value'")
    args = parser.parse_args()

    if args.method == "token":
        print(get_token(args.target))
        return 0

    headers = {"Accept": "application/json"}
    token = args.token or (get_token(args.user) if args.user else None)
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = None
    if args.body:
        data = Path(args.body).read_bytes()
        headers["Content-Type"] = "application/merge-patch+json" if args.method == "PATCH" else "application/json"
    if args.if_match:
        headers["If-Match"] = f'"{args.if_match}"'
    if args.if_none_match:
        headers["If-None-Match"] = f'"{args.if_none_match}"'
    if args.idempotency_key:
        headers["Idempotency-Key"] = args.idempotency_key
    for header in args.header:
        name, _, value = header.partition(":")
        headers[name.strip()] = value.strip()

    parts = urllib.parse.urlsplit(API_URL)
    connection = http.client.HTTPConnection(parts.hostname, parts.port or 80, timeout=30)
    connection.request(args.method, args.target, body=data, headers=headers)
    response = connection.getresponse()
    print(f"HTTP/1.1 {response.status} {response.reason}")
    for name, value in response.getheaders():
        print(f"{name.lower()}: {value}")
    print()
    print(response.read().decode("utf-8", errors="replace"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

`python scripts/call.py GET /v1/me --user bob` fetches a token for bob from Keycloak, sends the request and prints the answer in the same layout as `curl -i`. `--if-match 3` sends the header `If-Match: "3"` with the quotes the standard requires. `python scripts/call.py token alice` prints just a token, if you prefer curl. (The login with a password works only because the realm has the smoke client `tasks-smoke` for fake local users; real apps use the browser flow.)

Create the request bodies in `requests/` (the two team files from chapter 01 stay). `requests/task-create.json`:

**File: `requests/task-create.json`**
```json
{
  "title": "Review the OpenAPI file",
  "priority": "high",
  "dueDate": "2027-03-15"
}
```

`requests/task-create-other.json`:

**File: `requests/task-create-other.json`**
```json
{
  "title": "A different task"
}
```

`requests/task-patch.json`:

**File: `requests/task-patch.json`**
```json
{
  "status": "in_progress"
}
```

`requests/task-cancel.json`:

**File: `requests/task-cancel.json`**
```json
{
  "status": "cancelled"
}
```

`requests/reassign-outsider.json` (alice is not a member of the Mobile Team):

**File: `requests/reassign-outsider.json`**
```json
{
  "assigneeId": "a11ce000-0000-4000-8000-000000000001"
}
```

`requests/team-secret.json`:

**File: `requests/team-secret.json`**
```json
{
  "name": "Secret Team",
  "description": "Only carol and alice may see this team.",
  "leadUserId": "ca401000-0000-4000-8000-000000000003"
}
```

`requests/team-patch.json`:

**File: `requests/team-patch.json`**
```json
{
  "description": "Builds, runs and documents the shared platform."
}
```

## Run it
Start the API on your computer (the database and Keycloak run in Docker). Leave this terminal open:

```text
(.venv) tasksteams-api> python -m uvicorn app.main:app --port 8000
```

In a second terminal in the same folder, run the calls below. `python` here means the one of your environment (or any Python 3, the script uses only the standard library). Ids such as the task id differ in your run: copy them from the previous answer.

**1. Health now reports the database**

```text
tasksteams-api> python scripts/call.py GET /health
```

```text
HTTP/1.1 200 OK
date: Mon, 23 Nov 2026 08:33:40 GMT
server: uvicorn
content-length: 49
content-type: application/json
x-trace-id: e08123eedd0e477d81271056686f89e4

{"status":"ok","version":"1.0.0","database":"up"}
```

**2. Who am I?** Bob is a member of both seed teams. The first call creates nothing new (the seed has bob), a stranger would be inserted here:

```text
tasksteams-api> python scripts/call.py GET /v1/me --user bob
```

```text
HTTP/1.1 200 OK
date: Mon, 23 Nov 2026 08:33:41 GMT
server: uvicorn
content-length: 403
content-type: application/json
x-trace-id: fb1e2fce88e64cceb281ca0b858517c1

{"id":"b0b00000-0000-4000-8000-000000000002","username":"bob","email":"bob@tasksteams.test","displayName":"Bob Member","roles":["member"],"scopes":["email","openid","profile","tasks:admin","tasks:read","tasks:write"],"teams":[{"teamId":"7ea00000-0000-4000-8000-000000000002","name":"Mobile Team","role":"member"},{"teamId":"7ea00000-0000-4000-8000-000000000001","name":"Platform Team","role":"member"}]}
```

**3. Cursor pagination.** `limit=1` gives one team and a `nextCursor`; the second call passes it back as `cursor`:

```text
tasksteams-api> python scripts/call.py GET "/v1/teams?limit=1" --user bob
```

```text
HTTP/1.1 200 OK
date: Mon, 23 Nov 2026 08:33:41 GMT
server: uvicorn
content-length: 415
content-type: application/json
x-trace-id: 6ad7f2ed52ce45e6806450941799ad92

{"items":[{"id":"7ea00000-0000-4000-8000-000000000002","name":"Mobile Team","description":"Builds the phone apps.","memberCount":2,"createdBy":"a11ce000-0000-4000-8000-000000000001","version":1,"createdAt":"2026-11-23T08:32:45.468375Z","updatedAt":"2026-11-23T08:32:45.468375Z"}],"page":{"limit":1,"nextCursor":"WyIyMDI2LTExLTIzVDA4OjMyOjQ1LjQ2ODM3NSswMDowMCIsIjdlYTAwMDAwLTAwMDAtNDAwMC04MDAwLTAwMDAwMDAwMDAwMiJd"}}
```

```text
HTTP/1.1 200 OK
date: Mon, 23 Nov 2026 08:33:41 GMT
server: uvicorn
content-length: 333
content-type: application/json
x-trace-id: c8253df7d75541ec879bd9b843ec6dc2

{"items":[{"id":"7ea00000-0000-4000-8000-000000000001","name":"Platform Team","description":"Builds and runs the shared platform.","memberCount":3,"createdBy":"a11ce000-0000-4000-8000-000000000001","version":1,"createdAt":"2026-11-23T08:32:45.468375Z","updatedAt":"2026-11-23T08:32:45.468375Z"}],"page":{"limit":1,"nextCursor":null}}
```

The second answer ends with `"nextCursor":null`: that was the last page. A made-up cursor is a client error:

```text
tasksteams-api> python scripts/call.py GET "/v1/projects/9a000000-0000-4000-8000-000000000001/tasks?cursor=abc" --user bob
```

```text
HTTP/1.1 400 Bad Request
date: Mon, 23 Nov 2026 08:33:42 GMT
server: uvicorn
content-length: 240
content-type: application/problem+json
x-trace-id: f06d67950a414bd6a3978d378fb76109

{"type":"https://code101.example/problems/bad-request","title":"Bad request","status":400,"detail":"The cursor is not valid.","instance":"/v1/projects/9a000000-0000-4000-8000-000000000001/tasks","traceId":"f06d67950a414bd6a3978d378fb76109"}
```

**4. Filtering and sorting.** Repeat a parameter to match several values:

```text
tasksteams-api> python scripts/call.py GET "/v1/projects/9a000000-0000-4000-8000-000000000001/tasks?status=todo&status=blocked" --user bob
```

```text
HTTP/1.1 200 OK
date: Mon, 23 Nov 2026 08:33:41 GMT
server: uvicorn
content-length: 927
content-type: application/json
x-trace-id: 4d5beee0111a4cfdab53cbc67428da71

{"items":[{"id":"7a500000-0000-4000-8000-000000000005","projectId":"9a000000-0000-4000-8000-000000000001","title":"Add rate limiting","description":"RateLimit headers and 429 responses.","status":"blocked","priority":"medium","assigneeId":"b0b00000-0000-4000-8000-000000000002","dueDate":null,"completedAt":null,"createdBy":"a11ce000-0000-4000-8000-000000000001","version":1,"createdAt":"2026-11-23T08:32:45.480400Z","updatedAt":"2026-11-23T08:32:45.480400Z"},{"id":"7a500000-0000-4000-8000-000000000004","projectId":"9a000000-0000-4000-8000-000000000001","title":"Run the conformance script","description":"All checks green on every backend.","status":"todo","priority":"medium","assigneeId":null,"dueDate":"2027-02-19","completedAt":null,"createdBy":"b0b00000-0000-4000-8000-000000000002","version":1,"createdAt":"2026-11-23T08:32:45.480400Z","updatedAt":"2026-11-23T08:32:45.480400Z"}],"page":{"limit":25,"nextCursor":null}}
```

Sort by due date, two per page (the first page ends in a cursor, the second continues after it):

```text
HTTP/1.1 200 OK
date: Mon, 23 Nov 2026 08:33:41 GMT
server: uvicorn
content-length: 1073
content-type: application/json
x-trace-id: 7eba664db0e94efeae6a5933ef949300

{"items":[{"id":"7a500000-0000-4000-8000-000000000001","projectId":"9a000000-0000-4000-8000-000000000001","title":"Write the OpenAPI contract","description":"Every endpoint and schema.","status":"done","priority":"high","assigneeId":"a11ce000-0000-4000-8000-000000000001","dueDate":"2027-01-15","completedAt":"2026-11-23T08:32:45.480400Z","createdBy":"a11ce000-0000-4000-8000-000000000001","version":1,"createdAt":"2026-11-23T08:32:45.480400Z","updatedAt":"2026-11-23T08:32:45.480400Z"},{"id":"7a500000-0000-4000-8000-000000000002","projectId":"9a000000-0000-4000-8000-000000000001","title":"Design the database","description":"Tables, indexes, stored procedures.","status":"done","priority":"high","assigneeId":"b0b00000-0000-4000-8000-000000000002","dueDate":"2027-01-22","completedAt":"2026-11-23T08:32:45.480400Z","createdBy":"a11ce000-0000-4000-8000-000000000001","version":1,"createdAt":"2026-11-23T08:32:45.480400Z","updatedAt":"2026-11-23T08:32:45.480400Z"}],"page":{"limit":2,"nextCursor":"WyIyMDI3LTAxLTIyIiwiN2E1MDAwMDAtMDAwMC00MDAwLTgwMDAtMDAwMDAwMDAwMDAyIl0"}}
```

```text
HTTP/1.1 200 OK
date: Mon, 23 Nov 2026 08:33:42 GMT
server: uvicorn
content-length: 1004
content-type: application/json
x-trace-id: 19d8f571833444d7a9c94816cc8ef8a1

{"items":[{"id":"7a500000-0000-4000-8000-000000000003","projectId":"9a000000-0000-4000-8000-000000000001","title":"Configure Keycloak","description":"Realm, clients, roles and users.","status":"in_progress","priority":"urgent","assigneeId":"ca401000-0000-4000-8000-000000000003","dueDate":"2027-02-05","completedAt":null,"createdBy":"a11ce000-0000-4000-8000-000000000001","version":1,"createdAt":"2026-11-23T08:32:45.480400Z","updatedAt":"2026-11-23T08:32:45.480400Z"},{"id":"7a500000-0000-4000-8000-000000000004","projectId":"9a000000-0000-4000-8000-000000000001","title":"Run the conformance script","description":"All checks green on every backend.","status":"todo","priority":"medium","assigneeId":null,"dueDate":"2027-02-19","completedAt":null,"createdBy":"b0b00000-0000-4000-8000-000000000002","version":1,"createdAt":"2026-11-23T08:32:45.480400Z","updatedAt":"2026-11-23T08:32:45.480400Z"}],"page":{"limit":2,"nextCursor":"WyIyMDI3LTAyLTE5IiwiN2E1MDAwMDAtMDAwMC00MDAwLTgwMDAtMDAwMDAwMDAwMDA0Il0"}}
```

**5. Idempotency.** Send the same create twice with one `Idempotency-Key`:

```text
tasksteams-api> python scripts/call.py POST /v1/projects/9a000000-0000-4000-8000-000000000001/tasks --user bob --body requests/task-create.json --idempotency-key demo-key-0001
```

```text
HTTP/1.1 201 Created
date: Mon, 23 Nov 2026 08:33:42 GMT
server: uvicorn
location: http://localhost:8000/v1/tasks/e8787266-112f-4a3c-a9b1-9e2bea4b62ec
etag: "1"
content-length: 388
content-type: application/json
x-trace-id: 82ede733460f4f53b12f3f4de7a883ab

{"id":"e8787266-112f-4a3c-a9b1-9e2bea4b62ec","projectId":"9a000000-0000-4000-8000-000000000001","title":"Review the OpenAPI file","description":"","status":"todo","priority":"high","assigneeId":null,"dueDate":"2027-03-15","completedAt":null,"createdBy":"b0b00000-0000-4000-8000-000000000002","version":1,"createdAt":"2026-11-23T08:33:42.843808Z","updatedAt":"2026-11-23T08:33:42.843808Z"}
```

The second identical call returns the **same task**, marked as a replay (the body's members are in a different order because Postgres stores `jsonb`, which does not keep key order; the content is identical):

```text
HTTP/1.1 201 Created
date: Mon, 23 Nov 2026 08:33:42 GMT
server: uvicorn
location: http://localhost:8000/v1/tasks/e8787266-112f-4a3c-a9b1-9e2bea4b62ec
etag: "1"
idempotent-replayed: true
content-length: 388
content-type: application/json
x-trace-id: 5710b1901bba4716a58a70c730dd5804

{"id":"e8787266-112f-4a3c-a9b1-9e2bea4b62ec","title":"Review the OpenAPI file","status":"todo","dueDate":"2027-03-15","version":1,"priority":"high","createdAt":"2026-11-23T08:33:42.843808Z","createdBy":"b0b00000-0000-4000-8000-000000000002","projectId":"9a000000-0000-4000-8000-000000000001","updatedAt":"2026-11-23T08:33:42.843808Z","assigneeId":null,"completedAt":null,"description":""}
```

The same key with a different body is refused:

```text
tasksteams-api> python scripts/call.py POST /v1/projects/9a000000-0000-4000-8000-000000000001/tasks --user bob --body requests/task-create-other.json --idempotency-key demo-key-0001
```

```text
HTTP/1.1 422 Unprocessable Content
date: Mon, 23 Nov 2026 08:33:42 GMT
server: uvicorn
content-length: 290
content-type: application/problem+json
x-trace-id: b864006b207d4518b0b0130ab2d6f193

{"type":"https://code101.example/problems/validation-error","title":"Validation failed","status":422,"detail":"This Idempotency-Key was already used with a different request.","instance":"/v1/projects/9a000000-0000-4000-8000-000000000001/tasks","traceId":"b864006b207d4518b0b0130ab2d6f193"}
```

**6. ETag, If-None-Match and If-Match.** Read the task (use your own task id):

```text
tasksteams-api> python scripts/call.py GET /v1/tasks/<task id> --user bob
```

```text
HTTP/1.1 200 OK
date: Mon, 23 Nov 2026 08:33:42 GMT
server: uvicorn
etag: "1"
content-length: 388
content-type: application/json
x-trace-id: e70240abc4234fc4ae2942d3396ae072

{"id":"e8787266-112f-4a3c-a9b1-9e2bea4b62ec","projectId":"9a000000-0000-4000-8000-000000000001","title":"Review the OpenAPI file","description":"","status":"todo","priority":"high","assigneeId":null,"dueDate":"2027-03-15","completedAt":null,"createdBy":"b0b00000-0000-4000-8000-000000000002","version":1,"createdAt":"2026-11-23T08:33:42.843808Z","updatedAt":"2026-11-23T08:33:42.843808Z"}
```

Ask again with the ETag you hold. The answer has no body:

```text
tasksteams-api> python scripts/call.py GET /v1/tasks/<task id> --user bob --if-none-match 1
```

```text
HTTP/1.1 304 Not Modified
date: Mon, 23 Nov 2026 08:33:43 GMT
server: uvicorn
etag: "1"
x-trace-id: b48ca25d786343f3a3661ae33f2419c4
```

Change the task. No `If-Match` header is 428, a malformed one is 400, an outdated one is 412, and the right one is 200 with the new ETag:

```text
tasksteams-api> python scripts/call.py PATCH /v1/tasks/<task id> --user bob --body requests/task-patch.json
```

```text
HTTP/1.1 428 Precondition Required
date: Mon, 23 Nov 2026 08:33:43 GMT
server: uvicorn
content-length: 302
content-type: application/problem+json
x-trace-id: 261b32fd7ae540589b0f62123556c613

{"type":"https://code101.example/problems/precondition-required","title":"Precondition required","status":428,"detail":"The If-Match header is required. Read the resource first and send its ETag.","instance":"/v1/tasks/e8787266-112f-4a3c-a9b1-9e2bea4b62ec","traceId":"261b32fd7ae540589b0f62123556c613"}
```

```text
HTTP/1.1 400 Bad Request
date: Mon, 23 Nov 2026 08:33:43 GMT
server: uvicorn
content-length: 254
content-type: application/problem+json
x-trace-id: a13b14be521d497bad78326fc1a9921d

{"type":"https://code101.example/problems/bad-request","title":"Bad request","status":400,"detail":"If-Match must be one strong ETag such as \"3\".","instance":"/v1/tasks/e8787266-112f-4a3c-a9b1-9e2bea4b62ec","traceId":"a13b14be521d497bad78326fc1a9921d"}
```

```text
tasksteams-api> python scripts/call.py PATCH /v1/tasks/<task id> --user bob --body requests/task-patch.json --if-match 7
```

```text
HTTP/1.1 412 Precondition Failed
date: Mon, 23 Nov 2026 08:33:43 GMT
server: uvicorn
content-length: 278
content-type: application/problem+json
x-trace-id: bc8ca91c5bff4cb396b77f67e2f0da76

{"type":"https://code101.example/problems/precondition-failed","title":"Precondition failed","status":412,"detail":"The task changed since you read it (current version 1).","instance":"/v1/tasks/e8787266-112f-4a3c-a9b1-9e2bea4b62ec","traceId":"bc8ca91c5bff4cb396b77f67e2f0da76"}
```

```text
tasksteams-api> python scripts/call.py PATCH /v1/tasks/<task id> --user bob --body requests/task-patch.json --if-match 1
```

```text
HTTP/1.1 200 OK
date: Mon, 23 Nov 2026 08:33:43 GMT
server: uvicorn
etag: "2"
content-length: 395
content-type: application/json
x-trace-id: 1bd6ed1e0b764c70b5ff646e0187240a

{"id":"e8787266-112f-4a3c-a9b1-9e2bea4b62ec","projectId":"9a000000-0000-4000-8000-000000000001","title":"Review the OpenAPI file","description":"","status":"in_progress","priority":"high","assigneeId":null,"dueDate":"2027-03-15","completedAt":null,"createdBy":"b0b00000-0000-4000-8000-000000000002","version":2,"createdAt":"2026-11-23T08:33:42.843808Z","updatedAt":"2026-11-23T08:33:44.251622Z"}
```

**7. Rules that live in the database.** A cancelled task cannot be completed (the text comes from the stored function):

```text
HTTP/1.1 409 Conflict
date: Mon, 23 Nov 2026 08:33:44 GMT
server: uvicorn
content-length: 246
content-type: application/problem+json
x-trace-id: 4c68cb19bb8d40ef94e1ce6a6b244fcb

{"type":"https://code101.example/problems/conflict","title":"Conflict","status":409,"detail":"a cancelled task cannot be completed","instance":"/v1/tasks/1288943f-6b79-40c0-a233-c6bedb1331c4/complete","traceId":"4c68cb19bb8d40ef94e1ce6a6b244fcb"}
```

Carol, lead of the Mobile Team, reassigns a Mobile task to alice, who is not a member of that team:

```text
tasksteams-api> python scripts/call.py POST /v1/tasks/7a500000-0000-4000-8000-000000000007/reassign --user carol --body requests/reassign-outsider.json --if-match 1
```

```text
HTTP/1.1 422 Unprocessable Content
date: Mon, 23 Nov 2026 08:33:44 GMT
server: uvicorn
content-length: 304
content-type: application/problem+json
x-trace-id: c2a84af4c4664785b2dcfd4c48fa66f8

{"type":"https://code101.example/problems/validation-error","title":"Validation failed","status":422,"detail":"user a11ce000-0000-4000-8000-000000000001 is not a member of the project team","instance":"/v1/tasks/7a500000-0000-4000-8000-000000000007/reassign","traceId":"c2a84af4c4664785b2dcfd4c48fa66f8"}
```

**8. Who may see and change what.** Alice (an admin) creates a team led by carol; bob is not in it and gets **404**, as if it did not exist:

```text
tasksteams-api> python scripts/call.py POST /v1/teams --user alice --body requests/team-secret.json
```

```text
HTTP/1.1 201 Created
date: Mon, 23 Nov 2026 08:33:44 GMT
server: uvicorn
location: http://localhost:8000/v1/teams/b10d9536-252b-4704-89f3-d088e9539b50
etag: "1"
content-length: 285
content-type: application/json
x-trace-id: a8168240a31c47b3a2b75a96b0403705

{"id":"b10d9536-252b-4704-89f3-d088e9539b50","name":"Secret Team","description":"Only carol and alice may see this team.","memberCount":1,"createdBy":"a11ce000-0000-4000-8000-000000000001","version":1,"createdAt":"2026-11-23T08:33:45.186209Z","updatedAt":"2026-11-23T08:33:45.186209Z"}
```

```text
HTTP/1.1 404 Not Found
date: Mon, 23 Nov 2026 08:33:44 GMT
server: uvicorn
content-length: 226
content-type: application/problem+json
x-trace-id: bf0f202af075467fb428642436a3460b

{"type":"https://code101.example/problems/not-found","title":"Not found","status":404,"detail":"The team was not found.","instance":"/v1/teams/b10d9536-252b-4704-89f3-d088e9539b50","traceId":"bf0f202af075467fb428642436a3460b"}
```

Bob knows the Platform Team exists but is no lead, so changing it is **403**:

```text
tasksteams-api> python scripts/call.py PATCH /v1/teams/7ea00000-0000-4000-8000-000000000001 --user bob --body requests/team-patch.json --if-match 1
```

```text
HTTP/1.1 403 Forbidden
date: Mon, 23 Nov 2026 08:33:44 GMT
server: uvicorn
content-length: 252
content-type: application/problem+json
x-trace-id: 764ae0e39c8b48e6a9522a248a0940dc

{"type":"https://code101.example/problems/forbidden","title":"Forbidden","status":403,"detail":"Only a team lead or an admin may change the team.","instance":"/v1/teams/7ea00000-0000-4000-8000-000000000001","traceId":"764ae0e39c8b48e6a9522a248a0940dc"}
```

**9. The audit trail** names the caller, because every write transaction began with `set_config`:

```text
tasksteams-api> python scripts/call.py GET "/v1/audit-log?entityType=task&limit=2" --user alice
```

```text
HTTP/1.1 200 OK
date: Mon, 23 Nov 2026 08:33:45 GMT
server: uvicorn
content-length: 914
content-type: application/json
x-trace-id: e87a5ce7a09444c4987af693f28dd740

{"items":[{"id":25,"occurredAt":"2026-11-23T08:33:44.623354Z","actorId":"b0b00000-0000-4000-8000-000000000002","action":"update","entityType":"task","entityId":"1288943f-6b79-40c0-a233-c6bedb1331c4","details":{"status":"cancelled"}},{"id":24,"occurredAt":"2026-11-23T08:33:44.432995Z","actorId":"b0b00000-0000-4000-8000-000000000002","action":"create","entityType":"task","entityId":"1288943f-6b79-40c0-a233-c6bedb1331c4","details":{"id":"1288943f-6b79-40c0-a233-c6bedb1331c4","title":"A different task","status":"todo","version":1,"due_date":null,"priority":"medium","created_at":"2026-11-23T08:33:44.432995+00:00","created_by":"b0b00000-0000-4000-8000-000000000002","project_id":"9a000000-0000-4000-8000-000000000001","updated_at":"2026-11-23T08:33:44.432995+00:00","assignee_id":null,"description":"","completed_at":null}}],"page":{"limit":2,"nextCursor":"WyIyMDI2LTExLTIzVDA4OjMzOjQ0LjQzMjk5NSswMDowMCIsMjRd"}}
```

**10. Without a token**

```text
tasksteams-api> python scripts/call.py GET /v1/me
```

```text
HTTP/1.1 401 Unauthorized
date: Mon, 23 Nov 2026 08:33:45 GMT
server: uvicorn
www-authenticate: Bearer realm="tasksteams"
content-length: 203
content-type: application/problem+json
x-trace-id: 237db9331f20493f8fbab7bd34c5797a

{"type":"https://code101.example/problems/unauthorized","title":"Unauthorized","status":401,"detail":"A bearer access token is required.","instance":"/v1/me","traceId":"237db9331f20493f8fbab7bd34c5797a"}
```

**11. The conformance script** from the platform checks all of this in one run:

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
PASS  create team (201, Location and ETag set, team f58195cd-5da7-4f16-9262-ec87d2d09cfb)
PASS  create project (201, project 88442d30-a3bb-4d61-af84-1d541b9d2d7d)
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

17 passed, 1 failed, as announced: `me` needs the `RateLimit-*` headers of chapter 05. Stop the API with Ctrl+C. Leave Docker running for chapter 03, or stop it with `docker compose down -v`.

## How it works
**One write, step by step** (task `PATCH`):

```mermaid
sequenceDiagram
    autonumber
    participant C as Client
    participant R as router update_task
    participant A as access.py
    participant D as Postgres
    C->>R: PATCH /v1/tasks/ID with If-Match
    R->>R: parse_if_match (428 or 400)
    R->>D: BEGIN, set_config app.current_user_id
    R->>A: task_access (404 or 403)
    A->>D: SELECT task, team membership
    R->>D: SELECT version FOR UPDATE (412 if stale)
    R->>D: UPDATE changed columns
    D->>D: triggers: version+1, updated_at, audit row
    R->>D: SELECT the task again, COMMIT
    R-->>C: 200 with the new ETag
```

The version number is the whole ETag mechanism: the trigger `bump_version` raises it on every real change, the API prints it quoted, and the lock plus the comparison stop two writers from silently overwriting each other (the **lost update** problem).

New terms: **repository** (a module that holds the SQL of one kind of data); **bound parameter** (a value sent beside the SQL text, never inside it); **keyset pagination** (continue after the last row seen instead of skipping N rows); **optimistic concurrency** (assume no conflict, detect it at write time with a version); **idempotent** (doing it twice has the effect of doing it once); **SQLSTATE** (the five-character error code of Postgres); **stored function** (a function that lives in the database).

Why this, not that:

| Choice | Alternative | Why we chose this |
|--------|-------------|-------------------|
| Keyset cursors | `OFFSET` and `LIMIT` | A page starting at row 10,000 with OFFSET reads and throws away 10,000 rows, and a row inserted meanwhile shifts every page. Keyset reads only what it returns and stays stable; the cost is no jump to page 40 |
| `FOR UPDATE` plus a version check | Retry loops, or `UPDATE ... WHERE version = :v` and look at the row count | The lock gives a precise 412 with the current version in the message, and the rule is one pattern for three tables |
| Idempotency key stored in the same transaction | A cache with a time to live | No window in which a crash leaves a created resource without its key; the database's unique index serializes duplicates for free |
| Rules in stored functions | Rules in Python | The same rule for four backends in four languages; the price is that changing it means a database migration |
| SQLAlchemy Core with `text()` | The ORM | The SQL is visible and reviewable and maps one-to-one to the functions of the schema; there is no object graph to keep in step |
| Team access checked in the application | Postgres row-level security | RLS would also protect against our own bugs, but it needs one database role per user or a session setting for every query; we keep the rule in one readable module (`access.py`) and mention RLS as a hardening option |

## Try it
Exercise: **write the cursor yourself.** Copy `exercise/starter/cursor.py` into a folder of your own and finish `encode_cursor` and `decode_cursor`. `encode_cursor` turns a list into compact JSON (`separators=(",", ":")`), encodes it as base64url and removes the `=` padding. `decode_cursor` reverses it and raises `ValueError` for text that is not base64, not JSON or not a list. Run `python cursor.py`. The output must show a round trip and reject both `abc` and `e30`.

**File: `exercise/starter/cursor.py`**
```python
"""Exercise 2: an opaque cursor.

A cursor is the position of the last row of a page, hidden inside one string so clients cannot build it.
Finish both functions. Run:  python cursor.py
"""
import base64
import json


def encode_cursor(values):
    # TODO 1: turn the list into compact JSON text (separators=(",", ":")), encode it with
    # base64.urlsafe_b64encode, remove the "=" padding at the end and return the result as a str
    raise NotImplementedError


def decode_cursor(cursor):
    # TODO 2: undo encode_cursor (put the padding back first). Raise ValueError when the text is
    # not valid base64, not valid JSON, or not a JSON list
    raise NotImplementedError


if __name__ == "__main__":
    cursor = encode_cursor(["2026-11-23T08:00:00+00:00", "a11ce000-0000-4000-8000-000000000001"])
    print("cursor:", cursor)
    print("round trip:", decode_cursor(cursor))
    for bad in ("abc", "e30"):  # "e30" is the base64url text of {}
        try:
            decode_cursor(bad)
        except ValueError:
            print("rejected:", bad)
```

<details><summary>Solution</summary>

**File: `exercise/solution/cursor.py`**
```python
"""Exercise 2: an opaque cursor (solution).

Run:  python cursor.py
"""
import base64
import json


def encode_cursor(values):
    raw = json.dumps(values, separators=(",", ":"))
    return base64.urlsafe_b64encode(raw.encode()).rstrip(b"=").decode()


def decode_cursor(cursor):
    values = json.loads(base64.urlsafe_b64decode(cursor + "=" * (-len(cursor) % 4)))
    if not isinstance(values, list):
        raise ValueError("a cursor holds a list")
    return values


if __name__ == "__main__":
    cursor = encode_cursor(["2026-11-23T08:00:00+00:00", "a11ce000-0000-4000-8000-000000000001"])
    print("cursor:", cursor)
    print("round trip:", decode_cursor(cursor))
    for bad in ("abc", "e30"):  # "e30" is the base64url text of {}
        try:
            decode_cursor(bad)
        except ValueError:
            print("rejected:", bad)
```

`urlsafe_b64decode` needs the padding that `rstrip(b"=")` removed, which `"=" * (-len(cursor) % 4)` puts back. Every failure mode (bad base64, bad JSON, wrong type, bad UTF-8) is a `ValueError` or a subclass of it, so one `except ValueError` in the caller is enough. Expected output:

```text
cursor: WyIyMDI2LTExLTIzVDA4OjAwOjAwKzAwOjAwIiwiYTExY2UwMDAtMDAwMC00MDAwLTgwMDAtMDAwMDAwMDAwMDAxIl0
round trip: ['2026-11-23T08:00:00+00:00', 'a11ce000-0000-4000-8000-000000000001']
rejected: abc
rejected: e30
```

</details>

## Check yourself
1. Why does the API answer 404 and not 403 when bob asks for a team he does not belong to? <details><summary>Answer</summary>A 403 would confirm that the team exists. With 404 for both "unknown" and "not yours", ids cannot be probed (object level authorization, OWASP API1). 403 is for objects the caller may already see.</details>
2. What exactly protects `PATCH` from a lost update? <details><summary>Answer</summary>The client sends the version it read in `If-Match`; the server locks the row with `FOR UPDATE` and compares. Two writers cannot both succeed with the same version, the second gets 412 and must read again.</details>
3. A client sends the same create twice with one idempotency key and the second request arrives while the first is still running. What happens? <details><summary>Answer</summary>The second INSERT into `idempotency_keys` waits on the unique index until the first transaction commits, then conflicts and replays the stored response. Nothing is created twice.</details>
4. Why are table names formatted into SQL in `lock_and_check` but values never? <details><summary>Answer</summary>Identifiers cannot be bound parameters, so they must be written into the text. They are always literals chosen by our code, never request data. Values come from requests and are always bound.</details>
5. Why is `read_claims` dangerous, and what stays when we replace it? <details><summary>Answer</summary>Anyone can write a token with any claims; without a signature check the API believes them (chapter 03 demonstrates it). The `Principal`, scopes, roles and team checks stay, because they only consume claims.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `pydantic_core._pydantic_core.ValidationError: 1 validation error for Settings` then `database_url` and `Field required [type=missing, input_value={}, input_type=dict]` | `DATABASE_URL` is not set: there is no `.env`, or you started Uvicorn in another folder | Copy `.env.example` to `.env` in the project folder and start Uvicorn there |
| The API answers 503 `The database is not available.` (and `/health` answers 503 with `"database":"down"`) | Postgres is not running or not healthy | `docker compose ps`, then `docker compose up -d --wait`. The log line says `database unavailable: ConnectionTimeout` |
| `412` with `The task changed since you read it (current version 1).` | Your `If-Match` is older than the stored version: someone changed the task, or you typed the wrong number | Read the task again (`GET`), copy the new ETag |
| `400` with `If-Match must be one strong ETag such as "3".` | The header has no quotes (`If-Match: 1`), is weak (`W/"1"`) or is `*` | Send the quoted version; `--if-match 1` of `scripts/call.py` adds the quotes |
| `422` with `This Idempotency-Key was already used with a different request.` | The same key was used for another body or URL | Use a new key for a new request, the same key only for a retry of the same request |
| The seed data you edited in `db/seed.sql` does not show up | The schema and seed run only on an empty volume | `docker compose down -v`, then `docker compose up -d --wait` |
| `404` for a team you can see in the database | The token's user is not a member and not an admin (404 hides existence) | Use a member's token, or alice, or add the membership with `PUT /v1/teams/{id}/members/{userId}` |

## Best practice
Authorize on the server for every object, check scope and role and membership together, and keep the rules that must be identical everywhere (version checks, atomic changes) in one place. Source: OWASP API Security Top 10 2023, API1 Broken Object Level Authorization https://owasp.org/API-Security/editions/2023/en/0x11-t10/ and PostgreSQL 17 documentation, Explicit Locking https://www.postgresql.org/docs/17/explicit-locking.html

## Next lesson
03. Identity: replace the stand-in `read_claims` with real validation of the Keycloak token (signature from the cached JWKS, issuer, audience, expiry), show that a forged token is rejected, and test every token rule offline.
