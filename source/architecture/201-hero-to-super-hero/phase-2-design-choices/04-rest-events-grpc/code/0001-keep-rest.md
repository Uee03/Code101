# ADR 0001: Keep REST for the client-facing API

Status: Accepted (recorded after the fact from the platform TDD, section 4)
Date: 2026-11-23
Owner: Platform maintainers

## Context
Web and mobile clients call one backend. Four backends in different languages must implement the same interface, and browsers are among the callers.

## Options
- REST over HTTP and JSON, described by one OpenAPI file. Cost: chatty for some screens and no push.
- gRPC. Cost: browsers need a translation layer, and the cost of the extra tooling is paid by every client.
- Events only. Cost: a client that must show the result of its own action cannot wait for a consumer.

## Decision
Use REST with OpenAPI as the client-facing contract. Events remain an option for work between backend parts.

## Consequences
- Benefit: every client and every backend language reads the same contract; HTTP caching and curl-based debugging work.
- Cost or risk: other parties that want to react to task changes would have to poll.

## Revisit when
A second consumer needs to react to task changes and polling is measured to be a problem. Reviewer: the platform maintainers.
