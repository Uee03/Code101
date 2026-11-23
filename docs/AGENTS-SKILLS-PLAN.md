# Agents and skills plan

Gap analysis against what already exists in `F:\Projects\Git\Claude\AgenticAssisstance\templates`
(source of truth; also mirrored in `Git\Claude\AgenticReasoning\.github`). Conventions to follow: skills
are `<name>/SKILL.md` with `name` + `description` front matter and a "Best model" tier line; agents are
`*.agent.md` with `description`, `name`, `tools`, `model` fallback list (tiers in the `model-routing`
skill); stack bundles also carry `AGENTS.md`, `instructions`, CI, tasks.

## 1. What exists today

| Bundle | Agents | Skills |
|--------|--------|--------|
| workspace | Orchestrator, Planner, Implementer, Deep Researcher, Quick Helper, SVG Designer | model-routing, planning-projects, researching-ideas, modeling-uml, writing-mermaid, designing-diagrams, authoring-svg, language-best-practices (Python, C, C++) |
| python | Reviewer, Scaffolder | project-intake, python-clean-architecture, scaffolding-python-api/desktop/webapp |
| dotnet | Reviewer, Scaffolder | project-intake, dotnet-clean-architecture, dotnet-cqrs, scaffolding-dotnet-api (controllers or FastEndpoints)/webapp/desktop/crossplatform |
| angular | Reviewer, Scaffolder | project-intake, angular-app-architecture, angular-components, primeng-theming, scaffolding-angular-app |
| c-cpp | Reviewer, Scaffolder | c-coding-standard, cpp-core-guidelines, memory-safety, c-cpp-project-structure, c-cpp-testing-and-analysis, c-cpp-interop, project-intake |
| flutter | Reviewer, Scaffolder | project-intake, flutter-app-architecture, flutter-state-and-packages, scaffolding-flutter-app |
| sql | SQL Reviewer | database-selection, sql-schema-design, postgres/sqlite/sqlserver-conventions, sql-migrations, postgres-sql-deployment, efcore-data-access |
| supabase | Scaffolder | supabase-setup, supabase-auth, supabase-database-and-rls, supabase-storage, project-intake |
| unity | Architect, Developer, Performance Auditor, Reviewer, UITK Editor Tools | 29 skills incl. design-patterns (11 patterns), shader-graph, vfx-graph, netcode |
| keycloak | Setup Reviewer | keycloak-oidc |
| ollama | Ollama Reviewer (any OS/GPU), AMD Reviewer | ollama-local-setup (built 2026-11-23, native installs incl. manual), ollama-amd-windows (AMD + Windows GPU) |
| foundations | Deployment Advisor | docker-and-services, choosing-hosting, deploying-with-dokploy, gitignore-setup, project-licensing |
| craft-tools | Sound Designer, Visual Artist | craft-tools, figcraft-ui, soundcraft-audio, vectorcraft-art |

Strong: Python, .NET, Angular, C/C++, Flutter, SQL, Supabase, Unity, diagrams.

## 2. Gaps (nothing exists)

Go, Rust, React, Kotlin + Jetpack Compose, Web Foundations (HTML/CSS/TypeScript),
Authentik, general (non-Unity) Design Patterns + SOLID, API Craft (DTOs, response objects, errors,
versioning; now used by capstone authors), System Architecture principles (C4, ADRs, scaling), full-stack
capstone scaffolding, and **everything tutorial-related** (authoring, review, lab verification, learner
simulation, tracking). WebGL was dropped (decision D8).

## 3. Tutorial tooling (lives in `Code101\.github`) — BUILT 2026-11-23

Built: 8 agents (curriculum-architect, tutorial-author, tutorial-reviewer, lab-verifier, learner-beginner,
learner-intermediate, learner-senior, link-curator), 8 skills (authoring-tutorials, source-packs,
tutorial-quality-checklist, verifying-labs, curriculum-tracking, simulating-learners, curating-links,
designing-capstones), 4 prompts (new-lesson, review-lesson, verify-lab, walkthrough), `copilot-instructions.md`,
and scripts `build_packs.py`, `verify_labs.py`, `check_links.py`. Not yet built: the draw.io/Mermaid hooks for capstone diagrams
(reuse existing `designing-diagrams` and `writing-mermaid` skills from the workspace bundle: copy them into `.github/skills` in Wave 2).

| Type | Name | Tier | Purpose |
|------|------|------|---------|
| Agent | Curriculum Architect | Plan | Turns `_BRIEF.md` into a lesson list; checks prerequisite order and level fit; read-only |
| Agent | Tutorial Author | Act | Writes one lesson plus its `labs/` code from the template and brief; updates `_STATE.md` |
| Agent | Tutorial Reviewer | Plan | Reviews a lesson against the quality checklist; read-only; severity-ranked findings |
| Agent | Lab Verifier | Act | Runs every lab (build, test, run) in a clean folder and reports pass/fail; never edits lessons |
| Agent | Learner: Beginner | Plan | Follows level 101 literally with no assumed knowledge; logs friction |
| Agent | Learner: Intermediate | Plan | Follows 201; challenges clarity, missing steps, and weak exercises |
| Agent | Learner: Senior | Deep | Audits 301 for correctness, outdated or unsafe advice, missing trade-offs |
| Agent | Link Curator | Quick | Checks links, assigns tiers, updates `docs/LINKS.md` |
| Skill | authoring-tutorials | Act | Lesson template, voice per level, analogy bank by field, Angular/React parallel rule |
| Skill | tutorial-quality-checklist | Plan | Pass/fail checklist (runs, defined terms, exercise + solution, sourced best practice, accessibility of language) |
| Skill | curriculum-tracking | Quick | The `CONTEXT.md` / `_BRIEF.md` / `_STATE.md` protocol that keeps token use low |
| Skill | verifying-labs | Act | Per-language build/test/run commands and clean-room rules |
| Skill | simulating-learners | Plan | Persona scripts, friction log format, pass criteria |
| Skill | curating-links | Quick | Tier rules and liveness check (script in `scripts/`) |
| Skill | designing-capstones | Plan | Capstone structure (domain, contract-first, compose, diagrams, auth) |
| Prompt | /new-lesson, /review-lesson, /verify-lab, /walkthrough | - | One-line entry points for the above |

## 4. New: stack bundles (author in `templates/<stack>`, then sync to Code101)

| Bundle | Agents | Skills (initial) |
|--------|--------|------------------|
| go | Go Reviewer, Go Scaffolder | go-idioms (Effective Go + Google guide), go-http-api (net/http, chi, pgx/sqlc), go-concurrency, scaffolding-go-api (Flutter-friendly contract) |
| rust | Rust Reviewer, Rust Scaffolder | rust-idioms, rust-error-handling, rust-axum-api (Axum, SQLx, serde), rust-security (cargo audit/deny, unsafe policy), scaffolding-rust-api |
| react | React Reviewer, React Scaffolder | react-best-practices (Vercel + react.dev), react-data-fetching, react-app-architecture, scaffolding-react-app |
| kotlin-compose | Compose Reviewer, Compose Scaffolder | kotlin-conventions, compose-best-practices, compose-performance, android-architecture, android-security |
| web-foundations | Web Reviewer | html-semantics-a11y, css-architecture, typescript-best-practices |
| webgl | (dropped, D8) | - |
| design-patterns | Pattern Advisor | solid-principles, gof-creational, gof-structural, gof-behavioral, patterns-in-practice (generalizes the Unity pattern references) |
| api-craft | API Reviewer (used when writing capstone phase 1) | rest-api-design, dto-and-response-objects, problem-details, openapi-first |
| architecture | Architecture Reviewer | system-architecture-principles, c4-and-adrs, scaling-and-resilience, microservices-vs-monolith |
| identity (extend keycloak) | Identity Reviewer | keycloak-production, keycloak-realm-and-clients, authentik-setup, oidc-pkce-spa-mobile, owasp-api-security |
| fullstack | Full-Stack Scaffolder | scaffolding-fullstack (backend + client + Postgres + compose pairs C1 to C9) |

## 5. Updates to existing assets

| Asset | Update | Source |
|-------|--------|--------|
| workspace `copilot-instructions.md`, `model-routing`, `docs/ai-workflow.md` | Add tutorial agents to routing table and tiers | Section 3 |
| `language-best-practices` | Add reference files for Go, Rust, TypeScript, Kotlin, C# | Tier 1 links |
| python `scaffolding-python-api` + reviewer | FastAPI/Uvicorn run and deploy specifics, DTO vs entity, response models, stored-procedure access, problem details | FastAPI docs |
| dotnet `scaffolding-dotnet-api` + reviewer | Add best-practice checklist from Microsoft docs, Result/ProblemDetails, stored procs, FastEndpoints specific skill | MS Learn |
| `keycloak-oidc`, Setup Reviewer | Production config, hardening, realm export, PKCE for SPA and Flutter | keycloak.org |
| sql `postgres-conventions`, `sql-schema-design` | Indexing, EXPLAIN, HA, pgvector, RLS performance | Tier 1/2 links |
| supabase `database-and-rls` | RLS performance rules, environments | Supabase KB |
| angular skills + reviewer | Signals, RxJS subscription rules, Nx/feature slices | angular.dev |
| flutter skills | OpenAPI client, PKCE login, offline-first, performance | docs.flutter.dev |
| `ollama-amd-windows` | Done 2026-11-23: now covers any native install; generic `ollama-local-setup` skill and Ollama Reviewer added. Still to add: `ollama-app-integration`, `ollama-rag-pgvector` | Ollama docs |
| `docker-and-services` | Multi-stage builds, healthchecks, non-root, secrets, compose profiles | Docker docs |
| unity `unity-shader-graph` | Add HLSL shader basics reference | Tier 2 links |
| c-cpp skills | Add desktop GUI guidance (Qt, Dear ImGui, SDL/GTK/Win32) | Qt/ImGui docs |

## 6. Rules for creating or editing

1. Read one existing skill in the same bundle first and copy its shape.
2. Description states what it does and "Use when..." triggers; body under about 100 lines with detail in
   `reference/` files.
3. Rules cite Tier 1 or Tier 2 sources from `docs/LINKS.md`; no uncited best-practice claims.
4. Review agents are read-only; scaffold/implement agents ask before choosing stack options.
5. After each new or changed asset, update `CONTEXT.md` and the bundle `AGENTS.md`.

## 7. Order of work (Wave 0 unless noted)

1. Tutorial tooling (section 3): all of it, because every later wave depends on it.
2. `design-patterns`, `api-craft`, `identity`: needed by Wave 1 and 2.
3. `react`, `web-foundations`: Wave 1/2. `go`, `rust`, `kotlin-compose`: Wave 3. `architecture`: Wave 4.
4. Updates in section 5 land with the wave that uses them.
5. A final consistency pass: agent names unique, model lists valid, every skill listed in its bundle `AGENTS.md`.
