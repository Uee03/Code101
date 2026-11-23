# desktop-cpp state

Updated 2026-11-23. Writing-only block: nothing was built, run, tested or packed.

| Chapter | Title | Status | Requirements |
|---|---|---|---|
| 01 | Setup and window | written (not run) | D-01 to D-03, D-25 (part) |
| 02 | HTTP and JSON client | written (not run) | D-04 to D-06 |
| 03 | Auth with PKCE | written (not run) | D-07 to D-11, D-19/D-20 (part) |
| 04 | Screens, threading and state | written (not run) | D-12 to D-20, D-25 |
| 05 | Hardening and packaging | written (not run) | D-21 to D-24, D-26, D-27 |

Every chapter front matter is exactly `verified: not yet run`. Every phase has a complete snapshot (`code`), exercise overlays, `verify.json` and a `PACK-README.md`.

## Not done (needs an authorised run)
- Compile all five snapshots; expect small API or syntax fixes. The lessons were typed from the files, so a fix must be applied to the file and the lesson text together.
- `python scripts/verify_labs.py --static capstones/desktop-cpp` (expected to flag unchanged files that a lesson only lists by reference, by design of this capstone) and `python scripts/build_packs.py desktop-cpp`.
- Manual: import the Keycloak client, sign in, create, edit, conflict, delete, close during a request, the log has no token.
- Confirm the Keycloak loopback port rule; if it fails, register a fixed port (TDD section 12).
- `ctest` and `cpack` presets, Linux and macOS presets (only Windows commands are in `verify.json`).

## Platform backlog found while writing
Add the public client `tasks-desktop` (redirect `http://127.0.0.1/callback`) to `realm-tasksteams.json` in contract v1.1. The platform and other capstones were not edited.

## Decisions
- Header-only where small; a static `tasks_core` library for everything testable without a window.
- OpenSSL only for SHA-256 and random bytes; cpp-httplib only for the loopback listener.
- SDL_OpenURL runs on the UI thread (SDL requirement), so the session's browser opener posts to the UI queue.
- In-memory tokens only; the production note names the OS secret stores.
- Lessons list unchanged files instead of repeating them (allowed: "refer to previous steps only when genuinely identical"); packs contain every file.
