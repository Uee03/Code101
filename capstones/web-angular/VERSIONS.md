# Official version checks, 2026-11-23

Runtime facts below were captured **before** the user paused execution. Current chapter status is written (not run); no final runtime PASS is claimed.

| Tool/library | Pin and official check |
|---|---|
| Angular / CLI / build / compiler | 22.3.0; npm package version/engines/peer metadata, actual pinned npx ng new and production builds. https://angular.dev/reference/versions accepts Node ^26.0.0, TypeScript >=6.0.0 <6.1.0, RxJS ^7.4.0. https://angular.dev/tools/cli/setup-local |
| Angular architecture | Standalone/OnPush, functional interceptors; zoneless is default since v21. https://angular.dev/style-guide (Tier 1), https://angular.dev/guide/zoneless, https://angular.dev/guide/http/interceptors |
| Node / npm | Installed v26.13.1 / 11.20.0, actual node --version/npm --version output. https://nodejs.org/en/download links the v26.13.1 release. https://docs.npmjs.com/cli/v11/commands/npm-ci defines lockfile-only reproducible installation. |
| TypeScript | 6.0.3; npm version/repository metadata and actual Angular build. https://github.com/microsoft/TypeScript |
| RxJS | 7.8.2; npm version/repository metadata and Angular peer range; actual stream/interceptor compilation. https://github.com/reactivex/rxjs |
| tslib | 2.8.1; npm version/repository metadata, installed with lockfile. https://github.com/Microsoft/tslib |
| ng-openapi-gen | 1.1.0; official maintainer README/schema and actual generation of 27 operations/33 models from OpenAPI 3.1.1. https://github.com/cyclosproject/ng-openapi-gen |
| angular-oauth2-oidc | 22.0.2; npm peers >=22; inspected pinned oauth-service.ts/installed declarations for nonce/PKCE_verifier, initCodeFlow, timeoutFactor, refreshToken and logOut. Protected createLoginUrl is NOT called directly. Actual library-generated S256 URL returned a Keycloak login page 200. https://github.com/manfredsteyer/angular-oauth2-oidc/tree/22.0.2 |
| tsx | 4.23.15; npm version/engines/repository metadata (Node >=18), actual execution of generated functions in Node. https://github.com/privatenumber/tsx . The tsx.is docs site did not respond in two attempts; no claim that its page was read. |
| Node builder image | node:26-alpine; tag appears in official image page, manifest resolved; actual multi-stage build succeeded. https://hub.docker.com/_/node |
| nginx runtime image | nginxinc/nginx-unprivileged:1.30-alpine; manifest resolved and actual container user=101 health=healthy; official Hub page marks repository archived and directs users to nginx/nginx-unprivileged. Original approved pin retained, maintenance finding reported. https://hub.docker.com/r/nginxinc/nginx-unprivileged |

Python/Postgres/Keycloak dependency pins are inherited verbatim from backend-python's final phase pack, not upgraded in this client. Only the installed environment and one small generated-client scenario per snapshot are verified; no unit suites, ng test, lint, dependency-audit suite or browser automation were run. npm audit --omit=dev remains release advice, not a claimed audit result.
