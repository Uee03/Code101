---
track: kotlin
level: 201
phase: 1
phase_name: architecture
lesson: 03
title: Coroutines and Flow in depth
time: 75-90 min
prerequisites: [201-01, 201-02]
versions: { kotlinx-coroutines: "1.11.0", lifecycle: "2.11.1", hilt: "2.60.1", kotlin: "2.4.21" }
verified: not yet run
source: source/kotlin/201-hero-to-super-hero/phase-1-architecture/03-coroutines-and-flow-in-depth/
assets: []
---

# 03. Coroutines and Flow in depth

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- explain structured concurrency, cancellation and why `CancellationException` must not be swallowed;
- turn a one-shot repository into an observable `Flow` API with a separate `refresh`;
- build screen state with `combine`, `debounce`, `flatMapLatest` and `stateIn(WhileSubscribed)`;
- send one-off events through a `Channel` and collect them lifecycle-aware.

## Recap
1. What does `viewModelScope` cancel, and when? <details><summary>Answer</summary>Every coroutine started in it, when the ViewModel is cleared.</details>
2. Why is `@Singleton` needed on the repository binding? <details><summary>Answer</summary>All ViewModels must share one instance of the data.</details>

## Why it matters
A pot on the stove does not need you to stand next to it: you do other work and react when it boils. A **Flow** is such a pot: it keeps announcing new values. In lesson 01 each screen asked once and got a list; in an offline-first app (capstone M-18) the screen *observes* a source and a separate action *refreshes* it. Getting concurrency right (cancel old work, keep the UI responsive, do not lose events) is what separates a demo from an app.

## What you will build
Tasks Mini with: a debounced team search, repository reads as `Flow`s, a `refresh` that may fail while cached data stays visible, a snackbar for one-off events, and an injected IO dispatcher. The fake repository fails **once** when you open the Platform Team's projects, so you can see the error state and Retry.

## Before you start
- The project from lesson 02. Time: about 75 to 90 minutes.
- Source pack (optional): every file is shown in full in this lesson. The finished code, starter and solution are in https://github.com/Uee03/Code101 under `source/kotlin/201-hero-to-super-hero/phase-1-architecture/03-coroutines-and-flow-in-depth/` (**Code, Download ZIP**, or `git clone https://github.com/Uee03/Code101.git`).

Files that stay **exactly as in lesson 02**: all Gradle files, `.gitignore`, the manifest, `Theme.kt`, `Models.kt`, `Routes.kt`, `TasksApplication.kt`, `MainActivity.kt`, `RepositoryModule.kt`, `ProjectsScreen.kt`. Changed or new files are shown below.

New words: structured concurrency, cancellation, dispatcher, `Flow`, `combine`, `debounce`, `flatMapLatest`, `stateIn`, `Channel`, one-off event, qualifier.

## Steps

### Step 1. Strings
**File: `app/src/main/res/values/strings.xml`**
```xml
<resources>
    <string name="app_name">Tasks Mini</string>
    <string name="teams">Teams</string>
    <string name="projects">Projects</string>
    <string name="tasks">Tasks</string>
    <string name="back">Back</string>
    <string name="retry">Retry</string>
    <string name="error_offline">The data could not be loaded. Check the connection and try again.</string>
    <string name="empty">Nothing here yet.</string>
    <string name="members">%1$d members</string>
    <string name="new_task">New task</string>
    <string name="add">Add</string>
    <string name="open_count">%1$d open</string>
    <string name="search_teams">Search teams</string>
    <string name="task_added">Task added</string>
    <string name="refresh_failed">Could not refresh. Showing the saved data.</string>
    <string name="status_todo">To do</string>
    <string name="status_in_progress">In progress</string>
    <string name="status_blocked">Blocked</string>
    <string name="status_done">Done</string>
    <string name="status_cancelled">Cancelled</string>
</resources>
```

### Step 2. The domain contract becomes observable
**File: `app/src/main/kotlin/com/code101/tasks/domain/repository/TasksRepository.kt`**
```kotlin
package com.code101.tasks.domain.repository

import com.code101.tasks.domain.model.Project
import com.code101.tasks.domain.model.TaskItem
import com.code101.tasks.domain.model.Team
import kotlinx.coroutines.flow.Flow

interface TasksRepository {
    fun teams(query: String): Flow<List<Team>>

    fun projects(teamId: String): Flow<List<Project>>

    fun tasks(projectId: String): Flow<List<TaskItem>>

    suspend fun refreshTeams()

    suspend fun refreshProjects(teamId: String)

    suspend fun refreshTasks(projectId: String)

    suspend fun addTask(projectId: String, title: String)
}
```
Reads are plain functions that return a `Flow` (no `suspend`: they only describe a stream). Writes and refreshes are `suspend`: they do work and may fail. This split ("observe" and "refresh") is the shape of the capstone's repository.

### Step 3. Inject the dispatcher
A **dispatcher** decides which threads run a coroutine. `Dispatchers.IO` is meant for blocking input and output. Hard-coding it inside a class makes the class hard to control; injecting it keeps the choice in one place.

**File: `app/src/main/kotlin/com/code101/tasks/di/DispatchersModule.kt`**
```kotlin
package com.code101.tasks.di

import javax.inject.Qualifier
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class IoDispatcher

@Module
@InstallIn(SingletonComponent::class)
object DispatchersModule {
    @Provides
    @IoDispatcher
    fun ioDispatcher(): CoroutineDispatcher = Dispatchers.IO
}
```
A `@Qualifier` is a label that tells Hilt which of several values of the same type (`CoroutineDispatcher`) you mean.

### Step 4. The fake repository: a cache that refreshes
**File: `app/src/main/kotlin/com/code101/tasks/data/repository/FakeTasksRepository.kt`**
```kotlin
package com.code101.tasks.data.repository

import com.code101.tasks.di.IoDispatcher
import com.code101.tasks.domain.model.Project
import com.code101.tasks.domain.model.TaskItem
import com.code101.tasks.domain.model.Team
import com.code101.tasks.domain.repository.TasksRepository
import java.io.IOException
import java.util.UUID
import javax.inject.Inject
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.withContext

class FakeTasksRepository @Inject constructor(
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher,
) : TasksRepository {
    private val serverTeams = listOf(
        Team("t1", "Platform Team", "Services and tooling", 4),
        Team("t2", "Mobile Team", "Android and iOS apps", 3),
    )
    private val serverProjects = listOf(
        Project("p1", "t1", "PLAT", "API gateway"),
        Project("p2", "t2", "MOB", "Tasks app"),
    )
    private val serverTasks = mutableListOf(
        TaskItem("k1", "p2", "Draw the login screen", "todo", 1),
        TaskItem("k2", "p2", "Wire the Retrofit client", "in_progress", 1),
        TaskItem("k3", "p1", "Write the OpenAPI file", "done", 3),
    )

    private val cachedTeams = MutableStateFlow<List<Team>>(emptyList())
    private val cachedProjects = MutableStateFlow<List<Project>>(emptyList())
    private val cachedTasks = MutableStateFlow<List<TaskItem>>(emptyList())
    private var outageSimulated = false

    override fun teams(query: String): Flow<List<Team>> =
        cachedTeams.map { teams -> teams.filter { it.name.contains(query, ignoreCase = true) } }

    override fun projects(teamId: String): Flow<List<Project>> =
        cachedProjects.map { projects -> projects.filter { it.teamId == teamId } }

    override fun tasks(projectId: String): Flow<List<TaskItem>> =
        cachedTasks.map { tasks -> tasks.filter { it.projectId == projectId } }

    override suspend fun refreshTeams() {
        withContext(ioDispatcher) {
            delay(300)
            cachedTeams.value = serverTeams
        }
    }

    override suspend fun refreshProjects(teamId: String) {
        withContext(ioDispatcher) {
            delay(300)
            if (teamId == "t1" && !outageSimulated) {
                outageSimulated = true
                throw IOException("Simulated outage")
            }
            cachedProjects.update { current ->
                current.filterNot { it.teamId == teamId } + serverProjects.filter { it.teamId == teamId }
            }
        }
    }

    override suspend fun refreshTasks(projectId: String) {
        withContext(ioDispatcher) {
            delay(300)
            cachedTasks.update { current ->
                current.filterNot { it.projectId == projectId } + serverTasks.filter { it.projectId == projectId }
            }
        }
    }

    override suspend fun addTask(projectId: String, title: String) {
        withContext(ioDispatcher) {
            delay(300)
            val task = TaskItem(UUID.randomUUID().toString(), projectId, title, "todo", 1)
            serverTasks.add(task)
            cachedTasks.update { current -> current + task }
        }
    }
}
```
`withContext(ioDispatcher)` moves the work to the IO threads and comes back, which makes every function **main-safe**: callers on the main thread never block. `MutableStateFlow.update { }` changes the cache atomically.

### Step 5. Shared state helper and scaffold snackbar
**File: `app/src/main/kotlin/com/code101/tasks/ui/common/UiState.kt`**
```kotlin
package com.code101.tasks.ui.common

import com.code101.tasks.R

sealed interface UiState<out T> {
    data object Loading : UiState<Nothing>
    data class Success<T>(val data: T) : UiState<T>
    data class Failure(val messageRes: Int) : UiState<Nothing>
}

fun <T> screenState(data: List<T>, refreshed: Boolean, failed: Boolean): UiState<List<T>> = when {
    data.isNotEmpty() -> UiState.Success(data)
    failed -> UiState.Failure(R.string.error_offline)
    refreshed -> UiState.Success(data)
    else -> UiState.Loading
}
```
`screenState` is the offline-first rule in four lines: show cached data if there is any, even when the refresh failed; otherwise show the error, or "nothing", or the spinner.

**File: `app/src/main/kotlin/com/code101/tasks/ui/components/Components.kt`**
```kotlin
package com.code101.tasks.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.code101.tasks.R
import com.code101.tasks.ui.common.UiState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppScaffold(
    titleRes: Int,
    onBack: (() -> Unit)? = null,
    snackbarHost: @Composable () -> Unit = {},
    content: @Composable (PaddingValues) -> Unit,
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = stringResource(titleRes),
                        modifier = Modifier.semantics { heading() },
                    )
                },
                navigationIcon = {
                    if (onBack != null) {
                        TextButton(onClick = onBack) {
                            Text(stringResource(R.string.back))
                        }
                    }
                },
            )
        },
        snackbarHost = snackbarHost,
        content = content,
    )
}

@Composable
fun <T> UiStateContent(
    state: UiState<T>,
    onRetry: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable (T) -> Unit,
) {
    when (state) {
        UiState.Loading -> Box(
            modifier = modifier.fillMaxSize(),
            contentAlignment = Alignment.Center,
        ) {
            CircularProgressIndicator()
        }
        is UiState.Failure -> Column(
            modifier = modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(text = stringResource(state.messageRes))
            Button(onClick = onRetry) {
                Text(stringResource(R.string.retry))
            }
        }
        is UiState.Success -> content(state.data)
    }
}

fun statusLabel(status: String): Int = when (status) {
    "todo" -> R.string.status_todo
    "in_progress" -> R.string.status_in_progress
    "blocked" -> R.string.status_blocked
    "done" -> R.string.status_done
    else -> R.string.status_cancelled
}
```
The only change: the `snackbarHost` parameter, passed to `Scaffold`.

### Step 6. Teams: search with debounce
**File: `app/src/main/kotlin/com/code101/tasks/ui/teams/TeamsViewModel.kt`**
```kotlin
package com.code101.tasks.ui.teams

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.code101.tasks.domain.model.Team
import com.code101.tasks.domain.repository.TasksRepository
import com.code101.tasks.ui.common.UiState
import com.code101.tasks.ui.common.screenState
import dagger.hilt.android.lifecycle.HiltViewModel
import java.io.IOException
import javax.inject.Inject
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

@HiltViewModel
class TeamsViewModel @Inject constructor(
    private val repository: TasksRepository,
) : ViewModel() {
    private val query = MutableStateFlow("")
    private val refreshed = MutableStateFlow(false)
    private val failed = MutableStateFlow(false)

    val searchText: StateFlow<String> = query.asStateFlow()

    @OptIn(FlowPreview::class, ExperimentalCoroutinesApi::class)
    val state: StateFlow<UiState<List<Team>>> = combine(
        query
            .debounce { text -> if (text.isEmpty()) 0L else 300L }
            .distinctUntilChanged()
            .flatMapLatest { text -> repository.teams(text) },
        refreshed,
        failed,
    ) { teams, isRefreshed, hasFailed ->
        screenState(teams, isRefreshed, hasFailed)
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = UiState.Loading,
    )

    init {
        refresh()
    }

    fun onSearchChange(text: String) {
        query.value = text
    }

    fun refresh() {
        viewModelScope.launch {
            failed.value = false
            try {
                repository.refreshTeams()
            } catch (e: IOException) {
                failed.value = true
            } finally {
                refreshed.value = true
            }
        }
    }
}
```
**File: `app/src/main/kotlin/com/code101/tasks/ui/teams/TeamsScreen.kt`**
```kotlin
package com.code101.tasks.ui.teams

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.code101.tasks.R
import com.code101.tasks.domain.model.Team
import com.code101.tasks.ui.common.UiState
import com.code101.tasks.ui.components.AppScaffold
import com.code101.tasks.ui.components.UiStateContent

@Composable
fun TeamsScreen(
    state: UiState<List<Team>>,
    searchText: String,
    onSearchChange: (String) -> Unit,
    onRetry: () -> Unit,
    onOpenTeam: (String) -> Unit,
) {
    AppScaffold(titleRes = R.string.teams) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            OutlinedTextField(
                value = searchText,
                onValueChange = onSearchChange,
                label = { Text(stringResource(R.string.search_teams)) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )
            UiStateContent(
                state = state,
                onRetry = onRetry,
                modifier = Modifier.weight(1f),
            ) { teams ->
                if (teams.isEmpty()) {
                    Text(text = stringResource(R.string.empty))
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(vertical = 4.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        items(teams, key = { it.id }) { team ->
                            Card(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable { onOpenTeam(team.id) },
                            ) {
                                Column(modifier = Modifier.padding(16.dp)) {
                                    Text(team.name, style = MaterialTheme.typography.titleMedium)
                                    Text(team.description)
                                    Text(stringResource(R.string.members, team.memberCount))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
```

### Step 7. Projects and Tasks
**File: `app/src/main/kotlin/com/code101/tasks/ui/projects/ProjectsViewModel.kt`**
```kotlin
package com.code101.tasks.ui.projects

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.navigation.toRoute
import com.code101.tasks.domain.model.Project
import com.code101.tasks.domain.repository.TasksRepository
import com.code101.tasks.ui.common.UiState
import com.code101.tasks.ui.common.screenState
import com.code101.tasks.ui.navigation.ProjectsRoute
import dagger.hilt.android.lifecycle.HiltViewModel
import java.io.IOException
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

@HiltViewModel
class ProjectsViewModel @Inject constructor(
    private val repository: TasksRepository,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {
    private val teamId = savedStateHandle.toRoute<ProjectsRoute>().teamId
    private val refreshed = MutableStateFlow(false)
    private val failed = MutableStateFlow(false)

    val state: StateFlow<UiState<List<Project>>> = combine(
        repository.projects(teamId),
        refreshed,
        failed,
    ) { projects, isRefreshed, hasFailed ->
        screenState(projects, isRefreshed, hasFailed)
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = UiState.Loading,
    )

    init {
        refresh()
    }

    fun refresh() {
        viewModelScope.launch {
            failed.value = false
            try {
                repository.refreshProjects(teamId)
            } catch (e: IOException) {
                failed.value = true
            } finally {
                refreshed.value = true
            }
        }
    }
}
```
**File: `app/src/main/kotlin/com/code101/tasks/ui/tasks/TasksViewModel.kt`**
```kotlin
package com.code101.tasks.ui.tasks

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.navigation.toRoute
import com.code101.tasks.domain.model.TaskItem
import com.code101.tasks.domain.repository.TasksRepository
import com.code101.tasks.ui.common.UiState
import com.code101.tasks.ui.common.screenState
import com.code101.tasks.ui.navigation.TasksRoute
import dagger.hilt.android.lifecycle.HiltViewModel
import java.io.IOException
import javax.inject.Inject
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

sealed interface TasksEvent {
    data object Added : TasksEvent
    data object RefreshFailed : TasksEvent
}

@HiltViewModel
class TasksViewModel @Inject constructor(
    private val repository: TasksRepository,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {
    private val projectId = savedStateHandle.toRoute<TasksRoute>().projectId
    private val refreshed = MutableStateFlow(false)
    private val failed = MutableStateFlow(false)
    private val eventChannel = Channel<TasksEvent>(Channel.BUFFERED)

    val events: Flow<TasksEvent> = eventChannel.receiveAsFlow()

    val state: StateFlow<UiState<List<TaskItem>>> = combine(
        repository.tasks(projectId),
        refreshed,
        failed,
    ) { tasks, isRefreshed, hasFailed ->
        screenState(tasks, isRefreshed, hasFailed)
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = UiState.Loading,
    )

    init {
        refresh()
    }

    fun refresh() {
        viewModelScope.launch {
            failed.value = false
            try {
                repository.refreshTasks(projectId)
            } catch (e: IOException) {
                failed.value = true
                eventChannel.send(TasksEvent.RefreshFailed)
            } finally {
                refreshed.value = true
            }
        }
    }

    fun addTask(title: String) {
        val clean = title.trim()
        if (clean.isEmpty()) return
        viewModelScope.launch {
            try {
                repository.addTask(projectId, clean)
                eventChannel.send(TasksEvent.Added)
            } catch (e: IOException) {
                eventChannel.send(TasksEvent.RefreshFailed)
            }
        }
    }
}
```
**File: `app/src/main/kotlin/com/code101/tasks/ui/tasks/TasksScreen.kt`**
```kotlin
package com.code101.tasks.ui.tasks

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.repeatOnLifecycle
import com.code101.tasks.R
import com.code101.tasks.domain.model.TaskItem
import com.code101.tasks.ui.common.UiState
import com.code101.tasks.ui.components.AppScaffold
import com.code101.tasks.ui.components.UiStateContent
import com.code101.tasks.ui.components.statusLabel
import kotlinx.coroutines.flow.Flow

@Composable
fun TasksScreen(
    state: UiState<List<TaskItem>>,
    events: Flow<TasksEvent>,
    onRetry: () -> Unit,
    onAdd: (String) -> Unit,
    onBack: () -> Unit,
) {
    var draft by rememberSaveable { mutableStateOf("") }
    val snackbarHostState = remember { SnackbarHostState() }
    val lifecycleOwner = LocalLifecycleOwner.current
    val addedText = stringResource(R.string.task_added)
    val failedText = stringResource(R.string.refresh_failed)

    LaunchedEffect(events, lifecycleOwner) {
        lifecycleOwner.lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) {
            events.collect { event ->
                val message = when (event) {
                    TasksEvent.Added -> addedText
                    TasksEvent.RefreshFailed -> failedText
                }
                snackbarHostState.showSnackbar(message)
            }
        }
    }

    AppScaffold(
        titleRes = R.string.tasks,
        onBack = onBack,
        snackbarHost = { SnackbarHost(snackbarHostState) },
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                OutlinedTextField(
                    value = draft,
                    onValueChange = { draft = it },
                    label = { Text(stringResource(R.string.new_task)) },
                    singleLine = true,
                    modifier = Modifier.weight(1f),
                )
                Button(
                    onClick = {
                        onAdd(draft)
                        draft = ""
                    },
                    enabled = draft.isNotBlank(),
                ) {
                    Text(stringResource(R.string.add))
                }
            }
            UiStateContent(
                state = state,
                onRetry = onRetry,
                modifier = Modifier.weight(1f),
            ) { tasks ->
                if (tasks.isEmpty()) {
                    Text(text = stringResource(R.string.empty))
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        items(tasks, key = { it.id }) { task ->
                            Card(modifier = Modifier.fillMaxWidth()) {
                                Column(modifier = Modifier.padding(16.dp)) {
                                    Text(task.title, style = MaterialTheme.typography.titleMedium)
                                    Text(stringResource(statusLabel(task.status)))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
```

### Step 8. The graph
**File: `app/src/main/kotlin/com/code101/tasks/ui/navigation/AppGraph.kt`**
```kotlin
package com.code101.tasks.ui.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.code101.tasks.ui.projects.ProjectsScreen
import com.code101.tasks.ui.projects.ProjectsViewModel
import com.code101.tasks.ui.tasks.TasksScreen
import com.code101.tasks.ui.tasks.TasksViewModel
import com.code101.tasks.ui.teams.TeamsScreen
import com.code101.tasks.ui.teams.TeamsViewModel

@Composable
fun AppGraph() {
    val navController = rememberNavController()

    NavHost(navController = navController, startDestination = TeamsRoute) {
        composable<TeamsRoute> {
            val viewModel: TeamsViewModel = hiltViewModel()
            val state by viewModel.state.collectAsStateWithLifecycle()
            val searchText by viewModel.searchText.collectAsStateWithLifecycle()
            TeamsScreen(
                state = state,
                searchText = searchText,
                onSearchChange = viewModel::onSearchChange,
                onRetry = viewModel::refresh,
                onOpenTeam = { teamId -> navController.navigate(ProjectsRoute(teamId)) },
            )
        }
        composable<ProjectsRoute> {
            val viewModel: ProjectsViewModel = hiltViewModel()
            val state by viewModel.state.collectAsStateWithLifecycle()
            ProjectsScreen(
                state = state,
                onRetry = viewModel::refresh,
                onOpenProject = { projectId -> navController.navigate(TasksRoute(projectId)) },
                onBack = { navController.popBackStack() },
            )
        }
        composable<TasksRoute> {
            val viewModel: TasksViewModel = hiltViewModel()
            val state by viewModel.state.collectAsStateWithLifecycle()
            TasksScreen(
                state = state,
                events = viewModel.events,
                onRetry = viewModel::refresh,
                onAdd = viewModel::addTask,
                onBack = { navController.popBackStack() },
            )
        }
    }
}
```
Predict before you run: open **Platform Team**, then **Projects**. What do you see first, and what happens when you press **Retry**? Type "mob" in the Teams search: what appears, and after how long?

## Run it
Expected result (described, not yet seen): Teams show a spinner, then both teams. Typing "mob" shows only "Mobile Team" about 0.3 s after you stop typing. Opening Platform Team's projects shows the error text and **Retry** (the fake fails once); Retry shows "API gateway". In the Mobile Team's project, adding a task shows a "Task added" snackbar.

## How it works
**Structured concurrency.** Every coroutine has a parent scope: `viewModelScope` here. When the scope ends, its children are cancelled, so no request outlives its screen and none can leak. Inside a function, `coroutineScope { }` groups children and waits for them; if one child fails the others are cancelled (use `supervisorScope` when siblings should survive each other).

**Cancellation is cooperative.** Suspending functions such as `delay` check for cancellation and throw `CancellationException`. Never swallow it: `catch (e: Exception)` would also catch it, so either catch narrower types (as here, `IOException`) or rethrow `CancellationException`. `finally` still runs on cancellation, which is why `refreshed.value = true` lives there.

**Dispatchers and main-safety.** The main thread draws the screen. A function that does slow work should switch with `withContext` itself, so callers need not know; that is *main-safety*. Injecting `@IoDispatcher` keeps the choice replaceable.

**Cold flows vs state.** A plain `Flow` is *cold*: it runs when someone collects it. `StateFlow` is *hot*: it holds a current value. `stateIn(viewModelScope, WhileSubscribed(5_000), initial)` turns a cold chain into a hot state that is shared by all collectors, stays alive for 5 seconds after the last collector leaves (so a rotation does not restart it) and stops after that. Misconception: `WhileSubscribed(0)` is "more efficient". It restarts the upstream on every rotation.

**The operators.**
| Operator | Job here |
|---|---|
| `combine` | rebuild the screen state whenever the data, `refreshed` or `failed` changes |
| `debounce` | wait until the user pauses typing; the lambda form lets an empty query pass at once |
| `distinctUntilChanged` | ignore the same query twice |
| `flatMapLatest` | start a new inner flow for each query and cancel the previous one |

`debounce` is marked `@FlowPreview` and `flatMapLatest` `@ExperimentalCoroutinesApi`; `@OptIn` records that you accept that.

**One-off events.** A snackbar must show once. If it were part of `UiState`, it would reappear after a rotation. A `Channel` delivers each event to exactly one collector; `Channel.BUFFERED` holds events that arrive while no one collects. The UI collects inside `repeatOnLifecycle(STARTED)`, so nothing is shown while the app is in the background.

**Why this, not that.**
| Choice | Alternative | Why |
|---|---|---|
| `Channel` + `receiveAsFlow` | `SharedFlow` with no replay | A SharedFlow without a collector drops events; a Channel buffers them |
| Events as a stream | a `message: String?` field in state plus "message shown" call | The field needs a manual reset and loses the guarantee of showing once |
| `refresh` separate from observe | one `suspend fun teams(): List<Team>` | Screens keep showing data while a refresh runs or fails (capstone M-18) |

**Where this reappears.** `SyncScheduler` in the capstone combines flows exactly like `TeamsViewModel` (`combine(online, status, outboxSize)`); lesson 08 builds it.

## Try it
1. **Guided:** the starter `OpenCount.kt` has an extension on `Flow<List<TaskItem>>` that does not do its job yet. Fill the TODO.

**File: `app/src/main/kotlin/com/code101/tasks/ui/tasks/OpenCount.kt`**
```kotlin
package com.code101.tasks.ui.tasks

import com.code101.tasks.domain.model.TaskItem
import kotlinx.coroutines.flow.Flow

// TODO: map each list of tasks to the number of tasks that are not "done" and not "cancelled",
// and let the flow emit only when that number really changes
fun Flow<List<TaskItem>>.toOpenCount(): Flow<Int> = this as Flow<Int>
```
Expected: a flow of lists with open counts 2, 2, 1 emits 2 and then 1.
2. **Change:** expose `val openCount: StateFlow<Int>` in `TasksViewModel` with `repository.tasks(projectId).toOpenCount().stateIn(...)`, and show it with `R.string.open_count` above the list.
3. **Stretch (optional):** replace `refreshed`/`failed` by one `MutableStateFlow` of a small `RefreshState` enum. What gets simpler?

<details><summary>Solution</summary>

**File: `app/src/main/kotlin/com/code101/tasks/ui/tasks/OpenCount.kt`**
```kotlin
package com.code101.tasks.ui.tasks

import com.code101.tasks.domain.model.TaskItem
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map

fun Flow<List<TaskItem>>.toOpenCount(): Flow<Int> =
    map { tasks -> tasks.count { it.status != "done" && it.status != "cancelled" } }
        .distinctUntilChanged()
```
</details>

## Check yourself
1. Why must you not write `catch (e: Exception) { }` around a `suspend` call? <details><summary>Answer</summary>It swallows `CancellationException` and breaks cancellation; catch narrower types or rethrow it.</details>
2. What does `flatMapLatest` do when a new query arrives? <details><summary>Answer</summary>It cancels the previous inner flow and starts one for the new query.</details>
3. Why is a snackbar an event and not state? <details><summary>Answer</summary>State is replayed after rotation; an event must be shown once.</details>
4. What does `WhileSubscribed(5_000)` buy you? <details><summary>Answer</summary>The upstream survives short gaps such as a rotation, and stops when the screen is really gone.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| A build error about an experimental or preview API on `debounce`/`flatMapLatest` (typical) | Missing `@OptIn` | Add `@OptIn(FlowPreview::class, ExperimentalCoroutinesApi::class)` |
| The snackbar shows twice after a rotation | The event was kept in state | Use a `Channel` for events |
| Type mismatch on `stateIn(initialValue = UiState.Loading)` (typical) | The flow's element type is not `UiState<...>` | Make `screenState` return `UiState<List<T>>` as shown |
| The screen restarts its loading after every rotation | `SharingStarted.Eagerly` or `WhileSubscribed(0)` | Use `WhileSubscribed(5_000)` |
| Hilt reports a missing binding for `CoroutineDispatcher` (typical) | The qualifier annotation is missing on the parameter | Add `@IoDispatcher` to the constructor parameter |

## Best practice
Expose `StateFlow` from ViewModels, keep one-off events in a `Channel`, collect with lifecycle awareness and never swallow `CancellationException`. Source: Kotlin coroutines best practices https://developer.android.com/kotlin/coroutines/coroutines-best-practices and StateFlow and SharedFlow https://developer.android.com/kotlin/flow/stateflow-and-sharedflow

## Going further
- Coroutines and Flow on Android: https://developer.android.com/kotlin/flow
- Capstone chapters 03 and 04 use these patterns for the cache and the outbox.

## Summary
- You explained structured concurrency and cooperative cancellation.
- You built an observe-plus-refresh repository and an offline-first screen state.
- You used `combine`, `debounce`, `flatMapLatest` and `stateIn`, and delivered one-off events through a `Channel`.

## Next lesson (not written yet)
04. A generated API client with Retrofit/OkHttp (status: planned).
