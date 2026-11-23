# Flutter 201, phase 3: Offline and quality

**Status: written (not run).** Lessons 07 to 10.

## Unzip and open
Windows: right-click the zip, **Extract All**. macOS: double-click. Linux: `unzip`. Each lesson folder has `code/` (the whole app at that point, minus the Android scaffold and minus generated files), `exercise/starter`, `exercise/solution` and `verify.json`.
Use the project from phase 1 (`flutter create --org com.code101 --project-name tasks --platforms=android tasks_app`), copy the lesson's files over it, then:

```text
flutter pub get
dart run swagger_parser
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define-from-file=config/dev.json
```
`lib/data/generated/`, `lib/data/local/database.g.dart` and `pubspec.lock` are created by those commands and are not in the pack. `contract/openapi.yaml` is a copy of the platform contract. Lesson 10 deletes two files of lesson 09 (`task_composer.dart` and `lib/features/tasks/view/refresh_status.dart`); its `code/` folder does not contain them, so copy it into a clean project or delete them by hand.

## Prerequisites
Flutter 3.50.1 (Dart 3.14.0), Android toolchain. New packages: drift 2.35.4, drift_flutter 0.3.1, drift_dev 2.35.3 (dev), connectivity_plus 7.3.2 (lesson 08). Running against the API needs the platform and one backend (port 8000, Keycloak 8180): follow `capstones/mobile-flutter/tutorials/phase-5-ship/05-build-run-ship.md`, section "Start a disposable backend session", and its cleanup. Emulator: `adb reverse tcp:8180 tcp:8180`. Lesson 07 changes the database layout only by creating it (schemaVersion 1); lessons 08 and 10 raise it to 2 and 3, so an app installed from an earlier lesson of this phase upgrades in place; uninstall it first if anything looks wrong.

## Lessons
07 A local database. 08 Offline cache and a sync queue. 09 Accessibility and performance basics. 10 Project: a task app against the platform contract.
