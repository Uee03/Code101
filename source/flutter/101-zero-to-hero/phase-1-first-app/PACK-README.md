# Flutter 101, phase 1: First app

**Status: written (not run).** Lessons 01 to 04.

## Unzip and open
Windows: right-click the zip, **Extract All**. macOS: double-click. Linux: `unzip`. Each lesson folder has `code/` (the files to place over a project made with `flutter create --platforms=android <name>`), `exercise/starter`, `exercise/solution` and `verify.json`.
Lessons 02 and 03 are plain Dart: run `dart run main.dart` in `code/` or an exercise folder. Lessons 01 and 04 are Flutter apps: copy `pubspec.yaml` and `lib/` into your project, delete the generated `test/` folder, run `flutter pub get`, then `flutter run`.

## Prerequisites
Flutter 3.50.1 (Dart 3.14.0), Android Studio with the Android SDK, an emulator or an Android phone. Lesson 01 installs all of it.
`pubspec.lock` is not included: `flutter pub get` creates it.

## Lessons
01 Install Flutter and the Android toolchain, create and run a first app. 02 Dart basics. 03 Dart collections, classes and async basics. 04 Widgets and layout.
