# Production readiness review

Service: <name>
Reviewed by: <names>
Date: <date>

Score every row: 0 = missing, 1 = partly, 2 = done and evidenced.
Rows marked MUST cannot be 0 for a launch. Write the evidence (a link, a command and its result), not a promise.

| Area | Check | MUST | Score | Evidence |
|------|-------|------|-------|----------|
| Security | Runs as non-root, read-only root, no extra capabilities | yes | | |
| Security | Images pinned by digest and signed; base image policy passes | yes | | |
| Security | No secrets in images, environment files in Git or logs | yes | | |
| Security | Only needed ports published; databases never published | yes | | |
| Reliability | Health checks or probes reflect real readiness | yes | | |
| Reliability | At least two replicas and a disruption budget, or a written reason | no | | |
| Reliability | Rollback tested with the real release process | yes | | |
| Reliability | Restart policy and shutdown handling (SIGTERM) verified | yes | | |
| Observability | RED metrics, structured logs and traces exist | yes | | |
| Observability | Page alerts exist for symptoms and each has a runbook | yes | | |
| Data | Backup runs on a schedule and is stored off the host | yes | | |
| Data | Restore drill passed in the last quarter; RPO and RTO measured | yes | | |
| Capacity | Requests and limits come from measurements; autoscaling bounded | no | | |
| Capacity | Log and metric retention fit the disk; rotation configured | yes | | |
| Operations | On-call owner and escalation path named | yes | | |
| Operations | Upgrade plan for the runtime, base images and database | no | | |

Result: launch only if no MUST row is 0 and the total is at least 70 percent of the maximum.
Open risks accepted by the owner, with an expiry date:
-
