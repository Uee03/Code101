# Desktop C phase 5: Hardening and packaging

Status: written (not run). No verification claim applies to this snapshot.

## Open
Extract the zip and open `05-hardening-and-packaging/code` in your editor. It holds the finished app: chapters 01 to 04 plus the
redacting logger, the leak report, hardening flags, the `asan` and `release` presets, install rules and the CPack zip.
Read `tutorials/phase-5-ship/05-hardening-and-packaging.md` in the capstone repository (`capstones/desktop-c`).

## Prerequisites
Everything from phases 1 to 4. For the sanitizer run: Linux with gcc or clang (AddressSanitizer and LeakSanitizer), or Windows
with a recent Visual Studio (AddressSanitizer, no leak detection). The manual checks need the running platform, one backend,
the imported Keycloak client and a browser, as in chapters 03 and 04.

## Later commands (not executed during this writing-only session)
From `05-hardening-and-packaging/code` (Windows PowerShell; Linux and macOS use `./build/<preset>/tasksteams`):

```powershell
cmake --preset default
cmake --build --preset default
$env:TASKS_LOG = "1"
.\build\default\Debug\tasksteams.exe

cmake --preset release
cmake --build --preset release
cmake --install build\release --config Release --prefix dist\tasksteams
cpack --config build\release\CPackConfig.cmake -C Release -B dist
```

Sanitizer build (Linux): `cmake --preset asan`, `cmake --build --preset asan`, `./build/asan/tasksteams`.
Exercise: `gcc -std=c17 -Wall -Wextra -o exercise exercise.c`; for the bug hunt also try `-fsanitize=address -g` on the starter.
Clean up afterwards: close the app, `docker compose -p platform down -v --remove-orphans`, delete `build/` and `dist/`.

## Chapter
05. Hardening and packaging, 120 minutes.

## Assets and secrets
No art assets. The package contains the executable, its libraries, `keycloak/tasks-desktop-client.json` (public configuration)
and `THIRD-PARTY-NOTICES.md`. It must never contain a token, a key, a `.env` file or debug symbols of a release you sign.
