# Diagram sources, lesson 01

Each fenced block is the content of the .mmd file named above it.

**File: `scaling-stages.mmd`**

```mermaid
flowchart TD
    S1["Stage 1: one server runs the app and the database"]
    S2["Stage 2: the database moves to its own server"]
    S3["Stage 3: several stateless app servers behind a load balancer"]
    S4["Stage 4: caches and read replicas take the read load"]
    S5["Stage 5: queues take slow work and a CDN takes static files"]
    S6["Stage 6: data is partitioned across shards"]
    S1 -->|"app and database compete for CPU or memory"| S2
    S2 -->|"one app server is the limit or a single point of failure"| S3
    S3 -->|"database reads dominate"| S4
    S4 -->|"slow or bursty work hurts request time"| S5
    S5 -->|"writes or data size exceed one primary"| S6
```

**File: `scaled-platform.mmd`**

```mermaid
flowchart LR
    users(["Users"])
    cdn["CDN for static app files, proposal"]
    lb["Load balancer, proposal"]
    subgraph apis["Stateless backend API instances, proposal"]
        a1["API instance 1"]
        a2["API instance 2"]
        an["API instance N"]
    end
    cache["Shared cache, optional proposal"]
    pri[("PostgreSQL primary: all writes")]
    rep[("Read replica: tolerant reads")]
    kc["Keycloak, external"]
    users -->|"static files"| cdn
    users -->|"API calls with bearer token"| lb
    lb --> a1
    lb --> a2
    lb --> an
    a1 & a2 & an -->|"writes and reads that follow a write"| pri
    a1 & a2 & an -->|"list and report reads"| rep
    a1 & a2 & an -->|"cached copies"| cache
    pri -->|"asynchronous replication"| rep
    a1 -.->|"signing keys, cached per instance"| kc
```

**File: `sharding-by-team.mmd`**

```mermaid
flowchart LR
    api["Backend API with a shard map"]
    s1[("Shard 1: some teams")]
    s2[("Shard 2: other teams")]
    s3[("Shard 3: other teams")]
    adm["Admin audit query across all teams"]
    api -->|"team id picks the shard"| s1
    api -->|"team id picks the shard"| s2
    api -->|"team id picks the shard"| s3
    adm -.->|"must ask every shard and merge the answers"| api
```
