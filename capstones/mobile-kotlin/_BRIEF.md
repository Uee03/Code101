# Mobile Kotlin authoring brief

Approved scope: [TDD.md](TDD.md); platform decisions in section 12.1 override older v1 prose.

| Chapter | Phase | Requirements |
|---|---|---|
| 01 Setup and generated client | phase-1-setup | M-01 to M-04 |
| 02 Auth (PKCE) and secure storage | phase-2-auth | M-05 to M-09, M-26 |
| 03 Screens and state | phase-3-screens | M-10 to M-15, M-22, M-23 |
| 04 Offline cache, sync and errors | phase-4-offline | M-07, M-16 to M-22 |
| 05 Build, run and ship | phase-5-ship | M-24, M-25 |

Use the TDD S1-S10 screen names and routes unchanged; Flutter uses the same chapter numbers.
Tier 1: developer.android.com architecture, Compose, network security, accessibility, offline-first,
Keystore, WorkManager, Room and signing guides; Kotlin releases; Gradle wrapper guide.
Tier 2: AppAuth, Dagger, KSP and OpenAPI Generator upstream release documentation.
Smoke scope: one assembleDebug per chapter, no tests and no emulator. Human checks stay unverified.

## Updated authoring rule
User stopped execution on 2026-11-23. Write only; static comparison and pack building are allowed.
All chapter front matter: verified: not yet run. All state rows: written (not run).
Historical build/error transcripts are not evidence that the final snapshot was run.
