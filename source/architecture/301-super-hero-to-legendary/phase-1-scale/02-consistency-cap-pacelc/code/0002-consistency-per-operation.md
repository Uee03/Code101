# ADR 0002: Choose consistency per operation

Status: Proposed
Date: 2026-11-23
Owner: Platform maintainers

## Context
A system with replicas or events cannot be strongly consistent everywhere without paying in availability and latency. Some operations lose data if they read old values; others are harmless when briefly old.

## Options
- Strong consistency for every read and write. Cost: higher latency and more refused requests when a node is unreachable.
- Eventual consistency for everything. Cost: lost updates and duplicates in operations that depend on the latest value.
- Choose per operation and write the choice down. Cost: more design effort and a table to maintain.

## Decision
Choose per operation. Writes and reads that precede a write are strong. Lists, reports and read models may be eventual, with their lag measured and displayed.

## Consequences
- Benefit: correctness where it matters and speed where staleness is harmless.
- Cost or risk: developers must know which operations are which, and a mistake in the table is a defect.

## Revisit when
A user-visible defect is traced to a stale read, or the measured lag of an eventual operation exceeds what users accept. Reviewer: the platform maintainers.
