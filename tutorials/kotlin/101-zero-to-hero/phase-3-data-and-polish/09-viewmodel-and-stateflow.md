---
track: kotlin
level: 101
phase: 3
phase_name: data-and-polish
lesson: 09
title: ViewModel and StateFlow
time: 60-75 min
prerequisites: [05, 06, 07, 08]
versions: { lifecycle: "2.11.1", kotlinx-coroutines: "1.11.0", compose-bom: "2026.11.01", kotlin: "2.4.21" }
verified: not yet run
source: source/kotlin/101-zero-to-hero/phase-3-data-and-polish/09-viewmodel-and-stateflow/
assets: []
---

# 09. ViewModel and StateFlow

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- explain why the list was lost on rotation and what a `ViewModel` is;
- hold a screen's data in one `UiState` object inside a `MutableStateFlow`;
- collect that flow in Compose with `collectAsStateWithLifecycle`;
- change the state only through small functions of the ViewModel.

## Recap
1. What does `rememberSaveable` keep that `remember` does not? <details><summary>Answer</summary>Simple values across an activity recreation such as a rotation.</details>
2. Why does `LazyColumn` need keys? <details><summary>Answer</summary>So Compose can tell the rows apart when items are added or removed.</details>
3. What does `copy` do on a data class? <details><summary>Answer</summary>It creates a changed copy and leaves the original unchanged.</details>

## Why it matters
A restaurant's waiter takes your order, but the kitchen keeps the real order book. If the waiter changes shift (the screen is recreated by a rotation), the order must not vanish. The **ViewModel** is the order book: it lives longer than the screen. The composables are the waiter: they show what is in the book and pass new orders to it. Keeping data and the rules for changing it in one place also keeps your screens simple.

## What you will build
The same app as in lesson 08, but the task list and the typed text live in a `TasksViewModel`. Rotating the phone no longer loses your tasks.

## Before you start
- The project from lesson 08.
- Time: about 60 to 75 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/kotlin/101-zero-to-hero/phase-3-data-and-polish/09-viewmodel-and-stateflow/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

Files that stay **exactly as in lesson 08**: `settings.gradle.kts`, `build.gradle.kts`, `gradle.properties`, `gradle/wrapper/gradle-wrapper.properties`, `.gitignore`, the manifest, `strings.xml`, `Theme.kt`, `model/Task.kt`, `AddTaskBar.kt`, `TaskCard.kt`, `DetailScreen.kt`, `MainActivity.kt`, the four icons and the licence file. Changed or new: `libs.versions.toml`, `app/build.gradle.kts`, `TasksViewModel.kt` (new), `HomeScreen.kt` and `TasksApp.kt`.

New words: `ViewModel`, UI state, `StateFlow`, `MutableStateFlow`, `update`, unidirectional data flow, lifecycle, `collectAsStateWithLifecycle`.

## Steps

### Step 1. Add three libraries
**File: `gradle/libs.versions.toml`**
```toml
[versions]
agp = "9.5.1"
kotlin = "2.4.21"
compose = "2026.11.01"
activity = "1.13.0"
navigation = "2.10.2"
lifecycle = "2.11.1"
coroutines = "1.11.0"

[libraries]
compose-bom = { module = "androidx.compose:compose-bom", version.ref = "compose" }
compose-material3 = { module = "androidx.compose.material3:material3" }
compose-ui = { module = "androidx.compose.ui:ui" }
compose-ui-tooling = { module = "androidx.compose.ui:ui-tooling" }
compose-ui-tooling-preview = { module = "androidx.compose.ui:ui-tooling-preview" }
activity-compose = { module = "androidx.activity:activity-compose", version.ref = "activity" }
navigation = { module = "androidx.navigation:navigation-compose", version.ref = "navigation" }
lifecycle-runtime = { module = "androidx.lifecycle:lifecycle-runtime-compose", version.ref = "lifecycle" }
lifecycle-viewmodel = { module = "androidx.lifecycle:lifecycle-viewmodel-compose", version.ref = "lifecycle" }
coroutines = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-android", version.ref = "coroutines" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
kotlin-compose = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
```
New: `lifecycle` and `coroutines` versions and three libraries: the lifecycle helpers for Compose, the Compose ViewModel helper, and **kotlinx.coroutines**, which contains `StateFlow`.

**File: `app/build.gradle.kts`**
```kotlin
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
}

android {
    namespace = "com.code101.taskstart"
    compileSdk { version = release(37) }

    defaultConfig {
        applicationId = "com.code101.taskstart"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    buildFeatures {
        compose = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

dependencies {
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.material3)
    implementation(libs.compose.ui)
    implementation(libs.compose.ui.tooling.preview)
    implementation(libs.activity.compose)
    implementation(libs.navigation)
    implementation(libs.lifecycle.runtime)
    implementation(libs.lifecycle.viewmodel)
    implementation(libs.coroutines)
    debugImplementation(libs.compose.ui.tooling)
}
```
Three new `implementation` lines. Sync Gradle.

### Step 2. The ViewModel
Create `ui/TasksViewModel.kt`.

**File: `app/src/main/kotlin/com/code101/taskstart/ui/TasksViewModel.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.lifecycle.ViewModel
import com.code101.taskstart.model.Task
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

data class TasksUiState(
    val tasks: List<Task> = listOf(
        Task(1, "Buy milk"),
        Task(2, "Call dentist"),
        Task(3, "Pay rent", done = true),
    ),
    val draft: String = "",
)

class TasksViewModel : ViewModel() {
    private val _uiState = MutableStateFlow(TasksUiState())
    val uiState: StateFlow<TasksUiState> = _uiState.asStateFlow()

    fun onDraftChange(text: String) {
        _uiState.update { it.copy(draft = text) }
    }

    fun addTask() {
        _uiState.update { state ->
            val title = state.draft.trim()
            if (title.isEmpty()) {
                state
            } else {
                val nextId = (state.tasks.maxOfOrNull { it.id } ?: 0) + 1
                state.copy(tasks = state.tasks + Task(nextId, title), draft = "")
            }
        }
    }

    fun toggle(id: Int) {
        _uiState.update { state ->
            state.copy(
                tasks = state.tasks.map { task ->
                    if (task.id == id) task.copy(done = !task.done) else task
                },
            )
        }
    }

    fun delete(id: Int) {
        _uiState.update { state ->
            state.copy(tasks = state.tasks.filterNot { it.id == id })
        }
    }
}
```

### Step 3. The home screen only displays
**File: `app/src/main/kotlin/com/code101/taskstart/ui/HomeScreen.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.code101.taskstart.R
import com.code101.taskstart.model.Task
import com.code101.taskstart.ui.theme.TasksTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    state: TasksUiState,
    onDraftChange: (String) -> Unit,
    onAdd: () -> Unit,
    onToggle: (Int) -> Unit,
    onOpen: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(title = { Text(stringResource(R.string.app_name)) })
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .padding(innerPadding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            AddTaskBar(
                draft = state.draft,
                onDraftChange = onDraftChange,
                onAdd = onAdd,
            )
            Text(
                text = stringResource(R.string.open_count, state.tasks.count { !it.done }),
                style = MaterialTheme.typography.titleMedium,
            )
            if (state.tasks.isEmpty()) {
                Text(text = stringResource(R.string.empty_list))
            }
            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(state.tasks, key = { it.id }) { task ->
                    TaskCard(
                        task = task,
                        onToggle = { onToggle(task.id) },
                        onOpen = { onOpen(task.id) },
                    )
                }
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
fun HomeScreenPreview() {
    TasksTheme {
        HomeScreen(
            state = TasksUiState(
                tasks = listOf(Task(1, "Buy milk"), Task(2, "Pay rent", done = true)),
            ),
            onDraftChange = { },
            onAdd = { },
            onToggle = { },
            onOpen = { },
        )
    }
}
```
Look at what disappeared: no `remember`, no `rememberSaveable`. The screen has no state of its own, only parameters.

### Step 4. Connect the ViewModel to the screens
**File: `app/src/main/kotlin/com/code101/taskstart/ui/TasksApp.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument

@Composable
fun TasksApp(viewModel: TasksViewModel = viewModel()) {
    val navController = rememberNavController()
    val state by viewModel.uiState.collectAsStateWithLifecycle()

    NavHost(navController = navController, startDestination = "home") {
        composable("home") {
            HomeScreen(
                state = state,
                onDraftChange = viewModel::onDraftChange,
                onAdd = viewModel::addTask,
                onToggle = viewModel::toggle,
                onOpen = { id -> navController.navigate("detail/$id") },
            )
        }
        composable(
            route = "detail/{taskId}",
            arguments = listOf(navArgument("taskId") { type = NavType.IntType }),
        ) { entry ->
            val taskId = entry.arguments?.getInt("taskId")
            DetailScreen(
                task = state.tasks.firstOrNull { it.id == taskId },
                onBack = { navController.popBackStack() },
                onDelete = {
                    if (taskId != null) {
                        viewModel.delete(taskId)
                    }
                    navController.popBackStack()
                },
            )
        }
    }
}
```
Predict before you run: add the task "Walk dog", then rotate the device. What happens now, compared with lesson 07 and 08? What happens if you then close the app completely from the recent-apps screen and open it again?

## Run it
Run the app, add "Walk dog", toggle a task, and rotate the device (emulator toolbar rotate buttons).

Expected result (described, not yet seen): after rotating, "Walk dog" and the toggled state are still there, and text typed but not added is also still in the field. After you remove the app from recent apps and start it again, the list is back to the three original tasks, because a ViewModel does not outlive the app's process. Lesson 11 stores tasks permanently.

## How it works
**ViewModel.** `class TasksViewModel : ViewModel()` is created by `viewModel()` the first time the screen asks, and Android keeps it alive across rotations, giving the *same* object to the new activity. It is destroyed when the user leaves the screen for good. Use it for the screen's data and for the rules that change that data; do not put composables or `Context` in it.

**UI state.** `TasksUiState` is a `data class` holding everything the screen shows: the task list and the typed draft. One immutable object per moment: easy to read, to compare and to preview. A new state is made with `copy`, never by editing the old one.

**StateFlow.** A **flow** is a stream of values over time. A `StateFlow` is a flow that always has a current value (`.value`) and tells everyone who listens when it changes. `MutableStateFlow` is the version you can write to; it stays `private` as `_uiState` (the underscore means "internal twin"). The public `uiState: StateFlow<TasksUiState>` is read-only (`asStateFlow()`). Misconception: the screen never changes the state itself; it can only call the functions `onDraftChange`, `addTask`, `toggle` and `delete`.

**`update`.** `_uiState.update { state -> ... }` computes the new state from the current one and stores it safely, even if two changes arrive at nearly the same time.

**Collecting in Compose.** `collectAsStateWithLifecycle()` turns the flow into a Compose `State`, so a new value makes the screen recompose. The "with lifecycle" part stops collecting while the app is not visible, which saves battery. `by` unwraps the state, as in lesson 07.

**Data flows one way.** State goes down (ViewModel, then screens); events go up (taps call ViewModel functions, which create new state). This is called **unidirectional data flow** and is the pattern recommended by Android's architecture guide. The ViewModel does not know about composables, so it could also feed a different UI.

**What a ViewModel does not do.** It survives rotation, not the death of the app's process. Anything the user must never lose is saved in storage (lesson 11).

## Try it
1. **Guided:** the starter `TasksViewModel.kt` has one empty function, `clearDone()`. Fill it so it removes every done task; the other functions stay as they are.

**File: `app/src/main/kotlin/com/code101/taskstart/ui/TasksViewModel.kt`** (last function only; keep the rest)
```kotlin
    fun clearDone() {
        // TODO: remove every task that is done, keep the others
    }
```
Expected: after the change, calling `clearDone()` on the three sample tasks leaves "Buy milk" and "Call dentist".
2. **Change:** add `<string name="clear_done">Clear done tasks</string>` to `strings.xml`, put a `TextButton` with that text under the open-count heading in `HomeScreen` and give `HomeScreen` a new parameter `onClearDone: () -> Unit` that `TasksApp` fills with `viewModel::clearDone`. Remember to update the preview call too.
3. **Stretch (optional):** disable the button when no task is done.

<details><summary>Solution</summary>

**File: `app/src/main/kotlin/com/code101/taskstart/ui/TasksViewModel.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.lifecycle.ViewModel
import com.code101.taskstart.model.Task
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

data class TasksUiState(
    val tasks: List<Task> = listOf(
        Task(1, "Buy milk"),
        Task(2, "Call dentist"),
        Task(3, "Pay rent", done = true),
    ),
    val draft: String = "",
)

class TasksViewModel : ViewModel() {
    private val _uiState = MutableStateFlow(TasksUiState())
    val uiState: StateFlow<TasksUiState> = _uiState.asStateFlow()

    fun onDraftChange(text: String) {
        _uiState.update { it.copy(draft = text) }
    }

    fun addTask() {
        _uiState.update { state ->
            val title = state.draft.trim()
            if (title.isEmpty()) {
                state
            } else {
                val nextId = (state.tasks.maxOfOrNull { it.id } ?: 0) + 1
                state.copy(tasks = state.tasks + Task(nextId, title), draft = "")
            }
        }
    }

    fun toggle(id: Int) {
        _uiState.update { state ->
            state.copy(
                tasks = state.tasks.map { task ->
                    if (task.id == id) task.copy(done = !task.done) else task
                },
            )
        }
    }

    fun delete(id: Int) {
        _uiState.update { state ->
            state.copy(tasks = state.tasks.filterNot { it.id == id })
        }
    }

    fun clearDone() {
        _uiState.update { state ->
            state.copy(tasks = state.tasks.filterNot { it.done })
        }
    }
}
```
`filterNot { it.done }` keeps the tasks for which `done` is false; `copy` makes the new state.

</details>

## Check yourself
1. Why does the list survive a rotation now? <details><summary>Answer</summary>It is held by the ViewModel, which Android keeps alive across the activity's recreation.</details>
2. Why is `_uiState` private and `uiState` public? <details><summary>Answer</summary>Only the ViewModel may change the state; the screens can read it and call its functions.</details>
3. What does the `WithLifecycle` in `collectAsStateWithLifecycle` do? <details><summary>Answer</summary>It stops collecting while the app is in the background and restarts when visible again.</details>
4. Predict: you change `state.tasks + Task(...)` to `state.tasks.add(Task(...))`. Will it compile? <details><summary>Answer</summary>No: `tasks` is a read-only `List`, it has no `add`. Build a new list instead.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Unresolved reference 'viewModel'` (typical message) | Missing import `androidx.lifecycle.viewmodel.compose.viewModel` or the dependency | Add `lifecycle-viewmodel-compose` (Step 1) and the import |
| `Unresolved reference 'collectAsStateWithLifecycle'` (typical) | Missing `lifecycle-runtime-compose` or the import | Add the dependency and `androidx.lifecycle.compose.collectAsStateWithLifecycle` |
| The screen does not update after a change | The state was changed in place (a mutable list) instead of making a new object | Use `copy` and new lists, and `update` |
| `Type mismatch` between `() -> Unit` and a function reference (typical) | Parameter and function signatures differ | Compare `onToggle: (Int) -> Unit` with `fun toggle(id: Int)` |
| Tasks are gone after the app is closed | A ViewModel lives only as long as the process | Expected; lesson 11 saves them |

## Best practice
Expose immutable state from the ViewModel (`StateFlow`), keep the mutable one private, and let the UI send events to named ViewModel functions. Source: Guide to app architecture https://developer.android.com/topic/architecture and ViewModel overview https://developer.android.com/topic/libraries/architecture/viewmodel

## Going further
- StateFlow and SharedFlow: https://kotlinlang.org/docs/flow.html and https://developer.android.com/kotlin/flow/stateflow-and-sharedflow
- Level 201 (lesson 01) turns this pattern into clean layers.

## Summary
- You explained why a ViewModel keeps data through a rotation.
- You modelled the screen as one `TasksUiState` inside a `StateFlow`.
- You collected it with `collectAsStateWithLifecycle` and changed it only through ViewModel functions.

## Next lesson
10. Coroutines intro and calling an HTTP API: waiting for slow work without freezing the screen.
