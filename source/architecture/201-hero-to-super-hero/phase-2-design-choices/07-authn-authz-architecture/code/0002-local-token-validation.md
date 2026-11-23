# ADR 0002: Validate access tokens locally in each backend

Status: Accepted (recorded after the fact from the platform TDD, section 4)
Date: 2026-11-23
Owner: Platform maintainers

## Context
Every request carries a short-lived access token issued by Keycloak. Four backends must check it, and a network call to the identity service on every request would add a delay and a dependency.

## Options
- Check the signature, issuer, audience and expiry locally with cached public keys. Cost: a revoked token stays usable until it expires.
- Ask the identity service about every token (introspection). Cost: one extra network call per request and a hard dependency on the identity service.

## Decision
Validate locally with cached keys. Keep token lifetimes short so the revocation delay stays small.

## Consequences
- Benefit: no per-request hop to Keycloak; a short Keycloak outage does not stop requests that carry valid tokens.
- Cost or risk: revocation takes effect only when the token expires; a leaked token works until then.

## Revisit when
Security review requires immediate revocation for some operations. Reviewer: the platform maintainers. Then protect only those operations with an introspection check.
