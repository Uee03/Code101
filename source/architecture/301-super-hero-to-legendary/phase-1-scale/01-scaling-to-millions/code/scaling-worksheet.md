# Scaling worksheet

Fill the measurement column before you change anything. A stage is added only when a measured bottleneck points to it.

| Stage | Question to answer with a measurement | Signal to read | What the stage adds | How hard it is to undo |
|---|---|---|---|---|
| 2 Separate database | Do the app and the database compete for the same machine? | CPU, memory and disk use of each process | A network hop and a second machine to run | Easy |
| 3 Stateless instances and load balancer | Is one app instance saturated or a single point of failure? | CPU and request queue per instance, error rate during a restart | A load balancer, health checks, shared state moved out of the app | Easy to medium |
| 4 Cache and read replica | Which reads repeat, and do they dominate the database load? | Slow query list, cache hit ratio, replica lag | Stale reads, invalidation, read-after-write rules | Medium |
| 5 Queue and CDN | Which work is slow or bursty, and which files are the same for everyone? | Request time by endpoint, backlog, share of bytes that are static | A broker, duplicates, a backlog to watch | Medium |
| 6 Shards | Does one primary reach its write or size limit even after tuning? | Write rate, storage growth, vacuum and index build time | Cross-shard queries, a shard map, resharding work | Hard |

Measure these at every stage: request rate, p95 latency per endpoint, error rate, CPU, memory, database connections in use, slow queries, cache hit ratio, replica lag.
