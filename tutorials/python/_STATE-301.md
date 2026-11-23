# Python 301 state

Status flow: planned -> written (not run) -> verified -> reviewed -> simulated. Brief: [_BRIEF-301.md](_BRIEF-301.md).

| Lesson | Title | Status | Time | Notes |
|--------|-------|--------|------|-------|
| 301.1.01 | Clean and hexagonal architecture | written (not run) | 75 min | stdlib only; AST dependency-rule check; ADR-001 |
| 301.1.02 | Domain modeling and SOLID | written (not run) | 80 min | stdlib only; contract-test mixin; ADR-002; SOLID table |
| 301.1.03 | API design at scale | written (not run) | 90 min | FastAPI, direct pins; in-memory idempotency store is flagged as not for production; ADR-003 |
| 301.2.04 | Concurrency models | written (not run) | 85 min | stdlib only; learner records own timings; optional free-threaded interpreter; ADR-004 |
| 301.2.05 | Profiling and optimisation | written (not run) | 90 min | stdlib core; Redis and Docker step is optional; ADR-005 |
| 301.2.06 | Background work and queues | written (not run) | 90 min | SQLite outbox, simulated clock, deterministic output; ADR-006 |
| 301.3.07 | Observability | written (not run) | 100 min | OpenTelemetry pins; full Collector config and Compose; offline demo is deterministic; ADR-007 |
| 301.3.08 | Security hardening | written (not run) | 95 min | Pydantic; OWASP API Top 10 table; fake resolver for SSRF tests; ADR-008 |
| 301.3.09 | Packaging, release and readiness | written (not run) | 110 min | Dockerfile, Compose, CI outline, readiness script, review exercise; ADR-009 |

Runtime verification is **UNVERIFIED** for all nine lessons. Static text parity is not execution evidence.

## Static evidence (authoring session, 2026-11-23)

- `python scripts\verify_labs.py --static python/301`: 9 static-checked (not run), 0 failed. This confirms only that every non-blank line of every checked file in `code/` and every `expect_stdout` or `expect_contains` text appears in the lesson, and that each `verify.json` parses.
- `python scripts\build_packs.py python-301`: archives the three phases and the level zip into `dist/packs/` (ignored by git).
- No code, tests, type checks, package installs, builds, servers, containers or the Collector were run.

## Things to check when the labs are first run (author uncertainty)

1. **Lesson 07**: instrumentation API details (`FastAPIInstrumentor.instrument_app(..., meter_provider=...)`, `uninstrument_app`), `InMemoryMetricReader.get_metrics_data()` traversal in `counter_total`, and the status of a span after an exception. The Collector configuration was written from the documented schema, not started; `memory_limiter` first, `debug` exporter output layout is described as typical only.
2. **Lesson 03**: that the OpenAPI component is named `TaskV1` (not `TaskV1-Output`), that the `Sunset` and `Link` headers set in a router dependency reach the response, and the `application/problem+json` content type without a charset suffix.
3. **Lesson 08**: Pydantic's order of `str_strip_whitespace` and `min_length` (the whitespace-only title test), and `ipaddress.is_global` for the listed addresses on the Python version in use (the library has changed its private-range tables across releases).
4. **Lesson 04**: the `loop_lag.py` second line is timing dependent; `bench.py` relies on process start-up working under `unittest` on Windows (spawn).
5. **Lesson 09**: `pip wheel -r requirements.txt .` in the Docker build, `cyclonedx_py environment` flags, `--rmi all` clean-up, the readiness text matching on a real Dockerfile, and the GitHub Actions inputs (`cache-dependency-path`).
6. Version pins and image tags were checked on 2026-11-23 and will age; review them at the first real run.

## Follow-ups

- Run the labs (Lab Verifier) and replace the "not yet run" labels with real output; delete the draft notices with `scripts/add_draft_notice.py --remove` only after that.
- Persona walk-through (senior) for the whole level, then a review pass with the quality checklist.
- A 301 capstone chapter on observability and release for each backend would reuse lessons 07 and 09.
