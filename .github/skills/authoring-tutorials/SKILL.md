---
name: authoring-tutorials
description: 'Writes one Code101 lesson (101 Zero to Hero, 201 Hero to Super Hero, 301 Super Hero to Legendary) with every step shown, runnable source code in a phased source pack, and a verify.json. Use when creating or rewriting a tutorial lesson, a capstone chapter, or when the user says new lesson, write the tutorial, or add a lesson to a track.'
---

# Authoring tutorials

**Best model:** Act tier (GPT-6.1 Sol) via the Tutorial Author.

One lesson = one idea, 15 to 25 minutes, one runnable example, one exercise with a solution.

## Before writing (token discipline)

1. Read `CONTEXT.md`, then `tutorials/<track>/_BRIEF.md` and `_STATE.md`. Do not load `docs/LINKS.md`.
2. Read the previous lesson's *Next lesson* section and the track `GLOSSARY.md` so terms stay consistent.
3. Use only the Tier 1 and 2 links named in the brief. Confirm version-specific facts against the official docs.

## The "show all steps" rule (non-negotiable)

- Show every step a learner must do, in order: create folder, create file, full file content, command
  to run, the **expected output**, what each part means.
- Show every file **in full** the first time it appears. When a later step changes a file, show the
  whole changed region with 3 lines of context, or the whole file if under 40 lines. Never write
  "add the rest yourself" or "as before" for code.
- "Refer to previous steps" is allowed **only** when the steps are genuinely identical (for example
  a second Angular component made the same way). Then say exactly which steps repeat and list the
  concrete differences (file names, class names, one changed line). If more than a small part differs,
  write the steps out.
- Every command states the folder it runs in, and the Windows, macOS and Linux form when they differ.
- Every code block has a language tag and a file path caption (`**File: src/app.py**`).
- Show the common error a learner will hit and how to read it.
- **Show every configuration.** For Docker, Compose, databases, servers and tools: the full `Dockerfile`, `docker-compose.yml`, `.env` /
  `.env.example`, `.dockerignore`, config files and IDE connection settings, each in full with a path caption, then the commands to start,
  check status, read logs and stop or clean up, and the expected output of each. Explain every line of a config the first time it appears
  (what it does and what happens if you change it). Never say "configure Docker" without showing the file.

## Voice by level

| Level | Voice |
|-------|-------|
| 101 | Plain words, a non-programming analogy first (cooking, accounting, music, building), define each term once and add it to `GLOSSARY.md`, no unexplained abbreviations, small steps |
| 201 | Assume 101. Explain the why, show alternatives with "Why this, not that", tests with every feature, diagrams for structure |
| 301 | Assume 201. Trade-offs, failure modes, benchmarks or measurements, "when not to use this", production checklists, ADR-style decisions |

## Lesson file

Path: `tutorials/<track>/<level-folder>/<phase-folder>/NN-slug.md`. Use
[reference/lesson-template.md](reference/lesson-template.md) exactly. Sections in order: Why it matters,
What you will build, Before you start, Steps (numbered, all shown), Run it, How it works, Try it
(exercise), Check yourself (3 to 5 questions with answers), Common mistakes, Best practice (with a
source link), Next lesson.

## Best-practice teaching rules (apply to every new lesson)

1. **Outcomes first.** Every lesson starts with 2 to 4 measurable outcomes; "Check yourself" has one question per outcome; the Summary restates them.
2. **Retrieval practice.** Each lesson opens with a Recap of 2 to 3 questions from earlier lessons (spaced repetition); each phase ends with a mixed review.
3. **Worked example, then faded practice.** Show a complete example, then a guided exercise with TODOs, then a change exercise, then an optional stretch.
4. **One new idea at a time**, introduced by a concrete case before the general rule; name and correct the most common misconception.
5. **Predict before you run.** At least one step asks the learner to predict the output before they run it.
6. **Interleave and connect.** Link each lesson to where the idea reappears (a later lesson or a capstone chapter); level 201 and 301 lessons say why and when not to use the technique.
7. **Security by default** in every example; **accessibility** of web and mobile examples (labels, contrast, keyboard) from the first lesson.
8. **Plain language**, short sentences, every term defined once, analogies at level 101, trade-offs and failure modes at level 301.

## Source pack (see the `source-packs` skill)

Every lesson owns a folder in `source/` with the finished code and a `verify.json`. The lesson text
and the source files must be identical; copy from the files, never retype from memory. Run the
`verifying-labs` skill before marking a lesson done.

## Security, identity and API craft

These are taught **inside capstones** (see `designing-capstones`), not as separate tracks. When a language
lesson touches them (DTOs, validation, auth), keep it minimal and link to the capstone chapter.

## Best-practice claims

Each best-practice callout ends with `Source: <title> <link>` from a Tier 1 or 2 source. No source, no claim.

## Done means

Lesson file written, source folder complete, `verify.json` passes, `GLOSSARY.md` updated, one line added
to the track `_STATE.md`.
