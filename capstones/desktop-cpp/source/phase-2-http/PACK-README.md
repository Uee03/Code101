# Desktop C++ phase 2: HTTP and JSON client

Status: written (not run). No verification claim applies to this snapshot.

## Open
Extract the zip. Open `02-http-and-json-client/code`. The folder holds the whole project at the end of this chapter, not a patch.
Read `tutorials/phase-2-http/02-http-and-json-client.md` in the capstone repository.

## Prerequisites
Everything from phase 1, plus the platform running (`docker compose -p platform up -d --wait`) and one backend on `http://localhost:8000`.
Check with `curl http://localhost:8000/health`.

## Later commands (not executed during this writing-only block)
```powershell
cmake --preset windows
cmake --build --preset windows-debug
$env:SPDLOG_LEVEL = "debug"
.\build\windows\out\tasks_desktop.exe
```
Linux and macOS: the `linux` or `macos` presets. Settings: `API_BASE_URL` (default `http://localhost:8000`), `SPDLOG_LEVEL`.
The exercise is an overlay: copy `exercise/starter/src` or `exercise/solution/src` over `code/src`.

## Chapter
02. HTTP and JSON client, 90 minutes.

## Never ship
`build/`, `vcpkg_installed/`, `CMakeUserPresets.json`, log files, tokens.
