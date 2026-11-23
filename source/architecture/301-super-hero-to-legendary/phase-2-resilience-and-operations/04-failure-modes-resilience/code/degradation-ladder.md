# Degradation ladder

| Level | Trigger | Behaviour | What users see | Return to normal when |
|---|---|---|---|---|
| 0 Normal | none | Everything works | Nothing unusual | Not applicable |
| 1 Optional parts off | A non-essential dependency fails | Features that depend on it are hidden or marked as delayed | A notice that some data may be late | The dependency answers again and its breaker closes |
| 2 Stale reads | The primary is slow but a replica or cache is healthy | Lists are served from copies, each marked with its age | Data with a visible age | The primary meets its latency target again |
| 3 Read only | The primary cannot accept writes | Reads continue, writes are refused with 503 and Retry-After | A clear message that changes cannot be saved now | Writes succeed again; clients retry with idempotency keys |
| 4 Maintenance message | A core dependency is down | A small static page and a status link | An honest outage message | The core dependency is restored |
