# React 101, Phase 3: Data and polish

Source pack for lessons 09 to 12. **Status: written, not yet run.** The code was prepared by reading the code and the official documentation; no install, build or browser check has been executed yet (see `tutorials/react/_STATE.md`). If something behaves differently from the lesson, trust what you see and report it.

| Folder | Lesson | You build |
|---|---|---|
| `09-calling-an-api-with-fetch` | Calling an API with fetch (and a first look at TanStack Query) | A checked `fetch` helper and `useQuery` for the book list |
| `10-styling-and-accessibility` | Styling and accessibility | Custom properties, dark mode, icons, skip link, focus styles |
| `11-custom-hooks` | Custom hooks | `usePageTitle` and `useLocalStorage` |
| `12-project-task-list` | Project: a task list app | A **new** project `task-list`: add, tick, delete, filter, saved in the browser |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/` | The finished project (no `package-lock.json`, no `node_modules`). Lessons 09 to 11 continue `react-app`; lesson 12 is a separate project. |
| `exercise/starter/` | **Overlay files** for the Try it exercise. |
| `exercise/solution/` | The same files, completed. |
| `verify.json` | How a maintainer would check the lesson later. |

Lesson 09 adds `@tanstack/react-query` 5.108.3 to `package.json`. Lessons 10 and 12 use three CC0 icons from the course art folder (`plus`, `x`, `check-circle`) in `public/icons/ui/` with their licence file.

**How the exercise overlay works.** Copy the files from `exercise/starter/` over the same paths in your project (lesson 11 has two files, one of them new).

## Where to get the optional files
Visit https://github.com/Uee03/Code101, choose **Code > Download ZIP** and open `source/react/101-zero-to-hero/phase-3-data-and-polish/`; or run `git clone https://github.com/Uee03/Code101.git`. Windows: right-click the zip, **Extract All**; macOS: double-click; Linux: `unzip`.

## Needs
Phase 2 finished. Node 26.13.1, npm 11.20.0, React 19.3.1, Vite 8.3.8, TypeScript 5.9.3, react-router 8.5.2, TanStack Query 5.108.3. Windows PowerShell: use `npm.cmd` if `npm.ps1` is blocked. Only one dev server can use port 5173 at a time: stop the other before starting a new one.

## How to run
```powershell
npm install
npm run dev
```
Open `http://localhost:5173/`.

## Verification boundary
Nothing has been executed. Accessibility checks in the lessons (keyboard walk, zoom, dark mode) are manual and must be done by a human.

Next: level 201, `source/react/201-hero-to-super-hero/`.
