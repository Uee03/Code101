# Web Foundations state

Last updated: 2026-11-23. Level: 101-zero-to-hero. Status: **verified** (smoke only; browser checklist remains open).

Toolchain: Windows 11 / PowerShell-compatible commands, Node 26.13.1, npm 11.20.0, TypeScript 7.0.2. Python 3.15.2 is used only for author-side temporary HTTP probes, never required of learners. Official download/setup links were checked read-only; installer screens still need human confirmation.

| Lesson | Phase | Status | Evidence |
|---|---|---|---|
| 01 How the web works + your first HTML page | 1 | verified | Aggregate source/web smoke: PASS for code and solution |
| 02 Text, links, images, lists | 1 | verified | Aggregate source/web smoke: PASS for code and solution |
| 03 Forms and semantic HTML | 1 | verified | Aggregate source/web smoke: PASS for code and solution |
| 04 CSS basics | 1 | verified | Aggregate source/web smoke: PASS for code and solution |
| 05 Box model and spacing | 2 | verified | Aggregate source/web smoke: PASS for code and solution |
| 06 Flexbox | 2 | verified | Aggregate source/web smoke: PASS for code and solution |
| 07 Grid and responsive design | 2 | verified | Aggregate source/web smoke: PASS for code and solution |
| 08 JavaScript basics | 2 | verified | Aggregate source/web smoke: PASS for code and solution |
| 09 The DOM and events | 3 | verified | Aggregate source/web smoke: PASS for code and solution |
| 10 TypeScript first steps | 3 | verified | Aggregate source/web smoke: PASS for code and solution |
| 11 TypeScript in the browser | 3 | verified | Aggregate source/web smoke: PASS for code and solution |
| 12 Project: personal landing page + todo list | 3 | verified | Aggregate source/web smoke: PASS for code and solution |

## Beginner walk-through resolution
Applied `reviews/web-101.md`: **1/1 Blocker, 23/23 Should-fix, 22/22 Nits fixed. None skipped.** The cheap nits fit into the required lesson rewrites; browser-only checks are not claimed completed.

| Lesson | Should-fix IDs resolved | Nit IDs resolved | Change |
|---|---|---|---|
| 01 | 01-1, 01-2 | 01-3, 01-4, 01-5 | Exact UI clicks, optional repository path, no maintainer blocks; same fixes propagated across the track. |
| 02 | 02-2, 02-3 | 02-4 | Blocker 02-1 fixed with complete course SVG and save path; glossary link and decorative empty alt are consistent in code/starter/solution. |
| 03 | 03-1 | 03-2 | Four form checks, query-string/%40 explanation and self-contained Live Server fallback. |
| 04 | 04-1 | 04-2, 04-3 | Per-lesson mistake tables across 04-12; default heading-size explanation; no unexplained cascade detour. |
| 05 | 05-1 | 05-2 | Viewport, content-box, parent and DevTools box diagram introduced before measured checks. |
| 06 | 06-1 | 06-2, 06-3 | Wide/medium/narrow descriptions plus taught device mode; lone-card growth explained; exercise is a goal. |
| 07 | 07-1 | 07-2 | Measured-width how-to references the identical taught steps; removed the expected-behavior-as-error row. |
| 08 | 08-1, 08-2, 08-3 | 08-4, 08-5, 08-6 | Real PowerShell policy/Node errors, honest two-sitting time, early definitions, no Console pasting, official Linux route link. |
| 09 | 09-1, 09-2 | 09-3 | Real null-listener error; browser-first click lesson without learner Node detour; ARIA explained. |
| 10 | 10-1, 10-2, 10-3, 10-4 | 10-5, 10-6 | Honest time, fresh install output, slim config explanation, npx wrong-folder warning; no discarded init or giant generated lock listing. |
| 11 | 11-1, 11-2, 11-3 | 11-4 | Detailed server/Network workflow and origin definition; captured missing-.js error; honest time; four syntax items explained; no wrong generated name. |
| 12 | 12-1, 12-2 | 12-3, 12-4, 12-5, 12-6 | Two 60-90-minute sittings, simpler explanation, null hint/error, all three render diagnostics, same-address wording, action labels and personalization goal. |

## Decisions and boundaries
- Keep all 12 lesson numbers and all three phases. Lessons 08/09/11 allow 90 minutes, lesson 10 90-120, lesson 12 120-180; all five explicitly have two sittings and a marked break. Lesson 12's longer estimate is deliberate: a full first-timer project takes 2-3 hours.
- Every lesson uses the verbatim optional source-pack sentence with its concrete repository folder. Exercises copy the completed lesson folder, or copy starter and rename it; no hidden pack prerequisite.
- ui/search is the only declared art dependency (lesson 02). Its complete CC0 SVG is in the text, code and exercises; HTML alt is now empty because it is decoration. Lesson 12 toggle labels say Mark <task> as done/not done and retain Done/Undo for visible-label matching.
- Source listings were copied from source files, not retyped. 74 full listings were compared with their code/starter/solution counterparts and matched. Generated package-lock.json is retained in source packs but omitted from lesson prose using skip_lesson_check. Identical tsconfig.json in lessons 11/12 is copied explicitly from lesson 10 Step 5, with no changed settings, and likewise exempted from duplicate text checks.
- Removed all learner-facing verifier/build commands and captured maintainer transcripts. HTTP probes still assert status/title (and JSON shape in lesson 11) but no longer print maintainer status messages into the lessons. One initial 11/12 result was a leftover JSON-output text expectation, corrected once; no runtime blocker remained.
- Captured real errors by changing disposable copies: wrong folder Cannot find module; reassigned const; missing closing JS brace; null addEventListener result; TS2322; missing .js import (compile exit 0, Node ERR_MODULE_NOT_FOUND); Clear all TS18047 at (80,3); all three render TS18047 diagnostics. Browser error prefixes are not claimed captured: the lesson 09 text explicitly identifies its Node reproduction.
- Captured the actual npm.ps1 policy error in a child PowerShell with Restricted policy, and node-not-recognized with that child process's PATH empty. No persistent execution-policy/PATH changes. npx --no-install tsc outside a project reproduced the missing tsc@2.0.4-package error without installing it. Learners are told to answer n to download prompts.
- Lessons 01 and 12 were reconstructed from their literal markdown file listings in clean folders, not copied from code. Lesson 12 used the lesson 10 config as instructed, installed locally, compiled silently, printed 0 tasks, and served HTML/CSS/generated JS with HTTP 200. This is a text-to-folder smoke walkthrough, not a GUI/browser simulation.
- No test suites, linters, browser automation, global tools, certificates or persistent servers. Temporary folders are deleted. Only tutorials/web and source/web are authored; the explicitly requested builder generates ignored dist/packs archives. No commits. Decisions needed: none.

## Smoke evidence
Command: `python scripts/verify_labs.py source/web/`.

Captured aggregate output:
```text
[PASS      ] source/web/101-zero-to-hero/phase-1-html-and-css/01-first-html-page
[PASS      ] source/web/101-zero-to-hero/phase-1-html-and-css/02-text-links-images-lists
[PASS      ] source/web/101-zero-to-hero/phase-1-html-and-css/03-forms-and-semantic-html
[PASS      ] source/web/101-zero-to-hero/phase-1-html-and-css/04-css-basics
[PASS      ] source/web/101-zero-to-hero/phase-2-layout-and-javascript/05-box-model-and-spacing
[PASS      ] source/web/101-zero-to-hero/phase-2-layout-and-javascript/06-flexbox
[PASS      ] source/web/101-zero-to-hero/phase-2-layout-and-javascript/07-grid-and-responsive-design
[PASS      ] source/web/101-zero-to-hero/phase-2-layout-and-javascript/08-javascript-basics
[PASS      ] source/web/101-zero-to-hero/phase-3-typescript-and-project/09-dom-and-events
[PASS      ] source/web/101-zero-to-hero/phase-3-typescript-and-project/10-typescript-first-steps
[PASS      ] source/web/101-zero-to-hero/phase-3-typescript-and-project/11-typescript-in-the-browser
[PASS      ] source/web/101-zero-to-hero/phase-3-typescript-and-project/12-personal-page-and-todos

12 passed, 0 failed, 0 unverified (missing tools)
```

## Packaging
Ran `python scripts/build_packs.py web-101` after the final 12/12 smoke PASS. Captured builder output:
```text
built web-101-phase-1-html-and-css.zip (23 files)
built web-101-phase-2-layout-and-javascript.zip (29 files)
built web-101-phase-3-typescript-and-project.zip (62 files)
built web-101-all.zip (3 phases)
```

All four archives passed ZIP integrity, lesson-count, generated-output exclusion and under-25-MB checks. Lesson 02 is the only art declaration. Its `assets/icons/ui/search.svg` plus code/starter/solution copies are byte-identical to assets/art in both phase 1 and all archives, with the CC0 license present. Other lessons declare no art.

| Archive | Bytes | Lessons |
|---|---|---|
| web-101-all.zip | 86834 | 12 |
| web-101-phase-1-html-and-css.zip | 14072 | 4 |
| web-101-phase-2-layout-and-javascript.zip | 16173 | 4 |
| web-101-phase-3-typescript-and-project.zip | 54777 | 4 |

## Needs a human with a browser
Original review checklist retained below. For the revised lesson 02, verify the icon is skipped with `alt=""` rather than announced as Search; lesson 08 no longer requests Console pasting, so do not type allow pasting or bypass browser protection. These are manual checks, not smoke PASS claims.

- [ ] Every "Expected browser result": tab title text, heading sizes, colours (pale blue-grey background, blue/green paragraphs in 04), card width and centring (05), flex wrap at about 1000/500/350px (06), grid 1 to 3 columns at 700px (07).
- [ ] That the 24px search icon is visible and black on Edge, Chrome and Firefox (lesson 02), and what a screen reader says for `alt="Search"`.
- [ ] Lesson 03 form behaviour over `file:///`: Tab order, clicking a label focuses the input, validation messages, GET submission and the query string, and the Live Server fallback.
- [ ] Lesson 08 Console output (six lines) and Chrome/Edge "allow pasting" behaviour; lesson 09 click counter, keyboard Space/Enter, `aria-live` announcement.
- [ ] Lesson 11: that double-clicking `index.html` really stays on "Loading profile..." (and the console message that appears), Live Server install and the Port label, DevTools Network list, and the rename-the-JSON failure path.
- [ ] Lesson 12: add, done/undo, remove, reload persistence, spaces-only entry, Clear all, focus outline, 700px layout, and storage-blocked messages (private mode).
- [ ] Whether Windows 10/11 "Open with" shows Edge/Chrome/Firefox as the lesson says, and the VS Code and Node installer screens (read-only here).
