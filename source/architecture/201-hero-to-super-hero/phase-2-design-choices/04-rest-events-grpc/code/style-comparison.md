# Interaction styles compared

| Question | REST over HTTP and JSON | Events through a broker | gRPC |
|---|---|---|---|
| Who waits | The caller waits for the answer | Nobody waits for the consumer; the producer waits only for the broker | The caller waits, usually for a short call |
| Coupling in time | Both sides must be up together | Producer and consumer can be down at different times | Both sides must be up together |
| Contract | OpenAPI file | Event schema, for example JSON Schema or AsyncAPI | Protocol Buffers file |
| Browser as caller | Native | Not directly; the browser talks to an API that publishes | Needs a gRPC-Web translation layer |
| Caching | Standard HTTP caching and ETags | Not applicable; consumers keep their own state | No standard shared caching |
| Failure behaviour | Timeout, retry, error status | Redelivery, duplicates, dead-letter queue | Deadline, retry, status code |
| Debugging | Easy with curl and browser tools | Needs correlation ids and tracing | Needs gRPC-aware tools |
| Fit in Tasks and Teams | Client to API: yes, today | Task changes reaching other parties: proposal | Not needed today |
