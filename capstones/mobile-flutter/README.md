# Mobile client in Flutter ? Tasks and Teams

**Status: written (not run).** All five chapters and whole-app source snapshots are written. The user's later update stopped executable verification; no final clean-room PASS or device/browser acceptance is claimed. Only text/source comparison is permitted for this delivery.

| Chapter | Tutorial | Pack |
|---|---|---|
| 01 Setup and generated client | [Chapter 01](tutorials/phase-1-setup/01-setup.md) | mobile-flutter-phase-1-setup.zip |
| 02 Auth (PKCE) and secure storage | [Chapter 02](tutorials/phase-2-auth/02-auth.md) | mobile-flutter-phase-2-auth.zip |
| 03 Screens and state | [Chapter 03](tutorials/phase-3-screens/03-screens.md) | mobile-flutter-phase-3-screens.zip |
| 04 Offline cache, sync and errors | [Chapter 04](tutorials/phase-4-offline/04-offline.md) | mobile-flutter-phase-4-offline.zip |
| 05 Build, run and ship | [Chapter 05](tutorials/phase-5-ship/05-build-run-ship.md) | mobile-flutter-phase-5-ship.zip |

Every phase contains its complete Android app under `source/phase-N-slug/NN-slug/code`, plus exercise starter/solution, a future `verify.json` and a phase PACK-README. Generated client files and pubspec.lock are included; build output, machine-local properties, keys and caches are not. `mobile-flutter-all.zip` collects all five phases.

## Shared design
The approved [TDD](TDD.md) and [platform contract](../platform/TDD.md), including section 12.1's Decision column, govern the app. No platform or other capstone files are modified.
The client works toward the same M-xx requirements, five phases and S1?S10 names as [mobile-kotlin](../mobile-kotlin/README.md).

| Part | Choice |
|---|---|
| Architecture | Feature-first MVVM/repositories, Riverpod, go_router |
| API | Read-only copied OpenAPI ? swagger_parser ? standalone Dio clients |
| Auth | System-browser authorization code + PKCE, flutter_appauth, Keystore-backed secure storage |
| Offline | drift/SQLite cache, transactional outbox, ordered drain, conflicts/backoff, WorkManager |
| App id | `com.code101.tasks.flutter` |
| OAuth redirect | `com.code101.tasks:/oauth2redirect` |
| Browser logout | `com.code101.tasks:/logout` |
| Separate task link | `code101-tasks-flutter://app` plus an existing route; unrun device acceptance |
| Art | Only the ten CC0 SVGs from assets/art, drawn with flutter_svg |
| Targets | Android; ASP.NET, Python or Go backend, not Rust |

Screens: S1 Session check; S2 Login; S3 Teams; S4 Projects; S5 Task list; S6 Task detail; S7 Create or edit task; S8 Conflict sheet; S9 Settings; S10 Sync queue. The offline banner is shared, not an eleventh screen.

## Read before running later
- [Manual device/browser/accessibility and cleanup checklist](MANUAL-CHECKLIST.md): everything in it is unrun.
- [Version pins, APIs, design deviations and limits](VERSION-NOTES.md): includes Flutter's extracted material_ui package, generator options, cross-isolate refresh, schema additions and release-signing limitations.
- [State](_STATE.md) and [glossary](GLOSSARY.md).

Use Flutter 3.50.1 / Dart 3.14.0, Android Studio JBR, SDK platform 36, build-tools 36.0.0 and NDK 28.2.13676358; SDK 37.2 alone does not provide all Flutter/plugin build inputs. The earlier Doctor accepted Android tooling/licenses, but that is not final-app verification.

## Future app commands (not executed for this delivery)
Extract one phase and open its `code` folder. Commands are the same in PowerShell, macOS and Linux; use python3 if needed there:

```text
flutter pub get
dart run swagger_parser
dart run build_runner build
flutter analyze --no-pub
flutter build apk --debug --no-pub --dart-define-from-file=config/dev.json
python tool/check_artifacts.py
```

A device/emulator is not needed to build, but all sign-in, offline UX, conflict and accessibility acceptance needs one. Do not equate static checking with execution.
For an emulator the API uses `10.0.2.2:8000`; reverse Keycloak with `adb reverse tcp:8180 tcp:8180` so its issuer stays localhost. For a USB phone also reverse 8000 and use `config/usb.json`. Install only one mobile twin at a time: both claim the fixed OAuth scheme.
Before a future device session, follow chapter 05's locked disposable backend procedure using the Python backend phase-5 Compose files, and its mandatory cleanup. Docker belongs to the backend/platform only, never the Flutter app. No Docker stack, emulator, adb server or development server was started for this authoring task.

## Release is a separate procedure
Chapter 05 supplies full conditional signing configuration. Without private `android/key.properties` it prints NOT FOR STORE and uses a debug key. `config/release.example.json` contains deliberately unusable .invalid HTTPS hosts.
No keystore or private properties file is supplied. Real HTTPS, an external private upload key, current platform requirements and the unrun manual checklist are prerequisites to distributing an app to users.
