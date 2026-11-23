# Kotlin 201, Phase 1: Architecture

Source pack for lessons 01 to 03 of **Kotlin 201 (Hero to Super Hero)**: MVVM and clean layers, Hilt, and coroutines and Flow in depth. The app, **Tasks Mini**, is a thin slice of `capstones/mobile-kotlin` (package `com.code101.tasks`, application id `com.code101.tasks.lab`).
The optional source is also available at https://github.com/Uee03/Code101 under `source/kotlin/201-hero-to-super-hero/phase-1-architecture/` (**Code > Download ZIP**). Every file needed is shown in the lessons.

**Status: written (not run).** Nothing in this pack has been built or run yet.

| Folder | Lesson | You build / exercise |
|---|---|---|
| `01-mvvm-and-clean-layers` | MVVM and clean layers | three screens on a fake repository / `openCount` extension |
| `02-dependency-injection-hilt` | Dependency injection with Hilt | Hilt wiring of the same app / `TimeModule` |
| `03-coroutines-and-flow-in-depth` | Coroutines and Flow in depth | Flow repository, debounced search, events / `toOpenCount` |

Each lesson folder has `code/` (the whole project at the end of the lesson), `exercise/starter/` and `exercise/solution/` (only the changed files, full paths below `app/`) and `verify.json` (maintainer steps for a later run; learners can ignore it).

## How to run

Android Studio with the Android 37 platform and an emulator (101 lesson 05). **File > Open** a lesson's `code` folder, trust it, wait for the sync, press **Run**. `gradlew`, `gradlew.bat`, the wrapper jar and `local.properties` are not shipped; Android Studio creates them.

## Needs

AGP 9.5.1, Gradle 9.6.0 (with a pinned SHA-256), Kotlin 2.4.21, KSP 2.3.14, Compose BOM 2026.11.01, Lifecycle 2.11.1, Navigation Compose 2.10.2, Hilt 2.60.1 and AndroidX Hilt 1.4.0 (from lesson 02), kotlinx coroutines 1.11.0, kotlinx serialization 1.13.0. These are the capstone's pins.
Lesson text: `tutorials/kotlin/201-hero-to-super-hero/phase-1-architecture/`.

Phases 2 and 3 (lessons 04 to 10) are in `phase-2-network-and-auth` and `phase-3-offline-and-quality`.
