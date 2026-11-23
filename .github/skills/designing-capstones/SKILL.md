---
name: designing-capstones
description: 'Designs and structures Code101 capstones: one shared platform contract, four backends (Python, ASP.NET, Go, Rust), two web clients (Angular, React), two mobile clients (Flutter, Kotlin), plus TDD-only practice capstones. Covers where API craft, identity and security are taught. Use when planning or writing a capstone, pairing a backend with a client, or creating a practice project.'
---

# Designing capstones

**Best model:** Plan tier to design, Act tier to write.

Capstones replace separate Security, Identity and API Craft tracks: those topics are chapters of real projects.
Every capstone starts from a **Technical Design Document** (`writing-tdds` skill) and ships phased source packs (`source-packs` skill).

## The built set (modular, decided 2026-11-23)

One domain, "Tasks and Teams", one contract, mix and match.

| Id | Project | Depends on |
|----|---------|------------|
| `platform` | OpenAPI 3.1 contract, Postgres schema + seed, Keycloak realm export, shared Compose infra, conformance smoke script | none |
| `backend-python` | FastAPI + Uvicorn + SQLAlchemy/Alembic, stored procedure access | platform |
| `backend-dotnet` | ASP.NET Core + FastEndpoints + EF Core + stored procedures | platform |
| `backend-go` | Go (stdlib/chi, pgx, sqlc) | platform |
| `backend-rust` | Rust (Axum, SQLx) | platform |
| `web-angular` | Angular (Signals, RxJS, generated client, Keycloak PKCE) | platform + any backend |
| `web-react` | React (hooks, TanStack Query, generated client, Keycloak PKCE) | platform + any backend |
| `mobile-flutter` | Flutter app, OIDC PKCE, offline cache | platform + ASP.NET, Python or Go backend |
| `mobile-kotlin` | Kotlin + Jetpack Compose app, OIDC PKCE, Room cache | platform + ASP.NET, Python or Go backend |

Mobile apps are taught against the ASP.NET, Python and Go backends (not Rust). Because every backend passes the same conformance smoke
script, a client works with any of them: the backend is chosen with one environment variable. Angular and React get **parallel chapters**
(same screens, same numbering); apply the "genuinely identical steps" rule only when the steps really match.

## Practice capstones (TDD only)

`capstones/_practice/<NN-slug>/TDD.md`: no source. Sized as 1 to 3 month sprints, broken into weekly phases with exit criteria, rubric,
stack options, stretch goals and hints. They reuse the Code101 lessons as references.

## Standard phases for a backend capstone (each phase pack holds the whole project at that point)

| Phase | Chapter | Taught here |
|-------|---------|-------------|
| 1 Skeleton | Project layout, config, health endpoint, implement the contract's first resources | REST rules, status codes, DTOs vs entities, response objects, RFC 9457 problem details, validation |
| 2 Data | Migrations, repository, **stored procedures**, ORM/driver, transactions | Parameterised queries, least-privilege DB user, optimistic concurrency, pagination, filtering, idempotency keys |
| 3 Identity | Keycloak token validation, roles and scopes, ownership checks (Authentik appendix) | OAuth2/OIDC, JWT validation (issuer, audience, expiry, keys), roles vs scopes |
| 4 Run and ship | Dockerfile, Compose profile, healthchecks, CI | Non-root images, secrets via env, multi-stage builds |
| 5 Hardening | OWASP API Top 10 walk-through, rate limiting, security headers, logging and audit, backup and restore | Production checklist |

Client capstones (web and mobile): 1 Setup and generated client, 2 Auth (PKCE) and token storage, 3 Screens and state, 4 Errors, offline and polish,
5 Build, run and ship.

## Rules

1. TDD first, code second; requirement ids (`R-xx`) trace to phases and smoke checks.
2. Every capstone README has a Mermaid system diagram; the platform TDD owns the domain and API, others link to it.
3. Show all steps and every configuration (Docker, Keycloak realm, `.env`); source packs per phase; smoke verification only; Docker temporary.
4. Keycloak is the primary identity provider; Authentik appears as an appendix mapping each step.
5. Cite Tier 1 sources for each security rule (Keycloak production docs, OWASP, ASP.NET Core best practices, Postgres docs).
6. Unity and desktop capstones are practice TDDs; Unity is never run in Docker.
