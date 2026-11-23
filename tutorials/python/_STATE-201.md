# Python 201 state: Hero to Super Hero

Last authoring update: 2026-11-23. Scope/decisions: [_BRIEF-201.md](_BRIEF-201.md).

**All 11 lessons: written (not run). Runtime verification: UNVERIFIED.** Every lesson has `verified: not yet run` and the owner's verbatim draft notice immediately below H1. Static checks do not prove execution. Existing verified Python 101 lessons and records were not relabeled.

| Lesson | Title | Status | Runtime verification | Static gate |
|---|---|---|---|---|
| 201.1.01 | Classes in depth | written (not run) | not yet run | clean |
| 201.1.02 | Type hints and mypy | written (not run) | not yet run | clean |
| 201.1.03 | Iterators and generators | written (not run) | not yet run | clean |
| 201.1.04 | Decorators and context managers | written (not run) | not yet run | clean |
| 201.2.05 | async/await and asyncio | written (not run) | not yet run | clean |
| 201.2.06 | Packaging with pyproject.toml, venv and uv | written (not run) | not yet run | clean |
| 201.2.07 | Logging, configuration and secrets | written (not run) | not yet run | clean |
| 201.3.08 | Your first FastAPI service | written (not run) | not yet run | clean |
| 201.3.09 | Data with SQLAlchemy 2 and a stored procedure | written (not run) | not yet run | clean |
| 201.3.10 | Authentication basics | written (not run) | not yet run | clean |
| 201.4.11 | Testing with pytest and a small notes API | written (not run) | not yet run | clean |

## Delivered

- Eleven template-complete lessons in four phases under `tutorials/python/201-hero-to-super-hero/`, each with outcomes, retrieval recap, predict-before-run, full source/starter/guided solution, change/stretch practice, matched questions and answers, typical-mistake guidance, cited official best practice, Mermaid structure, summary and next link. Mixed review closes each phase.
- Eleven source folders under `source/python/201-hero-to-super-hero/`, each with code, feature tests, exercise starter/solution and `verify.json`; four phase PACK-READMEs. Lesson 11's exercise variants contain complete standalone project copies, differing from the finished project only by their added guided test.
- New level brief/state and appended glossary terms. Existing track brief/state now link here; 101 content and its verification history remain intact. No CONTEXT, scripts, skills, docs, capstones, other-track files or repository settings were edited. No commit was made. A temporary file-writing helper under the allowed Python tutorial path was removed before final archiving.
- Four phase ZIPs and one all-level ZIP generated in the explicitly permitted ignored `dist/packs/` exception. No art is used (`assets: []`); no third-party art or private credentials are bundled.

## What was and was not checked

The permitted static command parsed each verify.json and compared lesson text with source lines and declared deterministic expected-output fragments. The final command output below was captured directly from that command, not inferred. Its `0 passed` is intentional: no runtime pass is claimed. Its missing-tool count is not an environment-readiness claim: static mode does not check required tools.

No example, exercise, unit/integration test, pytest run, mypy invocation, package resolution/install, package build, server, container or database was executed during authoring. `build_packs.py` only archived source files. A read-only command-location inspection found Python available, but not uv/Docker on the inspected session PATH; nothing was installed and no missing tool was probed by running it. The learner Python baseline is 3.12; toolchain compatibility, dependency resolution and floating container tags remain unverified.

Expected application output is derived from the source and labeled unrun. Variable server/container logs, hashes, tokens, private generated values, installation transcripts and timings are not fabricated. Common-mistake messages are explicitly typical/not captured. Official API checks and the Uvicorn-host fallback are documented in the brief.

## Final static command: actual output

`python scripts\verify_labs.py --static python/201`

```text
[STATIC    ] source/python/201-hero-to-super-hero/phase-1-core-skills/01-classes-in-depth
[STATIC    ] source/python/201-hero-to-super-hero/phase-1-core-skills/02-type-hints-and-mypy
[STATIC    ] source/python/201-hero-to-super-hero/phase-1-core-skills/03-iterators-and-generators
[STATIC    ] source/python/201-hero-to-super-hero/phase-1-core-skills/04-decorators-and-context-managers
[STATIC    ] source/python/201-hero-to-super-hero/phase-2-concurrency-and-packaging/05-async-and-asyncio
[STATIC    ] source/python/201-hero-to-super-hero/phase-2-concurrency-and-packaging/06-packaging-with-uv
[STATIC    ] source/python/201-hero-to-super-hero/phase-2-concurrency-and-packaging/07-logging-configuration-and-secrets
[STATIC    ] source/python/201-hero-to-super-hero/phase-3-apis-and-data/08-your-first-fastapi-service
[STATIC    ] source/python/201-hero-to-super-hero/phase-3-apis-and-data/09-sqlalchemy-and-stored-procedures
[STATIC    ] source/python/201-hero-to-super-hero/phase-3-apis-and-data/10-authentication-basics
[STATIC    ] source/python/201-hero-to-super-hero/phase-4-quality/11-testing-and-notes-api

0 passed, 11 static-checked (not run), 0 failed, 0 unverified (missing tools)
```

## Source-pack archiving: actual output

`python scripts\build_packs.py python-201`

```text
built python-201-phase-1-core-skills.zip (23 files)
built python-201-phase-2-concurrency-and-packaging.zip (25 files)
built python-201-phase-3-apis-and-data.zip (34 files)
built python-201-phase-4-quality.zip (58 files)
built python-201-all.zip (4 phases)
```

## Remaining verification / next authorized session

1. Resolve supported teaching/deployment dependency versions on Python 3.12 in isolated copies; generate a real uv.lock for lesson 06 rather than hand-writing it. These direct pins are snapshots, not a complete transitive lock or current security certification.
2. Literally walk lessons 01 and 11 from the Markdown in fresh workspaces. Run feature tests and guided solutions only when explicitly authorized. Check mypy diagnostics, package installation/distributions and command names against actual tools.
3. Run PostgreSQL procedure/transaction/constraint integration checks and the mini-project's full container workflow in their distinct disposable projects, including diagnostics and cleanup. SQLite application tests cannot stand in for PostgreSQL, migrations, runtime networking or image builds.
4. Review the local issuer's limitations; use the backend-python capstone for Keycloak/asymmetric trust, real migrations, least-privilege roles and full deployment hardening. Do not turn the privileged local issuer into a public login service.
5. Replace expected text only with actual observations; remove the draft notice/change verified metadata only after a later explicitly authorized runtime walkthrough. Until then every runtime status remains UNVERIFIED, not verified or reviewed.
