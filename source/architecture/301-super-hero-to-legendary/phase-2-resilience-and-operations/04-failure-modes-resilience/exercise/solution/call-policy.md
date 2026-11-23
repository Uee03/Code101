# Call policy

| Call | Timeout basis | Retries (allowed? how?) | Circuit breaker | Fallback |
|---|---|---|---|---|
| Platform API reads one task from PostgreSQL | Measured p99 of a normal read with margin, shorter than the client's timeout | At most one retry for a read, only on a connection error | Not needed for a single database; a bounded pool protects it | Return 503 with Retry-After |
| P07 Orders asks the payment fake to charge an order | Measured latency of the provider's slowest normal answers | Yes, a few tries with backoff and jitter, always with the order id as the idempotency key | Yes, to stop retry storms when the provider is failing | Leave the order in a waiting state; the saga retries later or compensates |
| P07 Fulfilment asks the courier fake to create a shipment | Longer than the payment call but bounded, from measured courier latency | Yes, with the order id as the key, a limited number of tries | Yes | Keep the shipment pending and tell Orders only when a final result exists; Orders is unaffected meanwhile |
