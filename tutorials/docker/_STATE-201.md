# Docker 201 track state

Ten lessons in three phases written on 2026-11-23 under the owner's "do not run smoke tests" instruction. Nothing was executed: no Docker, no builds, no containers. No commits; only `tutorials/docker/` and `source/docker/201-hero-to-super-hero/` were edited.

| Lesson | Status | Evidence |
|---|---|---|
| 01-multi-stage-builds | written (not run) | static check only: text contains every code line and expected output |
| 02-build-cache-and-buildkit | written (not run) | static check only |
| 03-non-root-and-hardening | written (not run) | static check only |
| 04-scanning-and-supply-chain | written (not run) | static check only |
| 05-profiles-overrides-extensions | written (not run) | static check only |
| 06-secrets-and-configs | written (not run) | static check only |
| 07-networking-and-limits | written (not run) | static check only |
| 08-dev-containers | written (not run) | static check only |
| 09-ci-with-github-actions | written (not run) | static check only |
| 10-backups-and-upgrades | written (not run) | static check only |

## Decisions and open points
- Every lesson carries the verbatim "Draft: written but not yet run" notice and `verified: not yet run`. Remove the notice only in the run that sets a real `verified:` date.
- Expected outputs were derived by reading the code (JSON bodies, `docker inspect` values, exit codes). Tool-specific text (BuildKit progress, scanner reports, pytest timings) is described, not shown; error texts not taken from official docs are marked "typical message".
- Image tags to confirm when the labs are first run: `golang:1.25-alpine`, `node:24-alpine`, `python:3.13-slim`, `postgres:16-alpine`, `postgres:17-alpine`, `alpine:3.22`, `mcr.microsoft.com/devcontainers/python:3.13-bookworm`, `aquasec/trivy:latest`.
- GitHub Action majors used (checked against Docker's and GitHub's documentation on 2026-11-23): checkout v7, setup-buildx v4, build-push v7, login v4, metadata v6. Actions are not pinned to commit shas (lesson 09 explains why and how).
- Things most likely to need a correction on the first real run: the `docker compose --progress=plain build` flag position (06), `docker compose port` output (07), attestation support with the local image store (04), `pg_restore` flags on Alpine images (10), `develop.watch` behaviour with `sync+restart` (08).
- Verifier note: `verify.json` files exist for every lesson but have never been executed. Several use fixed container names or host port 8080, so run one lesson at a time.
- Docker 101 is unchanged. Docker 301 (orchestration concepts, registries at scale, observability, deeper hardening) is not written.
- Packs built with `python scripts\build_packs.py docker-201` into `dist/packs/` (git-ignored).
