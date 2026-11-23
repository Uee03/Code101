# Mobile Flutter ? phase 4: Offline cache, sync and errors

**Status: written (not run).** Executable verification was stopped at the user's request. This is not a verified release.

## Unzip and open
Windows: right-click `mobile-flutter-phase-4-offline.zip`, choose **Extract All**. macOS: double-click. Linux: `unzip mobile-flutter-phase-4-offline.zip`.
Open `04-offline/code` in Android Studio or VS Code. This is the **whole Android app at this phase**, not a patch. Do not mix files from different phases.
The chapter is `capstones/mobile-flutter/tutorials/phase-4-offline/04-offline.md` in the Code101 repository.

## Prerequisites
Flutter 3.50.1 / Dart 3.14.0; Android Studio JBR; SDK platform 36, build-tools 36.0.0, NDK 28.2.13676358 (SDK 37.2 alone does not supply these); accepted Android licenses.
Python 3 is used only for artifact inspection. An emulator is not needed to build; a device or emulator with a browser is needed to exercise the UI.
All packages are pinned in `pubspec.yaml`; keep the included `pubspec.lock`. The Material UI package is the official extracted `material_ui` 1.11.1, not the deprecated SDK import.

## Build later (not executed for this delivery)
From `04-offline/code` on every OS:

```text
flutter pub get
dart run swagger_parser
dart run build_runner build
flutter analyze --no-pub
flutter build apk --debug --no-pub --dart-define-from-file=config/dev.json
python tool/check_artifacts.py
```

On macOS/Linux, use `python3` if `python` is not installed. `build_runner` 2.17.1 no longer needs `--delete-conflicting-outputs`.
The debug APK will be `build/app/outputs/flutter-apk/app-debug.apk`.
Set `ANDROID_HOME` to your SDK folder if it is not at the Windows default; the artifact script uses build-tools 36.0.0.

## Manual run later
Complete the platform and one backend first. Use ASP.NET, Python or Go (not Rust); all presets refer to one chosen backend on port 8000, not three simultaneous services.
For an Android emulator, reverse Keycloak with `adb reverse tcp:8180 tcp:8180`, then run `flutter run --dart-define-from-file=config/dev.json`.
For a USB phone, also run `adb reverse tcp:8000 tcp:8000` and use `config/usb.json`.
Install only this Flutter client or its Kotlin twin, not both: both claim `com.code101.tasks:/oauth2redirect`.
Stop the app with `q`, undo reverses with `adb reverse --remove-all`, and stop an adb server or emulator only if you started it.
The final chapter contains the locked, disposable backend-session instructions and the complete device checklist. No backend, browser or device acceptance is claimed here.

## Exercise
Copy `04-offline/exercise/starter` to your own work folder and edit `main.dart`. The independent Dart program illustrates the chapter's rule without a Flutter engine.
Run `dart run main.dart` there. Compare with `exercise/solution/main.dart`; the solution is not a unit-test suite.

## Generated files and exclusions
Regenerate `lib/data/generated` with `dart run swagger_parser`, then its JSON parts (and the drift database from phase 4) with `dart run build_runner build`.
`flutter pub get` restores `pubspec.lock`; do not hand-edit it. `verify.json` lists every generated text file in `skip_lesson_check`; the chapter shows every authored file in full.
Do not distribute `build/`, `.dart_tool/`, `android/.gradle/`, `local.properties`, `key.properties` or keystores. `pubspec.lock` **is included**.
The ten SVGs are the CC0 icons named in chapter front matter; their license is `code/assets/LICENSE-ICONS-CC0.txt`.

## Chapter and requirements
04. Offline cache, sync and errors ? M-07, M-16?M-22.
