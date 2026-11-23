# Shared writing brief for Code101 authors (read first)

> **LATEST USER RULE (overrides everything below that mentions checks):** do NOT run ANY checks or tests of any kind: no `verify_labs.py` (not even `--static`), no `build_packs.py`,
> no builds, no linters, no Mermaid parsing. Only read files, look things up in official docs, and write files. Do NOT write unit tests for Angular, React, Flutter or Kotlin lessons
> (101 and 201): no Karma/Jasmine/Vitest/Jest/flutter_test/JUnit lessons or exercises. Still write a `verify.json` per lesson (so it can be run later) and put the draft notice under each H1.
> Because nothing is checked, make every lesson show every code line itself and copy code from the source file into the lesson text exactly.

The repository owner has explicitly instructed: **"Dont run smoke tests. Just Create the lessons make sure they are following the best learning outcomes and best practices.
Create the Source Code for them."** So authors WRITE lessons and source code WITHOUT executing the code. This is documented in
`.github/skills/authoring-tutorials/reference/lessons-learned.md` (section "Verification policy").

## Allowed and forbidden
- Forbidden: running the lesson code, compilers, package managers, servers, Docker, emulators, Ollama or any lab.
- Allowed: reading files, official-docs lookups on the web, creating/editing files in your own folders, and exactly two commands:
  `python scripts\verify_labs.py --static <filter>` (executes nothing: compares lesson text with code files) and
  `python scripts\build_packs.py <filter>` (zips files into `dist\packs\`, an allowed exception to "only edit under ...").
- Write carefully: conventional code, APIs and package versions checked in official docs / package registries, expected output derived by reading the code,
  never invented output or error text (Common mistakes: say "typical message" when not exact). Model or browser appearance: describe, never claim you saw it.
- Every lesson carries, verbatim directly under the H1, the draft notice from lessons-learned.md, and front matter `verified: not yet run`.
  Status in `_STATE` files is `written (not run)`.

## Read once before writing
1. `.github/skills/authoring-tutorials/SKILL.md` and `reference/lesson-template.md` (structure: outcomes, recap, predict-before-run, 3-rung exercise, going further, summary)
   and `reference/lessons-learned.md` (rules 1-27 + verification policy).
2. `.github/skills/source-packs/SKILL.md`, `docs/CURRICULUM.md` (your track's rows), the track's existing `tutorials/<track>/_BRIEF.md`, `_STATE.md`, `GLOSSARY.md` if present.
3. One finished lesson of a similar track as style model (e.g. `tutorials/python/101-zero-to-hero/phase-3-real-programs/` with its `source/` folder and `verify.json`).
4. For stack conventions: the skills under `F:\Projects\Git\Claude\AgenticAssisstance\templates\<stack>\.github\skills\` when named in your task.

## Level voices
- 101: analogy first, plain words, every term defined, tiny steps, setup explained, honest first-timer times.
- 201: assume 101; explain the why; "Why this, not that" boxes; tests with features; Mermaid diagrams for structure; link to the capstone chapter where the topic is used in a real app.
- 301: assume 201; trade-offs, failure modes, "when not to use this", measurements to take (never invented numbers), production checklists, ADR-style decisions, security and operations.

## Layout and files (see the source-packs skill)
- Lesson text: `tutorials/<track>/<level-folder>/phase-N-slug/NN-slug.md` (numbering restarts at 01 per level).
  Level folders: `101-zero-to-hero`, `201-hero-to-super-hero`, `301-super-hero-to-legendary`.
- Source: `source/<track>/<level-folder>/phase-N-slug/NN-slug/{code,exercise/starter,exercise/solution,verify.json}` + `PACK-README.md` per phase.
  Every file the lesson uses is shown in full in the lesson (the static check enforces it); put generated or very large files in `skip_lesson_check` and say so in the lesson.
  Lockfiles (package-lock.json, Cargo.lock, go.sum, pubspec.lock) cannot be created without running tools: do not include them and say which command creates them.
- Show every configuration (Docker, compose, .env.example (never .env), config files) in full with line-by-line explanation.
- Tracking files for a NEW level of an existing track: create `_BRIEF-<level>.md` and `_STATE-<level>.md` and append new terms to `GLOSSARY.md`; for a NEW track create `_BRIEF.md`,
  `_STATE.md`, `GLOSSARY.md` (you own them). Do not edit other tracks, `CONTEXT.md`, `docs/`, `.github/`, `scripts/`, `reviews/`.
- UTF-8 without BOM. Icons only from `assets/art` via front matter `assets: [category/name]`.
- Security by default, accessibility for web/mobile/UI, Unity local only (never Docker), Docker temporary.

## Finish
Run the static check for your filter until it reports 0 failures, then `build_packs` for your filter. Final reply at most 6 lines: lessons written, static result, anything uncertain.
If you decline, reply with ONE line quoting the exact rule that forbids it.
