# Lessons learned (from the Python 101 beginner walk-through, 35 findings)

Read before writing any lesson. Each rule exists because a real reader would have been stuck without it.

## Order and definitions
1. **Introduce a tool before it is used.** Open the terminal before installing anything that is checked in the terminal. Install the editor
   before the step that uses `code .`. Never use a word (terminal, `>>>`, `exit()`, PATH) before the step that explains it.
2. **Every term in a "New terms" list is defined in the text** (one sentence each) and added to the track `GLOSSARY.md`.
3. **Exercises use only what the lesson taught.** If the starter nests calls, the steps must have shown nesting first.
4. **No forward promises without a lesson number** ("lesson 09 covers errors") and the target lesson must exist in `_BRIEF.md`.

## Logistics a first-timer cannot guess
5. Say exactly **where** a file goes and **which folder** the terminal must be in. Tell how to know the current folder (the text before `>` or `$`)
   and give the recovery command (`cd ~/code101/lesson01`).
6. Say how to **unzip** a pack (Windows: right-click, Extract All; macOS: double-click; Linux: `unzip`) and to **copy** exercise starters into the
   learner's own lesson folder before running them.
7. After installing a tool, tell the learner to **close the terminal and open a new one**; old terminals do not see new PATH entries.
8. Unsaved files: tell learners a dot on the editor tab means "not saved".
9. Time estimates are for a first-timer. Setup lessons are 45 minutes or more; split a lesson that mixes installation and a first program if needed.
10. Give one install route per OS with exact button names; official docs link for anything else. Check install steps against the official docs
    at writing time (installers change: e.g. Python on Windows is now the Python install manager).

## Output and errors must be real
11. **Run it, capture it.** Every "Expected output" and every "Common mistakes" error text must come from running the code (trigger the
    error on purpose). Never write an error message from memory. Platform differences count (`mkdir` prints a table on Windows PowerShell).
12. Common mistakes should list the **likeliest** beginner errors first: missing colon/brace, wrong folder, unsaved file, still inside a REPL,
    typing `$80` or `15%` where a number is expected, wrong capitalisation, forgotten quote, tool not on PATH (open a new terminal).
    Do not list an error that cannot happen or whose message you did not see.

## Writing files and checks
13. Write files with the editor tools (UTF-8 **without BOM**). Windows PowerShell 5.1 `Set-Content -Encoding utf8` adds a BOM, which the verifier rejects.
14. The lesson text must contain **every non-blank line** of every file in `code/` and each expected output (the verifier checks this). Paste from
    the file; do not retype.
15. When capturing output in PowerShell, `2>&1` on a native command prints `NativeCommandError` noise; use `cmd /c "<command> 2>&1"` to see the plain text.
16. Refresh PATH in your own shell when a tool was installed recently:
    `$env:Path=[Environment]::GetEnvironmentVariable('Path','Machine')+';'+[Environment]::GetEnvironmentVariable('Path','User')`.
    `verify_labs.py` does this itself.
## Verification policy (user instruction, 2026-11-23: supersedes the earlier smoke-test rules)

**Do not run smoke tests.** Authors write the lessons and the source code and do **not** execute the code, build projects, start servers or use Docker.

**Honesty rule that makes this acceptable:** every lesson written under this policy carries, directly under the title, this notice (verbatim):

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

and front matter `verified: not yet run`. The notice is removed only by the verifier run that sets `verified:` to a real date. This way no learner or reviewer is misled, and the lessons can be written now and run later.
Reason carefully instead: write small, conventional code; derive expected output by reading the code; use only APIs you checked in the official docs.
The only check allowed is the static one, which executes nothing:

```
python scripts\verify_labs.py --static <filter>     # lesson text must contain every code line and expected output; verify.json must parse
```

- Still write a `verify.json` for every lesson so it can be run later; set front matter `verified: not yet run` and `_STATE.md` status `written (not run)`.
- Never invent output you cannot derive from the code. When unsure, show the output with the note "expected output, not yet run" and prefer deterministic programs.
- Never paste "real captured" error text you did not capture: for Common mistakes use only error messages you know exactly from official docs or earlier verified lessons,
  and mark others "typical message".
- Earlier verified lessons (101 level tracks, platform and backend capstones) remain marked verified.

## 17 (old rule, replaced by the policy above). Verification is a **smoke test** (see the `verifying-labs` skill): run the code once with small input; no test suites; Docker labs are temporary and
    always cleaned up.

## Added after the 5-track beginner walk-through (about 180 findings)
18. **Say where the source pack is, and make it optional.** Every lesson's "Before you start" has the standard sentence from the lesson template (repository
    `https://github.com/Uee03/Code101`, folder `source/<track>/...`, Code > Download ZIP or `git clone`). Every file and starter is shown in the lesson, so a learner
    can follow without the pack. Never write "download the pack to Downloads" without a source. The learner text never mentions maintainer commands
    (`verify_labs.py`, `build_packs.py`, "Maintainer smoke result").
19. **Copy instructions for starters must be exact:** "copy the `starter` folder and rename it `try01`" (copying it *into* `try01` breaks paths such as `go.mod`).
20. **Common mistakes rows must be reproducible by that lesson's own code.** Trigger each one and paste the real text. Never write placeholder causes ("see the
    failing line"). Always cover the likeliest first-timer errors for that lesson: wrong folder, unsaved file, missing colon/brace/semicolon, typing `$80` or `15%`
    for a number, wrong capitalisation, running the wrong command (`go run main.go`, `python` still at the `>>>` prompt, `npx tsc` outside the project).
    Remove rows for errors the finished code cannot produce, and never include the author's machine paths in captured output (replace with `<project>`).
21. **Honest times.** Time = first-timer reading plus typing plus running plus exercise. Use about 5 minutes per new idea plus 10 for setup per tool. A lesson
    with more than 5 new ideas is split or trimmed. Project lessons may take 60 to 90 minutes: say "two sittings" and mark the break point in the text.
22. **Define before use**, including small words: sequence, caller, body, viewport, DevTools, nil map, method, octal, insertion order, lifetime. If a term appears
    in "New terms", it is defined in the text.
23. **Do not give the exercise answer away in the Try it text.** Describe the goal and the expected output, not the code.
24. **Platform traps to show next to the first command:** PowerShell `npm.ps1 cannot be loaded` (use `npm.cmd` or fix the execution policy), the Microsoft Store
    `python` alias, Restricted execution policy blocking `.venv\Scripts\Activate.ps1`, first-run banners (`dotnet` telemetry and HTTPS certificate notice), VS Code
    workspace trust prompt, extension sign-in prompts (C# Dev Kit), hidden file extensions on Windows.
25. **Repeated boilerplate:** when a project file is genuinely identical to an earlier lesson's, say so, list the differences, and put the file in
    `skip_lesson_check` (the user's "genuinely identical steps" rule). Never repeat a 60-line block in 11 lessons.
26. **Run the walkthrough yourself before finishing:** type the lesson's steps literally in a clean folder (not from `code/`), at least for lessons 01 and the project lesson.
27. **Side effects:** tests and walk-throughs must not change the learner's or author's machine (no installing certificates, no global tools, no PATH edits).
