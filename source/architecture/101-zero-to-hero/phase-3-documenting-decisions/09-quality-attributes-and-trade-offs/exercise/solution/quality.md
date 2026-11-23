# Reweight the Tasks and Teams options

These are hypothetical estimates, not measurements.
Scale: 1 poor fit, 2 partial fit, 3 good fit.
Keep the team-access security gate unchanged.
New weights: performance 4, security 3, availability 2.

| Option | Performance | Security | Availability | Weighted total |
|---|---:|---:|---:|---:|
| A: API reads PostgreSQL | 2 | 3 | 2 | 21 |
| B: API checks access then reads a team-scoped cache | 3 | 2 | 2 | 22 |

A total: 4 x 2 + 3 x 3 + 2 x 2 = 21.
B total: 4 x 3 + 3 x 2 + 2 x 2 = 22.
Decision: B ranks first under these new weights, not as a universal winner.
Do not adopt B until team-access checks and cache invalidation are evidenced.
The security gate can reject B regardless of its total.
