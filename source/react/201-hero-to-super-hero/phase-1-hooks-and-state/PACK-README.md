# React 201, Phase 1: Hooks and state

Source pack for lessons 01 to 03. **Status: written, not yet run.** Prepared by reading the code and the official documentation; nothing has been installed, built or opened in a browser (see `tutorials/react/_STATE.md`).

| Folder | Lesson | You build |
|---|---|---|
| `01-hooks-in-depth` | Hooks in depth | A reducer-driven board; console proof of which rows redraw (`memo`, `useMemo`, `useCallback`, `useRef`) |
| `02-tanstack-query` | TanStack Query | Queries, mutations, invalidation and an optimistic update against an in-memory fake API |
| `03-state-management-options` | State management options | Context for the view mode, Zustand for search and toasts |

Each lesson folder has `code/` (finished project, no `package-lock.json`: `npm install` creates it), `exercise/starter/` and `exercise/solution/` (**overlay files**: copy them over your project), and `verify.json` (for a later run).

Optional files: https://github.com/Uee03/Code101 (**Code > Download ZIP** or `git clone https://github.com/Uee03/Code101.git`), folder `source/react/201-hero-to-super-hero/phase-1-hooks-and-state/`.

Needs: Web 101 and React 101 finished; Node 26.13.1, npm 11.20.0, React 19.3.1, Vite 8.3.8, TypeScript 5.9.3, TanStack Query 5.108.3, zustand 5.1.0. Run `npm install` then `npm run dev` in a lesson's `code/` folder.
