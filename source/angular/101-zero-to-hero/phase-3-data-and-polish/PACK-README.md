# Angular 101, Phase 3: Data and polish

Source pack for lessons 09 to 12. **Status: written, not yet run** (see `tutorials/angular/_STATE.md`). Trust your tool's real output over the lesson text and report differences.

| Folder | Lesson | You build |
|--------|--------|-----------|
| `09-httpclient-and-calling-an-api` | HttpClient and calling an API | The store loads tasks from `public/api/tasks.json` with loading, ready and error states |
| `10-styling-and-accessibility` | Styling and accessibility | CSS tokens, focus ring, skip link, focus after navigation, CC0 icons (`ui/plus`, `ui/x`, `ui/alert-triangle`, `arrows/refresh-cw`) |
| `11-pipes-and-lifecycle-basics` | Pipes and lifecycle basics | Built-in and custom pipes, `ngOnInit` and `ngOnDestroy`, the `async` pipe |
| `12-project-task-list-app` | Project: a task list app | A new project, `task-list`, with everything combined and saved in `localStorage` |

Each lesson folder has `code/`, `exercise/starter/`, `exercise/solution/` (overlay files) and `verify.json` (not run yet). Icons are CC0 files from the course art library, kept under `code/public/icons/`. No `package-lock.json`: `npm install` creates it.

## Needs and how to run
Node 26.13.1 target, Angular 22.3.0, TypeScript 6.0.3. In `code/`: `npm install --no-audit --no-fund`, `npm start`, open http://localhost:4200/. Restart `npm start` after adding files under `public/`.

## Where to get the optional files
https://github.com/Uee03/Code101, **Code > Download ZIP**, then `source/angular/101-zero-to-hero/phase-3-data-and-polish/`; or `git clone https://github.com/Uee03/Code101.git`.

Next: level 201 (`source/angular/201-hero-to-super-hero/`).
