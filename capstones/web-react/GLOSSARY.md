# Web React glossary

| Term | Meaning |
|---|---|
| SPA | Single-page application: the browser router changes screens while one HTML entry remains loaded. |
| Contract | The platform-owned OpenAPI description of HTTP paths, inputs, outputs and security. |
| Generated client | A small runtime HTTP client whose paths and request/response types come from generated declarations. |
| DTO | Data transfer object: the JSON-shaped entity/request type exchanged with the API. |
| Lockfile | Generated exact dependency resolutions used by npm ci; different from a process/port lock. |
| ESM | JavaScript modules using import/export. |
| PKCE | Proof Key for Code Exchange: a random verifier binds an authorization code to its initiating client. S256 is its SHA-256 challenge method. |
| OIDC | OpenID Connect: the identity protocol implemented by Keycloak and the browser auth library. |
| Issuer | The exact authority URL that minted a token; localhost and 127.0.0.1 are not interchangeable. |
| Scope | A permission requested for a client, intersected with the caller's role and team membership. |
| SSO | Single sign-on: the identity provider's existing session can complete another redirect without another password. |
| Step-up | An additional authorization redirect requesting tasks:admin for an admin-only operation. |
| User store | The in-memory OIDC user/token store; deliberately does not survive reload. |
| State store | Transient per-tab storage of redirect state and PKCE verifier; not token storage. |
| Single flight | Concurrent renewal callers share one in-progress promise, important with refresh-token rotation. |
| Bearer boundary | Code that adds a token only for the configured API origin and base-path boundary. |
| Server state | Remote data cached and revalidated by TanStack Query, not copied into a second global store. |
| Query key | The stable identity of a cached resource/list, including parent and filter values. |
| Mutation | An intentional server write, unlike a query/read. |
| Invalidation | Marking cached server state stale so it can be fetched again after a write. |
| Opaque cursor | A next-page string copied unchanged from page.nextCursor; clients never decode or create it. |
| Idempotency key | One UUID per submit attempt; the same body/key can replay a create without duplicating it. |
| ETag | The API's exact quoted strong version label, cached alongside a resource. |
| If-Match | Request header carrying the exact ETag that must still match before a write. |
| If-None-Match | Conditional task GET header; a matching tag returns 304 and no new body. |
| Optimistic update | Showing an anticipated cache change before a write completes, with a snapshot for rollback. |
| Rollback | Restoring the previous cached snapshot after a failed optimistic write. |
| Problem details | RFC 9457 structured error fields carried as application/problem+json. |
| JSON Pointer | A field location such as /title in validation errors; maps to a named form control. |
| Trace id | A non-secret support identifier connecting an error response to API logs. |
| Live region | A status/alert region announced by assistive technology without moving keyboard focus. |
| CSP | Content Security Policy: browser-enforced response rules limiting resource and connection origins. |
| CORS | Cross-origin resource sharing: the API/identity server's explicit browser origin/header rules. |
| BFF | Backend-for-frontend: a server alternative that can keep tokens away from browser JavaScript using HttpOnly cookies. |
| Build context | Files sent to Docker's builder; .dockerignore keeps unnecessary or local-sensitive files out. |
| Multi-stage image | A build stage emits assets, then a smaller separate runtime stage copies only the needed output. |
| Non-root | A runtime process with a nonzero uid, reducing operating-system privileges. |
| SPA fallback | nginx serves index.html for client routes such as /teams so a deep link loads the router. |
| Smoke verification | One small execution proving the environment/code works; not a unit suite, browser test or certification. |
