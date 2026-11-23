# Traceability: scenarios, decisions, diagrams and risks

Every quality scenario should lead to a decision that serves it, a diagram that shows it and a risk that watches it. Empty cells are gaps to close.

| Scenario | Decision | Diagram | Risk |
|---|---|---|---|
| Q1 listing tasks | Cursor pagination on indexed columns, no ADR yet | components-backend.mmd | none yet |
| Q2 probing another team | Team membership check, 404 for non-members, no ADR yet | components-backend.mmd | none yet |
| Q3 adding a backend | ADR 0001 keep REST, contract first | containers.mmd | R5 |
| Q4 short identity outage | ADR 0002 local token validation | containers.mmd | R1, R3, R4 |
| Q5 concurrent edit | ADR 0003 rules in database functions | components-backend.mmd | R2 |
| Q6 repeated create | Idempotency handler, no ADR yet | components-backend.mmd | none yet |
