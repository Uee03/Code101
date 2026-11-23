---
name: tutorial-quality-checklist
description: 'Pass/fail checklist for reviewing a Code101 lesson, source folder or capstone chapter. Use when reviewing a tutorial, grading a lesson before marking it done, or when the user says review the lesson, check the tutorial, or quality gate.'
---

# Tutorial quality checklist

**Best model:** Plan tier (Claude Sonnet 5.5) via the Tutorial Reviewer. Read-only.

Mark each item PASS / FAIL with file and line. Report FAILs by severity: **Blocker** (learner cannot
continue or is misled), **Should-fix**, **Nit**.

## Completeness (all steps shown)
- [ ] Every file the learner needs is shown in full at first use; later edits show the changed region with context
- [ ] No "as before" or "refer to earlier steps" except for genuinely identical steps, and then the differing names or lines are listed
- [ ] Every command names its folder; OS differences shown (Windows, macOS, Linux)
- [ ] Expected output shown for every Run step and it matches what the code prints
- [ ] Front matter complete (track, level, phase, versions, verified date, source, assets)

## Correctness
- [ ] Lesson code is byte-identical to `source/.../code/`
- [ ] `verify.json` exists and `python scripts/verify_labs.py <lesson>` passes
- [ ] Versions pinned and current against official docs
- [ ] Best-practice callouts cite a Tier 1 or 2 source; none contradict it
- [ ] Security by default: parameterised queries, hashed passwords, no secrets in code, HTTPS for real services

## Teaching quality
- [ ] One idea per lesson, 15 to 25 minutes
- [ ] Every term defined before use (and in `GLOSSARY.md`); no term from a later lesson
- [ ] Level voice correct (101 analogy-first, 201 why + alternatives, 301 trade-offs and failure modes)
- [ ] Exercise matches the lesson, has starter and solution, and the solution passes
- [ ] 3 to 5 check questions with answers, testing understanding not memory
- [ ] Common mistakes: every row is reproducible by this lesson's own code, shows the real text (no author paths), none is a placeholder, and the likeliest first-timer errors are present
- [ ] Time is honest (about 5 minutes per new idea plus setup); more than 5 new ideas means split or trim
- [ ] "Before you start" has the optional source-pack sentence with the repository location; no maintainer text (`verify_labs`, `build_packs`) in learner-facing text
- [ ] Try it describes the goal and expected output without giving the answer
- [ ] Repeated boilerplate is referenced (with differences listed) rather than copied

## Packaging
- [ ] Lesson folder has `code/`, `exercise/starter/`, `exercise/solution/`, `verify.json`
- [ ] Only art from `assets/art` is used and listed in `assets:`; license file present
- [ ] No secrets, no machine-specific paths, no build output committed

## Output format

```
Verdict: Approve | Approve-with-nits | Request-changes
Blockers: ...   Should-fix: ...   Nits: ...
```
