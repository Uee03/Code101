---
track: capstone
level: 201
phase: 5
phase_name: hardening
lesson: 05
title: "Hardening: limits, headers, logging, OWASP walk-through, backup"
time: 75 min
prerequisites: [capstone-backend-python-04]
versions: { python_image: "python:3.14.10-slim-trixie", fastapi: "0.165.0", starlette: "1.10.0", postgres_image: "17-alpine" }
verified: 2026-11-23 on Windows 11, Docker 29.9.3, Compose 5.7.0
source: capstones/backend-python/source/phase-5-hardening/05-hardening/
assets: []
---

# 05. Hardening: limits, headers, logging, OWASP walk-through, backup

## Why it matters
A bank vault has more than a thick door. It has a guard who counts how often you come in, cameras that record who asked for what, walls that do not let anyone climb out of their own room, and a copy of the ledger in another building. Chapters 01 to 04 built a correct service; this chapter makes it hard to abuse and easy to recover. It also turns the last conformance check green.

## What you will build
- A **rate limiter**: 100 requests per 60 seconds per user, 30 per client address when anonymous, with the `RateLimit-Limit`, `RateLimit-Remaining` and `RateLimit-Reset` headers and a `429` problem with `Retry-After`.
- **Security headers**, a **CORS** allow-list, a **1 MB request body limit** (413) and the interactive docs switched off in the container.
- **Security logging**: every refusal (401, 403, 429) becomes a log event with the user id and the reason, never a token or a body.
- A **hardened container**: read-only file system, no Linux capabilities, memory and process limits.
- The **OWASP API Security Top 10** walked through against your own code, a production checklist, and a **backup and restore** that you actually run.

Conformance state at the end of this chapter: **18 passed, 0 failed**.

```mermaid
flowchart LR
    C["client"] --> RC["RequestContextMiddleware: trace id, access log, RateLimit headers, 500 safety net"]
    RC --> SH["SecurityHeadersMiddleware"]
    SH --> CO["CORSMiddleware: allow-list, preflight"]
    CO --> BS["BodySizeLimitMiddleware: 413"]
    BS --> APP["FastAPI: routing, validation, authenticate (429, 401, 403), handlers"]
```

## Before you start
- Chapter 04 done, or unzip `backend-python-phase-5-hardening.zip` and open `05-hardening/code`. Files unchanged from earlier chapters (including the `Dockerfile` and `.dockerignore` of chapter 04) are not repeated.
- Docker running; host ports 5432, 8180 and 8000 free.

## Steps
### Step 1. New settings
Replace `app/config.py` (seven new settings and a helper that splits the origin list):

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
    rate_limit_user: int = 100
    rate_limit_anonymous: int = 30
    rate_limit_window_seconds: int = 60
    max_body_bytes: int = 1_048_576
    cors_origins: str = "http://localhost:4200,http://localhost:5173"
    enable_hsts: bool = False

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
```

Replace `.env.example` (a new block at the end). The container gets the same values from the override file below:

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

# Limits and browser rules (phase 5). Requests per window and user, per window and unknown caller, window length, largest body in bytes.
RATE_LIMIT_USER=100
RATE_LIMIT_ANONYMOUS=30
RATE_LIMIT_WINDOW_SECONDS=60
MAX_BODY_BYTES=1048576
CORS_ORIGINS=http://localhost:4200,http://localhost:5173
ENABLE_HSTS=false
```

### Step 2. The rate limiter
Create `app/ratelimit.py`:

**File: `app/ratelimit.py`**
```python
import math
import threading
import time
from collections.abc import Callable
from dataclasses import dataclass


@dataclass(frozen=True)
class Decision:
    allowed: bool
    limit: int
    remaining: int
    reset_seconds: int

    def headers(self) -> dict[str, str]:
        return {
            "RateLimit-Limit": str(self.limit),
            "RateLimit-Remaining": str(self.remaining),
            "RateLimit-Reset": str(self.reset_seconds),
        }


class FixedWindowLimiter:
    """Counts requests per key in fixed windows. It lives in this process, so with several workers or
    containers each one counts on its own; use a shared store (for example Redis) when that is not acceptable."""

    def __init__(self, window_seconds: int, clock: Callable[[], float] = time.monotonic) -> None:
        self.window = window_seconds
        self.clock = clock
        self._windows: dict[str, tuple[float, int]] = {}  # key -> (window start, requests so far)
        self._lock = threading.Lock()

    def hit(self, key: str, limit: int) -> Decision:
        now = self.clock()
        with self._lock:
            if len(self._windows) > 10_000:  # keep memory bounded: forget windows that already ended
                self._windows = {k: v for k, v in self._windows.items() if now - v[0] < self.window}
            start, count = self._windows.get(key, (now, 0))
            if now - start >= self.window:
                start, count = now, 0
            count += 1
            self._windows[key] = (start, count)
        reset = max(1, math.ceil(self.window - (now - start)))
        return Decision(count <= limit, limit, max(0, limit - count), reset)
```

A **fixed window** counts requests per key between two moments in time: the first request opens a window of `window_seconds`, every request adds one, and when the window has passed the count starts again. `hit` returns a `Decision` with the numbers for the headers. The clock is a parameter, so the arithmetic can be tested without waiting (the exercise below does exactly that). The dictionary holds one entry per key and is cleaned when it grows past 10,000 entries, which bounds memory.

Two limits you must know: the counters live **in this process**, so two replicas allow twice the traffic (use a shared store such as Redis when that matters), and a fixed window allows a burst of twice the limit around a window boundary (a sliding window or a token bucket smooths that, at the price of more state).

### Step 3. Apply it where identity is decided
Replace `app/dependencies.py` (adds the limiter):

**File: `app/dependencies.py`**
```python
from typing import Annotated

from fastapi import Depends, Request

from app.config import Settings, get_settings
from app.db import Database
from app.ratelimit import FixedWindowLimiter
from app.tokens import TokenVerifier


def get_db(request: Request) -> Database:
    return request.app.state.db


def get_verifier(request: Request) -> TokenVerifier:
    return request.app.state.verifier


def get_limiter(request: Request) -> FixedWindowLimiter:
    return request.app.state.limiter


Db = Annotated[Database, Depends(get_db)]
Verifier = Annotated[TokenVerifier, Depends(get_verifier)]
Limiter = Annotated[FixedWindowLimiter, Depends(get_limiter)]
AppSettings = Annotated[Settings, Depends(get_settings)]
```

Replace `app/auth.py`:

**File: `app/auth.py`**
```python
import logging
from dataclasses import dataclass
from typing import Annotated, Any
from uuid import UUID

from fastapi import Depends, Request, Security
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer, SecurityScopes

from app.dependencies import AppSettings, Db, Limiter, Verifier
from app.errors import ProblemError, forbidden, unauthorized
from app.logging_config import log_fields
from app.ratelimit import FixedWindowLimiter
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


def client_address(request: Request) -> str:
    return request.client.host if request.client else "unknown"


def enforce_limit(request: Request, limiter: FixedWindowLimiter, key: str, limit: int) -> None:
    """Count this request. The RateLimit-* headers are added to the response by RequestContextMiddleware."""
    decision = limiter.hit(key, limit)
    request.state.rate_headers = decision.headers()
    if not decision.allowed:
        raise ProblemError(429, f"Too many requests. Try again in {decision.reset_seconds} seconds.",
                           headers={"Retry-After": str(decision.reset_seconds), **decision.headers()})


def authenticate(
    security_scopes: SecurityScopes,
    request: Request,
    verifier: Verifier,
    db: Db,
    limiter: Limiter,
    settings: AppSettings,
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> Principal:
    """Dependency for every protected route: 429 when over the limit, 401 without a valid token, 403 without the required scopes."""
    anonymous_key = f"ip:{client_address(request)}"
    if credentials is None:
        enforce_limit(request, limiter, anonymous_key, settings.rate_limit_anonymous)
        raise unauthorized("A bearer access token is required.")
    try:
        claims = verifier.verify(credentials.credentials)
    except TokenRejected as rejected:
        enforce_limit(request, limiter, anonymous_key, settings.rate_limit_anonymous)
        logger.warning("token rejected", extra=log_fields(event="token_rejected", reason=rejected.reason))
        raise unauthorized(rejected.public, {"WWW-Authenticate": 'Bearer realm="tasksteams", error="invalid_token"'}) from None
    except KeysUnavailable as unavailable:
        logger.error("signing keys unavailable: %s", unavailable)
        raise ProblemError(503, "The sign-in keys cannot be fetched right now.", headers={"Retry-After": "5"}) from None
    principal = principal_from_claims(claims)
    request.state.user_id = str(principal.user_id)
    enforce_limit(request, limiter, f"user:{principal.user_id}", settings.rate_limit_user)
    missing = [scope for scope in security_scopes.scopes if scope not in principal.scopes]
    if missing:
        raise forbidden(f"The scope {missing[0]} is required.")
    if principal.user_id not in _known_users:
        with db.transaction() as conn:
            users.ensure_user(conn, principal.user_id, principal.username, principal.email, principal.display_name)
        _known_users.add(principal.user_id)
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

Look at `authenticate` from the top. Without a token, or with a bad one, the caller is counted by **client address** (limit 30): that stops password-guessing style floods before they cost anything, and it cannot be dodged by sending a made-up user id, because the id is only trusted after the signature is verified. With a valid token the user id is counted (limit 100). `enforce_limit` stores the numbers in the request state; the middleware turns them into headers on **every** response, success or failure. When the limit is exceeded it raises a 429 problem with `Retry-After`.

### Step 4. Log refusals as security events
Replace `app/errors.py`. The only change is in `handle_problem`: a 401, 403 or 429 is also written to the log as a warning with an `event`, the user id and the reason:

**File: `app/errors.py`**
```python
import logging

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.logging_config import log_fields, trace_id_var

security_logger = logging.getLogger("tasksteams.security")

PROBLEM_BASE = "https://code101.example/problems/"

# status -> (last part of the problem type URI, title)
PROBLEMS: dict[int, tuple[str, str]] = {
    400: ("bad-request", "Bad request"),
    401: ("unauthorized", "Unauthorized"),
    403: ("forbidden", "Forbidden"),
    404: ("not-found", "Not found"),
    405: ("method-not-allowed", "Method not allowed"),
    409: ("conflict", "Conflict"),
    412: ("precondition-failed", "Precondition failed"),
    413: ("payload-too-large", "Payload too large"),
    422: ("validation-error", "Validation failed"),
    428: ("precondition-required", "Precondition required"),
    429: ("rate-limited", "Too many requests"),
    500: ("internal-error", "Internal server error"),
    503: ("service-unavailable", "Service unavailable"),
}


class ProblemError(Exception):
    """Raise this anywhere; the handler below turns it into an RFC 9457 response."""

    def __init__(self, status: int, detail: str, *, code: str | None = None,
                 errors: list[dict[str, str]] | None = None, headers: dict[str, str] | None = None) -> None:
        super().__init__(detail)
        self.status = status
        self.detail = detail
        self.code = code
        self.errors = errors
        self.headers = headers


def bad_request(detail: str) -> ProblemError:
    return ProblemError(400, detail)


def unauthorized(detail: str, headers: dict[str, str] | None = None) -> ProblemError:
    return ProblemError(401, detail, headers={"WWW-Authenticate": 'Bearer realm="tasksteams"', **(headers or {})})


def forbidden(detail: str) -> ProblemError:
    return ProblemError(403, detail)


def not_found(detail: str = "The resource was not found.") -> ProblemError:
    return ProblemError(404, detail)


def conflict(detail: str, code: str | None = None) -> ProblemError:
    return ProblemError(409, detail, code=code)


def problem_response(path: str, status: int, detail: str, *, code: str | None = None,
                     errors: list[dict[str, str]] | None = None,
                     headers: dict[str, str] | None = None) -> JSONResponse:
    slug, title = PROBLEMS.get(status, ("error", "Error"))
    body: dict[str, object] = {
        "type": PROBLEM_BASE + slug,
        "title": title,
        "status": status,
        "detail": detail,
        "instance": path,
        "traceId": trace_id_var.get(),
    }
    if code:
        body["code"] = code
    if errors:
        body["errors"] = errors
    return JSONResponse(body, status_code=status, media_type="application/problem+json", headers=headers)


def json_pointer(loc: tuple[object, ...]) -> str:
    """('body', 'dueDate') -> '/dueDate' (RFC 6901: ~ becomes ~0 and / becomes ~1)."""
    return "".join("/" + str(part).replace("~", "~0").replace("/", "~1") for part in loc[1:])


async def handle_problem(request: Request, exc: ProblemError) -> JSONResponse:
    if exc.status in (401, 403, 429):  # security events: who, what, why. Never the token, never the request body.
        security_logger.warning("request refused", extra=log_fields(
            event="refused", status=exc.status, method=request.method, path=request.url.path,
            userId=getattr(request.state, "user_id", None), detail=exc.detail))
    return problem_response(request.url.path, exc.status, exc.detail, code=exc.code, errors=exc.errors, headers=exc.headers)


async def handle_validation(request: Request, exc: RequestValidationError) -> JSONResponse:
    errors = exc.errors()
    path = request.url.path
    if any(error["type"] == "json_invalid" for error in errors):
        return problem_response(path, 400, "The request body is not valid JSON.")
    outside_body = [error for error in errors if error["loc"][0] != "body"]
    if outside_body:  # a bad query parameter, path value or header is a 400, not a 422
        first = outside_body[0]
        name = ".".join(str(part) for part in first["loc"][1:])
        return problem_response(path, 400, f"The {first['loc'][0]} parameter '{name}' is invalid: {first['msg']}.")
    details = [{"pointer": json_pointer(error["loc"]), "detail": error["msg"].removeprefix("Value error, ")} for error in errors]
    return problem_response(path, 422, "One or more fields are invalid.", errors=details)


async def handle_http_exception(request: Request, exc: StarletteHTTPException) -> JSONResponse:
    detail = "No such route." if exc.status_code == 404 else str(exc.detail)
    return problem_response(request.url.path, exc.status_code, detail, headers=dict(exc.headers or {}))


def register_error_handlers(app: FastAPI) -> None:
    app.add_exception_handler(ProblemError, handle_problem)
    app.add_exception_handler(RequestValidationError, handle_validation)
    app.add_exception_handler(StarletteHTTPException, handle_http_exception)
```

### Step 5. Headers, size limit and the rate-limit headers
Replace `app/middleware.py`. It now holds three middlewares:

**File: `app/middleware.py`**
```python
import logging
import time
import uuid

from starlette.datastructures import Headers, MutableHeaders
from starlette.types import ASGIApp, Message, Receive, Scope, Send

from app.errors import problem_response
from app.logging_config import log_fields, trace_id_var

logger = logging.getLogger("tasksteams.access")


class RequestContextMiddleware:
    """Gives each request a trace id, writes one access log line, adds the RateLimit-* headers
    that the authentication dependency left in the request state, and turns a crash into a 500 problem.

    It is a plain ASGI middleware (not BaseHTTPMiddleware) so it adds almost no overhead and sees every response.
    """

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        trace_id = uuid.uuid4().hex
        token = trace_id_var.set(trace_id)
        started = time.perf_counter()
        status = 500
        response_started = False

        async def send_with_trace(message: Message) -> None:
            nonlocal status, response_started
            if message["type"] == "http.response.start":
                response_started = True
                status = message["status"]
                headers = MutableHeaders(scope=message)
                headers["X-Trace-Id"] = trace_id
                for name, value in scope.get("state", {}).get("rate_headers", {}).items():
                    headers[name] = value
            await send(message)

        try:
            await self.app(scope, receive, send_with_trace)
        except Exception:
            logger.exception("unhandled error")
            if not response_started:
                status = 500
                response = problem_response(scope["path"], 500, "An unexpected error occurred.")
                await response(scope, receive, send_with_trace)
        finally:
            fields = {
                "method": scope["method"],
                "path": scope["path"],
                "status": status,
                "durationMs": round((time.perf_counter() - started) * 1000, 1),
                "userId": scope.get("state", {}).get("user_id"),
            }
            logger.info("request", extra=log_fields(**fields))
            trace_id_var.reset(token)


class SecurityHeadersMiddleware:
    """Adds the response headers that tell browsers not to sniff, frame, cache or guess anything about an API answer."""

    def __init__(self, app: ASGIApp, hsts: bool = False) -> None:
        self.app = app
        self.fixed = {
            "X-Content-Type-Options": "nosniff",
            "Cache-Control": "no-store",
            "Referrer-Policy": "no-referrer",
            "Cross-Origin-Resource-Policy": "same-site",
        }
        if hsts:  # only behind HTTPS: browsers remember this for a year
            self.fixed["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        docs = scope["path"] in ("/docs", "/openapi.json")  # Swagger UI loads scripts, so the strict policy would break it

        async def send_with_headers(message: Message) -> None:
            if message["type"] == "http.response.start":
                headers = MutableHeaders(scope=message)
                for name, value in self.fixed.items():
                    headers[name] = value
                if not docs:
                    headers["Content-Security-Policy"] = "default-src 'none'; frame-ancestors 'none'"
            await send(message)

        await self.app(scope, receive, send_with_headers)


class BodyTooLarge(Exception):
    pass


class BodySizeLimitMiddleware:
    """Refuses request bodies above `max_bytes`: by the Content-Length header, and by counting chunked uploads."""

    def __init__(self, app: ASGIApp, max_bytes: int) -> None:
        self.app = app
        self.max_bytes = max_bytes

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        declared = Headers(scope=scope).get("content-length")
        if declared is not None and declared.isdigit() and int(declared) > self.max_bytes:
            await self.reject(scope, receive, send)
            return
        received = 0
        response_started = False

        async def counting_receive() -> Message:
            nonlocal received
            message = await receive()
            if message["type"] == "http.request":
                received += len(message.get("body", b""))
                if received > self.max_bytes:
                    raise BodyTooLarge()
            return message

        async def tracking_send(message: Message) -> None:
            nonlocal response_started
            if message["type"] == "http.response.start":
                response_started = True
            await send(message)

        try:
            await self.app(scope, counting_receive, tracking_send)
        except BodyTooLarge:
            if response_started:
                raise
            await self.reject(scope, receive, send)

    async def reject(self, scope: Scope, receive: Receive, send: Send) -> None:
        response = problem_response(scope["path"], 413, f"The request body may not be larger than {self.max_bytes} bytes.")
        await response(scope, receive, send)
```

- `RequestContextMiddleware` (known from chapter 01) now also copies `rate_headers` from the request state into the response.
- `SecurityHeadersMiddleware` adds `X-Content-Type-Options: nosniff` (browsers must not guess content types), `Cache-Control: no-store` (answers contain personal data), `Referrer-Policy: no-referrer`, `Cross-Origin-Resource-Policy: same-site`, and a Content-Security-Policy that forbids loading or framing anything (`default-src 'none'; frame-ancestors 'none'`). An API returns JSON, never pages, so the strictest policy is free. `/docs` is exempt because Swagger UI loads scripts. `Strict-Transport-Security` is added only when `ENABLE_HSTS=true`, because browsers remember it for a year and it is only valid behind HTTPS.
- `BodySizeLimitMiddleware` refuses a body larger than `MAX_BODY_BYTES`. It reads the `Content-Length` header first (cheap), and counts the bytes of chunked uploads that declare no length. Either way the answer is `413` and the excess is never parsed.

### Step 6. Wire everything
Replace `app/main.py`:

**File: `app/main.py`**
```python
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.db import Database
from app.db_errors import register_database_handlers
from app.errors import register_error_handlers
from app.logging_config import configure_logging
from app.middleware import BodySizeLimitMiddleware, RequestContextMiddleware, SecurityHeadersMiddleware
from app.ratelimit import FixedWindowLimiter
from app.routers import audit, comments, health, me, members, projects, tasks, teams, users
from app.tokens import JwksKeys, TokenVerifier


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    app.state.db = Database(settings.database_url, settings.db_pool_size, settings.db_max_overflow)
    app.state.limiter = FixedWindowLimiter(settings.rate_limit_window_seconds)
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
    app.add_middleware(BodySizeLimitMiddleware, max_bytes=settings.max_body_bytes)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
        allow_headers=["Authorization", "Content-Type", "If-Match", "If-None-Match", "Idempotency-Key"],
        expose_headers=["ETag", "Location", "RateLimit-Limit", "RateLimit-Remaining", "RateLimit-Reset",
                        "Retry-After", "Idempotent-Replayed", "X-Trace-Id"],
        max_age=600,
    )
    app.add_middleware(SecurityHeadersMiddleware, hsts=settings.enable_hsts)
    app.add_middleware(RequestContextMiddleware)  # added last, so it is the outermost layer and sees everything
    register_error_handlers(app)
    register_database_handlers(app)
    for module in (health, me, users, teams, members, projects, tasks, comments, audit):
        app.include_router(module.router)
    return app


app = create_app()
```

The order is the order of layers. `add_middleware` wraps what was added before it, so the **last** one added is the **outermost**: `RequestContextMiddleware` sees every request and response, including the 413 and the CORS answers. The CORS middleware answers browser **preflight** requests (`OPTIONS`) itself, before authentication, which is why a web client on `localhost:4200` can call the API at all. Credentials are not allowed (`allow_credentials` stays off): the API uses bearer tokens, not cookies, so there is no ambient authority for another site to abuse.

### Step 7. Harden the container
Replace `docker-compose.override.yml` (new: the docs setting, the limits, and the last block of restrictions):

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
      ENABLE_DOCS: "false"
      RATE_LIMIT_USER: "100"
      RATE_LIMIT_ANONYMOUS: "30"
      RATE_LIMIT_WINDOW_SECONDS: "60"
      MAX_BODY_BYTES: "1048576"
      CORS_ORIGINS: http://localhost:4200,http://localhost:5173
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "127.0.0.1:8000:8000"
    networks:
      - tasksteams
    restart: unless-stopped
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    pids_limit: 200
    mem_limit: 256m
    cpus: 1.0
```

| New line | Effect |
|----------|--------|
| `ENABLE_DOCS: "false"` | `/docs` and `/openapi.json` do not exist in the container (OWASP API9: no undocumented surface) |
| `RATE_LIMIT_*`, `MAX_BODY_BYTES`, `CORS_ORIGINS` | the limits are visible and changeable without a rebuild |
| `read_only: true` | the root file system cannot be written; a compromised process cannot drop files |
| `tmpfs: /tmp` | a small writable memory folder for libraries that need one |
| `cap_drop: [ALL]` | removes every Linux capability; a web service needs none |
| `security_opt: no-new-privileges:true` | a process can never gain more rights than it started with |
| `pids_limit: 200`, `mem_limit: 256m`, `cpus: 1.0` | one runaway service cannot starve the machine |

## Run it
Rebuild and start the stack:

```text
tasksteams-api> docker compose up -d --build --wait
```

**1. Conformance: all 18**

```text
tasksteams-api> python scripts/conformance.py
```

```text
PASS  keycloak discovery (issuer matches, PKCE S256 offered)
PASS  token for alice (iss, aud tasks-api, sub, role admin, three scopes)
PASS  token for bob (role member only)
PASS  postgres reachable (127.0.0.1:5432 answers the Postgres protocol)
PASS  health (200, status ok, no token needed)
PASS  me (alice is admin, RateLimit headers present)
PASS  create team (201, Location and ETag set, team 86e0a2da-69ef-4994-b059-0309c2fbe449)
PASS  create project (201, project 7b6500c7-d2fd-4575-98cc-f738db18b042)
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
18 passed, 0 failed
```

**2. Rate-limit and security headers on a normal answer**

```text
tasksteams-api> python scripts/call.py GET /v1/me --user alice
```

```text
HTTP/1.1 200 OK
date: Mon, 23 Nov 2026 09:09:23 GMT
content-length: 318
content-type: application/json
vary: Origin
x-content-type-options: nosniff
cache-control: no-store
referrer-policy: no-referrer
cross-origin-resource-policy: same-site
content-security-policy: default-src 'none'; frame-ancestors 'none'
x-trace-id: fcc18b29767f463fa1e8eee282edc1e8
ratelimit-limit: 100
ratelimit-remaining: 79
ratelimit-reset: 60

{"id":"a11ce000-0000-4000-8000-000000000001","username":"alice","email":"alice@tasksteams.test","displayName":"Alice Admin","roles":["admin"],"scopes":["email","openid","profile","tasks:admin","tasks:read","tasks:write"],"teams":[{"teamId":"7ea00000-0000-4000-8000-000000000001","name":"Platform Team","role":"lead"}]}
```

`ratelimit-remaining` is 79 here because the conformance script already used some of alice's 100 requests in this minute. `/health` is public and not counted:

```text
HTTP/1.1 200 OK
date: Mon, 23 Nov 2026 09:09:23 GMT
content-length: 49
content-type: application/json
vary: Origin
x-content-type-options: nosniff
cache-control: no-store
referrer-policy: no-referrer
cross-origin-resource-policy: same-site
content-security-policy: default-src 'none'; frame-ancestors 'none'
x-trace-id: 08ee29c1e7ff4be182339a0cd382033e

{"status":"ok","version":"1.0.0","database":"up"}
```

**3. The docs are gone**

```text
tasksteams-api> python scripts/call.py GET /docs
```

```text
HTTP/1.1 404 Not Found
date: Mon, 23 Nov 2026 09:09:36 GMT
content-length: 176
content-type: application/problem+json
vary: Origin
x-content-type-options: nosniff
cache-control: no-store
referrer-policy: no-referrer
cross-origin-resource-policy: same-site
x-trace-id: 61a788581d234bd4b7564cdccae526bb

{"type":"https://code101.example/problems/not-found","title":"Not found","status":404,"detail":"No such route.","instance":"/docs","traceId":"61a788581d234bd4b7564cdccae526bb"}
```

**4. CORS.** The browser sends a preflight before a cross-origin call. The allowed web origin gets its permissions; an unknown origin is refused:

```text
tasksteams-api> curl -s -i -X OPTIONS http://127.0.0.1:8000/v1/teams -H "Origin: http://localhost:4200" -H "Access-Control-Request-Method: POST" -H "Access-Control-Request-Headers: authorization,content-type"
```

```text
HTTP/1.1 200 OK
date: Mon, 23 Nov 2026 09:09:36 GMT
vary: Origin, Access-Control-Request-Method, Access-Control-Request-Headers, Access-Control-Request-Private-Network
access-control-allow-methods: GET, POST, PUT, PATCH, DELETE
access-control-max-age: 600
access-control-allow-headers: Accept, Accept-Language, Authorization, Content-Language, Content-Type, Idempotency-Key, If-Match, If-None-Match
access-control-allow-origin: http://localhost:4200
content-length: 2
content-type: text/plain; charset=utf-8
x-content-type-options: nosniff
cache-control: no-store
referrer-policy: no-referrer
cross-origin-resource-policy: same-site
content-security-policy: default-src 'none'; frame-ancestors 'none'
x-trace-id: 7145ef50a9cb40dd9a66f33a908d6289

OK
```

```text
tasksteams-api> curl -s -i -X OPTIONS http://127.0.0.1:8000/v1/teams -H "Origin: http://evil.example" -H "Access-Control-Request-Method: POST"
```

```text
HTTP/1.1 400 Bad Request
date: Mon, 23 Nov 2026 09:09:36 GMT
vary: Origin, Access-Control-Request-Method, Access-Control-Request-Headers, Access-Control-Request-Private-Network
access-control-allow-methods: GET, POST, PUT, PATCH, DELETE
access-control-max-age: 600
access-control-allow-headers: Accept, Accept-Language, Authorization, Content-Language, Content-Type, Idempotency-Key, If-Match, If-None-Match
content-length: 22
content-type: text/plain; charset=utf-8
x-content-type-options: nosniff
cache-control: no-store
referrer-policy: no-referrer
cross-origin-resource-policy: same-site
content-security-policy: default-src 'none'; frame-ancestors 'none'
x-trace-id: bcca7da982ad4d65bcbf2c4147dbef7f

Disallowed CORS origin
```

On Windows PowerShell write `curl.exe`.

**5. Latency.** The platform wants a p95 under 200 ms for reads on the seed data. Create `scripts/measure.py`, which times sequential requests:

**File: `scripts/measure.py`**
```python
#!/usr/bin/env python3
"""Time some sequential GET requests and print the median, the 95th percentile and the slowest.

  python scripts/measure.py /v1/projects/<project id>/tasks --user bob --count 25
"""
import argparse
import statistics
import time
import urllib.request

from call import API_URL, get_token


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("path")
    parser.add_argument("--user", default="bob")
    parser.add_argument("--count", type=int, default=25)
    args = parser.parse_args()
    headers = {"Authorization": f"Bearer {get_token(args.user)}"}
    milliseconds = []
    for _ in range(args.count):
        started = time.perf_counter()
        with urllib.request.urlopen(urllib.request.Request(API_URL + args.path, headers=headers)) as response:
            response.read()
        milliseconds.append((time.perf_counter() - started) * 1000)
    milliseconds.sort()
    p95 = milliseconds[min(len(milliseconds) - 1, int(len(milliseconds) * 0.95))]
    print(f"{args.count} requests to {args.path} as {args.user}: median {statistics.median(milliseconds):.1f} ms, "
          f"p95 {p95:.1f} ms, slowest {milliseconds[-1]:.1f} ms")


if __name__ == "__main__":
    main()
```

```text
tasksteams-api> python scripts/measure.py /v1/projects/9a000000-0000-4000-8000-000000000001/tasks --user bob --count 25
```

```text
25 requests to /v1/projects/9a000000-0000-4000-8000-000000000001/tasks as bob: median 6.0 ms, p95 7.1 ms, slowest 7.3 ms
```

(The numbers come from the author's Windows 11 machine with Docker Desktop; yours differ, the order of magnitude should not.)

**6. The rate limit (429).** Send 35 requests without a token. The limit for anonymous callers is 30 per minute; the first status lines are 401, then the limiter takes over:

```powershell
# Windows PowerShell
1..35 | ForEach-Object { (python scripts/call.py GET /v1/me)[0] }
```

```bash
# macOS and Linux
for i in $(seq 35); do python3 scripts/call.py GET /v1/me | head -1; done
```

```text
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 401 Unauthorized
HTTP/1.1 429 Too Many Requests
HTTP/1.1 429 Too Many Requests
HTTP/1.1 429 Too Many Requests
HTTP/1.1 429 Too Many Requests
HTTP/1.1 429 Too Many Requests
```

The first 30 answers are 401 and the last 5 are 429 (if you ran the conformance script less than a minute earlier, its one anonymous request also counts and the 429s start one request earlier). The next answer shows everything the client needs to back off: `retry-after`, the three `ratelimit-*` headers and the problem body:

```text
tasksteams-api> python scripts/call.py GET /v1/me
```

```text
HTTP/1.1 429 Too Many Requests
date: Mon, 23 Nov 2026 09:12:28 GMT
retry-after: 56
ratelimit-limit: 30
ratelimit-remaining: 0
ratelimit-reset: 56
content-length: 217
content-type: application/problem+json
vary: Origin
x-content-type-options: nosniff
cache-control: no-store
referrer-policy: no-referrer
cross-origin-resource-policy: same-site
content-security-policy: default-src 'none'; frame-ancestors 'none'
x-trace-id: 39dfe08d39904696bb27c254aeb2a48a

{"type":"https://code101.example/problems/rate-limited","title":"Too many requests","status":429,"detail":"Too many requests. Try again in 56 seconds.","instance":"/v1/me","traceId":"39dfe08d39904696bb27c254aeb2a48a"}
```

**7. The size limit (413).** Create a file of 1.2 MB and post it. The content does not matter; the body is refused before it is read as JSON:

```text
tasksteams-api> python -c "open('big.json', 'w').write('x' * 1200000)"
tasksteams-api> python scripts/call.py POST /v1/teams --user alice --body big.json
```

```text
HTTP/1.1 413 Content Too Large
date: Mon, 23 Nov 2026 09:12:28 GMT
content-length: 236
content-type: application/problem+json
vary: Origin
x-content-type-options: nosniff
cache-control: no-store
referrer-policy: no-referrer
cross-origin-resource-policy: same-site
content-security-policy: default-src 'none'; frame-ancestors 'none'
x-trace-id: b79a1f0d96b74f319fb72ef717826e34

{"type":"https://code101.example/problems/payload-too-large","title":"Payload too large","status":413,"detail":"The request body may not be larger than 1048576 bytes.","instance":"/v1/teams","traceId":"b79a1f0d96b74f319fb72ef717826e34"}
```

Delete `big.json` afterwards.

**8. The container is locked down**

```text
tasksteams-api> docker compose exec -T api sh -c "touch /srv/test.txt"
```

```text
touch: cannot touch '/srv/test.txt': Read-only file system
```

```text
tasksteams-api> docker compose exec -T api sh -c "touch /tmp/test.txt && echo tmp-ok"
```

```text
tmp-ok
```

```text
tasksteams-api> docker inspect tasksteams-api-api-1 --format "read-only: {{.HostConfig.ReadonlyRootfs}}, cap-drop: {{.HostConfig.CapDrop}}, security-opt: {{.HostConfig.SecurityOpt}}, memory: {{.HostConfig.Memory}}, pids: {{.HostConfig.PidsLimit}}"
```

```text
read-only: true, cap-drop: [ALL], security-opt: [no-new-privileges:true], memory: 268435456, pids: 200
```

**9. Security events in the log.** The refusals of the conformance run and of the flood above (first three lines shown). Find them with `docker compose logs api --no-log-prefix | grep "request refused"` on macOS and Linux, or `docker compose logs api --no-log-prefix | Select-String "request refused"` in PowerShell:

```text
{"time": "2026-11-23T09:09:23.401+00:00", "level": "WARNING", "logger": "tasksteams.security", "message": "request refused", "traceId": "efc97c2e88804bfeb001c1eff6ba1d8f", "event": "refused", "status": 401, "method": "GET", "path": "/v1/me", "userId": null, "detail": "A bearer access token is required."}
{"time": "2026-11-23T09:09:23.412+00:00", "level": "WARNING", "logger": "tasksteams.security", "message": "request refused", "traceId": "09ed306070b942a99d784bfa57779463", "event": "refused", "status": 403, "method": "GET", "path": "/v1/audit-log", "userId": "b0b00000-0000-4000-8000-000000000002", "detail": "The admin role is required."}
{"time": "2026-11-23T09:09:23.416+00:00", "level": "WARNING", "logger": "tasksteams.security", "message": "request refused", "traceId": "6b018193f57a49af8e17950ca324d295", "event": "refused", "status": 403, "method": "POST", "path": "/v1/teams", "userId": "b0b00000-0000-4000-8000-000000000002", "detail": "The admin role is required."}
```

Each line has the `event`, the status, the path and the `userId` (`null` before authentication). No token, no body, no query string, no e-mail address.

**10. Backup and restore.** A backup you never restored is a hope, not a backup. Dump the database **inside** the container to a file, then copy the file out (this avoids shell differences: Windows PowerShell 5.1 would write a redirected dump as UTF-16, which `psql` cannot read):

```text
tasksteams-api> docker compose exec -T db pg_dump -U tasks_admin --no-owner -f /tmp/backup.sql tasksteams
tasksteams-api> docker compose cp db:/tmp/backup.sql backup.sql
```

Restore it into a **new, empty** database next to the original and compare:

```text
tasksteams-api> docker compose exec -T db createdb -U tasks_admin restore_check
tasksteams-api> docker compose exec -T db psql -U tasks_admin -d restore_check -v ON_ERROR_STOP=1 -q -o /dev/null -f /tmp/backup.sql
tasksteams-api> docker compose exec -T db psql -U tasks_admin -d restore_check -tAc "SELECT (SELECT count(*) FROM users) || ' users, ' || (SELECT count(*) FROM tasks) || ' tasks, ' || (SELECT count(*) FROM audit_log) || ' audit rows'"
```

```text
3 users, 8 tasks, 34 audit rows
```

```text
tasksteams-api> docker compose exec -T db psql -U tasks_admin -d tasksteams -tAc "SELECT (SELECT count(*) FROM users) || ' users, ' || (SELECT count(*) FROM tasks) || ' tasks, ' || (SELECT count(*) FROM audit_log) || ' audit rows'"
```

```text
3 users, 8 tasks, 34 audit rows
```

The numbers match. Remove the practice database and the dump (`docker compose exec -T db dropdb -U tasks_admin restore_check`, delete `backup.sql`; it holds all your data), then clean up the whole stack with `docker compose down -v --remove-orphans --rmi local`.

## The OWASP API Security Top 10, walked through
| Risk (2023) | Where this code answers it | How you saw it work |
|-------------|----------------------------|---------------------|
| API1 Broken object level authorization | `app/access.py`: every project, task and comment resolves to a team; `team_access` answers 404 for non-members | chapter 02, run 8: bob gets 404 for the secret team |
| API2 Broken authentication | `app/tokens.py` (RS256 only, signature, `iss`, `aud`, `exp`, cached JWKS); `authenticate` counts failed attempts per client address | chapter 03: forged token gives 401; this chapter: anonymous flood gives 429 |
| API3 Broken object property level authorization | `app/schemas.py` (`extra="forbid"`, `nullable` per PATCH field); `update_columns` in `repositories/sql.py` allow-lists columns; `id`, `version`, timestamps are never bound from input | chapter 01: `colour` is refused with a pointer |
| API4 Unrestricted resource consumption | `limit` at most 100 (`pagination.py`), `MAX_BODY_BYTES` (413), rate limits (429), pool timeout of 5 s (`db.py`), container memory, pid and cpu limits | 429 and 413 above |
| API5 Broken function level authorization | scope plus role per route (`Reader`, `Writer`, `AdminWriter`, `AdminOnly` in `auth.py`); `Access.require_manage` for lead actions | conformance check `403 for member on admin route` |
| API6 Unrestricted access to sensitive business flows | admin-only team creation, `Idempotency-Key`, the last-lead rule (`routers/members.py`), per-user rate limit | chapter 02, runs 5 and 8 |
| API7 Server-side request forgery | the only outgoing request is the JWKS fetch from the configured `JWKS_URL`; PyJWT accepts only `http` and `https` addresses and does not follow redirects; no request data becomes a URL | `app/tokens.py` has no URL from input |
| API8 Security misconfiguration | security headers, CORS allow-list, docs off, no stack traces (500 and database errors use fixed sentences), non-root and read-only container, loopback ports, pinned image | steps 2 to 6 above |
| API9 Improper inventory management | one contract, `/v1` prefix, `ENABLE_DOCS=false` in the container, no debug routes | `/docs` answers 404 |
| API10 Unsafe consumption of APIs | the JWKS is parsed by PyJWT and token claims are type-checked in `principal_from_claims`; every SQL value is bound | `app/auth.py` |

Production checklist (what this lab deliberately leaves out): terminate TLS in front of the API and set `ENABLE_HSTS=true`; take `DATABASE_URL` and the database password from a secret store, create the `tasks_app` role there and not in a file; run Keycloak in production mode behind HTTPS with a real database; keep the rate limiter in a shared store when you run more than one replica; pin the base image by digest and rebuild regularly; scan images and dependencies; install packages with `pip install --require-hashes`; ship the JSON logs to a collector and alert on `event: refused` spikes; schedule backups, keep them off the host, and test a restore every month.

## How it works
Where each protection sits: the **edge** (middlewares) handles what needs no knowledge of the user: trace id, headers, CORS, size. The **door** (`authenticate`) handles identity: token, limit, scopes. The **rooms** (`access.py` and the stored functions) handle what a user may do with one object. A request must pass all three, and the cheapest checks come first, so abusive traffic is refused before it costs a database query.

New terms: **rate limit** (a cap on requests per time window); **fixed window** (the counter resets at fixed intervals); **CORS** (Cross-Origin Resource Sharing: the rules by which browsers let a page call another origin); **preflight** (the `OPTIONS` request a browser sends before a risky cross-origin call); **CSP** (Content-Security-Policy: what a page may load); **HSTS** (tell browsers to use HTTPS only); **capability** (a fine-grained Linux privilege); **security event** (a log line about a refused action).

Why this, not that:

| Choice | Alternative | Why we chose this |
|--------|-------------|-------------------|
| Limit in the application | Limit in a gateway or reverse proxy | The app knows the user id (a proxy only sees addresses) and the contract wants per-user limits. A gateway is still a good second layer, and the only place that can protect against floods before they reach Python |
| Fixed window | Sliding window, token bucket | Simplest to read and to test; the burst at a window boundary is a known price |
| `no-store` on every answer | Cache headers per route | Answers hold personal data; the ETag logic still works for conditional requests the client makes itself |
| `read_only` plus `tmpfs` | A writable container | An attacker who gets code execution cannot persist files; Python needs no writable folder because we set `PYTHONDONTWRITEBYTECODE` |
| Logs on stdout in JSON | Log files with rotation | The platform collects the stream; the app needs no write access |

## Try it
Exercise: **the arithmetic of the limiter.** Copy `exercise/starter/window.py` into a folder of your own and finish `decision`: when the window has passed start a new one, count this request, and return whether it is allowed, how many requests remain and how many seconds are left (rounded **up**, at least 1). Run `python window.py`; compare with the four lines below.

**File: `exercise/starter/window.py`**
```python
"""Exercise 5: the arithmetic of a fixed-window rate limiter.

Finish decision(). Run:  python window.py
"""
import math


def decision(window_start, now, count, limit, window):
    """`count` requests were already counted in the window that began at `window_start`; this is one more.

    Return (allowed, remaining, reset_seconds).
    """
    # TODO 1: when now - window_start >= window, a new window begins: window_start = now and count = 0
    # TODO 2: count this request (count + 1)
    # TODO 3: allowed is count <= limit; remaining is limit - count but never below 0;
    #         reset_seconds is the time left in the window, rounded UP (math.ceil), at least 1
    raise NotImplementedError


if __name__ == "__main__":
    cases = [
        ("first request:", 0, 0, 0, 100, 60),
        ("last allowed:", 0, 30, 99, 100, 60),
        ("over the limit:", 0, 30, 100, 100, 60),
        ("new window:", 0, 61, 100, 100, 60),
    ]
    for name, start, now, count, limit, window in cases:
        allowed, remaining, reset = decision(start, now, count, limit, window)
        print(f"{name:<16} allowed={allowed} remaining={remaining} reset={reset}")
```

<details><summary>Solution</summary>

**File: `exercise/solution/window.py`**
```python
"""Exercise 5: the arithmetic of a fixed-window rate limiter (solution).

Run:  python window.py
"""
import math


def decision(window_start, now, count, limit, window):
    """`count` requests were already counted in the window that began at `window_start`; this is one more.

    Return (allowed, remaining, reset_seconds).
    """
    if now - window_start >= window:
        window_start, count = now, 0
    count += 1
    reset = max(1, math.ceil(window - (now - window_start)))
    return count <= limit, max(0, limit - count), reset


if __name__ == "__main__":
    cases = [
        ("first request:", 0, 0, 0, 100, 60),
        ("last allowed:", 0, 30, 99, 100, 60),
        ("over the limit:", 0, 30, 100, 100, 60),
        ("new window:", 0, 61, 100, 100, 60),
    ]
    for name, start, now, count, limit, window in cases:
        allowed, remaining, reset = decision(start, now, count, limit, window)
        print(f"{name:<16} allowed={allowed} remaining={remaining} reset={reset}")
```

Output:

```text
first request:   allowed=True remaining=99 reset=60
last allowed:    allowed=True remaining=0 reset=30
over the limit:  allowed=False remaining=0 reset=30
new window:      allowed=True remaining=99 reset=60
```

Rounding the reset **up** means a client that waits exactly `Retry-After` seconds is never told to wait again by a fraction of a second.

</details>

## Check yourself
1. Why is the anonymous limit keyed by client address and the authenticated one by user id? <details><summary>Answer</summary>Before the token is verified, a user id in it cannot be trusted (anyone can write one); the address is what the connection proves. After verification the user id is the fair unit, because many users may share one address.</details>
2. Why does `BodySizeLimitMiddleware` count bytes as well as read `Content-Length`? <details><summary>Answer</summary>A client can send a chunked body with no length header, or lie about the length. Counting what actually arrives enforces the limit either way.</details>
3. What does `read_only: true` protect against, and what must you then provide? <details><summary>Answer</summary>It stops an attacker or a bug from writing files into the image's file system. Anything that must be written (here only `/tmp`) needs an explicit `tmpfs` or volume.</details>
4. Two API replicas each allow 100 requests per minute per user. What is the real limit and how do you fix it? <details><summary>Answer</summary>Up to 200 (the counters are per process). Use a shared store for the counters, or limit at a gateway that sees all traffic.</details>
5. What is the value of restoring a backup into a second database before you ever need it? <details><summary>Answer</summary>It proves that the dump is complete and that your commands work, while nothing depends on it. Finding out during a disaster is too late.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `429` with `"detail":"Too many requests. Try again in 48 seconds."` while testing | You used up the window (30 anonymous or 100 per user per 60 seconds) | Wait for `Retry-After` seconds, or raise `RATE_LIMIT_USER` in `docker-compose.override.yml` for a load test |
| `413` with `The request body may not be larger than 1048576 bytes.` | A body above `MAX_BODY_BYTES` | Send less data; raise the limit only if the contract needs it |
| A browser says the request was blocked by CORS, the preflight answers `400 Disallowed CORS origin` | The page's origin is not in `CORS_ORIGINS` | Add the exact origin (scheme, host and port) to `CORS_ORIGINS` and restart the container |
| `touch: cannot touch '/srv/test.txt': Read-only file system` | The container is read-only on purpose | Write only to `/tmp`, or mount a volume |
| `/docs` answers `{"type":".../not-found",...,"detail":"No such route."}` | `ENABLE_DOCS` is `false` in the container | Run the API on your computer with `ENABLE_DOCS=true` when you need the interactive docs |
| Restore with a PowerShell redirect fails with strange characters | Windows PowerShell 5.1 writes `>` output as UTF-16 | Use `pg_dump -f` inside the container and `docker compose cp`, as shown |
| Two replicas let more requests through than the limit | The limiter counts per process | Use a shared limiter or a gateway |

## Best practice
Defend in layers (edge, door, rooms), log refusals without secrets, run with the fewest privileges you can, and test your restore. Source: OWASP API Security Top 10 2023 https://owasp.org/API-Security/editions/2023/en/0x11-t10/ and Docker documentation, Docker security https://docs.docker.com/engine/security/

## Next lesson
You have a reference backend that passes all 18 conformance checks. Next: the web clients (`web-angular`, `web-react`) and the mobile clients (`mobile-flutter`, `mobile-kotlin`) that run against it, and the other backends (`backend-dotnet`, `backend-go`, `backend-rust`) that must pass the same script. Compare how each language solves the problems of chapters 02 and 03.
