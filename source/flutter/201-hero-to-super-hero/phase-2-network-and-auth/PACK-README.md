# Flutter 201, phase 2: Network and auth

**Status: written (not run).** Lessons 04 to 06.

## Unzip and open
Windows: right-click the zip, **Extract All**. macOS: double-click. Linux: `unzip`. Each lesson folder has `code/` (the whole app at that point, minus the Android scaffold and minus generated files), `exercise/starter`, `exercise/solution` and `verify.json`.
Use the project from phase 1 (`flutter create --org com.code101 --project-name tasks --platforms=android tasks_app`), copy the lesson's files over it, then:

```text
flutter pub get
dart run swagger_parser
dart run build_runner build
flutter run --dart-define-from-file=config/dev.json
```
`lib/data/generated/` and `pubspec.lock` are created by those commands and are not in the pack. `contract/openapi.yaml` is a copy of the platform contract.

## Prerequisites
Flutter 3.50.1 (Dart 3.14.0), Android toolchain. Packages: dio 5.11.1, swagger_parser 2.3.0, flutter_appauth 13.0.0, flutter_secure_storage 11.2.0. Running against the API needs the platform and one backend (port 8000, Keycloak 8180): follow `capstones/mobile-flutter/tutorials/phase-5-ship/05-build-run-ship.md`, section "Start a disposable backend session", and its cleanup. Emulator: `adb reverse tcp:8180 tcp:8180`.

## Lessons
04 A generated API client (swagger_parser) with dio. 05 Errors and RFC 9457 problem details. 06 OIDC PKCE login with flutter_appauth and secure storage.
