# Desktop C authoring brief

Approved scope: [TDD.md](TDD.md); platform decisions in section 12.1 of the platform TDD apply (task-only `If-None-Match`,
case-insensitive headers, replayed idempotent answers, 413 and 503 problems).

| Chapter | Phase | Requirements |
|---|---|---|
| 01 Setup and window | phase-1-setup | D-01 to D-04 |
| 02 HTTP and JSON client | phase-2-http-json | D-05 to D-08 |
| 03 Auth: PKCE in the system browser | phase-3-auth | D-09 to D-14, D-30 |
| 04 Screens and state | phase-4-screens | D-15 to D-22, D-28, D-29 |
| 05 Hardening and packaging | phase-5-ship | D-23 to D-27 |

Level 201: assume C 101 (lessons 01 and 05 to 12). Explain the why; show every file in full in the chapter where it is new or changed
and list unchanged files; each source pack is a complete snapshot; exercises are standard-library-only single files.
Tier 1: RFC 8252, RFC 7636, RFC 9700, RFC 9457, RFC 7396, SDL3 wiki, libcurl option reference, Nuklear repository, CMake and vcpkg manuals,
SEI CERT C. Tier 2: cJSON README, Keycloak issue threads on loopback redirects.
Smoke scope (when authorised): configure and build each snapshot; compile and run each solution exercise; manual sign-in and task flow.

## Authoring rule for this block
The repository owner forbade every check on 2026-11-23: no builds, no compilers, no tests, no verify_labs.py (not even `--static`),
no build_packs.py. Every chapter front matter says `verified: not yet run`; every state row says `written (not run)`.
Expected output is derived from the code or marked "typical". Platform files were read, never edited.
