# Architecture 201: authoring state

Updated: 2026-11-23.
Level: 201-hero-to-super-hero. Scope: ten lessons, three phases.
Execution status: written (not run).
Static documentation status: verified (static only; not rendered or executed).

| Lesson | Status | Static documentation |
|---|---|---|
| 01 Sequence diagrams for real flows | written (not run) | verified (static only) |
| 02 ER and data-flow diagrams | written (not run) | verified (static only) |
| 03 Deployment and network diagrams in draw.io | written (not run) | verified (static only) |
| 04 REST, events or gRPC: when each | written (not run) | verified (static only) |
| 05 Caching and CDNs | written (not run) | verified (static only) |
| 06 Queues, streams and async work | written (not run) | verified (static only) |
| 07 Authentication and authorisation architecture | written (not run) | verified (static only) |
| 08 arc42 and architecture documentation as code | written (not run) | verified (static only) |
| 09 Quality scenarios and risk analysis (ATAM-lite) | written (not run) | verified (static only) |
| 10 Project: an architecture package for a system | written (not run) | verified (static only) |

## Boundaries and honesty
No diagram was rendered. No Mermaid renderer, draw.io, XML validator, smoke test, server or Docker command was run. All Mermaid sources use a conservative subset (flowchart, sequenceDiagram, erDiagram, stateDiagram-v2, quoted labels, no tabs) chosen from the Mermaid documentation and still need a first real render. The `.drawio` file in lesson 03 follows the structure of the 101 `.drawio` file (containers use `container=1` and children with `parent` set to the container); it needs a first open in diagrams.net. Expected pictures, counts of shapes and arrows were derived by reading the sources.

Facts about the platform and P07 were taken from `capstones/platform/README.md`, `capstones/platform/TDD.md` and `capstones/_practice/P07-event-driven-order-processing/TDD.md` (sections 1 to 6). Proposals are labelled as proposals. No performance, availability or price number is invented.

## Decisions to retain
- Diagrams are shown in fenced blocks with a `**File: ...**` line; `diagram-sources.md` is the companion so the static check covers diagram text. `.mmd` files are not displayed separately.
- Exercise starters and solutions are shown in the lessons (starter in Try it, solution in a collapsed block); lesson 03 shows the solution as the two changes to the starter because the files are otherwise identical.
- ADRs recorded after the fact say so in their status; ADR numbers 0001 to 0003 in 201 form the platform package.
- Likelihood and impact in the risk register are judgements for discussion.

## Delivery
Command: `python scripts\verify_labs.py --static architecture/201`.
Observed output on 2026-11-23:

```text
0 passed, 10 static-checked (not run), 0 failed, 0 unverified (missing tools)
```

Pack build: `python scripts\build_packs.py architecture-201` (packaging only).

```text
built architecture-201-phase-1-diagram-depth.zip (18 files)
built architecture-201-phase-2-design-choices.zip (34 files)
built architecture-201-phase-3-documenting-and-reviewing.zip (35 files)
built architecture-201-all.zip (3 phases)
```

Remaining execution and render review: not performed by instruction.
No edits were made to CONTEXT.md, shared tooling, curriculum or other tracks.
