# Architecture 301: phase 3 - evolution

Decide between a monolith, a modular monolith and services and migrate safely, estimate cost and capacity without inventing numbers, and review the platform and P07 designs in writing.

## Prerequisites and status
Architecture 301 phases 1 and 2. All material is **written (not run)**. Lesson front matter remains `verified: not yet run`; no diagram was rendered and nothing was executed. No compiler, server or Docker is required. The designs reviewed in lesson 09 are documents; none of their implementations was run or tested for this level.

## Open the pack
1. Windows: right-click the ZIP and choose **Extract All**. macOS: double-click the ZIP. Linux: use the file manager's **Extract** action.
2. Each numbered lesson folder has `code/` (finished files), `exercise/starter/` and `exercise/solution/`. `verify.json` holds empty steps, so nothing runs.
3. For practice, copy the **starter folder itself** and rename the copy `301-lessonNN-try`.
4. Lesson 09 cites `capstones/platform/TDD.md` and `capstones/_practice/P07-event-driven-order-processing/TDD.md`; keep the repository open beside it.
5. `.mmd` files are raw Mermaid; `diagram-sources.md` repeats them inside fences for Markdown previews.

## Lessons
- **07. Monolith, modular monolith and microservices** - `07-monolith-to-microservices/`. [Lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/301-super-hero-to-legendary/phase-3-evolution/07-monolith-to-microservices.md).
- **08. Cost, capacity and performance modelling** - `08-cost-capacity-performance/`. [Lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/301-super-hero-to-legendary/phase-3-evolution/08-cost-capacity-performance.md).
- **09. Capstone review** - `09-capstone-review/`. [Lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/301-super-hero-to-legendary/phase-3-evolution/09-capstone-review.md).

## Honesty notes
The worked arithmetic in lesson 08 uses only numbers stated in the platform and P07 documents. The example reviews are course examples written from the documents' text; they are not an audit of any running system.

## Verification scope
Static check only: lesson text against source files and `verify.json` parsing. No rendering, no execution.
