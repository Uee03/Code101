# Web Foundations 201 state

Last updated: 2026-11-23. Level: 201-hero-to-super-hero. Status: **written (not run)**. Static check clean: `python scripts/verify_labs.py --static source/web/201-hero-to-super-hero` reports 12 static-checked, 0 failed.

Policy: the repository owner instructed "Dont run smoke tests. Just create the lessons ... Create the source code for them." Nothing below was executed: no `npm install`, `tsc`, `vite`, `vitest`, browser, Node server or Docker command. See `.github/skills/authoring-tutorials/reference/lessons-learned.md`, "Verification policy". Each lesson carries the mandatory notice and `verified: not yet run`; the notice is removed only by a verifier run.

| Lesson | Phase | Status | Evidence |
|---|---|---|---|
| 01 Custom properties and theming | 1 | written (not run) | Static check clean; 3 code files, overlay `exercise.css` |
| 02 Modern layout | 1 | written (not run) | Static check clean; 2 code files, overlay `exercise.css` |
| 03 CSS architecture and animation | 1 | written (not run) | Static check clean; 3 code files, overlay `exercise.css` |
| 04 Unions, narrowing and utility types | 2 | written (not run) | Static check clean; 14 expected output lines derived by reading the code |
| 05 Generics and typed API clients | 2 | written (not run) | Static check clean; 8 expected output lines derived by reading the code |
| 06 Modules, Vite and the dev workflow | 2 | written (not run) | Static check clean; 13 code files |
| 07 Fetching data | 3 | written (not run) | Static check clean; 6 scenarios described from code |
| 08 State and events without a framework | 3 | written (not run) | Static check clean |
| 09 Forms and accessibility | 3 | written (not run) | Static check clean |
| 10 Web security basics | 4 | written (not run) | Static check clean; includes `server/cors-server.mjs` |
| 11 Performance and Core Web Vitals | 4 | written (not run) | Static check clean |
| 12 Testing and the task board project | 4 | written (not run) | Static check clean; 21 tests counted by reading (6 + 3 + 7 + 5), 25 with the exercise solution |

## Packaging
Ran `python scripts/build_packs.py web-201` (the allowed exception). Result:
```text
built web-201-phase-1-modern-css.zip (19 files)
built web-201-phase-2-typescript-in-depth.zip (40 files)
built web-201-phase-3-app-patterns.zip (46 files)
built web-201-phase-4-quality-and-ship.zip (56 files)
built web-201-all.zip (4 phases)
```
Archive integrity was read with Python's `zipfile` (all pass; the all-archive is about 117 KB). Art copied: lesson 01 sun and moon, lesson 07 alert-triangle, lesson 12 plus, each with `LICENSE-ICONS-CC0.txt`. All 62 external URLs in the lessons returned HTTP 200 (read-only check).

## Decisions
- **Versions** are the npm registry latest on 2026-11-23, pinned exactly: TypeScript 7.0.2, Vite 8.3.8, Vitest 5.1.1, jsdom 31.0.1, @types/node 26.6.6. Manifests say `node >=22.12.0`; Docker uses `node:26.13.1-alpine` and `nginxinc/nginx-unprivileged:1.30-alpine` (tags confirmed to exist).
- **Overlay exercises.** Starters and solutions contain only changed files; PACK-READMEs explain how to apply them. Rung 2 and 3 are text in several lessons; verify.json copies `code/` and overlays `exercise/solution` before checking.
- **No scaffolder in the main path.** Lesson 06 writes the Vite project by hand (a pinned `npm create vite@9.3.4 ... --no-interactive` comparison is mentioned once in Going further), because the generated template contents cannot be checked without running it.
- **CSS features** used and named as current-browser features: `light-dark()`, container queries, `@layer`, `color-mix()`, `text-wrap: balance`, `AbortSignal.any()`, `PerformanceObserver` entry types. Fallback text is shown where a browser may not support an entry type.
- **Security demo is deliberate**: `unsafe-demo.ts` uses `innerHTML` with a benign `alert` payload, labelled DEMONSTRATION ONLY, next to the safe renderer; the lesson explains the CSP blocks it on the built site.
- **No `package-lock.json`** in packs; lesson 12 tells learners to keep the one `npm install` creates, since its Dockerfile uses `npm ci`.
- **Boundaries.** Only `tutorials/web/` and `source/web/201-hero-to-super-hero/` were created or edited; `dist/packs` zips come from the allowed builder. CONTEXT.md and the top-level curriculum files were not touched; update them when a human verifies.

## Risks to check on the first real run (assumptions made from documentation, not from execution)
- TypeScript 7.0.2 with `moduleResolution: "Bundler"`, `verbatimModuleSyntax`, `types: ["vite/client"]` and `noUnusedLocals`: confirm `npx tsc --noEmit` is clean in lessons 06 to 12 and `npx tsc` emits in 04 and 05 (exhaustive `switch` without `default`, `let response` assigned in `try`, narrowing through `tasks.every(isTask)`).
- `vite build` output of Vite 8: the lessons describe it only as a typical file table; confirm the dynamic `import()` creates a second chunk in 06, 11 and that `dist/api/tasks.json` exists in 07.
- Vitest 5 summary format: the lesson shows `Test Files  4 passed (4)` and `Tests  21 passed (21)`; confirm the exact text, and that `// @vitest-environment jsdom` still works at the top of `mount.test.ts`.
- `defineConfig` from `vitest/config` accepting `server`, `preview`, `build` and `test` together (lesson 12).
- The `preview.headers` CSP in lesson 10 does not block the built page's own assets (Vite 8 may inject something inline); if it does, relax or add a hash and update the lesson.
- nginx: `expires -1` plus inherited `add_header`, and gzip of `text/javascript`; confirm with `curl.exe -I`.
- `docker build` with `npm test` inside the image on alpine (jsdom).

## Needs a human with a browser
Original checklist for this level. Nothing here was seen by the author.
- [ ] 01: light and dark colours from the system setting; toggle flips colours, swaps sun and moon, survives reload (also when the page is opened from disk); no flash on reload; the warning card's accent and padding differ from the others; text and focus colours meet contrast (check with the DevTools contrast tool).
- [ ] 02: the left card shows the picture beside the text and the right card stacks at about 1200 px; both side by side at about 600 px; both stacked at about 400 px; zoom to 200 percent keeps heading and gaps growing; the Arabic note mirrors (bar and tag swap sides) and the Arabic text renders correctly.
- [ ] 03: layer demo (moving `.u-full-width`), toast slide and fade, hover lift, Dismiss returns focus, the "motion setting" line and the reduced-motion behaviour (system setting and DevTools emulation).
- [ ] 06: dev server banner and URL, `.env` title after restart, HMR on saving `notes.ts`, Mode `development` vs `production`, second JavaScript file in Network after "Load details".
- [ ] 07: all six scenarios, Cancel, double click on Slow (one result), Offline throttling with the Normal scenario, screen reader announcements of status and alert, the warning icon.
- [ ] 08: initial list and summary, add, toggle with Space (focus stays), filters (pressed state), remove (focus to input), activity log entries.
- [ ] 09: empty submit (summary, three entries, focus on summary), link jumps focus to field, live messages while typing, spaces-only title, past date, saved sentence, keyboard-only pass, NVDA or VoiceOver reading of labels, hints, errors and the summary, 200 percent zoom.
- [ ] 10: attack sample on the dev server (alert appears in unsafe list only), on the preview server (no alert, CSP message in the Console, response headers visible), CORS lines `/allowed`, `/blocked`, `/preflight` and the OPTIONS plus POST pair in Network; `localhost` vs `127.0.0.1` behaviour.
- [ ] 11: LCP, CLS and slowest-interaction readouts in Chrome or Edge (and what Firefox and Safari show), slow vs fast click, banner A vs B, lazy images in Network, Lighthouse run steps and panel names for the current Chrome.
- [ ] 12: manual board check table in Step 15 (including focus after moving to Done), persistence across reload, the build and preview, `npm test` summary, Docker build, `docker ps` health status, `curl.exe -I` headers (including hashed asset caching and gzip), `docker logs`.
- [ ] Windows: `npm.ps1` error text for the PowerShell execution policy is quoted from Web 101's captured text; confirm it still matches.
