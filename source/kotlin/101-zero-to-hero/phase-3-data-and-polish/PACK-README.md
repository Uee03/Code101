# Kotlin 101, Phase 3: Data and polish

Source pack for lessons 09 to 12 of **Kotlin 101 (Zero to Hero)**: a ViewModel, a network call, local storage and the finished task list app.
The optional source is also available at https://github.com/Uee03/Code101 under `source/kotlin/101-zero-to-hero/phase-3-data-and-polish/` (**Code > Download ZIP**, then extract the repository). Every file needed is shown in the lessons.

**Status: written (not run).** Nothing in this pack has been built or run yet.

| Folder | Lesson | You build / exercise |
|---|---|---|
| `09-viewmodel-and-stateflow` | ViewModel and StateFlow | UI state that survives rotation / `clearDone` |
| `10-coroutines-and-http-api` | Coroutines intro and calling an HTTP API | Retrofit call to a public practice API / countdown coroutine |
| `11-saving-data` | Saving data (DataStore, intro to Room) | Room table and a DataStore setting / two DAO queries |
| `12-project-task-list` | Project: a task list app | the finished app with filter, edit and TalkBack pass / summary line |

## Inside each lesson folder

| Folder or file | What it is |
|---|---|
| `code/` | The whole `TasksStart` Android project at the end of the lesson. Open this folder in Android Studio. |
| `exercise/starter/` | Only the files the exercise changes (full paths below `app/`). Copy them over the same paths in your project. |
| `exercise/solution/` | The same files, completed. Try first. |
| `verify.json` | Maintainer steps for a later verification run. Learners can ignore this file. |

## How to run any lesson

1. Android Studio with the Android 37 platform and an emulator or phone (lesson 05).
2. **File > Open**, choose a lesson's `code` folder, **Trust Project**, wait for the Gradle sync.
3. Press the green **Run** triangle. Lessons 10 and 12 need internet access for the sample tasks (a public practice server, https://jsonplaceholder.typicode.com, called only when you press the button).

## Not in the pack

`gradlew`, `gradlew.bat`, `gradle/wrapper/gradle-wrapper.jar` and `local.properties` are not shipped; Android Studio creates what it needs. No Room schema files are written (`exportSchema = false`); level 201 turns them on.

## Needs

Android Studio, the Android 37 platform, internet for the first sync. Pinned versions: AGP 9.5.1, Gradle 9.6.0, Kotlin 2.4.21, KSP 2.3.14, Compose BOM 2026.11.01, Lifecycle 2.11.1, Navigation Compose 2.10.2, Room 2.8.5, DataStore 1.3.0, Retrofit 3.0.0, OkHttp 5.5.1, kotlinx serialization 1.13.0, kotlinx coroutines 1.11.0.
Lesson text: `tutorials/kotlin/101-zero-to-hero/phase-3-data-and-polish/` in the repository.

Next: level 201, Hero to Super Hero.
