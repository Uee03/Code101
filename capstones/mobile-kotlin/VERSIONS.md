# Version and compatibility evidence

Documentation/repository checks were made on 2026-11-23 before the user stopped execution.
This records published pins, not a verification claim for the final source snapshot.
All chapter front matter is `verified: not yet run`; all state rows are `written (not run)`.

| Item | Pin | Official source checked |
|---|---|---|
| Android Gradle Plugin | 9.5.1 | https://developer.android.com/build/releases/agp-9-5-0-release-notes |
| Gradle wrapper | 9.6.0 | https://docs.gradle.org/9.6.0/userguide/gradle_wrapper.html |
| Kotlin; Compose compiler; serialization plugin | 2.4.21 | https://kotlinlang.org/docs/releases.html |
| Compose BOM | 2026.11.01 | https://developer.android.com/develop/ui/compose/bom/bom-mapping |
| Activity Compose | 1.13.0 | https://developer.android.com/jetpack/androidx/releases/activity |
| Lifecycle | 2.11.1 | https://developer.android.com/jetpack/androidx/releases/lifecycle |
| Navigation Compose | 2.10.2 | https://developer.android.com/jetpack/androidx/releases/navigation |
| Dagger/Hilt | 2.60.1 | https://github.com/google/dagger/releases |
| AndroidX Hilt | 1.4.0 | https://developer.android.com/jetpack/androidx/releases/hilt |
| KSP | 2.3.14 | https://github.com/google/ksp/releases |
| Room | 2.8.5 | https://developer.android.com/jetpack/androidx/releases/room |
| WorkManager | 2.12.0 | https://developer.android.com/jetpack/androidx/releases/work |
| Preferences DataStore | 1.3.0 | https://developer.android.com/jetpack/androidx/releases/datastore |
| Retrofit; kotlinx serialization converter | 3.0.0 | https://repo.maven.apache.org/maven2/com/squareup/retrofit2/retrofit/maven-metadata.xml |
| OkHttp | 5.5.1 | https://repo.maven.apache.org/maven2/com/squareup/okhttp3/okhttp/maven-metadata.xml |
| kotlinx serialization JSON | 1.13.0 | https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-serialization-json/maven-metadata.xml |
| kotlinx coroutines Android | 1.11.0 | https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-coroutines-android/maven-metadata.xml |
| AppAuth-Android | 0.11.1 | https://repo.maven.apache.org/maven2/net/openid/appauth/maven-metadata.xml and https://github.com/openid/AppAuth-Android |
| OpenAPI Generator CLI | 7.27.0 | https://repo.maven.apache.org/maven2/org/openapitools/openapi-generator-cli/maven-metadata.xml and https://openapi-generator.tech/docs/generators/kotlin/ |

## Compatibility decisions
- AGP 9.5's official table specifies Gradle 9.6.0, minimum JDK 17, build-tools 36.0.0 and base API 37 support.
- The installed platform is android-37.2, so the app explicitly selects release(37) with minorApiLevel=2. This clarifies the TDD's base compileSdk 37, not a targetSdk increase. targetSdk=36, minSdk=26, Java/Kotlin bytecode target=17.
- The installed Studio JBR reports Java 25.0.4. A global JDK 25 also exists. The source ships no machine JDK or SDK path.
- AGP 9 built-in Kotlin is enabled; no org.jetbrains.kotlin.android is applied. Additional generated Kotlin is registered through AndroidSourceSet.kotlin, not java or the legacy Kotlin source sets. Source: https://developer.android.com/build/migrate-to-built-in-kotlin.
- Compose BOM 2026.11.01 is explicitly listed in the mapping page. The BOM does not select the Compose compiler version; that plugin follows Kotlin 2.4.21.
- AndroidX Hilt 1.4.0 uses hilt-lifecycle-viewmodel-compose and its lifecycle.viewmodel.compose import, avoiding the deprecated hilt-navigation-compose entry point.
- The generator is a pinned CLI JavaExec Gradle task rather than the generator Gradle plugin. It still provides one openApiGenerate task with the TDD's Kotlin/Retrofit/coroutine/java8 settings. CollectionFormats is generated; AnyType is mapped to JsonElement. No generated source is hand-edited.
- Gradle's generated wrapper jar and launchers are shipped. gradle-wrapper.properties also pins the official distribution SHA-256. Regeneration is shown in every chapter.

No dependency upgrade was substituted for a pinned version. Resolved dependency graphs and final builds remain for a later explicit verification session.
