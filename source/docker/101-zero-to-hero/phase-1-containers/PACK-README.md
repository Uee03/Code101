# Docker 101, Phase 1: Containers

Source pack for lessons 01 to 04 of **Docker 101 (Zero to Hero)**.

| Folder | What you build |
|---|---|
| `01-what-is-a-container` | Install Docker and run hello-world |
| `02-images-and-containers` | nginx and a complete container lifecycle |
| `03-your-first-dockerfile` | Your own Python web image |
| `04-data-that-survives` | Persistent volume and read-only bind mount |

## Inside each lesson
- `code/`: finished files, identical to the lesson. For lessons 01/02/04, the .ps1 file is a PowerShell command checklist.
  macOS/Linux learners type the Docker commands from the lesson; the bind path substitution is shown there.
- `exercise/starter/`: runnable baseline, with the exercise's target values already listed for the lifecycle drills.
- `exercise/solution/`: finished answer. Try first, then compare; Compose exercises change only the specified file(s).
- `verify.json`: maintainer smoke specification; starts temporary resources and always cleans up, including built images.

## Unzip and run
1. Install Docker following lesson 01. Author baseline (2026-11-23): Windows 11, Engine/CLI 29.9.3,
   Desktop 4.99.0, Compose v5.7.0, WSL2 Ubuntu-26.04. The engine must be running (`docker info`).
2. Windows: right-click the zip > **Extract All**; macOS: double-click; Linux: archive manager > **Extract**
   (or `unzip <pack>.zip`). Open the extracted phase folder, then the lesson's `code` folder.
3. Open a terminal in `code`: PowerShell on Windows, Terminal on macOS/Linux. Do not run from the phase root.
4. Follow that lesson's **Run it** commands in order. Docker commands are identical across systems unless noted.
   Windows uses `curl.exe`; macOS/Linux use `curl`. Ubuntu Engine users prefix Docker commands with `sudo`.
5. Stop the lesson before starting the next: all web lessons use **127.0.0.1:8080** (lesson 02 exercise uses 8081).
   Postgres is never published to the host; 5432 is reserved for the Databases track.
6. Exercises: copy every starter file (including dotfiles/subfolders) into your own `practice` folder;
   open a terminal there, apply the lesson's changes, run, then clean up using the same resource/project names.

## Settings and safety
All .env values and the secret file in this pack are **public demonstration values**, never real credentials.
The pack ships `.env.example`, not `.env`. Before running a lesson's `docker compose` commands, copy it: Windows PowerShell `Copy-Item .env.example .env`; macOS and Linux `cp .env.example .env`.
Your project should track only .env.example, not real .env files or secrets. Do not reuse the demo password.
Optional Windows .wslconfig and Linux repository configuration in lesson 01 are documentation examples,
not automatically applied by the lab. Do not overwrite an existing machine configuration.
macOS/Linux install routes are official-docs checked; only Windows lab execution is verified.
No art is used. Images use explicitly checked version-family tags, which can receive patch updates.

## Cleanup (do not skip)
Lessons 01-04 list exact container names and explicit rm/volume-rm commands in the tutorial.
For Compose, run from the same code/practice folder with the **same -p project name** used at startup:

```text
docker compose -p <project-name-from-the-lesson> down -v --remove-orphans
docker image rm <project-name-from-the-lesson>-web:demo
```

`-v` permanently deletes this project's database data: omit it to preserve valuable data, and back up first.
Do not use global prune to clean one lesson. The labels/names code101-verify-* identify temporary course work,
not permission to delete unrelated resources. The maintainer verifier also removes the code image before rebuilding
an exercise image so no previous build is stranded. Base image downloads and the builder's reusable cache are separate.

## Maintainer verification
Windows, repository root: `python scripts/verify_labs.py source/docker/101-zero-to-hero/PHASE/LESSON`.
A PASS means code and solution smoke-run, expected outputs appear in the tutorial, and code matches the tutorial.
Verification is not a production audit or a unit-test suite.

Verification status: **4/4 verified**, 2026-11-23, Windows 11, Docker 29.9.3, Compose v5.7.0; code and exercise solutions passed scripts/verify_labs.py.
