# Diagram sources, lesson 07

Each fenced block is the content of the .mmd file named above it.

**File: `modular-monolith.mmd`**

```mermaid
flowchart TD
    subgraph app["One deployable: Tasks and Teams backend"]
        http["HTTP layer"]
        subgraph mods["Modules, each with a public interface and its own tables"]
            teams["Teams and membership"]
            work["Projects and tasks"]
            talk["Comments"]
            audit["Audit trail"]
        end
    end
    db[("One PostgreSQL database, a schema per module")]
    http --> teams
    http --> work
    http --> talk
    work -->|"asks: is the caller a member?"| teams
    talk -->|"asks: does the task exist and may the caller see it?"| work
    teams -->|"publishes change facts"| audit
    work -->|"publishes change facts"| audit
    talk -->|"publishes change facts"| audit
    mods --> db
```

**File: `strangler-routing.mmd`**

```mermaid
flowchart LR
    cl["Web and mobile clients"]
    fac["Facade that routes by path, proposal"]
    mono["Existing backend, still serves most paths"]
    new["New Comments service, serves the comment paths"]
    dbm[("Existing database")]
    dbn[("Comments database owned by the new service")]
    cl --> fac
    fac -->|"all other paths"| mono
    fac -->|"comment paths"| new
    mono --> dbm
    new --> dbn
    new -->|"asks the existing backend: may this caller see the task?"| mono
```

**File: `strangler-steps.mmd`**

```mermaid
flowchart TD
    S1["1 Find a seam: a part with a clear interface and its own data"]
    S2["2 Put a facade in front that can route by path"]
    S3["3 Build the new part behind the facade and send it copies of traffic"]
    S4["4 Compare the old and new answers and fix the differences"]
    S5["5 Route a small share of real traffic to the new part"]
    S6{"6 Healthy for the agreed observation period?"}
    S7["7 Route all traffic to the new part and keep the old path ready to switch back"]
    S8["8 Remove the old code and data after the agreed waiting period"]
    S9["Switch the traffic back and fix the new part"]
    S1 --> S2
    S2 --> S3
    S3 --> S4
    S4 --> S5
    S5 --> S6
    S6 -->|"yes"| S7
    S6 -->|"no"| S9
    S9 --> S3
    S7 --> S8
```
