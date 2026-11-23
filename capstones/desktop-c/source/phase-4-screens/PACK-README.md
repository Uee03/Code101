# Desktop C phase 4: Screens and state

Status: written (not run). No verification claim applies to this snapshot.

## Open
Extract the zip and open `04-screens-and-state/code` in your editor. It holds the whole app at the end of chapter 04
(chapters 01 to 03 plus the store's task operations and the three-column workspace), not a patch.
Read `tutorials/phase-4-screens/04-screens-and-state.md` in the capstone repository (`capstones/desktop-c`).

## Prerequisites
Everything from phases 1 to 3, including the imported Keycloak client `tasks-desktop` (`code/keycloak/tasks-desktop-client.json`)
and a running platform with one backend (Python, ASP.NET, Go or Rust; the desktop app has no Rust restriction).
Test users: alice (admin), bob and carol (members); fake passwords are in the platform TDD, section 7 (local practice only).

## Later commands (not executed during this writing-only session)
From `04-screens-and-state/code`:

```powershell
cmake --preset default
cmake --build --preset default
.\build\default\Debug\tasksteams.exe
```

Linux and macOS: `./build/default/tasksteams`. Exercise: `gcc -std=c17 -Wall -Wextra -o exercise exercise.c`.
Clean up afterwards: close the window, `docker compose -p platform down -v --remove-orphans`.

## Chapter
04. Screens and state, 180 minutes.

## Assets and secrets
No art assets and no secrets. The Keycloak client file is public configuration. Never commit `build/`, `vcpkg_installed/`
or any `.env` file, and never paste tokens into a bug report.
