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
