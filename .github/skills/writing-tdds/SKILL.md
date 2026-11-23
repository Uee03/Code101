---
name: writing-tdds
description: 'Writes a Technical Design Document (TDD) for a Code101 capstone: full scope, requirements, architecture, data model, API, auth flows, security, verification plan and phase plan. Two kinds: built capstones (source code ships, TDD is the spec) and practice capstones (TDD only, the learner builds it in a 1 to 3 month sprint). Use when planning or documenting a capstone, or when the user says TDD, design doc, spec, or practice project.'
---

# Writing TDDs

**Best model:** Plan tier (Claude Sonnet 5.5) via the Technical Design Author. Read-only on code; writes only the TDD files.

A TDD gives the learner **full scope** before they write a line: what is built, why, how the parts fit, what "done" means.
Use [reference/tdd-template.md](reference/tdd-template.md) (built capstones) or
[reference/practice-tdd-template.md](reference/practice-tdd-template.md) (practice, no source).

## Where files go

| Kind | Path |
|------|------|
| Platform contract TDD | `capstones/platform/TDD.md` |
| Built capstone TDD | `capstones/<id>/TDD.md` |
| Practice capstone TDD | `capstones/_practice/<NN-slug>/TDD.md` (plus optional `diagrams/*.mmd`) |

Built capstones: `platform`, `backend-python`, `backend-dotnet`, `backend-go`, `backend-rust`, `web-angular`, `web-react`,
`mobile-flutter`, `mobile-kotlin`. All implement the platform contract and the domain "Tasks and Teams".

## Rules

1. **Spec first, then code.** A built capstone's TDD is written before its source and the source must match it (requirement ids `R-xx` trace to
   a phase and a smoke check). Practice TDDs never ship source.
2. **Be concrete.** Real endpoint tables, real entity fields and types, real status codes, real diagrams (Mermaid, valid syntax). No "TBD".
3. **Traceability.** Every requirement has an id, a priority (MoSCoW) and an acceptance check. Every phase lists the requirement ids it delivers.
4. **Security and identity are designed here**: auth flows as sequence diagrams, roles and scopes tables, data protection, OWASP API Top 10 mapping.
5. **Cite Tier 1 sources** from `docs/LINKS.md` / official docs for every standard claimed (OIDC, RFC 9457, OpenAPI, Keycloak, Postgres).
6. **Verification plan = smoke test only** (environment starts, one request works), Docker temporary and cleaned up (see `verifying-labs`).
7. **Practice TDDs** state the sprint length (1 to 3 months), split into weekly phases with exit criteria, give a grading rubric, stack options
   and hints, and list stretch goals. They never include a solution, only enough design hints to start.
8. Diagram syntax must render: check Mermaid with the `writing-mermaid` rules (quote labels with special characters, no tabs).
9. Keep each TDD between about 150 and 400 lines; link to the platform contract instead of repeating it.
