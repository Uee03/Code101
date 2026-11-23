# ADR 001: Keep shared work records in PostgreSQL

Status: Accepted for the teaching platform
Date: 2026-11-23
Owner: Tasks and Teams maintainers

## Context
Four alternative backends must share teams, projects and tasks.
Related changes must be saved together or not at all.

## Options
- PostgreSQL with relationships and transactions.
- Separate JSON files with application-managed consistency.

## Decision
Use PostgreSQL as the source of truth for work records.
Keep shared atomic work rules in the platform stored functions.

## Consequences
- Benefit: constraints and atomic changes are shared by all backends.
- Cost or risk: schema changes need migrations and database skills.

## Revisit when
Maintainers review if a required client cannot use the shared schema.
