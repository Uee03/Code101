# ADR 004: Assign documentation review ownership

Status: Proposed
Date: 2026-11-23
Owner: Tasks and Teams maintainers

## Context
The platform has several clients and interchangeable backends.
Diagram changes can become inconsistent with the shared contract.

## Options
- One platform reviewer: consistent but can delay changes.
- Any client reviewer: faster but can miss backend effects.

## Decision
Ask one platform maintainer and one affected client maintainer to review.

## Consequences
- Benefit: both ends of a contract change are represented.
- Cost or risk: two reviewers need time to coordinate.

## Revisit when
Maintainers review if three consecutive changes wait over five working days.
