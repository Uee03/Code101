# Diagram source listings

These listings reproduce the editable diagram sources in this folder.

## layers.mmd

```mermaid
flowchart TD
  presentation["Presentation layer: accept and display"]
  application["Application layer: apply borrowing rules"]
  data["Data layer: read and save records"]
  presentation -->|"Ask to borrow"| application
  application -->|"Load and save loan"| data
```
