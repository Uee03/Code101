# React 101, Phase 2: Building

Source pack for lessons 05 to 08. **Status: written, not yet run.** The code was prepared by reading the code and the official documentation; no install, build or browser check has been executed yet (see `tutorials/react/_STATE.md`). If something behaves differently from the lesson, trust what you see and report it.

| Folder | Lesson | You build |
|---|---|---|
| `05-forms-and-controlled-inputs` | Forms and controlled inputs | An "Add a book" form with validation |
| `06-effects-and-fetching-data` | Effects and fetching data | The list loads `books.json` with loading and error states |
| `07-routing-with-react-router` | Routing with React Router | Pages: list, book detail, About, not found |
| `08-sharing-state-lifting-and-context` | Sharing state: lifting up and context | A `BooksContext` shared by header, list and detail |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/` | The finished project at the end of that lesson (no `package-lock.json`, no `node_modules`). |
| `exercise/starter/` | **Overlay files** for the Try it exercise. |
| `exercise/solution/` | The same files, completed. |
| `verify.json` | How a maintainer would check the lesson later. |

You continue in the same `react-app` project. From lesson 07 `package.json` also lists `react-router` 8.5.2; after editing it run `npm install` and restart `npm run dev`.

**How the exercise overlay works.** Copy the files from `exercise/starter/` over the same paths in your project. To keep your finished lesson, copy your project (without `node_modules`) first and run `npm install` in the copy.

## Where to get the optional files
Visit https://github.com/Uee03/Code101, choose **Code > Download ZIP** and open `source/react/101-zero-to-hero/phase-2-building/`; or run `git clone https://github.com/Uee03/Code101.git`. Windows: right-click the zip, **Extract All**; macOS: double-click; Linux: `unzip`.

## Needs
Phase 1 finished. Node 26.13.1, npm 11.20.0, React 19.3.1, Vite 8.3.8, TypeScript 5.9.3, react-router 8.5.2 (from lesson 07). Windows PowerShell: use `npm.cmd` if `npm.ps1` is blocked.

## How to run
```powershell
npm install
npm run dev
```
Open `http://localhost:5173/`. Deep links such as `/books/1` work because the dev server falls back to `index.html`.

## Verification boundary
Nothing has been executed; browser behaviour is described from reading the code.

Next: phase 3, Data and polish (`../phase-3-data-and-polish/`).
