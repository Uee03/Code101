# Kotlin track brief (Kotlin + Jetpack Compose)

Levels: **101 Zero to Hero** (12 lessons, 3 phases, written) and **201 Hero to Super Hero** (10 lessons, 3 phases, all written, not run). No 301 level.
Rule in force: no checks, no tests of any kind, no unit-test lessons. Every lesson carries the draft notice and `verified: not yet run`.

## 101 plan (written)
| Phase | Lesson | Build / exercise |
|---|---|---|
| 1 kotlin-basics | 01 Install Android Studio and run your first Kotlin program | `KotlinBasics` Gradle project, hello / recipe card |
| 1 | 02 Variables, types and null safety | café report / stock update |
| 1 | 03 Functions, collections and lambdas | collections demo / short titles |
| 1 | 04 Classes, data classes and objects | task types, sealed `LoadState` / bookshelf |
| 2 compose-basics | 05 Your first Compose app | `TasksStart` project, greeting / subtitle |
| 2 | 06 Layouts and Material 3 | home screen, four CC0 icons converted to vector drawables / profile card |
| 2 | 07 State and recomposition (remember) | add and toggle tasks / counter with reset |
| 2 | 08 Lists (LazyColumn) and navigation | list and detail screens / empty state |
| 3 data-and-polish | 09 ViewModel and StateFlow | UI state / `clearDone` |
| 3 | 10 Coroutines intro and calling an HTTP API | Retrofit call to jsonplaceholder / countdown |
| 3 | 11 Saving data (DataStore, intro to Room) | Room table and setting / DAO queries |
| 3 | 12 Project: a task list app | filters, edit, TalkBack pass / summary line |

## 201 plan
| Phase | Lesson | Status |
|---|---|---|
| 1 architecture | 01 MVVM and clean layers | written (not run) |
| 1 | 02 Dependency injection with Hilt | written (not run) |
| 1 | 03 Coroutines and Flow in depth | written (not run) |
| 2 network-and-auth | 04 A generated API client with Retrofit/OkHttp (as in the TDD) | written (not run) |
| 2 | 05 Errors and RFC 9457 problem details | written (not run) |
| 2 | 06 OIDC PKCE login with AppAuth and secure token storage (Keycloak realm tasksteams, redirect com.code101.tasks:/oauth2redirect) | written (not run) |
| 3 offline-and-quality | 07 Room | written (not run) |
| 3 | 08 WorkManager and an offline sync queue | written (not run) |
| 3 | 09 Accessibility and performance basics (TalkBack, baseline profiles intro) | written (not run) |
| 3 | 10 Project: a task app against the platform contract (then continue with `capstones/mobile-kotlin`) | written (not run) |

Design of the 201 app (as written): the app is **Tasks Mini** (package `com.code101.tasks`, application id `com.code101.tasks.lab`). Lesson 04 adds the OpenAPI Generator CLI task, `openapi/generator-config.json`, `WireJson`, `NetworkModule` and a `/health` check (the API needs a token for everything else); 05 adds `ProblemParser`/`ApiFailure` and a remote-backed repository; 06 adds `AuthConfig`, `TokenVault`, `AuthStateManager`, `AuthInterceptor` and a login screen, following the capstone files; 07 swaps the cache for Room (schema export, `Migration`); 08 adds the outbox, `SyncWorker` (HiltWorker) and the banner; 09 adds semantics and performance notes; 10 integrates and adds complete-task with `If-Match`.

## Versions (identical to `capstones/mobile-kotlin/VERSIONS.md`)
AGP 9.5.1, Gradle 9.6.0 (SHA-256 pinned from 201), Kotlin 2.4.21 (Compose compiler and serialization plugins the same), KSP 2.3.14, Compose BOM 2026.11.01, Activity Compose 1.13.0, Lifecycle 2.11.1, Navigation Compose 2.10.2, Hilt 2.60.1 / AndroidX Hilt 1.4.0, Room 2.8.5, WorkManager 2.12.0, DataStore 1.3.0, Retrofit and converter 3.0.0, OkHttp 5.5.1, kotlinx serialization 1.13.0, kotlinx coroutines 1.11.0, AppAuth 0.11.1, OpenAPI Generator 7.27.0. compileSdk 37 (`release(37)`; the capstone adds `minorApiLevel = 2` for its author's platform 37.2), targetSdk 36, minSdk 26, JVM target 17.

## Sources (Tier 1)
- https://kotlinlang.org/docs/coding-conventions.html and https://kotlinlang.org/docs/home.html
- https://developer.android.com/develop/ui/compose, https://developer.android.com/topic/architecture, https://developer.android.com/kotlin/style-guide
- https://developer.android.com/build/releases/agp-9-5-0-release-notes

## Scope choices
- 101 lessons 01 to 04 are a plain Kotlin/Gradle project opened in Android Studio (no emulator); lesson 05 on is the Android app `TasksStart`. Learners type files by hand (New > File) or open the pack; `local.properties` and the wrapper jar come from Android Studio.
- The 101 HTTP lesson calls the public practice API jsonplaceholder (HTTPS, no data sent); the 201 lessons call the platform contract.
- Icons: four CC0 icons from `assets/art` (`ui/plus`, `ui/check`, `files/trash`, `ui/list`) hand-converted, with Vector Asset Studio shown as the alternative.
- Draft files: `ClickCounter.kt` (101-07) exists only for the interactive preview.
