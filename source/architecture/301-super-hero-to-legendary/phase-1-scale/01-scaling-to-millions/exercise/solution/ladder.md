# Bottleneck ladder

| Symptom | Likely stage | First measurement | Main cost of the stage |
|---|---|---|---|
| App server CPU is saturated while database CPU is low | Stage 3, more stateless instances behind a load balancer | CPU and request queue per instance | State must live outside the instances, and a load balancer with health checks is needed |
| The database spends most of its time on the same few list queries | Stage 4, cache or read replica | The slow query list and the repeat rate of those queries | Stale reads and invalidation rules |
| A monthly export makes normal requests slow | Stage 5, move the export to a queue and a worker | Request time by endpoint during the export | A backlog to watch and duplicate handling |
| One table has outgrown the largest affordable machine | Stage 6, partitioning or shards, after tuning and archiving | Storage growth and the time of maintenance jobs | Cross-shard queries and resharding work |
