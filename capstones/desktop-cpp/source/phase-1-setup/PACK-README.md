# Desktop C++ phase 1: Setup and window

Status: written (not run). No verification claim applies to this snapshot.

## Open
Extract the zip. Open `01-setup-and-window/code` in your editor or terminal. The folder holds the whole project at the end of this chapter, not a patch.
Read `tutorials/phase-1-setup/01-setup-and-window.md` in the capstone repository.

## Prerequisites
A C++20 compiler (Visual Studio 2022 or newer with the C++ workload, GCC 12+ or Clang 15+), CMake 3.28+, Git, and vcpkg with `VCPKG_ROOT` set (lesson step 1).
Linux needs a few system packages for SDL3; the first configure lists what is missing.

## Later commands (not executed during this writing-only block)
From `01-setup-and-window/code`:

```powershell
cmake --preset windows
cmake --build --preset windows-debug
.\build\windows\out\tasks_desktop.exe
```
Use the `linux` or `macos` presets on those systems. The first configure builds every dependency and takes a long time; later runs reuse the result.
The exercise is an overlay: copy `exercise/starter/src` over `code/src`, or `exercise/solution/src` to see the answer.

## Chapter
01. Setup and window, 60 minutes.

## Never ship
`build/`, `vcpkg_installed/`, `CMakeUserPresets.json`, log files, tokens.
