# System Architecture 201: track brief

## Audience and promise
Architecture 201 Hero to Super Hero is for learners who finished 101 (or have the equivalent). They no longer need analogies; they need depth: real flows, design choices with reasons, and documentation that survives. By the end they can produce a reviewable architecture package for a small system. No application code, compiler, server, database or Docker is needed: the source code of this track is diagram sources (`.mmd`, `.drawio`) and Markdown documents (ADRs, tables, checklists).

## Scope and pacing
- Track folder: `architecture`; level folder: `201-hero-to-super-hero`.
- Ten lessons in three phases: 3 diagram-depth, 4 design-choices, 3 documenting-and-reviewing. Planned time: about 11 hours 30 minutes (60, 60, 70 / 60, 60, 65, 70 / 70, 75, 150 minutes).
- Voice: assume 101, explain the why, "Why this, not that" box in each lesson, link to the capstone material where the topic is used. Terms are defined when first used and added to `GLOSSARY.md`.
- Every lesson ends with a three-rung exercise (guided starter, change, stretch), a solution, check-yourself questions and "common mistakes" marked as typical symptoms (no renderer was run).

## Lesson map
| Phase | Lesson | Deliverable | Time |
|---|---|---|---:|
| 1 diagram-depth | 01 Sequence diagrams for real flows | Sign-in with PKCE and idempotent create as sequences | 60 min |
| 1 | 02 ER and data-flow diagrams | Platform ER view and a data-flow view of "complete a task" | 60 min |
| 1 | 03 Deployment and network diagrams in draw.io | Local stack deployment and a connection inventory | 70 min |
| 2 design-choices | 04 REST, events or gRPC | Decision flowchart, event flow, comparison table, ADR | 60 min |
| 2 | 05 Caching and CDNs | Layers, cache-aside, conditional GET, cache policy | 60 min |
| 2 | 06 Queues, streams and async work | Async export flow, job states, design checklist | 65 min |
| 2 | 07 Authentication and authorisation architecture | Token validation, gateway variant, check order, access matrix | 70 min |
| 3 documenting-and-reviewing | 08 arc42 and documentation as code | Layout, arc42 summary, review checklist, workflow | 70 min |
| 3 | 09 Quality scenarios and risk analysis | Six scenarios, utility tree, risk register, ATAM-lite run sheet | 75 min |
| 3 | 10 Project: an architecture package | C4 L1 to L3, ADR 0003, traceability, README; own package | 150 min |

## Running example and accuracy boundaries
The platform (`capstones/platform/TDD.md` and `README.md`) is the main example; the practice capstone P07 appears in lessons 04, 06 and in level 301. Every fact about them is quoted or paraphrased from those documents; everything else is marked **proposal** (gateway, cache, CDN, export feature, broker, read replica). The Community Library is an invented system for exercises and its facts are marked invented. Keycloak is drawn as external in the work-planning views (as in 101) and inside the boundary in the TDD; lesson 10 states the choice. No lesson contains an invented performance or availability number: targets are either quoted from the TDD with their measurement conditions or described as "chosen from measurements".

## Primary sources (Tier 1)
- Mermaid syntax: https://mermaid.js.org/syntax/sequenceDiagram.html, https://mermaid.js.org/syntax/entityRelationshipDiagram.html, https://mermaid.js.org/syntax/flowchart.html
- C4 model: https://c4model.com/diagrams
- arc42: https://arc42.org/overview and https://docs.arc42.org/
- Azure Architecture Center patterns: https://learn.microsoft.com/azure/architecture/patterns/
- AWS Well-Architected: https://aws.amazon.com/architecture/well-architected/
- RFC 7636 PKCE, RFC 9111 HTTP caching, RFC 9700 OAuth security BCP, OpenID Connect Core 1.0, OWASP API Security Top 10 2023

## Supporting sources (Tier 2)
- ByteByteGo, Software Architecture: https://bytebytego.com/guides/software-architecture/
- GitHub Docs, creating diagrams: https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams

All teaching prose is original paraphrase. No article text or external artwork is reproduced. `assets: []` in every lesson.

## Verification and delivery policy
- Every lesson carries `verified: not yet run` and the exact draft notice under the H1. Status is `written (not run)`.
- The only checks are `python scripts\verify_labs.py --static architecture/201` and `python scripts\build_packs.py architecture-201`. No Mermaid renderer, draw.io, XML validator, server or smoke test was run.
- The verifier does not read `.mmd` or `.drawio`. Each Mermaid lesson has `code/diagram-sources.md` (the same text inside fences) and Markdown documents are checked line by line; the lessons show the diagrams in fenced blocks with a `**File: ...**` line above each, so the companion's lines are all in the lesson text. The `.mmd` and `.drawio` bodies are shown in full in the lessons (the `.drawio` file is shown as XML).
- Every `verify.json` has empty requires, steps and cleanup arrays.
