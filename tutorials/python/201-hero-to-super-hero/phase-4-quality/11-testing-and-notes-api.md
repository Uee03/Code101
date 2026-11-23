---
track: python
level: 201
phase: 4
phase_name: quality
lesson: '11'
title: "Testing with pytest and a small notes API"
time: "180 min"
prerequisites: [201.3.10]
versions: { python: "3.12", dependencies: "exact direct pins in source manifests" }
verified: not yet run
source: source/python/201-hero-to-super-hero/phase-4-quality/11-testing-and-notes-api/
assets: []
---

# 11. Testing with pytest and a small notes API

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Build isolated pytest fixtures and parametrized API contract tests.
- Combine validated DTOs, SQLAlchemy persistence and owner-scoped bearer access.
- Package a loopback-only notes API with complete, explainable container configuration.
- Distinguish fast SQLite application tests from PostgreSQL, identity and deployment verification.

## Recap
1. What must a route still check after JWT validation?
   <details><summary>Answer</summary>Resource authorization: a valid identity does not grant access to another subject's records.</details>
2. What does `session.begin()` own in lesson 09?
   <details><summary>Answer</summary>The transaction: commit on success, rollback on failure. Closing a session alone is not a request to commit.</details>
3. Why did lesson 08 use an explicit response model?
   <details><summary>Answer</summary>To validate/filter public output independently of internal stored attributes.</details>

## Why it matters
A green happy-path test can coexist with a serious ownership bug. Useful tests separate data setup from behavior and exercise negative boundaries deliberately. The application below is small enough to understand end to end while exposing the important differences between unit, application-integration and deployment checks.

## What you will build
A create/list/read notes API: validated titles, database-owned IDs, authenticated owners, filtered DTOs, PostgreSQL persistence and a nonroot container. Tests use disposable file-backed SQLite and fresh app instances; they never require your private dotenv file. There is no registration, password grant, refresh token, team model or full-stack UI. Use [capstones/backend-python](https://github.com/Uee03/Code101/tree/main/capstones/backend-python) for the full Keycloak-backed application rather than expanding this mini-project into a duplicate.

## Before you start
- **Prerequisites:** [Python 201 lesson 10, authentication basics](../phase-3-apis-and-data/10-authentication-basics.md).
- Time: 180 min, including typing, reasoning and the exercise.
- Python **3.12** installed using the setup from Python 101 lesson 01; a code editor and terminal from that track. Windows commands select it with `py -3.12`; macOS/Linux commands use `python3.12`. If necessary, Windows install-manager users can run `py install 3.12` from any folder, then reopen the terminal. Other platforms: [official Python setup](https://docs.python.org/3.12/using/index.html). Do not point the dependency snapshots at an arbitrary newer interpreter and assume compatibility.
- Source pack (optional): every new file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the course repository https://github.com/Uee03/Code101 under `source/python/201-hero-to-super-hero/phase-4-quality/11-testing-and-notes-api/` (on that page choose **Code, Download ZIP**, or run `git clone https://github.com/Uee03/Code101.git`).
- Extract ZIPs before using them: Windows **Extract All > Extract**; macOS double-click; Linux use your archive manager's **Extract**. A repository ZIP contains `Code101-main` followed by the source path above. Phase ZIPs contain this lesson's `code` and `exercise` folders. Work in a copy, not inside the ZIP.
- Third-party versions below are teaching snapshots, **not a claim of current security support**. Direct requirements are pinned, transitive dependencies are not locked; review supported releases and resolve a lock before deployment. All output below is unrun.

Finish lessons 08-10. Docker prerequisites are exactly those in lesson 09. Three sittings are realistic: pause **before Step 5** (tests) and **before Step 9** (containers). Port 8011 is the local API; 5543 is this lab's host-side PostgreSQL port. It is a different database/project from lesson 09, not a migration of that schema. Use synthetic notes only. All Docker commands below are learner instructions, not evidence that containers have already been built or started.

## Steps
### Step 1. Create a fresh mini-project workspace
Open **Terminal > New Terminal** in VS Code. The path before `>` or `$` is the current folder. From anywhere:

**PowerShell - folder: anywhere**
```powershell
New-Item -ItemType Directory -Path "$HOME/code101/python201/lesson11" -Force | Out-Null
Set-Location "$HOME/code101/python201/lesson11"
code .
```

**macOS/Linux - folder: anywhere**
```bash
mkdir -p ~/code101/python201/lesson11
cd ~/code101/python201/lesson11
code .
```
Expected result, not yet run: the folder exists and the editor opens it. If `code` is unavailable, choose **File > Open Folder** instead. In that window open a new terminal; it must show this lesson folder. If asked, trust your own folder.

For every file below use **Explorer > New File** (create named subfolders first), enter the exact filename, paste/type its complete content and save. **Ctrl+S**, or **Cmd+S** on macOS, removes the unsaved dot on the tab. Enable filename extensions in your file manager so `.py` does not become `.py.txt`. Paths below are relative to this lesson folder. If lost, `cd ~/code101/python201/lesson11` returns here on all three platforms.

### Step 2. Separate runtime and test dependencies
**File: `~/code101/python201/lesson11/requirements.txt`**
```text
fastapi==0.115.12
pydantic==2.11.3
pydantic-settings==2.8.1
uvicorn==0.34.2
SQLAlchemy==2.0.40
psycopg[binary]==3.2.6
PyJWT==2.10.1
pwdlib[argon2]==0.2.1
```
**File: `~/code101/python201/lesson11/requirements-dev.txt`**
```text
-r requirements.txt
httpx==0.28.1
pytest==8.3.5
```
The dev file first includes runtime requirements, then adds HTTPX for `TestClient` and pytest for test discovery/assertions. Runtime image installation will use only the first file. `pwdlib` remains with the shared lesson-10 security module; this API has no public password-handling endpoint.
Use the requirements file above in an isolated environment. No activation is needed, so PowerShell's Restricted script policy cannot block these commands.

**PowerShell - folder: `~/code101/python201/lesson11`**
```powershell
py -3.12 -m venv .venv
& ./.venv/Scripts/python.exe -m pip install -r requirements-dev.txt
```

**macOS/Linux - folder: `~/code101/python201/lesson11`**
```bash
python3.12 -m venv .venv
.venv/bin/python -m pip install -r requirements-dev.txt
```
Expected result, not yet run: `.venv` is created and the requirements install successfully. Package download lines and resolved transitive versions vary; no installer transcript is claimed. If installation fails, stop and read the first error rather than proceeding with a partially prepared environment. The Python 101 virtual-environment lesson covers a missing `venv` component. Always use this lesson's interpreter, not a global `pip`.

**File: `~/code101/python201/lesson11/pyproject.toml`**
```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-ra"
```
The first line names pytest's TOML section. `testpaths` restricts default collection to `tests`; it prevents the exercise copy from being collected with the main project. `addopts="-ra"` adds a short report for nonpassing outcomes. These are test-runner options, not build-system metadata; a Python file using a pyproject config is not automatically an installable package.

### Step 3. Define settings, entities and the token boundary
**File: `~/code101/python201/lesson11/settings.py`**
```python
from pydantic import SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="NOTES_", env_file=".env", extra="ignore")
    database_url: SecretStr
    jwt_secret: SecretStr

    @field_validator("jwt_secret")
    @classmethod
    def require_generated_secret(cls, value: SecretStr) -> SecretStr:
        secret = value.get_secret_value()
        if len(secret) < 32 or secret.startswith("replace-"):
            raise ValueError("generate a private JWT secret of at least 32 characters")
        return value
```
The environment prefix selects `NOTES_DATABASE_URL` and `NOTES_JWT_SECRET`. Both are required, with secret representations because a database URL contains a password. We intentionally use `extra="ignore"` for this shared dotenv file: Compose also needs `POSTGRES_PASSWORD`, which is not an application field. Unlike lesson 07's focused file, unrelated dotenv entries are allowed. A misspelled required key still leaves a required value missing and fails. The secret validator is unchanged from lesson 10.

**File: `~/code101/python201/lesson11/models.py`**
```python
from sqlalchemy import CheckConstraint, String
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class Note(Base):
    __tablename__ = "notes"
    __table_args__ = (CheckConstraint("length(trim(title)) BETWEEN 1 AND 120"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(120))
    owner: Mapped[str] = mapped_column(String(200), index=True)
```
The model adds `owner` and an owner index. The database constraint rejects space-only/overlength stored titles even outside Pydantic. SQL trim here strips ordinary spaces; the API additionally rejects other whitespace-only text through its broader string constraints. An **index** helps a database find matching rows, with a write/storage cost; this small example does not claim measured performance. The output DTO will omit owner. The production database schema is created by `init.sql`, not by running `create_all` during application startup.

**File: `~/code101/python201/lesson11/security.py`**
```python
from datetime import UTC, datetime, timedelta

import jwt
from jwt.exceptions import InvalidTokenError
from pwdlib import PasswordHash

ISSUER = "python201"
AUDIENCE = "notes-api"
ALGORITHM = "HS256"
password_hash = PasswordHash.recommended()


def issue_token(subject: str, secret: str, *, now: datetime | None = None) -> str:
    if not subject.strip():
        raise ValueError("subject must not be blank")
    issued = now if now is not None else datetime.now(UTC)
    return jwt.encode(
        {"sub": subject, "iss": ISSUER, "aud": AUDIENCE, "exp": issued + timedelta(minutes=5)},
        secret,
        algorithm=ALGORITHM,
    )


def validate_token(token: str, secret: str) -> str:
    claims = jwt.decode(
        token,
        secret,
        algorithms=[ALGORITHM],
        issuer=ISSUER,
        audience=AUDIENCE,
        options={"require": ["exp", "sub", "iss", "aud"]},
    )
    subject = claims["sub"]
    if not isinstance(subject, str) or not subject.strip():
        raise InvalidTokenError("subject must not be blank")
    return subject
```
This is the **identical** security module from lesson 10; there is no new algorithm, claim policy or password grant. Its trust boundary is still a local learning issuer, not production identity.

**File: `~/code101/python201/lesson11/issue.py`**
```python
import argparse

from security import issue_token
from settings import Settings


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Trusted local issuer, not a login endpoint")
    parser.add_argument("subject")
    args = parser.parse_args()
    settings = Settings()
    print(issue_token(args.subject, settings.jwt_secret.get_secret_value()))
```
This is also identical to lesson 10. Only trusted local tooling should have the symmetric signing key. Never expose this script as an unauthenticated route. It will run inside the API container when you explicitly mint a learning token.

### Step 4. Compose the API and own each session
**File: `~/code101/python201/lesson11/app.py`**
```python
from collections.abc import AsyncIterator, Iterator
from contextlib import asynccontextmanager
from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt.exceptions import InvalidTokenError
from pydantic import BaseModel, ConfigDict, StringConstraints
from sqlalchemy import Engine, create_engine, select, text
from sqlalchemy.orm import Session

from models import Note
from security import validate_token
from settings import Settings

Title = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=120)]


class NoteCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    title: Title


class NoteRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    title: str


def create_app(settings: Settings | None = None, engine: Engine | None = None) -> FastAPI:
    config = settings if settings is not None else Settings()
    owns_engine = engine is None
    db = engine if engine is not None else create_engine(
        config.database_url.get_secret_value(), pool_pre_ping=True
    )

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        try:
            yield
        finally:
            if owns_engine:
                db.dispose()

    app = FastAPI(title="Small notes API", lifespan=lifespan)
    bearer = HTTPBearer(auto_error=False)

    def get_session() -> Iterator[Session]:
        with Session(db) as session:
            yield session

    def current_subject(
        credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer)],
    ) -> str:
        if credentials is not None:
            try:
                return validate_token(credentials.credentials, config.jwt_secret.get_secret_value())
            except InvalidTokenError:
                pass
        raise HTTPException(status_code=401, detail="invalid credentials", headers={"WWW-Authenticate": "Bearer"})

    @app.get("/health")
    def health(session: Annotated[Session, Depends(get_session)]) -> dict[str, str]:
        session.execute(text("SELECT 1"))
        return {"status": "ok"}

    @app.post("/notes", response_model=NoteRead, status_code=201)
    def create_note(
        payload: NoteCreate,
        subject: Annotated[str, Depends(current_subject)],
        session: Annotated[Session, Depends(get_session)],
    ) -> NoteRead:
        with session.begin():
            note = Note(title=payload.title, owner=subject)
            session.add(note)
            session.flush()
            result = NoteRead.model_validate(note)
        return result

    @app.get("/notes", response_model=list[NoteRead])
    def list_notes(
        subject: Annotated[str, Depends(current_subject)],
        session: Annotated[Session, Depends(get_session)],
    ) -> list[Note]:
        return list(session.scalars(select(Note).where(Note.owner == subject).order_by(Note.id).limit(100)))

    @app.get("/notes/{note_id}", response_model=NoteRead)
    def read_note(
        note_id: int,
        subject: Annotated[str, Depends(current_subject)],
        session: Annotated[Session, Depends(get_session)],
    ) -> Note:
        note = session.scalar(select(Note).where(Note.id == note_id, Note.owner == subject))
        if note is None:
            raise HTTPException(status_code=404, detail="note not found")
        return note

    return app
```
Follow the seams instead of reading this as one large handler:
- `Title`, `NoteCreate` and `NoteRead` preserve lesson 08's validation and public field filtering. Clients cannot supply `owner`.
- The factory accepts an injected engine/settings for tests. Normal startup constructs one pooled engine from runtime settings. Importing the module does not connect to a real database or create tables.
- A **lifespan** context brackets application startup/shutdown. `asynccontextmanager` is lesson 04's pattern for an async lifetime. The factory disposes only an engine it owns; the fixture owns and closes injected engines.
- `get_session` gives each request its own session and closes it even on failure. Never share a global session between concurrent requests.
- Bearer parsing and token validation are the lesson-10 contract. A failed credential produces 401, not a leaked parser traceback.
- `create_note` derives owner from the validated subject. `flush` sends the insert and gets the generated ID while still inside the transaction. It is **not a commit**. The DTO is materialized before leaving; transaction exit commits before the response returns.
- Both read paths constrain `Note.owner == subject` in the query. A note owned by someone else has the same 404 outcome as a nonexistent note. Hiding an owner field is not enough; the query itself must enforce ownership.
- List output is ordered by ID and capped at 100 notes to avoid an unbounded result. This is a deliberately bounded learning contract, **not pagination**; a production API needs an explicit continuation/pagination contract.
- `/health` performs `SELECT 1` so its success includes database reachability. It exposes no credentials or internal schema details. These synchronous database operations stay in synchronous handlers, not blocking an async event loop body.

### Step 5. Build fresh fixtures instead of shared mutable test state
A **fixture** supplies reusable test setup by name. A **yield fixture** also guarantees teardown after the requesting test. `conftest.py` makes fixtures available to tests in its directory tree without manual imports. `tmp_path` is pytest's unique temporary-folder fixture.

Create `tests`, then the two files below.
**File: `~/code101/python201/lesson11/tests/conftest.py`**
```python
from collections.abc import Iterator
from pathlib import Path
from secrets import token_hex

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, create_engine

from app import create_app
from models import Base
from security import issue_token
from settings import Settings


@pytest.fixture
def secret() -> str:
    return token_hex(32)


@pytest.fixture
def engine(tmp_path: Path) -> Iterator[Engine]:
    db = create_engine(f"sqlite:///{(tmp_path / 'notes.db').as_posix()}")
    Base.metadata.create_all(db)
    try:
        yield db
    finally:
        db.dispose()


@pytest.fixture
def client(engine: Engine, secret: str) -> Iterator[TestClient]:
    config = Settings(database_url="sqlite://", jwt_secret=secret, _env_file=None)
    with TestClient(create_app(config, engine)) as test_client:
        yield test_client


@pytest.fixture
def ada_headers(secret: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {issue_token('ada', secret)}"}


@pytest.fixture
def bob_headers(secret: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {issue_token('bob', secret)}"}
```
Each function-scoped engine gets a separate SQLite file under `tmp_path`. File-backed SQLite avoids the per-connection identity surprises of a bare in-memory database with threaded application requests. SQLAlchemy 2 supports its file-backed SQLite pooling/thread use; do not generalize this into sharing a session between threads. `create_all` is acceptable here because this is a brand-new temporary test database. It is not a production migration. Context-managed TestClient runs lifespan cleanup. The same per-test `secret` fixture signs both test users' tokens, matching a single trusted issuer.

### Step 6. Parametrize boundary cases and test ownership
**Parametrization** runs one test function for several independent input cases. Pytest discovers `test_` functions and rewrites assertions to explain failures; unlike `unittest.TestCase`, these functions use ordinary `assert` statements for developer checks. Required runtime validation still uses exceptions/models, not assertions.

**File: `~/code101/python201/lesson11/tests/test_api.py`**
```python
from datetime import UTC, datetime, timedelta

import jwt
import pytest
from fastapi.testclient import TestClient

from security import AUDIENCE, ISSUER, issue_token


def test_create_read_and_output_filter(client: TestClient, ada_headers: dict[str, str]) -> None:
    response = client.post("/notes", json={"title": " Read docs "}, headers=ada_headers)
    assert response.status_code == 201
    assert response.json() == {"id": 1, "title": "Read docs"}
    assert client.get("/notes/1", headers=ada_headers).json() == response.json()


@pytest.mark.parametrize("title", ["", "   ", "x" * 121])
def test_invalid_title(client: TestClient, ada_headers: dict[str, str], title: str) -> None:
    response = client.post("/notes", json={"title": title}, headers=ada_headers)
    assert response.status_code == 422
    assert client.get("/notes", headers=ada_headers).json() == []


def test_extra_owner_is_rejected(client: TestClient, ada_headers: dict[str, str]) -> None:
    response = client.post("/notes", json={"title": "Read", "owner": "bob"}, headers=ada_headers)
    assert response.status_code == 422


def test_ownership(client: TestClient, ada_headers: dict[str, str], bob_headers: dict[str, str]) -> None:
    client.post("/notes", json={"title": "Ada only"}, headers=ada_headers)
    assert client.get("/notes/1", headers=bob_headers).status_code == 404
    assert client.get("/notes", headers=bob_headers).json() == []
    assert client.get("/notes", headers=ada_headers).json() == [{"id": 1, "title": "Ada only"}]


def test_missing_note(client: TestClient, ada_headers: dict[str, str]) -> None:
    assert client.get("/notes/999", headers=ada_headers).status_code == 404


@pytest.mark.parametrize("headers", [{}, {"Authorization": "Bearer broken"}, {"Authorization": "Basic abc"}])
def test_invalid_bearer(client: TestClient, headers: dict[str, str]) -> None:
    response = client.get("/notes", headers=headers)
    assert response.status_code == 401
    assert response.headers["www-authenticate"] == "Bearer"


def test_expired_bearer(client: TestClient, secret: str) -> None:
    token = issue_token("ada", secret, now=datetime(2000, 1, 1, tzinfo=UTC))
    assert client.get("/notes", headers={"Authorization": f"Bearer {token}"}).status_code == 401


@pytest.mark.parametrize("change", [{"iss": "wrong"}, {"aud": "wrong"}, {"sub": " "}, {"exp": None}])
def test_invalid_claims(client: TestClient, secret: str, change: dict[str, object]) -> None:
    claims = {"sub": "ada", "iss": ISSUER, "aud": AUDIENCE, "exp": datetime.now(UTC) + timedelta(minutes=5)}
    claims.update(change)
    if claims["exp"] is None:
        del claims["exp"]
    token = jwt.encode(claims, secret, algorithm="HS256")
    assert client.get("/notes", headers={"Authorization": f"Bearer {token}"}).status_code == 401


def test_health(client: TestClient) -> None:
    assert client.get("/health").json() == {"status": "ok"}
```
Read tests as contracts: trimming and public shape, invalid inputs causing no insert, rejection of a caller-supplied owner, owner-only reads/listing, not-found behavior, missing/malformed credentials, expired tokens and invalid claims. Every claim test changes one policy field while the other claims remain valid. Fresh function-scoped databases make the first ID predictable and prevent test order from determining correctness.

### Step 7. Add one inspectable application probe
**File: `~/code101/python201/lesson11/probe.py`**
```python
from pathlib import Path
from secrets import token_hex
from tempfile import TemporaryDirectory

from fastapi.testclient import TestClient
from sqlalchemy import create_engine

from app import create_app
from models import Base
from security import issue_token
from settings import Settings


if __name__ == "__main__":
    with TemporaryDirectory() as folder:
        secret = token_hex(32)
        engine = create_engine(f"sqlite:///{(Path(folder) / 'notes.db').as_posix()}")
        Base.metadata.create_all(engine)
        config = Settings(database_url="sqlite://", jwt_secret=secret, _env_file=None)
        try:
            with TestClient(create_app(config, engine)) as client:
                ada = {"Authorization": f"Bearer {issue_token('ada', secret)}"}
                bob = {"Authorization": f"Bearer {issue_token('bob', secret)}"}
                created = client.post("/notes", json={"title": "Read docs"}, headers=ada)
                note_id = created.json()["id"]
                print("create:", created.status_code)
                print("owner:", client.get(f"/notes/{note_id}", headers=ada).status_code)
                print("other owner:", client.get(f"/notes/{note_id}", headers=bob).status_code)
                print("anonymous:", client.get("/notes").status_code)
        finally:
            engine.dispose()
```
This is a small example of the same API flow without test-runner formatting. Its temporary SQLite database is independent of real PostgreSQL and removed after the engine closes. It does not bind a server port. Neither the probe nor the fast tests establishes that Docker networking, the PostgreSQL initialization SQL or production identity works.

### Step 8. Predict before you run
If Bob knows Ada's note ID, which exact query condition denies him access? Will `owner` appear in the response? Why would the ownership test fail if you filtered a list only after first returning a single note without its owner condition?

### Step 9. Write all private configuration and initialization inputs
**File: `~/code101/python201/lesson11/.env.example`**
```dotenv
POSTGRES_PASSWORD=replace-db-password
NOTES_JWT_SECRET=replace-jwt-secret
NOTES_DATABASE_URL=postgresql+psycopg://notes:replace-db-password@127.0.0.1:5543/notes
```
Line 1 supplies Compose's database password placeholder. Line 2 supplies a separate JWT secret placeholder; never reuse database credentials as signing material. Line 3 supplies a host-side SQLAlchemy URL for optional host tools: `127.0.0.1:5543`, not the Docker service name. Changing host port requires changing this URL and the matching Compose mapping. A container-side URL is explicitly supplied by Compose below.

**File: `~/code101/python201/lesson11/configure.py`**
```python
from pathlib import Path
from secrets import token_hex


if __name__ == "__main__":
    content = Path(".env.example").read_text(encoding="utf-8")
    content = content.replace("replace-db-password", token_hex(32))
    content = content.replace("replace-jwt-secret", token_hex(32))
    with Path(".env").open("x", encoding="utf-8") as file:
        file.write(content)
    print("Created .env; keep it private.")
```
One generated database password replaces both occurrences of its placeholder; the JWT key is independently generated. Hex output is URL-safe here, so the template's connection URL needs no extra escaping. Arbitrary real passwords need a URL constructor/encoding, as taught in lesson 09. Exclusive file creation refuses to overwrite an existing `.env`.

**File: `~/code101/python201/lesson11/.gitignore`**
```text
.env
.venv/
__pycache__/
.pytest_cache/
*.db
```
Its lines exclude the private dotenv file, project environment, bytecode caches, pytest cache and local SQLite files, respectively. They do not remove previously committed secrets.

**File: `~/code101/python201/lesson11/init.sql`**
```sql
CREATE TABLE notes (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title varchar(120) NOT NULL CHECK (length(trim(title)) BETWEEN 1 AND 120),
    owner varchar(200) NOT NULL
);
CREATE INDEX ix_notes_owner ON notes (owner);
```
The six lines create the table, generated ID, constrained title and non-null owner, close the table declaration and create the owner index. Initialization runs only on an empty PostgreSQL volume. Use Alembic for evolving real schemas; do not repeatedly delete real data or rely on ORM startup creation.

### Step 10. Write the complete container inputs
**File: `~/code101/python201/lesson11/Dockerfile`**
```dockerfile
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
RUN useradd --create-home --uid 10001 app
COPY --chown=app:app app.py models.py security.py settings.py issue.py ./
USER app
EXPOSE 8000
CMD ["python", "-m", "uvicorn", "app:create_app", "--factory", "--host", "0.0.0.0", "--port", "8000"]
```
Every line in order:
| Line | Explanation and effect of changing it |
|---|---|
| 1 | Uses the Python 3.12 slim base. The tag floats across patches; production pinning needs digest/update management. |
| 2 | Avoids writing bytecode files in the runtime image. |
| 3 | Makes process output unbuffered for container logging. |
| 4 | Makes `/app` the working directory for subsequent instructions and runtime. |
| 5 | Copies runtime requirements before source to reuse the installation layer on code-only edits. |
| 6 | Installs only runtime dependencies without a pip cache; version/security review still matters. |
| 7 | Creates a dedicated nonroot runtime user with UID 10001. |
| 8 | Copies exactly the required application/issuer modules with that user's ownership, not your whole checkout. |
| 9 | Switches subsequent runtime execution to the unprivileged user. |
| 10 | Documents container port 8000; it does not publish a host port. |
| 11 | Exec-form startup runs one Uvicorn factory on all container interfaces; Compose restricts host exposure. No development reloader is used. |

**File: `~/code101/python201/lesson11/.dockerignore`**
```text
.env
.env.*
.venv/
__pycache__/
.pytest_cache/
tests/
exercise/
.git/
```
Line by line, exclude `.env`, dotenv variants (including the public template, which the runtime does not need), the host environment, bytecode caches, pytest cache, tests, exercise copies and Git metadata. Build-context exclusion is defense in depth: the Dockerfile also copies an explicit file list. Never bake real keys into an image with COPY, ARG or ENV.

**File: `~/code101/python201/lesson11/compose.yml`**
```yaml
services:
  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: notes
      POSTGRES_DB: notes
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?generate .env first}
    ports:
      - "127.0.0.1:5543:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/001-notes.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"]
      interval: 2s
      timeout: 3s
      retries: 20
  api:
    build: .
    environment:
      NOTES_DATABASE_URL: postgresql+psycopg://notes:${POSTGRES_PASSWORD:?generate .env first}@db:5432/notes
      NOTES_JWT_SECRET: ${NOTES_JWT_SECRET:?generate .env first}
    ports:
      - "127.0.0.1:8011:8000"
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2).close()"]
      interval: 5s
      timeout: 3s
      retries: 20
volumes:
  pgdata:
```
Every line in order:
| Line | Explanation |
|---|---|
| 1 | Begins services. |
| 2 | Names the PostgreSQL service `db`. |
| 3 | Chooses the PostgreSQL 17 Alpine image. |
| 4 | Starts container environment assignments. |
| 5 | Sets the initialization/login role to `notes`. |
| 6 | Sets the database name to `notes`. |
| 7 | Requires the private database password from local Compose input. |
| 8 | Starts host publishing. |
| 9 | Maps host loopback 5543 to database port 5432, distinct from lesson 09. |
| 10 | Starts database mounts. |
| 11 | Persists data in this project's volume. |
| 12 | Mounts first-start SQL read-only. |
| 13 | Starts the database readiness policy. |
| 14 | Runs `pg_isready`; doubled dollars leave expansion to the container. |
| 15 | Checks every two seconds. |
| 16 | Allows three seconds per check. |
| 17 | Allows twenty failed checks. |
| 18 | Names the application service `api`. |
| 19 | Builds the current directory's Dockerfile and permitted context. |
| 20 | Starts API runtime environment assignments. |
| 21 | Constructs the container-side URL: host `db`, port 5432, and the generated database password. It overrides the host URL in the template. |
| 22 | Supplies the independently generated JWT secret at runtime, never at image build time. |
| 23 | Starts API host publishing. |
| 24 | Maps only host loopback 8011 to container 8000. |
| 25 | Starts dependency ordering. |
| 26 | Selects the database dependency. |
| 27 | Waits for its health check before starting the API; this is startup ordering, not permanent outage recovery. |
| 28 | Starts the API health policy. |
| 29 | Uses Python's standard-library HTTP client inside the container to request `/health`; failure gives a failing check. |
| 30 | Checks every five seconds. |
| 31 | Allows three seconds per check, longer than the client's two-second network timeout. |
| 32 | Allows twenty failed checks. |
| 33 | Declares top-level named volumes. |
| 34 | Defines this project's `pgdata`. |

Compose environment variables are convenient for a loopback lab, not a production secret store. A Docker administrator can inspect runtime configuration. The database initialization user is elevated; use separate least-privilege application roles in a production design. No password, JWT, image build or database startup has been performed for this draft.

## Run it
First inspect the fast application flow; no real database or network service is needed:
**PowerShell - folder: `~/code101/python201/lesson11`**
```powershell
& ./.venv/Scripts/python.exe probe.py
```

**macOS/Linux - folder: `~/code101/python201/lesson11`**
```bash
.venv/bin/python probe.py
```
Expected output, not yet run:
```text
create: 201
owner: 200
other owner: 404
anonymous: 401
```
**PowerShell - folder: `~/code101/python201/lesson11`**
```powershell
& ./.venv/Scripts/python.exe -m pytest -q
```

**macOS/Linux - folder: `~/code101/python201/lesson11`**
```bash
.venv/bin/python -m pytest -q
```
Expected outcome, not yet run: the source defines **16 collected cases** (including parametrized expansions), all intended to pass. Timing, progress formatting, dependency warnings and plugin output are environment-dependent; no captured pytest transcript is invented. A passing count would not prove PostgreSQL or Docker behavior.

For the separate container workflow, generate private runtime configuration once:
**PowerShell - folder: `~/code101/python201/lesson11`**
```powershell
& ./.venv/Scripts/python.exe configure.py
```

**macOS/Linux - folder: `~/code101/python201/lesson11`**
```bash
.venv/bin/python configure.py
```
Expected output, not yet run:
```text
Created .env; keep it private.
```
All following Docker commands work in PowerShell and macOS/Linux terminals from the **lesson11 root**:

**PowerShell or macOS/Linux - folder: `~/code101/python201/lesson11`**
```shell
docker compose -p python201-notes up -d --build --wait
docker compose -p python201-notes ps
docker compose -p python201-notes logs --tail 20 api db
```
Expected results, not yet run: the image builds, PostgreSQL initializes on an empty volume, and both services become healthy. `ps` should report two running healthy services; logs contain actual startup information, not a fixed sequence of timestamps/IDs. If either fails, inspect the real logs and correct the cause before trying requests. Never post logs containing credentials publicly.

Check health using a second terminal or your browser:

**PowerShell - folder: `~/code101/python201/lesson11`**
```powershell
Invoke-RestMethod http://127.0.0.1:8011/health | ConvertTo-Json -Compress
```

**macOS/Linux - folder: `~/code101/python201/lesson11`**
```bash
curl --fail http://127.0.0.1:8011/health
```
Expected JSON content, not yet run (newline formatting may differ):
```json
{"status":"ok"}
```
Mint a trusted **local learning** token using the runtime key inside the API container:

**PowerShell or macOS/Linux - folder: `~/code101/python201/lesson11`**
```shell
docker compose -p python201-notes exec -T api python issue.py ada
```
Expected output, not yet run: one signed five-minute JWT. It depends on time/private key and is not fabricated here. This CLI bypasses any password login on purpose: possession of the issuer key is privileged. Do not deploy it as a public issuer endpoint.

Open `http://127.0.0.1:8011/docs`. Choose **Authorize**, paste the raw JWT into the bearer field, authorize and close. Expand **POST /notes > Try it out**, enter this complete request body, then execute:

**Request body - Swagger editor for `POST /notes`:**
```json
{"title":"Read docs"}
```
Expected response, not yet run: HTTP 201 with `id` and `title`, never `owner`. On a completely new volume the first ID is 1; on later runs use the ID actually returned. Expand **GET /notes/{note_id}**, enter that ID and execute: expect HTTP 200 and the same public fields. Expand **GET /notes** and execute: expect only Ada's notes, ordered by ID, at most 100.

Repeat the token-mint command with the **only change** `ada` -> `bob`; reauthorize Swagger with Bob's raw JWT using the same dialog steps. Repeating GET with Ada's ID should yield HTTP 404. Bob's list should be empty on this fresh lab. Clear authorization and repeat GET: expect HTTP 401 with a bearer challenge. If a token expires mid-experiment, mint another for the same subject; never disable expiry.

To observe persistence, mint a fresh Ada token if needed and read her note after this container restart:

**PowerShell or macOS/Linux - folder: `~/code101/python201/lesson11`**
```shell
docker compose -p python201-notes restart api
```
Expected result, not yet run: the API process restarts; allow its health check to become healthy again (`docker compose -p python201-notes ps`). Reading the actual saved ID should still return the note because PostgreSQL data outlives the API process. This is a manual PostgreSQL integration observation, not something the SQLite tests already proved.

Finally stop or destroy only this lab:

**PowerShell or macOS/Linux - folder: `~/code101/python201/lesson11`**
```shell
docker compose -p python201-notes stop
docker compose -p python201-notes down -v --remove-orphans
```
Expected results, not yet run: services stop, then the project's containers/network/volume are removed. **`-v` deletes this lab's notes.** Omit `-v` to retain the volume. Exact Docker progress messages vary. The built image may remain cached; that is not a running service. Close the docs page and credential-bearing terminal when finished.

## How it works
Runtime requests cross three distinct boundaries: DTO validation, authenticated identity, and owner-filtered database access. A request owns one session; a write owns an explicit transaction. Tests replace external infrastructure with a fresh engine and settings object, but keep the real routing, validation and JWT verification path.

**Structure (Mermaid):**
```mermaid
flowchart LR
    A[Client bearer and JSON] --> B[FastAPI validation and identity]
    B --> C[Owner-scoped handler]
    C --> D[Request Session]
    D --> E[(PostgreSQL at runtime)]
    D -. injected in tests .-> F[(Temporary SQLite)]
    C --> G[NoteRead public DTO]
```
> **Why this, not that?** Fixtures make setup ownership explicit and parametrization keeps boundary cases visible. Fresh test databases avoid order-dependent cleanup scripts and accidental writes to real data. SQLite gives fast feedback for this small portable mapping; it cannot certify PostgreSQL procedures, locking, types or migrations. Keep real-database checks such as lesson 09 and a later container/identity walkthrough as separate gates.

Common misconception: TestClient starts Uvicorn or a TCP listener. It does not. A passing application test is valuable, but deployment/networking and identity-provider integration still require their own later execution.

## Try it
1. **Guided:** add an ownership regression test using the existing fixture names. With the pack, copy the **whole** `exercise/starter` folder into your lesson11 workspace and rename the copy `try11`, not `try11/starter`.

Without the pack, create `try11` and repeat the **identical file-creation steps** above using identical contents for: `app.py`, `models.py`, `settings.py`, `security.py`, `issue.py`, `probe.py`, `configure.py`, both requirements files, `pyproject.toml`, `init.sql`, `Dockerfile`, `compose.yml`, `.env.example`, `.gitignore`, `.dockerignore`, `tests/conftest.py` and `tests/test_api.py`. You may copy those exact finished files into matching paths instead of retyping. **Do not copy `.env`, `.venv`, caches or a real database.** The sole additional file/difference is the following starter:

**File: `~/code101/python201/lesson11/try11/tests/test_exercise.py`**
```python
from fastapi.testclient import TestClient


def test_two_owners(client: TestClient, ada_headers: dict[str, str], bob_headers: dict[str, str]) -> None:
    response = client.post("/notes", json={"title": "Ada only"}, headers=ada_headers)
    note_id = response.json()["id"]
    # TODO: assert Ada can read this note and Bob receives 404.
    raise NotImplementedError("complete the ownership assertions")
```
Use the already installed parent environment while running from the exercise project:

**PowerShell - starting folder: `~/code101/python201/lesson11`**
```powershell
Set-Location "$HOME/code101/python201/lesson11/try11"
& ../.venv/Scripts/python.exe -m pytest -q
```

**macOS/Linux - starting folder: `~/code101/python201/lesson11`**
```bash
cd ~/code101/python201/lesson11/try11
../.venv/bin/python -m pytest -q
```
Expected completed outcome, not yet run: the original 16 cases plus the new ownership test should pass (17 total). The starter intentionally raises until completed. No exact timing/report transcript is claimed.
2. **Change:** parametrize that test for two different valid titles while preserving the owner/nonowner assertions. Keep each case's database isolated.
3. **Stretch (optional):** design a PostgreSQL-backed fixture that uses a dedicated test database, rolls back its own data and cannot accidentally target a production URL. Explain what it would prove beyond SQLite before implementing infrastructure.

<details><summary>Solution to the guided rung</summary>

Only this new test differs from the finished project and starter's already-shown supporting files:
**File: `~/code101/python201/lesson11/try11/tests/test_exercise.py`**
```python
from fastapi.testclient import TestClient


def test_two_owners(client: TestClient, ada_headers: dict[str, str], bob_headers: dict[str, str]) -> None:
    response = client.post("/notes", json={"title": "Ada only"}, headers=ada_headers)
    note_id = response.json()["id"]
    assert client.get(f"/notes/{note_id}", headers=ada_headers).status_code == 200
    assert client.get(f"/notes/{note_id}", headers=bob_headers).status_code == 404
```
Use the same fixtures, not a global client or a second unrelated signing key. The test should fail if the single-note owner predicate is removed.
</details>

## Check yourself
1. Why does each test request `client`/`engine` by parameter name?
   <details><summary>Answer</summary>Pytest resolves the fixture dependency graph, creates function-scoped resources and guarantees yield-fixture teardown.</details>
2. Which input is trusted for the stored owner, and which two routes must filter by it?
   <details><summary>Answer</summary>The validated JWT subject, not request JSON. Both list and single-note read queries must enforce the owner predicate.</details>
3. Why is `EXPOSE 8000` not equivalent to publishing an API publicly?
   <details><summary>Answer</summary>It documents a container port. Compose's host mapping controls exposure, here restricted to loopback.</details>
4. Could all 16 SQLite cases pass while PostgreSQL startup is broken?
   <details><summary>Answer</summary>Yes. They do not execute the PostgreSQL initialization SQL, build the image or test external networking/identity.</details>

## Common mistakes
| Symptom or typical message (not captured) | Cause | Fix |
|---|---|---|
| Pytest cannot find fixtures/import the app | Wrong root or misspelled `conftest.py` | Run from the specific project root; keep fixtures under its `tests` folder. |
| Note IDs depend on earlier tests | A global/shared test database leaked state | Keep the function-scoped `tmp_path` engine fixture. |
| HTTP 401 after copying a valid-looking token | Different issuer key, wrong audience or expiry | Mint a fresh local token against the same runtime; never weaken validation. |
| HTTP 500 for missing table | Existing volume/schema mismatch or no initialization | Read database logs; use migrations for retained data and only reset explicitly disposable lab volumes. |
| Compose is healthy but host request fails | Wrong host port or local networking rules | Use 8011 on the host, 8000 inside the container; inspect actual logs/status. |

## Best practice
Make test resources explicit and isolated, parametrize independent boundaries, and test the public HTTP contract rather than implementation details. Source: pytest, [Fixtures](https://docs.pytest.org/en/stable/how-to/fixtures.html) and [Parametrization](https://docs.pytest.org/en/stable/how-to/parametrize.html); FastAPI, [Testing](https://fastapi.tiangolo.com/tutorial/testing/).

## Going further
- [Python backend capstone](https://github.com/Uee03/Code101/tree/main/capstones/backend-python): Keycloak, migrations, the full application contract and deployment hardening.
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/) and [Compose services](https://docs.docker.com/reference/compose-file/services/).
- Add PostgreSQL, migration and real identity-provider execution only in an explicitly authorized later verification session. This draft intentionally records no such pass.

### Phase 4 mixed review
1. A response hides `owner`, but its query has no owner predicate. Is the API authorized correctly?
   <details><summary>Answer</summary>No. Output filtering is not resource authorization.</details>
2. A test signs the wrong-audience token with the wrong key too. What is lost?
   <details><summary>Answer</summary>It can fail for the key alone, so it no longer independently proves audience validation.</details>
3. Does a source ZIP prove the code, Docker build or tests run?
   <details><summary>Answer</summary>No. Packaging source and statically checking text are different from executing and observing behavior.</details>

## Summary
- You built fixture-driven, parametrized contract tests with disposable data.
- You combined validated DTOs, transactions and owner-scoped bearer access.
- You explained the complete Dockerfile, Compose and private configuration inputs.
- You separated fast application checks from real database, identity and deployment verification.

## Next lesson
Python 201 is complete. Continue with the [backend-python capstone](https://github.com/Uee03/Code101/tree/main/capstones/backend-python) for the full application; Python 301's architecture/performance scope is listed in the [curriculum](https://github.com/Uee03/Code101/blob/main/docs/CURRICULUM.md#python), not an unwritten lesson promised by number.
