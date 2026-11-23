# Desktop C phase 2: HTTP and JSON client

Status: written (not run). No verification claim applies to this snapshot.

## Open
Extract the zip and open `02-http-and-json/code` in your editor. It holds the whole app at the end of chapter 02
(chapter 01 plus the HTTP wrapper, JSON models, API functions, worker thread and the connection panel), not a patch.
Read `tutorials/phase-2-http-json/02-http-and-json.md` in the capstone repository (`capstones/desktop-c`).

## Prerequisites
Everything from phase 1 (compiler, CMake, vcpkg with `VCPKG_ROOT` set). For the manual check a running platform and one
backend on port 8000 (`docker compose -p platform up -d --wait`, then a backend capstone's run command). Without a backend
the window still starts and the buttons show a transport problem, which is a useful test too.

## Later commands (not executed during this writing-only session)
From `02-http-and-json/code`:

```powershell
cmake --preset default
cmake --build --preset default
.\build\default\Debug\tasksteams.exe
```

Linux and macOS: `./build/default/tasksteams`. Exercise: `gcc -std=c17 -Wall -Wextra -o exercise exercise.c` in
`exercise/starter` or `exercise/solution`. Add the vcpkg baseline once with `vcpkg x-update-baseline --add-initial-baseline`
(chapter 01, step 2); the pack does not ship one.

## Chapter
02. HTTP and JSON, 150 minutes.

## Assets and secrets
No art assets. No secrets: this chapter sends no token. Never commit `build/`, `vcpkg_installed/` or any `.env` file.
