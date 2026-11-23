# Angular 101, Phase 2: Building

Source pack for lessons 05 to 08. **Status: written, not yet run** (see `tutorials/angular/_STATE.md`). Trust your tool's real output over the lesson text and report differences.

| Folder | Lesson | You build |
|--------|--------|-----------|
| `05-component-inputs-and-outputs` | Component inputs and outputs | A reusable `TaskItem` with `input()` and `output()` |
| `06-forms-template-driven-then-reactive` | Forms | The same "new task" form with `ngModel` and with a reactive `FormGroup` |
| `07-routing` | Routing | Home, tasks, task detail, about and not-found pages |
| `08-services-and-dependency-injection` | Services and dependency injection | A `TaskStore` service shared by all pages |

Each lesson folder has `code/` (the whole project at the end of the lesson), `exercise/starter/` and `exercise/solution/` (overlay files: copy them over your project with the same relative paths) and `verify.json` (not run yet). No `package-lock.json`: `npm install` creates it.

## Needs and how to run
Same as phase 1 (Node 26.13.1 target, Angular 22.3.0, TypeScript 6.0.3). In `code/`: `npm install --no-audit --no-fund`, `npm start`, open http://localhost:4200/.

## Where to get the optional files
https://github.com/Uee03/Code101, **Code > Download ZIP**, then `source/angular/101-zero-to-hero/phase-2-building/`; or `git clone https://github.com/Uee03/Code101.git`.

Next: Phase 3, data and polish (lessons 09 to 12).
