# ADR 001: Store loans in PostgreSQL

Status: Proposed
Date: 2026-11-23
Owner: Community Library team

## Context
Each loan must refer to an existing member and book.

## Options
- PostgreSQL: relationships but database administration.
- JSON files: simple files but manual consistency rules.

## Decision
Use PostgreSQL for member, book and loan records.

## Consequences
- Benefit: the database can enforce references.
- Cost or risk: the team must manage schema changes and backups.

## Revisit when
The library team reviews when its support budget changes.
