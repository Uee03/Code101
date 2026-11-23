# Versions and evidence (desktop-c)

Nothing was installed, built or run for this capstone. The table records what the author read in official sources on 2026-11-23
and what the learner's tools will decide at install time.

| Item | Pin or rule | Source read | Note |
|------|-------------|-------------|------|
| C standard | C17 (`-std=c17`, extensions off) | ISO C17; CMake `C_STANDARD 17` | `_POSIX_C_SOURCE=200809L` only for `loopback.c` on Unix |
| CMake | 3.21 or newer | CMake presets version 3 needs 3.21; `$<TARGET_RUNTIME_DLLS>` needs 3.21 | the C 101 track also uses 3.21 |
| vcpkg | manifest mode; `builtin-baseline` written by `vcpkg x-update-baseline --add-initial-baseline` | Microsoft vcpkg documentation | the baseline hash is a property of the learner's checkout and is not written in the lessons |
| SDL3 | vcpkg port `sdl3` (the registry page read on 2026-11-23 listed 3.4.20) | vcpkg registry | `SDL_AtomicInt`, `SDL_CreateThread`, `SDL_OpenURL`, `SDL_GetCurrentRenderOutputSize` are SDL3 names |
| Nuklear | tag `v4.13.4`; backend `demo/sdl3_renderer/nuklear_sdl3_renderer.h` | GitHub API listing of tags and of `demo/sdl3_renderer` at that tag | the SDL3 backend is not in vcpkg's `nuklear` port |
| libcurl | vcpkg port `curl` (default features, TLS from the platform: Schannel on Windows, OpenSSL on Linux) | curl.se option reference | `CURLOPT_PROTOCOLS_STR` needs libcurl 7.85 or newer |
| cJSON | vcpkg port `cjson`; header `<cjson/cJSON.h>`; target `cjson` (fallback `cJSON::cJSON`) | cJSON README | `cJSON_ParseWithLength`, `cJSON_InitHooks` |
| OpenSSL | vcpkg port `openssl`; only `RAND_bytes` and `EVP_Digest` (SHA-256) | OpenSSL manual pages | libcrypto only |
| Keycloak | the platform's Keycloak 26.x, realm `tasksteams`; loopback redirect `http://127.0.0.1/*` matches any port | Keycloak issues 25637 and 39880 (RFC 8252 loopback handling); admin console "Import client" | exact UI labels may differ slightly between 26.x releases |
| Compilers | MSVC (Build Tools for Visual Studio), gcc or clang | C 101 lesson 01 | MinGW with vcpkg untested |

Not verified at all: that FetchContent skips Nuklear's CMakeLists with a missing `SOURCE_SUBDIR`, that the vcpkg `cjson` target is named
`cjson` on the learner's baseline, that Keycloak accepts the import file unchanged, every flag in the hardening block, every expected output
marked "typical".
