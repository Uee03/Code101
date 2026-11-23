# System Architecture 301: track brief

## Audience and promise
Architecture 301 Super Hero to Legendary is for engineers who finished 201 and make or review real design decisions. Lessons state trade-offs, failure modes, when not to use a technique, what to measure, a production checklist and the security and operations angle. By the end learners can critique a design in writing with evidence. No application code, compiler, server, database or Docker is needed: the source code of this track is diagram sources (`.mmd`) and Markdown documents (ADRs, tables, checklists, reviews).

## Scope and pacing
- Track folder: `architecture`; level folder: `301-super-hero-to-legendary`.
- Nine lessons in three phases: 3 scale, 3 resilience-and-operations, 3 evolution. Planned time: about 12 hours 15 minutes (80, 75, 90 / 85, 85, 90 / 90, 80, 120 minutes).
- Voice: assume 201; each lesson has "Why this, not that", failure modes, "when not to", measurements to take (never invented numbers), and security and operations notes.

## Lesson map
| Phase | Lesson | Deliverable | Time |
|---|---|---|---:|
| 1 scale | 01 Scaling from one server to millions | Ladder, scaled platform (proposal), shard map, worksheet, read-replica ADR | 80 min |
| 1 | 02 Consistency, availability, CAP and PACELC | Partition sequence, PACELC picture, per-operation menu, ADR | 75 min |
| 1 | 03 Event-driven architecture, outbox and saga | Outbox, saga and order state machine, event contract, ADR | 90 min |
| 2 resilience-and-operations | 04 Failure modes, timeouts, retries, bulkheads, degradation | Resilient call, bulkhead, failure-mode table, retry rules, ladder | 85 min |
| 2 | 05 Observability and SLOs | Golden signals, telemetry flow, trace propagation, SLO template, error budget policy | 85 min |
| 2 | 06 Security architecture | Trust boundaries, STRIDE table, tenant isolation, secrets policy | 90 min |
| 3 evolution | 07 Monolith, modular monolith and microservices | Decision framework, modules, strangler steps and checklist, ADR | 90 min |
| 3 | 08 Cost, capacity and performance modelling | Worksheet, worked examples from the TDDs, measurement plan, loop | 80 min |
| 3 | 09 Capstone review | Review template and complete reviews of the platform and P07 | 120 min |

## Running example and accuracy boundaries
The platform and P07 (`capstones/_practice/P07-event-driven-order-processing/TDD.md`) are the running examples. Platform facts come from its README and TDD; P07 facts from sections 1 to 6 of its TDD. Larger designs (load balancer, replica, shards, gateway, secret store, row-level security, modular-monolith modules) are proposals and are labelled so. The reviews in lesson 09 are course examples built from the documents' text, not audits of running systems; they use questions where the documents are silent. Arithmetic in lessons 05 and 08 is derived only from numbers stated in the TDDs or is explicitly illustrative.

## Primary sources (Tier 1)
- Google SRE book and workbook: https://sre.google/sre-book/monitoring-distributed-systems/, https://sre.google/sre-book/service-level-objectives/, https://sre.google/sre-book/addressing-cascading-failures/, https://sre.google/sre-book/handling-overload/, https://sre.google/workbook/implementing-slos/, https://sre.google/workbook/alerting-on-slos/
- Azure Architecture Center: saga, compensating transaction, publisher-subscriber, retry, circuit breaker, bulkhead, strangler fig, cache-aside patterns, microservices guide; Azure Well-Architected cost optimization
- AWS Well-Architected: https://aws.amazon.com/architecture/well-architected/
- NIST SP 800-207 zero trust; Microsoft Learn STRIDE threat reference; OWASP API Security Top 10 2023
- arc42 sections 9, 10 and 11

## Supporting sources (Tier 2)
- ByteByteGo, Software Architecture: https://bytebytego.com/guides/software-architecture/

All teaching prose is original paraphrase. No article text or artwork is reproduced. `assets: []` in every lesson.

## Verification and delivery policy
- Every lesson carries `verified: not yet run` and the exact draft notice under the H1. Status is `written (not run)`.
- The only checks are `python scripts\verify_labs.py --static architecture/301` and `python scripts\build_packs.py architecture-301`. No Mermaid renderer, draw.io, XML validator, server or smoke test was run.
- The verifier does not read `.mmd`. Each lesson has `code/diagram-sources.md` (the same diagrams inside fences) and Markdown documents; the lessons show every diagram in a fenced block with a `**File: ...**` line above it, so all companion lines are in the lesson text.
- Every `verify.json` has empty requires, steps and cleanup arrays.
