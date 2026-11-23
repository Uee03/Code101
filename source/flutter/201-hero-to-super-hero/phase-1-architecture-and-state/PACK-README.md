# Flutter 201, phase 1: Architecture and state

**Status: written (not run).** Lessons 01 to 03.

## Unzip and open
Windows: right-click the zip, **Extract All**. macOS: double-click. Linux: `unzip`. Each lesson folder has `code/` (the whole app at that point, minus the Android scaffold), `exercise/starter`, `exercise/solution` and `verify.json`.
Create the project once: `flutter create --org com.code101 --project-name tasks --platforms=android tasks_app`, delete `test/`, copy `pubspec.yaml`, `lib/` and `assets/` over it, run `flutter pub get`, then `flutter run`. `pubspec.lock` is created by `flutter pub get`.

## Prerequisites
Flutter 101 (or equivalent), Flutter 3.50.1 (Dart 3.14.0), Android toolchain. Packages: flutter_riverpod 3.5.0, go_router 18.1.4, flutter_svg 2.5.0. Lessons 01 and 02 need no backend.
Exercises of lessons 01 is plain Dart (`dart run main.dart`); lessons 02 and 03 exercises are small Flutter files.

## Lessons
01 Feature-first structure and MVVM with repositories. 02 State with Riverpod. 03 Navigation with go_router.
