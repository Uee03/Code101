# TDD template: built capstone

Copy the structure. Every section is required; write "None" if it truly does not apply.

````markdown
# TDD: <Capstone name>

| Field | Value |
|-------|-------|
| Id | <platform / backend-python / ...> |
| Level | 201 or 301 |
| Status | Draft / Approved / Built / Verified |
| Depends on | <capstone ids> |
| Stack | <languages, frameworks, versions verified against official docs, date> |
| Estimated learner time | <weeks, hours per week> |
| Last updated | <date> |

## 1. Purpose and learning goals
What is built, who it serves, and the 5 to 8 skills the learner gains.

## 2. Scope
In scope / out of scope / assumptions / constraints.

## 3. Requirements
| Id | Requirement | Priority (MoSCoW) | Acceptance check | Phase |
|----|-------------|-------------------|------------------|-------|
| R-01 | ... | Must | `GET /health` returns 200 | 1 |

Non-functional requirements (performance targets with numbers, availability, accessibility, i18n) in a second table.

## 4. Architecture
Context diagram (C4 level 1) and container diagram (C4 level 2) as Mermaid, one paragraph per component, technology choices with
"Why this, not that" for each major decision (ADR-style: decision, alternatives, consequences).

## 5. Domain and data model
ER diagram (Mermaid), table of every entity with columns, types, constraints, indexes. Migration strategy. Seed data.

## 6. API design
Table: method, path, auth/role, request DTO, response DTO, success status, error statuses. Error format (RFC 9457 problem details),
pagination, filtering, versioning, idempotency, rate limits. Link the OpenAPI file.

## 7. Identity and security design
Auth flow sequence diagram(s), roles/scopes table, token validation rules, secrets handling, CORS, data protection, OWASP API Top 10 mapping
(risk, mitigation here), threat model summary (assets, entry points, top threats).

## 8. Project structure
Folder tree, layering rules and dependency direction, naming conventions, configuration and environment variables.

## 9. Delivery plan (phases)
| Phase | Title | Chapters | Requirement ids | Exit check (smoke) | Source pack |
|-------|-------|----------|-----------------|--------------------|-------------|

## 10. Verification plan
Smoke steps only: how the environment is started (temporary Docker), the one-request checks, how it is cleaned up. Conformance with the platform contract.

## 11. Deployment and operations
Docker/Compose files (names, ports from the host-port table), environment variables, logging, health checks, backups.

## 12. Risks, open questions, decisions
| Risk or question | Impact | Mitigation / decision |

## 13. References
Tier 1 links with titles.
````
