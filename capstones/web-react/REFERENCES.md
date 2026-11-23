# Official references checked 2026-11-23

Package versions were queried from the npm registry (the publishers' package manifests), not guessed from current latest tags.
Node v26.13.1, npm 11.20.0, Docker 29.9.3 were available. create-vite 9.3.4 created the react-ts scaffold.
React 19.3.1; react-dom 19.3.1; Vite 8.3.8; @vitejs/plugin-react 6.3.0; TypeScript 5.9.3; react-router 8.5.2;
@tanstack/react-query 5.108.3; openapi-typescript 7.13.0 (peer TypeScript ^5.x); openapi-fetch 0.17.0;
react-oidc-context 3.3.1 (peer oidc-client-ts ^3.1.0); oidc-client-ts 3.5.0; tsx 4.23.15.

- https://react.dev/learn/build-a-react-app-from-scratch ? Vite scaffold, routing and TanStack Query for client REST state (Tier 1).
- https://react.dev/learn/you-might-not-need-an-effect ? derive values rather than synchronize duplicate state (Tier 1).
- https://vite.dev/guide/ ? react-ts, dev/build commands.
- https://vite.dev/config/server-options ? port 5173 and strictPort.
- https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-9.html ? strict, verbatimModuleSyntax.
- https://reactrouter.com/start/data/installation ? createBrowserRouter from react-router; RouterProvider from react-router/dom.
- https://tanstack.com/query/latest/docs/framework/react/guides/optimistic-updates ? cancel, snapshot, roll back, invalidate.
- https://openapi-ts.dev/introduction ? generate 3.1 runtime-free types; noUncheckedIndexedAccess.
- https://openapi-ts.dev/openapi-fetch/middleware-auth ? native Request/Response cloning and token boundary.
- https://github.com/authts/react-oidc-context ? callback URL cleanup and provider lifecycle.
- https://authts.github.io/oidc-client-ts/classes/InMemoryWebStorage.html ? Storage implementation for the user store.
- https://authts.github.io/oidc-client-ts/interfaces/UserManagerSettings.html ? automaticSilentRenew, userStore and stateStore.
- https://github.com/privatenumber/tsx ? TypeScript runner (tsx.is certificate chain failed locally; official repository used).
- https://github.com/nginx/docker-nginx-unprivileged ? non-root, 8080, temporary PID path.
- https://nodejs.org/en/about/previous-releases ? Node release documentation.
- https://www.w3.org/TR/WCAG22/ ? manual accessibility checklist, not an automated conformance claim.

The requested node:26-alpine and nginxinc/nginx-unprivileged:1.30-alpine images were actually pulled/built/run by the production smoke.
See captures/ for real command output. No browser automation, test suite, or linter was used.
