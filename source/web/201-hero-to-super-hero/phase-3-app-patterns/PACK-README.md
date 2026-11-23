# Web Foundations 201, Phase 3: App patterns

Source pack for lessons 07 to 09. **Status: written, not yet run.** The code was prepared by reading the code and the official documentation; no build or browser check has been executed yet (see `tutorials/web/_STATE-201.md`). If something behaves differently from the lesson, trust what you see and report it.

| Folder | Lesson | You build |
|---|---|---|
| `07-fetching-data` | Fetching data | A task list loaded with `fetch`, a timeout, cancel and retry, and six simulated scenarios that show every load state |
| `08-state-and-events-without-a-framework` | State and events without a framework | A task list with a reducer, a generic store, event delegation and typed custom events |
| `09-forms-and-accessibility` | Forms and accessibility | An accessible "New task" form with labels, hints, per-field errors, an error summary and keyboard checks |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/` | Finished Vite and TypeScript project. No `package-lock.json`: `npm install` creates it. |
| `exercise/starter/` | **Overlay files** for the Try it exercise (a few files in `src/`). |
| `exercise/solution/` | The same files, completed (lesson 08 also includes the changed `src/main.ts`). Try the exercise first. |

The identical boilerplate (`tsconfig.json`, `vite.config.ts`, `.gitignore`, `src/dom.ts`) is repeated in every `code/` folder so each folder runs on its own; the lessons tell you which files are identical to lesson 06.

**How the exercise overlay works.** Copy `code/` (without `node_modules` and `dist`) to a new folder such as `lesson07-try`, run `npm install` there, then copy the files from `exercise/starter/` over the copy, keeping the same relative paths. Rung 2 and rung 3 of each exercise are described in the lesson; only rung 1 is a ready-made overlay (lesson 07 rung 2 is a small edit you make yourself).

## Where to get the optional files
Every file and starter is shown in the lesson, so the pack is optional. Visit https://github.com/Uee03/Code101 and choose **Code > Download ZIP**, then open `source/web/201-hero-to-super-hero/phase-3-app-patterns/`. Or run `git clone https://github.com/Uee03/Code101.git`. Prebuilt archives, if supplied, are `web-201-phase-3-app-patterns.zip` and `web-201-all.zip`.

## Needs
- Node 22.12 or newer (course target 26.13.1), npm 11.20.0, a current browser. TypeScript 7.0.2, Vite 8.3.8 and `@types/node` 26.6.6, pinned exactly.
- Windows PowerShell: if `npm.ps1` is blocked, use `npm.cmd`.
- A screen reader (NVDA on Windows, VoiceOver on macOS) is useful for lesson 09 but optional; the lesson has a keyboard-only checklist.

## How to run
In the lesson folder (`code/` or your copy):
```powershell
npm install --no-audit --no-fund
npm run typecheck
npm run dev
```
Then open the `Local:` address Vite prints (configured as `http://localhost:5173/`). `npm run build` type-checks and builds to `dist/`.

## Verification boundary
`verify.json` files describe how each lesson would be checked (install, type check, build); they have not been run. Browser behaviour in the lessons (loading states, announcements, focus, validation messages) is described from reading the code; the manual browser checklist is in the track state file.

## Time planning
Lessons 07 and 08 take about 60 minutes each, lesson 09 about 65 minutes. Each marks a break point.

Next: Phase 4, quality and ship (lessons 10 to 12).
