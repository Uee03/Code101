# Flutter 101, phase 3: Data and polish

**Status: written (not run).** Lessons 09 to 12.

## Unzip and open
Windows: right-click the zip, **Extract All**. macOS: double-click. Linux: `unzip`. Each lesson folder has `code/`, `exercise/starter`, `exercise/solution` and `verify.json`.
Create a project with `flutter create --platforms=android <name>`, copy `pubspec.yaml`, `lib/`, `assets/` and (lesson 09) `android/app/src/main/AndroidManifest.xml` over it, delete the generated `test/` folder, run `flutter pub get`, then `flutter run`.
Lessons 10 and 11 continue `shopping_list`; lesson 12 is a new project, `task_list`.

## Prerequisites
Flutter 3.50.1 (Dart 3.14.0), Android toolchain, emulator or phone; internet for lesson 09 (a public test server). `pubspec.lock` is created by `flutter pub get`.

## Art
Lessons 10 to 12 use CC0 icons from `assets/art`; see `assets/LICENSE-ICONS-CC0.txt` in the code folders.

## Lessons
09 HTTP and JSON. 10 Local storage with shared_preferences. 11 Accessibility and adaptive layout. 12 Project: a task list app.
