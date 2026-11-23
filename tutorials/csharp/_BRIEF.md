# C# 101 (Zero to Hero): author brief

## Learner and outcome
Complete beginners from any field; no terminal, editor or programming experience assumed.
Twelve lessons in three downloadable phases lead to a small, local expense tracker.
Use everyday analogies first, define terms where introduced, show every command and complete file,
and include a runnable starter, a full solution, three or four answered questions and real diagnostics.
Setup takes 100-120 minutes; later lessons take 30-55 minutes including exercises.
The project takes 90-120 minutes in two sittings, with a marked break after Run it.
Keep all twelve lesson numbers; trim tangents and identical setup rather than splitting lessons.

## Version decision (2026-11-23)
Microsoft's supported-release table lists .NET 11 as active STS (standard-term support), released
2026-11-10, supported through 2028-11-14. The author machine reports SDK 11.0.100.
Use SDK 11.0.100, global.json with latestPatch roll-forward, TargetFramework net11.0,
nullable checking and implicit imports enabled. Explain top-level statements. No external packages.
Keep the SDK on current supported patches; later 11.0.1xx servicing releases are allowed.

## Lesson map
| Phase | Lesson | Main build / exercise |
|---|---|---|
| 1 foundations | 01 Hello, C# | install tools, generated console project / recipe card |
| 1 foundations | 02 Variables and types | stock label / event budget |
| 1 foundations | 03 Input and math | tip calculator / bill splitter |
| 1 foundations | 04 Making decisions | ticket machine / grade checker |
| 2 building blocks | 05 Loops | packing checklist / count even numbers |
| 2 building blocks | 06 Methods | paint estimate / delivery price |
| 2 building blocks | 07 Arrays, lists and dictionaries | pantry inventory / score board |
| 2 building blocks | 08 Files | write/read a tiny CSV / shopping CSV |
| 3 real programs | 09 Handling errors | re-ask for quantity / safe age input |
| 3 real programs | 10 Classes and objects | refillable counter / savings jar |
| 3 real programs | 11 Null safety and records | optional receipt / optional contact |
| 3 real programs | 12 Project: expense tracker | menu + records + CSV + plain assertion self-check / total command |

## Sources (Tier 1: official; no other tiers needed)
- Install hub and OS-specific linked instructions: https://learn.microsoft.com/dotnet/core/install/
- Release support: https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core
- SDK downloads: https://dotnet.microsoft.com/en-us/download/dotnet/11.0
- VS Code setup: https://code.visualstudio.com/docs/csharp/get-started
- C# language guide and its linked reference pages: https://learn.microsoft.com/dotnet/csharp/
- Types: https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/built-in-types
- Numbers: https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/floating-point-numeric-types
- Control flow: https://learn.microsoft.com/dotnet/csharp/language-reference/statements/selection-statements
- Loops: https://learn.microsoft.com/dotnet/csharp/language-reference/statements/iteration-statements
- Methods: https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/methods
- Collections: https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/collections
- Files: https://learn.microsoft.com/dotnet/standard/io/how-to-write-text-to-a-file
- Exceptions: https://learn.microsoft.com/dotnet/standard/exceptions/best-practices-for-exceptions
- Classes: https://learn.microsoft.com/dotnet/csharp/fundamentals/types/classes
- Null safety: https://learn.microsoft.com/dotnet/csharp/nullable-references
- Records: https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/record

## Delivery and verification
Only author tutorials/csharp and source/csharp. Use no art (assets: []). Write/run source first,
then copy files and actual output into template sections. Verify main and solution once each with
small input through `python scripts/verify_labs.py csharp`; no test suites, no xUnit.
The project includes only a tiny plain-assert method exercised by its normal run.
Build three phase zips and the all-phases zip with `python scripts/build_packs.py csharp-101`.
Do not commit; stop after two failed fixes to the same issue. Do not edit shared tracking files.
