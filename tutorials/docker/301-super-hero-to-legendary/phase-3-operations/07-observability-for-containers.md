---
track: docker
level: 301
phase: 3
phase_name: operations
lesson: 07
title: Observability for containers - logs, metrics and traces with Prometheus, Grafana and an OpenTelemetry collector
time: 110 min
prerequisites: ["docker 301 lessons 01 to 06", "docker 201 lessons 05, 07", "docker 101 lesson 07"]
versions: { docker: "29.9.3 (inherited authoring baseline, not re-checked)", compose: "5.7.0 (inherited)", prometheus: "v3.16.0", grafana: "12.4.15", otel_collector: "0.165.0", otel_python_sdk: "1.45.2", python_image: "3.13-slim" }
verified: not yet run
source: source/docker/301-super-hero-to-legendary/phase-3-operations/07-observability-for-containers/
assets: []
---

# 07. Observability for containers - logs, metrics and traces with Prometheus, Grafana and an OpenTelemetry collector

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Explain what logs, metrics and traces each answer and why you need all three.
- Run a Compose stack with an instrumented service, Prometheus, Grafana and an OpenTelemetry collector, and read every configuration file in it.
- Query request rate, error ratio and p95 latency with PromQL, and explain why latency is a histogram and not an average.
- Name the failure modes of an observability stack (cardinality, log volume, lost telemetry, alert fatigue) and the measurement that exposes each.

## Recap
- Why did lesson 06 insist on honest readiness probes and per-version metrics for canaries? <details><summary>Answer</summary>A canary is only informative if you can compare its error rate and latency with the stable version's.</details>
- What does `init: true` fix? (lesson 03) <details><summary>Answer</summary>Signal handling and zombie reaping when the application would otherwise be process 1.</details>
- Which resource limits did lesson 03 recommend setting from measurements? <details><summary>Answer</summary>Memory, process count and CPU; this lesson is where the measurements come from.</details>

## Why it matters
Containers are short-lived and numerous. When one fails you cannot log in and look; the container may already be gone, replaced by a new one with a new name. **Observability** is the ability to ask new questions about a running system from the data it emits, without shipping new code. Three kinds of data answer three kinds of question. **Logs** say what happened in one event. **Metrics** say how much and how often, cheaply, over time, and drive alerts. **Traces** say where time went in one request across steps. An outage that starts with "something is slow" is only solvable if you can move between them: an alert (metric) leads to an affected request (trace) and to the exact error (log).

## What you will build
A Compose project with four services: `api` (a small Python service that writes JSON logs, exposes Prometheus metrics at `/metrics` and sends traces over OTLP), `otel-collector` (receives traces and prints them), `prometheus` (scrapes metrics, evaluates two alert rules) and `grafana` (a provisioned data source and dashboard). You will generate traffic, read the numbers by hand, find one request in the logs and in the collector's trace output by its trace id, and see an alert become pending.

## Before you start
- **Prerequisites:** Docker 301 lessons [01, threat model for containers](../phase-1-secure-supply-chain/01-threat-model-for-containers.md) to [06, Helm, Kustomize and rollouts](../phase-2-registries-and-orchestration/06-helm-kustomize-and-rollouts.md); Docker 201 lessons [05, Compose profiles](../../201-hero-to-super-hero/phase-2-compose-in-depth/05-profiles-overrides-extensions.md) and [07, networking and limits](../../201-hero-to-super-hero/phase-2-compose-in-depth/07-networking-and-limits.md); [Docker 101 lesson 07, healthchecks and cleanup](../../101-zero-to-hero/phase-2-compose/07-healthchecks-and-cleanup.md).
- Docker running; Compose; a browser; `curl` (Windows: `curl.exe`). No Python on the host.
- Time: 110 minutes. Two sittings: stop after Step 9 (stack running and checked) and do the dashboard and alert steps later.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/docker/301-super-hero-to-legendary/phase-3-operations/07-observability-for-containers/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Ports on loopback only: 8090 (api), 9090 (Prometheus), 3000 (Grafana). Stop other labs that use them. Nothing is published on 0.0.0.0.
- Images and versions were looked up on 2026-11-23 (tags and package versions only, nothing pulled or installed): `prom/prometheus:v3.16.0`, `grafana/grafana:12.4.15`, `otel/opentelemetry-collector:0.165.0`, and the Python packages `opentelemetry-sdk` and `opentelemetry-exporter-otlp-proto-http` at `1.45.2`. Tools in this ecosystem change configuration formats between releases: if a service refuses to start, read its log and the project's documentation for your version before you debug anything else.
- The Grafana password in `.env.example` is a public demonstration value. Choose your own in `.env`.

## What each signal is for
| Signal | Question | Cost | Weakness |
|---|---|---|---|
| Logs | What happened to this request or this event? | Storage grows with traffic | Hard to aggregate; free text varies |
| Metrics | Is the system healthy right now, and how is it trending? | Small, grows with label combinations | No detail about one request |
| Traces | Where did this request spend its time? | Grows with traffic unless sampled | Needs instrumentation and context passing |

Two frameworks tell you which metrics to chart first. **RED** for services: **R**ate (requests per second), **E**rrors (failed requests), **D**uration (latency). **USE** for resources: **U**tilisation, **S**aturation, **E**rrors of CPU, memory, disk, network. The service in this lesson exposes RED. Container-level USE data (CPU, memory per container) comes from the container runtime or a node-level collector such as cAdvisor or the Kubernetes kubelet; this stack does not include one, deliberately: such collectors need access to host files or the Docker socket, which lesson 01 treated as a risk. Lesson 08 uses `docker stats` and Kubernetes metrics for resource data.

## Steps

### Step 1. Make the lesson folder
**Terminal (PowerShell)**
```powershell
New-Item -ItemType Directory -Force "$HOME\code101\docker301\lesson07\code\app", "$HOME\code101\docker301\lesson07\code\prometheus", "$HOME\code101\docker301\lesson07\code\otel", "$HOME\code101\docker301\lesson07\code\grafana\provisioning\datasources", "$HOME\code101\docker301\lesson07\code\grafana\provisioning\dashboards", "$HOME\code101\docker301\lesson07\code\grafana\dashboards" | Out-Null
Set-Location "$HOME\code101\docker301\lesson07\code"
```

**Terminal (macOS/Linux)**
```bash
mkdir -p ~/code101/docker301/lesson07/code/{app,prometheus,otel,grafana/provisioning/datasources,grafana/provisioning/dashboards,grafana/dashboards}
cd ~/code101/docker301/lesson07/code
```
Expected result: no output; you are inside `code`, which now has six empty subfolders. All commands run here unless stated.

### Step 2. The instrumented service
**File: `app/app.py`**
```python
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
```
How it works, in the order it runs:
- **Imports and constants.** The `opentelemetry` imports are the standard OpenTelemetry Python SDK pieces (a tracer provider, an exporter that sends spans over HTTP, a batching processor). `BUCKETS` are the upper bounds in seconds of the latency histogram's buckets. `ROUTES` is the **allow list of path labels** (see "cardinality" below). `REQUESTS` and `DURATIONS` hold the metric state in memory; `LOCK` protects them because the server handles requests in several threads.
- **Logging.** `JsonFormatter` turns each log record into one JSON object per line: time, level, message and any extra `fields`. One line per event, machine-parsable, written to **standard output** (the container convention: the runtime collects it; the application never manages log files).
- **Tracing.** `setup_tracing` creates a tracer provider labelled with the resource attribute `service.name = code101-api` (how the backend names the service). If the environment variable `OTEL_EXPORTER_OTLP_ENDPOINT` is set, it adds a **batch** span processor that sends spans to `<endpoint>/v1/traces` in the background; the batching means a slow or absent collector does not slow requests, but spans may be dropped.
- **Metrics.** `record` counts a request by path label and status code, and updates the histogram: for each bucket whose bound is at least the observed duration it adds one (cumulative buckets, as Prometheus requires), plus a running sum and count. Any path that is not in `ROUTES` is recorded as `other`. `render_metrics` writes the **Prometheus text exposition format**: `# HELP` and `# TYPE` lines, then `name{label="value"} number` lines. The bucket for `le="+Inf"` always equals the total count.
- **The handler.** `reply` writes a response. `route` serves `/` (fast), `/slow` (sleeps 0.3 seconds), `/fail` (always status 500, a simulated failure) and `/healthz`; anything else is a 404. `do_GET` handles `/metrics` first (it is deliberately **not** counted), then for other paths starts a span named `GET <path>`, calls `route`, records the status on the span, reads the 32-character hexadecimal trace id, measures the duration, updates the metrics and writes one log line containing path, status, duration and the **trace id**. That id is the link between a log line and a trace.
- `log_message` is overridden to do nothing, so the default plain-text access log does not duplicate our JSON log.

**File: `app/requirements.txt`**
```text
opentelemetry-sdk==1.45.2
opentelemetry-exporter-otlp-proto-http==1.45.2
```
Both packages pinned to one version. This pins direct dependencies only; their own dependencies float. For a production build pin everything with hashes (`pip install --require-hashes` or a lock file from a tool such as `uv`; Docker 201 covered build inputs) so lesson 02's reproducibility argument holds.

**File: `app/Dockerfile`**
```dockerfile
FROM python:3.13-slim
ENV PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1
RUN useradd --system --uid 10001 --no-create-home --shell /usr/sbin/nologin app
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .
USER 10001:10001
EXPOSE 8080
CMD ["python", "app.py"]
```
- `PYTHONUNBUFFERED=1` flushes output at once; `PIP_NO_CACHE_DIR=1` keeps pip's download cache out of the image layer.
- `COPY requirements.txt .` then `RUN pip install ...` **before** copying `app.py`: the install layer is cached until the requirements change, so editing code does not reinstall packages.
- The rest is the usual non-root pattern.

**File: `app/.dockerignore`**
```text
__pycache__
*.pyc
```

### Step 3. The Compose file
**File: `docker-compose.yml`**
```yaml
name: code101-observability
services:
  api:
    build: ./app
    image: code101/observability-api:1.0.0
    environment:
      OTEL_EXPORTER_OTLP_ENDPOINT: http://otel-collector:4318
    ports:
      - "127.0.0.1:8090:8080"
    depends_on:
      - otel-collector
    init: true
    read_only: true
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
  otel-collector:
    image: otel/opentelemetry-collector:0.165.0
    command: ["--config=/etc/otelcol/config.yaml"]
    volumes:
      - ./otel/collector-config.yaml:/etc/otelcol/config.yaml:ro
  prometheus:
    image: prom/prometheus:v3.16.0
    command:
      - --config.file=/etc/prometheus/prometheus.yml
      - --storage.tsdb.path=/prometheus
      - --storage.tsdb.retention.time=7d
    volumes:
      - ./prometheus:/etc/prometheus:ro
      - prometheus-data:/prometheus
    ports:
      - "127.0.0.1:9090:9090"
  grafana:
    image: grafana/grafana:12.4.15
    environment:
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_ADMIN_PASSWORD:?Set GRAFANA_ADMIN_PASSWORD in .env}
      GF_USERS_ALLOW_SIGN_UP: "false"
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
      - ./grafana/dashboards:/etc/grafana/dashboards:ro
      - grafana-data:/var/lib/grafana
    ports:
      - "127.0.0.1:3000:3000"
    depends_on:
      - prometheus
volumes:
  prometheus-data:
  grafana-data:
```
Line by line:
- `name:` is the project name. Services reach each other by **service name** on the project network (`otel-collector`, `api`, `prometheus`), as in Docker 101 lesson 06.
- `api`: `build: ./app` builds the Dockerfile in `app/`; `OTEL_EXPORTER_OTLP_ENDPOINT` is the standard OpenTelemetry environment variable naming the collector's HTTP endpoint (port 4318 is the OTLP/HTTP default). The port line publishes 8090 on loopback. `depends_on` starts the collector first; it only controls start **order**, not readiness, and the batch processor tolerates a collector that is not ready yet. `init`, `read_only`, `cap_drop` and `security_opt` are lesson 03 (the service writes no files, so no `tmpfs` is needed).
- `logging` selects the `json-file` log driver and rotates: each log file at most 10 MB, at most 3 files. **Without these options the default driver keeps growing log files** until the disk is full, one of the commonest container outages.
- `otel-collector`: the **core** distribution image. `command` passes the one flag it needs; the configuration file is mounted read-only at the path named there. No port is published: only other containers on the project network (the API) need to reach it.
- `prometheus`: `command` replaces the image's default arguments, so every flag we need is listed: the configuration file, the data directory `/prometheus` (a named volume) and `--storage.tsdb.retention.time=7d` (keep samples for seven days; without a limit, the default is 15 days, and storage grows with it). `./prometheus:/etc/prometheus:ro` mounts both the main configuration and the alert rules file. The UI is published on loopback only: it has no authentication of its own.
- `grafana`: `GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_ADMIN_PASSWORD:?...}` takes the password from the `.env` file and **stops Compose with the given message if it is missing** (the `:?` form). `GF_USERS_ALLOW_SIGN_UP: "false"` disables self sign-up. The provisioning and dashboard folders are mounted read-only; `grafana-data` keeps users and state.
- Top-level `volumes:` declares the two named volumes. Removing them (`down -v`) deletes stored metrics and Grafana state.

**File: `.env.example`**
```text
GRAFANA_ADMIN_PASSWORD=change-me-demo-only
```
**File: `.gitignore`**
```text
.env
```
Create your real settings file by copying the example (Windows PowerShell: `Copy-Item .env.example .env`; macOS/Linux: `cp .env.example .env`). The `.gitignore` line keeps `.env` out of Git; commit only `.env.example`.

### Step 4. Prometheus configuration and alert rules
**File: `prometheus/prometheus.yml`**
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
rule_files:
  - /etc/prometheus/alerts.yml
scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ["localhost:9090"]
  - job_name: code101-api
    metrics_path: /metrics
    static_configs:
      - targets: ["api:8080"]
```
- Prometheus **pulls**: every `scrape_interval` it fetches the text from each target. `evaluation_interval` is how often alert rules are checked. Shorter intervals give finer detail and cost more storage and CPU; 15 seconds is a common starting point.
- `rule_files` lists rule files (the path is inside the container).
- Two scrape jobs: Prometheus scrapes itself (`localhost:9090`) and the API at `api:8080`, the Compose service name and the container's own port (not the published 8090). Each target automatically gets a metric `up` that is 1 when the last scrape worked and 0 when it failed.

**File: `prometheus/alerts.yml`**
```yaml
groups:
  - name: code101-api
    rules:
      - alert: ApiDown
        expr: up{job="code101-api"} == 0
        for: 1m
        labels:
          severity: page
        annotations:
          summary: "code101-api target is down"
      - alert: ApiHighErrorRatio
        expr: sum(rate(app_requests_total{status=~"5.."}[5m])) / sum(rate(app_requests_total[5m])) > 0.05
        for: 5m
        labels:
          severity: page
        annotations:
          summary: "More than 5 percent of requests fail with 5xx"
```
- A rule has an `alert` name, an `expr` (a **PromQL** expression: the alert is active while it returns any value), a `for` duration (it must stay true that long before it fires, which suppresses blips), `labels` (used for routing) and `annotations` (text for humans).
- `ApiDown`: the scrape has failed for a minute.
- `ApiHighErrorRatio`: `rate(x[5m])` is the per-second increase of a counter averaged over five minutes; `status=~"5.."` is a regular-expression match for any 5xx; the division is "failed requests per second over all requests per second". This is a **symptom** alert (users see errors) rather than a **cause** alert (CPU is high). Symptom alerts page for things that matter; cause alerts create noise.
- **Honest limit:** this stack has no Alertmanager, so alerts appear in the Prometheus UI (state `pending`, then `firing`) but nobody is notified. A real system adds Alertmanager (routing, grouping, silencing, on-call integration) or the equivalent in a hosted service.

### Step 5. The OpenTelemetry collector
**File: `otel/collector-config.yaml`**
```yaml
receivers:
  otlp:
    protocols:
      http:
        endpoint: 0.0.0.0:4318
processors:
  memory_limiter:
    check_interval: 1s
    limit_mib: 128
  batch:
    timeout: 2s
exporters:
  debug:
    verbosity: detailed
service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [debug]
```
- The collector is a pipeline: **receivers** accept data, **processors** transform it, **exporters** send it on, and `service.pipelines` wires them per signal. This one has a single `traces` pipeline.
- `otlp` receiver, `http` protocol on `0.0.0.0:4318`. Recent collector versions listen on localhost only by default; `0.0.0.0` inside the container is required so the API container can reach it, and it is safe here because no host port is published.
- `memory_limiter` starts refusing data when the collector approaches 128 MiB, checked every second: a collector that dies of memory exhaustion takes all telemetry down with it. It must come **first** in the processor list. `batch` groups spans and sends them every 2 seconds, which is far cheaper than sending one by one.
- The `debug` exporter writes what it receives to the collector's own standard output, with `detailed` verbosity (full span information). **It is a learning tool.** A real deployment replaces it with an exporter to a trace backend (an OTLP endpoint of Tempo, Jaeger or a hosted service). Using a collector instead of sending straight from the app means you can change backends, add sampling or redact data centrally without redeploying every service.

### Step 6. Grafana provisioning
**File: `grafana/provisioning/datasources/prometheus.yml`**
```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    uid: prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
```
- **Provisioning** means Grafana reads configuration files at start-up instead of you clicking in the UI, so the setup is repeatable and reviewable.
- `uid: prometheus` is a fixed identifier that dashboards refer to. `access: proxy` makes Grafana's server call Prometheus (rather than your browser). `url` uses the Compose service name. `editable: false` stops changes in the UI that the next restart would silently revert.

**File: `grafana/provisioning/dashboards/dashboards.yml`**
```yaml
apiVersion: 1
providers:
  - name: code101
    folder: Code101
    type: file
    disableDeletion: true
    updateIntervalSeconds: 30
    options:
      path: /etc/grafana/dashboards
```
- A dashboard **provider** tells Grafana to load JSON dashboards from a folder (`path`, inside the container) into a Grafana folder named `Code101`, re-reading every 30 seconds. `disableDeletion: true` prevents deleting provisioned dashboards from the UI.

**File: `grafana/dashboards/app-overview.json`**
```json
{
  "uid": "code101-api",
  "title": "Code101 API overview",
  "schemaVersion": 39,
  "version": 1,
  "refresh": "10s",
  "time": {"from": "now-15m", "to": "now"},
  "panels": [
    {
      "id": 1,
      "type": "timeseries",
      "title": "Requests per second by path",
      "datasource": {"type": "prometheus", "uid": "prometheus"},
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
      "targets": [
        {"refId": "A", "expr": "sum by (path) (rate(app_requests_total[1m]))", "legendFormat": "{{path}}"}
      ]
    },
    {
      "id": 2,
      "type": "timeseries",
      "title": "p95 latency (seconds)",
      "datasource": {"type": "prometheus", "uid": "prometheus"},
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
      "targets": [
        {"refId": "A", "expr": "histogram_quantile(0.95, sum by (le) (rate(app_request_duration_seconds_bucket[1m])))", "legendFormat": "p95"}
      ]
    },
    {
      "id": 3,
      "type": "stat",
      "title": "5xx ratio",
      "datasource": {"type": "prometheus", "uid": "prometheus"},
      "gridPos": {"h": 6, "w": 8, "x": 0, "y": 8},
      "fieldConfig": {"defaults": {"unit": "percentunit"}, "overrides": []},
      "targets": [
        {"refId": "A", "expr": "sum(rate(app_requests_total{status=~\"5..\"}[1m])) / sum(rate(app_requests_total[1m]))"}
      ]
    }
  ]
}
```
- Top level: a fixed `uid` and `title`, `refresh` every 10 seconds, a default time range of the last 15 minutes. `schemaVersion` is the dashboard format version; Grafana upgrades older formats when it loads them.
- Each panel has an `id`, a `type`, a `title`, the data source by its fixed `uid`, a `gridPos` (height `h`, width `w` on a 24-column grid, and position `x`, `y`) and one or more `targets`, each a PromQL expression.
- Panel 1 shows requests per second per path. Panel 2 shows the 95th-percentile latency: `rate(..._bucket[1m])` per bucket, summed across paths while keeping the `le` (less-or-equal) label, then `histogram_quantile(0.95, ...)` estimates the value below which 95 percent of requests fall. Panel 3 shows the share of requests that fail with 5xx as a percentage (`percentunit` shows 0 to 1 as 0 to 100 percent).
- I wrote this dashboard by hand to keep it readable. Dashboards usually start as exports from the UI; if Grafana rejects a field in your version, export a dashboard from the UI and compare.

**Why a histogram, not an average:** an average latency of 100 ms can hide a tail where 5 percent of requests take two seconds. The histogram counts requests in latency buckets, so you can compute any percentile later and **aggregate across many containers** (you can add bucket counts together; you cannot meaningfully average averages or add percentiles). The price is that percentile accuracy depends on the bucket boundaries you chose: choose them around your latency target.

### Step 7. Check the configuration before you start
Validate before running: it catches typos in seconds. Use the same images as the stack.

**Terminal (PowerShell; folder: `code`)**
```powershell
docker run --rm --entrypoint promtool -v "${PWD}/prometheus:/etc/prometheus:ro" prom/prometheus:v3.16.0 check config /etc/prometheus/prometheus.yml
docker run --rm -v "${PWD}/otel/collector-config.yaml:/etc/otelcol/config.yaml:ro" otel/opentelemetry-collector:0.165.0 validate --config=/etc/otelcol/config.yaml
```
macOS/Linux: replace `${PWD}` with `"$PWD"`. Expected output of the first command (typical wording of `promtool`; not yet run):
```text
Checking /etc/prometheus/prometheus.yml
  SUCCESS: 1 rule files found
 SUCCESS: /etc/prometheus/prometheus.yml is valid prometheus config file syntax

Checking /etc/prometheus/alerts.yml
  SUCCESS: 2 rules found
```
The collector's `validate` command prints nothing on success and exits with code 0 (check with `$LASTEXITCODE` in PowerShell or `echo $?` in bash); on failure it prints the error. (The first run pulls both images.)

### Step 8. Start the stack
**Terminal (any OS; folder: `code`)**
```bash
docker compose up -d --build
docker compose ps
```
Expected result (not yet run): four services in the `ps` table, each `running` (or `Up`). The first run builds the API image and pulls the three others, which takes a few minutes. If `grafana` is missing, read `docker compose logs grafana`; a missing `.env` stops Compose with the message `Set GRAFANA_ADMIN_PASSWORD in .env`.

### Step 9. Produce data and read it by hand
Send one request, then read the metrics text.

**Terminal (PowerShell; folder: `code`)**
```powershell
curl.exe -s http://127.0.0.1:8090/
curl.exe -s http://127.0.0.1:8090/metrics
```
macOS/Linux: `curl` instead of `curl.exe`. Expected output of the first command (derived from the code; not yet run):
```text
{"message": "ok"}
```
The second command prints the metrics text. The lines for one request to `/` are (excerpt; the bucket lines in between and the `_sum` value depend on how long the request took):
```text
app_requests_total{path="/",status="200"} 1
app_request_duration_seconds_count{path="/"} 1
```
Now generate a realistic mix: 20 fast requests, 20 slow ones and 20 failures.

**Terminal (PowerShell; folder: `code`)**
```powershell
1..20 | ForEach-Object { curl.exe -s -o NUL http://127.0.0.1:8090/ ; curl.exe -s -o NUL http://127.0.0.1:8090/slow ; curl.exe -s -o NUL http://127.0.0.1:8090/fail }
```
**Terminal (macOS/Linux; folder: `code`)**
```bash
for i in $(seq 1 20); do curl -s -o /dev/null http://127.0.0.1:8090/; curl -s -o /dev/null http://127.0.0.1:8090/slow; curl -s -o /dev/null http://127.0.0.1:8090/fail; done
```
**Predict first:** what will the three `app_requests_total` lines say now? (Counts are cumulative: `/` has 21 requests in total including Step 9's first one.) Then read them:

**Terminal (PowerShell; folder: `code`)**
```powershell
curl.exe -s http://127.0.0.1:8090/metrics | Select-String "app_requests_total"
```
macOS/Linux: `curl -s http://127.0.0.1:8090/metrics | grep app_requests_total`. Expected output (derived from the code; not yet run):
```text
# HELP app_requests_total Requests handled, by path and status.
# TYPE app_requests_total counter
app_requests_total{path="/",status="200"} 21
app_requests_total{path="/fail",status="500"} 20
app_requests_total{path="/slow",status="200"} 20
```
(Rows are sorted by path.) On a quiet machine every `/slow` request takes about 0.3 seconds, so its `le="0.25"` bucket count should be 0 and its `le="0.5"` count 20; verify this in the output yourself and, if your numbers differ, work out why (a loaded machine can push requests past 0.5 seconds).

### Step 10. Logs, traces and the link between them
**Terminal (any OS; folder: `code`)**
```bash
docker compose logs api
```
Expected output (not yet run; the `time` and `duration_ms` values and trace ids differ; the key order is fixed by the code): one JSON object per request, for example:
```text
{"time": "<date>T<time>", "level": "INFO", "message": "request", "path": "/", "status": 200, "duration_ms": <number>, "trace_id": "<32 hexadecimal characters>"}
```
(Compose prefixes each line with the service name.) Copy the `trace_id` of one `/fail` line. Now look at the collector's output, which receives the spans two seconds after the batch fills or times out:

**Terminal (any OS; folder: `code`)**
```bash
docker compose logs otel-collector
```
Expected result (not yet run): detailed span records. In the `debug` exporter's detailed format each span lists its trace id, name (`GET /fail`) and attributes (including `http.status_code`). Search the output for the trace id you copied; the exact layout depends on the collector version. **That is the point:** one id ties together the log line, the span and (in a real backend) the whole request path. In a multi-service system the id travels between services in a request header (the W3C `traceparent` header) so that each service's spans join the same trace; this demo has one service, so there is nothing to propagate.

### Step 11. Prometheus and Grafana
Open the Prometheus UI at `http://127.0.0.1:9090`. In **Status > Targets** both jobs should show `UP` after the first scrape (within about 15 seconds). On the **Graph** page run these queries (each is an expression you can type):
```text
up
sum by (path) (rate(app_requests_total[1m]))
histogram_quantile(0.95, sum by (le) (rate(app_request_duration_seconds_bucket[1m])))
```
Expected result (not yet run): `up` returns 1 for both jobs; the rate query shows one series per path (values near zero if the loop finished more than a minute ago, because `rate` looks at a window); the third returns a single latency number. If a query returns nothing, check the range: `rate` over `[1m]` needs at least two scrapes inside the window.

Open Grafana at `http://127.0.0.1:3000`, log in as `admin` with the password from your `.env`, and open **Dashboards > Code101 > Code101 API overview**. Run the traffic loop again and watch the panels update; the 5xx stat shows the failing share (about one third while the loop runs, because one request in three goes to `/fail`).

Now the alert. With the loop's 33 percent failures the `ApiHighErrorRatio` expression is true. Repeat the loop for several minutes (run it a few times), then open **Alerts** in the Prometheus UI: the rule is `Pending` while the condition has held for less than five minutes and `Firing` after that. Remember: nothing is notified.

### Step 12. Clean up
**Terminal (any OS; folder: `code`)**
```bash
docker compose down -v
docker image rm code101/observability-api:1.0.0
```
`down -v` removes the containers, the network **and the two volumes**, deleting stored metrics and Grafana state. The lab images from Docker Hub remain in your image cache; remove them if you need the space.

## How it works
Follow one request through all three signals. The request reaches `do_GET`. A **span** starts, the handler runs, the span ends and is queued for export; the batch processor sends it to the collector, which prints it. In the same call the **metrics** are updated in memory, and Prometheus copies them every 15 seconds. Finally a **log** line is written with the trace id. Three different pipelines, three different storage costs and retention, one shared identifier.

Misconceptions to correct. First, "metrics, logs and traces are three tools for the same job": they have different costs and questions, and each one is a poor substitute for the others. Second, "more data means more observability": cost and noise grow with data; the skill is choosing what to keep. Third, "Grafana stores my metrics": Grafana draws charts; Prometheus stores the data. If Prometheus's volume is lost, so is the history.

## Decision record (ADR-07): what we collect, keep and alert on
- **Context:** the platform runs a dozen services; incidents are detected by customers; logs are free text in files on each host; nobody can say what normal latency is.
- **Decision:** every service writes one JSON log line per request to standard output with a trace id, exposes RED metrics with a **bounded** label set, and sends traces to a collector with sampling configured centrally. Page-level alerts are symptoms only (error ratio, latency against the objective, instance down). Cause metrics (CPU, memory, queue depth) are on dashboards and ticket-level alerts.
- **Consequences:** engineers must add instrumentation to every new service (a shared library helps); label review becomes part of code review; the platform team owns storage, retention and the cost of the stack.
- **Alternatives rejected:** a hosted all-in-one service (valid; chosen only if the team cannot run the stack, at the cost of per-volume pricing and data leaving the network); logs only (cannot answer rate or latency questions cheaply); alert on every metric (alert fatigue).
- **Revisit when:** the telemetry bill or the on-call load grows faster than traffic.

## When not to use this
- Do not run this exact stack in production. It has no Alertmanager, no authentication, no long-term storage, no high availability and a debug exporter for traces. It teaches the parts.
- Do not self-host the whole stack if nobody will operate it: storage, upgrades and backups are real work. A hosted backend with the same OpenTelemetry instrumentation is a legitimate choice; the instrumentation is the portable part.
- Do not add tracing to a single-process program with no downstream calls and expect value; logs and metrics are enough until requests cross services.
- Do not mount the Docker socket into a metrics agent just to get container metrics (lesson 01). Prefer the kubelet, the runtime's own metrics endpoint or a node agent with reviewed permissions.

## Failure modes
- **Label cardinality explosion:** a label with unbounded values (user id, full URL path with ids, request id) creates a new time series for every value; memory and disk grow until Prometheus is killed. This is why the app maps unknown paths to `other`. Count your series (`prometheus_tsdb_head_series`) and review every new label.
- **Log volume:** debug logs in production and no rotation fill disks. This stack caps each container's log at about 30 MB (3 files of 10 MB).
- **Sensitive data in logs and traces:** tokens, personal data and SQL parameters leak into long-lived stores. Redact at the source and in the collector; never log secrets.
- **Lost telemetry:** a down collector or a full queue silently drops spans. Observability data is best-effort by design; alert on the collector's own health and queue drops in production, and never let telemetry block requests.
- **Averages that lie:** dashboards showing mean latency hide the tail. Show percentiles from histograms.
- **Alert fatigue:** too many pages teach people to ignore them. Every page must be actionable and about a user-visible symptom.
- **Alerts nobody receives:** rules without a notification path (this lesson's state) are a decoration.
- **Clock skew and gaps:** missing scrapes during restarts produce gaps and wrong rates; use `rate` over windows several times the scrape interval.
- **Retention surprises:** a seven-day limit means last month's incident cannot be investigated. Decide retention from your investigation needs and cost, then measure the disk it uses.
- **Wrong place to measure:** the app reports its own latency, not what the user experiences. Add a probe or edge measurement for the full path.

## Measurements to take
- Number of active time series (`prometheus_tsdb_head_series`) and its growth after each release.
- Prometheus disk usage per day and the retention it supports (`docker system df -v` shows volume sizes).
- Log lines and bytes per service per day.
- Fraction of spans dropped, and the trace sampling rate you actually use.
- Alert counts per week, the share that were actionable, and time to acknowledge.
- Time to detect an injected failure (run the `/fail` loop and note when the alert would reach a person in your real setup).

## Production checklist
- [ ] Every service logs structured lines to standard output; no secrets in logs; log rotation configured.
- [ ] RED metrics per service with a reviewed, bounded label set; latency as histograms with buckets around the objective.
- [ ] Traces sent through a collector with a memory limiter, sampling and redaction rules; the backend is not the debug exporter.
- [ ] Alertmanager (or equivalent) routes pages to a person; every page alert has a runbook (lesson 09).
- [ ] Prometheus and Grafana require authentication, are not exposed beyond the operations network, and are backed up or reproducible.
- [ ] Retention and storage sizes decided from measurements; series count monitored.
- [ ] Dashboards and rules are in version control and provisioned, not hand-edited in the UI.
- [ ] The observability stack itself is monitored.

## Try it
Work in a folder `exercise` next to `code`. Copy the starter rule file there.

**File: `exercise/slow-alert.yml` (starter)**
```yaml
groups:
  - name: code101-api-exercise
    rules:
      - alert: ApiSlowP95
        # TODO: replace expr with a query that is true when the 95th percentile
        # latency of all paths, measured over 5 minutes, is above 0.5 seconds.
        expr: vector(0) > 1
        for: 5m
        labels:
          severity: ticket
        annotations:
          summary: "p95 latency is above 500 ms"
```
1. **Guided:** replace the `expr`. Check the file with `promtool` (the expected result is `SUCCESS: 1 rules found`): run `docker run --rm --entrypoint promtool -v "${PWD}/exercise:/rules:ro" prom/prometheus:v3.16.0 check rules /rules/slow-alert.yml` from `code` (macOS/Linux: `"$PWD"`), adjusting the folder to where you saved the file.
2. **Change:** to load the rule into the running stack, copy the file into `code/prometheus/` as `slow-alert.yml`, add `- /etc/prometheus/slow-alert.yml` to `rule_files` in `prometheus.yml`, and restart Prometheus with `docker compose restart prometheus`. **Predict:** with only the `/slow` and `/` requests of your loop (0.3 seconds each), will this alert fire? (No: p95 stays below 0.5 seconds. Change `/slow` in `app.py` to sleep 0.8 seconds, rebuild and see it become pending.)
3. **Stretch (no single answer):** write an objective for the API in one sentence ("99 percent of `/` requests succeed within 300 ms over 30 days") and decide which of the three signals measures it, which alert would page on it, and what error budget that leaves per month. Explain why you would not page on a single failed request.

<details><summary>Solution</summary>

**File: `exercise/solution/slow-alert.yml`**
```yaml
groups:
  - name: code101-api-exercise
    rules:
      - alert: ApiSlowP95
        expr: histogram_quantile(0.95, sum by (le) (rate(app_request_duration_seconds_bucket[5m]))) > 0.5
        for: 5m
        labels:
          severity: ticket
        annotations:
          summary: "p95 latency is above 500 ms"
```
The expression sums the per-bucket rates across all paths (keeping `le`), then estimates the 95th percentile. Because the histogram's highest finite bucket in this app is 1.0 second, a p95 above 1 second is reported as 1.0: the estimate cannot go past the last bucket, which is another reason to choose bucket bounds around your objective. For the stretch: a request-based objective is measured by the metrics (counts and the histogram); the page fires when the error budget is being consumed too fast (a burn-rate alert) rather than on any single failure; a 99 percent objective over 30 days leaves about 1 percent of requests as budget, which is about 7.2 hours of total failure time if you express it as time; one failed request is expected noise and not worth waking anyone.

</details>

## Check yourself
1. Which signal would you use to find out why one specific request was slow? <details><summary>Answer</summary>The trace (and the log line with the same trace id) for that request.</details>
2. Predict: you add a metric label `user_id` with 100,000 distinct users. What happens? <details><summary>Answer</summary>Up to 100,000 times more time series for that metric: memory and disk grow sharply (cardinality explosion). Put user ids in logs or traces, not metric labels.</details>
3. Why does the Compose file set `max-size` and `max-file`? <details><summary>Answer</summary>Without them the default log driver lets log files grow without limit and can fill the host's disk.</details>
4. Why is `ApiHighErrorRatio` a better page than "CPU above 80 percent"? <details><summary>Answer</summary>It measures what users experience (failed requests); high CPU may be harmless or may not coincide with any user impact.</details>
5. What is the difference between `Pending` and `Firing`? <details><summary>Answer</summary>Pending means the expression is true but has not yet been true for the whole `for` duration; firing means it has.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Set GRAFANA_ADMIN_PASSWORD in .env` (the message in the Compose file) | No `.env` file | Copy `.env.example` to `.env` |
| Target `code101-api` is `DOWN` in Prometheus | The API crashed or the target name is wrong | `docker compose logs api`; the target must be `api:8080` |
| `port is already allocated` (typical wording) | 8090, 9090 or 3000 is in use | Stop the other lab or process |
| The Grafana panels say "No data" | No traffic in the time range, or the data source is unreachable | Run the traffic loop; check the data source (Connections) |
| The `up` query is empty | Prometheus has not scraped yet | Wait 15 seconds; check **Status > Targets** |
| `docker run ... promtool ... no such file` (typical wording) | The folder is not mounted at the path you check | Run from `code` and keep `${PWD}/prometheus` |
| Collector log shows connection errors at start | The API started before the collector accepted connections | Batched spans are retried; wait and send new requests |
| `curl.exe -o NUL` creates a file named `NUL` on macOS/Linux | The Windows form was used | Use `-o /dev/null` |

## Best practice
Instrument with a vendor-neutral standard, emit structured logs to standard output, keep metric labels bounded, page on symptoms, and keep the stack's own configuration in version control. Source: OpenTelemetry documentation (project documentation, not a Tier 1 source) https://opentelemetry.io/docs/ and Docker documentation, JSON File logging driver https://docs.docker.com/engine/logging/drivers/json-file/

## Going further
- Prometheus documentation (project): https://prometheus.io/docs/introduction/overview/
- Grafana provisioning (project): https://grafana.com/docs/grafana/latest/administration/provisioning/
- OpenTelemetry Collector configuration (project): https://opentelemetry.io/docs/collector/configuration/
- Docker logging drivers: https://docs.docker.com/engine/logging/configure/
- Kubernetes logging and metrics architecture: https://kubernetes.io/docs/concepts/cluster-administration/system-metrics/

## Summary
- You separated what logs, metrics and traces each answer and linked them with a trace id.
- You ran a Prometheus, Grafana and collector stack from configuration you read line by line.
- You queried rate, error ratio and p95 latency and explained why latency uses histograms.
- You listed the failure modes of observability (cardinality, volume, lost data, alert fatigue) and a measurement for each.

## Next lesson
08. Resource management, autoscaling and cost: limits and requests, what happens at the limit, horizontal autoscaling and a cost model.
