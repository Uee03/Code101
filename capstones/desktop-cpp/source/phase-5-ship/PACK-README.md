# Desktop C++ phase 5: Hardening and packaging

Status: written (not run). No verification claim applies to this snapshot.

## Open
Extract the zip. Open `05-hardening-and-packaging/code`. This is the finished app, with tests and release presets.
Read `tutorials/phase-5-ship/05-hardening-and-packaging.md` in the capstone repository.

## Prerequisites
Everything from phase 4 for the manual checks. The unit tests need no server.

## Later commands (not executed during this writing-only block)
```powershell
cmake --preset windows
cmake --build --preset windows-debug
ctest --preset windows

cmake --preset ship-windows
cmake --build --preset ship-windows
cpack --preset ship-windows
```
Linux and macOS: the `linux` and `macos` presets, and `ship-linux` or `ship-macos`.
The ZIP appears in `build/ship-<os>`.
The exercise copies two files: `exercise/starter/src` and `exercise/starter/tests` (or the `solution` folders) over `code/src` and `code/tests`, then re-run `cmake --preset <os>` so that the new test file is found.

## Chapter
05. Hardening and packaging, 90 minutes.

## Never ship
`build/`, `vcpkg_installed/`, `CMakeUserPresets.json`, log files, tokens, memory dumps.
