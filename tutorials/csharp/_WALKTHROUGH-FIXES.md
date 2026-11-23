# C# 101 beginner walk-through resolution

2026-11-23. Review: `reviews/csharp-101.md` (read-only). No Blockers were reported.
Status: **20/20 Should-fix addressed; 16 actionable Nits addressed; 2 positive Nit observations retained unchanged.**

## Should-fix (in review order)
| # | Lesson | Resolution |
|---|---|---|
| 1 | 01 (all lessons) | Verbatim optional source-pack sentence, real repository and exact per-lesson source path; no pack required. |
| 2 | 01 | Captured fresh CLI-home banner with telemetry text and links; certificate generation disabled per process; no certificate creation/trust command. Telemetry opt-out named. |
| 3 | 01 | Terminal before use, home notation after terminal, SDK/framework/band definitions before use, JSON before file, restore defined before --no-restore. |
| 4 | 01 | 100-120 minutes, three-file learner inventory, bin/obj summarized, generated csproj inspected rather than pointlessly rewritten. |
| 5 | 01 | PATH failure, incompatible global.json SDK band, and no-project messages triggered in isolation and captured. |
| 6 | 01 | No extension or sign-in required; plain C# extension optional; explicit Dev Kit subscription sign-in/license note. |
| 7 | 02 | Interpolation/F2 and culture setup introduced before typing; culture setup is copied unchanged, not an extra exercise. |
| 8 | 02-12 | Identical workspace steps referenced with exact folder differences; only two unchanged project files copied. Both unchanged project files added to skip_lesson_check; every file still ships in packs. |
| 9 | 03 | Captured $80 and 15% FormatExceptions; stack-trace reading explained. |
| 10 | 04 | Removed impossible unused-age warning; retained and re-triggered assignment/type mismatch and missing-brace errors. |
| 11 | 05 | Captured missing-decrement repetition and < versus <= output; Ctrl+C recovery and off-by-one explanation. |
| 12 | 06 | Caller/body/scope defined before typing; static gets a limited working rule and a lesson-10 contrast; dropped signature/static-local-function tangent. |
| 13 | 06 | Unused-Area warning now has the actual cause (replacing its only call with a literal); scope error is separate. |
| 14 | 07 | 40-50 minutes, one-line generic/constructor explanations, no extra ContainsKey API; visible second-shelf print; missing-int lookup value explained as 0. |
| 15 | 09 | Real CS0165 and CS1513 mistakes plus handled retry/overflow messages; no copied unhandled Parse errors. |
| 16 | 10 | SavingsJar zero-initialized-field explanation moved into its exercise; numbered explanation continuous. |
| 17 | 10 | State, getter, public/private and property notation defined before typing; count/Count contrast; 45-55 minutes; four connected teaching chunks. |
| 18 | 11 | No split/renumber: remove custom enum/category and guard branch; cut init-only, positional-record, shallow-copy and suppression tangents; five connected ideas, 40-50 minutes. |
| 19 | 12 | Actual friendly input and malformed-CSV messages, exact triggers and fixes; no scratch-program errors or nonexistent int.Parse. |
| 20 | 12 | 90-120 minutes in two sittings, explicit break after Run it; starter and solution reference byte-identical helpers instead of repeating 160 lines. |

## Nits (in review order)
| # | Lesson | Resolution |
|---|---|---|
| 1 | 01 | Explain x86 column versus 64-bit Windows 11 route. |
| 2 | 01 | Remove lesson-01 self-link. |
| 3 | 02 | Complete lesson 01 (not 01 through 01). |
| 4 | 02 | Define warning versus error and show visible starter result. |
| 5 | 03 | Define exception before use; TryParse wording no longer says without throwing before explanation. |
| 6 | 03 | Explain zero people is outside the exercise and produces Share: Infinity; captured with 90/0. |
| 7 | 04 | Define switch expression, arm and pattern before code. |
| 8 | 05 | Starter comment now uses number % 2 == 0; copied identically into lesson. |
| 9 | 06 | Metres and 6 square metres per litre stated before code. |
| 10 | 07 | Missing-key exception replaces lowercase-console example. |
| 11 | 08 | Explain newline escape before code. |
| 12 | 09 | Nullable-input syntax defined before code; honest 35-45 minutes and focus on retry/handler. |
| 13 | 10 | No change needed: positive finding that both files and private-field diagnostic already work; re-ran both. |
| 14 | 11 | Explain CS8602 is a warning: build succeeds, first output appears, then unsafe read crashes. |
| 15 | 12 | No change needed: positive finding that main, solution and input validation already work; preserved and re-ran. |
| 16 | 12 | Skip blank/whitespace CRLF lines before parsing, preserve physical row numbers; capture has only invalid row 3 and Loaded: 1. |
| 17 | all | At least one prediction/trace question per lesson, using real captured program behavior. |
| 18 | packs | Separate exact phase-pack, all-in-one and repository-root cd examples in all three READMEs. |

## Decisions and limits
- No lesson split or renumbering. Estimates include reading, typing, running and exercises; installation routes are alternatives, not cumulative tasks.
- The first-use HTTPS installation notice is deliberately absent in the safe capture: automatic generation was disabled, not an existing certificate trusted or cleaned. The lesson explains that no certificate is needed and any trust suggestion is irrelevant.
- Only Windows was executed; existing macOS/Linux install routes remain documentation-based. Download .NET 11 page fetched successfully; VS Code and CLI-environment-variable page refreshes failed twice (proxy), so no further fetch retries.
- Verification is smoke only. No test suites, global tools, machine PATH edits or user-level settings changed. Disposable literal walkthroughs cover lessons 01 and 12; retained mistake rows were triggered using the actual lesson projects.
- See [_VERIFICATION.md](_VERIFICATION.md) for captured runs/diagnostics and [_STATE.md](_STATE.md) for the final PASS and pack results. No decisions needed.
