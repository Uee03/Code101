# Production readiness checklist

Copy this file into your repository and tick every line with evidence (a link, a command output, a dashboard), not with a feeling.

## Build and supply chain
- [ ] The SDK is pinned (`global.json`) and the base images use exact tags that match it.
- [ ] Package versions are central and locked; the restore runs in locked mode in CI.
- [ ] `TreatWarningsAsErrors` is on and the NuGet audit reports no known vulnerabilities.
- [ ] The image is built from a clean checkout in CI, not from a laptop; the build is reproducible.
- [ ] Images are scanned and signed or have a provenance record.

## Configuration and secrets
- [ ] No secret in the repository, the image or `appsettings.json`; secrets come from a store or the platform.
- [ ] Configuration differs only by environment variables or mounted files, not by code.
- [ ] Every setting has a safe default and the service refuses to start on invalid configuration.

## Security
- [ ] Every endpoint declares its authentication and authorization; anonymous is explicit.
- [ ] Tokens are validated for signature, issuer, audience and lifetime; roles are checked per operation.
- [ ] Input is validated at the edge; output never contains stack traces or internal details.
- [ ] CORS, security headers and rate limits are set deliberately; request size limits exist.
- [ ] The container runs as a non-root user with a read-only file system and no extra capabilities.

## Reliability
- [ ] Every outbound call has a timeout, safe retries, a circuit breaker and a bulkhead.
- [ ] Side effects use an outbox and idempotent consumers; non-idempotent requests carry idempotency keys.
- [ ] Liveness and readiness probes exist and check different things.
- [ ] The service shuts down gracefully within the platform's termination period.
- [ ] A load test and a failure test (dependency down, slow, restarting) have been run and recorded.

## Observability
- [ ] Logs are structured, carry the trace id and contain no secrets or personal data.
- [ ] Metrics cover rate, errors and duration, plus saturation of pools and queues.
- [ ] Traces cross every service boundary and the message broker.
- [ ] Alerts exist for symptoms users feel, each with an owner and a runbook.

## Performance and capacity
- [ ] The performance budget is written down and measured, not guessed.
- [ ] Memory and CPU limits are set from measurements and the service is tested at those limits.
- [ ] Caches have staleness budgets, bounded size and a cold-start plan.

## Data
- [ ] Migrations are backward compatible (expand, migrate, contract) and tested on a copy of production-sized data.
- [ ] Backups are taken and a restore has been rehearsed.
- [ ] Retention and deletion rules exist for personal data.

## Operations
- [ ] A rollback takes minutes and has been rehearsed.
- [ ] Deployments are gradual (canary or rolling) with an automatic stop on error rate.
- [ ] On-call knows the service, the dashboards and the runbook.
- [ ] Dependencies and their owners are listed, with the expected behavior when each one fails.
