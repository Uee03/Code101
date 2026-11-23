# Flutter 101, phase 2: Building

**Status: written (not run).** Lessons 05 to 08.

## Unzip and open
Windows: right-click the zip, **Extract All**. macOS: double-click. Linux: `unzip`. Each lesson folder has `code/`, `exercise/starter`, `exercise/solution` and `verify.json`.
Create a project with `flutter create --platforms=android <name>`, copy `pubspec.yaml`, `lib/` and (lesson 08) `assets/` over it, delete the generated `test/` folder, run `flutter pub get`, then `flutter run`.
Lessons 06, 07 and 08 build one project, `shopping_list`; each `code/` folder holds the whole project at that point (unchanged files are copies of the previous lesson's).

## Prerequisites
Flutter 3.50.1 (Dart 3.14.0), Android toolchain, emulator or phone. `pubspec.lock` is created by `flutter pub get`.

## Art
Lesson 08 uses three CC0 icons from `assets/art` (`ui/plus`, `files/trash`, `ui/list`); the licence note is `code/assets/LICENSE-ICONS-CC0.txt`.

## Lessons
05 StatelessWidget, StatefulWidget and setState. 06 Lists, forms and input. 07 Navigation. 08 Theming and assets.
