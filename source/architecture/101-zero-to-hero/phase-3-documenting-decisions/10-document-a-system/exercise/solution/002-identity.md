# ADR 002: Use an external identity provider

Status: Proposed
Date: 2026-11-23
Owner: Community Library team

## Context
Members must see only their own loans; the library cannot maintain passwords.

## Options
- External identity provider: shared expertise but an extra dependency.
- Build sign-in: local control but ongoing password security work.

## Decision
Delegate sign-in and validate access tokens in the Library API.
The API derives member identity from the validated token, not a requested member id.

## Consequences
- Benefit: the library does not collect passwords.
- Cost or risk: identity outages can prevent new sign-ins.

## Revisit when
The library team reviews when provider terms or availability needs change.
