# Kotlin track state

Last updated: 2026-11-23. Nothing in this track has been built or run (no checks were allowed). All written lessons carry the draft notice and `verified: not yet run`.

## 101 Zero to Hero (12 of 12 written)
| Lesson | Phase | Status |
|---|---|---|
| 01-install-and-first-program | phase-1-kotlin-basics | written (not run) |
| 02-variables-types-null-safety | phase-1-kotlin-basics | written (not run) |
| 03-functions-collections-lambdas | phase-1-kotlin-basics | written (not run) |
| 04-classes-data-classes-objects | phase-1-kotlin-basics | written (not run) |
| 05-first-compose-app | phase-2-compose-basics | written (not run) |
| 06-layouts-and-material-3 | phase-2-compose-basics | written (not run) |
| 07-state-and-recomposition | phase-2-compose-basics | written (not run) |
| 08-lists-and-navigation | phase-2-compose-basics | written (not run) |
| 09-viewmodel-and-stateflow | phase-3-data-and-polish | written (not run) |
| 10-coroutines-and-http-api | phase-3-data-and-polish | written (not run) |
| 11-saving-data | phase-3-data-and-polish | written (not run) |
| 12-project-task-list | phase-3-data-and-polish | written (not run) |

PACK-README.md exists for all three 101 phases.

## 201 Hero to Super Hero (10 of 10 written)
| Lesson | Phase | Status |
|---|---|---|
| 01 MVVM and clean layers | phase-1-architecture | written (not run) |
| 02 Dependency injection with Hilt | phase-1-architecture | written (not run) |
| 03 Coroutines and Flow in depth | phase-1-architecture | written (not run) |
| 04 A generated API client with Retrofit/OkHttp | phase-2-network-and-auth | written (not run) |
| 05 Errors and RFC 9457 problem details | phase-2-network-and-auth | written (not run) |
| 06 OIDC PKCE login with AppAuth and secure token storage | phase-2-network-and-auth | written (not run) |
| 07 Room | phase-3-offline-and-quality | written (not run) |
| 08 WorkManager and an offline sync queue | phase-3-offline-and-quality | written (not run) |
| 09 Accessibility and performance basics | phase-3-offline-and-quality | written (not run) |
| 10 Project: a task app against the platform contract | phase-3-offline-and-quality | written (not run) |

PACK-README.md exists for all three 201 phases. No 301 level is planned for this track.

## Known uncertainties for the first verification run
- Android Studio menu names (Vector Asset, Device Manager, SDK Manager) and the exact Run-window wording were written from documentation, not seen.
- Gradle opening of a plain Kotlin project without the wrapper jar (101 lessons 01 to 04) relies on the IDE using the wrapper properties.
- Version pins are copied from the capstone (`VERSIONS.md`); the Hilt/KSP/AGP 9 combination and the Room schema, `toRoute` in `SavedStateHandle` and `repeatOnLifecycle` imports have not been compiled.
- `verify.json` files need the wrapper files copied in (see each `note`) and an Android SDK.
- 201: 07's exercise (`description` column, version 2) conflicts with 08's migration; the pack README says to start 08 from 07's `code/`. The hand-written `MIGRATION_1_2` must equal the exported `2.json` schema. `Modifier.semantics(mergeDescendants)` with a nested button (201-10) and the `LocalLifecycleOwner` import from `androidx.lifecycle.compose` are unverified.
- 201-10's manual session needs the backend and Keycloak; expected results are described, not seen.
