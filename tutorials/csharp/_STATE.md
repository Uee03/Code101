# C# track state

Last updated: 2026-11-23. C# 101 beginner walk-through findings applied; all 12 lessons **verified**.

## Version and scope
- SDK 11.0.100, global.json latestPatch pin (11.0.1xx); TargetFramework net11.0, nullable analysis/implicit imports enabled; no packages or art.
- Windows 11 execution only. macOS/Linux install instructions are documentation-based, not locally executed.
- Only tutorials/csharp and source/csharp authored; generated dist/packs archives rebuilt as requested. No commits, global tools, machine PATH changes, servers or user settings.
- Fresh-home banner capture disables automatic HTTPS certificate generation in the child process. No certificate creation/trust/cleanup command run.

## Lessons
| Lesson | Phase | Status | Smoke steps |
|---|---|---|---|
| [01. Hello, C#](101-zero-to-hero/phase-1-foundations/01-hello-csharp.md) | 1 | verified | main once; solution once |
| [02. Variables and types](101-zero-to-hero/phase-1-foundations/02-variables-and-types.md) | 1 | verified | main once; solution once |
| [03. Input and math](101-zero-to-hero/phase-1-foundations/03-input-and-math.md) | 1 | verified | main once; solution once |
| [04. Making decisions](101-zero-to-hero/phase-1-foundations/04-making-decisions.md) | 1 | verified | main once; solution once |
| [05. Loops](101-zero-to-hero/phase-2-building-blocks/05-loops.md) | 2 | verified | main once; solution once |
| [06. Methods](101-zero-to-hero/phase-2-building-blocks/06-methods.md) | 2 | verified | main once; solution once |
| [07. Arrays, lists and dictionaries](101-zero-to-hero/phase-2-building-blocks/07-arrays-lists-and-dictionaries.md) | 2 | verified | main once; solution once |
| [08. Files](101-zero-to-hero/phase-2-building-blocks/08-files.md) | 2 | verified | main once; solution once |
| [09. Handling errors](101-zero-to-hero/phase-3-real-programs/09-handling-errors.md) | 3 | verified | main once; solution once |
| [10. Classes and objects](101-zero-to-hero/phase-3-real-programs/10-classes-and-objects.md) | 3 | verified | main once; solution once |
| [11. Null safety and records](101-zero-to-hero/phase-3-real-programs/11-null-safety-and-records.md) | 3 | verified | main once; solution once |
| [12. Project: expense tracker](101-zero-to-hero/phase-3-real-programs/12-expense-tracker.md) | 3 | verified | main once; solution once |

## Review resolution
- **Blockers: 0 reported, 0 outstanding. Should-fix: 20/20 addressed.**
- **Nits: 16 actionable findings fixed; 2 positive observations retained/rechecked.** No actionable Nit skipped. The no-change rows are lesson 10's already-working two-file/private-access behavior and lesson 12's already-working program/exercise/validation paths.
- Full finding-by-finding ledger: [_WALKTHROUGH-FIXES.md](_WALKTHROUGH-FIXES.md). Captured evidence: [_VERIFICATION.md](_VERIFICATION.md).
- No split or renumbering. Setup now 100-120 minutes; later lessons 30-55 minutes; project 90-120 in **two sittings**, break after Run it.
- All 12 lessons use the template's optional source-repository sentence and exact source path. Exercise instructions copy starter and rename it, not nest it. No maintainer commands in lesson text.
- Repeated project configuration removed from lessons 02-12 and exercises; exact unchanged earlier steps/files and folder-name differences listed. code/global.json and code/Lesson.csproj alone are in skip_lesson_check for 02-12. Full files still ship. All 36 manifests match the real generated file displayed in 01.
- Lesson 01: safe full first-use banner/telemetry opt-out, no-sign-in default, three-file inventory, no unnecessary csproj rewrite, real SDK/PATH/folder errors.
- All Common mistakes rows re-triggered against their own lesson's code or explicit edits; caught input errors show friendly messages, not fictitious crashes. Added $80/15%, loop bugs, real scope/unused-method causes, missing-key and CSV-row messages; no author paths.
- Jargon defined before use in 01/02/03/06/10; glossary aligned. Prediction question in every lesson; misplaced SavingsJar paragraph moved into exercise.
- Trimmed 07 generic/constructor explanations and extra lookup API; printed changed shelf. Trimmed 11 to nullable access, records, copying/equality (removed category enum/guard/theory tangents). Project exercises reference identical helpers; blank CRLF CSV rows skipped without losing physical row numbers.
- Kept double for first arithmetic practice, decimal for stored expenses; CSV is a restricted teaching dialect, with explicit backup/incomplete-load warning and no claim of accounting readiness.

## Verification
`python scripts\verify_labs.py source/csharp/`: **12 passed, 0 failed, 0 unverified (missing tools)** after final lesson/source edits. Main and solution once each with small input; no test suites. All 36 main/starter/solution projects also ran in disposable copies. Actual diagnostic captures and literal no-source-pack walkthroughs for 01/12 are in _VERIFICATION.md; no background helper remains.

Static authoring audit: section order, consecutive steps, local links, byte-matching snippets or exact identical-file reconstruction, optional source sentence, skip lists and UTF-8 without BOM. The .NET 11 download page fetched successfully; VS Code and CLI-environment-variable doc refreshes failed twice through the proxy, so they were not retried. Existing official install guidance retained; no unresolved code/toolchain blocker.

## Packs
`python scripts\build_packs.py csharp-101` completed after the PASS. All four archives passed ZIP integrity, expected lesson counts, build-output exclusion and 25 MB limit. Phase READMEs now distinguish phase zip, all-in-one archive and repository-root cd examples, exact exercise copying, revised scope and realistic times.

Actual pack-builder output:
```text
built csharp-101-phase-1-foundations.zip (41 files)
built csharp-101-phase-2-building-blocks.zip (41 files)
built csharp-101-phase-3-real-programs.zip (50 files)
built csharp-101-all.zip (3 phases)
```

| Zip | Files | Bytes |
|---|---|---|
| `csharp-101-all.zip` | 132 | 62,894 |
| `csharp-101-phase-1-foundations.zip` | 41 | 17,696 |
| `csharp-101-phase-2-building-blocks.zip` | 41 | 17,558 |
| `csharp-101-phase-3-real-programs.zip` | 50 | 24,780 |

## Decisions needed
None. Art remains assets: [] everywhere. No actionable Nit was deferred.
