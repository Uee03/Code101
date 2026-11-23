# Documentation layout

```text
docs/
  architecture/
    README.md                     start here: purpose, reading order, owner
    arc42.md                      the twelve sections, short, linking to the files below
    adr/
      0001-keep-rest.md
      0002-local-token-validation.md
    diagrams/
      context.mmd
      containers.mmd
      components-backend.mmd
      signin-pkce.mmd
      deployment.drawio
    quality/
      scenarios.md
      risks.md
```

Rules:
- One folder, in the same repository as the code it describes.
- Diagrams are text files (.mmd) or uncompressed XML (.drawio) so a pull request shows what changed.
- ADRs are numbered and never edited after acceptance; a later ADR supersedes an earlier one.
- Each file names an owner and a date in its first lines.
- An exported picture is a copy for slides, never the source.
