# React 201, Phase 2: HTTP and auth

Source pack for lessons 04 to 06. **Status: written, not yet run.** Prepared by reading the code and the official documentation; nothing has been installed, built or opened in a browser (see `tutorials/react/_STATE.md`).

| Folder | Lesson | You build |
|---|---|---|
| `04-typed-api-client` | A typed API client | Types generated from the platform contract, `openapi-fetch` client, health hook |
| `05-error-handling` | Error handling | `ApiProblem` parser, status table, error panel, error boundary, canned server answers |
| `06-oidc-login-and-protected-routes` | OIDC login with PKCE | `react-oidc-context` against Keycloak realm `tasksteams`, memory-only tokens, `RequireAuth` |

Each lesson folder has `code/` (no `package-lock.json`, no `node_modules`, no generated `src/api/schema.d.ts`), `exercise/starter/` and `exercise/solution/` (**overlay files**), and `verify.json`. `code/contract/openapi.yaml` is a verbatim copy of the platform contract and must never be edited. Lessons 04 and 06 need the platform stack and one backend for a live run (Keycloak 8180, API 8000); use `http://localhost:5173`, never `127.0.0.1`.

Optional files: https://github.com/Uee03/Code101 (**Code > Download ZIP** or `git clone https://github.com/Uee03/Code101.git`), folder `source/react/201-hero-to-super-hero/phase-2-http-and-auth/`.

Needs: Node 26.13.1, npm 11.20.0, React 19.3.1, Vite 8.3.8, TypeScript 5.9.3, openapi-typescript 7.13.0, openapi-fetch 0.17.0, react-router 8.5.2, react-oidc-context 3.3.1, oidc-client-ts 3.5.0. Run `npm install` then `npm run dev` (it generates the types first).
