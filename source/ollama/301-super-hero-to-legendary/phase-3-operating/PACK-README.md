# Ollama 301 - Phase 3: operating

**Draft: written (not run).** No Docker, nginx, Ollama, pip, server or program was executed by the author, and no static check was run on this level. Every lesson's front matter says `verified: not yet run`.

## Audience and prerequisites
Finish phases 1 and 2, Docker 101 and Databases 101. Python 3.12+, native Ollama (never Docker), Docker for Postgres (`pgvector/pgvector:0.8.7-pg17`) and nginx (`nginx:1.30.7-alpine`, `httpd:2.4-alpine` for one `htpasswd` command), all tags checked on Docker Hub 2026-11-23. Lesson 08 needs a clone of the course repository: its documents are `capstones/platform`.

## Get and extract
Repository: https://github.com/Uee03/Code101 (clone it for lesson 08), then `source/ollama/301-super-hero-to-legendary/phase-3-operating`. Generated archives (not yet built): `dist/packs/ollama-301-phase-3-operating.zip`, `ollama-301-all.zip`.

## Lessons
| Lesson | New source | What it adds |
|---|---|---|
| 06 Serving and scaling | `load_test.py`, `stats.py`, `ollama-override.conf`, `set-ollama-env.ps1`, tests | Bounded concurrency test, percentiles, server variables per OS |
| 07 Security and deployment | `nginx.conf`, `nginx.tls.conf`, `docker-compose.yml`, `probe.py`, tests | Loopback, authenticated allow-listed proxy, limits, review exercise |
| 08 Capstone RAG service | `service.py`, `smoke.py`, `golden.json`, `.env.example`, tests | Authenticated loopback service, guarded pipeline, evaluation, review exercise |

## Run deliberately, as a learner
`python -m unittest` first (lesson 08's tests start loopback servers on random ports). `.htpasswd` and `.env` are created by you and never committed. `set-ollama-env.ps1` changes only your user environment and has `-Remove`; Linux `systemctl revert`, macOS `launchctl unsetenv` undo the others. Never change `OLLAMA_HOST`.

## Safety and honesty
Ollama has no authentication: keep it on loopback and expose only the authenticated proxy, with TLS, if at all. No measured number is shown anywhere: every table is yours to fill.
