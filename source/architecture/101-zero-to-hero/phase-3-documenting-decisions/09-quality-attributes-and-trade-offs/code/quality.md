# Tasks and Teams: quality decision worksheet

Audience: product, support and implementation teams.
Scope: choosing the first production task-list read design.
Scores below are discussion estimates, not measured evidence.
The platform does not currently have a response cache.

## Scenarios and hard gates
- Performance: 95 of 100 task-list reads finish within 500 ms at 20 concurrent users.
- Security: a signed-in non-member never receives another team's task data.
- Availability: 99.5 percent of task-list reads succeed over a calendar month.
- Hard gate: reject a design that cannot enforce team access on every read.

## Comparison
Scale: 1 poor fit, 2 partial fit, 3 good fit for these scenarios.
Weights: performance 2, security 3, availability 2.

| Option | Performance | Security | Availability | Weighted total |
|---|---:|---:|---:|---:|
| A: API reads PostgreSQL | 2 | 3 | 2 | 17 |
| B: API checks access then reads a team-scoped cache | 3 | 2 | 2 | 16 |

A total: 2 x 2 + 3 x 3 + 2 x 2 = 17.
B total: 3 x 2 + 2 x 3 + 2 x 2 = 16.
B's security score reflects extra risks to manage, not permission to leak data.
B needs permission-aware cache keys, invalidation and a safe database fallback.

## Decision and uncertainty
Start with A because it has fewer moving parts and no cache invalidation burden.
Neither option proves the security gate or the availability target by scoring well.
Measure read durations and denied cross-team reads before accepting production readiness.
Review failed reads over a month; plan backups and test recovery separately.
Revisit caching if the performance scenario fails after query review.
Owner: Tasks and Teams maintainers.
