# Implementation notes and contract feedback

Approved design: TDD.md. All edits for this task remain under capstones/web-react; pack builder output is its requested dist/packs delivery.

## Historical local smoke evidence (before instruction change)
captures/ contains real build, stack/status/log/cleanup, generated-client smoke, intentional exercise-error and shipping-header output.
The authored chapters copy source files, not handwritten approximations. All 26 intended consumer operations are present (all contract operations except listUsers).
Only the Python final backend was used here; interchangeability with the other backends is contract-based, not a claim that four integration runs occurred.

## Deliberate implementation choices / disclosures
- Five full-app packs; focused pure-function exercise starters/solutions, not five redundant whole-app exercise copies.
- To make standalone packs runnable, backend/ is a verbatim copy of the Python final phase, not a reference requiring another unzip.
- skip_lesson_check lists generated lock/schema, immutable copied platform contract, upstream backend source/data/realm and copied CC0 icon/licence files. All authored application files and the actual backend Docker/Compose/environment configurations are shown in full in every chapter.
- Every route, including Login, is lazy; this is stricter than the design's minimum of lazy loading everything except Login.
- A failed transport conservatively marks connectivity offline; Try again restores onlineManager from navigator.onLine before refetch. This is not a claim that a network interface proves API health.
- Validation field messages are collected into the focused summary and associated by aria-describedby, rather than one message span per field.
- Strings are English in their owning UI modules; a central translation catalogue is not introduced. This differs from the TDD's one-place strings aspiration; i18n is explicitly out of scope.
- A bad cursor remains a visible 400 with a recovery path (reset filters/URL or reload); automatic cache-reset of expired cursor chains is not implemented. Do not silently drop a malformed cursor.
- Task edits preserve changed fields and the draft baseline; project archive/name edits read an ETag immediately before sending. Conflict dialog is task-specific as specified.
- tasks:admin step-up also protects team DELETE, not only Audit. After redirect, confirm the deletion again; destructive actions are never automatically resumed.

## Contract feedback (platform files untouched)
No new blocking defect found. Follow platform TDD 12.1 Decision for unlisted errors, tasks-only conditional reads, header casing and replayed JSON ordering.
openapi-typescript 7.13.0 treats defaulted description fields as required generated inputs; app/create smoke sends description explicitly. This is generator behaviour, not a platform change.
The web TDD's 8201 smoke origin cannot authenticate by design; sign-in needs localhost:5173 (stop Vite first). No request to weaken realm/CORS policy.

## Open manual acceptance
Every browser requirement remains human-checklist verification, not an automated PASS: W-07/09/11/12 UI behaviour, screen flows, optimistic visual timing/rollback/conflict choice, offline timing, WCAG key criteria, production auth.
Current delivery is written (not run); runtime verification is deferred, not blocked by a missing toolchain. No production deployment or dependency-audit result is claimed; run npm audit --omit=dev and review advisories before shipping.

## No-execution update
All five front-matter verification values are now not yet run; every state row is written (not run). The repeated verifier process was stopped. No new builds, smoke tests, servers or Docker startup are performed after this instruction. Historical captures remain labelled; verify.json is retained for later authorized use. Packaging and --static text comparison are allowed.
