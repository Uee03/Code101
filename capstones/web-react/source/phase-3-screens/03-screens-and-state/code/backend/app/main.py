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
