# Kotlin 101, Phase 1: Kotlin basics

Source pack for lessons 01 to 04 of **Kotlin 101 (Zero to Hero)**.
The optional source is also available at https://github.com/Uee03/Code101 under `source/kotlin/101-zero-to-hero/phase-1-kotlin-basics/` (**Code > Download ZIP**, then extract the repository). Every file needed is shown in the lessons. Open one lesson `code` folder, not the parent containing all lessons.

**Status: written (not run).** Nothing in this pack has been compiled or executed yet.

| Folder | Lesson | You build / exercise |
|---|---|---|
| `01-install-and-first-program` | Install Android Studio and run your first Kotlin program | two printed lines / recipe card |
| `02-variables-types-null-safety` | Variables, types and null safety | café report / stock update |
| `03-functions-collections-lambdas` | Functions, collections and lambdas | collection demo / short titles |
| `04-classes-data-classes-objects` | Classes, data classes and objects | task list types / bookshelf |

## Inside each lesson folder

| Folder or file | What it is |
|---|---|
| `code/` | The whole `KotlinBasics` project as it is at the end of the lesson (a plain Kotlin/Gradle project). |
| `exercise/starter/` | Only the exercise source file(s), with TODO markers. Copy `src/main/kotlin/exerciseNN` into your project. |
| `exercise/solution/` | The same file(s), completed. Try first. |
| `verify.json` | Maintainer steps for a later verification run. Learners can ignore this file. |

## How to run any program

1. Install Android Studio (lesson 01).
2. In Android Studio choose **File > Open** and select the `code` folder of a lesson (or your own `kotlin-basics` folder). Choose **Trust Project**.
3. Wait for the Gradle sync to finish (the Build window shows no red errors).
4. Open the `.kt` file with `fun main()` (for lesson 02 `src/main/kotlin/lesson02/Main.kt`) and click the green triangle beside `fun main()`.

## Not in the pack

`gradlew`, `gradlew.bat`, `gradle/wrapper/gradle-wrapper.jar` and `local.properties` are not shipped. Android Studio does not need them to open and run the project; to create the wrapper files use the **Gradle** tool window, **Tasks > build setup > wrapper**.

## Needs

Android Studio (latest stable) with its bundled JDK, and internet for the first Gradle sync. No prior programming knowledge.
Lesson text: `tutorials/kotlin/101-zero-to-hero/phase-1-kotlin-basics/` in the repository.

Next: Phase 2, Compose basics.
