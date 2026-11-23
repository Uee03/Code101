# Architecture 301: phase 2 - resilience and operations

Design for failure (timeouts, retries, bulkheads, degradation), see the system (golden signals, SLOs, error budgets) and secure it (zero trust, STRIDE, secrets, tenant isolation).

## Prerequisites and status
Architecture 301 phase 1. All material is **written (not run)**. Lesson front matter remains `verified: not yet run`; no diagram was rendered and nothing was executed. No compiler, server, broker, database or Docker is required. No timeout, retry count, SLO target or capacity figure is given: each comes from your own measurements.

## Open the pack
1. Windows: right-click the ZIP and choose **Extract All**. macOS: double-click the ZIP. Linux: use the file manager's **Extract** action.
2. Each numbered lesson folder has `code/` (finished files), `exercise/starter/` and `exercise/solution/`. `verify.json` holds empty steps, so nothing runs.
3. For practice, copy the **starter folder itself** and rename the copy `301-lessonNN-try`.
4. Lesson 06 refers to the platform TDD section 7; keep the repository open beside it.
5. `.mmd` files are raw Mermaid; `diagram-sources.md` repeats them inside fences for Markdown previews.

## Lessons
- **04. Failure modes, timeouts, retries, bulkheads and graceful degradation** - `04-failure-modes-resilience/`. [Lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/301-super-hero-to-legendary/phase-2-resilience-and-operations/04-failure-modes-resilience.md).
- **05. Observability and SLOs** - `05-observability-slos/`. [Lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/301-super-hero-to-legendary/phase-2-resilience-and-operations/05-observability-slos.md).
- **06. Security architecture** - `06-security-architecture/`. [Lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/301-super-hero-to-legendary/phase-2-resilience-and-operations/06-security-architecture.md).

## Honesty notes
The illustrative error-budget arithmetic in lesson 05 is arithmetic, not a target. The security lessons teach design; they do not certify any system as secure. Use only fake credentials in practice.

## Verification scope
Static check only: lesson text against source files and `verify.json` parsing. No rendering, no execution.
