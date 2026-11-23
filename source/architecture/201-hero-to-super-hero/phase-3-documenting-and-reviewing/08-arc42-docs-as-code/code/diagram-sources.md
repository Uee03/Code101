# Diagram sources, lesson 08

Each fenced block is the content of the .mmd file named above it.

**File: `docs-workflow.mmd`**

```mermaid
flowchart LR
    A["Design change decided"]
    B["Edit diagram text and documents in a branch"]
    C["Open a pull request with code and docs together"]
    D{"Reviewer: does the checklist pass?"}
    E["Merge to the main branch"]
    F["Readers open the files in the repository or a rendered preview"]
    A --> B
    B --> C
    C --> D
    D -->|"no, comments"| B
    D -->|"yes"| E
    E --> F
```
