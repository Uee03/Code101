# Desktop C phase 1: Setup and window

Status: written (not run). No verification claim applies to this snapshot.

## Open
Extract the zip (Windows: Extract All; macOS: double-click; Linux: `unzip desktop-c-phase-1-setup.zip`).
Open the `01-setup-and-window/code` folder in your editor. It holds the whole app at the end of chapter 01, not a patch.
Read `tutorials/phase-1-setup/01-setup-and-window.md` in the capstone repository (`capstones/desktop-c`).

## Prerequisites
A C compiler and CMake 3.21 or newer (C 101 lesson 01), Git, a vcpkg checkout with `VCPKG_ROOT` set, network access for the
first configure (it builds SDL3, curl, cJSON and OpenSSL). Windows: Build Tools for Visual Studio (MSVC). Linux: the system
packages vcpkg names when SDL3 asks for them.

## Later commands (not executed during this writing-only session)
From `01-setup-and-window/code`:

```powershell
& "$env:VCPKG_ROOT\vcpkg.exe" x-update-baseline --add-initial-baseline
cmake --preset default
cmake --build --preset default
.\build\default\Debug\tasksteams.exe
```

Linux and macOS: `"$VCPKG_ROOT/vcpkg" x-update-baseline --add-initial-baseline`, then the same two cmake commands and
`./build/default/tasksteams`. The exercise needs only a C compiler: `gcc -std=c17 -Wall -Wextra -o exercise exercise.c`.

## Chapter
01. Setup and window, 90 minutes (the first vcpkg build adds waiting time).

## Assets and secrets
No art assets. No secrets exist in this chapter. Never commit `build/`, `vcpkg_installed/` or any `.env` file.
