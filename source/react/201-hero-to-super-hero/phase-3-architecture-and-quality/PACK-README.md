# React 201, Phase 3: Architecture and quality

Source pack for lessons 07 to 10. **Status: written, not yet run.** Prepared by reading the code and the official documentation; nothing has been installed, built or opened in a browser (see `tutorials/react/_STATE.md`).

| Folder | Lesson | You build |
|---|---|---|
| `07-forms-and-validation` | Forms and validation | `FormData` form, pure validation, error summary with focus, 422 pointer mapping, idempotency key |
| `08-performance` | Performance (memo, code splitting, Suspense) | 2000-row list, row counter, `memo` plus stable props, `useDeferredValue`, `lazy` report, `Suspense` with `use` |
| `09-accessibility` | Accessibility | Skip link, landmarks, route-change focus and title, live region, native `<dialog>`, "Move to" select, CC0 icons |
| `10-project-task-board` | Project: a task board against the platform contract | Signed-in board: projects, infinite task list, optimistic move with `If-Match`, create with `Idempotency-Key` |

Each lesson folder has `code/` (no `package-lock.json`, no `node_modules`; lesson 10 also has no generated `src/api/schema.d.ts`), `exercise/starter/` and `exercise/solution/` (**overlay files**) and `verify.json`. Lessons 07 to 09 need no backend. Lesson 10 needs the platform stack and one backend for a live run (Keycloak 8180, API 8000); use `http://localhost:5173`, never `127.0.0.1`. `10-project-task-board/code/contract/openapi.yaml` is a verbatim copy of the platform contract and must never be edited.

Optional files: https://github.com/Uee03/Code101 (**Code > Download ZIP** or `git clone https://github.com/Uee03/Code101.git`), folder `source/react/201-hero-to-super-hero/phase-3-architecture-and-quality/`.

Needs: Node 26.13.1, npm 11.20.0, React 19.3.1, Vite 8.3.8, TypeScript 5.9.3; lesson 09 adds react-router 8.5.2; lesson 10 adds react-router 8.5.2, @tanstack/react-query 5.108.3, openapi-typescript 7.13.0, openapi-fetch 0.17.0, react-oidc-context 3.3.1, oidc-client-ts 3.5.0. Run `npm install` then `npm run dev` (lesson 10 generates the types first).
