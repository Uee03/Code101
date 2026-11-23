---
track: kotlin
level: 101
phase: 3
phase_name: data-and-polish
lesson: 12
title: "Project: a task list app"
time: 90-120 min (two sittings, break after Step 5)
prerequisites: [05, 06, 07, 08, 09, 10, 11]
versions: { room: "2.8.5", datastore-preferences: "1.3.0", compose-bom: "2026.11.01", kotlin: "2.4.21" }
verified: not yet run
source: source/kotlin/101-zero-to-hero/phase-3-data-and-polish/12-project-task-list/
assets: [ui/plus, ui/check, files/trash, ui/list]
---

# 12. Project: a task list app

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- finish a small app by combining Compose, ViewModel, Room, DataStore and a network call;
- add a persisted filter and an edit screen without breaking the existing layers;
- test the app with a screen reader (TalkBack) and fix what you hear;
- describe, in your own words, what each layer of your app does.

## Recap
1. Why does the screen show a task list without a "refresh" button? <details><summary>Answer</summary>Room returns a `Flow` that emits whenever the table changes.</details>
2. What is a repository for? <details><summary>Answer</summary>It hides where data comes from from the ViewModel.</details>
3. What does `contentDescription = null` mean? <details><summary>Answer</summary>The image is decoration and a screen reader should skip it.</details>

## Why it matters
A kitchen is not a cook who knows one skill; it is the whole workflow from shopping to washing up. This project joins every skill of the course so far into one app that you could show a friend: it keeps your tasks, filters them, lets you edit them, loads sample tasks from the internet, and can be used with a screen reader.

## What you will build
**Tasks Start**, finished:
- add, toggle, rename and delete tasks, stored in Room;
- **filter chips** All, Open, Done, remembered by DataStore;
- **Task details** screen with a text field and a Save button;
- the sample-task import from lesson 10;
- screen titles marked as headings for TalkBack.

The layers (you will name them at the end):
```text
ui (HomeScreen, DetailScreen, FilterBar, TaskCard)  ->  TasksViewModel  ->  TasksRepository  ->  Room (TaskDao) + DataStore (SettingsStore) + Retrofit (TodoApi)
```

## Before you start
- The project from lesson 11.
- Time: 90 to 120 minutes in two sittings; take the break after Step 5 (all code is in; the TalkBack check comes after the break).
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/kotlin/101-zero-to-hero/phase-3-data-and-polish/12-project-task-list/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

Files that stay **exactly as in lesson 11**: all Gradle files (`settings.gradle.kts`, `build.gradle.kts`, `gradle/libs.versions.toml`, `app/build.gradle.kts`, `gradle.properties`, the wrapper properties), `.gitignore`, the manifest, `Theme.kt`, `MainActivity.kt`, `TasksApplication.kt`, `model/Task.kt`, `AddTaskBar.kt`, `TaskCard.kt`, `data/TaskEntity.kt`, `data/TasksDatabase.kt`, `data/TodoDto.kt`, `data/TodoApi.kt`, `data/TodoClient.kt`, the four icons and the licence file. Changed or new files are shown below.

New words: filter, enum `entries`, `FilterChip`, heading (accessibility), TalkBack, semantics.

## Steps

### Step 1. Plan before typing
Write the feature list down; a plan this small fits on one card.

| Feature | Where it lives |
|---|---|
| Filter All / Open / Done, remembered after restart | `TaskFilter` (model), `SettingsStore` (DataStore), `FilterBar` (UI) |
| Rename a task | `TaskDao.rename`, `TasksRepository.rename`, `TasksViewModel.rename`, `DetailScreen` |
| Empty message depends on the filter | `HomeScreen` |
| Headings for TalkBack | `HomeScreen`, `DetailScreen` |

Notice that each feature touches the layers from the bottom to the top. That is the point of layers: you always know where to start.

### Step 2. Strings
**File: `app/src/main/res/values/strings.xml`**
```xml
<resources>
    <string name="app_name">Tasks Start</string>
    <string name="new_task_label">New task</string>
    <string name="add">Add</string>
    <string name="open_count">%1$d open</string>
    <string name="toggle_task">Mark %1$s as done or open</string>
    <string name="open_details">Open details</string>
    <string name="status_done">Done</string>
    <string name="status_open">Open</string>
    <string name="details">Task details</string>
    <string name="back">Back</string>
    <string name="delete_task">Delete task</string>
    <string name="task_not_found">This task no longer exists.</string>
    <string name="empty_list">No tasks yet. Add one above.</string>
    <string name="empty_filter">No tasks match this filter.</string>
    <string name="load_samples">Load sample tasks</string>
    <string name="loading_samples">Loading sample tasks...</string>
    <string name="samples_done">Added %1$d sample tasks.</string>
    <string name="samples_failed">Could not load the sample tasks. Check your connection and try again.</string>
    <string name="filter_all">All</string>
    <string name="filter_open">Open</string>
    <string name="filter_done">Done</string>
    <string name="title_label">Title</string>
    <string name="save">Save</string>
</resources>
```
New: `empty_filter`, the three `filter_*` labels, `title_label` and `save`. The old `hide_done` is gone.

### Step 3. The model and the data layer
Create `app/src/main/kotlin/com/code101/taskstart/model/TaskFilter.kt`.

**File: `app/src/main/kotlin/com/code101/taskstart/model/TaskFilter.kt`**
```kotlin
package com.code101.taskstart.model

enum class TaskFilter { All, Open, Done }
```
**File: `app/src/main/kotlin/com/code101/taskstart/data/SettingsStore.kt`**
```kotlin
package com.code101.taskstart.data

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.code101.taskstart.model.TaskFilter
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.settingsDataStore by preferencesDataStore(name = "settings")

class SettingsStore(private val context: Context) {
    private val filterKey = stringPreferencesKey("filter")

    val filter: Flow<TaskFilter> = context.settingsDataStore.data.map { preferences ->
        TaskFilter.entries.firstOrNull { it.name == preferences[filterKey] } ?: TaskFilter.All
    }

    suspend fun setFilter(value: TaskFilter) {
        context.settingsDataStore.edit { preferences ->
            preferences[filterKey] = value.name
        }
    }
}
```
**File: `app/src/main/kotlin/com/code101/taskstart/data/TaskDao.kt`**
```kotlin
package com.code101.taskstart.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface TaskDao {
    @Query("SELECT * FROM tasks ORDER BY id")
    fun observeAll(): Flow<List<TaskEntity>>

    @Insert
    suspend fun insert(task: TaskEntity)

    @Insert
    suspend fun insertAll(tasks: List<TaskEntity>)

    @Query("UPDATE tasks SET done = NOT done WHERE id = :id")
    suspend fun toggle(id: Int)

    @Query("UPDATE tasks SET title = :title WHERE id = :id")
    suspend fun rename(id: Int, title: String)

    @Query("DELETE FROM tasks WHERE id = :id")
    suspend fun delete(id: Int)
}
```
**File: `app/src/main/kotlin/com/code101/taskstart/data/TasksRepository.kt`**
```kotlin
package com.code101.taskstart.data

import com.code101.taskstart.model.Task
import com.code101.taskstart.model.TaskFilter
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class TasksRepository(
    private val dao: TaskDao,
    private val settings: SettingsStore,
    private val api: TodoApi,
) {
    val tasks: Flow<List<Task>> = dao.observeAll().map { rows -> rows.map { it.toTask() } }
    val filter: Flow<TaskFilter> = settings.filter

    suspend fun add(title: String) = dao.insert(TaskEntity(title = title))

    suspend fun toggle(id: Int) = dao.toggle(id)

    suspend fun rename(id: Int, title: String) = dao.rename(id, title)

    suspend fun delete(id: Int) = dao.delete(id)

    suspend fun setFilter(value: TaskFilter) = settings.setFilter(value)

    suspend fun importSamples(limit: Int): Int {
        val todos = api.todos(limit)
        dao.insertAll(todos.map { TaskEntity(title = it.title, done = it.completed) })
        return todos.size
    }
}
```
The filter is stored as the enum's text name (`"Open"`). When the stored text is missing or unknown (a first run, or a later version without that name), `?: TaskFilter.All` is the safe default. `TaskFilter.entries` is the list of all enum values.

### Step 4. The ViewModel
**File: `app/src/main/kotlin/com/code101/taskstart/ui/TasksViewModel.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider.AndroidViewModelFactory.Companion.APPLICATION_KEY
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.code101.taskstart.TasksApplication
import com.code101.taskstart.data.TasksRepository
import com.code101.taskstart.model.Task
import com.code101.taskstart.model.TaskFilter
import java.io.IOException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.serialization.SerializationException
import retrofit2.HttpException

sealed interface ImportState {
    data object Idle : ImportState
    data object Loading : ImportState
    data class Done(val count: Int) : ImportState
    data object Failed : ImportState
}

data class TasksUiState(
    val allTasks: List<Task> = emptyList(),
    val filter: TaskFilter = TaskFilter.All,
    val draft: String = "",
    val importState: ImportState = ImportState.Idle,
) {
    val visibleTasks: List<Task>
        get() = when (filter) {
            TaskFilter.All -> allTasks
            TaskFilter.Open -> allTasks.filterNot { it.done }
            TaskFilter.Done -> allTasks.filter { it.done }
        }
}

class TasksViewModel(private val repository: TasksRepository) : ViewModel() {
    private val draft = MutableStateFlow("")
    private val importState = MutableStateFlow<ImportState>(ImportState.Idle)

    val uiState: StateFlow<TasksUiState> = combine(
        repository.tasks,
        repository.filter,
        draft,
        importState,
    ) { tasks, filter, draftText, importValue ->
        TasksUiState(
            allTasks = tasks,
            filter = filter,
            draft = draftText,
            importState = importValue,
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = TasksUiState(),
    )

    fun onDraftChange(text: String) {
        draft.value = text
    }

    fun addTask() {
        val title = draft.value.trim()
        if (title.isEmpty()) return
        draft.value = ""
        viewModelScope.launch { repository.add(title) }
    }

    fun toggle(id: Int) {
        viewModelScope.launch { repository.toggle(id) }
    }

    fun rename(id: Int, title: String) {
        val clean = title.trim()
        if (clean.isEmpty()) return
        viewModelScope.launch { repository.rename(id, clean) }
    }

    fun delete(id: Int) {
        viewModelScope.launch { repository.delete(id) }
    }

    fun onFilterChange(value: TaskFilter) {
        viewModelScope.launch { repository.setFilter(value) }
    }

    fun importSamples() {
        if (importState.value == ImportState.Loading) return
        viewModelScope.launch {
            importState.value = ImportState.Loading
            importState.value = try {
                ImportState.Done(repository.importSamples(limit = 5))
            } catch (e: IOException) {
                ImportState.Failed
            } catch (e: HttpException) {
                ImportState.Failed
            } catch (e: SerializationException) {
                ImportState.Failed
            }
        }
    }

    companion object {
        val Factory = viewModelFactory {
            initializer {
                val app = this[APPLICATION_KEY] as TasksApplication
                TasksViewModel(app.repository)
            }
        }
    }
}
```
`rename` trims and refuses an empty title in the ViewModel too, so the rule holds even if another screen calls it.

### Step 5. The screens
**File: `app/src/main/kotlin/com/code101/taskstart/ui/FilterBar.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.code101.taskstart.R
import com.code101.taskstart.model.TaskFilter
import com.code101.taskstart.ui.theme.TasksTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FilterBar(
    selected: TaskFilter,
    onSelect: (TaskFilter) -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        TaskFilter.entries.forEach { option ->
            FilterChip(
                selected = selected == option,
                onClick = { onSelect(option) },
                label = { Text(stringResource(labelFor(option))) },
            )
        }
    }
}

private fun labelFor(filter: TaskFilter): Int = when (filter) {
    TaskFilter.All -> R.string.filter_all
    TaskFilter.Open -> R.string.filter_open
    TaskFilter.Done -> R.string.filter_done
}

@Preview(showBackground = true)
@Composable
fun FilterBarPreview() {
    TasksTheme {
        FilterBar(selected = TaskFilter.Open, onSelect = { })
    }
}
```
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
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.code101.taskstart.R
import com.code101.taskstart.model.Task
import com.code101.taskstart.model.TaskFilter
import com.code101.taskstart.ui.theme.TasksTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    state: TasksUiState,
    onDraftChange: (String) -> Unit,
    onAdd: () -> Unit,
    onToggle: (Int) -> Unit,
    onOpen: (Int) -> Unit,
    onLoadSamples: () -> Unit,
    onFilterChange: (TaskFilter) -> Unit,
    modifier: Modifier = Modifier,
) {
    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = stringResource(R.string.app_name),
                        modifier = Modifier.semantics { heading() },
                    )
                },
            )
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
                text = stringResource(R.string.open_count, state.allTasks.count { !it.done }),
                style = MaterialTheme.typography.titleMedium,
            )
            FilterBar(selected = state.filter, onSelect = onFilterChange)
            OutlinedButton(
                onClick = onLoadSamples,
                enabled = state.importState != ImportState.Loading,
            ) {
                Text(stringResource(R.string.load_samples))
            }
            ImportStatus(state.importState)
            if (state.visibleTasks.isEmpty()) {
                Text(
                    text = stringResource(
                        if (state.allTasks.isEmpty()) R.string.empty_list else R.string.empty_filter,
                    ),
                )
            }
            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(state.visibleTasks, key = { it.id }) { task ->
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

@Composable
private fun ImportStatus(importState: ImportState) {
    val text = when (importState) {
        ImportState.Idle -> null
        ImportState.Loading -> stringResource(R.string.loading_samples)
        is ImportState.Done -> stringResource(R.string.samples_done, importState.count)
        ImportState.Failed -> stringResource(R.string.samples_failed)
    }
    if (text != null) {
        Text(
            text = text,
            modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite },
        )
    }
}

@Preview(showBackground = true)
@Composable
fun HomeScreenPreview() {
    TasksTheme {
        HomeScreen(
            state = TasksUiState(
                allTasks = listOf(Task(1, "Buy milk"), Task(2, "Pay rent", done = true)),
                filter = TaskFilter.Open,
            ),
            onDraftChange = { },
            onAdd = { },
            onToggle = { },
            onOpen = { },
            onLoadSamples = { },
            onFilterChange = { },
        )
    }
}
```
**File: `app/src/main/kotlin/com/code101/taskstart/ui/DetailScreen.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.code101.taskstart.R
import com.code101.taskstart.model.Task
import com.code101.taskstart.ui.theme.TasksTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DetailScreen(
    task: Task?,
    onBack: () -> Unit,
    onRename: (String) -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var title by rememberSaveable(task?.id) { mutableStateOf(task?.title.orEmpty()) }

    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = stringResource(R.string.details),
                        modifier = Modifier.semantics { heading() },
                    )
                },
                navigationIcon = {
                    TextButton(onClick = onBack) {
                        Text(stringResource(R.string.back))
                    }
                },
            )
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .padding(innerPadding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            if (task == null) {
                Text(text = stringResource(R.string.task_not_found))
            } else {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text(stringResource(R.string.title_label)) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                Button(
                    onClick = { onRename(title) },
                    enabled = title.isNotBlank() && title.trim() != task.title,
                ) {
                    Text(stringResource(R.string.save))
                }
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Icon(
                        painter = painterResource(if (task.done) R.drawable.ic_check else R.drawable.ic_list),
                        contentDescription = null,
                    )
                    Text(
                        text = stringResource(if (task.done) R.string.status_done else R.string.status_open),
                        style = MaterialTheme.typography.titleMedium,
                    )
                }
                OutlinedButton(onClick = onDelete) {
                    Icon(
                        painter = painterResource(R.drawable.ic_trash),
                        contentDescription = null,
                        modifier = Modifier.padding(end = 8.dp),
                    )
                    Text(stringResource(R.string.delete_task))
                }
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
fun DetailScreenPreview() {
    TasksTheme {
        DetailScreen(
            task = Task(1, "Buy milk"),
            onBack = { },
            onRename = { },
            onDelete = { },
        )
    }
}
```
`rememberSaveable(task?.id)` uses the id as a *key*: if the screen is shown for a different task, the text field restarts with that task's title. `Save` is enabled only when the text is not blank and differs from the stored title.

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
fun TasksApp(viewModel: TasksViewModel = viewModel(factory = TasksViewModel.Factory)) {
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
                onLoadSamples = viewModel::importSamples,
                onFilterChange = viewModel::onFilterChange,
            )
        }
        composable(
            route = "detail/{taskId}",
            arguments = listOf(navArgument("taskId") { type = NavType.IntType }),
        ) { entry ->
            val taskId = entry.arguments?.getInt("taskId")
            DetailScreen(
                task = state.allTasks.firstOrNull { it.id == taskId },
                onBack = { navController.popBackStack() },
                onRename = { title ->
                    if (taskId != null) {
                        viewModel.rename(taskId, title)
                    }
                },
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
**Break point:** you can stop here.

Predict before you run: you choose the **Done** chip with no done tasks. Which message appears: the empty list or the empty filter text? Then you close and reopen the app: which chip is selected?

## Run it
Sync Gradle (nothing new to download) and run the app.

Expected result (described, not yet seen):
1. Add "Walk dog". It appears in **All** and **Open**, but not in **Done**.
2. Tick it: it moves out of **Open** and into **Done**; the heading count drops by one.
3. Open its details, change the title, press **Save**, press **Back**: the list shows the new title.
4. Choose **Done**, close the app completely and open it again: the **Done** chip is still selected and the same tasks are present.
5. Press **Load sample tasks** with internet: five more tasks arrive and also survive a restart.

Now the **TalkBack pass** (this is part of the project, not an extra):
1. On the emulator open **Settings > Accessibility > TalkBack** and switch it on (the first time it explains a tutorial; follow it). Swipe right to go to the next item and double tap to activate it.
2. Listen to the order: the title "Tasks Start" should be announced as a heading; the text field and the **Add** button should be read with their labels; each task checkbox should say "Mark ... as done or open"; the filter chips should say whether they are selected.
3. Press **Load sample tasks** with the connection off and listen: the failure sentence should be spoken without you moving the focus (the live region).
4. Switch TalkBack off again (hold both volume keys, or return to the same Settings screen).

Write down every place where TalkBack said something confusing and fix one of them yourself; that is your first accessibility bug report.

## How it works
**Following one feature through the layers.** Pressing the "Open" chip calls `FilterBar.onSelect` → `HomeScreen.onFilterChange` → `TasksViewModel.onFilterChange` → `TasksRepository.setFilter` → `SettingsStore.setFilter` writes `"Open"` in DataStore. DataStore's `filter` flow emits the new value, `combine` builds a new `TasksUiState`, `visibleTasks` is recomputed and the list recomposes. No layer reaches over its neighbour, and nobody calls "refresh".

**Derived data.** `visibleTasks` is a property computed from `allTasks` and `filter`. It is not stored, so it can never disagree with them. Misconception: state must always be stored. Derived values are better computed.

**Enums and `when`.** `when (filter)` over an enum must handle every case; adding a fourth filter will make the compiler point at `visibleTasks` and `labelFor`.

**Accessibility choices.** `heading()` lets TalkBack users jump between headings. A `liveRegion` announces changes. Controls have text labels or descriptions. State is not by colour alone: the filter chips show a check mark when selected, the cards show text and a strike-through.

**What is not in this app.** There are no migrations (changing the entity needs a new `version` and a `Migration`, level 201), no dependency injection library (level 201 uses Hilt), no sign-in and no server of your own (level 201, lessons 04 to 06).

## Try it
1. **Guided:** add `SummaryLine.kt` from the starter, finish the two TODOs, and add `<string name="summary">%1$d open, %2$d done</string>` to `strings.xml`. Check the preview.

**File: `app/src/main/kotlin/com/code101/taskstart/ui/SummaryLine.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import com.code101.taskstart.R
import com.code101.taskstart.ui.theme.TasksTheme

@Composable
fun SummaryLine(openCount: Int, doneCount: Int, modifier: Modifier = Modifier) {
    // TODO 1: show a Text whose text is stringResource(R.string.summary, openCount, doneCount)
    // TODO 2: give the Text the modifier passed in, so that the caller can place it
}

@Preview(showBackground = true)
@Composable
fun SummaryLinePreview() {
    TasksTheme {
        SummaryLine(openCount = 2, doneCount = 3)
    }
}
```
Expected preview: `2 open, 3 done`. Then use it in `HomeScreen` instead of the "n open" heading.
2. **Change:** add a priority to tasks (low, normal, high): a new enum, a new column in `TaskEntity` with a default, a bump of the database `version` to 2 and a migration or, during development only, a fresh install; show it on the card.
3. **Stretch (optional):** add a text search field that filters `visibleTasks` by title. Which layer should own the search text? Defend your answer in two sentences.

<details><summary>Solution</summary>

**File: `app/src/main/kotlin/com/code101/taskstart/ui/SummaryLine.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import com.code101.taskstart.R
import com.code101.taskstart.ui.theme.TasksTheme

@Composable
fun SummaryLine(openCount: Int, doneCount: Int, modifier: Modifier = Modifier) {
    Text(
        text = stringResource(R.string.summary, openCount, doneCount),
        modifier = modifier,
    )
}

@Preview(showBackground = true)
@Composable
fun SummaryLinePreview() {
    TasksTheme {
        SummaryLine(openCount = 2, doneCount = 3)
    }
}
```
The string has two placeholders, `%1$d` and `%2$d`, filled in order by the two numbers.

</details>

## Check yourself
1. Which layers does the "rename" feature touch, from bottom to top? <details><summary>Answer</summary>`TaskDao`, `TasksRepository`, `TasksViewModel`, `DetailScreen` (and the wiring in `TasksApp`).</details>
2. Why is `visibleTasks` computed instead of stored? <details><summary>Answer</summary>A computed value cannot disagree with `allTasks` and `filter`.</details>
3. What happens if the stored filter name is not a valid `TaskFilter`? <details><summary>Answer</summary>`firstOrNull` returns `null` and `?: TaskFilter.All` supplies the default.</details>
4. Name two things you checked with TalkBack and what each should sound like. <details><summary>Answer</summary>For example the checkbox: "Mark Buy milk as done or open"; the title: announced as a heading.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Unresolved reference 'hideDone'` (typical) | A file still uses the lesson 11 name | Replace `hideDone` by `filter` everywhere; search the project (Ctrl+Shift+F) |
| The filter always starts at All | The value is not written, or the key differs between read and write | Use the same `stringPreferencesKey("filter")` in one place |
| Detail shows an old title after switching tasks | `rememberSaveable` without a key | Pass `task?.id` as the key |
| Build error: Room could not find a column (typical) | The DAO query names a column that does not exist | Use `title`, `done`, `id` exactly |
| TalkBack reads "unlabelled" (typical wording) | A control has no text and no description | Add a `contentDescription` or visible text |

## Best practice
Build each feature through the layers from the data upwards, derive what you can instead of storing it, and test with a screen reader before you call it finished. Source: Guide to app architecture https://developer.android.com/topic/architecture and Accessibility testing https://developer.android.com/guide/topics/ui/accessibility/testing

## Going further
- Level 201 starts with the architecture behind this app: `tutorials/kotlin/201-hero-to-super-hero/phase-1-architecture/01-mvvm-and-clean-layers.md`.
- The finished capstone for this stack: `capstones/mobile-kotlin`.

## Summary
- You finished the app by joining Compose, a ViewModel, Room, DataStore and Retrofit.
- You added a persisted filter and an edit screen through all the layers.
- You tested with TalkBack and noted what to fix.
- You named the layers and the job of each one.

## Next lesson
Level 201, lesson 01 (MVVM and clean layers): turn this app's habits into a named architecture.
