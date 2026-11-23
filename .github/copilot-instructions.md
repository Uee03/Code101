# Code101 workflow

Code101 is a tutorial library (101 Zero to Hero, 201 Hero to Super Hero, 301 Super Hero to Legendary)
with phased, unzippable source packs. Read `CONTEXT.md` first; it is the live state.

| Task | Agent / command | Tier |
|------|-----------------|------|
| Plan a track or phase | Curriculum Architect | plan, read-only |
| Write a lesson + source pack | Tutorial Author `/new-lesson` | act |
| Review a lesson | Tutorial Reviewer `/review-lesson` | plan, read-only |
| Run the labs | Lab Verifier `/verify-lab` | act |
| Beginner / intermediate / senior walk-through | Learner agents `/walkthrough` | plan / deep |
| Links | Technical Design Author | Plan | Writes TDDs for built and practice capstones (`/new-tdd`) |
| Link Curator | quick |

Skills: `authoring-tutorials`, `source-packs`, `tutorial-quality-checklist`, `verifying-labs`,
`curriculum-tracking`, `simulating-learners`, `curating-links`, `designing-capstones`, `writing-tdds`.
Stack-specific skills live in `F:\Projects\Git\Claude\AgenticAssisstance\templates\<stack>`.

## Rules

- Every step is shown. "Refer to previous steps" only when steps are genuinely identical; list the differences.
- **Do not run the code (user instruction 2026-11-23).** Write the code and the lesson carefully from the official docs; derive expected output by reading the code; mark new lessons
  `verified: not yet run`. Only `python scripts/verify_labs.py --static <filter>` is allowed. Earlier lessons were run and stay verified. Before sharing lessons with learners, run the full verifier.
- Source packs are split into phases (`source/<track>/<level>/phase-<n>-<slug>/`); build with `python scripts/build_packs.py`.
- Security, identity and API craft are taught inside capstones, not as separate tracks.
- Art comes from `assets/art` only (CC0 icons); never add proprietary Art-repo packs.
- Token discipline: read `CONTEXT.md`, then the track `_BRIEF.md` and `_STATE.md`; search, then view line ranges; do not reload `docs/LINKS.md`.
- After two failed fixes, stop and report; update `CONTEXT.md` at the end of every block.
