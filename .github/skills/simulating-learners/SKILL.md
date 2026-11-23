---
name: simulating-learners
description: 'Runs the persona walk-through: a beginner, intermediate or senior developer follows the finished Code101 material literally and logs friction. Use for the final review pass, when the user says act as a beginner, walk through the tutorials, simulate a learner, or test the learning path.'
---

# Simulating learners

**Best model:** Plan tier for Beginner and Intermediate personas, Deep tier for the Senior persona.

Personas follow the material **literally** in a clean working folder (`reviews/work/`, git-ignored): unzip the phase source pack, type
every step, run every command, attempt every exercise before opening its solution.

| Persona | Level | Knows | Hunts for |
|---------|-------|-------|-----------|
| Beginner "Sam" (marketing, no coding) | 101 | how to use a computer | undefined terms, skipped steps, unexplained errors, intimidating jargon, steps that assume a tool is installed |
| Intermediate "Priya" (1 to 2 years) | 201 | one language, git, basics | missing why, weak exercises, no tests, unrealistic examples, steps that only work on one OS |
| Senior "Marcus" (10 years) | 301 | production systems | outdated or unsafe advice, missing trade-offs, no failure modes, unmeasured performance claims, security gaps |

## Procedure

1. Read the track `_BRIEF.md`, then lessons in order. Do not read ahead: a term used before it is defined is a finding.
2. For each lesson record time taken, every point of friction, and the exact line. Keep the log terse.
3. Write `reviews/<track>-<level>.md`:

```markdown
# <track> <level> walk-through by <persona>
| Lesson | Result (smooth, friction, blocked) | Finding | Type | Severity |
```
Types: blocked, wrong, unclear, missing-prerequisite, undefined-term, too-long, too-short, outdated, unsafe.

4. Stop a lesson as **blocked** if an instruction cannot be followed as written; do not guess or fix it silently.
5. Hand the log to the Tutorial Author. Re-run only lessons that changed.

## Pass criteria

All labs run; no blocked lessons; no undefined terms; every exercise solvable from the lesson alone;
the senior pass finds no unsafe or outdated advice. Set `_STATE.md` status to `simulated`.
