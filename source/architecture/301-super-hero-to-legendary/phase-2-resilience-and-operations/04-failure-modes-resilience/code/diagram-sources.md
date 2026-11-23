# Diagram sources, lesson 04

Each fenced block is the content of the .mmd file named above it.

**File: `resilient-call.mmd`**

```mermaid
flowchart TD
    A["Incoming request with a deadline"]
    B{"Bulkhead: is a slot free for this dependency?"}
    C{"Circuit breaker: is it open?"}
    D["Call the dependency with a timeout"]
    E{"Did the call succeed?"}
    F{"Safe to retry, tries left and time left before the deadline?"}
    G["Wait with exponential backoff and jitter"]
    H["Fallback: a degraded answer or a clear error"]
    OK["Return the answer"]
    A --> B
    B -->|"no"| H
    B -->|"yes"| C
    C -->|"yes"| H
    C -->|"no"| D
    D --> E
    E -->|"yes"| OK
    E -->|"no"| F
    F -->|"yes"| G
    G --> D
    F -->|"no"| H
```

**File: `bulkhead.mmd`**

```mermaid
flowchart LR
    inc["Incoming requests"]
    subgraph svc["One service"]
        p1["Pool A: calls to the payment provider"]
        p2["Pool B: calls to the order database"]
        p3["Pool C: health and metrics endpoints"]
    end
    pay["Payment provider, slow or failing"]
    db[("Order database, healthy")]
    inc --> p1
    inc --> p2
    inc --> p3
    p1 -->|"pool fills up, only these calls wait or fail"| pay
    p2 --> db
```
