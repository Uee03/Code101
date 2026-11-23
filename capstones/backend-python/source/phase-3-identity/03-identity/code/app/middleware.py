import logging
import time
import uuid

from starlette.datastructures import MutableHeaders
from starlette.types import ASGIApp, Message, Receive, Scope, Send

from app.errors import problem_response
from app.logging_config import log_fields, trace_id_var

logger = logging.getLogger("tasksteams.access")


class RequestContextMiddleware:
    """Gives each request a trace id, writes one access log line and turns a crash into a 500 problem.

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
                MutableHeaders(scope=message)["X-Trace-Id"] = trace_id
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
