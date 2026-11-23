# Flutter state

Last updated: 2026-11-23. **101: 12 of 12 lessons written (not run). 201: 10 of 10 written (not run).** No code, build, check or test was run.

## Level 101
| Lesson | Phase | Status |
|---|---|---|
| 01 Install Flutter and the Android toolchain, create and run a first app | first-app | written (not run) |
| 02 Dart basics | first-app | written (not run) |
| 03 Dart collections, classes and async basics | first-app | written (not run) |
| 04 Widgets and layout | first-app | written (not run) |
| 05 StatelessWidget, StatefulWidget and setState | building | written (not run) |
| 06 Lists, forms and input | building | written (not run) |
| 07 Navigation | building | written (not run) |
| 08 Theming and assets | building | written (not run) |
| 09 HTTP and JSON | data-and-polish | written (not run) |
| 10 Local storage with shared_preferences | data-and-polish | written (not run) |
| 11 Accessibility and adaptive layout | data-and-polish | written (not run) |
| 12 Project: a task list app | data-and-polish | written (not run) |

## Level 201
| Lesson | Phase | Status |
|---|---|---|
| 01 Feature-first structure and MVVM with repositories | architecture-and-state | written (not run) |
| 02 State with Riverpod | architecture-and-state | written (not run) |
| 03 Navigation with go_router | architecture-and-state | written (not run) |
| 04 A generated API client (swagger_parser) with dio | network-and-auth | written (not run) |
| 05 Errors and RFC 9457 problem details | network-and-auth | written (not run) |
| 06 OIDC PKCE login with flutter_appauth and secure storage | network-and-auth | written (not run) |
| 07 A local database | offline-and-quality | written (not run) |
| 08 Offline cache and a sync queue | offline-and-quality | written (not run) |
| 09 Accessibility and performance basics | offline-and-quality | written (not run) |
| 10 Project: a task app against the platform contract | offline-and-quality | written (not run) |

Phase 3 of 201 (`phase-3-offline-and-quality`) has lessons, source folders and a PACK-README. Next step: the capstone `mobile-flutter` (already written), then the persona walk-throughs and a later real run of the labs.

## Known uncertainties
- `verify.json` first step `flutter create . --project-name ...` over existing files is assumed not to overwrite them; unproven.
- `material_ui` and `Icons`: lessons avoid the Material icon font (SVG icons only). `uses-material-design: false` in 201 follows the capstone.
- Generated files (`lib/data/generated`) and `pubspec.lock` are not shipped; the lessons say which commands create them.
- Expected outputs are derived from code; UI behaviour is described, not observed.
- 201 lessons 04 to 06 need the platform backend and Keycloak running; lesson 04 expects a 401 on the task list until lesson 06.
- 201 phase 3: the drift API calls (`@TableIndex`, `insertAllOnConflictUpdate`, `selectOnly` with `count()` and `min()`, `readTableOrNull`, `migrator.createIndex(outboxByState)`), `connectivity_plus` 7.3.2 and the exact generated names `Team$Response`, `TeamPage$Response`, `ProjectPage$Response` were written from the docs and from the capstone's generated client, not compiled. A dependency resolution of the pubspec files was done by the editor's automatic `pub get` (drift 2.35.4, drift_dev 2.35.3, drift_flutter 0.3.1, connectivity_plus 7.3.2 resolved); nothing else was run. The auto-created `pubspec.lock` and `.dart_tool` files were deleted again.
- 201 lesson 08 stores the problem kind only; the queue screen rebuilds the message from it. An open detail screen on a local task id shows "not available" after the create is accepted (the capstone uses an alias table).
- 201 lesson 10 deletes two files of lesson 09 (`task_composer.dart`, `lib/features/tasks/view/refresh_status.dart`); the lesson says so and the code folder does not contain them.
