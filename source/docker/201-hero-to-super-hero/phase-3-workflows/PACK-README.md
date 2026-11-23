# Docker 201, Phase 3: Workflows

Source pack for lessons 08 to 10 of **Docker 201 (Hero to Super Hero)**. You need Docker 101 and phases 1 and 2 first.

> **Status: written but not yet run.** The code in this pack was prepared by reading it and the official documentation. It has not been executed yet. If something does not behave as described, trust your tool's real output and report it.

| Folder | What you build |
|---|---|
| `08-dev-containers` | A `.devcontainer/devcontainer.json`, a dev Dockerfile, a `compose watch` loop and a bind-mount loop |
| `09-ci-with-github-actions` | A GitHub Actions workflow that builds, tests, scans and publishes an image, and a Dependabot file |
| `10-backups-and-upgrades` | `pg_dump` backup and restore, a volume `tar` backup, a Postgres 16 to 17 upgrade, and cleanup |

## Inside each lesson folder
- `code/`: finished files, identical to the lesson text (including the hidden `.devcontainer` and `.github` folders; turn on "show hidden files" if you do not see them).
- `exercise/starter/` and `exercise/solution/`: the exercise and its answer.
- `verify.json`: a machine-readable list of the lesson's steps.

## Unzip and run
1. Docker 29.9.3 and Compose v5.7.0 (or newer) must be running.
2. Extract the zip and open a terminal in the lesson's `code` folder.
3. Lessons 08 and 10 need local settings: Windows PowerShell `Copy-Item .env.example .env` (lesson 10), macOS/Linux `cp .env.example .env`.
4. Lesson 08's dev container needs VS Code with the Dev Containers extension; every other step needs only Docker.
5. Lesson 09's workflow runs on GitHub: it needs a GitHub account and an empty practice repository. No password or token is stored: the workflow uses the temporary `GITHUB_TOKEN`.
6. Exercises: work in a `practice` copy, never in the pack originals.

## Safety
All passwords in this pack are public demonstration values. Lesson 10's `backups/` folder contains your data: it is git-ignored and must never be committed or shared. `down -v`, `volume rm` and any `prune --all` or `--volumes` command delete data; read the risk table in lesson 10 before using them.

Unity is never in Docker.
