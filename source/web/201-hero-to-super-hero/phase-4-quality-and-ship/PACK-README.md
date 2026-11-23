# Web Foundations 201, Phase 4: Quality and ship

Source pack for lessons 10 to 12. **Status: written, not yet run.** The code was prepared by reading the code and the official documentation; no build, test run, server or Docker command has been executed yet (see `tutorials/web/_STATE-201.md`). If something behaves differently from the lesson, trust what you see and report it.

| Folder | Lesson | You build |
|---|---|---|
| `10-web-security-basics` | Web security basics | A comment wall that renders safely and unsafely side by side, a CSP on the built site and a tiny CORS demo server |
| `11-performance-and-core-web-vitals` | Performance and Core Web Vitals | A lab page that measures LCP, layout shift and slow interactions, with lazy images, code splitting and a Lighthouse audit |
| `12-testing-and-task-board-project` | Testing with Vitest and the task board | A typed, accessible, persistent task board with 21 Vitest tests, a production build and a Docker image served by nginx |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/` | Finished project. No `package-lock.json`: `npm install` creates it (lesson 12's Dockerfile needs it, so run `npm install` before `docker build`). |
| `exercise/starter/` | **Overlay files** for the Try it exercise (one or two files in `src/`). |
| `exercise/solution/` | The completed files. Try the exercise first. |

**How the exercise overlay works.** Copy `code/` (without `node_modules` and `dist`) to a new folder such as `lesson10-try`, run `npm install` there, then copy the files from `exercise/starter/` over the copy, keeping the same relative paths. Lesson 12's solution overlay also replaces `src/storage.ts`.

## Where to get the optional files
Every file and starter is shown in the lesson, so the pack is optional. Visit https://github.com/Uee03/Code101 and choose **Code > Download ZIP**, then open `source/web/201-hero-to-super-hero/phase-4-quality-and-ship/`. Or run `git clone https://github.com/Uee03/Code101.git`. Prebuilt archives, if supplied, are `web-201-phase-4-quality-and-ship.zip` and `web-201-all.zip`.

## Needs
- Node 22.12 or newer (course target 26.13.1), npm 11.20.0, a current browser (Chrome or Edge for the Lighthouse panel in lesson 11).
- Pinned versions: TypeScript 7.0.2, Vite 8.3.8, `@types/node` 26.6.6; lesson 12 also Vitest 5.1.1 and jsdom 31.0.1.
- **Docker** (Docker Desktop on Windows and macOS, Docker Engine on Linux) for the last three steps of lesson 12 only. Images used: `node:26.13.1-alpine` and `nginxinc/nginx-unprivileged:1.30-alpine`. Everything before those steps works without Docker.
- Windows PowerShell: if `npm.ps1` is blocked use `npm.cmd`; use `curl.exe` instead of `curl`.

## How to run
**Lessons 10 and 11** (Vite projects), in the lesson folder:
```powershell
npm install --no-audit --no-fund
npm run typecheck
npm run dev
```
Lesson 10 also uses `npm run build`, `npm run preview` (the built site with its CSP) and, in a second terminal, `npm run cors-server`. Lesson 11 uses `npm run build` and `npm run preview` for the Lighthouse audit.

**Lesson 12** (project, tests and container), in the project folder:
```powershell
npm install --no-audit --no-fund
npm run typecheck
npm test
npm run build
docker build -t task-board:1.0 .
docker run --rm -d --name task-board -p 8080:8080 task-board:1.0
```
Then open `http://localhost:8080/`. Stop with `docker stop task-board`.

## Verification boundary
`verify.json` files describe how each lesson would be checked, including (lesson 12) the tests and a container probe on port 18512; none has been run. Test counts (21 tests in 4 files; 25 in 5 with the exercise solution) were counted by reading the test files. Browser, Lighthouse and Docker output in the lessons is described as typical output or derived from the configuration.

## Time planning
Lesson 10 takes about 70 minutes, lesson 11 about 65 minutes, and project lesson 12 about 150 minutes in two sittings.

Next: the framework capstones `capstones/web-angular` and `capstones/web-react`.
