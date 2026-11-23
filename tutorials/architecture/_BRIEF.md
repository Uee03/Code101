# System Architecture (diagrams): track brief

## Audience and promise
Architecture 101 Zero to Hero is for people from any field. No application coding, programming-language installation, database, terminal, Docker or server is required. Learners start with a city map, a restaurant or a post office analogy, then write small editable diagram descriptions and short decisions. By the end they can hand a reader a coherent documentation bundle, not claim a production implementation.

## Scope and pacing
- Track folder: `architecture`; level folder: `101-zero-to-hero`.
- Ten lessons in three phases: 4 thinking lessons, 3 toolkit lessons, 3 decision/project lessons.
- Individual lesson estimates include first-time reading, file creation and guided practice. Toolkit/ADR lessons allow two sittings; the final project allows three. Total planned time: about 9 hours 30 minutes, with extra time for a larger learner project.
- This track intentionally introduces draw.io, ER/sequence views, ADRs and basic quality comparisons at 101, as explicitly requested, although the broad curriculum row also develops them at 201. No curriculum files outside this track are changed.
- One main teaching question per view. Complete sources first, then full lessons copied from the sources. Worked example, TODO-guided exercise, change practice and optional stretch appear in every lesson.
- Each phase ends with mixed retrieval review. Each lesson has three outcomes and three matching self-check questions, including prediction or fault-finding.

## Lesson map
| Phase | Lesson | Deliverable | First-timer time |
|---|---|---|---:|
| 1 thinking-in-systems | 01 What architecture is and why diagrams | Reader, question, scope and two-node map | 40 min |
| 1 | 02 Client, server and the request journey | Web-request sequence | 35 min |
| 1 | 03 Layers and responsibilities | Layered call flow | 35 min |
| 1 | 04 Data and storage | Storage-role map and loan ER view | 45 min |
| 2 diagram-toolkit | 05 Mermaid in depth | Flowchart, sequence, class, ER and state sources | 70 min |
| 2 | 06 The C4 model: context and containers | Two consistent platform zoom levels | 50 min |
| 2 | 07 draw.io: editable diagrams | Full uncompressed editable XML | 60 min |
| 3 documenting-decisions | 08 Architecture decision records | Template and Postgres, Keycloak, OpenAPI-first ADRs | 70 min |
| 3 | 09 Quality attributes and trade-offs | Measurable scenarios and weighted comparison | 45 min |
| 3 | 10 Project: document a system end to end | Four views, two ADRs and a review checklist | 120 min |

## Running example and accuracy boundaries
Lessons 01-04 use a small library. BOOK means one physical copy; historical loans do not implement an active-loan rule. Lessons 05-10 use Tasks and Teams, grounded in `capstones/platform/README.md` and `capstones/platform/TDD.md`. Lesson 10 works the platform project-board slice first, then offers a Community Library exercise solution while allowing any small learner-chosen app.

The platform work-planning boundary contains the web client, one backend and work database. Identity is external to that responsibility boundary even when operated in the same local stack. The platform TDD's operational container view has a broader scope; lessons explicitly explain this distinction. Mobile clients, complete schema fields and full access-check algorithms are omitted from the web slice. HTTPS arrows describe intended production transport, not the existing local HTTP setup. State transitions are an illustrative subset, not an asserted complete API rule. The optional cache and production quality targets are proposals, not platform features or measured results.

## Primary sources (Tier 1)
- Mermaid introduction and syntax: https://mermaid.js.org/intro/
- Flowcharts: https://mermaid.js.org/syntax/flowchart.html
- Sequences: https://mermaid.js.org/syntax/sequenceDiagram.html
- Classes: https://mermaid.js.org/syntax/classDiagram.html
- ER: https://mermaid.js.org/syntax/entityRelationshipDiagram.html
- States: https://mermaid.js.org/syntax/stateDiagram.html
- C4 context: https://c4model.com/diagrams/system-context
- C4 containers: https://c4model.com/diagrams/container
- GitHub diagram rendering: https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams
- VS Code Markdown and built-in Mermaid preview: https://code.visualstudio.com/docs/languages/markdown
- Previous Mermaid extension's deprecation notice: https://marketplace.visualstudio.com/items?itemName=bierner.markdown-mermaid
- draw.io integration, primary publisher documentation: https://marketplace.visualstudio.com/items?itemName=hediet.vscode-drawio
- draw.io file format reference: https://github.com/jgraph/drawio-mcp/blob/main/shared/xml-reference.md
- Editor entry points: https://mermaid.live/ and https://app.diagrams.net/

## Supporting sources (Tier 2)
- ByteByteGo, Software Architecture: https://bytebytego.com/guides/software-architecture/
- freeCodeCamp, System Architecture Documentation Best Practices and Tools: https://www.freecodecamp.org/news/system-architecture-documentation-best-practices-and-tools/

All teaching prose is original paraphrase. No article text or external artwork is reproduced. `assets: []` in every lesson; diagram shapes are not imported icons.

## Verification and delivery policy
- All lessons retain `verified: not yet run` and the owner's exact draft notice below H1.
- Execution status stays `written (not run)`; a successful static check is recorded separately as static documentation verification only.
- The only check is `python scripts\verify_labs.py --static architecture/101`. No Mermaid renderer, XML validation script, smoke test, server or platform command is run.
- Every `verify.json` has empty requires/steps/cleanup arrays. There is nothing to execute.
- The current verifier recognises `.md` but not `.mmd` or `.drawio`. Each diagram lesson therefore includes `code/diagram-sources.md`, copied from its diagram sources and shown in full in the lesson. This extends line-coverage checking without modifying shared scripts. It does not parse Mermaid/XML or guarantee later source/mirror synchronisation.
- Sources, starters and solutions are fully listed in lessons. No lesson-check exemptions are used.
- Phase PACK-READMEs accompany the sources. The owner permits `build_packs.py architecture-101` to write the three phase ZIPs and all-level ZIP under `dist/packs/`; that is the only allowed write exception outside the two track trees.
