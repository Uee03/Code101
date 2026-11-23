# CONTEXT: read this first

Live state for humans and agents. Update at the end of every work block. Keep under 120 lines.
Last updated: 2026-11-23 (session 2, block 2: Wave 1 first batch complete).

## Project in one paragraph

Code101 is a tutorial library taking learners from zero to senior across 17 tracks in three levels:
**101 Zero to Hero**, **201 Hero to Super Hero**, **301 Super Hero to Legendary**, plus 14 full-stack capstones
(Python/ASP.NET/Go/Rust/Supabase backends + Postgres + Angular/React/Flutter + Docker, monoliths and microservices).
Security, identity (Keycloak, Authentik) and API craft are chapters inside the capstones, not tracks. Every level ships phased,
unzippable source packs. Tutorial tooling is in `.github/`; stack agents/skills live in
`F:\Projects\Git\Claude\AgenticAssisstance\templates`. Art: `F:\Projects\Git\Art` (CC0 subset copied to `assets/art`).

## Phase and status

| Item | Status |
|------|--------|
| Phase | **Policy (user, 2026-11-23): NO smoke tests; write lessons + source only.** Shared author brief: `docs/WRITING-BRIEF.md` (agents of type Tutorial Author kept refusing unrun code; **general-purpose agents comply**, so use general-purpose for authoring). Done (written, not run, static-checked): Design Patterns 101, System Architecture 101, Ollama 101, Databases 201, Rust 201, capstones web-angular, web-react, mobile-flutter, mobile-kotlin. In flight: Python 201, C# 201, Go 201, Web 201, Docker 201, Patterns 201, and 301 for Python, C#, Go, Rust, Databases, Web, Docker, Patterns, plus Architecture 201+301 and Ollama 201+301. All 101/201/301 tracks above are now written, and Angular, React, Flutter, Kotlin at 101+201. Still to write: C, C++, Unity, Supabase (101/201/301). Docker 101 and Databases 101 still need the walk-through fixes (source-pack sentence, maintainer text, honest times). |
| Repo | `main`, one commit; everything else uncommitted (user has not asked for commits) |
| Links | 142 supplied, 72 kept and tiered (26/26/20), 70 dropped: [docs/LINKS.md](docs/LINKS.md) |
| Agents/skills | Tutorial tooling built; stack bundles still to build per wave (Go, Rust, React, Kotlin, patterns...): [docs/AGENTS-SKILLS-PLAN.md](docs/AGENTS-SKILLS-PLAN.md). Ollama skills now support native installs on any OS |
| Tutorial tooling | Built in `.github/`: 8 agents, 8 skills (+ `lessons-learned.md`), 4 prompts, copilot-instructions. Scripts: `build_packs.py`, `verify_labs.py` (PATH refresh, bg servers, retries, always-run cleanup), `check_links.py` |
| Art | 549 CC0 icons + 12 loaders + 4 Uee03 brand SVGs in `assets/art` (see its README) |
| Tutorials written | **80 of about 630, all level 101:** Python 12, C# 12, Web (HTML/CSS/JS/TS) 12, Go 12, Rust 12, Docker 8, Databases (PostgreSQL) 12. Full run `python scripts/verify_labs.py`: **80 passed, 0 failed, 0 unverified** (407 s). 28 zips in `dist/packs/` (git-ignored; rebuild with `python scripts/build_packs.py`) |
| Review status | Only Python 101 phase 1 has had a beginner walk-through. The other 68 lessons are verified (code runs, text matches code) but **not yet reviewed or walked through**. |
| Capstones | `platform` verified (TDD 390 lines, OpenAPI 3.1.1 27 operations, schema + 3 stored functions, Keycloak 26.8.2 realm, conformance script 18 checks). **Backends: python (5 chapters), go (7), rust (5), dotnet (5): all pass the final phase at 18/18 conformance; I re-ran the four final phases myself, all PASS, Docker clean.** Client TDDs written (angular/react 400 lines, flutter 404, kotlin 419; 24 Mermaid diagrams parse). `capstones/_practice/` P01-P11 TDDs + README. Contract v1.1 backlog (12 items found by the backends) is in `capstones/platform/TDD.md` section 12.1, to be applied once after the clients report. `openapi.yaml` (1,200 lines) is shown section by section in its lesson: the one disclosed exception to "show every line". |

## What I learned (facts to reuse, do not re-derive)

- The user's existing library (`Git\Claude\AgenticAssisstance\templates`) already covers Python, .NET (incl.
  FastEndpoints), Angular, C/C++, Flutter, SQL (Postgres, SQL Server, SQLite, EF Core, stored procedure
  scripts), Supabase, Unity (29 skills), Keycloak (1 skill), Ollama (AMD + Windows only), Docker basics,
  diagrams (Mermaid, draw.io, UML, SVG). Missing: Go, Rust, React, Kotlin/Compose, Web Foundations,
  Authentik, general design patterns/SOLID, API craft, architecture principles.
- Existing conventions: skills = `SKILL.md` with `name`, `description` and a "Best model" tier line; agents
  = `*.agent.md` with `tools` and a `model` fallback list; four model tiers (Quick, Plan, Act, Deep) in the
  `model-routing` skill; workspace rules: plan before act, read-only reviewers, stop after two failed fixes.
- Link check: 107 of 141 URLs return 200; 32 are 403 (sites blocking scripts, mostly Medium) and 2 timed out.
- Machine (Windows): has Python 3.15.2, .NET 11.0.100, Node 26.13.1, npm 11.20.0, Flutter 3.50.1, JDK 25, Ollama (manual install, server stopped),
  **Go 1.27.4, Rust 1.100.0 (stable-msvc, clippy, fmt, rust-analyzer; verified compile+run), WSL 3.0.5 with Ubuntu-26.04 (WSL2), Docker CLI 29.9.3
  (Docker Desktop installed but the engine was NOT running when checked), MSVC Build Tools (VS 18)**. Still missing: CMake, gcc, psql, Angular CLI,
  kotlinc/Android SDK, Supabase CLI. No `.wslconfig` yet (WSL VM defaults to about 16 GB; suggest `memory=8GB`). Tool PATH changes need a new shell.
- **Unity is local only, never Docker** (user rule): no Compose/container steps in Unity lessons or verification.
- **Art repo (`F:\Projects\Git\Art`):** 29 GB with node_modules. Its LICENSE is proprietary (no redistribution) EXCEPT `src/saas-icons`,
  which is CC0 (549 plain icons, 24x24, `stroke=currentColor`). Only that CC0 set is bundled. `saas-icons/loaders-colored` has 48k
  generated files: never copy it.
- **Windows Python install changed:** python.org ships the "Python install manager" (MSIX), not the old "Add to PATH" installer;
  `python` works after install. Source: https://docs.python.org/3/using/windows.html. Lesson 01 reflects this.
- **Tooling gotchas:** Windows PowerShell 5.1 `Set-Content -Encoding utf8` writes a BOM; `verify_labs.py` flags BOMs (the lesson text won't
  contain U+FEFF). Write files with the editor tools or `[IO.File]::WriteAllText` with `UTF8Encoding($false)`.
- **Ollama (user installed it manually):** `C:\Users\mruee\AppData\Local\Programs\Ollama\ollama.exe`, client 0.40.17; the server was not
  running when checked. On Windows/macOS `ollama list/ps/run` **auto-start the app** when no server answers (it happened during a check),
  so health checks use process, port and `/api/version` first. Official install: Windows `irm https://ollama.com/install.ps1 | iex`,
  macOS/Linux `curl -fsSL https://ollama.com/install.sh | sh` (both verified). Skills/agents in the Claude templates repo now cover native
  installs on any OS (`ollama-local-setup`, Ollama Reviewer).
- **Machine specs:** Windows 11 Pro 26300, Ryzen 7 5800XT (8c/16t), 31.9 GB RAM, RX 7900 XT, lots of free disk. WSL not installed, so Docker Desktop
  needs `wsl --install` first. winget is available.
- **Verifier filter gotcha:** `verify_labs.py` filters are path substrings and several filters are OR-ed, so `python-101 phase-2` also matched Docker's
  phase-2. Pass one filter per run (e.g. `source/python/`). `build_packs.py` filters on zip names: use `<track>-101` so the level "all" zip has every phase.
- **Docker `.env`:** lessons ship `.env.example` only; the verifier creates `.env` in a step. `.env` is git-ignored, so never rely on one in `source/`.
  `bin/`, `obj/`, `target/` are build output created by verification and are git-ignored and excluded from zips.
- Docker engine had to be started by hand once (Docker Desktop); after the full verify Docker had 0 containers, 0 volumes, 0 extra networks. The
  `postgres:17-alpine` image is kept as a cache (about 424 MB).
- **Capstone port lock:** all capstone labs share host ports 8000/8180/5432 and the `tasksteams-net` network. `verify.json` must set `"exclusive": "tasksteams"`;
  `scripts/stack_lock.py` serializes runs across processes (tested: a second holder waits). Debug commands that touch those ports:
  `python scripts/stack_lock.py tasksteams -- <command>`. Mermaid diagrams in capstone docs were all parse-checked with mermaid + jsdom (39 ok, negative test fails correctly).
- **Draft notice:** every lesson written without running carries the notice "Draft: written but not yet run" under its title (rule in `lessons-learned.md`). `python scripts/add_draft_notice.py`
  adds it to any lesson whose front matter says `verified: not yet run` (idempotent); `--remove` strips it from lessons that got a real verified date. Run it after each writing wave.
- Verifier proven to fail on tampered code (negative test done) and pass on correct code.

## Next actions (in order)

1. **Persona walk-throughs** of the new 101 tracks (beginner agent per track; batch them like the writers), apply fixes via Tutorial Author; the 21 open nits in `reviews/python-101.md`.
2. User confirms D1 (meaning of "101") and D10 (art scope); reviews a few lessons and packs (`dist/packs/`).
3. Next writing batch (needs no new installs): Design Patterns + SOLID 101, System Architecture 101 (Mermaid/draw.io), Ollama 101 (local server must be started: ask first), then level 201 for Python, C#, Web, Go, Rust, Databases, Docker.
4. Install still missing before their waves: CMake (C/C++ via MSVC already present), Postgres client not needed (Docker), Angular CLI (npm), Android SDK/Kotlin, Supabase CLI.
5. Update this file after every block.

## Open questions

- D1 (what "101" means) and D10 (extra art to bundle). Everything else in PLAN.md section 2 is decided or defaulted.
- Which of Qt or Dear ImGui for the C++ desktop capstone, SDL or GTK for C? Default Qt and SDL.
- Authentik: appendix per capstone beside Keycloak (default) or full lessons?
- License: MIT for all lesson text and code (user, 2026-11-23); art stays CC0 / brand marks reserved. Learning is free choice: any track, any order; any backend pairs with any client (`capstones/README.md`); prerequisites are recommendations only.

## Verification scope (user instruction 2026-11-23, supersedes the smoke-test rule below): NO smoke tests

Authors write lessons and source code and do **not** execute code, build, start servers or use Docker. Use `python scripts/verify_labs.py --static <filter>`
(executes nothing: compares lesson text with code files and expected output, checks verify.json parses). Mark new lessons `verified: not yet run` and
`written (not run)` in `_STATE.md`. Lessons written before this instruction (101 tracks, platform and four backend capstones) stay verified.
Earlier text (kept for reference, not the current rule):

Verification proves the **environment works and the code runs once**. It is a smoke test, not a test suite:

- Run each lab's program once with a small input and check its output. Do **not** run unit-test suites, linters or benchmarks as verification
  (lessons may still teach testing; the verifier does not run those tests).
- **Docker / Compose labs are temporary.** The verifier starts them under a throwaway project name (`code101-verify-<lesson>`), probes once, and
  **always cleans up** (`docker compose -p <name> down -v --remove-orphans`) through the `cleanup` list in `verify.json`, even when a step fails.
  Never leave containers, networks or volumes behind. Never publish a fixed host port that another lab uses (see the port table below).
- **Lessons show every Docker configuration** a learner needs: the full `docker-compose.yml`, `Dockerfile`, `.env` / `.env.example`, `.dockerignore`,
  the commands to start, check, view logs and stop, and the expected output. `verify_labs.py` already enforces that every line of every file in `code/`
  appears in the lesson text.
- **Unity is local only, never in Docker.**

| Host port | Used by |
|-----------|---------|
| 5432 | Databases track (Postgres) |
| 8080 | Docker 101 sample web app |
| 8081 | Docker 101 second service |
| 5173, 4200 | Vite (React) / Angular dev servers |
| 8000 | Capstone backends (one at a time; same contract, same port) |
| 8180 | Keycloak (capstone platform; avoids 8080) |
| 11434 | Ollama (native, not Docker) |

Docker 101 labs do not publish Postgres to the host (apps reach it by service name), so they never clash with the Databases track.

## Verifier features

- `requires`: tools that must exist, otherwise the lesson is UNVERIFIED (never a pass).
- `steps`: commands run in a clean copy; `cleanup`: commands that **always** run afterwards (use for `docker compose down -v`, killing servers).
- On Windows the verifier reloads PATH from the registry first, so tools installed after a terminal opened (Go, Rust, Docker) are found.

## Working protocol (saves tokens)

1. Read this file, then only the relevant track `_STATE.md` and `_BRIEF.md`.
2. Search, then view line ranges. Never reload `docs/LINKS.md` in full; use the per-track brief.
3. One lesson per author-agent run; reviewers use the checklist, not free reading.
4. Record decisions here (one line each), not in chat.
5. Never write unverified code into a lesson; mark and log it in `_STATE.md` if a toolchain is missing.
6. Run `python scripts/verify_labs.py <filter>` after any code or lesson change; `python scripts/build_packs.py <filter>` to rebuild zips.

## Decision log

| Date | Decision |
|------|----------|
| 2026-11-23 | Link tiers: official docs first; Medium and duplicate listicles dropped. |
| 2026-11-23 | Level codes 101/201/301; Angular and React lessons are parallel. |
| 2026-11-23 | User: security, identity and API craft taught inside capstones, no separate tracks. |
| 2026-11-23 | User: WebGL dropped. |
| 2026-11-23 | User: show all steps; "refer to previous steps" only when genuinely identical. |
| 2026-11-23 | User: source packs per level of every track, split into phases (zips via `build_packs.py`). |
| 2026-11-23 | User (credits nearly exhausted): finish lessons only; no start-here pages. Angular, React, Flutter, Kotlin written at 101 (12 each) and 201 (10 each); 301 not planned for these four. Platform primers, Docker 101/Databases 101 fixes and the cross-link pass are done. **Nothing since the "no smoke tests" instruction has been run or checked; run `verify_labs.py` before sharing.** | Start-here pages done: `docs/START-HERE.md` and `docs/paths/{backend,web,mobile}.md`. Capstone readiness checklists were skipped by request. Not started: C 201/301, C++ 201/301, Unity, Supabase. Written (not run): C 101 and C++ 101 (12 lessons each) and capstones `desktop-c` and `desktop-cpp` (5 chapters each; they need a `tasks-desktop-client.json` Keycloak client, a platform v1.1 backlog item). Zips in `dist/packs/` are stale. |
| 2026-11-23 | User: capstones are modular: one `platform` contract + backends Python, ASP.NET, Go, Rust + web Angular and React + mobile Flutter and Kotlin (mobile on ASP.NET/Python/Go only). Every capstone has a TDD first. |
| 2026-11-23 | User: also TDD-only practice capstones, 1 to 3 month sprints in weekly phases (11 planned in `capstones/_practice/`). Android Studio + SDK 37.2 are installed (Kotlin can be verified). |
| 2026-11-23 | Tutorial tooling lives in `Code101\.github`; stack bundles go to the Claude templates repo in the wave that needs them. |
