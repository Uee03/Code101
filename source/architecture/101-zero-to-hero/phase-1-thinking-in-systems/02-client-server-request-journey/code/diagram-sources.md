# Diagram source listings

These listings reproduce the editable diagram sources in this folder.

## request.mmd

```mermaid
sequenceDiagram
  actor Visitor
  participant Browser
  participant Server
  Visitor->>Browser: Open catalogue
  Browser->>Server: GET /catalogue
  Server-->>Browser: 200 OK and page
  Browser-->>Visitor: Show catalogue
```
