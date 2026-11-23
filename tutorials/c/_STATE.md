# C track state

Last updated: 2026-11-23.

## 101 Zero to Hero

C17, console programs, standard library only. 12 lessons, three phases. Nothing has been compiled or run (writing-brief rule): every lesson
carries the draft notice and `verified: not yet run`.

| Lesson | Phase | Status | Verified |
|---|---|---|---|
| 01-hello-c | phase-1-foundations | written (not run) | not yet run |
| 02-types-printf-scanf | phase-1-foundations | written (not run) | not yet run |
| 03-making-decisions | phase-1-foundations | written (not run) | not yet run |
| 04-loops | phase-1-foundations | written (not run) | not yet run |
| 05-functions | phase-2-building-blocks | written (not run) | not yet run |
| 06-arrays-and-strings | phase-2-building-blocks | written (not run) | not yet run |
| 07-pointers | phase-2-building-blocks | written (not run) | not yet run |
| 08-structs | phase-2-building-blocks | written (not run) | not yet run |
| 09-headers-and-multiple-files | phase-2-building-blocks | written (not run) | not yet run |
| 10-memory-and-bugs | phase-3-real-programs | written (not run) | not yet run |
| 11-files | phase-3-real-programs | written (not run) | not yet run |
| 12-expense-tracker | phase-3-real-programs | written (not run) | not yet run |

## To do when checks are allowed
- `python scripts\verify_labs.py --static source/c/` (lesson text vs code files), then `python scripts\verify_labs.py source/c/` on a machine with gcc.
- Capture the real output of every Common mistakes row marked "typical message"; replace with exact text, then remove the draft notice and set `verified:`.
- Run the Makefile (09, 12) and CMake (12) steps on Windows (MSYS2 and MSVC), macOS and Linux; confirm the MSYS2 package names and PATH steps against current docs.
- Confirm that `app` / `app.exe` behaviour with `mingw32-make` (always relinks) is as described in lesson 09.
- Build packs: `python scripts\build_packs.py c-101` (not run).

## Decisions
- 12 lessons (not 14): install and hello world share lesson 01; Makefile is taught inside lesson 09, CMake inside the project lesson 12.
- Windows: MSYS2 gcc is the main route (same commands as macOS/Linux); MSVC `cl` is shown beside every build command that differs.
- Starter folders compile and run; their TODO comments state the goal, not the code.
