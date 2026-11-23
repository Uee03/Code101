# Python track brief

**Audience 101:** anyone, any field, no coding experience. **201:** knows Python basics; wants to build real apps and APIs.
**301:** intermediate to senior: architecture, performance, production. Voice rules: `authoring-tutorials` skill.

**Version pins (verified 2026-11-23 on the author machine):** Python 3.12 or newer taught; author machine has 3.15.2.
Windows install uses the **Python install manager** (https://docs.python.org/3/using/windows.html).
Commands are written `python`; macOS/Linux learners type `python3`.

## Sources (Tier 1 first)
1. https://docs.python.org/3/ (tutorial, library, using/windows)
2. https://peps.python.org/pep-0008/ (style), pep-0020 (Zen), pep-0257 (docstrings)
3. FastAPI https://fastapi.tiangolo.com/ and Uvicorn https://www.uvicorn.org/ (201)
4. Real Python SOLID https://realpython.com/solid-principles-python/ (Tier 2, 301; site blocks scripts)

## Level 101 (12 lessons, 3 phases)
| Phase | # | Lesson | Goal |
|-------|---|--------|------|
| 1 Foundations | 01 | Hello, Python | install, terminal, editor, first program (`print`) |
| | 02 | Variables and types | str, int, float, bool, f-strings, reassignment |
| | 03 | Input and math | `input`, conversion, operators, tip calculator |
| | 04 | Making decisions | comparisons, and/or/not, if/elif/else, ticket machine |
| 2 Building blocks | 05 | Loops | `for`, `while`, `range`, break/continue, times-table, guessing game |
| | 06 | Functions | `def`, parameters, return, scope, reuse |
| | 07 | Lists and dictionaries | collections, indexing, loops over them, simple inventory |
| | 08 | Files | read/write text and CSV, `pathlib`, `with` |
| 3 Real programs | 09 | Handling errors | `try/except`, validating input (referenced from 03 and 04) |
| | 10 | Modules and packages | `import`, own modules and a regular package, standard library tour, `venv` + `pip` (pinned Colorama 0.4.6 installation practice) |
| | 11 | Classes basics | objects, attributes, methods |
| | 12 | Project: expense tracker | menu-driven console app with a CSV file and a tiny plain-`assert` self-check run with `python` (no pytest) |

## Level 201 / 301
Python 201 has its own [_BRIEF-201.md](_BRIEF-201.md) and [_STATE-201.md](_STATE-201.md): 11 lessons in four phases, written (not run). Python 301 is written (not run): see [_BRIEF-301.md](_BRIEF-301.md) and [_STATE-301.md](_STATE-301.md).

## Terminology (use consistently)
program, script, terminal, command, string, integer, float, boolean, variable, function, f-string. Full list: `GLOSSARY.md`.
