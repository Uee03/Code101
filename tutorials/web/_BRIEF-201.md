# Web Foundations 201 - Hero to Super Hero

## Audience and outcome
Learners who finished Web 101 (HTML, CSS, JavaScript and TypeScript basics, the personal page and todo list) and have 1 to 2 years of experience. Outcome: build, test and ship a small typed, accessible web app without a framework, and understand what frameworks later automate. Voice: assume 101, explain the why, "Why this, not that" tables, Mermaid diagrams, one prediction step per lesson, a three-rung exercise (guided, change, stretch) and a Recap and Check yourself that map to the lesson outcomes. Lessons are 45 to 70 minutes; project lesson 12 is about 150 minutes in two sittings.

## Plan (12 lessons, four downloadable phases)
| Phase | Lesson | Outcome |
|---|---|---|
| 1 modern-css | 01 Custom properties and theming | Tokens, `color-scheme`, `light-dark()`, a saved light and dark toggle, a per-component override |
| 1 | 02 Modern layout | Container queries, `clamp()` with zoom-safe sizes, logical properties and right-to-left |
| 1 | 03 CSS architecture and animation | `@layer`, BEM, transitions and keyframes, `prefers-reduced-motion` from one token |
| 2 typescript-in-depth | 04 Unions, narrowing and utility types | Discriminated unions, `assertNever`, type guards, `Partial`, `Pick`, `Omit`, `Record`, `Extract`, `satisfies` |
| 2 | 05 Generics and type-safe API clients | Constraints, `keyof`, `Endpoint<T>`, `Result<T>`, validating parsers, injected fetch |
| 2 | 06 Modules, Vite and the dev workflow | Hand-written Vite and TypeScript project, complete `vite.config.ts`, env vars, dynamic import, build and preview |
| 3 app-patterns | 07 Fetching data | `fetch`, `AbortController`, timeout, load states as a union, stale-response guard |
| 3 | 08 State and events without a framework | Reducer, generic store, delegation, typed custom events, focus after re-render |
| 3 | 09 Forms and accessibility | Labels, hints, errors, validity API, error summary, focus, keyboard test, ARIA only when needed |
| 4 quality-and-ship | 10 Web security basics | XSS and safe DOM APIs, URL allow-list, CSP header, CORS and preflight demo |
| 4 | 11 Performance and Core Web Vitals | LCP, INP, CLS measurement, image dimensions, lazy loading, code splitting, Lighthouse |
| 4 | 12 Testing with Vitest and the task board | 21 tests, typed accessible task board, production build, multi-stage Docker image served by nginx |

Capstones `web-angular` and `web-react` are linked as the next step and are not duplicated.

## Versions and evidence (checked 2026-11-23)
npm registry latest at writing: **TypeScript 7.0.2**, **Vite 8.3.8** (Node 20.19+ or 22.12+), **Vitest 5.1.1** (Node 22.12+, Vite 6.4+), **jsdom 31.0.1**, **@types/node 26.6.6**, create-vite 9.3.4 (named once as an optional comparison). Docker Hub tags confirmed to exist: `node:26.13.1-alpine`, `nginxinc/nginx-unprivileged:1.30-alpine`. Node target 26.13.1 and npm 11.20.0 as in Web 101; manifests state `>=22.12.0`. Official pages read for the APIs used: Vite guide, build options, env and modes, preview options; Vitest guide, config, environments. All 62 URLs in the lessons returned HTTP 200 on 2026-11-23.

## Teaching references (Tier 1)
MDN (custom properties, `light-dark()`, container queries, `@layer`, `prefers-reduced-motion`, Fetch, AbortController, constraint validation, CORS, CSP, PerformanceObserver), web.dev (Learn CSS, Core Web Vitals, CSP), typescriptlang.org (handbook: narrowing, generics, utility types; tsconfig), vite.dev, vitest.dev, W3C WAI (WCAG 2.2, forms tutorials, ARIA practices), OWASP XSS cheat sheet, Docker docs (multi-stage builds). Each Best practice callout ends with a source link.

## Delivery conventions
- `tutorials/web/201-hero-to-super-hero/phase-N-slug/NN-slug.md` plus `source/web/201-hero-to-super-hero/phase-N-slug/NN-slug/{code, exercise/starter, exercise/solution, verify.json}` and a `PACK-README.md` per phase. Numbering restarts at 01.
- Exercises 01 to 03 (static CSS) and 04 to 12 use **overlay files**: `exercise/starter` and `exercise/solution` contain only the files the exercise changes, and the learner copies their finished lesson folder first. This keeps each pack small; each PACK-README explains it.
- Boilerplate shared by the Vite lessons (`tsconfig.json`, `vite.config.ts`, `.gitignore`, `src/dom.ts`) is shown once in lesson 06 and repeated in the other `code/` folders; lessons 07 to 11 say it is identical and `verify.json` lists those files in `skip_lesson_check`. Lesson 12 shows every file.
- No `package-lock.json` in packs; lessons say `npm install` creates it (lesson 12's Dockerfile uses `npm ci`, so it says to keep it).
- Art only from `assets/art` (CC0), declared in front matter: lesson 01 `weather/sun`, `weather/moon`; lesson 07 `ui/alert-triangle`; lesson 12 `ui/plus`. Icons are shown as inline SVG text.
- Every lesson carries the mandatory "Draft: written but not yet run" notice directly under the H1 and `verified: not yet run`.

## Verification boundaries (user instruction, 2026-11-23)
Nothing was executed: no compile, install, build, dev server, test run, browser or Docker. Only `python scripts/verify_labs.py --static source/web/201-hero-to-super-hero` (lesson text contains every code line and expected output; verify.json parses) and `python scripts/build_packs.py web-201` were run. Expected outputs were derived by reading the code (lessons 04 and 05) or are labelled "typical output" (Vite, Vitest, Docker, TypeScript diagnostics). Browser appearance is described from the CSS and code, never claimed seen.
