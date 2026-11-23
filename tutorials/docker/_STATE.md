# Docker track state

Eight lessons in two phases delivered on 2026-11-23. No commits; only this track edited.

| Lesson | Status | Evidence |
|---|---|---|
| 01-what-is-a-container | verified | scripts/verify_labs.py: 1 passed, 0 failed, 0 unverified; code + solution |
| 02-images-and-containers | verified | scripts/verify_labs.py: 1 passed, 0 failed, 0 unverified; code + solution |
| 03-your-first-dockerfile | verified | scripts/verify_labs.py: 1 passed, 0 failed, 0 unverified; code + solution |
| 04-data-that-survives | verified | scripts/verify_labs.py: 1 passed, 0 failed, 0 unverified; code + solution |
| 05-environment-and-secrets | verified | scripts/verify_labs.py: 1 passed, 0 failed, 0 unverified; code + solution |
| 06-networks-and-compose | verified | scripts/verify_labs.py: 1 passed, 0 failed, 0 unverified; code + solution |
| 07-healthchecks-and-cleanup | verified | scripts/verify_labs.py: 1 passed, 0 failed, 0 unverified; code + solution |
| 08-two-service-project | verified | scripts/verify_labs.py: 1 passed, 0 failed, 0 unverified; code + solution |

## Verification scope and decisions
- Smoke only: requires docker, checks the engine, probes with bounded retries, unconditional cleanup.
- Windows: CLI/Engine 29.9.3, Desktop 4.99.0, Compose v5.7.0, WSL2 Ubuntu-26.04.
- macOS/Linux install routes and optional .wslconfig are official-docs checked, not machine-tested.
  WSL integration was off. Direct WSL script validation was blocked; temporary bridge attempts were abandoned,
  not retried indefinitely. Source checklists are PowerShell; lessons give equivalent macOS/Linux commands.
  Desktop settings/live .wslconfig never changed; wsl --shutdown documented, not executed.
- Image version-family tags pulled successfully 2026-11-23; patches can change tags. hello-world is the explicit
  latest-tag diagnostic exception. Driver psycopg[binary]==3.2.9 smoke-built successfully.
- Only web is published (127.0.0.1:8080; 02 exercise: 8081). Postgres is private; host 5432 belongs to Databases.
- Code images removed before solution rebuild; all solution images removed in cleanup.
- 08 additionally demonstrated a preserved counter across down/up with a named volume.
- Real errors: name conflict, allocated port, missing image, YAML parser failure, unreachable daemon pipe.
  Daemon failure used a nonexistent endpoint; the running engine was not stopped.
- No art, no real secrets, no Unity Docker work. No global prune of unrelated external resources.
- Final sweep: **8 passed, 0 failed, 0 unverified**. An overlapping external sweep caused transient port/project
  contention; rerunning after it cleared passed all eight. Prior per-lesson PASS evidence is in each lesson.
- Final audit: zero containers, zero named volumes, only bridge/host/none networks, zero builder cache;
  no code101-verify resources or author-built/downloaded images. Shared Databases postgres:17-alpine preserved.
  Details: _VERIFICATION.md. Desktop engine still running; settings unchanged.
- Built docker-101-phase-1-containers.zip, docker-101-phase-2-compose.zip and docker-101-all.zip in dist/packs.
  No commits. No UNVERIFIED lesson or outstanding decision.
- 101 text fixes (no code changed, nothing run): optional source-pack sentence (repo + Download ZIP/git clone) replaces unzip wording; maintainer smoke blocks removed; honest times (01 about 60+ in two sittings with marked break, 05-07 about 40, 08 about 75 in two sittings); Common mistakes: unproducible rows removed, wrong-folder/.env/Docker-not-running rows added and marked typical message; New terms lists added; Try it no longer gives the answer.
