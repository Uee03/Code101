# ADR 003: Agree the OpenAPI contract first

Status: Accepted for the teaching platform
Date: 2026-11-23
Owner: Tasks and Teams maintainers

## Context
Different client and backend teams must agree on request shapes.
A client should not change when a conforming backend is swapped.

## Options
- Agree one OpenAPI description before implementation.
- Let each backend publish an independently generated description.

## Decision
Use the platform openapi.yaml as the shared contract first.
Review contract changes with client and backend maintainers.

## Consequences
- Benefit: teams can work against one agreed interface.
- Cost or risk: the description and implementations can drift apart.

## Revisit when
Maintainers review when a breaking client change is proposed.
