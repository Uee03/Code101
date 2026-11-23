import json
import logging
import os
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

BUCKETS = (0.05, 0.1, 0.25, 0.5, 1.0)
ROUTES = {"/", "/slow", "/fail", "/healthz"}
LOCK = threading.Lock()
REQUESTS = {}
DURATIONS = {}


class JsonFormatter(logging.Formatter):
    def format(self, record):
        payload = {
            "time": self.formatTime(record, "%Y-%m-%dT%H:%M:%S"),
            "level": record.levelname,
            "message": record.getMessage(),
        }
        payload.update(getattr(record, "fields", {}))
        return json.dumps(payload)


def setup_logging():
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    logger = logging.getLogger("api")
    logger.setLevel(logging.INFO)
    logger.addHandler(handler)
    return logger


def setup_tracing():
    provider = TracerProvider(resource=Resource.create({"service.name": "code101-api"}))
    endpoint = os.environ.get("OTEL_EXPORTER_OTLP_ENDPOINT")
    if endpoint:
        exporter = OTLPSpanExporter(endpoint=endpoint + "/v1/traces")
        provider.add_span_processor(BatchSpanProcessor(exporter))
    trace.set_tracer_provider(provider)
    return trace.get_tracer("code101.api")


LOGGER = setup_logging()
TRACER = setup_tracing()


def record(path, status, seconds):
    label = path if path in ROUTES else "other"
    with LOCK:
        REQUESTS[(label, status)] = REQUESTS.get((label, status), 0) + 1
        entry = DURATIONS.setdefault(label, {"buckets": [0] * len(BUCKETS), "sum": 0.0, "count": 0})
        for index, bound in enumerate(BUCKETS):
            if seconds <= bound:
                entry["buckets"][index] += 1
        entry["sum"] += seconds
        entry["count"] += 1


def render_metrics():
    lines = [
        "# HELP app_requests_total Requests handled, by path and status.",
        "# TYPE app_requests_total counter",
    ]
    with LOCK:
        for (path, status), count in sorted(REQUESTS.items()):
            lines.append(f'app_requests_total{{path="{path}",status="{status}"}} {count}')
        lines.append("# HELP app_request_duration_seconds Request latency in seconds.")
        lines.append("# TYPE app_request_duration_seconds histogram")
        for path, entry in sorted(DURATIONS.items()):
            for bound, count in zip(BUCKETS, entry["buckets"]):
                lines.append(f'app_request_duration_seconds_bucket{{path="{path}",le="{bound}"}} {count}')
            lines.append(f'app_request_duration_seconds_bucket{{path="{path}",le="+Inf"}} {entry["count"]}')
            lines.append(f'app_request_duration_seconds_sum{{path="{path}"}} {entry["sum"]:.6f}')
            lines.append(f'app_request_duration_seconds_count{{path="{path}"}} {entry["count"]}')
    return "\n".join(lines) + "\n"


class Handler(BaseHTTPRequestHandler):
    def reply(self, status, body, content_type="application/json"):
        data = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def route(self, path):
        if path == "/":
            self.reply(200, json.dumps({"message": "ok"}))
            return 200
        if path == "/slow":
            time.sleep(0.3)
            self.reply(200, json.dumps({"message": "slow but ok"}))
            return 200
        if path == "/fail":
            self.reply(500, json.dumps({"error": "simulated failure"}))
            return 500
        if path == "/healthz":
            self.reply(200, json.dumps({"status": "alive"}))
            return 200
        self.reply(404, json.dumps({"error": "not found"}))
        return 404

    def do_GET(self):
        path = self.path.split("?")[0]
        if path == "/metrics":
            self.reply(200, render_metrics(), "text/plain; version=0.0.4; charset=utf-8")
            return
        started = time.perf_counter()
        with TRACER.start_as_current_span("GET " + path) as span:
            status = self.route(path)
            span.set_attribute("http.status_code", status)
            trace_id = format(span.get_span_context().trace_id, "032x")
        seconds = time.perf_counter() - started
        record(path, status, seconds)
        LOGGER.info("request", extra={"fields": {
            "path": path,
            "status": status,
            "duration_ms": round(seconds * 1000, 1),
            "trace_id": trace_id,
        }})

    def log_message(self, fmt, *args):
        pass


if __name__ == "__main__":
    LOGGER.info("starting", extra={"fields": {"port": 8080}})
    ThreadingHTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
