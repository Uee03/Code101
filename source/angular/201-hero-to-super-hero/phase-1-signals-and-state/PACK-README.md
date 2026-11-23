# Angular 201, Phase 1: Signals and state

Source pack for lessons 01 to 03. **Status: written, not yet run** (see `tutorials/angular/_STATE.md`). Trust your tool's real output over the lesson text and report differences.

| Folder | Lesson | You build |
|--------|--------|-----------|
| `01-signals-in-depth` | Signals in depth: computed, effect and linkedSignal | A "Signals lab": lazy `computed`, a `linkedSignal` chooser, an `effect` theme switch |
| `02-rxjs-essentials-and-signal-interop` | RxJS essentials and signal interop | A debounced, cancel-safe search with `toObservable` and `toSignal` |
| `03-state-patterns-service-with-signals` | State patterns: a store service with signals | A `TaskStore` with a cursor list, optimistic update, 412 handling and idempotent create against an in-memory fake API |

Each lesson folder has `code/` (whole project), `exercise/starter/` and `exercise/solution/` (overlay files, same relative paths) and `verify.json` (not run yet). No `package-lock.json`: `npm install` creates it.

## Needs and how to run
Level 101 finished. Node 26.13.1 target, Angular 22.3.0, TypeScript 6.0.3, RxJS 7.8.2. In `code/`: `npm install --no-audit --no-fund`, `npm start`, open http://localhost:4200/. No server is needed in this phase.

## Where to get the optional files
https://github.com/Uee03/Code101, **Code > Download ZIP**, then `source/angular/201-hero-to-super-hero/phase-1-signals-and-state/`; or `git clone https://github.com/Uee03/Code101.git`.
