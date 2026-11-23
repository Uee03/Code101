# Golden signals

The four golden signals are latency, traffic, errors and saturation. Measure each for every service that users depend on.

| Signal | Question | Platform API example | P07 example | Caution |
|---|---|---|---|---|
| Latency | How long do requests take? | Time to answer each endpoint, split by successful and failed requests | Time from POST order to a final state | Use percentiles, not averages; keep failed requests apart, because a fast error looks like speed |
| Traffic | How much demand is there? | Requests per second by endpoint and status class | Orders placed per second, events consumed per second | Count by endpoint, not by user id |
| Errors | How many requests fail? | Share of 5xx responses; 4xx counted separately | Failed saga steps, dead-letter count | A wrong answer with status 200 is an error too |
| Saturation | How full is the most limited resource? | Database connections in use, CPU, memory | Queue depth, consumer lag, outbox backlog | The limit that fills first is the one to watch |

Labels: never put an unbounded value such as an order id, a user id or a full URL with ids in a metric label. Put such values in traces and logs.
