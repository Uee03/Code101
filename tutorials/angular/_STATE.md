# Angular track state

Last updated: 2026-11-23. Status: **written (not run)** for all 22 lessons (101: 12, 201: 10). Nothing was executed; the static check was not run either (user rule).

| Level | Lesson | Status |
|-------|--------|--------|
| 101 | 01 Install Node and the Angular CLI, create and run your first app | written (not run) |
| 101 | 02 Project tour and standalone components | written (not run) |
| 101 | 03 Templates and data binding | written (not run) |
| 101 | 04 Control flow (@if, @for, @switch) and signals basics | written (not run) |
| 101 | 05 Component inputs and outputs | written (not run) |
| 101 | 06 Forms (template-driven then reactive intro) | written (not run) |
| 101 | 07 Routing | written (not run) |
| 101 | 08 Services and dependency injection | written (not run) |
| 101 | 09 HttpClient and calling an API | written (not run) |
| 101 | 10 Styling and accessibility | written (not run) |
| 101 | 11 Pipes and component lifecycle basics | written (not run) |
| 101 | 12 Project: a task list app | written (not run) |
| 201 | 01 Signals in depth (computed, effect, linkedSignal) | written (not run) |
| 201 | 02 RxJS essentials and signal interop | written (not run) |
| 201 | 03 State patterns (service with signals) | written (not run) |
| 201 | 04 HTTP interceptors and problem+json error handling | written (not run) |
| 201 | 05 A typed API client from OpenAPI (ng-openapi-gen) | written (not run) |
| 201 | 06 OIDC login with PKCE and route guards (angular-oauth2-oidc, Keycloak realm tasksteams) | written (not run) |
| 201 | 07 Reactive forms and validation | written (not run) |
| 201 | 08 Lazy routes, resolvers and performance (OnPush, zoneless note) | written (not run) |
| 201 | 09 Accessibility and i18n basics | written (not run) |
| 201 | 10 Project: a task board against the platform contract | written (not run) |

Phase packs with a `PACK-README.md`: 101 phases 1 to 3, 201 phase 1 (lessons 01 to 03), 201 phase 2 (lessons 04 to 06) and 201 phase 3 (lessons 07 to 10). The Angular 201 track is fully written; the next step is the capstone `capstones/web-angular`.

## Known gaps and risks (for the next author or the verifier)
- No code was compiled. Risky spots to check first: `@let` narrowing in 201/04 `demo.html` and 201/05 `explorer.html`; `[(ngModel)]` bound to a signal in 101/06; `ng new` flags and generated-file list in 101/01 (shown as "typical"); `ariaCurrentWhenActive` and `(activate)` on the router outlet in 101/07 and 101/10; `linkedSignal` typings in 201/01; console-order claims in 201/01.
- 201/05: the generated names are assumed from the capstone usage (`api/functions`, `api/models`, `Api.invoke`, `invoke$Response`, header params such as `'If-Match'`); check the first `npm run api:gen` output. The `@angular/localize`, `angular.json` `i18n`/`localize`/serve `de` configuration of 201/09 follows angular.dev but was not built.
- 201/06: the code follows the capstone's `AuthService`; `OAuthEvent` narrowing, `provideOAuthClient()`, `refreshToken()` and the silent `prompt=none` flow were not run. The mock decodes the token payload without verifying it (documented as a classroom shortcut).
- 201/07: `toSignal(form.statusChanges)` is used to redraw a zoneless `OnPush` view after async validation; confirm in a browser that "Checking..." disappears. 201/08: `@defer (on viewport)` of a component imported in the same file, `RedirectCommand` from a resolver and `withComponentInputBinding` for `data` and resolved data were not run. 201/09: hand-written XLIFF 1.2 ids and `<x id="INTERPOLATION">` placeholder; the CLI sets `lang` per locale as documented. 201/10: `environment.authEnabled` keeps `angular-oauth2-oidc` in the initial bundle; a rollback re-creates the card and does not restore focus (documented).
- 201 lessons 07 to 09 continue from the lesson 05 project; lesson 10 re-adds sign-in. Learners who followed 06 must start phase 3 from a fresh copy of lesson 05 (said in 07).
- Packaging (`build_packs.py`) and the static check were not run.
