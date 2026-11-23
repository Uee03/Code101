# Kotlin 201, Phase 2: Network and auth

Source pack for lessons 04 to 06 of **Kotlin 201 (Hero to Super Hero)**: a generated API client, RFC 9457 problem details, and OIDC PKCE sign-in with AppAuth. The app is **Tasks Mini** (package `com.code101.tasks`, application id `com.code101.tasks.lab`), a thin slice of `capstones/mobile-kotlin`.
The optional source is also available at https://github.com/Uee03/Code101 under `source/kotlin/201-hero-to-super-hero/phase-2-network-and-auth/` (**Code > Download ZIP**). Every file needed is shown in the lessons (the generated client and the copied contract are the exception: they are produced by `openApiGenerate`, see lesson 04).

**Status: written (not run).** Nothing in this pack has been built or run yet.

| Folder | Lesson | You build / exercise |
|---|---|---|
| `04-generated-api-client` | A generated API client with Retrofit and OkHttp | generator task, network module, `/health` line / `callerName()` |
| `05-errors-and-problem-details` | Errors and RFC 9457 problem details | `ApiProblem`, parser, remote repository, field errors / 413 message |
| `06-oidc-pkce-appauth` | OIDC PKCE login with AppAuth and secure token storage | Keycloak sign-in, Keystore vault, bearer interceptor / `needsRefresh` |

Each lesson folder has `code/` (the whole project at the end of the lesson), `exercise/starter/`, `exercise/solution/` (only the changed files, full paths below `app/`) and `verify.json` (maintainer steps for a later run; learners can ignore it).

## Running against the platform

Lessons 04 to 06 need the platform (Keycloak on 8180) and one backend (ASP.NET, Python or Go) on 8000. Follow the manual session in `capstones/mobile-kotlin/tutorials/phase-5-ship/05-build-run-ship.md`. On an emulator the API is `http://10.0.2.2:8000` (set by `BuildConfig`) and Keycloak is reached with `adb reverse tcp:8180 tcp:8180`. Install only one Kotlin app at a time: they share the redirect scheme `com.code101.tasks`.

## Not in the pack

`gradlew`, `gradlew.bat`, the wrapper jar and `local.properties` (Android Studio creates them). No keystore, signing key or secrets; the OIDC client is public and uses PKCE.

## Needs

Everything from phase 1 plus Retrofit 3.0.0, OkHttp 5.5.1, OpenAPI Generator CLI 7.27.0 (run by Gradle), AppAuth 0.11.1 and DataStore 1.3.0 (lesson 06).
Lesson text: `tutorials/kotlin/201-hero-to-super-hero/phase-2-network-and-auth/`.

Next: phase 3, Offline and quality.
