# Architecture 101: phase 3 - documenting decisions

Record choices, compare quality needs and hand over a consistent documentation bundle.

## Prerequisites and status
Architecture 101 phases 1 and 2; retain your editor and chosen preview route.
All material is **written (not run)**. Lesson front matter remains `verified: not yet run`; static documentation checking does not render diagrams or execute an app. No language runtime, server, database or Docker is required. An optional local VS Code preview is introduced in lesson 05, with current built-in Mermaid support; the draw.io extension is optional in lesson 07.

## Open the pack
1. Windows: right-click the ZIP > **Extract All**. macOS: double-click the ZIP. Linux: use the file manager's **Extract** action. Do not work inside the compressed archive.
2. Open this extracted phase folder and locate the numbered lesson folder. `code/` is the finished diagram/document bundle; `exercise/starter/` is guided practice; `exercise/solution/` is one answer. Empty `verify.json` steps deliberately execute nothing.
3. Make a separate `code101/architecture/lessonNN` folder in your home directory as shown in each lesson. Type the full files there, or copy finished sources only to compare. For practice, copy the **starter folder itself**, then rename the copy `lessonNN-try`; do not nest starter inside it.
4. `.mmd` is raw Mermaid source. The `diagram-sources.md` companion repeats it inside Mermaid fences for Markdown preview. Keep both in sync when editing. For browser preview paste only one raw `.mmd` file at a time into https://mermaid.live/; do not include fences or upload confidential diagrams.
5. `.drawio` opens as an editable diagram using https://app.diagrams.net/ and a Device open, or VS Code's optional draw.io integration. Markdown ADRs and worksheets need only a text editor. These learner preview instructions have not been performed by the author.

## Lessons
- **08. Architecture decision records** - `08-architecture-decision-records/code/`. [Full lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/101-zero-to-hero/phase-3-documenting-decisions/08-architecture-decision-records.md).
- **09. Quality attributes and trade-offs** - `09-quality-attributes-and-trade-offs/code/`. [Full lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/101-zero-to-hero/phase-3-documenting-decisions/09-quality-attributes-and-trade-offs.md).
- **10. Project: document a system end to end** - `10-document-a-system/code/`. [Full lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/101-zero-to-hero/phase-3-documenting-decisions/10-document-a-system.md).

## Review and accessibility
Every lesson includes outcomes, retrieval questions, complete sources, TODO starters, change practice, a full solution and answerable checks. The final lesson in this phase adds mixed review. Labels, not colour alone, carry meaning. No icons, external art, credentials or real personal records are included.

## Verification scope
The repository's static checker compares Markdown source lines and parses verification specifications; it does not parse Mermaid or draw.io XML. The Markdown diagram companions make the diagram text visible to that existing checker. A clean static result is not proof of rendering, a running platform or security. Application execution status remains not run.

## Recorded static result

```text
0 passed, 10 static-checked (not run), 0 failed, 0 unverified (missing tools)
```

This result is documentation verification only; the lesson draft notices remain.
