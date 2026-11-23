---
name: verifying-labs
description: 'Runs and checks every lab in a Code101 lesson in a clean folder using scripts/verify_labs.py and each lesson verify.json. Use when a lesson is written, before marking it verified, after changing source code, or when the user says verify, test the lab, does the code run, or check the source pack.'
---

# Verifying labs

**Best model:** Act tier (GPT-6.1 Sol) via the Lab Verifier. It never edits lesson text.

A lesson is `verified` only when `python scripts/verify_labs.py <path>` prints PASS.

## What the script checks

1. Copies the lesson folder to a temp directory (clean room: no `.venv`, no build output) and runs each step in `verify.json`.
2. The exit code, `expect_stdout` (exact, after normalising line ends) and `expect_contains` match.
3. Every expected output also appears in the lesson markdown, so the "Expected output" shown to learners is real.
4. Every non-blank line of every text file in `code/` appears in the lesson markdown, so lesson and source agree.
5. Missing tools give **UNVERIFIED** (not a pass): install the tool, or record it in `_STATE.md`.

## Verification scope (user rule): smoke test only

Verification proves the **environment works and the code runs once** with a small input. Do **not** run unit-test suites, linters or benchmarks
in `verify.json` (lessons may still teach testing). Check the toolchain version only when a lesson installs it.

## Docker and Compose labs are temporary

- Start under the throwaway project `-p {project}` (the verifier fills it as `code101-verify-<lesson>`), probe once (use `retries` for health),
  and put `docker compose -p {project} down -v --remove-orphans` in `cleanup`, which runs even when a step fails. Never leave containers,
  networks, volumes or images created only for verification behind (`docker image rm` the ones you built, if any).
- Do not publish a host port that another lab uses (CONTEXT.md port table). Docker 101 labs do not publish Postgres.
- If the Docker engine is not running, the lesson is UNVERIFIED (requires `docker` and a `docker info` step); never fake a pass.
- Unity is never run in Docker.

## `verify.json`

```json
{
  "requires": ["python"],
  "steps": [
    { "name": "run", "cwd": "code", "cmd": "{python} main.py", "stdin": "Ada\n",
      "expect_stdout": "What is your name? Hello, Ada!" },
    { "name": "solution", "cwd": "exercise/solution", "cmd": "{python} main.py", "expect_contains": ["Done"] },
    { "name": "serve", "cwd": "code", "cmd": "{python} -m http.server 18765", "bg": true, "wait": 1 },
    { "name": "probe", "cmd": "curl -s http://127.0.0.1:18765/", "retries": 10, "retry_delay": 1 }
  ],
  "cleanup": [ { "name": "down", "cwd": "code", "cmd": "docker compose -p {project} down -v --remove-orphans" } ],
  "skip_lesson_check": ["code/data.csv"]
}
```

`bg` starts a server and kills its process tree at the end. `retries` repeats a step until it passes. `cleanup` always runs.
`"exclusive": "tasksteams"` takes a cross-process lock (`scripts/stack_lock.py`) so labs that share host ports (capstones: 8000, 8180, 5432) never run at the
same time, even when several authors work in parallel. **Every capstone lab that starts the platform stack must set it.** To run any one-off command
that touches those ports while debugging, wrap it: `python scripts/stack_lock.py tasksteams -- <command>`; otherwise you may clash with another run.
Always verify the **solution** too (a second step with `cwd: exercise/solution`). Interactive programs use `stdin`.
When `input()` shows a prompt, the prompt appears in stdout without a newline; account for it in `expect_stdout`.

## Per-language smoke commands

| Track | Smoke steps (one run, small input) |
|-------|------------------------------------|
| Python | `{python} main.py` |
| C# | `dotnet run --project <proj> --nologo` (no `dotnet test`) |
| Node / TypeScript / Angular / React | `npm ci` (or `npm install`), `npm run build` once, or `node file.js` |
| Go | `go run .` |
| Rust | `cargo run --quiet` |
| C / C++ | `cmake -S . -B build`, `cmake --build build`, run the binary once |
| Flutter | `flutter analyze` once, or `dart run` |
| Kotlin | `./gradlew assembleDebug` once |
| Docker | `docker compose -p {project} up -d --build`, one `curl` probe, then `cleanup` |
| SQL | start a throwaway Postgres container (`cleanup` removes it), run the script, `SELECT` once |

## Report

```
Lesson | Result | Failing step | Cause
```
List unverified lessons with the missing tool. Never claim a pass without running the script.
