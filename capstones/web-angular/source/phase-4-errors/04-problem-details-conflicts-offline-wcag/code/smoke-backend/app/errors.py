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
