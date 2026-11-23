---
track: capstone
level: 201
phase: 1
phase_name: setup
lesson: 01
title: "Setup and window"
time: 60 min
prerequisites: [cpp-101-12, platform-primers-01]
versions: { cpp: "20", cmake: "3.28+", vcpkg_baseline: "9eec002df1cd109f8f104cd966a763daf9751489", sdl3: "baseline port", imgui: "baseline port, sdl3 renderer backend" }
verified: not yet run
source: capstones/desktop-cpp/source/phase-1-setup/01-setup-and-window/
---

# 01. Setup and window

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## Why it matters
A C++ project is a build system, a dependency list and a few rules about who owns what before it is any code. If those are right on day one (one command to configure, one to build, no hand-released resources), every later chapter is only new code. This chapter builds the smallest real desktop app: an empty window that opens, draws a frame and closes cleanly.

## What you will build
A CMake project with a vcpkg manifest, three CMake presets (Windows, Linux, macOS), and a window made with SDL3 and Dear ImGui. Requirements: D-01, D-02, D-03 and the first part of D-25 (keyboard navigation, display scaling). The window says "Setup ready" and has a Quit button.

## Predict before you run
Before you build, write down: (1) which folder will hold the executable, (2) what you expect to see in the window, (3) what happens if you press Escape. Check yourself after "Run it". (Answers are in "How it works".)

## New C++ in this chapter
- **RAII** (resource acquisition is initialisation): an object acquires a resource in its constructor and releases it in its destructor, so the release can never be forgotten. You met it in lesson 09.
- **`std::unique_ptr` with a custom deleter**: a smart pointer that calls *your* function (here `SDL_DestroyWindow`) instead of `delete`.
- **`inline` functions in headers**: a function defined in a header must be `inline` so that several `.cpp` files can include it without breaking the one-definition rule.

## Before you start
- Read the [design](../../TDD.md) sections 1 to 4 (about 15 minutes).
- Tools: a C++20 compiler (Windows: Visual Studio 2022 or newer Build Tools with "Desktop development with C++"; macOS: `xcode-select --install`; Linux: GCC 12+ or Clang 15+), CMake 3.28 or newer, Git, and vcpkg (Step 1). Lesson `cpp/101` 01 shows the compiler and CMake setup.
- Extract `desktop-cpp-phase-1-setup.zip` and open the folder `01-setup-and-window/code`. Every pack is the whole project at that point, not a patch.
- All commands run from that `code` folder. The Windows commands are PowerShell. Do not type the prompt.

## Steps
### Step 1. Install vcpkg once
vcpkg is a package manager for C and C++ libraries. In *manifest mode* the project lists its libraries in `vcpkg.json` and vcpkg builds exactly those, inside the project's build folder.

**Command (Windows, PowerShell):**
```powershell
git clone https://github.com/microsoft/vcpkg.git "$HOME\vcpkg"
& "$HOME\vcpkg\bootstrap-vcpkg.bat" -disableMetrics
[Environment]::SetEnvironmentVariable('VCPKG_ROOT', "$HOME\vcpkg", 'User')
```
**Command (macOS and Linux):**
```bash
git clone https://github.com/microsoft/vcpkg.git "$HOME/vcpkg"
"$HOME/vcpkg/bootstrap-vcpkg.sh" -disableMetrics
echo 'export VCPKG_ROOT="$HOME/vcpkg"' >> ~/.profile
```
Close and reopen the terminal so that `VCPKG_ROOT` is set. Check with `echo $env:VCPKG_ROOT` (PowerShell) or `echo $VCPKG_ROOT`. Use a full clone, not a shallow one: the `builtin-baseline` in Step 3 is a commit id that must exist in your clone. On Linux you also need a few system packages (typically `build-essential`, `cmake`, `ninja-build`, `pkg-config`, `curl`, `zip`, `unzip`, `tar`); the first SDL3 build prints the extra development packages for X11 or Wayland that it misses, so install what it lists.

### Step 2. Create `CMakeLists.txt`
This file describes the build. Create it in the `code` folder.

**File: `CMakeLists.txt`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(tasks_desktop VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

find_package(SDL3 CONFIG REQUIRED)
find_package(imgui CONFIG REQUIRED)
find_package(spdlog CONFIG REQUIRED)

add_library(tasks_warnings INTERFACE)
target_compile_options(tasks_warnings INTERFACE
    $<$<CXX_COMPILER_ID:MSVC>:/W4 /permissive- /utf-8>
    $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-Wall -Wextra -Wpedantic>)

add_executable(tasks_desktop src/main.cpp src/app/App.cpp)
target_include_directories(tasks_desktop PRIVATE src)
target_link_libraries(tasks_desktop PRIVATE tasks_warnings SDL3::SDL3 imgui::imgui spdlog::spdlog)
```
Line by line: `cmake_minimum_required` pins the CMake features used. `project` names the build and the language. The three `CMAKE_CXX_*` lines ask for C++20, make it a requirement and switch off compiler-specific extensions (so `-std=c++20`, not `gnu++20`). `CMAKE_RUNTIME_OUTPUT_DIRECTORY` puts the program in `build/<preset>/out`; the `$<1:out>` generator expression stops Visual Studio from adding a `Debug` folder (the same trick as the C++ 101 lessons). `find_package(... CONFIG REQUIRED)` asks vcpkg's toolchain for each library and stops with an error if it is missing. `tasks_warnings` is an *interface library*: it holds only compile options, which any target can link to get the same warnings (`/W4 /permissive-` on MSVC, `-Wall -Wextra -Wpedantic` elsewhere; `/utf-8` makes MSVC read and write UTF-8). The executable lists its two source files; `target_include_directories(... src)` lets code write `#include "app/App.hpp"`.

### Step 3. Create `vcpkg.json`
**File: `vcpkg.json`**
```json
{
  "$schema": "https://raw.githubusercontent.com/microsoft/vcpkg-tool/main/docs/vcpkg.schema.json",
  "name": "tasks-desktop",
  "version": "0.1.0",
  "builtin-baseline": "9eec002df1cd109f8f104cd966a763daf9751489",
  "dependencies": [
    "sdl3",
    { "name": "imgui", "features": ["sdl3-binding", "sdl3-renderer-binding"] },
    "spdlog"
  ]
}
```
`name` must be lower case. `builtin-baseline` is a commit of the vcpkg repository (the 2026.10.16 release tag); it fixes the version of every package, so the build is the same next year. To update later, replace it with a newer release's commit id and rebuild. `sdl3` is the window and input library. `imgui` is Dear ImGui; its two *features* add the SDL3 platform backend and the SDL3 renderer backend, which are the glue files `imgui_impl_sdl3` and `imgui_impl_sdlrenderer3`. `spdlog` is the logger. Later chapters add `cpr`, `nlohmann-json`, `tl-expected`, `openssl`, `cpp-httplib` and `catch2` here.

### Step 4. Create `CMakePresets.json`
Presets store the long configure options in a file, so the command is `cmake --preset windows` and not a line of `-D` flags.

**File: `CMakePresets.json`**
```json
{
  "version": 6,
  "cmakeMinimumRequired": { "major": 3, "minor": 28, "patch": 0 },
  "configurePresets": [
    {
      "name": "base",
      "hidden": true,
      "binaryDir": "${sourceDir}/build/${presetName}",
      "toolchainFile": "$env{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake"
    },
    {
      "name": "windows",
      "displayName": "Windows, Visual Studio generator, static libraries",
      "inherits": "base",
      "condition": { "type": "equals", "lhs": "${hostSystemName}", "rhs": "Windows" },
      "cacheVariables": { "VCPKG_TARGET_TRIPLET": "x64-windows-static-md" }
    },
    {
      "name": "linux",
      "displayName": "Linux, Ninja Multi-Config",
      "inherits": "base",
      "generator": "Ninja Multi-Config",
      "condition": { "type": "equals", "lhs": "${hostSystemName}", "rhs": "Linux" },
      "cacheVariables": { "VCPKG_TARGET_TRIPLET": "x64-linux" }
    },
    {
      "name": "macos",
      "displayName": "macOS on Apple silicon, Ninja Multi-Config",
      "inherits": "base",
      "generator": "Ninja Multi-Config",
      "condition": { "type": "equals", "lhs": "${hostSystemName}", "rhs": "Darwin" },
      "cacheVariables": { "VCPKG_TARGET_TRIPLET": "arm64-osx" }
    }
  ],
  "buildPresets": [
    { "name": "windows-debug", "configurePreset": "windows", "configuration": "Debug" },
    { "name": "windows-release", "configurePreset": "windows", "configuration": "Release" },
    { "name": "linux-debug", "configurePreset": "linux", "configuration": "Debug" },
    { "name": "linux-release", "configurePreset": "linux", "configuration": "Release" },
    { "name": "macos-debug", "configurePreset": "macos", "configuration": "Debug" },
    { "name": "macos-release", "configurePreset": "macos", "configuration": "Release" }
  ]
}
```
`base` is hidden and shared: build folder `build/<preset name>` and the vcpkg *toolchain file*, which teaches CMake to run vcpkg during configure. The three OS presets each check `hostSystemName` in a `condition`, so only the preset for your machine is offered. `VCPKG_TARGET_TRIPLET` chooses how vcpkg builds libraries: `x64-windows-static-md` links libraries statically and the C++ runtime dynamically (one `.exe`, no extra DLLs); `x64-linux` and `arm64-osx` are static by default. On Intel macOS use `x64-osx`. Windows uses the default Visual Studio generator; Linux and macOS use Ninja Multi-Config, where one build folder holds Debug and Release. The six build presets pick the configuration.

### Step 5. Create `.gitignore`
**File: `.gitignore`**
```text
build/
vcpkg_installed/
CMakeUserPresets.json
*.log
.vs/
.idea/
.cache/
```
Build output, vcpkg's installed packages, your personal presets, logs and editor folders never go into Git.

### Step 6. Create `src/app/Theme.hpp`
**File: `src/app/Theme.hpp`**
```cpp
#pragma once

#include <imgui.h>

namespace tt {

// Colours and spacing for the whole app. `scale` is the display scale reported by SDL.
inline void applyTheme(ImGuiStyle& style, float scale) {
    ImGui::StyleColorsDark(&style);
    style.WindowRounding = 0.0F;
    style.FrameRounding = 4.0F;
    style.ItemSpacing = ImVec2{8.0F, 6.0F};
    style.Colors[ImGuiCol_Button] = ImVec4{0.20F, 0.45F, 0.80F, 1.0F};
    style.Colors[ImGuiCol_ButtonHovered] = ImVec4{0.28F, 0.55F, 0.92F, 1.0F};
    style.Colors[ImGuiCol_ButtonActive] = ImVec4{0.16F, 0.38F, 0.70F, 1.0F};
    style.ScaleAllSizes(scale);
    style.FontScaleDpi = scale;
}

}  // namespace tt
```
`#pragma once` stops a header from being included twice. `namespace tt` ("tasks and teams") keeps our names apart from other libraries. `ScaleAllSizes` multiplies paddings and spacings by the display scale, and `FontScaleDpi` scales the font, so the app is readable on a high-resolution screen (D-25). Colours are `ImVec4{red, green, blue, alpha}` from 0 to 1.

### Step 7. Create `src/app/Platform.hpp`
This is the heart of the chapter: three small classes that own SDL and Dear ImGui resources.

**File: `src/app/Platform.hpp`**
```cpp
#pragma once

#include "app/Theme.hpp"

#include <SDL3/SDL.h>
#include <imgui.h>
#include <imgui_impl_sdl3.h>
#include <imgui_impl_sdlrenderer3.h>

#include <memory>
#include <stdexcept>
#include <string>

namespace tt {

// SDL_Init and SDL_Quit as one object (C++ Core Guidelines R.1 and E.6).
class SdlRuntime {
public:
    SdlRuntime() {
        if (!SDL_Init(SDL_INIT_VIDEO)) {
            throw std::runtime_error(std::string{"SDL_Init failed: "} + SDL_GetError());
        }
    }
    SdlRuntime(const SdlRuntime&) = delete;
    SdlRuntime& operator=(const SdlRuntime&) = delete;
    ~SdlRuntime() { SDL_Quit(); }
};

// A window and its renderer. The renderer is declared last, so it is destroyed first.
class Window {
public:
    Window(const char* title, int width, int height) {
        window_.reset(SDL_CreateWindow(title, width, height, SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIGH_PIXEL_DENSITY));
        if (!window_) {
            throw std::runtime_error(std::string{"SDL_CreateWindow failed: "} + SDL_GetError());
        }
        renderer_.reset(SDL_CreateRenderer(window_.get(), nullptr));
        if (!renderer_) {
            throw std::runtime_error(std::string{"SDL_CreateRenderer failed: "} + SDL_GetError());
        }
        SDL_SetRenderVSync(renderer_.get(), 1);
        SDL_SetWindowMinimumSize(window_.get(), 640, 400);
    }

    [[nodiscard]] SDL_Window* window() const noexcept { return window_.get(); }
    [[nodiscard]] SDL_Renderer* renderer() const noexcept { return renderer_.get(); }

    [[nodiscard]] float displayScale() const noexcept {
        const float scale = SDL_GetWindowDisplayScale(window_.get());
        return scale > 0.0F ? scale : 1.0F;
    }

private:
    struct WindowDeleter {
        void operator()(SDL_Window* window) const noexcept { SDL_DestroyWindow(window); }
    };
    struct RendererDeleter {
        void operator()(SDL_Renderer* renderer) const noexcept { SDL_DestroyRenderer(renderer); }
    };

    std::unique_ptr<SDL_Window, WindowDeleter> window_;
    std::unique_ptr<SDL_Renderer, RendererDeleter> renderer_;
};

// The Dear ImGui context and its two backends for the lifetime of the object.
class ImGuiLayer {
public:
    ImGuiLayer(const Window& window, float scale) {
        IMGUI_CHECKVERSION();
        ImGui::CreateContext();
        ImGuiIO& io = ImGui::GetIO();
        io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
        io.IniFilename = nullptr;
        applyTheme(ImGui::GetStyle(), scale);
        if (!ImGui_ImplSDL3_InitForSDLRenderer(window.window(), window.renderer())) {
            ImGui::DestroyContext();
            throw std::runtime_error("Dear ImGui SDL3 backend failed to start");
        }
        if (!ImGui_ImplSDLRenderer3_Init(window.renderer())) {
            ImGui_ImplSDL3_Shutdown();
            ImGui::DestroyContext();
            throw std::runtime_error("Dear ImGui renderer backend failed to start");
        }
    }
    ImGuiLayer(const ImGuiLayer&) = delete;
    ImGuiLayer& operator=(const ImGuiLayer&) = delete;
    ~ImGuiLayer() {
        ImGui_ImplSDLRenderer3_Shutdown();
        ImGui_ImplSDL3_Shutdown();
        ImGui::DestroyContext();
    }

    void processEvent(const SDL_Event& event) { ImGui_ImplSDL3_ProcessEvent(&event); }

    void beginFrame() {
        ImGui_ImplSDLRenderer3_NewFrame();
        ImGui_ImplSDL3_NewFrame();
        ImGui::NewFrame();
    }

    void endFrame(SDL_Renderer* renderer) {
        ImGui::Render();
        SDL_SetRenderDrawColor(renderer, 24, 26, 30, 255);
        SDL_RenderClear(renderer);
        ImGui_ImplSDLRenderer3_RenderDrawData(ImGui::GetDrawData(), renderer);
        SDL_RenderPresent(renderer);
    }
};

}  // namespace tt
```
What each part does:
- `SdlRuntime`: the constructor starts SDL's video system and throws `std::runtime_error` if that fails (a constructor cannot return an error, so an exception is the right tool, rule E.2). The destructor calls `SDL_Quit`. Copying is deleted: two objects must not both quit SDL.
- `Window`: `std::unique_ptr<SDL_Window, WindowDeleter>` is "a pointer that calls `SDL_DestroyWindow` when it goes away". The window is created first and the renderer second; members are destroyed in *reverse* order of declaration, so the renderer goes first, which SDL requires. `SDL_WINDOW_HIGH_PIXEL_DENSITY` asks for a sharp window on high-DPI displays; `SDL_SetRenderVSync(..., 1)` waits for the monitor refresh so the loop does not spin a CPU core at 100 percent. `displayScale()` returns SDL's content scale for the window, or `1.0` if SDL reports nothing sensible. `[[nodiscard]]` makes the compiler warn if a caller ignores a returned value.
- `ImGuiLayer`: creates the context, enables keyboard navigation (Tab, arrows, Enter), sets `IniFilename = nullptr` so Dear ImGui does not write an `imgui.ini` file next to the program, applies the theme and starts both backends. If the second backend fails, the first is shut down before the exception leaves the constructor, because a destructor does not run for an object whose constructor threw. `beginFrame` and `endFrame` are the standard Dear ImGui frame: new frame, build widgets, render, clear the screen, draw the draw lists, present.

### Step 8. Create `src/app/App.hpp`
**File: `src/app/App.hpp`**
```cpp
#pragma once

#include "app/Platform.hpp"

namespace tt {

class App {
public:
    App();

    // Runs until the window is closed or Quit is pressed. Returns the process exit code.
    int run();

private:
    void drawFrame();

    SdlRuntime sdl_;
    Window window_;
    ImGuiLayer imgui_;
    bool quit_{false};
};

}  // namespace tt
```
The order of the three members is the order of construction (SDL, then window, then Dear ImGui) and, reversed, the order of destruction. That ordering is the whole shutdown logic.

### Step 9. Create `src/app/App.cpp`
**File: `src/app/App.cpp`**
```cpp
#include "app/App.hpp"

namespace tt {

App::App() : window_{"Tasks and Teams", 1100, 720}, imgui_{window_, window_.displayScale()} {}

int App::run() {
    while (!quit_) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            imgui_.processEvent(event);
            const bool closeRequested = event.type == SDL_EVENT_QUIT ||
                                        (event.type == SDL_EVENT_WINDOW_CLOSE_REQUESTED &&
                                         event.window.windowID == SDL_GetWindowID(window_.window()));
            if (closeRequested) {
                quit_ = true;
            }
        }
        if ((SDL_GetWindowFlags(window_.window()) & SDL_WINDOW_MINIMIZED) != 0) {
            SDL_Delay(50);
            continue;
        }
        imgui_.beginFrame();
        drawFrame();
        imgui_.endFrame(window_.renderer());
    }
    return 0;
}

void App::drawFrame() {
    const ImGuiViewport* viewport = ImGui::GetMainViewport();
    ImGui::SetNextWindowPos(viewport->WorkPos);
    ImGui::SetNextWindowSize(viewport->WorkSize);
    constexpr ImGuiWindowFlags kFlags =
        ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoSavedSettings;
    if (ImGui::Begin("Tasks and Teams", nullptr, kFlags)) {
        ImGui::TextUnformatted("Tasks and Teams");
        ImGui::Separator();
        ImGui::TextUnformatted("Setup ready: SDL3 and Dear ImGui are running.");
        const int sdl = SDL_GetVersion();
        ImGui::Text("SDL %d.%d.%d, Dear ImGui %s", SDL_VERSIONNUM_MAJOR(sdl), SDL_VERSIONNUM_MINOR(sdl),
                    SDL_VERSIONNUM_MICRO(sdl), IMGUI_VERSION);
        ImGui::Text("%.1f frames per second", ImGui::GetIO().Framerate);
        if (ImGui::Button("Quit")) {
            quit_ = true;
        }
    }
    ImGui::End();
}

}  // namespace tt
```
The constructor's member initialiser list builds `window_` and `imgui_` (`sdl_` is default-constructed first because it is declared first). `run()` is the *frame loop*: (1) drain the operating-system events and give each to Dear ImGui; a close request ends the loop, (2) skip drawing while the window is minimised, (3) draw one frame. `drawFrame` makes one borderless Dear ImGui window that fills the whole SDL window and prints a few lines. `TextUnformatted` prints a string as it is; `Text` takes a printf-style format string (never pass untrusted text as that first argument; later chapters always use `"%s"` or `TextUnformatted` for server text).

### Step 10. Create `src/main.cpp`
**File: `src/main.cpp`**
```cpp
#include "app/App.hpp"

#include <spdlog/spdlog.h>

#include <exception>

int main() {
    try {
        spdlog::set_pattern("%H:%M:%S.%e [%^%l%$] %v");
        spdlog::info("Tasks and Teams desktop starting");
        tt::App app;
        const int exitCode = app.run();
        spdlog::info("clean shutdown");
        return exitCode;
    } catch (const std::exception& error) {
        spdlog::critical("fatal: {}", error.what());
        return 1;
    }
}
```
`main` is only a safety net: any start-up exception from `SdlRuntime`, `Window` or `ImGuiLayer` is logged and becomes exit code 1. All the objects live inside `App`, so when `app` goes out of scope (normal return or exception) everything is released in reverse order. `{}` in an spdlog message is a placeholder filled by the next argument.

### Static comparison only (not a build)
This chapter's text was written from the files by hand. No static check, build or run was executed in this writing block (the repository owner's rule), so "typical" below means "what the code and the documentation say should happen".

## Run it
**For a later session only; this snapshot has not been run.** From the `code` folder.

**Command (Windows, PowerShell):**
```powershell
cmake --preset windows
cmake --build --preset windows-debug
.\build\windows\out\tasks_desktop.exe
```
**Command (Linux):**
```bash
cmake --preset linux
cmake --build --preset linux-debug
./build/linux/out/tasks_desktop
```
**Command (macOS):**
```bash
cmake --preset macos
cmake --build --preset macos-debug
./build/macos/out/tasks_desktop
```
Expected, typical: the first `cmake --preset` prints many lines while vcpkg downloads and compiles SDL3, Dear ImGui and spdlog (plan for a long wait the first time; later runs reuse the result) and ends with `Build files have been written to: ...`. The build ends without errors. Starting the program prints two log lines (`Tasks and Teams desktop starting` first) and opens a window titled "Tasks and Teams" with the text "Setup ready: SDL3 and Dear ImGui are running.", the SDL and Dear ImGui versions, a frame rate and a Quit button. Pressing Quit or closing the window prints `clean shutdown` and ends with exit code 0 (`$LASTEXITCODE` in PowerShell, `$?` in bash).

## How it works
- The answers to the prediction: (1) `build/<preset>/out`; (2) the text above; (3) nothing: Escape is not handled, only the close button, `SDL_EVENT_QUIT` and the Quit button end the program.
- One frame: events in, Dear ImGui builds a list of triangles from the widget calls, SDL's renderer draws the list. Dear ImGui is an *immediate-mode* library: the widget code runs every frame and `if (ImGui::Button("Quit"))` is both the drawing and the click handler. There is no widget tree to keep in sync with your data, which is why the later screens are only functions over plain structs.
- Shutdown is a consequence of member order. `App` destroys `imgui_`, then `window_` (renderer, then window), then `sdl_`. No `delete`, no `SDL_Destroy...` call is written by hand anywhere in the app (rules R.1 and R.11).
- Display scale: `SDL_GetWindowDisplayScale` is 1.0 on a standard display and larger on a scaled one; the theme multiplies sizes and font by it.

## Try it
Make the theme selectable. The exercise changes one file, `src/app/Theme.hpp`, and keeps the function signature, so the rest of the app does not change.

Where: the `code` folder. Copy the starter over your file, then edit it.

**Command (Windows, PowerShell):**
```powershell
Copy-Item ..\exercise\starter\src\app\Theme.hpp src\app\Theme.hpp -Force
```
**Command (macOS and Linux):**
```bash
cp ../exercise/starter/src/app/Theme.hpp src/app/Theme.hpp
```
**File: `../exercise/starter/src/app/Theme.hpp`**
```cpp
#pragma once

#include <imgui.h>

namespace tt {

// Exercise: make the theme selectable.
// Rung 1 (guided): change the three button colours to another accent colour.
// Rung 2 (partial): read the environment variable TASKS_THEME with SDL_getenv (include <SDL3/SDL.h>).
//   "light" selects ImGui::StyleColorsLight, anything else keeps ImGui::StyleColorsDark.
// Rung 3 (open): add "contrast" with black, white and yellow only, and work out the contrast ratio of your text colours.
inline void applyTheme(ImGuiStyle& style, float scale) {
    ImGui::StyleColorsDark(&style);  // TODO rung 2: choose by TASKS_THEME
    style.WindowRounding = 0.0F;
    style.FrameRounding = 4.0F;
    style.ItemSpacing = ImVec2{8.0F, 6.0F};
    style.Colors[ImGuiCol_Button] = ImVec4{0.20F, 0.45F, 0.80F, 1.0F};
    style.Colors[ImGuiCol_ButtonHovered] = ImVec4{0.28F, 0.55F, 0.92F, 1.0F};
    style.Colors[ImGuiCol_ButtonActive] = ImVec4{0.16F, 0.38F, 0.70F, 1.0F};
    style.ScaleAllSizes(scale);
    style.FontScaleDpi = scale;
}

}  // namespace tt
```
Try rung 1, then rung 2 (`$env:TASKS_THEME = "light"` in PowerShell, `export TASKS_THEME=light` in bash, then start the program), then rung 3. For rung 3 the WCAG contrast ratio is `(L1 + 0.05) / (L2 + 0.05)` with `L` the relative luminance; aim for at least 4.5 for normal text.

<details><summary>Solution (rungs 1 to 3)</summary>

**File: `../exercise/solution/src/app/Theme.hpp`**
```cpp
#pragma once

#include <SDL3/SDL.h>
#include <imgui.h>

#include <string_view>

namespace tt {

// Chooses the colour set from the environment variable TASKS_THEME ("light", "contrast" or anything else for dark).
inline void applyTheme(ImGuiStyle& style, float scale) {
    const char* raw = SDL_getenv("TASKS_THEME");
    const std::string_view theme = raw != nullptr ? raw : "";
    if (theme == "light") {
        ImGui::StyleColorsLight(&style);
    } else {
        ImGui::StyleColorsDark(&style);
    }
    style.WindowRounding = 0.0F;
    style.FrameRounding = 4.0F;
    style.ItemSpacing = ImVec2{8.0F, 6.0F};
    style.Colors[ImGuiCol_Button] = ImVec4{0.20F, 0.45F, 0.80F, 1.0F};
    style.Colors[ImGuiCol_ButtonHovered] = ImVec4{0.28F, 0.55F, 0.92F, 1.0F};
    style.Colors[ImGuiCol_ButtonActive] = ImVec4{0.16F, 0.38F, 0.70F, 1.0F};
    if (theme == "contrast") {
        style.Colors[ImGuiCol_WindowBg] = ImVec4{0.0F, 0.0F, 0.0F, 1.0F};
        style.Colors[ImGuiCol_Text] = ImVec4{1.0F, 1.0F, 1.0F, 1.0F};
        style.Colors[ImGuiCol_Button] = ImVec4{0.0F, 0.0F, 0.0F, 1.0F};
        style.Colors[ImGuiCol_ButtonHovered] = ImVec4{0.35F, 0.35F, 0.0F, 1.0F};
        style.Colors[ImGuiCol_ButtonActive] = ImVec4{1.0F, 1.0F, 0.0F, 1.0F};
        style.Colors[ImGuiCol_Border] = ImVec4{1.0F, 1.0F, 0.0F, 1.0F};
        style.FrameBorderSize = 1.0F;
    }
    style.ScaleAllSizes(scale);
    style.FontScaleDpi = scale;
}

}  // namespace tt
```
`SDL_getenv` returns a null pointer when the variable is unset, so the code turns that into an empty `std::string_view` before comparing. White text on black has the maximum ratio of 21:1; the yellow border and active button give a second, non-colour cue because the frame border is drawn. Check the active button label yourself: black text on yellow is also well above 4.5.

</details>

Both exercise folders also hold a short README that says they are overlays on `src/`, not projects.

## Check yourself
1. Why is `builtin-baseline` in `vcpkg.json`?
   <details><summary>Answer</summary>It pins every library to the version in one vcpkg commit, so the build is repeatable.</details>
2. Why does `Window` declare the renderer after the window?
   <details><summary>Answer</summary>Members are destroyed in reverse order, so the renderer is destroyed before the window it draws into.</details>
3. What happens if `SDL_CreateRenderer` fails inside `Window`'s constructor?
   <details><summary>Answer</summary>The constructor throws; the already built `window_` member is destroyed by its `unique_ptr`; `main` logs the error and returns 1.</details>
4. Why `IniFilename = nullptr`?
   <details><summary>Answer</summary>So that Dear ImGui does not write a settings file next to the executable.</details>

## Common mistakes
| Symptom (typical message) | Cause | Fix |
|---|---|---|
| CMake says it cannot find `VCPKG_ROOT` or the toolchain file | the variable is not set in this terminal | set it (Step 1) and open a new terminal |
| vcpkg reports that the baseline commit is unknown | shallow clone of vcpkg | `git -C $HOME/vcpkg fetch --unshallow` or clone again |
| Configure fails inside the SDL3 port on Linux | system development packages missing | install the packages the vcpkg log lists, then configure again |
| `Could not find a package configuration file provided by "imgui"` | the manifest feature list was edited | restore the `features` array of Step 3 |
| Linker error for `ImGui_ImplSDL3_...` | `sdl3-binding` or `sdl3-renderer-binding` missing | restore the `features` array |
| The window opens and closes at once | an exception was thrown: read the `fatal:` log line | the message names the SDL call that failed |

## Best practice
- C++ Core Guidelines R.1 (manage resources with RAII), R.11 (no explicit `new` and `delete`), R.20 (ownership is a smart pointer), E.2 and E.6 (constructors throw; clean up what was built before the throw), ES.23 (prefer `{}` initialisation), F.4 (`constexpr` where possible). Read them at https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines.
- Turn warnings on at the start of a project; fixing them later costs more.
- Keep the vcpkg baseline in Git and change it on purpose, not by accident.
- Keep third-party types (SDL pointers) inside small owner classes; the rest of the app should not see `SDL_Window*`.

## Going further
- Why no `CMAKE_BUILD_TYPE`? Visual Studio and Ninja Multi-Config choose the configuration at build time (`--config` or the build preset); read the "multi-config generator" part of the CMake manual.
- Binary caching makes the second machine's first configure fast: search "vcpkg binary caching" in the vcpkg docs.
- Press the window's maximise button and watch the fonts: they come from the display scale, not from a fixed size.

## Summary
You have a reproducible C++20 build (manifest, baseline, presets, warnings) and a window whose every resource is owned by an RAII type, so a clean exit is automatic. No file in the app calls a destroy function by hand.

## Next lesson
[02. HTTP and JSON client](../phase-2-http/02-http-and-json-client.md): the same window gains a typed API client that talks to the backend and shows RFC 9457 problems.
