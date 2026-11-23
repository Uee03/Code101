# Version evidence (desktop-cpp)

Read on 2026-11-23 from the official sources named below. Nothing was installed or built.

| Item | Value | Source |
|------|-------|--------|
| vcpkg registry baseline | commit `9eec002df1cd109f8f104cd966a763daf9751489` (release tag `2026.10.16`, published 2026-10-20) | https://github.com/microsoft/vcpkg/releases |
| imgui port | 1.93.0 on the vcpkg master branch at reading time; features `sdl3-binding` and `sdl3-renderer-binding` exist | `ports/imgui/vcpkg.json` |
| sdl3 port | 3.4.20 on master at reading time; CMake target `SDL3::SDL3` | `ports/sdl3/vcpkg.json`, `ports/sdl3/usage` |
| cpr port | 1.15.1 on master at reading time; default feature `ssl` | `ports/cpr/vcpkg.json` |
| cpp-httplib | CMake target `httplib::httplib` | `ports/cpp-httplib/usage` |
| tl-expected | `find_package(tl-expected CONFIG REQUIRED)`, target `tl::expected` | `ports/tl-expected/portfile.cmake` (config path `share/cmake/tl-expected`) |
| nlohmann-json, spdlog, openssl, catch2 | `nlohmann_json::nlohmann_json`, `spdlog::spdlog`, `OpenSSL::Crypto`, `Catch2::Catch2WithMain` | each library's documented CMake targets |
| Keycloak | 26.8.2 (platform) | platform TDD |
| C++ standard | C++20 (`std::jthread`, `std::stop_token`, `std::span`) | cppreference |
| CMake | 3.28 or newer; presets version 6 (configure, build, test, package presets) | cmake-presets(7) |

The port versions at the baseline commit may differ from the "master at reading time" values; vcpkg prints the resolved versions during the first configure. Where a lesson uses an API that was read from upstream headers (cpr `Session`, `WriteCallback`, `ProgressCallback`, `Redirect(bool)`; SDL3 `SDL_OpenURL`, `SDL_GetWindowDisplayScale`, `SDL_GetPrefPath`; Dear ImGui `ImGui_ImplSDL3_InitForSDLRenderer`, `Style::FontScaleDpi`), it was not compiled. SDL documents that `SDL_OpenURL` must be called on the main thread, which the controller respects.

Keycloak and loopback redirects: the securing-apps guide lists `http://127.0.0.1` as a valid redirect URI that allows any port, and RFC 8252 section 7.3 requires authorization servers to allow any port for loopback redirects. Confirm in the first manual run.
