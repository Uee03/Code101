# Retry and timeout rules

1. Every call to another process has a timeout. A call without a timeout can wait forever.
2. Choose each timeout from measured latency, not from a feeling. An inner timeout is shorter than the outer one that contains it.
3. Pass a deadline down the chain, so no layer works on a request whose caller has already given up.
4. Retry only operations that are safe to repeat: reads, or writes protected by an idempotency key or a natural key.
5. Wait between tries with exponential backoff and add jitter, a small random amount, so many clients do not retry at the same moment.
6. Limit the number of tries. When the limit is reached, take the fallback; do not loop.
7. Retry in one layer only. If three layers each make three tries, one user action can become twenty-seven calls to the failing dependency.
8. Obey Retry-After when a server sends it with 429 or 503.
9. A circuit breaker has three states: closed (calls go through), open (calls fail fast), half-open (a few trial calls test recovery).
10. Never retry an error that repetition cannot fix, such as a validation failure.
