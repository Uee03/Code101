# Phase 5: Hardening

Chapter 05 makes the API hard to abuse and easy to recover: a per-process fixed-window rate limiter with `RateLimit-*` headers and 429 (100 per minute per user, 30 per minute per anonymous address), security headers, a CORS allow-list, a 1 MB request body limit, interactive docs off in the container, security events in the JSON log (no tokens, no bodies), a read-only container without capabilities and with memory and process limits, the OWASP API Security Top 10 walked through against the code, a production checklist and a backup and restore that is actually run. This is the finished reference backend.

| Chapter | Lesson text | Folder |
|---------|-------------|--------|
| 05 Hardening: limits, headers, logging, OWASP walk-through, backup | `tutorials/phase-5-hardening/05-hardening.md` | `05-hardening/` |

## Prerequisites
- Chapter 04 (or this pack, which holds the whole project at the end of chapter 05).
- Docker with Compose v2; free host ports 5432, 8180 and 8000.
- Python 3.12 or newer for the helper scripts (`scripts/call.py`, `scripts/measure.py`, `scripts/conformance.py`).

## Folder layout
```text
05-hardening/
  code/                  the finished project; new here: app/ratelimit.py, scripts/measure.py
  exercise/starter/      window.py with TODOs
  exercise/solution/     window.py finished
  verify.json            what scripts/verify_labs.py runs
```

## Run it
```text
cd 05-hardening/code
copy .env.example .env              (macOS and Linux: cp .env.example .env)
docker compose up -d --build --wait
python scripts/conformance.py
docker compose down -v --remove-orphans --rmi local
```

## Conformance state
**18 passed, 0 failed.** The whole contract of the platform capstone is implemented.
