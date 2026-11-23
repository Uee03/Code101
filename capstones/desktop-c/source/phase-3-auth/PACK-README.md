# Desktop C phase 3: Auth (PKCE)

Status: written (not run). No verification claim applies to this snapshot.

## Open
Extract the zip and open `03-auth-pkce/code` in your editor. It holds the whole app at the end of chapter 03
(chapters 01 and 02 plus PKCE, the loopback listener, token handling, sign-in and sign-out), not a patch.
Read `tutorials/phase-3-auth/03-auth-pkce.md` in the capstone repository (`capstones/desktop-c`).

## Prerequisites
Everything from phases 1 and 2. For the manual check: the running platform (Keycloak on port 8180, realm `tasksteams`),
one backend on port 8000, a default browser, and the Keycloak client `tasks-desktop` imported from
`code/keycloak/tasks-desktop-client.json` (the chapter shows the admin-console steps). The platform files are not edited.
The fake test users and passwords are in the platform TDD, section 7 (local practice only).

## Later commands (not executed during this writing-only session)
From `03-auth-pkce/code`:

```powershell
cmake --preset default
cmake --build --preset default
.\build\default\Debug\tasksteams.exe
```

Linux and macOS: `./build/default/tasksteams`. Exercise: `gcc -std=c17 -Wall -Wextra -o exercise exercise.c`.
Clean up afterwards: close the window, `docker compose -p platform down -v --remove-orphans` if you started the platform.

## Chapter
03. Auth (PKCE), 150 minutes.

## Assets and secrets
No art assets. The pack contains no secret: the Keycloak client is public (no client secret exists), and tokens are only ever held
in memory at run time. Never paste a token into a bug report. Never commit `build/`, `vcpkg_installed/` or any `.env` file.
