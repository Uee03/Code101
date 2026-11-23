# Kotlin 201, Phase 3: Offline and quality

Source pack for lessons 07 to 10 of **Kotlin 201 (Hero to Super Hero)**: a Room cache, an offline outbox with WorkManager, accessibility and performance basics, and a project that completes tasks with `If-Match` and adds an account screen. The app is **Tasks Mini** (package `com.code101.tasks`, application id `com.code101.tasks.lab`), a thin slice of `capstones/mobile-kotlin`.
The optional source is also available at https://github.com/Uee03/Code101 under `source/kotlin/201-hero-to-super-hero/phase-3-offline-and-quality/` (**Code > Download ZIP**). Every file needed is shown in the lessons (the generated client and the copied contract are the exception: they are produced by `openApiGenerate`, see lesson 04).

**Status: written (not run).** Nothing in this pack has been built or run yet.

| Folder | Lesson | You build / exercise |
|---|---|---|
| `07-room` | Room: a local cache you can trust | entities, DAO, database v1, offline-first repository / `Migrations.kt` |
| `08-workmanager-offline-sync` | WorkManager and an offline sync queue | outbox, database v2 + migration, `SyncWorker`, banner / `RetryPolicy` |
| `09-accessibility-and-performance` | Accessibility and performance basics | merged semantics, plurals, `contentType`, `derivedStateOf` / `ProjectCard` |
| `10-project-task-app` | Project: a task app against the platform contract | complete task with `If-Match`, account screen / `canComplete()` |

Each lesson folder has `code/` (the whole project at the end of the lesson), `exercise/starter/`, `exercise/solution/` (only the changed files, full paths below `app/`) and `verify.json` (maintainer steps for a later run; learners can ignore it).

## Notes

- **Lesson 07's exercise versus lesson 08.** The exercise of lesson 07 adds a `description` column with a migration to version 2. Lesson 08 also moves the database to version 2 (the outbox). They conflict: start lesson 08 from lesson 07's `code/` folder, not from your exercise result, and uninstall the app from the emulator if you ran the exercise.
- Lessons 09 and 10 each build on the previous lesson's `code/` folder. Lesson 10 does not change the database version.
- Lesson 08 and 10 run best against the platform (backend on 8000, Keycloak on 8180 with `adb reverse tcp:8180 tcp:8180`); see `capstones/mobile-kotlin/tutorials/phase-5-ship/05-build-run-ship.md`. Install only one Kotlin app at a time: they share the redirect scheme `com.code101.tasks`.
- The accessibility checks of lesson 09 (TalkBack, font scale, Accessibility Scanner) and the manual session of lesson 10 are manual by design: the course has no automated test lessons.

## Not in the pack

`gradlew`, `gradlew.bat`, the wrapper jar and `local.properties` (Android Studio creates them). No keystore, signing key or secrets; the OIDC client is public and uses PKCE.

## Needs

Everything from phase 2 plus Room 2.8.5 with KSP 2.3.14 (lesson 07) and WorkManager 2.12.0 with AndroidX Hilt 1.4.0 (lesson 08).
Lesson text: `tutorials/kotlin/201-hero-to-super-hero/phase-3-offline-and-quality/`.

Next: the capstone `capstones/mobile-kotlin`.
