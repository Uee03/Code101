# ADR 002: Delegate sign-in to Keycloak

Status: Accepted for the teaching platform
Date: 2026-11-23
Owner: Tasks and Teams maintainers

## Context
Web and mobile clients need one identity service.
Backends must not collect or store user passwords.

## Options
- Keycloak as a separate identity service.
- A custom password and sign-in implementation per backend.

## Decision
Use Keycloak with OpenID Connect and PKCE for interactive clients.
Backends validate access tokens and still check team permissions.

## Consequences
- Benefit: clients share sign-in rather than duplicating passwords.
- Cost or risk: sign-in depends on another service and its configuration.

## Revisit when
Maintainers review if identity operations exceed the support budget.
