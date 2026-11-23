---
track: capstone
level: 201
phase: 3
phase_name: identity
lesson: 03
title: "Identity: validating Keycloak tokens, scopes and roles"
time: 90 min
prerequisites: [capstone-backend-python-02, capstone-platform-03]
versions: { python: "3.12 or newer (author run: 3.15.2)", pyjwt: "2.15.1", cryptography: "50.0.2", keycloak_image: "quay.io/keycloak/keycloak:26.8.2" }
verified: 2026-11-23 on Windows 11, Python 3.15.2, Docker 29.9.3, Compose 5.7.0
source: capstones/backend-python/source/phase-3-identity/03-identity/
assets: []
---

# 03. Identity: validating Keycloak tokens, scopes and roles

## Why it matters
Imagine a concert hall. The guard at the door can accept a hand-written note saying "I am the VIP", or check a ticket with a hologram that only the box office can print. Chapter 02 accepted the note: it read the claims of the token and believed them. This chapter installs the hologram check. Without it, anyone who can type JSON is an admin, which is the first of the OWASP API risks (broken authentication).

## What you will build
Real validation of the bearer token in `app/tokens.py`: the signing algorithm must be RS256, the signature must match a key from Keycloak's **JWKS** (JSON Web Key Set, its public keys), the issuer must be exactly ours, the audience must contain `tasks-api`, and the token must not be expired or not-yet-valid (with 30 seconds of tolerance). You will first forge an admin token and watch chapter 02 accept it, then watch the new code refuse it, and run an offline script that tries 14 broken tokens.

Conformance state at the end of this chapter: **17 passed, 1 failed**, the same `me` failure as in chapter 02 (rate-limit headers, chapter 05). Validation adds no new passing check; it removes a hole the script cannot see.

```mermaid
flowchart TD
    T["Authorization: Bearer token"] --> H{"header alg is RS256?"}
    H -- no --> X["401 invalid_token"]
    H -- yes --> K["key for kid from cached JWKS"]
    K -->|"Keycloak unreachable, no cached key"| U["503 Retry-After"]
    K --> S{"signature, iss, aud, exp, nbf, required claims"}
    S -- fails --> X
    S -- ok --> P["Principal: sub, roles, scopes"]
    P --> Q{"scopes of the route present?"}
    Q -- no --> F["403"]
    Q -- yes --> OK["route runs; role and team checks follow"]
```

## Before you start
- Chapter 02 done, or unzip `backend-python-phase-3-identity.zip` and open `03-identity/code`. Files unchanged from chapters 01 and 02 are not repeated (the pack holds the whole project).
- Docker running; the stack of chapter 02 may still run (`docker compose ps`), otherwise `docker compose up -d --wait` in the project folder (with `.env` from `.env.example`).
- Chapter 03 of the platform capstone (the realm, the claims in a token). The token of alice carries `iss` `http://localhost:8180/realms/tasksteams`, `aud` `tasks-api`, `sub` her user id, `realm_access.roles`, and a space separated `scope`.

## Steps
### Step 1. Add PyJWT
Replace `requirements.txt` and `pyproject.toml`. **PyJWT** reads and verifies JSON Web Tokens; the extra `[crypto]` installs the `cryptography` package that RS256 needs.

**File: `requirements.txt`**
```text
fastapi==0.165.0
uvicorn==0.54.0
pydantic==2.14.4
pydantic-settings==2.16.3
SQLAlchemy==2.1.9
psycopg[binary]==3.3.9
PyJWT[crypto]==2.15.1
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
    "PyJWT[crypto]>=2.15,<3",
]
```

```text
(.venv) tasksteams-api> python -m pip install -r requirements.txt
```

### Step 2. See the hole (with the chapter 02 code)
Create `scripts/forge_token.py`. It writes a token whose claims say "alice, admin, all scopes" and signs it with a **random key that Keycloak has never seen**:

**File: `scripts/forge_token.py`**
```python
#!/usr/bin/env python3
"""Print a FORGED admin token: well-formed claims for alice, signed with a key that Keycloak never saw.

  python scripts/forge_token.py

A server that only reads the payload (the phase 2 stand-in) believes it. A server that checks the signature rejects it.
"""
import time

import jwt
from cryptography.hazmat.primitives.asymmetric import rsa


def main() -> None:
    attacker_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    now = int(time.time())
    claims = {
        "iss": "http://localhost:8180/realms/tasksteams",
        "aud": "tasks-api",
        "sub": "a11ce000-0000-4000-8000-000000000001",
        "preferred_username": "alice",
        "realm_access": {"roles": ["admin"]},
        "scope": "openid tasks:read tasks:write tasks:admin",
        "iat": now,
        "exp": now + 300,
    }
    print(jwt.encode(claims, attacker_key, algorithm="RS256", headers={"kid": "forged"}))


if __name__ == "__main__":
    main()
```

Start the **chapter 02** API (`python -m uvicorn app.main:app --port 8000`, as before) and send the forged token with the helper of chapter 02. In PowerShell save the token in a variable first; in bash use `$(...)`:

```powershell
# Windows PowerShell
$FORGED = python scripts/forge_token.py
python scripts/call.py GET /v1/audit-log --token $FORGED
```

```bash
# macOS and Linux
FORGED=$(python3 scripts/forge_token.py)
python3 scripts/call.py GET "/v1/audit-log?limit=1" --token "$FORGED"
```

Expected output with the chapter 02 code: the API **believes the forgery** and hands the audit trail to a stranger.

```text
HTTP/1.1 200 OK
date: Mon, 23 Nov 2026 08:37:05 GMT
server: uvicorn
content-length: 549
content-type: application/json
x-trace-id: e7ac5112fb9e4e2b9de9367e7710504c

{"items":[{"id":21,"occurredAt":"2026-11-23T08:36:37.893970Z","actorId":"a11ce000-0000-4000-8000-000000000001","action":"create","entityType":"comment","entityId":"c0000000-0000-4000-8000-000000000003","details":{"id":"c0000000-0000-4000-8000-000000000003","body":"The emulator needs adb reverse for port 8180.","task_id":"7a500000-0000-4000-8000-000000000007","author_id":"b0b00000-0000-4000-8000-000000000002","created_at":"2026-11-23T08:36:37.89397+00:00"}}],"page":{"limit":1,"nextCursor":"WyIyMDI2LTExLTIzVDA4OjM2OjM3Ljg5Mzk3MCswMDowMCIsMjFd"}}
```

Stop that API with Ctrl+C. Everything in the next steps closes this hole.

### Step 3. New settings
Replace `app/config.py` (four new settings) and `.env.example` (the token section at the end):

**File: `app/config.py`**
```python
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Every setting comes from an environment variable of the same name (DATABASE_URL, TOKEN_ISSUER, ...)."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    service_version: str = "1.0.0"
    log_level: str = "INFO"
    public_base_url: str = "http://localhost:8000"
    enable_docs: bool = True
    database_url: str
    db_pool_size: int = 10
    db_max_overflow: int = 10
    token_issuer: str
    token_audience: str = "tasks-api"
    jwks_url: str
    token_leeway_seconds: int = 30


@lru_cache
def get_settings() -> Settings:
    return Settings()
```

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

# Token validation. TOKEN_ISSUER must equal the `iss` claim character for character; JWKS_URL is where the keys are fetched.
TOKEN_ISSUER=http://localhost:8180/realms/tasksteams
TOKEN_AUDIENCE=tasks-api
JWKS_URL=http://127.0.0.1:8180/realms/tasksteams/protocol/openid-connect/certs
TOKEN_LEEWAY_SECONDS=30
```

`TOKEN_ISSUER` must equal the `iss` claim of the tokens **character for character**; Keycloak builds it from its configured hostname (`http://localhost:8180/realms/tasksteams`), no matter which address you used to reach it. `JWKS_URL` is where the keys are fetched from: on your computer `127.0.0.1:8180`, inside Compose (chapter 04) `keycloak:8080`. The issuer and the key address are therefore two separate settings.

### Step 4. The token verifier
Create `app/tokens.py`:

**File: `app/tokens.py`**
```python
from collections.abc import Callable
from typing import Any

import jwt
from jwt import PyJWKClient, PyJWKClientConnectionError


class TokenRejected(Exception):
    """The token cannot be trusted. `reason` is for our log, `public` is safe to show the caller."""

    def __init__(self, reason: str, public: str = "The access token is invalid.") -> None:
        super().__init__(reason)
        self.reason = reason
        self.public = public


class KeysUnavailable(Exception):
    """The signing keys could not be fetched. Not the caller's fault, so the API answers 503, not 401."""


class JwksKeys:
    """Finds the public key for a token. PyJWKClient keeps the JWK Set in memory for `lifespan` seconds and,
    when a token names an unknown `kid`, fetches it again at most once per `cooldown` seconds."""

    def __init__(self, url: str, lifespan: float = 300, cooldown: float = 30, timeout: float = 5) -> None:
        self._client = PyJWKClient(url, lifespan=lifespan, cooldown_duration=cooldown, timeout=timeout)

    def __call__(self, token: str) -> Any:
        try:
            return self._client.get_signing_key_from_jwt(token).key
        except PyJWKClientConnectionError as exc:
            raise KeysUnavailable(str(exc)) from exc
        except jwt.PyJWTError as exc:
            raise TokenRejected(f"no signing key for this token: {exc}") from exc


class TokenVerifier:
    """Applies the platform's token rules (platform TDD, section 7) and returns the claims of a valid token."""

    def __init__(self, *, issuer: str, audience: str, key_for: Callable[[str], Any], leeway: int = 30) -> None:
        self.issuer = issuer
        self.audience = audience
        self.key_for = key_for
        self.leeway = leeway

    def verify(self, token: str) -> dict[str, Any]:
        try:
            header = jwt.get_unverified_header(token)
        except jwt.PyJWTError:
            raise TokenRejected("not a JWT") from None
        if header.get("alg") != "RS256":  # blocks alg=none and the HS256 key-confusion attack before any key is looked up
            raise TokenRejected(f"algorithm {header.get('alg')!r} is not allowed")
        key = self.key_for(token)
        try:
            return jwt.decode(
                token,
                key,
                algorithms=["RS256"],
                issuer=self.issuer,
                audience=self.audience,  # PyJWT accepts both a string and a list in the aud claim
                leeway=self.leeway,
                options={"require": ["exp", "iss", "aud", "sub"]},
            )
        except jwt.ExpiredSignatureError:
            raise TokenRejected("token expired", "The access token has expired.") from None
        except jwt.PyJWTError as exc:
            raise TokenRejected(f"{type(exc).__name__}: {exc}") from None
```

Read it in this order:

- `TokenRejected` carries a `reason` for **our log** and a `public` sentence safe to show the caller. The caller never learns *which* rule failed, only that the token is invalid; an attacker gets no feedback to iterate on. An expired token is the one friendly exception, because every honest client must be able to tell "refresh me".
- `KeysUnavailable` is a different failure: Keycloak cannot be reached and we have no cached key. That is not the caller's fault, so it becomes **503**, not 401.
- `JwksKeys` wraps PyJWT's `PyJWKClient`. It keeps the whole key set in memory for 5 minutes (`lifespan=300`). When a token names a `kid` we do not know, it fetches again, but at most once per 30 seconds (`cooldown_duration=30`), so someone sending random `kid` values cannot turn our API into a machine that hammers Keycloak. A key that Keycloak has just rotated can therefore be unknown for up to 30 seconds; the 5 minute token life makes that acceptable.
- `TokenVerifier.verify` first reads the **unverified header** and requires `alg == "RS256"`. This blocks the `none` algorithm and the **key confusion** attack (a token signed with HMAC using our public key as the secret) before any key is looked up. Then `jwt.decode` checks the signature, `iss`, `aud`, `exp` and `nbf` in one call. `audience=` accepts both forms the claim can take (a string for one audience, a list for several), and `options={"require": [...]}` makes the four claims mandatory, so a token without `exp` can never live forever. `leeway` tolerates 30 seconds of clock difference between servers.

`key_for` is a plain function that takes the token and returns the key. Production passes `JwksKeys`; the demo script below passes a lambda holding a key it made itself, which is why the rules can be tested without Keycloak.

### Step 5. Wire it in
Replace `app/dependencies.py` (adds the verifier):

**File: `app/dependencies.py`**
```python
from typing import Annotated

from fastapi import Depends, Request

from app.config import Settings, get_settings
from app.db import Database
from app.tokens import TokenVerifier


def get_db(request: Request) -> Database:
    return request.app.state.db


def get_verifier(request: Request) -> TokenVerifier:
    return request.app.state.verifier


Db = Annotated[Database, Depends(get_db)]
Verifier = Annotated[TokenVerifier, Depends(get_verifier)]
AppSettings = Annotated[Settings, Depends(get_settings)]
```

Replace `app/auth.py`. `read_claims` is gone; `authenticate` now calls the verifier:

**File: `app/auth.py`**
```python
import logging
from dataclasses import dataclass
from typing import Annotated, Any
from uuid import UUID

from fastapi import Depends, Request, Security
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer, SecurityScopes

from app.dependencies import Db, Verifier
from app.errors import ProblemError, forbidden, unauthorized
from app.logging_config import log_fields
from app.repositories import users
from app.tokens import KeysUnavailable, TokenRejected

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


def principal_from_claims(claims: dict[str, Any]) -> Principal:
    """Turn the claims of an already verified token into a Principal."""
    try:
        user_id = UUID(str(claims["sub"]))
    except (KeyError, ValueError):
        raise unauthorized("The access token has no valid subject.") from None
    username = str(claims.get("preferred_username") or user_id)
    realm_access = claims.get("realm_access")
    roles = realm_access.get("roles", []) if isinstance(realm_access, dict) else []
    return Principal(
        user_id=user_id,
        username=username,
        email=str(claims.get("email") or f"{username}@users.invalid"),
        display_name=str(claims.get("name") or username),
        roles=frozenset(role for role in roles if isinstance(role, str) and role in KNOWN_ROLES),
        scopes=frozenset(str(claims.get("scope", "")).split()),
    )


def authenticate(
    security_scopes: SecurityScopes,
    request: Request,
    verifier: Verifier,
    db: Db,
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> Principal:
    """Dependency for every protected route: 401 without a valid token, 403 without the required scopes."""
    if credentials is None:
        raise unauthorized("A bearer access token is required.")
    try:
        claims = verifier.verify(credentials.credentials)
    except TokenRejected as rejected:
        logger.warning("token rejected", extra=log_fields(event="token_rejected", reason=rejected.reason))
        raise unauthorized(rejected.public, {"WWW-Authenticate": 'Bearer realm="tasksteams", error="invalid_token"'}) from None
    except KeysUnavailable as unavailable:
        logger.error("signing keys unavailable: %s", unavailable)
        raise ProblemError(503, "The sign-in keys cannot be fetched right now.", headers={"Retry-After": "5"}) from None
    principal = principal_from_claims(claims)
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

What stayed the same is the point: the routers did not change at all, because they only know `Principal` and the `Reader` and `Writer` types. What is new: a rejected token is logged as a warning with the **reason but never the token**; the answer carries `WWW-Authenticate: Bearer realm="tasksteams", error="invalid_token"` (RFC 6750); unreachable keys give 503; and `principal_from_claims` now reads `realm_access` defensively, because even a verified token is input.

Replace `app/main.py` (the verifier is created next to the database pool):

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
from app.tokens import JwksKeys, TokenVerifier


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    app.state.db = Database(settings.database_url, settings.db_pool_size, settings.db_max_overflow)
    app.state.verifier = TokenVerifier(
        issuer=settings.token_issuer,
        audience=settings.token_audience,
        key_for=JwksKeys(settings.jwks_url),
        leeway=settings.token_leeway_seconds,
    )
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

### Step 6. Test the rules offline
Create `scripts/token_rules.py`. It makes its own RSA key, builds one token per broken rule, and shows what the verifier answers:

**File: `scripts/token_rules.py`**
```python
#!/usr/bin/env python3
"""Run the token rules offline: build tokens that break one rule each and show what the verifier says.

  python scripts/token_rules.py

No Keycloak and no network: the script makes its own RSA key and hands the verifier the matching public key.
"""
import base64
import hashlib
import hmac
import json
import sys
import time
from pathlib import Path

import jwt
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app.tokens import TokenRejected, TokenVerifier  # noqa: E402

ISSUER = "http://localhost:8180/realms/tasksteams"
AUDIENCE = "tasks-api"
trusted_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
attacker_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
verifier = TokenVerifier(issuer=ISSUER, audience=AUDIENCE, key_for=lambda token: trusted_key.public_key(), leeway=30)


def make_token(key=trusted_key, algorithm="RS256", **changes) -> str:
    now = int(time.time())
    claims = {"iss": ISSUER, "aud": AUDIENCE, "sub": "a11ce000-0000-4000-8000-000000000001", "iat": now, "exp": now + 300}
    claims.update(changes)
    claims = {name: value for name, value in claims.items() if value is not None}  # None removes a claim
    return jwt.encode(claims, key, algorithm=algorithm, headers={"kid": "demo"})


def hs256_with_public_key() -> str:
    """The key-confusion attack: sign with HMAC, using the server's PUBLIC key text as the secret."""
    def part(data: dict) -> str:
        return base64.urlsafe_b64encode(json.dumps(data).encode()).rstrip(b"=").decode()

    public_pem = trusted_key.public_key().public_bytes(serialization.Encoding.PEM, serialization.PublicFormat.SubjectPublicKeyInfo)
    now = int(time.time())
    signing_input = part({"alg": "HS256", "typ": "JWT", "kid": "demo"}) + "." + part(
        {"iss": ISSUER, "aud": AUDIENCE, "sub": "a11ce000-0000-4000-8000-000000000001", "exp": now + 300})
    signature = hmac.new(public_pem, signing_input.encode(), hashlib.sha256).digest()
    return signing_input + "." + base64.urlsafe_b64encode(signature).rstrip(b"=").decode()


now = int(time.time())
cases = [
    ("valid token", make_token(), True),
    ("audience is a list that contains tasks-api", make_token(aud=["account", AUDIENCE]), True),
    ("expired 10 s ago (inside the 30 s skew)", make_token(exp=now - 10), True),
    ("expired 120 s ago", make_token(exp=now - 120), False),
    ("not valid before 5 minutes from now", make_token(nbf=now + 300), False),
    ("wrong issuer", make_token(iss="http://evil.example/realms/tasksteams"), False),
    ("wrong audience (string)", make_token(aud="account"), False),
    ("wrong audience (list)", make_token(aud=["account", "other-api"]), False),
    ("no exp claim", make_token(exp=None), False),
    ("no sub claim", make_token(sub=None), False),
    ("signed with another key", make_token(key=attacker_key), False),
    ("algorithm none (no signature)", make_token(key=None, algorithm="none"), False),
    ("HS256 signed with the public key", hs256_with_public_key(), False),
    ("not a token at all", "hello", False),
]

failures = 0
for name, token, should_pass in cases:
    try:
        verifier.verify(token)
        outcome, passed = "accepted", True
    except TokenRejected as rejected:
        outcome, passed = f"rejected: {rejected.reason}", False
    verdict = "ok   " if passed == should_pass else "WRONG"
    failures += passed != should_pass
    print(f"{verdict} {name:<44} {outcome}")
print("all rules hold" if failures == 0 else f"{failures} rule(s) broken")
sys.exit(1 if failures else 0)
```

## Run it
Stack up (`docker compose up -d --wait`) and the API started as before:

```text
(.venv) tasksteams-api> python -m uvicorn app.main:app --port 8000
```

**1. The forged token is now refused**

```powershell
# Windows PowerShell
$FORGED = python scripts/forge_token.py
python scripts/call.py GET /v1/audit-log --token $FORGED
```

```text
HTTP/1.1 401 Unauthorized
date: Mon, 23 Nov 2026 08:37:07 GMT
server: uvicorn
www-authenticate: Bearer realm="tasksteams", error="invalid_token"
content-length: 204
content-type: application/problem+json
x-trace-id: fa9bd77cc7e7472591145b4250026c81

{"type":"https://code101.example/problems/unauthorized","title":"Unauthorized","status":401,"detail":"The access token is invalid.","instance":"/v1/audit-log","traceId":"fa9bd77cc7e7472591145b4250026c81"}
```

**2. A real token still works**

```text
tasksteams-api> python scripts/call.py GET /v1/me --user alice
```

```text
HTTP/1.1 200 OK
date: Mon, 23 Nov 2026 08:37:08 GMT
server: uvicorn
content-length: 318
content-type: application/json
x-trace-id: 459f402bc1354ca9b09e9e44828fe244

{"id":"a11ce000-0000-4000-8000-000000000001","username":"alice","email":"alice@tasksteams.test","displayName":"Alice Admin","roles":["admin"],"scopes":["email","openid","profile","tasks:admin","tasks:read","tasks:write"],"teams":[{"teamId":"7ea00000-0000-4000-8000-000000000001","name":"Platform Team","role":"lead"}]}
```

**3. Every token rule, without Keycloak or a network**

```text
(.venv) tasksteams-api> python scripts/token_rules.py
```

```text
ok    valid token                                  accepted
ok    audience is a list that contains tasks-api   accepted
ok    expired 10 s ago (inside the 30 s skew)      accepted
ok    expired 120 s ago                            rejected: token expired
ok    not valid before 5 minutes from now          rejected: ImmatureSignatureError: The token is not yet valid (nbf)
ok    wrong issuer                                 rejected: InvalidIssuerError: Invalid issuer
ok    wrong audience (string)                      rejected: InvalidAudienceError: Audience doesn't match
ok    wrong audience (list)                        rejected: InvalidAudienceError: Audience doesn't match
ok    no exp claim                                 rejected: MissingRequiredClaimError: Token is missing the "exp" claim
ok    no sub claim                                 rejected: MissingRequiredClaimError: Token is missing the "sub" claim
ok    signed with another key                      rejected: InvalidSignatureError: Signature verification failed
ok    algorithm none (no signature)                rejected: algorithm 'none' is not allowed
ok    HS256 signed with the public key             rejected: algorithm 'HS256' is not allowed
ok    not a token at all                           rejected: not a JWT
all rules hold
```

**4. Conformance**

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
PASS  create team (201, Location and ETag set, team b28f4b72-8f23-4ec6-9524-29094d6e3281)
PASS  create project (201, project f5097380-4f01-4ce4-a4a0-48c8c992d4c7)
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

Still 17 and 1: the signature checks protect you from attackers; the conformance script only sends honest tokens.

**5. Break it on purpose.** Start the API with the wrong issuer (`127.0.0.1` instead of `localhost`). In PowerShell `$env:TOKEN_ISSUER = "http://127.0.0.1:8180/realms/tasksteams"`; in bash `export TOKEN_ISSUER=http://127.0.0.1:8180/realms/tasksteams`; then start Uvicorn again. Every token is now refused, and **the log says why** while the client is told nothing:

```text
HTTP/1.1 401 Unauthorized
date: Mon, 23 Nov 2026 08:37:11 GMT
server: uvicorn
www-authenticate: Bearer realm="tasksteams", error="invalid_token"
content-length: 197
content-type: application/problem+json
x-trace-id: 391ddc1018484d4a9b614131374b1443

{"type":"https://code101.example/problems/unauthorized","title":"Unauthorized","status":401,"detail":"The access token is invalid.","instance":"/v1/me","traceId":"391ddc1018484d4a9b614131374b1443"}
```

```text
{"time": "2026-11-23T08:37:12.087+00:00", "level": "WARNING", "logger": "tasksteams.auth", "message": "token rejected", "traceId": "391ddc1018484d4a9b614131374b1443", "event": "token_rejected", "reason": "InvalidIssuerError: Invalid issuer"}
```

Remove the variable (`Remove-Item Env:TOKEN_ISSUER` or `unset TOKEN_ISSUER`). Now point `JWKS_URL` at a closed port, for example `http://127.0.0.1:9/jwks`, and restart: the API cannot get a key, so it answers **503**:

```text
HTTP/1.1 503 Service Unavailable
date: Mon, 23 Nov 2026 08:37:13 GMT
server: uvicorn
retry-after: 5
content-length: 228
content-type: application/problem+json
x-trace-id: 20025d363e204109a0d161157097fd9f

{"type":"https://code101.example/problems/service-unavailable","title":"Service unavailable","status":503,"detail":"The sign-in keys cannot be fetched right now.","instance":"/v1/me","traceId":"20025d363e204109a0d161157097fd9f"}
```

```text
{"time": "2026-11-23T08:37:16.125+00:00", "level": "ERROR", "logger": "tasksteams.auth", "message": "signing keys unavailable: Fail to fetch data from the url, err: \"<urlopen error [WinError 10061] No connection could be made because the target machine actively refused it>\"", "traceId": "20025d363e204109a0d161157097fd9f"}
```

Remove that variable too and stop the API with Ctrl+C.

## How it works
The three questions every protected request answers, in order:

| Question | Where | Failure |
|----------|-------|---------|
| Is this a genuine, current token for us? | `TokenVerifier` (signature, `iss`, `aud`, `exp`, `nbf`) | 401, or 503 if the keys are unavailable |
| May this **client** do this kind of thing? | `authenticate` compares the route's scopes (`tasks:read`, `tasks:write`, `tasks:admin`) with the token's `scope` claim | 403 |
| May this **user** do it, here? | the role (`realm_access.roles`) in `require_admin`, and team membership in `access.py` | 403 or 404 |

A token carries scopes **and** roles on purpose. Scopes are what the user consented to give the app (an app that only needs to read asks for `tasks:read`); roles are what the user is in the company. Effective permission is the **intersection**: bob's token holds the `tasks:admin` scope in the smoke client, and bob is still refused admin routes because he lacks the `admin` role (conformance check `403 for member on admin route`).

```mermaid
sequenceDiagram
    autonumber
    participant C as Client
    participant A as API
    participant K as Keycloak
    C->>A: request, token with kid K1
    A->>K: GET JWKS (first use only)
    K-->>A: key set {K1}
    A-->>C: 200 (key cached for 5 minutes)
    C->>A: request, token with unknown kid K2
    A->>A: last fetch under 30 s ago, no refetch
    A-->>C: 401
    C->>A: the same later
    A->>K: GET JWKS (cooldown over)
    K-->>A: key set {K1, K2}
    A-->>C: 200
```

New terms: **JWT** (a signed JSON token: header, claims, signature); **JWKS** (the public keys of the issuer, as JSON); **`kid`** (key id: which key signed this token); **claim** (one fact inside the token, like `sub` or `exp`); **audience** (`aud`: who the token is meant for); **issuer** (`iss`: who made it); **clock skew** (two servers disagree on the time by a few seconds); **key confusion** (tricking a verifier into using a public key as an HMAC secret).

Why this, not that:

| Choice | Alternative | Why we chose this |
|--------|-------------|-------------------|
| Validate locally with cached keys | Call Keycloak's introspection endpoint per request | No network round trip per request and no dependency on Keycloak for every call; the price is that a revoked token stays valid until it expires (5 minutes here) |
| PyJWT with `PyJWKClient` | Authlib or python-jose | Small and widely used, and the client already caches and throttles. Authlib is a good choice when the same app also acts as an OAuth client |
| Allow only `RS256` | Accept whatever the header says | The header is attacker controlled (RFC 8725). We decide the algorithm, not the token |
| Same message for every invalid token | Tell the caller which rule failed | An attacker gains nothing from the detail; the log keeps it for you |

### Appendix: the same steps with Authentik
Authentik can replace Keycloak as the identity provider. The code does not change, only settings and a few claims. Check each value in your own Authentik instance (provider and application settings) before you rely on it; the endpoint layout is from the Authentik OAuth2 provider documentation.

| Setting or fact | Keycloak (this capstone) | Authentik |
|-----------------|--------------------------|-----------|
| `TOKEN_ISSUER` | `http://localhost:8180/realms/tasksteams` | `https://<host>/application/o/<application-slug>/` (default issuer mode, with the trailing slash) |
| `JWKS_URL` | `.../realms/tasksteams/protocol/openid-connect/certs` | `https://<host>/application/o/<application-slug>/jwks/` |
| Signing algorithm | RS256 | choose a signing key (certificate) on the provider so that tokens are RS256; the verifier refuses anything else |
| `TOKEN_AUDIENCE` | `tasks-api` through an audience mapper | the provider's client id is the usual audience; set `TOKEN_AUDIENCE` to it |
| Roles | `realm_access.roles` | a scope mapping that adds the groups or roles claim you choose; change `principal_from_claims` to read it |
| Scopes | `scope` claim | `scope` claim from the requested scopes; define scope mappings for `tasks:read`, `tasks:write`, `tasks:admin` |

## Try it
Exercise: **read claims like the API.** Copy `exercise/starter/claims.py` into a folder of your own and finish three functions: `audiences` (the `aud` claim may be a string or a list; always return a list), `scopes` (one space separated string into a set), and `allowed` (the audience is listed and the scope is granted). Run `python claims.py`: only token `b` may write.

**File: `exercise/starter/claims.py`**
```python
"""Exercise 3: read token claims the way the API does.

Finish the three functions. Run:  python claims.py
"""


def audiences(claims):
    # TODO 1: the aud claim is a string for one audience and a list for several. Always return a list.
    raise NotImplementedError


def scopes(claims):
    # TODO 2: the scope claim is ONE string with the scopes separated by spaces. Return a set of scopes.
    raise NotImplementedError


def allowed(claims, audience, needed_scope):
    # TODO 3: True only when the audience is listed AND the scope is granted
    raise NotImplementedError


if __name__ == "__main__":
    tokens = {
        "a": {"aud": "tasks-api", "scope": "openid tasks:read"},
        "b": {"aud": ["account", "tasks-api"], "scope": "openid tasks:read tasks:write"},
        "c": {"aud": "account", "scope": "tasks:read tasks:write"},
    }
    for name, claims in tokens.items():
        print(name, allowed(claims, "tasks-api", "tasks:write"))
```

<details><summary>Solution</summary>

**File: `exercise/solution/claims.py`**
```python
"""Exercise 3: read token claims the way the API does (solution).

Run:  python claims.py
"""


def audiences(claims):
    aud = claims.get("aud", [])
    return [aud] if isinstance(aud, str) else list(aud)


def scopes(claims):
    return set(str(claims.get("scope", "")).split())


def allowed(claims, audience, needed_scope):
    return audience in audiences(claims) and needed_scope in scopes(claims)


if __name__ == "__main__":
    tokens = {
        "a": {"aud": "tasks-api", "scope": "openid tasks:read"},
        "b": {"aud": ["account", "tasks-api"], "scope": "openid tasks:read tasks:write"},
        "c": {"aud": "account", "scope": "tasks:read tasks:write"},
    }
    for name, claims in tokens.items():
        print(name, allowed(claims, "tasks-api", "tasks:write"))
```

Output:

```text
a False
b True
c False
```

Token `a` has the audience but no write scope, token `c` has the scope but the wrong audience: both fail, because a token must be meant for this API **and** carry the scope.

</details>

## Check yourself
1. Why does `verify` check the `alg` header before it looks for a key? <details><summary>Answer</summary>The header is written by the sender. If we let it choose the algorithm, an attacker can pick `none` (no signature) or HS256 with our public key as the secret. We decide: RS256 only.</details>
2. Why are `TOKEN_ISSUER` and `JWKS_URL` separate settings? <details><summary>Answer</summary>The issuer is a name that must match the `iss` claim exactly (`localhost`), while the key address is a network location that depends on where the API runs (`127.0.0.1` on the host, `keycloak` inside Docker).</details>
3. A user is removed in Keycloak at 10:00:00 and has a token issued at 09:58:00 (5 minute life). Until when can they still call the API, and how would you shorten it? <details><summary>Answer</summary>Until about 10:03:00 plus the 30 second skew, because validation is local. Shorten the token life, or call the introspection endpoint for sensitive operations, at the cost of a network call.</details>
4. Why is "Keycloak unreachable" a 503 and not a 401? <details><summary>Answer</summary>The caller did nothing wrong; telling them their token is invalid would make clients throw away good tokens and log users out. 503 with `Retry-After` says "try again".</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Every call is `401` with `"detail":"The access token is invalid."` and the log says `"reason": "InvalidIssuerError: Invalid issuer"` | `TOKEN_ISSUER` differs from the token's `iss`, for example `127.0.0.1` instead of `localhost`, or a missing `/realms/tasksteams` | Copy the `issuer` value from `http://127.0.0.1:8180/realms/tasksteams/.well-known/openid-configuration` |
| Every call is `503` with `"detail":"The sign-in keys cannot be fetched right now."` and the log says `signing keys unavailable: Fail to fetch data from the url` | `JWKS_URL` is wrong, Keycloak is not running, or inside Docker you used `127.0.0.1` (that is the container itself) | Check `docker compose ps`; open the `JWKS_URL` in a browser; inside Compose use `http://keycloak:8080/...` |
| `InvalidAudienceError: Audience doesn't match` in the log | The token was issued to a client without the `tasks-api` audience mapper | Use a client of the platform realm (`tasks-web`, `tasks-mobile`, `tasks-smoke`) |
| `401` with `The access token has expired.` | Tokens live 5 minutes | Get a new token (`--user bob` fetches one for every call) or refresh it |
| `ImportError` or `ModuleNotFoundError: No module named 'jwt'` | PyJWT is not installed in the active environment | `python -m pip install -r requirements.txt` |

## Best practice
Verify every claim you rely on, pin the algorithm yourself, and never log the token. Source: RFC 8725 JSON Web Token Best Current Practices https://www.rfc-editor.org/info/rfc8725 and PyJWT usage documentation https://pyjwt.readthedocs.io/en/stable/usage.html

## Next lesson
04. Run and ship: package the API as a multi-stage, non-root container image, add it to the platform Compose project with an override file, and start everything with one command.
