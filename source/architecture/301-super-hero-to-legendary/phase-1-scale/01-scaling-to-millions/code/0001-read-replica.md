# ADR 0001: Send only tolerant reads to a read replica

Status: Proposed
Date: 2026-11-23
Owner: Platform maintainers

## Context
If measurement shows that reads dominate the primary database, a read replica can take some of them. Replication is asynchronous, so a replica can lag behind the primary. The platform uses ETag and If-Match: a client that reads an old version from a lagging replica and then sends an update with that version receives a 412.

## Options
- Send every read to the replica. Cost: read-after-write surprises and avoidable 412 responses.
- Send only list and report reads to the replica, and read a single object from the primary when the client is about to change it. Cost: two routes to configure and test.
- Do not add a replica yet. Cost: the primary stays the bottleneck.

## Decision
Adopt the second option only after a measurement shows that reads dominate the primary.

## Consequences
- Benefit: the primary has fewer reads and the update protocol keeps working.
- Cost or risk: lists can be briefly out of date, and the lag must be monitored.

## Revisit when
Measured replica lag makes lists too stale for users, or reads on the primary are no longer the bottleneck. Reviewer: the platform maintainers.
