# React glossary

| Term | First lesson | Meaning |
|---|---|---|
| Component | 101.02 | A function that returns JSX; name starts with a capital letter |
| JSX | 101.02 | HTML-like syntax inside TypeScript, turned into function calls by Vite |
| Props | 101.03 | Inputs a parent passes to a component |
| key | 101.03 | Stable unique value that identifies a list item |
| State | 101.04 | Memory a component keeps between draws (`useState`) |
| Controlled input | 101.05 | An input whose value comes from state |
| Effect | 101.06 | Code React runs after drawing to sync with the outside world (`useEffect`) |
| Dependency array | 101.06 | List of values that decide when an effect runs again |
| Router / Outlet | 101.07 | Maps addresses to components; Outlet is where the child route appears |
| Lifting state up | 101.08 | Moving state to the closest common parent |
| Context | 101.08 | A shared value any component below a provider can read |
| TanStack Query | 101.09 | Library that fetches, caches and refreshes server data |
| Custom hook | 101.11 | Your own `use...` function that shares logic, not data |
| Reducer | 201.01 | Pure function `(state, action) => newState` used with `useReducer` |
| Ref | 201.01 | Mutable box (`useRef`) that does not cause a redraw |
| memo / useMemo / useCallback | 201.01 | Tools that keep references stable so redraws can be skipped |
| Server state | 201.02 | Data owned by a server and cached in the client |
| Invalidation | 201.02 | Marking cached data stale so it is refetched |
| Optimistic update | 201.02 | Showing the expected result first and rolling back on failure |
| Zustand store / selector | 201.03 | Small external store; a selector picks the value a component reads |
| OpenAPI contract | 201.04 | Machine-readable description of the API |
| Problem details | 201.05 | RFC 9457 `application/problem+json` error body |
| Error boundary | 201.05 | Class component that shows a fallback when a child throws while rendering |
| OIDC / PKCE | 201.06 | Sign-in standard; PKCE protects the code with a one-time verifier |
| Public client | 201.06 | An app that cannot keep a secret (a browser app) |
| Single-flight refresh | 201.06 | All callers share one token refresh request |
| Error summary | 201.07 | List of form problems that takes focus after a failed submit |
| Idempotency key | 201.07 | Header value that makes a retried create return the first result |
| Render vs commit | 201.08 | Render: React calls your component; commit: React applies the difference to the page |
| Profiler | 201.08 | React DevTools tab and `<Profiler onRender>` that report how long components took to draw |
| Code splitting / lazy | 201.08 | `lazy(() => import(...))` makes a separate file that loads when first drawn |
| Suspense / use | 201.08 | A boundary that shows a fallback while a child waits; `use(promise)` reads a cached promise while drawing |
| useDeferredValue | 201.08 | A copy of a value that lags behind so urgent updates (typing) stay fast |
| Skip link / landmark | 201.09 | First link that jumps past the menu; `header`, `nav`, `main` regions screen readers can jump to |
| Live region | 201.09 | An element (`role="status"` or `alert`) whose text changes are announced; it must exist before the message |
| Focus management | 201.09 | Moving keyboard focus on purpose after navigation, a move or a delete |
| Native dialog | 201.09 | `<dialog>` with `showModal()`: focus trap, Esc and inert background built in |
| Accessible name | 201.09 | The text assistive technology reads for a control (label, `aria-label`) |
| Infinite query | 201.10 | `useInfiniteQuery`: pages joined by `nextCursor`, loaded with "Load more" |
| If-Match / 412 | 201.10 | Request header with the version being changed; the server answers 412 when it is stale |
