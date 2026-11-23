# Failure modes table

Detection means how a person or a program finds out. Numbers such as timeouts are chosen from measurements and are not in this table.

| Call | Failure mode | Detection | Effect without protection | Protection and degraded behaviour |
|---|---|---|---|---|
| Client to platform API | Responses become slow | Latency percentile per endpoint, client timeout | Users wait and retry, which adds load | Client timeout; retries only for idempotent calls or with an Idempotency-Key; rate limit answers 429 with Retry-After |
| Platform API to PostgreSQL | All connections in use | Wait time for a connection, health endpoint reporting 503 | Every request waits for a connection and then fails | Bounded pool, short wait for a slot, fail fast with 503, alert |
| Platform API to Keycloak keys | Keys cannot be fetched for an unknown key id | Failed refresh counter | Tokens signed with a new key are rejected | Keep cached keys, refetch with backoff, alert on repeated failure |
| P07 Orders to payment fake | Errors for a period | Error rate and breaker state | Orders hang and threads pile up | Timeout, bounded retries with backoff and jitter, breaker; the saga compensates or retries later |
| P07 Orders to broker | Broker down | Outbox backlog and age of the oldest row | Events are not delivered | Outbox keeps the events; orders are accepted and progress after recovery |
| P07 Fulfilment to courier fake | Very slow answers | Courier call duration | Fulfilment threads blocked, backlog grows | Timeout, own pool, shipment created later; Orders unaffected |
| P07 consumers | Slower than producers | Queue depth and lag | Memory and backlog grow | Prefetch and in-flight limits, more workers, visible lag |
