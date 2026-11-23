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
