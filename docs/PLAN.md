# Code101 master plan

Status: **EXECUTING.** Wave 0 (foundation) is built and the Python 101 Phase 1 pilot is written and verified;
the rest follows the waves in section 6. Live status is in [CONTEXT.md](../CONTEXT.md).
Companion files: [CONTEXT.md](../CONTEXT.md) (live state), [CURRICULUM.md](CURRICULUM.md) (topics),
[AGENTS-SKILLS-PLAN.md](AGENTS-SKILLS-PLAN.md) (tooling), [LINKS.md](LINKS.md) (sources),
[RECOMMENDATIONS.md](RECOMMENDATIONS.md) (how to make learning easier).

## 1. Goal

Three progressive courses ("levels") for every track, so anyone from any field can go from nothing to
senior-level skill, plus full-stack capstones that combine tracks.

| Level | Name | From -> to | Code |
|-------|------|-----------|------|
| 1 | Zero to Hero | no experience -> confident junior | `101` |
| 2 | Hero to Super Hero | junior -> advanced/intermediate developer | `201` |
| 3 | Super Hero to Legendary | intermediate -> senior level | `301` |

## 2. Decisions

| # | Question | Decision |
|---|----------|----------|
| D1 | What does "101 tutorials" mean? | **Working default, not yet confirmed by you:** "101" is the course brand; each track gets as many lessons as it needs (budget in section 4, about 630). A curated **"Flagship 101" path per level** will be picked from the pool at the end. Tell me if you meant something else. |
| D2 | Where do the agents/skills live? | **Decided:** tutorial tooling in `Code101\.github` (built). Stack agents/skills (Go, Rust, React, Kotlin/Compose, Web, patterns, architecture, identity) are authored in `F:\Projects\Git\Claude\AgenticAssisstance\templates\<stack>` in the wave that needs them. See [AGENTS-SKILLS-PLAN.md](AGENTS-SKILLS-PLAN.md) |
| D3 | Rendered site? | Markdown first; MkDocs Material in the last wave |
| D4 | Language | English |
| D5 | Missing toolchains (section 7) | **Partly done by you:** Go, Rust, WSL2 and Docker Desktop are installed (Docker engine must be started). Still missing: CMake, Postgres client, Angular CLI, Android SDK, Supabase CLI. Unity stays local, never in Docker |
| D6 | Order if time runs short | Wave order in section 6 |
| D7 | Security, identity, API craft | **Decided by you:** taught inside capstones, no separate tracks (see `designing-capstones` skill and section 5) |
| D8 | WebGL | **Decided by you:** dropped. Unity keeps its shader lessons |
| D9 | Source packs | **Decided by you:** every level of every track and capstone ships a source pack split into phases (section 10) |
| D10 | Art folder | **Decided:** `F:\Projects\Git\Art`. Only the 549 **CC0** plain icons, 12 loaders and the Uee03 brand marks are copied into `assets/art`. Your proprietary animated/moon/weather/particle/loader packs are **not** bundled (their LICENSE forbids redistribution). Tell me if you want any added |

## 3. Scope: tracks

- Languages: Python, C#, C, C++, Go, Rust, Web Foundations (HTML + CSS + TypeScript).
- Frameworks/engines: Angular, React, Flutter, Kotlin + Jetpack Compose, Unity (incl. shaders).
- Data/platform: Databases (PostgreSQL first, SQL Server/SQLite notes), Supabase, Docker, Ollama, System Architecture (diagrams).
- Cross-cutting: Design Patterns + SOLID (every pattern in the refactoring.guru catalog).
- Capstones: full-stack, microservice and monolith builds (section 5). **Security, identity (Keycloak, Authentik) and API craft
  (DTOs, response objects, errors, versioning) are chapters inside the capstones.**

Dropped: WebGL/Three.js/WebGPU (D8), and separate API Craft and Identity tracks (D7).
My recommendation for the folded-in topics: a **topic finder** (`docs/TOPIC-FINDER.md`, built in Wave 2) that maps every topic ("JWT validation",
"problem details", "stored procedures", "RLS") to the capstone chapter that teaches it, and a **production readiness checklist** per capstone.

## 4. Lesson budget

One lesson = 15 to 25 minutes, one idea, one runnable example, one exercise.

| Group | Tracks | 101 / 201 / 301 | Per track | Total |
|-------|--------|-----------------|-----------|-------|
| Languages | Python, C#, C, C++, Go, Rust | 12 / 10 / 8 | 30 | 180 |
| Web Foundations | HTML, CSS, TypeScript | 14 / 12 / 10 | 36 | 36 |
| Frameworks | Angular, React, Flutter, Kotlin+Compose, Unity | 12 / 10 / 8 | 30 | 150 |
| Platform | Databases, Architecture | 12 / 10 / 8 | 30 | 60 |
| Platform | Supabase, Docker | 8 / 8 / 8 | 24 | 48 |
| Platform | Ollama | 6 / 6 / 6 | 18 | 18 |
| Cross-cutting | Design Patterns + SOLID | 8 / 12 / 10 | 30 | 30 |
| Capstones | 9 built capstones (about 6 to 16 chapters each) + 11 TDD-only practice capstones | - | - | about 110 chapters |
| **Total** | | | | **about 630** |

The budget is a target, not a promise; each track's `_STATE.md` records actuals.

## 5. Capstones (restructured 2026-11-23, user decision: modular)

One domain ("Tasks and Teams"), one shared **platform contract**, and interchangeable parts. Security, identity and API craft are chapters here (D7).
Every capstone has a **Technical Design Document (TDD)** written first (`writing-tdds` skill; agent `Technical Design Author`). Details: `designing-capstones` skill.

**Built capstones (source code ships, phased packs):**

| Id | Project | Stack |
|----|---------|-------|
| `platform` | Contract, schema, seed, Keycloak realm, shared Compose, conformance smoke script | OpenAPI 3.1, Postgres, Keycloak |
| `backend-python` | Backend | FastAPI + Uvicorn + SQLAlchemy/Alembic |
| `backend-dotnet` | Backend | ASP.NET Core + FastEndpoints + EF Core + stored procedures |
| `backend-go` | Backend | Go + chi/stdlib + pgx/sqlc |
| `backend-rust` | Backend | Rust + Axum + SQLx |
| `web-angular` | Web client (parallel chapters with React) | Angular + Signals + RxJS |
| `web-react` | Web client | React + TanStack Query |
| `mobile-flutter` | Mobile client, any of ASP.NET / Python / Go backend (not Rust) | Flutter |
| `mobile-kotlin` | Mobile client, any of ASP.NET / Python / Go backend (not Rust) | Kotlin + Jetpack Compose |

Any web or mobile client runs against any allowed backend because all backends pass the same conformance script (9 builds instead of 14 pairings).

**Practice capstones (TDD only, no source, 1 to 3 month sprints in weekly phases):** 11 projects in `capstones/_practice/`:
P01 Inventory and orders (4 wk), P02 Booking and scheduling (4 wk), P03 Team chat and notifications (6 wk), P04 Offline-first field-service mobile app (8 wk),
P05 Multi-tenant SaaS billing (8 wk), P06 Document search and RAG with Ollama + pgvector (8 wk), P07 Event-driven order processing / microservices (12 wk),
P08 IoT telemetry dashboard (8 wk), P09 C++ desktop app (6 wk), P10 C systems utility with a desktop front end (4 wk), P11 Unity vertical-slice game (8 wk, local only).
The earlier Supabase, microservice, local-AI and C/C++ capstone ideas live on as practice TDDs.

Flutter/Kotlin-friendly backend rules (all backends): OpenAPI-first contract, generated clients, OIDC code flow with PKCE (Keycloak), RFC 9457 problem
details, cursor pagination, ETag/idempotency keys, versioned DTOs.

Angular and React get **parallel lessons** (same domain, API, screens and lesson numbers) so learners can pick one or compare.

## 6. Execution waves

| Wave | Work | Status |
|------|------|--------|
| 0 Foundation | Tutorial agents/skills/prompts, lesson template, source-pack and verifier scripts, curated art, Python 101 Phase 1 pilot | **Done**, pilot under review |
| 1 Core | Web Foundations, Python, C#, Databases, Docker, Design Patterns + SOLID | Next (Python 101 phases 2 and 3 first) |
| 2 Full stack | Angular, React, Supabase, capstones C1 to C6, C9, topic finder | |
| 3 More backends/mobile | Flutter, Kotlin+Compose, Go, Rust, capstones C7, C8, C10 | Needs toolchain installs (D5) |
| 4 Specialist | C, C++ (desktop), Unity, Ollama, System Architecture, capstones C11 to C14 | |
| 5 Simulation | Persona walk-throughs (section 8), fixes, MkDocs site, flagship 101 paths | |

Parallelism: within a wave each track is written by its own background agent with a small **context
pack** (section 9). I review each track's `_STATE.md`, not every lesson.

## 7. Environment facts (checked 2026-11-23)

Installed: Python 3.15.2, .NET SDK 11.0.100, Node 26.13.1 / npm 11.20.0, Flutter 3.50.1, JDK 25, Ollama
CLI (server not running).
**Missing:** Docker, Go, Rust/cargo, gcc/g++/MSVC, CMake, psql/Postgres, Angular CLI, kotlinc and Android
SDK, Supabase CLI. Nothing has been installed yet (D5). The verifier reports lessons whose tools are
missing as UNVERIFIED, never as passed. Python, C#, TypeScript/Node (Web, React, Angular after `npm`),
and Flutter lessons can be verified now; Docker, Go, Rust, C/C++, Kotlin, Postgres and Supabase need installs.

## 8. Persona walk-through (your final step)

Three review agents (`learner-beginner`, `learner-intermediate`, `learner-senior`) follow the finished
material literally in a clean working folder: run every command, type every code block, attempt every
exercise, and log friction to `reviews/<track>-<level>.md` (blocked, confusing, wrong, missing
prerequisite, too long). Fixes go back through the track author agent. Pass criteria: all labs run, no
term used before it is introduced, every exercise has a solution, and the senior pass finds no outdated
or unsafe advice.

## 9. Token-saving rules (also in [CONTEXT.md](../CONTEXT.md))

1. Read `CONTEXT.md` first, then only the track's `_STATE.md`. Never reload the full link list.
2. Each track has a one-page **brief** (audience, lesson list with one-line goals, terminology, version
   pins, source links by tier). Authors work from the brief, not the raw links.
3. Search, then view line ranges. Do not re-read finished lessons; read their `_STATE.md` index lines.
4. Lessons come from one template; reviewers check against a checklist, not free reading.
5. Update `CONTEXT.md` at the end of every work block: done, in progress, next, open questions.
6. Cheap model for scaffolding and link checks, strong model for writing and review (existing
   `model-routing` skill tiers).

## 10. Lesson anatomy, source packs and layout

Each lesson: front matter (track, level, phase, number, time, prerequisites, versions, verified date, source folder,
art used), then Why it matters, What you will build, Before you start, **Steps (every step shown)**, Run it,
How it works, Try it (starter + solution), Check yourself, Common mistakes (real error text), Best practice
(sourced), Next lesson. Full template: `.github/skills/authoring-tutorials/reference/lesson-template.md`.
"Refer to previous steps" is used only when steps are genuinely identical, and the differences are listed.

**Source packs (D9):** every level of every track has code split into **phases** (3 to 5 phases per level, 3 to 4
lessons per phase). `python scripts/build_packs.py` builds one zip per phase, one zip per level, and the art library into `dist/packs/`.
Example: `python-101-phase-1-foundations.zip`, `python-101-all.zip`. Each lesson folder holds `code/`,
`exercise/starter`, `exercise/solution`, `verify.json`; `python scripts/verify_labs.py` runs them in a clean copy
and also checks that the lesson text contains every line of the code and its expected output.

```
tutorials/<track>/{101-zero-to-hero,201-hero-to-super-hero,301-super-hero-to-legendary}/phase-<n>-<slug>/NN-slug.md
tutorials/<track>/{_BRIEF.md,_STATE.md,GLOSSARY.md}
source/<track>/<level>/phase-<n>-<slug>/{PACK-README.md, NN-slug/{code,exercise,verify.json}}
capstones/Cxx-name/{README.md, tutorials/, source/phase-<n>-<slug>/}
assets/art/                 CC0 icons, loaders, brand marks (D10)
scripts/                    build_packs.py, verify_labs.py, check_links.py
reviews/                    persona walk-through logs
dist/packs/                 built zips (git-ignored)
docs/  .github/{agents,skills,prompts,copilot-instructions.md}
```

## 11. Next decisions for you

1. Confirm or change D1 (what "101" means) and D10 (which art you want bundled).
2. Review the pilot: `tutorials/python/101-zero-to-hero/phase-1-foundations/` and `dist/packs/python-101-phase-1-foundations.zip`.
3. Approve toolchain installs (D5) before Wave 3.
