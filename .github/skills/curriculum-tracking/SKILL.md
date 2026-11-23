---
name: curriculum-tracking
description: 'The Code101 tracking protocol: CONTEXT.md, per-track _BRIEF.md, _STATE.md and GLOSSARY.md that keep token use low across sessions. Use at the start and end of every work block, when creating a new track, or when asked what is done, what is next, or to update progress.'
---

# Curriculum tracking

**Best model:** Quick tier (GPT-6 Luna) via Quick Helper.

State lives in files, not in chat. Read small files first; never re-read finished lessons.

| File | Owner | Size cap | Contains |
|------|-------|----------|----------|
| `CONTEXT.md` | everyone | 120 lines | phase, status table, learned facts, next actions, open questions, decision log |
| `tutorials/<track>/_BRIEF.md` | Curriculum Architect | 1 page | audience, phase and lesson list with one-line goals, version pins, terminology, up to 10 source links |
| `tutorials/<track>/_STATE.md` | Tutorial Author | grows 1 line per lesson | lesson table: id, title, status (planned, written, verified, reviewed), verified date, notes |
| `tutorials/<track>/GLOSSARY.md` | Tutorial Author | grows | term, one-line definition, lesson where introduced |

## Start of a block
1. Read `CONTEXT.md`. 2. Read the track `_BRIEF.md` and `_STATE.md`. 3. Pick the next `planned` lesson.

## End of a block
1. Update `_STATE.md` rows. 2. Update `CONTEXT.md`: status table, next actions, any new fact or decision (one line).
3. Do not paste lesson content or logs into either file.

## `_STATE.md` format

```markdown
| Lesson | Title | Status | Verified | Notes |
|--------|-------|--------|----------|-------|
| 101.1.01 | Hello Python | verified | 2026-11-23 | |
```

Status flow: `planned` -> `written` -> `verified` (labs pass) -> `reviewed` (checklist approved) -> `simulated` (persona pass done).
