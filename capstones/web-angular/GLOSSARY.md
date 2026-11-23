# Web Angular glossary

| Term | Meaning |
|---|---|
| Standalone component | An Angular component that declares its own template dependencies without an NgModule. |
| Signal | A readable state cell that notifies Angular when its value changes. |
| Computed signal | A value derived from other signals, recalculated when its inputs change. |
| Zoneless | Change detection notified by Angular APIs rather than patched asynchronous browser APIs. |
| OnPush | A change-detection strategy that updates a component after explicit notifications, including signals. |
| Dependency injection / injector | Angular supplies a requested service from a configured provider. |
| Generated client | Typed models and request functions produced from the immutable OpenAPI contract. |
| Promise | A future result or failure of one asynchronous operation. |
| Observable / RxJS | A cancellable stream and the library used to compose streams, such as browser online events. |
| Interceptor | A function around HTTP requests/responses for common behaviour, not business features. |
| PKCE / S256 | A verifier/challenge proof binding an authorization code to the client that started sign-in; S256 uses SHA-256. |
| OIDC / discovery | OpenID Connect adds identity to OAuth; discovery publishes the issuer's endpoints. |
| Scope / role | A token's allowed operation category / a caller's assigned authority; the backend checks both. |
| Split storage | OAuthStorage implementation routing only nonce/verifier to sessionStorage and tokens to memory. |
| Nonce / state | Random values used to bind an identity response and browser sign-in attempt to their requests. |
| Single flight | Concurrent renewal callers share the same in-progress Promise, avoiding refresh-token reuse. |
| Step-up sign-in | Request an extra scope through the existing SSO session; it does not grant a missing role. |
| SSO | Single sign-on: a Keycloak session can complete a later sign-in without another password prompt. |
| Cursor | An opaque server continuation value, copied unchanged into the next list request. |
| ETag / If-Match | Exact quoted resource version / conditional-write header preventing lost updates. |
| If-None-Match / 304 | Conditional task revalidation / unchanged response that keeps cached data. |
| Optimistic update / rollback | Show a proposed edit immediately / restore the saved snapshot if the request fails. |
| Idempotency key | One UUID retained for retries of the same create action and payload. |
| Merge patch | Send only changed fields; null explicitly clears a nullable field. |
| Problem details / JSON Pointer | Structured HTTP error / slash-prefixed location of a field in a request body. |
| Retry-After | Case-insensitive HTTP header giving seconds or a date before another request. |
| Live region / landmark | Screen-reader announcement region / named page structure such as main or nav. |
| CSP | Content Security Policy restricts where a page may load or send content. |
| SPA fallback | Serve index.html for a deep application route instead of returning a static-server 404. |
| Multi-stage image | Build dependencies stay in one stage while a smaller runtime receives only the result. |
| Smoke verification | Check the environment and run one small scenario; not a unit suite or proof of browser usability. |
