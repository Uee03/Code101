# Python 201 brief: Hero to Super Hero

Audience: graduates of Python 101 with roughly 1-2 years of programming experience. Assume functions, modules, collections, exceptions, basic classes and virtual environments. Explain why a design is appropriate, when not to use it and the alternative; do not reteach 101 line by line.

## Delivery and verification boundary

- Track `python`; level `201-hero-to-super-hero`; numbering restarts at 01. Eleven lessons, four phases. Phase 4 is deliberately one substantial quality/mini-project lesson instead of an artificial split or a duplicate capstone.
- Status: **written (not run)**. Every lesson has `verified: not yet run` and the owner's verbatim visible draft notice directly under H1. Runtime verification is UNVERIFIED. Static text parity is not execution evidence.
- No lesson programs, tests, mypy checks, package builds, servers or Docker commands are executed during authoring. Commands in lessons are learner instructions. The permitted author gate is `python scripts\verify_labs.py --static python/201`.
- `verify.json` specifies future small probes/solutions, not proof of execution; installing dependencies and the PostgreSQL lifecycle are future opt-in actions. The data lab declares cleanup and its own exclusive lock. No generated dependency lock or credentials are fabricated.
- `python scripts\build_packs.py python-201` only archives sources and is explicitly permitted to write ignored artifacts to `dist/packs/`. This is not a Python project/container build.
- All source files are UTF-8 without BOM. Lesson source blocks are copied from source, never separately maintained. No art is used: `assets: []` throughout.

## Outcomes and route

Learners will model/test contracts, use Python protocols and structured concurrency, package a command, validate configuration, build a small API, persist data with explicit transactions, verify bearer claims and specify isolated HTTP tests.

| Phase | ID | Lesson and outcome | Time |
|---|---|---|---|
| [1 Core skills](201-hero-to-super-hero/phase-1-core-skills/) | 201.1.01 | [Classes in depth](201-hero-to-super-hero/phase-1-core-skills/01-classes-in-depth.md): dataclasses, properties, dunders, composition vs inheritance | 60 min |
| | 201.1.02 | [Type hints and mypy](201-hero-to-super-hero/phase-1-core-skills/02-type-hints-and-mypy.md): protocols, union narrowing, strict checks | 60 min |
| | 201.1.03 | [Iterators and generators](201-hero-to-super-hero/phase-1-core-skills/03-iterators-and-generators.md): laziness and exhaustion | 50 min |
| | 201.1.04 | [Decorators and context managers](201-hero-to-super-hero/phase-1-core-skills/04-decorators-and-context-managers.md): preserved metadata and cleanup | 60 min |
| [2 Concurrency and packaging](201-hero-to-super-hero/phase-2-concurrency-and-packaging/) | 201.2.05 | [async/await and asyncio](201-hero-to-super-hero/phase-2-concurrency-and-packaging/05-async-and-asyncio.md): owned tasks, deadlines, cancellation | 65 min |
| | 201.2.06 | [Packaging with uv](201-hero-to-super-hero/phase-2-concurrency-and-packaging/06-packaging-with-uv.md): pyproject, src layout, venv, entry point and real lock resolution | 75 min |
| | 201.2.07 | [Logging, configuration and secrets](201-hero-to-super-hero/phase-2-concurrency-and-packaging/07-logging-configuration-and-secrets.md): environment, pydantic-settings, safe logging | 70 min |
| [3 APIs and data](201-hero-to-super-hero/phase-3-apis-and-data/) | 201.3.08 | [First FastAPI service](201-hero-to-super-hero/phase-3-apis-and-data/08-your-first-fastapi-service.md): DTOs vs entities, response models, injection, errors, Uvicorn | 90 min |
| | 201.3.09 | [SQLAlchemy and stored procedures](201-hero-to-super-hero/phase-3-apis-and-data/09-sqlalchemy-and-stored-procedures.md): PostgreSQL CALL, bound values, transactions and complete Compose setup | 105 min |
| | 201.3.10 | [Authentication basics](201-hero-to-super-hero/phase-3-apis-and-data/10-authentication-basics.md): Argon2, bearer validation, JWT trust boundaries | 100 min |
| [4 Quality](201-hero-to-super-hero/phase-4-quality/) | 201.4.11 | [Testing and notes API](201-hero-to-super-hero/phase-4-quality/11-testing-and-notes-api.md): pytest fixtures/parametrize/TestClient, owner filtering, Dockerfile/Compose | 180 min |

Estimated typing/reading/exercise time: 915 minutes (15 hours 15 minutes), split across sittings. Source-pack users can concentrate on reading and experiments rather than typing every line. Lessons 08-10 are two-sitting labs; lesson 11 has three explicit sitting boundaries.

## Pedagogy and implementation decisions

Every lesson has measurable outcomes, spaced recap questions, a predict-before-run step, a complete example, feature tests, a guided TODO exercise with solution, a change rung, an optional design stretch, matched questions/answers, common mistakes labeled typical where unobserved, cited best practice, further reading, summary and a concrete next link. Every phase ends with mixed retrieval review in its final lesson.

- Early tests use standard-library unittest, so testing accompanies each feature before pytest is introduced in 11.
- Deterministic printed examples avoid timings, race-order transcripts, password hashes, JWT strings and random IDs. Uncertain tool/service output is explicitly described as expected and unrun, never represented as captured evidence.
- Python 3.12 is the teaching baseline, selected explicitly in learner commands. Direct dependency pins are snapshots, not the latest-version/security-support claim or a complete transitive lock.
- Pins: mypy 1.15.0; uv 0.6.14; Hatchling 1.27.0; Pydantic 2.11.3; pydantic-settings 2.8.1; FastAPI 0.115.12; Uvicorn 0.34.2; HTTPX 0.28.1; SQLAlchemy 2.0.40; psycopg[binary] 3.2.6; PyJWT 2.10.1; pwdlib[argon2] 0.2.1; pytest 8.3.5. Review and resolve supported versions before deployment. `uv.lock` is intentionally generated later by the learner, not handwritten by the author.
- Synchronous SQLAlchemy uses synchronous FastAPI handlers. The asyncio lesson does not imply async makes blocking calls cooperative.
- Lesson 08 is explicitly unauthenticated, loopback-only and memory-only. Lesson 10 uses a privileged local issuer CLI, not an insecure public login/registration endpoint. Lesson 11 preserves that limited trust model and enforces owner-scoped queries.
- PostgreSQL uses `postgres:17-alpine`, host ports 5542/5543 and isolated Compose project names. All full templates, initialization SQL, build context rules, health checks, diagnostics and destructive cleanup are shown. No real `.env` is stored. The runtime image is `python:3.12-slim` and nonroot; floating image tags are disclosed.
- SQLite fixtures are fast application checks, not PostgreSQL procedure/migration/locking verification. PostgreSQL integration specifications remain in lesson 09 and the manual mini-project workflow. Alembic is introduced as the schema-evolution next step, not falsely equated with initialization scripts or create_all.
- The full app, distributed identity/Keycloak, real migration lifecycle, production permissions and hardening belong to [backend-python](https://github.com/Uee03/Code101/tree/main/capstones/backend-python). This mini-project is notes-only.

## Official sources checked during authoring (2026-11-23)

Tier 1: prefer versioned official documentation for claims. Python/Pydantic/SQLAlchemy/FastAPI/pytest are primary teaching sources; the official tool/database/image docs below support their specific configuration boundaries.

- Python 3.12: [dataclasses](https://docs.python.org/3.12/library/dataclasses.html), [data model](https://docs.python.org/3.12/reference/datamodel.html), [typing](https://docs.python.org/3.12/library/typing.html), [functional/iteration HOWTO](https://docs.python.org/3.12/howto/functional.html), [contextlib](https://docs.python.org/3.12/library/contextlib.html), [functools](https://docs.python.org/3.12/library/functools.html), [asyncio tasks](https://docs.python.org/3.12/library/asyncio-task.html), [unittest](https://docs.python.org/3.12/library/unittest.html), [logging](https://docs.python.org/3.12/howto/logging.html), [secrets](https://docs.python.org/3.12/library/secrets.html).
- Packaging: [PEP 621](https://peps.python.org/pep-0621/), [PyPA pyproject guide](https://packaging.python.org/en/latest/guides/writing-pyproject-toml/), [uv projects](https://docs.astral.sh/uv/guides/projects/), [uv installation](https://docs.astral.sh/uv/getting-started/installation/), [uv environments](https://docs.astral.sh/uv/pip/environments/), [Hatch wheel selection](https://hatch.pypa.io/1.13/plugins/builder/wheel/#packages), [mypy](https://mypy.readthedocs.io/en/stable/getting_started.html).
- Data/API: [Pydantic settings](https://docs.pydantic.dev/latest/concepts/pydantic_settings/), [types](https://docs.pydantic.dev/2.11/api/types/), [validators](https://docs.pydantic.dev/2.11/concepts/validators/); FastAPI [responses](https://fastapi.tiangolo.com/tutorial/response-model/), [dependencies](https://fastapi.tiangolo.com/tutorial/dependencies/), [testing](https://fastapi.tiangolo.com/tutorial/testing/), [security](https://fastapi.tiangolo.com/tutorial/security/oauth2-jwt/), [manual server](https://fastapi.tiangolo.com/deployment/manually/).
- Uvicorn's former `www.uvicorn.org` host could not be resolved twice. The official version-tagged [0.34.2 settings source](https://github.com/encode/uvicorn/blob/0.34.2/docs/settings.md) was read instead and confirms module:factory, --factory, bind/port and worker/reload behavior. No unchecked substitute server API was invented.
- SQLAlchemy 2 [ORM quickstart](https://docs.sqlalchemy.org/en/20/orm/quickstart.html), [transactions/bound parameters](https://docs.sqlalchemy.org/en/20/tutorial/dbapi_transactions.html), [SQLite dialect](https://docs.sqlalchemy.org/en/20/dialects/sqlite.html); PostgreSQL 17 [CREATE PROCEDURE](https://www.postgresql.org/docs/17/sql-createprocedure.html); [Alembic tutorial](https://alembic.sqlalchemy.org/en/latest/tutorial.html).
- [PyJWT usage](https://pyjwt.readthedocs.io/en/stable/usage.html); pytest [fixtures](https://docs.pytest.org/en/stable/how-to/fixtures.html), [parametrize](https://docs.pytest.org/en/stable/how-to/parametrize.html), [temporary paths](https://docs.pytest.org/en/stable/how-to/tmp_path.html).
- Docker [Dockerfile](https://docs.docker.com/reference/dockerfile/), [Compose services](https://docs.docker.com/reference/compose-file/services/), [Compose up/--wait](https://docs.docker.com/reference/cli/docker/compose/up/), [Official PostgreSQL image](https://hub.docker.com/_/postgres).

## File boundaries

Lessons: `tutorials/python/201-hero-to-super-hero/phase-N-slug/NN-slug.md`.
Sources: `source/python/201-hero-to-super-hero/phase-N-slug/NN-slug/{code,exercise/starter,exercise/solution,verify.json}` and one `PACK-README.md` per phase. Glossary additions append to the existing Python glossary. Keep all existing verified Python 101 content/status intact.
