# Diagram sources, lesson 09

Each fenced block is the content of the .mmd file named above it.

**File: `review-flow.mmd`**

```mermaid
flowchart TD
    A["1 Read the documents and write down the scope and the boundary"]
    B["2 Restate the design in your own words"]
    C["3 Check each important quality scenario"]
    D["4 Walk the failure paths and the data paths"]
    E["5 Apply the lenses: scale, consistency, events, failure, observability, security, evolution, cost"]
    F["6 Record each finding with its evidence and a severity"]
    G{"7 Is the evidence missing?"}
    H["Turn the finding into a question for the authors"]
    I["8 Write what works well, the trade-off points and a verdict"]
    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F --> G
    G -->|"yes"| H
    G -->|"no"| I
    H --> I
```
