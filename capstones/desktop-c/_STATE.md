# Desktop C state

Last updated: 2026-11-23. Execution was forbidden during this block: nothing was compiled, built, run or packed.

| Item | Status | Notes |
|---|---|---|
| TDD.md (D-01 to D-30, readiness checklist) | written (not run) | design only; matches the source as written |
| 01 Setup and window | written (not run) | CMake, vcpkg, SDL3, Nuklear, util, config; exercise `join_path` |
| 02 HTTP and JSON client | written (not run) | http, model, api, jobs, store, connection panel; exercise `url_encode` |
| 03 Auth: PKCE in the system browser | written (not run) | pkce, loopback, auth, Keycloak client file; exercise `base64url` |
| 04 Screens and state | written (not run) | store ops, three-column UI, forms, conflict view; exercise `parse_etag_version` |
| 05 Hardening and packaging | written (not run) | log, leak report, presets, hardening, CPack; exercise ownership bugs |
| PACK-README per phase | written (not run) | five files |
| verify.json per chapter | written (not run) | build and exercise steps for a later authorised run |
| Pack zips | not built | `build_packs.py` was not run |

## Open points for the first real run
1. `FetchContent` with `SOURCE_SUBDIR no-cmake-here`: confirm that configure does not add Nuklear's own `CMakeLists.txt`.
2. vcpkg `cjson` CMake target name on the chosen baseline (`cjson` or `cJSON::cJSON`).
3. Keycloak import of `tasks-desktop-client.json` and acceptance of `http://127.0.0.1:<port>/callback` against `http://127.0.0.1/*`.
4. Nuklear `nk_edit_string_zero_terminated` byte limit, `nk_selectable_label` return value semantics and `nk_combo` item types under `-Wpedantic`.
5. MSVC: `/sdl` together with `_CRT_SECURE_NO_WARNINGS`; `/fsanitize=address` with the debug flags; `$<TARGET_RUNTIME_DLLS>` install list.
6. Window height arithmetic in `ts_ui_frame` (an estimate): adjust the margin if the columns are cut.
7. Platform finding to forward: add a loopback client (`tasks-desktop`) to the realm in the v1.1 backlog.

Tracking files owned by this capstone: `_BRIEF.md`, `_STATE.md`, `GLOSSARY.md`, `VERSIONS.md`. No other tracking file was edited.
