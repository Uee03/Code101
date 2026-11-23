# React track brief

Prerequisite: Web 101. Stack (from `capstones/web-react/TDD.md`): React 19.3.1, Vite 8.3.8 + @vitejs/plugin-react 6.3.0, TypeScript 5.9.3, react-router 8.5.2 (data router), @tanstack/react-query 5.108.3, openapi-typescript 7.13.0 + openapi-fetch 0.17.0, react-oidc-context 3.3.1 + oidc-client-ts 3.5.0, zustand 5.1.0 (201 lesson 03 only), Node 26.13.1, npm 11.20.0. Levels: 101 and 201 only (no 301). Tier 1 sources: react.dev, vite.dev, tanstack.com/query.

Rules: no checks, tests or unit-test lessons (WRITING-BRIEF); every lesson carries the draft notice and `verified: not yet run`; no `package-lock.json`; icons only from `assets/art` (CC0).
Layout: `tutorials/react/<level>/phase-N-slug/NN-slug.md`, `source/react/<level>/phase-N-slug/NN-slug/{code,exercise/starter,exercise/solution,verify.json}`; exercises are overlay files.

## 101 Zero to Hero (12 lessons, all written)
| Phase | Lessons |
|---|---|
| 1 first-app | 01 Install Node, create a Vite React app and run it; 02 JSX and components; 03 Props and rendering lists; 04 State with useState and events |
| 2 building | 05 Forms and controlled inputs; 06 Effects and fetching data; 07 Routing with React Router; 08 Sharing state: lifting up and context |
| 3 data-and-polish | 09 Calling an API with fetch (and TanStack Query); 10 Styling and accessibility; 11 Custom hooks; 12 Project: a task list app |

## 201 Hero to Super Hero (10 lessons, all written)
| Id | Title | Status |
|---|---|---|
| 201.1.01 | Hooks in depth | written |
| 201.1.02 | TanStack Query | written |
| 201.1.03 | State management options (context vs Zustand) | written |
| 201.2.04 | A typed API client | written |
| 201.2.05 | Error handling, problem+json and error boundaries | written |
| 201.2.06 | OIDC login with PKCE and protected routes | written |
| 201.3.07 | Forms and validation | written |
| 201.3.08 | Performance (memo, code splitting, Suspense) | written |
| 201.3.09 | Accessibility | written |
| 201.3.10 | Project: a task board against the platform contract (then capstones/web-react) | written |
