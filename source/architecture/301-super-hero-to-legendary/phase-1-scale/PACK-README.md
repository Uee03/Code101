# Architecture 301: phase 1 - scale

Scale from one server to many, choose consistency per operation, and design events, the outbox and sagas.

## Prerequisites and status
Architecture 201 finished. All material is **written (not run)**. Lesson front matter remains `verified: not yet run`; no diagram was rendered and nothing was executed. No compiler, server, broker, database or Docker is required. The lessons contain no performance numbers except figures quoted from the platform and P07 design documents.

## Open the pack
1. Windows: right-click the ZIP and choose **Extract All**. macOS: double-click the ZIP. Linux: use the file manager's **Extract** action.
2. Each numbered lesson folder has `code/` (finished files), `exercise/starter/` and `exercise/solution/`. `verify.json` holds empty steps, so nothing runs.
3. Make your own `code101/architecture/301-lessonNN` folder; for practice, copy the **starter folder itself** and rename the copy `301-lessonNN-try`.
4. Lesson 03 refers to `capstones/_practice/P07-event-driven-order-processing/TDD.md`; keep the repository open beside it.
5. `.mmd` files are raw Mermaid; `diagram-sources.md` repeats them inside fences for Markdown previews.

## Lessons
- **01. Scaling from one server to millions** - `01-scaling-to-millions/`. [Lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/301-super-hero-to-legendary/phase-1-scale/01-scaling-to-millions.md).
- **02. Consistency, availability and the CAP and PACELC trade-offs** - `02-consistency-cap-pacelc/`. [Lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/301-super-hero-to-legendary/phase-1-scale/02-consistency-cap-pacelc.md).
- **03. Event-driven architecture, outbox and saga at design level** - `03-events-outbox-saga/`. [Lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/301-super-hero-to-legendary/phase-1-scale/03-events-outbox-saga.md).

## Honesty notes
Scaled designs, replicas, caches, gateways and brokers are proposals, not parts of the platform. Ratings and thresholds are chosen from measurements, never invented.

## Verification scope
Static check only: lesson text against source files and `verify.json` parsing. No rendering, no execution.
