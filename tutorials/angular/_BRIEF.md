# Angular track brief (levels 101 and 201; no 301)

## Audience and outcome
**101 Zero to Hero:** learners who finished Web 101 (HTML, CSS, JavaScript, TypeScript, `npm`). Outcome: install the toolchain, build and run a standalone, signal-based Angular 22 app with components, templates, control flow, forms, routing, services, HttpClient, pipes and accessible styling, ending with a task list project.
**201 Hero to Super Hero:** learners who finished 101 (1 to 2 years of experience). Outcome: the skills `capstones/web-angular` assumes: signals in depth, RxJS and interop, store services, interceptors and problem+json, a typed client generated from OpenAPI, OIDC sign-in with PKCE and guards, reactive forms, lazy routes and resolvers, accessibility and i18n.
No tests, linters or unit-test lessons (user rule 2026-11-23); `verify.json` files only describe an install and a build.

## Versions (checked 2026-11-23 against angular.dev and the web-angular capstone)
Angular and CLI 22.3.0, TypeScript 6.0.3 (Angular 22 accepts `>=6.0.0 <6.1.0`), RxJS 7.8.2, tslib 2.8.1, Node 26.13.1 (Angular 22 accepts `^22.22.3`, `^24.15.0`, `^26.0.0`), npm 11.20.0. Used in lessons 05 to 10: `ng-openapi-gen` 1.1.0 (05), `angular-oauth2-oidc` 22.0.2 (06 and 10), `@angular/localize` 22.3.0 (09 and 10). The CLI is never installed globally: `npx --yes -p @angular/cli@22.3.0 ng new ...`. Angular 22 makes OnPush the default; 201 writes it explicitly.

## Plan
| Level | Phase | Lesson | Project | Status |
|-------|-------|--------|---------|--------|
| 101 | 1 first-app | 01 Install Node and the Angular CLI, create and run your first app | tasks-first | written (not run) |
| 101 | 1 | 02 Project tour and standalone components | tasks-first | written (not run) |
| 101 | 1 | 03 Templates and data binding | tasks-first | written (not run) |
| 101 | 1 | 04 Control flow (@if, @for, @switch) and signals basics | tasks-first | written (not run) |
| 101 | 2 building | 05 Component inputs and outputs | tasks-first | written (not run) |
| 101 | 2 | 06 Forms (template-driven then reactive intro) | tasks-first | written (not run) |
| 101 | 2 | 07 Routing | tasks-first | written (not run) |
| 101 | 2 | 08 Services and dependency injection | tasks-first | written (not run) |
| 101 | 3 data-and-polish | 09 HttpClient and calling an API | tasks-first | written (not run) |
| 101 | 3 | 10 Styling and accessibility | tasks-first | written (not run) |
| 101 | 3 | 11 Pipes and component lifecycle basics | tasks-first | written (not run) |
| 101 | 3 | 12 Project: a task list app | task-list | written (not run) |
| 201 | 1 signals-and-state | 01 Signals in depth (computed, effect, linkedSignal) | signals-lab | written (not run) |
| 201 | 1 | 02 RxJS essentials and signal interop | signals-lab | written (not run) |
| 201 | 1 | 03 State patterns (service with signals) | signals-lab | written (not run) |
| 201 | 2 http-and-auth | 04 HTTP interceptors and problem+json error handling | task-board | written (not run) |
| 201 | 2 | 05 A typed API client from OpenAPI (ng-openapi-gen) | task-board | written (not run) |
| 201 | 2 | 06 OIDC login with PKCE and route guards (angular-oauth2-oidc, Keycloak realm tasksteams) | task-board | written (not run) |
| 201 | 3 architecture-and-quality | 07 Reactive forms and validation | task-board | written (not run) |
| 201 | 3 | 08 Lazy routes, resolvers and performance (OnPush, zoneless note) | task-board | written (not run) |
| 201 | 3 | 09 Accessibility and i18n basics | task-board | written (not run) |
| 201 | 3 | 10 Project: a task board against the platform contract (then `capstones/web-angular`) | task-board | written (not run) |

Design notes (as written): lesson 05 has a mini OpenAPI file (getHealth, getMe, listTeams, listProjects, listTasks, createTask, getTask, updateTask; schemas copied from `capstones/platform`, `updateTask` keeps only `application/json`) with `ng-openapi-gen` `promises: true, services: false`; the generated `src/app/api` is git-ignored and rebuilt by `prestart` and `prebuild`. Lesson 06's mock (`npm run mock:auth`) reads `preferred_username` from the bearer payload without checking it (classroom shortcut) so bob is `member`; auth code is modelled on `capstones/web-angular` (split storage, single-flight refresh, silent re-entry with `ts.hint`) and uses Keycloak from `capstones/platform` (Docker, temporary). Phase 3 lessons 07 to 09 continue from the lesson 05 project (no sign-in, mock only); lesson 10 brings sign-in back from lesson 06 files behind `environment.authEnabled`. i18n uses explicit message ids and a hand-written German XLIFF 1.2 file (`@angular/localize` 22.3.0).

## Conventions
- Paths: `tutorials/angular/<level>/phase-N-slug/NN-slug.md`, `source/angular/<level>/phase-N-slug/NN-slug/{code,exercise/starter,exercise/solution,verify.json}` plus `PACK-README.md` per phase. Exercises are overlay files.
- Every file is shown in the lesson. Files unchanged since an earlier lesson are listed in a closing "did not change" block. No `package-lock.json` (`npm install` creates it).
- Icons only from `assets/art` (CC0): 101/01 `ui/check-circle` (favicon), 101/10 and 101/12 `ui/plus`, `ui/x`, `ui/alert-triangle`, `arrows/refresh-cw`.
- Tier 1 references: angular.dev (style guide, signals, HTTP, routing, i18n), rxjs.dev, RFC 9457, WCAG 2.2.

## Verification boundaries
Nothing was run: no `ng`, npm, build, server, browser or check script. Expected outputs are derived by reading code or marked "typical". Lessons 01 to 04 were assembled from draft files by a helper that expands code from the source files, so lesson text and code match by construction; lessons 05 to 10 were assembled the same way. Generated files (`src/app/api`) are not shown in full: lesson 05 shows only a typical, abbreviated shape. Package versions `ng-openapi-gen` 1.1.0, `angular-oauth2-oidc` 22.0.2 and `@angular/localize` 22.3.0 were taken from the web-angular capstone and the Angular version pin, not re-checked against the registry in this block.
