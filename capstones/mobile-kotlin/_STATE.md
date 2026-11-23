# Mobile Kotlin state

Updated 2026-11-23 after the user stopped builds, Docker and smoke verification.

| Chapter | Title | Status | Requirements |
|---|---|---|---|
| 01 | Setup and generated client | written (not run) | M-01 to M-04 |
| 02 | Auth (PKCE) and secure storage | written (not run) | M-05 to M-09, M-26; real-route integration in 03 |
| 03 | Screens and state | written (not run) | M-09 to M-15, M-22, M-23 |
| 04 | Offline cache, sync and errors | written (not run) | M-07, M-16 to M-22 |
| 05 | Build, run and ship | written (not run) | M-24, M-25 |

Every chapter front matter is exactly `verified: not yet run`.
Every phase has a full application snapshot, source/lesson match, exercise overlays, future verify.json
and PACK-README. Static comparison is allowed; it is not a smoke PASS or a functional verification.

## Execution boundary
Before the user's writing-only update, historical isolated debug/release builds and deliberate Gradle/
compiler-error demonstrations were captured. They ended with gradlew.bat --stop. Final source has changes
not built afterwards. Evidence files are explicitly historical and cannot certify this final snapshot.
No Docker containers/images/volumes/networks, dev servers, emulators or adb servers were started by this task.
Do not stop or delete another author's processes/projects.

## Remaining work
No chapter is intentionally unwritten. A future authorized session must run recipes and inspect artifacts;
a human/device must complete the chapter-05 checklist. No unit/instrumented tests are requested.
No final build, browser flow, accessibility, offline durability, background deadline, performance,
private upload signature or backend/device interoperability is claimed.

## Implementation decisions and unresolved acceptance
See README Design clarifications: minor compile API, CLI generation, unsent-only merge, SQLite outbox keys,
repository-owned drain, bounded snapshot cache, scripted vector conversion, realistic WorkManager timing.
No platform files were changed and no new platform contract defect was established.
The TDD's optional biometric vault unlock remains a stretch goal, not an unwritten required chapter.

## Static and packaging
Static comparison completed for all five chapters. Five phase zips and mobile-kotlin-all.zip were built with scripts/build_packs.py mobile-kotlin. No execution status is promoted.

```text
[STATIC    ] capstones/mobile-kotlin/source/phase-1-setup/01-setup
[STATIC    ] capstones/mobile-kotlin/source/phase-2-auth/02-auth
[STATIC    ] capstones/mobile-kotlin/source/phase-3-screens/03-screens
[STATIC    ] capstones/mobile-kotlin/source/phase-4-offline/04-offline
[STATIC    ] capstones/mobile-kotlin/source/phase-5-ship/05-build-run-ship

0 passed, 5 static-checked (not run), 0 failed, 0 unverified (missing tools)
```

## Delivery
All five required chapters are written. No chapter remains intentionally unwritten.
The six requested archives are in dist/packs. Temporary authoring/download/build copies were removed.
No owned JVM daemon remained at the cleanup inspection; no container, server, emulator or adb server was started.
No commits were made. Source and chapter edits remain under capstones/mobile-kotlin; the requested pack builder
writes its generated archives to dist/packs.
