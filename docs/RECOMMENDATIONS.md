# Recommendations: making the learning easier to follow

Ranked by impact. Items marked **(in plan)** are already built into [PLAN.md](PLAN.md); the rest need
your approval.

## Highest impact

1. **One running project per track, growing lesson by lesson (in plan).** Learners keep context instead
   of restarting with a new toy example. Capstones reuse the same "Tasks and Teams" domain.
2. **Every code block is verified (in plan).** A Lab Verifier runs each lab in a clean folder; each lesson
   shows "verified on <date> with <tool versions>". Broken tutorials are the top reason people quit.
3. **Exercises with solutions and a checkpoint quiz in every lesson (in plan).** Active practice beats
   reading. Solutions in a collapsed section or separate file so learners try first.
4. **Prerequisite map and "start here" quiz per track.** A diagram of how lessons depend on each other and
   a 10-question placement quiz so an experienced learner skips to the right level instead of reading all 101.
5. **Define a term once, link to it everywhere.** A shared `GLOSSARY.md` per track and a rule that no
   term appears before its definition. The beginner persona checks this.
6. **Analogies by field.** Level 1 explains ideas through cooking, accounting, medicine, construction
   or music, since your audience comes from any field.

## Structure and navigation

7. **Fixed lesson length (15 to 25 min) and one idea each.** Time estimate in front matter.
8. **Learning paths, not just folders.** Flagship 101 path per level; role paths (Backend, Frontend,
   Mobile, Game, Desktop, AI) listing lessons across tracks in order.
9. **Side-by-side Angular and React lessons (in plan).** Same app, same numbering, one table comparing
   concepts (component, state, effects, routing, forms) so choosing becomes informed.
10. **"Why this, not that" boxes.** Short trade-off notes (Controllers vs FastEndpoints, REST vs gRPC,
    monolith vs microservices) so learners understand decisions, not just recipes.
11. **Diagrams in every architecture lesson.** Mermaid for quick diagrams, draw.io for editable ones
    (existing skills), each with alt text.
12. **Common mistakes and debugging section.** Show the real error message and how to read it.

## Practice and feedback

13. **Starter and solution branches/folders.** `labs/<lesson>/starter` and `/solution` so a learner who is
    stuck can recover without losing progress.
14. **Progress tracker per learner.** A checklist file per level (checkbox per lesson) and badges in the
    README (101 done, 201 done, 301 done).
15. **Review checklists for learners' own code.** Reuse the Reviewer agents so learners can paste their
    solution and get feedback in the same standard as the lessons teach.
16. **Capstone rubric.** What "done" means: tests, README, diagram, security checklist, deployed via compose.

## Quality and maintenance

17. **Pin versions and re-verify quarterly.** Front matter has versions; a scheduled check flags drift
    (these stacks change fast: .NET, Angular, Flutter, Node and Python all moved recently).
18. **Source every best practice.** A short "Source" line with Tier 1 or 2 link per rule.
19. **Accessibility of the material itself.** Plain language, short sentences, no jargon before definition,
    alt text, high-contrast diagrams, copy-paste friendly code, Windows + macOS + Linux commands where they differ.
20. **Rendered site with search (MkDocs Material) and a "run in dev container" button.** Dev containers
    give identical environments and remove "works on my machine" problems.
21. **Security by default in examples.** Parameterized queries, hashed passwords, secrets from env, no
    hard-coded tokens, HTTPS. Teaching insecure shortcuts creates habits that are hard to unlearn.

## Things I recommend NOT doing

- Do not write 101 lessons per track per level; quality and verification would collapse (decision D1).
- Do not add video or interactive sandboxes now; add after the text is stable.
- Do not copy text from the linked articles; summarize, cite and write original examples.
