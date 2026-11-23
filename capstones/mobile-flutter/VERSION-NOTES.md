# Version and design notes

## Pins checked before executable work was stopped
On 2026-11-23 the pub.dev metadata published every TDD pin below. These are provenance checks, not a claim that the final apps were run.

| Package | Exact version | Source |
|---|---|---|
| flutter_riverpod | 3.5.0 | https://pub.dev/packages/flutter_riverpod/versions/3.5.0 |
| go_router | 18.1.4 | https://pub.dev/packages/go_router/versions/18.1.4 |
| dio | 5.11.1 | https://pub.dev/packages/dio/versions/5.11.1 |
| swagger_parser | 2.3.0 | https://pub.dev/packages/swagger_parser/versions/2.3.0 |
| flutter_appauth | 13.0.0 | https://pub.dev/packages/flutter_appauth/versions/13.0.0 |
| flutter_secure_storage | 11.2.0 | https://pub.dev/packages/flutter_secure_storage/versions/11.2.0 |
| drift | 2.35.4 | https://pub.dev/packages/drift/versions/2.35.4 |
| drift_dev | 2.35.3 | https://pub.dev/packages/drift_dev/versions/2.35.3 |
| drift_flutter | 0.3.1 | https://pub.dev/packages/drift_flutter/versions/0.3.1 |
| connectivity_plus | 7.3.2 | https://pub.dev/packages/connectivity_plus/versions/7.3.2 |
| workmanager | 0.10.10 | https://pub.dev/packages/workmanager/versions/0.10.10 |
| flutter_svg | 2.5.0 | https://pub.dev/packages/flutter_svg/versions/2.5.0 |
| uuid | 4.6.0 | https://pub.dev/packages/uuid/versions/4.6.0 |
| json_annotation | 4.12.0 | https://pub.dev/packages/json_annotation/versions/4.12.0 |
| json_serializable | 6.15.2 | https://pub.dev/packages/json_serializable/versions/6.15.2 |
| build_runner | 2.17.1 | https://pub.dev/packages/build_runner/versions/2.17.1 |
| intl | 0.20.3 | https://pub.dev/packages/intl/versions/0.20.3 |
| flutter_lints | 6.0.0 | https://pub.dev/packages/flutter_lints/versions/6.0.0 |
| path_provider | 2.1.6 | https://pub.dev/packages/path_provider/versions/2.1.6 |
| material_ui | 1.11.1 | https://pub.dev/packages/material_ui/versions/1.11.1 |

## API choices and deviations from the approved design
- Flutter 3.50.1 bundles Dart 3.14.0. Its Material library is extracted: import `package:material_ui/material_ui.dart`, with direct pin 1.11.1. Tier 1 migration/catalog: https://docs.flutter.dev/ui/widgets/material and https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui.
- path_provider 2.1.6 is a direct dependency for a token-free file lock. A shared Future serializes refresh inside one isolate; the file lock also serializes foreground and WorkManager token rotation. Read secure storage again inside the lock, and write the rotated blob before using it.
- An unreachable issuer is treated differently from an OAuth rejection: cached screens remain accessible on temporary failure. `invalid_grant` and equivalent authorization failures route to Login, preserving the queue. This makes the offline cold-start requirement consistent with refresh behavior.
- swagger_parser 2.3.0 uses the nested `generation` configuration. Dio-only clients use json_serializable parts. `TaskUpdate` does not express explicit-null merge-patch fields, so ApiService owns one raw Dio PATCH; generated files are never edited.
- build_runner 2.17.1 reports `--delete-conflicting-outputs` as removed; use `dart run build_runner build`.
- The SQLite baseline uses the TDD's named tables and indexed fields, with extra payload_json columns to retain every response field, cached_pages to retain query membership/cursors, and a sync lease to coordinate isolates. These are internal cache details, not a platform change.
- Domain snapshots use a small immutable Item/PageData model rather than separate Team/Project/TaskItem/Comment/Me classes. Collection behavior is shared by per-feature Riverpod ViewModel subclasses; views still cannot import generated DTOs or call HTTP/SQL.
- Edits may merge into an undispatched pending create only while attempts is zero. Once dispatch may have occurred, preserve its original idempotency body and queue a dependent write. A definitive 422 rejection can be corrected with a fresh key.
- Discard is intentionally labeled as discarding the entity and its dependent local changes; partial rollback of an arbitrary dependent offline chain is not taught.
- Android task links use a separate code101-tasks-flutter://app filter. OAuth retains the realm?s fixed AppAuth scheme. The router preserves only path/query for intended routes. Cold/warm OS delivery and return-after-sign-in remain unrun device acceptance; a custom scheme is not a verified HTTPS App Link.
- Product labels ASP.NET/Python/Go are stable proper names in Settings; all other authored presentation messages are ARB keys. These labels do not imply three running backends or backend conformance.
- All TDD package pins are present from phase 1 so the lockfile and plugin/Android compatibility are visible immediately, even though features are introduced in later phases.
- The WorkManager plugin still applies KGP and Flutter prints a future-compatibility warning. Keep the template's current compatibility flags; do not claim future AGP compatibility.
- Windows Kotlin incremental caches failed across drives; kotlin.incremental=false is documented in the shipped Gradle properties. Worker count and heap are bounded for parallel capstone authoring.
- Flutter Doctor accepted Android tooling but SDK 37.2 alone was insufficient: Flutter also required platform 36, NDK 28.2.13676358 and plugin platform/CMake components. Provision them before a future clean build; no SDK content is shipped.

## Contract decisions honored
The platform TDD section 12.1 Decision column is followed: header names are case-insensitive; do not depend on team/project If-None-Match; compare JSON structurally; /health is unauthenticated and its rate-limit headers are ignored; unknown/413/405/415/503 errors remain RFC 9457 messages, with retryable 5xx and Retry-After support.
No platform files were changed and no new confirmed platform defect is reported. The schema remains the byte-for-byte contract copy; run future backend checks against conformant ASP.NET/Python/Go, not Rust.

## Verification status
Every chapter is `written (not run)` after the user's stop instruction. Historical author output is retained only as provenance and Common mistakes evidence; it does not make the final lessons verified.
Future verification specs run dependency restore, generation, one analysis, one debug build, artifact inspection and one small Dart exercise; phase 5 additionally builds a release AAB. No tests, Docker or emulator steps are in those specs.
See MANUAL-CHECKLIST.md for all device/browser/security/UX acceptance and production sign-off. Release fallback signing is deliberately NOT FOR STORE; no keystore or private properties file is shipped.
