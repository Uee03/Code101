# Kotlin 101, Phase 2: Compose basics

Source pack for lessons 05 to 08 of **Kotlin 101 (Zero to Hero)**: your first Android app, built with Jetpack Compose.
The optional source is also available at https://github.com/Uee03/Code101 under `source/kotlin/101-zero-to-hero/phase-2-compose-basics/` (**Code > Download ZIP**, then extract the repository). Every file needed is shown in the lessons.

**Status: written (not run).** Nothing in this pack has been built or run yet.

| Folder | Lesson | You build / exercise |
|---|---|---|
| `05-first-compose-app` | Your first Compose app | greeting screen / subtitle composable |
| `06-layouts-and-material-3` | Layouts and Material 3 | static home screen with cards, four vector icons / profile card |
| `07-state-and-recomposition` | State and recomposition (remember) | add and toggle tasks / counter with reset |
| `08-lists-and-navigation` | Lists (LazyColumn) and navigation | list and detail screens / empty state |

## Inside each lesson folder

| Folder or file | What it is |
|---|---|
| `code/` | The whole `TasksStart` Android project at the end of the lesson. Open this folder in Android Studio. |
| `exercise/starter/` | Only the files the exercise changes (full paths below `app/`). Copy them over the same paths in your project. |
| `exercise/solution/` | The same files, completed. Try first. |
| `verify.json` | Maintainer steps for a later verification run. Learners can ignore this file. |

## How to run any lesson

1. Install Android Studio (lesson 01) and the Android 37 SDK platform (lesson 05, Step 7).
2. **File > Open**, select a lesson's `code` folder, choose **Trust Project** and wait for the Gradle sync.
3. Choose an emulator (lesson 05, Step 8) or a USB phone in the device list and press the green **Run** triangle. Composables with `@Preview` can also be seen in the **Split** editor without running the app.

## Not in the pack

`gradlew`, `gradlew.bat`, `gradle/wrapper/gradle-wrapper.jar` and `local.properties` are not shipped; Android Studio creates what it needs (`local.properties` with your SDK path, and the wrapper through the Gradle tool window **Tasks > build setup > wrapper**). Never commit `local.properties`.

The four icons in `app/src/main/res/drawable` are hand conversions of CC0 icons from `assets/art/icons` (`ui/plus`, `ui/check`, `files/trash`, `ui/list`); the licence file `LICENSE-ICONS-CC0.txt` is kept next to the project files.

## Needs

Android Studio (latest stable that supports Android Gradle Plugin 9.5.1), the Android 37 platform, an emulator or a phone, and internet for the first sync. Pinned versions: AGP 9.5.1, Gradle 9.6.0, Kotlin 2.4.21, Compose BOM 2026.11.01, Activity Compose 1.13.0, Navigation Compose 2.10.2 (from lesson 08).
Lesson text: `tutorials/kotlin/101-zero-to-hero/phase-2-compose-basics/` in the repository.

Next: Phase 3, Data and polish.
