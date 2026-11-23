# Python track state

Status flow: planned -> written -> verified -> reviewed -> simulated.

## Level 101
| Lesson | Title | Status | Verified | Notes |
|--------|-------|--------|----------|-------|
| 101.1.01 | Hello, Python | verified | 2026-11-23 | 60 min, two sittings before Step 7; setup terminology, editor/file traps and captured errors clarified |
| 101.1.02 | Variables and types | verified | 2026-11-23 | 35 min; intermediate run feedback, jar comments, braces, glossary link and exercise run command |
| 101.1.03 | Input and math | verified | 2026-11-23 | 35 min; arithmetic wording, floor division, partial-file guidance and captured numeric-input errors |
| 101.1.04 | Making decisions | verified | 2026-11-23 | 40 min; elif/quotes, Up arrow, decimal/empty input and actual indentation line numbers |
| 101.2.05 | Loops | verified | 2026-11-23 | 40 min; sequence/traceback defined here, indentation and bad-input rows captured |
| 101.2.06 | Functions | verified | 2026-11-23 | 30 min; caller/body/positional argument defined; exercise prose no longer gives the calculation |
| 101.2.07 | Lists and dictionaries | verified | 2026-11-23 | 35 min; mixed quotes and insertion order explained; cart exercise goal instead of answer |
| 101.2.08 | Files | verified | 2026-11-23 | 60 min, two sittings before Step 4; unchanged code presented as text-note then CSV; path/encoding details in optional Going further note |
| 101.3.09 | Handling errors | verified | 2026-11-23 | 40 min; isfinite detail optional; reachable guidance plus colon/continue/import mistakes; promise points to 03 only |
| 101.3.10 | Modules and packages | verified | 2026-11-23 | 60 min, two sittings before Step 5; activation, Restricted policy, leaving venv, pip failure, imports and one-liner terminology |
| 101.3.11 | Classes basics | verified | 2026-11-23 | 35 min; self/extra argument/_init_ errors captured; bare return explained; lifetime/class-variable jargon removed |
| 101.3.12 | Project: expense tracker | verified | 2026-11-23 | 90 min, two sittings before Step 3; reachable input/CSV guidance and real assertion traceback; tuple/OS/CSV terms defined; optional self-check and row-shape reference |

## Beginner walk-through fixes ? 2026-11-23

- `reviews/python-101-phases-2-3.md`: **11 of 11 Should-fix fixed**, findings 1, 8, 11, 14, 15, 16, 19, 21, 22, 23, 28.
  **18 of 18 nits fixed**, findings 2, 3, 4, 5, 6, 7, 9, 10, 12, 13, 17, 18, 20, 24, 25, 26, 27, 29.
- `reviews/python-101.md`: the earlier **14 of 14 Should-fix remain applied**. **20 of 21 open nits fixed**:
  findings 10?19, 22?26 and 30?34. Total across both reviews: 25/25 Should-fix addressed (11 this pass),
  38/39 nits addressed, no blockers.
- **Skipped: Phase 1 finding 35 (repository-wide line-ending policy).** Its proposed `.gitattributes` change or
  quality-checklist clarification is outside the permitted `tutorials/python/` and `source/python/` edit scope.
  Source/text parity is checked after newline normalisation; no repository-wide EOL policy was chosen.
- Every lesson now has the template's verbatim optional source-pack sentence with its own repository path.
  Starter-copy destinations and the terminal after `code .` are explicit. Learner-facing lessons and phase READMEs
  contain no maintainer command/result instructions or keyboard-echo wording. All use `assets: []`.
- The glossary is one continuous table, grouped by introducing lesson. Flagged terms were defined or unnecessary
  jargon removed; traceback now belongs to lesson 05. Phase READMEs include timings, break points and glossary links.
- No lesson IDs were changed or split. The only program-file changes are comments in
  `02-variables-and-types/code/variables.py` (jar metaphor) and `03-input-and-math/code/operators.py` (calculation wording).
  Those programs were run first, then their changed comments copied from source into all matching lesson blocks.
  Exercise files and verify.json files are unchanged. Whole-file source blocks were re-copied from source, including
  blank lines; lesson 08 presents the same complete source in two consecutive parts.

## Verification evidence ? 2026-11-23

Windows PowerShell 5.1 / Python 3.15.2. Verification was smoke-only: small program runs, not a unit-test suite.

- All **73 Common mistakes rows** were reproduced in disposable copies (edits, inputs, wrong-folder and saved-file
  symptoms); the captured error/guidance text was pasted into the lessons. Author paths were replaced by `<project>`.
- Lesson 10: created and removed an isolated venv, confirmed `sys.prefix != sys.base_prefix` prints `True`,
  and used pip's `--no-index` option to reproduce unavailable-package messages without changing connectivity.
  A child PowerShell process with `-ExecutionPolicy Restricted` reproduced blocked activation; no machine policy changed.
  The earlier successful Colorama 0.4.6 install/import evidence is retained; no global dependency was installed this pass.
- Walked lessons **01 and 12 from their Markdown**, not from `code/`, in a throwaway home folder using PowerShell
  folder/run commands. First program, recipe exercise, tracker menu, CSV reload and count-option exercise matched.
  The optional plain-Python self-check was run once as a learner command and printed `Self-check passed.`;
  it is not part of verify.json. Installers and GUI actions were read-only because the tools are already installed.
- Main examples, starters and solutions were run with small inputs. Full source-block parity (normalised newlines),
  standard source sentences, Markdown table widths and UTF-8-without-BOM checks passed. Temporary folders were removed.

Final requested commands, in order:

```text
python scripts\verify_labs.py source/python/
12 passed, 0 failed, 0 unverified (missing tools)
python scripts\build_packs.py python-101
built python-101-phase-1-foundations.zip (19 files)
built python-101-phase-2-building-blocks.zip (18 files)
built python-101-phase-3-real-programs.zip (29 files)
built python-101-all.zip (3 phases)
```

All 12 lessons retain status `verified`; none is UNVERIFIED. Four ignored pack artifacts were rebuilt as requested.
No review, tooling, CONTEXT, docs or other-track files were edited. No commit was made.

## Level 201 / 301
Python 201: 11 lessons in four phases, **written (not run)**; runtime **UNVERIFIED**. See [_STATE-201.md](_STATE-201.md) for static-only evidence and [_BRIEF-201.md](_BRIEF-201.md) for scope. No lesson examples, tests, servers or Docker commands were run. The uv/Docker CLIs were not present on the inspected session PATH; no installation was attempted.

Python 301: not started.
