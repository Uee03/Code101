# React 101, Phase 1: First app

Source pack for lessons 01 to 04. **Status: written, not yet run.** The code was prepared by reading the code and the official documentation; no install, build or browser check has been executed yet (see `tutorials/react/_STATE.md`). If something behaves differently from the lesson, trust what you see and report it.

| Folder | Lesson | You build |
|---|---|---|
| `01-install-node-and-run-a-vite-app` | Install Node, create a Vite React app and run it | A project that shows "Hello, React" |
| `02-jsx-and-components` | JSX and components | A page made of `Header`, `Footer` and a welcome area |
| `03-props-and-lists` | Props and rendering lists | Book cards drawn from an array |
| `04-state-and-events` | State with `useState` and events | Cards you can mark read, a filter and a counter |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/` | The finished project at the end of that lesson. No `package-lock.json` and no `node_modules`: `npm install` creates them. |
| `exercise/starter/` | **Overlay files** for the Try it exercise (only the files the exercise changes). |
| `exercise/solution/` | The same files, completed. Try the exercise first. |
| `verify.json` | How a maintainer would check the lesson later (install, build, probe). |

You keep **one** project folder (`react-app`) for lessons 01 to 11. Each `code/` folder shows that project after the lesson; boilerplate files that did not change are repeated so every folder runs alone, and the lesson tells you which files are unchanged.

**How the exercise overlay works.** Open the lesson's `exercise/starter` folder and copy its files over the same paths in your project (for example `exercise/starter/src/App.tsx` replaces `src/App.tsx`). To keep your finished lesson, copy your project folder first (leave out `node_modules`), then run `npm install` in the copy.

## Where to get the optional files
Every file and starter is shown in the lesson, so the pack is optional. Visit https://github.com/Uee03/Code101 and choose **Code > Download ZIP**, then open `source/react/101-zero-to-hero/phase-1-first-app/` in the extracted folder. Or run `git clone https://github.com/Uee03/Code101.git`. Windows: right-click the zip, **Extract All**; macOS: double-click; Linux: `unzip`.

## Needs
- Web 101 finished. Node 26.13.1, npm 11.20.0 (lesson 01 checks them), a current browser, VS Code.
- React 19.3.1, Vite 8.3.8, `@vitejs/plugin-react` 6.3.0, TypeScript 5.9.3, pinned exactly in `package.json`.
- Windows PowerShell: if `npm.ps1` is blocked, use `npm.cmd` and `npx.cmd`.

## How to run
In the lesson's `code/` folder (or your project):
```powershell
npm install
npm run dev
```
Open the `Local:` address Vite prints (`http://localhost:5173/`). `npm run build` type-checks and builds into `dist/`.

## Verification boundary
Nothing has been executed. Expected browser appearance in the lessons is described from the code, never from a screenshot.

Next: phase 2, Building (`../phase-2-building/`).
