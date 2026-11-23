# Flutter track brief

Two levels: **101 Zero to Hero** (12 lessons, written) and **201 Hero to Super Hero** (10 lessons, all written, not run). No 301. Capstone to continue with: `capstones/mobile-flutter` (TDD, five chapters).

## Policy
Written without running anything (user rule 2026-11-23): no builds, tests, checks or unit-test lessons. Every lesson carries the draft notice under the H1 and `verified: not yet run`. `verify.json` files exist so the labs can be run later; their `flutter create .` first step is unproven. Lessons were assembled from source files by a copy script, so lesson text equals the files.

## Versions (from the capstone TDD and pub.dev, 2026-11-23)
Flutter 3.50.1, Dart 3.14.0, material_ui 1.11.1 (Material is a separate package since 3.50; `package:flutter/material.dart` is deprecated), flutter_riverpod 3.5.0, go_router 18.1.4, dio 5.11.1, swagger_parser 2.3.0, json_serializable 6.15.2, build_runner 2.17.1, json_annotation 4.12.0, uuid 4.6.0, flutter_appauth 13.0.0, flutter_secure_storage 11.2.0, flutter_svg 2.5.0, http 1.6.0, shared_preferences 2.5.6 (SharedPreferencesAsync), flutter_lints 6.0.0. Planned for 201 phase 3: drift 2.35.4, drift_dev 2.35.3, drift_flutter 0.3.1, connectivity_plus 7.3.2.

## 101 sequence (Android only, learners need Android Studio or a device)
Phase 1 first-app: 01 Install Flutter and the Android toolchain, create and run a first app; 02 Dart basics; 03 Dart collections, classes and async basics; 04 Widgets and layout. Phase 2 building: 05 StatelessWidget, StatefulWidget and setState; 06 Lists, forms and input; 07 Navigation; 08 Theming and assets (flutter_svg, CC0 icons). Phase 3 data-and-polish: 09 HTTP and JSON; 10 Local storage; 11 Accessibility and adaptive layout; 12 Project: a task list app.

## 201 sequence
Phase 1 architecture-and-state: 01 Feature-first structure and MVVM with repositories; 02 State with Riverpod; 03 Navigation with go_router. Phase 2 network-and-auth: 04 A generated API client (swagger_parser) with dio; 05 Errors and RFC 9457 problem details; 06 OIDC PKCE login with flutter_appauth and secure storage (realm tasksteams, redirect com.code101.tasks:/oauth2redirect). Phase 3 offline-and-quality (written, not run): 07 A local database (drift, schemaVersion 1, StreamNotifier over the database); 08 Offline cache and a sync queue (outbox table, schemaVersion 2, sync engine with backoff and jitter, connectivity_plus, offline banner, queue screen); 09 Accessibility and performance basics (Semantics, 48 dp, 200 percent text switch `TEXT_SCALE`, `select`, keys, profile mode); 10 Project: a task app against the platform contract (teams, projects, task form, `If-Match` and a hand-written merge PATCH, schemaVersion 3, conflict choice; then continue with `capstones/mobile-flutter`).

## Notes on the written 201 lessons 07 to 10
- 07: tables in `lib/data/local/tables.dart`, `TaskRow`, `TaskLocalService`, refresh and list are separate providers (`tasksRefreshProvider`). 08: `Outbox` table (`seq` is the primary key, `id` unique), engine in `lib/data/sync/`, the queue row id is the `Idempotency-Key`, banner above the bottom bar, queue route `/settings/sync`; WorkManager and a lease stay in capstone chapter 04. 09: a debug-only `TEXT_SCALE` define, `TaskTile`, `RefreshStatus` with `select`. 10: `DEV_PROJECT_ID` is gone, `/teams` is home, `request id` = local task id = queue row id of a create, the PATCH body is hand-built in `ApiService.updateTask`.
- Each lesson copies the previous lesson's code and shows every changed file in full. The static list of unchanged files is in each `verify.json` (`skip_lesson_check`).
- Lesson 10 deletes `task_composer.dart` and moves `refresh_status.dart` to `lib/core/widgets/`.
- App id `com.code101.tasks.flutter`, namespace `com.code101.tasks` (set in lesson 06). Project made with `--org com.code101 --project-name tasks`.
- Lessons 01 to 06 code is the base for 07; each later lesson copies the one before.
