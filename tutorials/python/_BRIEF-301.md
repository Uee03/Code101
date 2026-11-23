# Python 301 brief: Super Hero to Legendary

Audience: senior-bound developers who finished Python 201 and the [backend-python capstone](https://github.com/Uee03/Code101/tree/main/capstones/backend-python). Assume async, typing, packaging with uv, FastAPI, SQLAlchemy, pytest and Docker basics. The voice is 301: trade-offs, failure modes, "when not to use this", measurements to take (never invented numbers), ADR-style decisions and production checklists. Each lesson also keeps the template structure (outcomes, recap, predict-before-run, three-rung exercise, check yourself, summary).

## Delivery and verification boundary

- Track `python`; level `301-super-hero-to-legendary`; numbering restarts at 01. Nine lessons in three phases, 815 minutes of typing, reading, measuring and exercises.
- Status: **written (not run)**. Every lesson has `verified: not yet run` and the verbatim draft notice under the H1. Nothing was executed: no lesson code, tests, mypy, pip, builds, servers, Docker or Collector. The only commands used by the author were `python scripts\verify_labs.py --static python/301` and `python scripts\build_packs.py python-301`.
- Output shown in lessons is derived by reading the code. Where it cannot be derived (timings, byte counts, pip, Docker, Collector and profiler transcripts) the lesson shows the *shape* with placeholders such as `<seconds>` and says "typical" or "not yet run". Timing-dependent lines in `verify.json` use `expect_contains` only for the deterministic fragment.
- `verify.json` files describe future probes. Lessons that need dependencies create a `.venv` and call its interpreter by path. Docker and network steps (Redis in 05, the Collector in 07, the image in 09) are manual steps in the lesson and are not in `verify.json`, so the verifier needs only Python (and network for `pip`). No lock files were created; the lessons say so.

## Route

| Phase | ID | Lesson | Time |
|---|---|---|---|
| [1 Architecture](301-super-hero-to-legendary/phase-1-architecture/) | 301.1.01 | [Clean and hexagonal architecture](301-super-hero-to-legendary/phase-1-architecture/01-clean-and-hexagonal-architecture.md): ports as Protocols, dependency rule enforced by an AST test | 75 min |
| | 301.1.02 | [Domain modeling and SOLID](301-super-hero-to-legendary/phase-1-architecture/02-domain-modeling-and-solid.md): entities, value objects, aggregate, unit of work, contract tests | 80 min |
| | 301.1.03 | [API design at scale](301-super-hero-to-legendary/phase-1-architecture/03-api-design-at-scale.md): versioning and sunset, cursor pagination, idempotency keys, contract tests | 90 min |
| [2 Performance and concurrency](301-super-hero-to-legendary/phase-2-performance-and-concurrency/) | 301.2.04 | [Concurrency models](301-super-hero-to-legendary/phase-2-performance-and-concurrency/04-concurrency-models.md): GIL, threads, processes, asyncio, free-threaded builds | 85 min |
| | 301.2.05 | [Profiling and optimisation](301-super-hero-to-legendary/phase-2-performance-and-concurrency/05-profiling-and-optimisation.md): cProfile, py-spy, tracemalloc, lru_cache, Redis cache-aside | 90 min |
| | 301.2.06 | [Background work and queues](301-super-hero-to-legendary/phase-2-performance-and-concurrency/06-background-work-and-queues.md): outbox, retries, dead letters, idempotent workers | 90 min |
| [3 Production](301-super-hero-to-legendary/phase-3-production/) | 301.3.07 | [Observability](301-super-hero-to-legendary/phase-3-production/07-observability.md): JSON logs, metrics, OpenTelemetry traces, Collector config | 100 min |
| | 301.3.08 | [Security hardening](301-super-hero-to-legendary/phase-3-production/08-security-hardening.md): audit, secrets, validation, SSRF, OWASP API Top 10 | 95 min |
| | 301.3.09 | [Packaging, release and readiness](301-super-hero-to-legendary/phase-3-production/09-packaging-release-and-readiness.md): wheel, SBOM, image, CI outline, review exercise | 110 min |

## Decisions

- **Baseline Python 3.14** (the capstone container runs 3.14); code needs 3.10 or newer syntax (`X | None`), `typing.Self` (3.11) and, in lesson 02, nothing newer. Commands use `py -3.14` and `python3.14`; newer interpreters work by changing the number. Lesson 04 treats the free-threaded build as an optional experiment and never states a speed-up; learners fill in a table from their own machine.
- **One running domain (tasks and teams)** across lessons so the capstone vocabulary carries over. Lessons 01, 02 and 06 are standard library only (SQLite for 01 and 06). Lessons 03, 07, 08 and 09 use FastAPI or Pydantic with direct pins.
- **Tests with `unittest`** (as in 201 lessons 01 to 10) so no extra tool is needed; lesson 09 notes pytest as the usual next step.
- **Security**: loopback-only ports everywhere, no real secrets, `.env` never created, secrets read from files in lesson 08, hardened container options in lesson 09. Docker host ports used: 6390 (Redis), 4317 and 4318 (Collector), 8000 (lessons 03 and 07 services), 8100 (lesson 09).
- **Architecture, security and API craft** here are the senior view of what the capstone chapters implement; each lesson links to the matching chapter.
- **No art** (`assets: []`).

## Pins (checked against PyPI and Docker Hub on 2026-11-23)

fastapi 0.165.0, uvicorn 0.54.0, pydantic 2.14.4, httpx 0.28.1, redis (client) 8.2.0, opentelemetry-api/sdk/exporter-otlp-proto-http 1.45.2, opentelemetry-instrumentation-fastapi 0.66b2, pip-audit 2.10.1, py-spy 0.4.4, hatchling 1.33.0, build 1.6.1, cyclonedx-bom 9.0.0, ruff 0.17.6, mypy 2.4.1. Images: `redis:8.8-alpine`, `otel/opentelemetry-collector-contrib:0.165.0`, `python:3.14-slim`. GitHub Actions in the CI outline: checkout, setup-python and upload-artifact at `v7` (latest releases when written). Direct pins are snapshots, not a security-support claim; transitive dependencies are not locked.

## Sources used (Tier 1)

- Python docs: [free-threading HOWTO](https://docs.python.org/3/howto/free-threading-python.html), [concurrent.futures](https://docs.python.org/3/library/concurrent.futures.html), [asyncio dev](https://docs.python.org/3/library/asyncio-dev.html), [profile and cProfile](https://docs.python.org/3/library/profile.html), [profiling (3.15)](https://docs.python.org/3/library/profiling.html), [tracemalloc](https://docs.python.org/3/library/tracemalloc.html), [functools](https://docs.python.org/3/library/functools.html), [sqlite3](https://docs.python.org/3/library/sqlite3.html), [ipaddress](https://docs.python.org/3/library/ipaddress.html), [hmac](https://docs.python.org/3/library/hmac.html), [logging cookbook](https://docs.python.org/3/howto/logging-cookbook.html).
- PEPs: [PEP 544](https://peps.python.org/pep-0544/), [PEP 703](https://peps.python.org/pep-0703/), [PEP 779](https://peps.python.org/pep-0779/), [PEP 621](https://peps.python.org/pep-0621/).
- SQLAlchemy 2.0: [Session basics](https://docs.sqlalchemy.org/en/20/orm/session_basics.html), [transactions](https://docs.sqlalchemy.org/en/20/orm/session_transaction.html). FastAPI: [response model](https://fastapi.tiangolo.com/tutorial/response-model/), [testing](https://fastapi.tiangolo.com/tutorial/testing/).
- OpenTelemetry: [Python status](https://opentelemetry.io/docs/languages/python/) (traces and metrics Stable, logs Development when written), [instrumentation](https://opentelemetry.io/docs/languages/python/instrumentation/), [Collector configuration](https://opentelemetry.io/docs/collector/configuration/).
- Supporting: [OWASP API Security Top 10 2023](https://owasp.org/API-Security/editions/2023/en/0x11-t10/), RFC 9457 and RFC 8594, [Dockerfile reference](https://docs.docker.com/reference/dockerfile/), [Pydantic strict mode](https://docs.pydantic.dev/latest/concepts/strict_mode/), [CycloneDX Python](https://cyclonedx-bom-tool.readthedocs.io/en/latest/), [PyPA pyproject guide](https://packaging.python.org/en/latest/guides/writing-pyproject-toml/), [GitHub Actions hardening](https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions).

## File boundaries

Lessons: `tutorials/python/301-super-hero-to-legendary/phase-N-slug/NN-slug.md`. Sources: `source/python/301-super-hero-to-legendary/phase-N-slug/NN-slug/{code,exercise/starter,exercise/solution,verify.json}` and one `PACK-README.md` per phase. Glossary additions are appended to `GLOSSARY.md` under 301 lesson ids.
