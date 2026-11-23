# Web Foundations 301 state

Last updated: 2026-11-23. Level: 301-super-hero-to-legendary. Status: **written (not run)**. Nothing was compiled, installed, built, served or opened in a browser (user policy, 2026-11-23). Only `python scripts/verify_labs.py --static web/301` and `python scripts/build_packs.py web-301` were run.

Toolchain assumed (not installed or executed by the author): Node 26.13.1, npm 11.20.0, TypeScript 7.0.2 (5.9.3 in lesson 06), Vite 8.3.8, Chrome or Edge for DevTools and Lighthouse. Versions were read from the npm registry, GitHub releases and official documentation on 2026-11-23 (details in `_BRIEF-301.md`).

| Lesson | Phase | Status | Evidence |
|---|---|---|---|
| 01 Advanced generics, conditional and mapped types | 1 | written (not run) | Static check: text contains every code line and expected output; verify.json parses |
| 02 Template literal types, type-safe routing and exhaustive checks | 1 | written (not run) | Same |
| 03 Library-quality TypeScript | 1 | written (not run) | Same |
| 04 Design systems and design tokens | 2 | written (not run) | Same |
| 05 Monorepos and build tooling | 2 | written (not run) | Same; hidden files (`.npmrc`, `.gitignore`, `ci.yml`) and `affected.mjs` are not covered by the static check and were pasted by hand |
| 06 API clients generated from OpenAPI | 2 | written (not run) | Same; generated `schema.d.ts` is not shipped |
| 07 Performance budgets and browser internals | 3 | written (not run) | Same; `.mjs` and workflow files pasted by hand |
| 08 Security hardening | 3 | written (not run) | Same; `.mjs`, `.npmrc`, workflow and Dependabot files pasted by hand |
| 09 Micro-frontends, release strategy and a production readiness checklist | 3 | written (not run) | Same; workflow pasted by hand; includes a pull request review exercise |

## Needs a human with a browser
Browser appearance and behaviour were described from the CSS and code only. Before marking a lesson verified, someone with Chrome or Edge (and ideally Firefox and Safari) must tick these:

**Lesson 04 (open `demo/index.html` by double-click, and `build/tokens.html`)**
- [ ] Light theme looks as described: white page, near-black text, light grey card with a thin grey border, blue buttons with white text.
- [ ] "Dark mode" button switches to a near-black page, dark grey card, light-blue buttons with near-black text; reloading keeps the choice (also check a private window where storage may be blocked).
- [ ] With no saved choice, DevTools emulation of `prefers-color-scheme: dark` shows the dark theme; choosing light explicitly overrides it.
- [ ] No flash of the light theme when a saved "dark" choice is reloaded (the `<head>` script runs before first paint).
- [ ] Tab shows a visible 3-pixel focus ring on both buttons in both themes; `aria-pressed` is announced by a screen reader.
- [ ] `build/tokens.html` renders both tables with readable swatches in both themes, and works without inline styles; zoom to 200 percent keeps it usable.
- [ ] Forced-colors emulation (DevTools Rendering tab) keeps the buttons and text readable.
- [ ] Record Performance while toggling the theme and note the Recalculate Style entries (the lesson asks the learner to take these numbers).

**Lesson 07 (`npm run preview`)**
- [ ] Blocking button: the `Working...` text does not appear before the result, typing is delayed, and the Performance panel shows one long task (red corner marker).
- [ ] Yielding button: typing stays responsive, `Working...` shows, the profile shows many short tasks, and the checksum equals the blocking one.
- [ ] Interactions track in the Performance panel shows input delay, processing and presentation delay as described.
- [ ] Console shows `[long frame] ...` lines in Chrome or Edge and nothing harmful in Firefox or Safari (no support for the entry types is handled); `[vitals] ...` lines appear after idle.
- [ ] `npx lighthouse@13.6.0 http://localhost:4173/ --budget-path=lighthouse-budget.json --view` accepts the budget file and shows a Budgets section.
- [ ] `scheduler.yield()` exists in the tested browsers, or the `setTimeout` fallback works.
- [ ] Time-sliced exercise button behaves like the yielding button.

**Lesson 08 (`npm run serve`, then `http://127.0.0.1:8301/`)**
- [ ] Enforced mode: the four buttons behave as the table in step 7 says (names of the errors in the result box are recorded; the table says "read the name shown" for `eval`).
- [ ] `CSP_REPORT_ONLY=1`: the inline handler runs, `innerHTML` accepts the string, `eval` runs, and violations are reported in the console.
- [ ] The server console prints `csp-report ...` lines when a violation occurs (the browser accepts the relative `Reporting-Endpoints` URL).
- [ ] `/api/session` sets the `__Host-session` cookie with Secure, HttpOnly and SameSite flags on `http://127.0.0.1` in Chrome, Edge and Firefox (and note Safari's behaviour).
- [ ] The page works with no `Refused to ...` message other than the intended ones.

**Lesson 05, 06, 07, 08, 09 workflows (needs a GitHub repository, not a browser)**
- [ ] The `ci`, `contract`, `performance`, `security` and `release` workflows run, and the YAML is accepted. `dependency-review` needs the dependency graph enabled. The `release` workflow's `readiness` job fails on purpose until the sample report is replaced.

## Needs a machine run (no browser)
First run, in this order; each item is something that could not be checked by reading:
1. Lesson 01: every `Expect<Equal<>>` entry compiles (the `Equal` identity trick on mapped and recursive results); the `@ts-expect-error` lines each hide exactly one error; the emitter's single cast; `NoInfer` on `oneOf`; `out`/`in` variance tests.
2. Lesson 02: `href()` with a rest tuple derived from a conditional type; the `Match` union and the `as Match` cast; `PathParams` recursion; the printed `index.ts` output.
3. Lesson 03: `isolatedDeclarations` together with `erasableSyntaxOnly` and `override readonly name: string`; self-reference of `@code101/result-kit` from `consumer/consumer.ts`; the loose consumer configuration; `attw --pack . --profile esm-only` (flag and output); `check:surface` count of 8 (and 10 in the solution).
4. Lesson 04: the compile of the pipeline; the printed CSS block (22 shared tokens in the order shown); the contrast gate passes for the shipped colours (ratios were reasoned by hand, not printed) and fails for the exercise starter.
5. Lesson 05: `tsc --build` with TypeScript 7 and `composite` plus `nodenext`; the `node --test "packages/*/dist/*.test.js"` glob quoting on Windows PowerShell, bash and cmd; npm links `"*"` workspace dependencies; the `affected` outputs; `tsc --build --verbose` decisions in the "Run it" predictions.
6. Lesson 06: `npm install` with TypeScript 5.9.3 resolves the generator's peer range; the shape of the generated `schema.d.ts` (the lesson only shows an excerpt of the kind of output); `openapi-fetch` 0.17.0 option and middleware types (`fetch` option type, `onRequest`/`onResponse`), and whether `error` is typed for `application/problem+json`; Zod 4.6.7 `z.uuid()` accepts the demo ids and `z.iso.datetime()` accepts `...Z`; the `SchemaDriftChecks` pass; the demo output.
7. Lesson 07: `tsc --noEmit` with `types: ["vite/client"]`; `vite build` with Vite 8 produces `dist/assets` as the budget script assumes; `web-vitals` 6.2.3 still exports `onCLS`, `onINP`, `onLCP` and `Metric`; the `Budget OK` run.
8. Lesson 08: TypeScript compile (template literal `Source` types, `nonceSource` return); `print-policy` output (the long CSP line and four findings); `check-package-policy` output; Dependabot `cooldown` and `groups` keys; `dependency-review-action` `fail-on-severity` input; `npm audit signatures` in CI.
9. Lesson 09: demo output including the 50 ms timeout and the rollout counts (the 50 percent line prints `true` if the count is within 150 of 500); both `check-release` outputs and exit codes.

## Open items and honest limits
- Web 201 is written. Lesson links and "Builds on" paragraphs follow the 201 plan in `_BRIEF-201.md` (lesson numbers 01, 04, 05, 06, 07, 10, 11, 12); every 301 lesson links its 201 prerequisites by relative path. If 201 renumbers, update the front matter `prerequisites` and the relative links.
- Lesson 04 duplicates a little of 201 lesson 01 (custom properties and a theme toggle) on purpose, to start from the same vocabulary; the lesson says what is new (pipeline, per-theme contrast gate, documentation).
- Lesson 06 explains the TypeScript 7 incompatibility of `openapi-typescript` 7.13.0 from its registry metadata (`peerDependencies`) and the TypeScript 7.0 announcement; the author did not run the generator on TypeScript 7, so the statement is "declares a peer dependency on TypeScript 5 and uses the compiler API" rather than a captured error.
- Statements about browser support (Trusted Types, `scheduler.yield`, long animation frames, import map integrity) are hedged and point at MDN compatibility tables; none was tested.
- The lessons print the expected output of the commands in blocks marked "not yet run"; messages marked "typical" are not captured text.
- Hash and distribution expectations (lesson 09, 50 percent tolerance of 150) are derived from the properties of FNV-1a over `flag:user-N` strings, not from a run.
- Budget numbers in lessons 07 are placeholders, labelled as such; no performance number, bundle size or timing was measured.
- Capstone links point at existing chapters of `capstones/web-react` and `capstones/web-angular`; those capstones are themselves not run.
- `docs/LINKS.md` was not edited (outside the allowed folders). New Tier 1 URLs used in this level (MDN, web.dev, OWASP, typescriptlang.org, vite.dev, w3.org/WAI, npm docs, GitHub docs, OpenAPI, RFC 9457, openapi-ts.dev) were read or are stable documentation paths; `scripts/check_links.py` was not run, so the Link Curator should check them.
