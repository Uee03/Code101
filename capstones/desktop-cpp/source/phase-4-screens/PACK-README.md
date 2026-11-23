# Desktop C++ phase 4: Screens, threading and state

Status: written (not run). No verification claim applies to this snapshot.

## Open
Extract the zip. Open `04-screens-threading-state/code`. The folder holds the whole project at the end of this chapter, not a patch.
Read `tutorials/phase-4-screens/04-screens-threading-state.md` in the capstone repository.

## Prerequisites
Everything from phase 3: platform, one backend on port 8000, the imported `tasks-desktop` Keycloak client, a browser.
For the conflict check, start a second copy of the app.

## Later commands (not executed during this writing-only block)
```powershell
cmake --preset windows
cmake --build --preset windows-debug
.\build\windows\out\tasks_desktop.exe
```
Sign in as `carol`, open Mobile Team and its project, then create, edit, force a 412 with a second copy, and delete a task (the manual checklist is in the chapter).
The exercise is an overlay: copy `exercise/starter/src` or `exercise/solution/src` over `code/src`.

## Chapter
04. Screens, threading and state, 150 minutes.

## Never ship
`build/`, `vcpkg_installed/`, `CMakeUserPresets.json`, log files, tokens.
