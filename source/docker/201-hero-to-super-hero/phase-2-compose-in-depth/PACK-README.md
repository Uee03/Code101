# Docker 201, Phase 2: Compose in depth

Source pack for lessons 05 to 07 of **Docker 201 (Hero to Super Hero)**. You need Docker 101 and phase 1 first.

> **Status: written but not yet run.** The code in this pack was prepared by reading it and the official documentation. It has not been executed yet. If something does not behave as described, trust your tool's real output and report it.

| Folder | What you build |
|---|---|
| `05-profiles-overrides-extensions` | One base Compose file with a development override, a production override, profiles and extension fields |
| `06-secrets-and-configs` | A file secret for the app and Postgres, a Compose config, and a build secret |
| `07-networking-and-limits` | A frontend network, an internal backend network, loopback publishing, resource limits and a full `.wslconfig` example |

## Inside each lesson folder
- `code/`: finished files, identical to the lesson text. The pack ships `.env.example` and `*.example` secret files, never real `.env` or secret files.
- `exercise/starter/` and `exercise/solution/`: the exercise and its answer (often only the changed files).
- `verify.json`: a machine-readable list of the lesson's steps.

## Unzip and run
1. Docker 29.9.3 and Compose v5.7.0 (or newer) must be running.
2. Extract the zip (Windows: **Extract All**; macOS: double-click; Linux: `unzip`). Open a terminal in the lesson's `code` folder.
3. Create your local settings first. Windows PowerShell: `Copy-Item .env.example .env`. macOS/Linux: `cp .env.example .env`. Lesson 06 also needs the copies of the two files in `secrets/` named in that lesson.
4. Follow **Run it**. Use the same project folder for every command of a lesson.
5. All web lessons publish `127.0.0.1:8080` (the lesson 05 staging exercise uses 8081). Stop one lesson (`docker compose down`) before starting the next. Postgres is never published to the host.
6. Exercises: work in a `practice` copy, never in the pack originals.

## Settings and safety
Every password and token in this pack is a **public demonstration value**, never a real credential. Your own projects should track `.env.example` and keep real `.env` files and secret files out of Git.

`down -v` deletes the project's named volumes and their data. It is used here only on throwaway databases.

The optional `wslconfig.example` in lesson 07 is a documentation example: it is not applied automatically and you must not overwrite an existing `.wslconfig` without a backup.
