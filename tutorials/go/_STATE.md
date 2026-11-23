# Go track state

Last updated: 2026-11-23 (beginner walk-through findings applied).

## 101 Zero to Hero

Minimum Go 1.22.0 in supplied modules; actual toolchain Go 1.27.4 on Windows.
12 lessons, three phases. Standard library only, no art or missing tools.

| Lesson | Phase | Status | Verified |
|---|---|---|---|
| 01-hello-go | phase-1-foundations | verified | 2026-11-23, Windows / Go 1.27.4 |
| 02-variables-and-types | phase-1-foundations | verified | 2026-11-23, Windows / Go 1.27.4 |
| 03-input-and-math | phase-1-foundations | verified | 2026-11-23, Windows / Go 1.27.4 |
| 04-making-decisions | phase-1-foundations | verified | 2026-11-23, Windows / Go 1.27.4 |
| 05-loops | phase-2-building-blocks | verified | 2026-11-23, Windows / Go 1.27.4 |
| 06-functions | phase-2-building-blocks | verified | 2026-11-23, Windows / Go 1.27.4 |
| 07-slices-and-maps | phase-2-building-blocks | verified | 2026-11-23, Windows / Go 1.27.4 |
| 08-files | phase-2-building-blocks | verified | 2026-11-23, Windows / Go 1.27.4 |
| 09-errors | phase-3-real-programs | verified | 2026-11-23, Windows / Go 1.27.4 |
| 10-structs-and-methods | phase-3-real-programs | verified | 2026-11-23, Windows / Go 1.27.4 |
| 11-interfaces-and-packages | phase-3-real-programs | verified | 2026-11-23, Windows / Go 1.27.4 |
| 12-expense-tracker | phase-3-real-programs | verified | 2026-11-23, Windows / Go 1.27.4 |

## Review resolution

Applied reviews/go-101.md: **19 of 19 Should-fix fixed; 19 of 19 actionable nits fixed, none skipped.**
Rows 10 and 28 are no-further-finding notes, not actionable nits. No decisions needed.

| Should-fix finding | Resolution |
|---|---|
| 1 | Every lesson has the template's optional source sentence and repository path; README explains repository and phase/all ZIP layouts. |
| 2 | Explorer, New File and New Folder are defined in lesson 01 and the shared guide. |
| 3 | Removed every hand edit of go.mod and its jargon paragraph; generated Go versions are left alone. |
| 4 | Captured wrong-folder and missing-module-name failures; folder recovery and GOPATH explanation are explicit. |
| 9 | Every lesson says copy the starter folder and rename it to its try name; go.mod/main.go must be direct children. |
| 13, 14 | Lesson 03 allows 60 minutes; Scan is optional, core explanations are trimmed and every guard has a plain-language reading. |
| 15 | Triggered $80, 15% and trailing-space input; pasted the actual messages into Common mistakes. |
| 17, 18 | Escaped the lesson 04 table pipes; added saved age changes 3, 12, -1 with captured full outputs, then restore 30. |
| 23 | Lesson 07 allows 40 minutes; removed unshown array/allocation/deep-copy/nil/make/bounds tangents. Nil map has a plain reference glossary definition. |
| 24 | Defined sequence, byte slice, permission code and octal before file code; removed KiB/token-limit/platform tangents. |
| 27 | Removed premature Error-method requirement and unplanned errors.Is/As promises; define method before the diagnostic that mentions it. |
| 29 | Lessons 03, 06, 08, 09, 10, 11 give exercise goals/output, not the implementation recipe; starter TODO comments also state goals. |
| 30 | Lesson 10 allows 50 minutes, trims receiver internals to an optional note and shows the captured silent value-receiver no-change effect. |
| 32 | Triggered misspelt recipt import; retained Go's go get suggestion and explicitly say not to run it. |
| 34 | Triggered go run main.go and decimal cents input in lesson 12; show actual diagnostics and recovery. |
| 35 | Lesson 12 allows 90 minutes in two sittings, with a marked break after Step 4; define new helpers nearby and trim limitations to two plain sentences. |
| 38 | Shared How every lesson works guide; identical folder steps list substitutions, no repeated module-edit paragraph, solution regions instead of entire repeated programs, identical project starter helpers referenced precisely. |

Actionable nits fixed: **5, 6, 7, 8, 11, 12, 16, 19, 20, 21, 22, 25, 26, 31, 33, 36, 37, 39, 40**.
- Explain PowerShell words, safer archive precheck before removal, real downloaded .deb filename, newest-stable option and profile reload shortcut; note optional tools location.
- Remove learner-facing maintainer blocks; clarify the lesson 02 line removal and remove package-level jargon.
- Define ./scan-demo; remove lesson 04's pre-exercise answer; capture an endless-loop symptom and give Ctrl+C recovery.
- Replace object with value and omit bare-return detour; correct rectangle and WriteFile diagnostics using actual lesson-file mutations.
- Locate shopping.csv explicitly; explain compiler headings and varying line numbers; format lesson 11 imports from source with gofmt.
- Simplify first-run persistence advice, link the official Tour of Go, describe extension download wait and single-module folder selection, explain the all-pack extra directory.

## Evidence and scope

Actual final command: `python scripts/verify_labs.py source/go/`.
One small run in code and one in exercise/solution per lesson; no test suites, go test, go vet, lint checks or benchmarks.

```text
[PASS      ] source/go/101-zero-to-hero/phase-1-foundations/01-hello-go
[PASS      ] source/go/101-zero-to-hero/phase-1-foundations/02-variables-and-types
[PASS      ] source/go/101-zero-to-hero/phase-1-foundations/03-input-and-math
[PASS      ] source/go/101-zero-to-hero/phase-1-foundations/04-making-decisions
[PASS      ] source/go/101-zero-to-hero/phase-2-building-blocks/05-loops
[PASS      ] source/go/101-zero-to-hero/phase-2-building-blocks/06-functions
[PASS      ] source/go/101-zero-to-hero/phase-2-building-blocks/07-slices-and-maps
[PASS      ] source/go/101-zero-to-hero/phase-2-building-blocks/08-files
[PASS      ] source/go/101-zero-to-hero/phase-3-real-programs/09-errors
[PASS      ] source/go/101-zero-to-hero/phase-3-real-programs/10-structs-and-methods
[PASS      ] source/go/101-zero-to-hero/phase-3-real-programs/11-interfaces-and-packages
[PASS      ] source/go/101-zero-to-hero/phase-3-real-programs/12-expense-tracker

12 passed, 0 failed, 0 unverified (missing tools)
```

Additional bounded walkthrough captures (disposable folders, removed afterwards):
- Built lessons 01 and 12 from their displayed Markdown files, not by copying code/. Generated modules kept go 1.27.4 unchanged. Program output and the project's saved CSV matched the lesson.
- Checked the project break: only expense.go/check.go exist at Step 4, with no attempt to run until main.go is added.
- Reconstructed the 01/12 starters from displayed text and explicit identical-file references; checked all 12 lessons' full code/starter blocks and solution regions against source (line endings normalized).
- Ran every changed starter and lesson 11 code/solution before copying their source into lessons. Captured each lesson's go mod init output.
- Triggered compiler failures by the exact mutations described in Common mistakes, not unrelated tiny sample programs. Author paths were replaced by <project> in the missing-module-name diagnostic.
- Triggered wrong folder, $80/15%/trailing space, value receiver, import typo, wrong multi-file command and decimal cents. Sampled the accidental endless loop and terminated only its own process.
- OS installer/editor UI instructions checked read-only against official Go and VS Code documentation (fetched with curl); no installation, certificate, global tool, machine PATH or profile changes were made.

## Source and pacing decisions

- No lessons renumbered or split. Times: 01 60; 02 35; 03 60; 04 40; 05 35; 06 40; 07 40; 08 45; 09 40; 10 50; 11 45; 12 90 minutes.
- Lesson 03's separate token-input demo and lesson 10's extra receiver mechanics are optional; neither exercise depends on the optional explanation.
- Source changes: gofmt import order in lesson 11 code/starter/solution and goal-only starter TODO comments in 03/08/09/10/11. Runtime behavior and exercise answers are unchanged.
- Every verify.json lists code/go.mod in skip_lesson_check for the shared generated-module explanation. Only the module-name suffix differs; all supplied modules keep the pinned minimum 1.22.0. No runnable Go files are excluded.
- CSV remains deliberately restricted; the project uses bounded integer cents and plain startup self-checks.
- No UNVERIFIED lessons or pending decisions. No commit requested or made. Repository edits limited to tutorials/go and source/go; the required pack builder writes ignored dist/packs outputs.

## Packs

Command: `python scripts/build_packs.py go-101`, run after the successful final smoke check.

Actual build output:

```text
built go-101-phase-1-foundations.zip (30 files)
built go-101-phase-2-building-blocks.zip (29 files)
built go-101-phase-3-real-programs.zip (38 files)
built go-101-all.zip (3 phases)
```

All three phase packs and the all-level pack rebuilt successfully; phase packs remain below 25 MB.
