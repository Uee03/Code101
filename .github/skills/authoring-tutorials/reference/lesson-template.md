# Lesson template

Copy this structure. Replace every `<...>`. Keep every section; write "None" for an empty one.

````markdown
---
track: <python|csharp|c|cpp|go|rust|web|angular|react|flutter|kotlin|unity|databases|supabase|docker|ollama|architecture|patterns|capstone>
level: <101|201|301>
phase: <number>
phase_name: <slug, e.g. foundations>
lesson: <NN>
title: <Title>
time: <15-25 min>
prerequisites: [<lesson ids or "none">]
versions: { <tool>: "<version>" }
verified: <YYYY-MM-DD> on <OS>, <tool versions>
source: source/<track>/<level-folder>/<phase-folder>/<NN-slug>/
assets: [<category/icon>, ...]
---

# <NN>. <Title>

## What you will be able to do
By the end of this lesson you will be able to (2 to 4 measurable outcomes, each starts with an action verb such as write, run, explain, predict, fix, compare, design):
- <outcome 1>
- <outcome 2>

## Recap
<2 to 3 questions from earlier lessons that this one builds on (retrieval practice), each with a collapsed answer. For the first lesson of a track write "None, this is the start".>

## Why it matters
<2 to 4 sentences. Level 101: begin with an everyday analogy.>

## What you will build
<One paragraph and, when useful, the expected final screen or output.>

## Before you start
- Tools and versions (with the install lesson if needed)
- Time: <realistic first-timer minutes>. <Optional: "two sittings, break at Step N" for project lessons>
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/<track>/<level>/<phase>/<NN-slug>/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

## Steps
### Step 1. <Action>
<Where: folder. What: command or file.>

**File: `<path>`**
```<lang>
<full content>
```
Expected result: <exactly what the learner sees>

### Step 2. ...

## Run it
```<shell>
<command>
```
Expected output:
```text
<exact output>
```

## How it works
<Walk through the code in the order it runs. Define each new term; add it to GLOSSARY.md. Name the most common misconception and correct it.>

## Try it
<Exercise in three rungs: (1) Guided: fill in the TODOs; (2) Change: modify the finished program to do something new; (3) Stretch (optional): a small design choice with no single answer. Describe the goal and the expected output; do not give the answer. Starter in `exercise/starter`, answer in `exercise/solution`.>

<details><summary>Solution</summary>

<full solution code and explanation>

</details>

## Check yourself
<3 to 5 questions, one per learning outcome, at least one that asks the learner to predict output or find the bug.>
1. <Question> <details><summary>Answer</summary><answer></details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|

## Best practice
<One rule.> Source: <title> <link>

## Going further
<Optional: 1 to 3 pointers (official docs section, a harder variation, a link to the capstone chapter where this is used).>

## Summary
<3 to 5 bullets that restate the outcomes in the past tense: "You wrote...", "You explained...">

## Next lesson
<NN+1. Title>: <one line on what it adds.>
````

## Source folder for the lesson

```
source/<track>/<level-folder>/<phase-folder>/<NN-slug>/
  code/                 finished, runnable code (what the Steps build)
  exercise/starter/     where the Try it exercise begins
  exercise/solution/    the answer
  verify.json           machine-checkable steps (see verifying-labs)
  assets/               only the art files this lesson uses (copied by build_packs.py)
```

Phase folders also contain `PACK-README.md` (how to unzip, run, and what the phase covers).
