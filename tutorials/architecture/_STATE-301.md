# Architecture 301: authoring state

Updated: 2026-11-23.
Level: 301-super-hero-to-legendary. Scope: nine lessons, three phases.
Execution status: written (not run).
Static documentation status: verified (static only; not rendered or executed).

| Lesson | Status | Static documentation |
|---|---|---|
| 01 Scaling from one server to millions | written (not run) | verified (static only) |
| 02 Consistency, availability and the CAP and PACELC trade-offs | written (not run) | verified (static only) |
| 03 Event-driven architecture, outbox and saga at design level | written (not run) | verified (static only) |
| 04 Failure modes, timeouts, retries, bulkheads and graceful degradation | written (not run) | verified (static only) |
| 05 Observability and SLOs: golden signals and error budgets | written (not run) | verified (static only) |
| 06 Security architecture: zero trust, STRIDE, secrets and tenant isolation | written (not run) | verified (static only) |
| 07 Monolith, modular monolith and microservices: decision and migration | written (not run) | verified (static only) |
| 08 Cost, capacity and performance modelling | written (not run) | verified (static only) |
| 09 Capstone review: critique the platform and P07 designs | written (not run) | verified (static only) |

## Boundaries and honesty
No diagram was rendered. No Mermaid renderer, XML validator, smoke test, server or Docker command was run. Mermaid sources use a conservative subset (flowchart including the `a & b --> c` form in lesson 01, sequenceDiagram with nested alt, stateDiagram-v2, quoted labels, no tabs) and still need a first real render; if an older renderer rejects the `&` form, lesson 01's common-mistakes row tells the learner to write one edge per instance.

Facts about the platform and P07 come from their README and TDDs (P07 sections 1 to 6; sections beyond the API sketch were not read). Scaled designs, gateways, replicas, shards, secret store and row-level security are proposals and are labelled. The reviews in lesson 09 are course examples written from the documents' text. No performance, availability, capacity or price number is invented; derived arithmetic (lesson 08) uses only numbers stated in the TDDs, and the 99.9 percent and 43.2 minute figures in lesson 05 are labelled illustrative arithmetic.

## Decisions to retain
- Same diagram and companion convention as level 201.
- Lessons add failure modes, when-not-to, measurements and security and operations notes in "How it works".
- ADR numbers inside lessons are local to each lesson's example (they are not one continuous series).
- Review severity definitions live in `review-template.md` (lesson 09).

## Delivery
Command: `python scripts\verify_labs.py --static architecture/301`.
Observed output on 2026-11-23:

```text
0 passed, 9 static-checked (not run), 0 failed, 0 unverified (missing tools)
```

Pack build: `python scripts\build_packs.py architecture-301` (packaging only).

```text
built architecture-301-phase-1-scale.zip (27 files)
built architecture-301-phase-2-resilience-and-operations.zip (27 files)
built architecture-301-phase-3-evolution.zip (27 files)
built architecture-301-all.zip (3 phases)
```

Remaining execution and render review: not performed by instruction.
No edits were made to CONTEXT.md, shared tooling, curriculum or other tracks.
