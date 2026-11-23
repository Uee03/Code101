# Diagram source listings

These listings reproduce the editable diagram sources in this folder.

## data.mmd

```mermaid
erDiagram
  MEMBER ||--o{ LOAN : borrows
  BOOK ||--o{ LOAN : appears_in
  MEMBER {
    int id PK
    string name
  }
  BOOK {
    int id PK
    string title
  }
  LOAN {
    int id PK
    int member_id FK
    int book_id FK
  }
```

## storage.mmd

```mermaid
flowchart LR
  app["Library service"]
  db["Database: loan records"]
  cache["Cache: temporary catalogue copies"]
  files["Files: cover images"]
  app -->|"Read and save truth"| db
  app -->|"Reuse recent results"| cache
  app -->|"Read cover image"| files
```
