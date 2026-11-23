# Angular glossary

| Term | First lesson | Meaning |
|---|---|---|
| Angular CLI | 101.01 | The `ng` command: creates projects, serves and builds them. |
| npx | 101.01 | Runs a package once without installing it globally. |
| Component | 101.02 | A TypeScript class with a template and styles, marked with `@Component`. |
| Standalone | 101.02 | A component that declares its own `imports`; no NgModule. |
| Selector | 101.02 | The HTML tag (or attribute) that places a component. |
| Interpolation | 101.03 | `{{ expression }}`: shows a value as text. |
| Property, attribute, class, event binding | 101.03 | `[prop]`, `[attr.x]`, `[class.x]`, `(event)`. |
| Template reference variable | 101.03 | `#name`: a name for an element inside a template. |
| Signal | 101.03 | A value holder that tells Angular when it changes; read with `()`. |
| Computed | 101.04 | A read-only signal derived from other signals, cached. |
| Control flow | 101.04 | `@if`, `@for` (with `track`), `@switch`, `@empty` blocks. |
| Input / output | 101.05 | `input()` passes data in; `output()` and `emit` send events out. |
| Template-driven / reactive form | 101.06 | Rules in the HTML with `ngModel`, or objects in the class with `FormGroup`. |
| Router, route, wildcard | 101.07 | Maps addresses to components; `**` matches any unknown address. |
| Service, dependency injection | 101.08 | A shared class handed out by `inject()` from the injector. |
| InjectionToken | 101.08 | A name for a plain value that can be injected. |
| HttpClient, Observable, subscribe | 101.09 | The HTTP service; a lazy stream of values; starts it. |
| Skip link, landmark, focus ring | 101.10 | Keyboard and screen-reader aids. |
| Pipe | 101.11 | `value \| name: arg` formats a value in a template. |
| Lifecycle hook | 101.11 | `ngOnInit`, `ngOnDestroy`: code at defined moments of a component's life. |
| linkedSignal | 201.01 | A computed signal you can also write; it resets when its source changes. |
| effect | 201.01 | Code that runs when signals it reads change; for side effects only. |
| switchMap, debounceTime, catchError | 201.02 | RxJS operators: cancel old work, wait for a pause, turn errors into values. |
| toSignal / toObservable | 201.02 | Bridges between signals and RxJS streams. |
| Store | 201.03 | A service that owns state and exposes read-only signals and methods. |
| Optimistic update, ETag, If-Match | 201.03 | Show the change first, undo on failure; version check for concurrent edits. |
| Idempotency-Key | 201.03 | A key that lets a server recognise a retried create. |
| Interceptor | 201.04 | A function that sees every HTTP request and response. |
| Problem details (RFC 9457) | 201.04 | The standard JSON error shape `application/problem+json`. |
| CORS, preflight | 201.04 | Browser rules for calls to another origin; the `OPTIONS` check before them. |
| OpenAPI, operationId | 201.05 | A machine-readable description of an API; the `operationId` becomes the function name of a generated client. |
| Generated client (ng-openapi-gen) | 201.05 | Typed functions and models written from the OpenAPI file; `Api.invoke` returns the body, `invoke$Response` also the headers. |
| npm lifecycle script | 201.05 | A `pre...` script (`prestart`, `prebuild`) that npm runs automatically before the script it names. |
| OIDC, authorization code flow | 201.06 | OpenID Connect sign-in: the app redirects to the identity provider and gets a one-time code back. |
| PKCE | 201.06 | A secret `code_verifier` whose hash (`code_challenge`) is sent first; makes a stolen code useless. |
| Access, refresh and id token | 201.06 | Short-lived key for the API; key to get a new access token; proof of who signed in. |
| Public client, issuer, discovery document | 201.06 | An app that cannot keep a secret; the identity provider's address; the JSON that lists its endpoints. |
| Single-flight renewal | 201.06 | Callers that need a new token at the same time share one refresh request. |
| Silent sign-in (`prompt=none`) | 201.06 | A redirect that returns a code without a login page when the provider session is still alive. |
| Open redirect, `safeReturn` | 201.06 | Sending users to an address an attacker put in a parameter; we accept only paths that start with one `/`. |
| Route guard (`CanActivateFn`), UrlTree | 201.06 | A function that decides whether a route may open; returning a UrlTree redirects. |
| Typed forms, `NonNullableFormBuilder` | 201.07 | Reactive forms whose control values have exact types and are never `null`. |
| Validator, async validator, PENDING | 201.07 | A function returning errors or `null`; one that returns an Observable or Promise; the status while it runs. |
| `setErrors` for server errors | 201.07 | Put a 422 `errors[].pointer` message on the matching control. |
| Lazy route (`loadComponent`), chunk | 201.08 | A route whose component is downloaded on first use, in its own JavaScript file. |
| Resolver (`ResolveFn`), `RedirectCommand` | 201.08 | A function that loads data before a page opens; it may redirect instead. |
| Component input binding | 201.08 | `withComponentInputBinding()` binds route params, data and resolved data to inputs. |
| `@defer`, placeholder | 201.08 | A template block whose components load later (for example `on viewport`). |
| OnPush, zoneless | 201.08 | Redraw a component only when its inputs, events or signals change; no Zone.js, so only signals and events trigger redraws. |
| Skip link, landmark, live region | 201.09 | Jump over repeated navigation; named page areas; an element whose text changes are read aloud. |
| Focus management, `TitleStrategy` | 201.09 | Moving focus and setting the tab title after a route change. |
| WCAG 2.2 | 201.09 | The W3C accessibility guidelines; level AA is the usual target. |
| i18n, `$localize`, message id | 201.09 | Marking text for translation; the tagged template function; the stable `@@id` of a message. |
| XLIFF, `trans-unit` | 201.09 | The translation file format: a `source` and a `target` per id. |
| Compile-time i18n, locale build | 201.09 | One built app per language (`ng build --localize`). |
| Board, optimistic move | 201.10 | Show a card in its new column at once, send `If-Match`, roll back or reload on failure. |
| `authEnabled` flag | 201.10 | An environment switch that turns browser-side sign-in on or off; it protects nothing on the server. |
