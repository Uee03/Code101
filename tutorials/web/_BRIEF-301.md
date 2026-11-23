# Web Foundations 301 - Super Hero to Legendary

## Audience and outcome
Developers who finished Web 201 (see `_BRIEF-201.md`: modern CSS and tokens, TypeScript in depth, modules and Vite, fetching, state, forms and accessibility, security basics, Core Web Vitals, testing and a shipped task board) and have built or read one of the web capstones (`capstones/web-angular`, `capstones/web-react`). Outcome: design and operate the web layer of a product at scale: type-level APIs, design systems and build systems, contract-driven clients, measured performance, defence in depth, and releases that can be undone. Voice 301: trade-offs, failure modes, "when not to use this", production checklists, ADR-style decisions, measurements to take (never invented numbers). Lessons are 120 to 180 minutes; each has Recap, a predict-before-run step, a three-rung exercise (guided, change, stretch), Check yourself, Common mistakes and a production checklist.

## Plan (9 lessons, three downloadable phases)
| Phase | Lesson | Outcome | Builds on (Web 201) |
|---|---|---|---|
| 1 type-level-typescript | 01 Advanced generics, conditional and mapped types | Mapped, conditional, recursive types; distribution; variance; `Expect<Equal<>>` and negative type tests; typed emitter | 04, 05 |
| 1 | 02 Template literal types, type-safe routing and exhaustive checks | Route table with typed `href()` and `matchRoute()`; strict vs tolerant exhaustiveness; type/runtime drift | 04 |
| 1 | 03 Library-quality TypeScript | `exports` map, `isolatedDeclarations`, strictness flags and who pays, consumer test (strict and loose), API surface snapshot, `attw`, breaking-change table | 06 |
| 2 systems | 04 Design systems and design tokens | Three token tiers; JSON to CSS, TypeScript names and docs; per-theme contrast gate; themes without flash; build vs buy ADR | 01 |
| 2 | 05 Monorepos and build tooling | npm workspaces, project references, affected script, CI (build once, test output), cache failure modes | 06 |
| 2 | 06 API clients generated from OpenAPI | `openapi-typescript` + `openapi-fetch`, Zod validation drift-checked at compile time, four-way result, versioning, ETag and `If-Match` | 05, 07 |
| 3 production-web | 07 Performance budgets and browser internals | Rendering pipeline, long tasks, yielding, INP anatomy, size budgets in CI, Lighthouse budget, lab vs field | 06, 11 |
| 3 | 08 Security hardening | Strict CSP (nonce, `strict-dynamic`), lint, report-only rollout, Trusted Types, token storage ADR, `__Host-` cookies, supply chain (`.npmrc`, SHA-pinned actions, Dependabot cooldown) | 10 |
| 3 | 09 Micro-frontends, release strategy and a production readiness checklist | Remote loader with contract and timeout, sticky rollout and kill switch, readiness checker, human checklist, release workflow, PR review exercise | 12 |

Security, identity and API craft stay inside the capstones; this level adds the browser-side depth (CSP, Trusted Types, token handling, supply chain) and links to the capstone chapters instead of repeating them.

## Versions and evidence (checked 2026-11-23, registry and official pages read; nothing installed or run)
| Item | Pin | Evidence |
|---|---|---|
| Node / npm | 26.13.1 / 11.20.0 | Same as Web 101 and 201 |
| TypeScript | **7.0.2** in lessons 01 to 05 and 07 to 09; **5.9.3 in lesson 06** | npm `typescript@latest` = 7.0.2. The TypeScript 7.0 announcement (devblogs.microsoft.com) lists the new defaults used in the tsconfigs (`rootDir` and `types` explicit), removed options, `--checkers`/`--builders`/`--singleThreaded`, and that 7.0 has **no programmatic API**. `openapi-typescript@7.13.0` has `peerDependencies: { typescript: "^5.x" }` and uses the compiler API, so lesson 06 pins 5.9.3 (the React capstone also pins 5.9.3) |
| @types/node | 26.6.6 | npm latest |
| Vite | 8.3.8 | npm latest (also pinned in `capstones/web-react`) |
| web-vitals | 6.2.3 | npm latest; README read for `onINP`, `onLCP`, `onCLS`, `Metric` |
| openapi-typescript / openapi-fetch | 7.13.0 / 0.17.0 | npm latest; openapi-ts.dev API page read for `createClient`, `fetch`, middleware |
| zod | 4.6.7 | npm latest (Zod 4 top-level `z.uuid()`, `z.iso.date()`, `z.iso.datetime()`) |
| @arethetypeswrong/cli | 0.18.5 | npm latest |
| Lighthouse | 13.6.0 (via `npx`, not installed) | npm latest |
| GitHub Actions | checkout v7.0.1, setup-node v7.1.0, upload-artifact v7.0.2, download-artifact v8.0.2, cache v6.1.0 (named, not used), dependency-review-action v5.0.1 | Release pages read; lesson 08 and 09 pin the first, second, third and last by commit SHA (SHAs read from the GitHub API on 2026-11-23) |
| Trusted Types | Baseline 2026 (newly available since February 2026) | MDN Trusted Types API page |
| npm workspaces | npm 11 docs read | docs.npmjs.com/cli/v11/using-npm/workspaces |

Style Dictionary 5.8.0 and Module Federation are **named** as alternatives in ADR tables; no code or configuration for them is shown, so nothing about them is unverified.

## Teaching references (Tier 1)
typescriptlang.org (handbook: conditional, mapped, template literal types; modules reference; TSConfig reference), the TypeScript team blog (7.0 announcement), developer.mozilla.org (CSP, Trusted Types, custom properties, `PerformanceObserver`, ETag, If-Match, import maps, custom elements), web.dev (INP, optimize long tasks, performance budgets, strict CSP, critical path), vite.dev, w3.org/WAI (WCAG 2.2 contrast and non-text contrast), owasp.org (CSP and DOM-based XSS cheat sheets, Top 10), docs.npmjs.com (workspaces), docs.github.com (Actions security hardening, environments), openapi-ts.dev, spec.openapis.org, rfc-editor.org (RFC 9457). Each Best practice callout ends with a source link.

## Delivery conventions
- `tutorials/web/301-super-hero-to-legendary/phase-N-slug/NN-slug.md` plus `source/web/301-super-hero-to-legendary/phase-N-slug/NN-slug/{code, exercise/starter, exercise/solution, verify.json}` and a `PACK-README.md` per phase. Numbering restarts at 01.
- Exercises use **overlay files**: `exercise/starter` and `exercise/solution` contain only the files the exercise changes; the learner copies their finished lesson folder first (each PACK-README says so). Lesson 09's exercise is a pull request review (documents and data).
- `verify.json` for every lesson: install, type-check or build, run with `expect_stdout` derived from the code, then an overlay of the solution. They use `python` only to copy folders. They have **not** been run.
- No lockfiles; every lesson says `npm install` creates `package-lock.json` and that your repository should commit it (workflows use `npm ci`). Lesson 06's generated `src/api/schema.d.ts` is not shipped; the lesson shows the kind of output to expect and says which command creates it.
- Every file in `code/` is shown in full in the lesson (checked by `verify_labs.py --static`). Hidden files (`.npmrc`, `.gitignore`, workflows, `dependabot.yml`) are shown too; the static check does not cover them, so they were pasted by hand and re-read.
- Every lesson carries the mandatory "Draft: written but not yet run" notice directly under the H1 and `verified: not yet run`. No art assets (`assets: []`).
- Lessons that name Web 201 lessons link to them by relative path; `_BRIEF-201.md` is the source for what 201 covers.

## Decisions recorded while writing
- **Own token pipeline, not Style Dictionary** (lesson 04): zero runtime dependency, about 250 lines, deterministic output the lesson can print in full. The ADR table says when to switch.
- **Lesson 06 pins TypeScript 5.9.3** and explains why (tool pins the compiler). The alternative (alias to the TypeScript 6 compatibility package plus an npm `overrides` entry) is described, not shown, because it could not be checked without installing.
- **`exactOptionalPropertyTypes` is off in lesson 06 only**, with the reason (Zod writes `?: T | undefined`; the generator writes `?: T`).
- **Size budgets fail CI; timing budgets are recorded** (lesson 07). Budget numbers in `budgets.json` and `lighthouse-budget.json` are labelled illustrative starting limits; timing thresholds are the published "good" thresholds. No measured numbers appear anywhere; each measurement step gives a table for the learner to fill in.
- **Lesson 08 pins actions by SHA**; lessons 05 to 07 use tags on purpose (taught as the first step, upgraded in 08) and say so.
- **Lesson 09 workflows are outlines**: deployment steps print a message; the sample report fails on purpose.
- Placeholders such as `example.test`, `cdn.example.com` and `boards.example.test` are reserved or documentation domains; no real service is contacted.

## Delivery and verification boundaries (user instruction, 2026-11-23)
Nothing was executed: no compile, install, build, dev server, test run, browser, Lighthouse or Docker. Only these commands were run: `python scripts/verify_labs.py --static web/301` (lesson text contains every code line and expected output; `verify.json` parses) and `python scripts/build_packs.py web-301` (zips). Expected outputs were derived by reading the code or are labelled "typical". Browser appearance and behaviour are described from the CSS and code, never claimed seen. Measurements: each lesson says how to take them (DevTools Performance panel, Lighthouse, `--extendedDiagnostics`) and never states a result.
