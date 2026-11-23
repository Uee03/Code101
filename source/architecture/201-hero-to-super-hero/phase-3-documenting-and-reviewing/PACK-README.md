# Architecture 201: phase 3 - documenting and reviewing

Keep architecture documentation in the repository (arc42, docs as code), state quality as scenarios and risks, and assemble a complete architecture package.

## Prerequisites and status
Architecture 201 phases 1 and 2. All material is **written (not run)**. Lesson front matter remains `verified: not yet run`; no diagram was rendered and nothing was executed. No compiler, server or Docker is required.

## Open the pack
1. Windows: right-click the ZIP and choose **Extract All**. macOS: double-click the ZIP. Linux: use the file manager's **Extract** action.
2. Each numbered lesson folder has `code/` (finished files), `exercise/starter/` and `exercise/solution/`. `verify.json` holds empty steps, so nothing runs.
3. Lesson 10 assembles files from lessons 01 to 09 into one `package` folder; keep your earlier lesson folders until you finish it.
4. For practice, copy the **starter folder itself** and rename the copy `201-lessonNN-try`.
5. `.mmd` files are raw Mermaid; `diagram-sources.md` repeats them inside fences for Markdown previews.

## Lessons
- **08. arc42 and architecture documentation as code** - `08-arc42-docs-as-code/`. [Lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/201-hero-to-super-hero/phase-3-documenting-and-reviewing/08-arc42-docs-as-code.md).
- **09. Quality scenarios and risk analysis (ATAM-lite)** - `09-quality-scenarios-and-risks/`. [Lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/201-hero-to-super-hero/phase-3-documenting-and-reviewing/09-quality-scenarios-and-risks.md).
- **10. Project: an architecture package for a system** - `10-project-architecture-package/`. [Lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/201-hero-to-super-hero/phase-3-documenting-and-reviewing/10-project-architecture-package.md).

## Honesty notes
Likelihood and impact ratings in the risk register are judgements for discussion, not measurements. The Community Library is an invented system; its facts are marked as invented.

## Verification scope
Static check only: lesson text against source files and `verify.json` parsing. No rendering, no execution.
