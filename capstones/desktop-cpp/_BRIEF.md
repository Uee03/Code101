# desktop-cpp brief

Built capstone, level 201: a native desktop client for the Tasks and Teams platform contract.

## Learners and outcome
Developers who finished C++ 101 (or have equivalent experience). They end with a C++20 desktop app (SDL3 + Dear ImGui) that signs in with PKCE through the system browser, works with every backend, handles concurrency conflicts and problem details, runs requests off the UI thread, has unit tests and a release ZIP.

## Plan (5 chapters, 5 packs)
| Chapter | Topic | Requirements |
|---|---|---|
| 01 | CMake presets, vcpkg manifest, RAII window | D-01 to D-03, D-25 (part) |
| 02 | Result type, transport, JSON models, API client | D-04 to D-06 |
| 03 | PKCE, loopback listener, session, workers | D-07 to D-11, D-19/D-20 (part) |
| 04 | State, controller, screens, forms, conflicts, problem details | D-12 to D-20, D-25 |
| 05 | URL policy, response cap, validation, logging, Catch2, CPack | D-21 to D-24, D-26, D-27 |

## Rules for this capstone
- Contract only: no platform file is edited; the extra Keycloak client ships as a partial import file here.
- Show every new or changed file in full in the lesson; list unchanged files with the chapter that shows them; every pack is a complete snapshot.
- No invented output: say "typical". Draft notice under each H1 and `verified: not yet run`.
- Core Guidelines ids are cited in each chapter's Best practice.
- Unit tests only for pure logic (chapter 05). No GUI or network tests.
- Tokens are never written to disk or logs.

## Open decisions
Keycloak's loopback port rule must be confirmed in a first run; vcpkg port versions are those of the baseline; a later run must compile everything and fix small API differences.
