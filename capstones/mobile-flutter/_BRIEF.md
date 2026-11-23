# Mobile Flutter authoring brief

The approved design is [TDD.md](TDD.md); the platform contract and its section 12.1 Decision column remain authoritative.
Level 201; five chapters with the same numbering and S1?S10 screen names as mobile-kotlin. Android only, application id `com.code101.tasks.flutter`.

| Chapter | Phase | Requirements |
|---|---|---|
| 01 Setup and generated client | phase-1-setup | M-01?M-04 |
| 02 Auth (PKCE) and secure storage | phase-2-auth | M-05?M-09, M-26 |
| 03 Screens and state | phase-3-screens | M-10?M-15, M-22, M-23 |
| 04 Offline cache, sync and errors | phase-4-offline | M-07, M-16?M-22 |
| 05 Build, run and ship | phase-5-ship | M-24, M-25 |

## Sources
Tier 1: https://docs.flutter.dev/app-architecture/guide, https://docs.flutter.dev/app-architecture/design-patterns/offline-first,
https://docs.flutter.dev/ui/accessibility, https://docs.flutter.dev/deployment/android,
https://docs.flutter.dev/ui/widgets/material, https://developer.android.com/privacy-and-security/security-config.
Package-specific APIs and versions: the exact-version pub.dev pages linked in the chapters and VERSION-NOTES.md.

## Verification policy for this delivery
The user's later update stops executable verification. Only `verify_labs.py --static` may compare text; it does not run code.
Every chapter has `verified: not yet run`; every state row is `written (not run)`.
Keep runnable verify.json files for a future authorized smoke run; no unit tests, Docker or emulator steps in those files.
