# Kotlin glossary

Definitions follow the first introduction in the lessons (101 first, then 201).

## 101-01 Install and first program
- **IDE:** one program with an editor, code helper and run buttons. **Android Studio:** the official Android IDE.
- **SDK:** the Android tools and libraries Studio downloads. **Gradle:** the tool that reads build files, downloads dependencies and builds.
- **project / folder / file:** a folder with code and build instructions; `.kt` marks a Kotlin file.
- **program, function, `main`, `println`, string:** instructions; a named block; the start of a program; prints a line; text in quotes.
- **version catalog:** `gradle/libs.versions.toml`, one place for versions. **wrapper:** pins the Gradle version.

## 101-02 Variables, types, null safety
- **`val` / `var`:** unchangeable / changeable variable. **type, type inference:** kind of value; Kotlin works it out.
- **string template:** `$name` inside text. **expression:** code that has a value (`if` is one).
- **`null`, nullable type `T?`, safe call `?.`, Elvis `?:`:** no value; may hold null; null-safe access; fallback value.

## 101-03 Functions, collections, lambdas
- **parameter / argument / default value / named argument / return value.** **`List`, `MutableList`, `Map`, `for`, `when`.**
- **lambda, `it`:** a small unnamed function; the single parameter name.

## 101-04 Classes
- **class / object (instance) / property / method / constructor.** **`data class`, `copy`.** **`enum class`.** **`object` declaration.** **`sealed interface`:** a closed set of states, exhaustive `when`.

## 101-05 First Compose app
- **manifest, activity, resource, `strings.xml`, namespace, applicationId.** **composable function, `@Composable`, `Modifier`, `Scaffold`, preview, theme.** **emulator, AVD.** **BOM:** one version for matching Compose libraries. **AGP:** Android Gradle Plugin.

## 101-06 Layouts and Material 3
- **`Column`, `Row`, `Box`, `Arrangement`, `Alignment`, `dp`/`sp`, `Card`, `TopAppBar`, `FloatingActionButton`.** **vector drawable:** XML picture. **`contentDescription`, decorative image, TalkBack.**

## 101-07 State
- **state, recomposition, `remember`, `mutableStateOf`, `rememberSaveable`, `mutableStateListOf`, `by` delegate, state hoisting.**

## 101-08 Lists and navigation
- **`LazyColumn`, `items`, `key`, `NavHost`, `NavController`, route, argument, back stack.**

## 101-09 ViewModel
- **`ViewModel`, UI state, `StateFlow`/`MutableStateFlow`, `update`, unidirectional data flow, `collectAsStateWithLifecycle`.**

## 101-10 Coroutines and HTTP
- **coroutine, `suspend`, `launch`, `viewModelScope`, structured concurrency.** **HTTP, API, endpoint, JSON, DTO, Retrofit, OkHttp, serialization, permission.**

## 101-11 Saving data
- **DataStore, preference key, Room, entity, DAO, SQL, `@Query`, KSP, repository, singleton, `Application`.**

## 101-12 Project
- **filter, enum `entries`, `FilterChip`, heading (accessibility), live region.**

## 201-01 MVVM and clean layers
- **MVVM; layers `ui`, `domain`, `data`; dependency rule `ui -> domain <- data`.** **domain model, repository interface, generic `UiState<T>`, type-safe route (`@Serializable`), use case, module.** **SHA-256 pinned wrapper.**

## 201-02 Hilt
- **dependency, constructor injection, graph, component, scope, `@Inject`, `@Module`, `@Binds`, `@Provides`, `@Singleton`, `@HiltViewModel`, `@HiltAndroidApp`, `@AndroidEntryPoint`, `SavedStateHandle`.**

## 201-03 Coroutines and Flow in depth
- **structured concurrency, cancellation (`CancellationException`), dispatcher, main-safety, qualifier.** **cold flow vs `StateFlow`, `combine`, `debounce`, `flatMapLatest`, `stateIn(WhileSubscribed)`, `Channel`, one-off event, observe-and-refresh repository.**

## 201-04 Generated API client
- **OpenAPI contract, code generator, Retrofit, OkHttp, interceptor, base URL, cleartext traffic (debug only), `BuildConfig`, `10.0.2.2`, wire format, `Response<T>`.**

## 201-05 Errors and problem details
- **RFC 9457 problem details (`type`, `title`, `status`, `detail`, `errors`), JSON pointer, `ApiFailure`, error mapping, field error, `Retry-After`.**

## 201-06 OIDC PKCE login
- **OIDC, authorization code flow, PKCE (code verifier and challenge), AppAuth, redirect URI, access / refresh token, Keystore, AES-GCM, single-flight refresh, `Authenticator`, Keycloak realm, `adb reverse`.**

## 201-07 Room
- **entity, DAO, `@Query`, `@Transaction`, schema export, migration, single source of truth, offline-first, KSP.**

## 201-08 WorkManager and offline sync
- **outbox, idempotency key, retry with exponential backoff and jitter, `CoroutineWorker`, `@HiltWorker`, constraints, unique work, `Result.retry()`, parking a failed change.**

## 201-09 Accessibility and performance
- **semantics, merged semantics, click label, content description, touch target (48 dp), live region, contrast ratio, font scale, plural resource, `contentType`, `derivedStateOf`, skipping, baseline profile, Macrobenchmark.**

## 201-10 Project
- **optimistic update, `If-Match`, ETag, 412 Precondition Failed, 428 Precondition Required, server wins, destructive action and confirmation, manual test session.**
