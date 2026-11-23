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
