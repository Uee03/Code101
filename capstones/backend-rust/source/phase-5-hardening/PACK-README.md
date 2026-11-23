# Rust backend, phase 5: Hardening

The finished backend: a fixed-window rate limiter with `RateLimit-*` headers and 429, CORS for the two web origins, security headers, a 1 MiB body limit, a 30 second request timeout, security events and user ids in the log, and the OWASP API Top 10 walk-through. Status: **verified** on 2026-11-23: the conformance script prints **`18 passed, 0 failed`**.

| Folder | Chapter | Outcome |
|--------|---------|---------|
| `05-hardening-and-owasp` | Hardening and OWASP | all 18 conformance checks pass; the OWASP table points at the code that answers each risk |

## Prerequisites and extraction
- Same as phase 4. Extract `backend-rust-phase-5-hardening.zip` and open `05-hardening-and-owasp/code`.

## Run
**Terminal (folder: `05-hardening-and-owasp/code`)**
```text
cp .env.example .env            (Windows PowerShell: Copy-Item .env.example .env)
docker compose -p backend up -d --build --wait
python scripts/conformance.py
```
Expect `18 passed, 0 failed`. To see a 429, stop the stack and start it again with `RATE_LIMIT_ANON=3` in the environment (the chapter shows how).

## Exercise
`exercise/starter`: a fixed-window limiter with an injected clock (`Limiter::check`). Solution in `exercise/solution`.

## Safety and cleanup
```text
docker compose -p backend down -v --remove-orphans
docker image rm code101/tasks-api-rust:local
```

## For maintainers
`verify.json` checks the hardening headers, a CORS preflight, all 18 conformance checks and cleans up. Changed files of this phase (`Cargo.toml`, `.env.example`, `docker-compose.override.yml`, `app.rs`, `auth.rs`, `config.rs`, `lib.rs`, `main.rs`, `ratelimit.rs`, `state.rs`) are checked against the chapter text.
