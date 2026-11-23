---
track: kotlin
level: 201
phase: 3
phase_name: offline-and-quality
lesson: 10
title: "Project: a task app against the platform contract"
time: 120-150 min
prerequisites: [201-06, 201-08, 201-09]
versions: { agp: "9.5.1", gradle: "9.6.0", kotlin: "2.4.21", compose-bom: "2026.11.01", room: "2.8.5", workmanager: "2.12.0" }
verified: not yet run
source: source/kotlin/201-hero-to-super-hero/phase-3-offline-and-quality/10-project-task-app/
assets: []
---

# 10. Project: a task app against the platform contract

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- finish an offline-first feature end to end: UI, ViewModel, repository, local database, outbox, API call;
- send a versioned change with `If-Match` and explain 412 and 428;
- build an account screen with a profile, a confirmed destructive action and sign-out;
- run a written manual test session of the whole app and know what the capstone adds.

## Recap
1. What does an outbox row store for a change made offline? <details><summary>Answer</summary>The kind, the entity id, the payload, the base version, the state and the retry timing, under an idempotency key.</details>
2. Why does the app show "Waiting to sync" as words? <details><summary>Answer</summary>State must never be shown by colour alone (lesson 09).</details>
3. Which class refreshes the access token, and how often at the same time? <details><summary>Answer</summary>`AuthStateManager`, one refresh at a time (single flight).</details>

## Why it matters
Every earlier lesson added one layer. A project is where the layers meet: one small feature must touch all of them in the right order, and you find out whether the architecture *helps* you or only looks neat. The feature here is "mark a task done". It looks tiny, but it needs a stored version, an `If-Match` header, an optimistic local change, a retry rule, a conflict rule and an accessible button. That is what most real mobile work looks like.

## What you will build
Tasks Mini now works against the platform contract (the backend and Keycloak from the capstone):
- a **Mark done** button on each task, working offline (optimistic change, queued, sent with `If-Match: "<version>"`);
- an **Account** screen: name and e-mail from `GET /v1/me`, the number of changes waiting, **Delete offline data** (with a confirmation) and **Sign out**;
- a written manual test session (no automated tests: the course teaches no test lessons).

## Before you start
- Lessons 01 to 09 done; the project from lesson 09. Time: 2 to 2.5 hours.
- The backend running on port 8000 and Keycloak (realm `tasksteams`) on port 8180 as in lesson 06, with `adb reverse tcp:8180 tcp:8180` for the emulator. The capstone `capstones/mobile-kotlin/README.md` lists the start commands.
- Source pack (optional): https://github.com/Uee03/Code101 under `source/kotlin/201-hero-to-super-hero/phase-3-offline-and-quality/10-project-task-app/` (**Code, Download ZIP**, or `git clone https://github.com/Uee03/Code101.git`).

**Files that stay as in lesson 09:** everything not listed below. **New:** `AccountRepository.kt`, `DefaultAccountRepository.kt`, `AccountViewModel.kt`, `AccountScreen.kt`. **Replaced in full:** `TaskRow.kt`. **Changed (regions shown):** `Models.kt`, `TasksRepository.kt`, `CacheDao.kt`, `RemoteDataSource.kt`, `OfflineFirstTasksRepository.kt`, `RepositoryModule.kt`, `Routes.kt`, `AppGraph.kt`, `TeamsScreen.kt`, `TasksScreen.kt`, `TasksViewModel.kt`, `strings.xml`.

New words: optimistic update, precondition, `If-Match`, ETag, 412 Precondition Failed, 428 Precondition Required, server wins, destructive action.

## Steps

### Step 1. Plan the slice before typing
Write the path of one tap on **Mark done**, top to bottom. It is the checklist for the next steps.
1. `TaskRow` button -> `TasksScreen.onComplete(taskId)` -> `TasksViewModel.completeTask`.
2. `TasksRepository.completeTask(taskId)` (domain interface).
3. `OfflineFirstTasksRepository`: read the row, refuse if it is not `synced` or already done, **in one transaction** mark it done + `pending` and insert an outbox row with `base_version`; ask the scheduler to sync.
4. `sync()` sends `complete_task`: `RemoteDataSource.completeTask(id, version)` -> `POST /v1/tasks/{id}/complete` with `If-Match: "<version>"`.
5. Success: the server's task (new version) replaces the local row and the outbox row is deleted. Failure: retry later (network, 408/425/429/5xx) or park (any other 4xx).

Predict: why can a task that is itself still waiting for its *create* not be completed yet? (Answer in Step 3.)

### Step 2. Domain: a profile and one new operation
**File: `app/src/main/kotlin/com/code101/tasks/domain/model/Models.kt`** (added before `TaskItem`)
```kotlin
data class Profile(
    val displayName: String,
    val email: String,
)
```
**File: `app/src/main/kotlin/com/code101/tasks/domain/repository/TasksRepository.kt`** (added before `sync()`)
```kotlin
    suspend fun completeTask(taskId: String)
```
**File: `app/src/main/kotlin/com/code101/tasks/domain/repository/AccountRepository.kt`**
```kotlin
package com.code101.tasks.domain.repository

import com.code101.tasks.domain.model.Profile

interface AccountRepository {
    suspend fun profile(): Profile

    suspend fun clearOfflineData()
}
```
The domain stays plain Kotlin: no Retrofit, no Room, no Android classes.

### Step 3. The local database: new queries
**File: `app/src/main/kotlin/com/code101/tasks/data/local/CacheDao.kt`** (changed regions)

Added next to the other queries, and `replaceTasks` replaced:
```kotlin
    @Query("SELECT * FROM tasks WHERE id = :id")
    abstract suspend fun findTask(id: String): TaskRow?

    @Query("SELECT id FROM tasks WHERE project_id = :projectId AND sync_state = 'pending'")
    abstract suspend fun pendingTaskIds(projectId: String): List<String>

    @Query("UPDATE tasks SET status = 'done', sync_state = 'pending' WHERE id = :id")
    abstract suspend fun markDonePending(id: String)

    @Transaction
    open suspend fun replaceTasks(projectId: String, rows: List<TaskRow>) {
        val keep = pendingTaskIds(projectId).toSet()
        clearSyncedTasks(projectId)
        upsertTasks(rows.filter { it.id !in keep })
    }
```
Added before `park`:
```kotlin
    @Transaction
    open suspend fun queueComplete(taskId: String, outbox: OutboxRow) {
        markDonePending(taskId)
        insertOutbox(outbox)
    }

    @Transaction
    open suspend fun completeUpdate(outboxId: String, server: TaskRow) {
        upsertTasks(listOf(server))
        deleteOutbox(outboxId)
    }
```
- No new table and no new column, so **the database stays at version 2**: the schema is unchanged and no migration is needed.
- `replaceTasks` now skips server rows for tasks that still have a pending change. Without it, a refresh would overwrite your optimistic "done" with the old server state and the task would flicker back.
- A task that is itself `pending` (its create has not been sent) has only a local id, and the server does not know it, so it cannot be completed yet: the button is hidden until the row is `synced`.

### Step 4. The remote call with `If-Match`
**File: `app/src/main/kotlin/com/code101/tasks/data/remote/RemoteDataSource.kt`** (changed regions)

Added import:
```kotlin
import com.code101.tasks.domain.model.Profile
```
Added at the end of the class:
```kotlin
    suspend fun completeTask(taskId: String, version: Int): TaskItem =
        tasksApi.completeTask(
            ifMatch = "\"$version\"",
            taskId = UUID.fromString(taskId),
        ).required().toDomain()

    suspend fun me(): Profile {
        val me = platformApi.getMe().required()
        return Profile(displayName = me.displayName, email = me.email)
    }
```
The contract defines the `ETag` as the quoted `version`, and `If-Match` must carry the quotes: `"3"`, not `3`. Missing header gives **428**, a stale version gives **412** (see `contract/openapi.yaml`). The generated `completeTask` takes the header as its first parameter, so you cannot forget it.

### Step 5. The repository: optimistic change and sending
**File: `app/src/main/kotlin/com/code101/tasks/data/repository/OfflineFirstTasksRepository.kt`** (changed regions)

Added before `sync()`:
```kotlin
    override suspend fun completeTask(taskId: String) {
        val task = dao.findTask(taskId) ?: return
        if (task.syncState != "synced" || task.status == "done") return
        val now = System.currentTimeMillis()
        dao.queueComplete(
            taskId = taskId,
            outbox = OutboxRow(
                id = UUID.randomUUID().toString(),
                kind = "complete_task",
                entityId = taskId,
                parentId = task.projectId,
                payload = "{}",
                baseVersion = task.version,
                state = "pending",
                attempts = 0,
                nextAttemptAt = now,
                problem = null,
                createdAt = now,
            ),
        )
        scheduler.syncSoon()
    }
```
In `send(row)`, a new branch before the `else`:
```kotlin
            "complete_task" -> {
                val version = row.baseVersion
                if (version == null) {
                    dao.park(row.id, row.entityId, "missing version")
                } else {
                    val updated = remote.completeTask(row.entityId, version)
                    dao.completeUpdate(row.id, updated.toRow())
                }
            }
            else -> dao.park(row.id, row.entityId, "unknown kind")
```
- `baseVersion` is the version the user *saw* when they tapped. The server compares it with the current one: equal means the change is applied, different means 412 and someone else changed the task first.
- The existing `sync()` loop already handles the failures: retryable statuses and `IOException` back off and stop the loop, other 4xx statuses are **parked** (the outbox row is kept with the problem text, the task shows "Could not be saved").
- **Conflict policy: server wins.** After a 412 the row shows the failure text; the next refresh replaces it with the server's task, because only rows with a *pending* change are protected in `replaceTasks`. Letting the user choose (keep mine or theirs) is a product decision covered in the capstone chapter on conflicts.

### Step 6. The account repository
**File: `app/src/main/kotlin/com/code101/tasks/data/repository/DefaultAccountRepository.kt`**
```kotlin
package com.code101.tasks.data.repository

import com.code101.tasks.data.local.TasksDatabase
import com.code101.tasks.data.remote.RemoteDataSource
import com.code101.tasks.di.IoDispatcher
import com.code101.tasks.domain.model.Profile
import com.code101.tasks.domain.repository.AccountRepository
import javax.inject.Inject
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.withContext

class DefaultAccountRepository @Inject constructor(
    private val remote: RemoteDataSource,
    private val database: TasksDatabase,
    @IoDispatcher private val io: CoroutineDispatcher,
) : AccountRepository {
    override suspend fun profile(): Profile = remote.me()

    override suspend fun clearOfflineData() {
        withContext(io) { database.clearAllTables() }
    }
}
```
`clearAllTables()` is blocking, so it runs on the injected IO dispatcher. It empties the cache **and the outbox**: that is why the screen asks for confirmation and shows how many changes are still waiting.

**File: `app/src/main/kotlin/com/code101/tasks/di/RepositoryModule.kt`** (changed regions)
```kotlin
import com.code101.tasks.data.repository.DefaultAccountRepository
import com.code101.tasks.domain.repository.AccountRepository
```
and inside the module class:
```kotlin
    @Binds
    @Singleton
    abstract fun accountRepository(impl: DefaultAccountRepository): AccountRepository
```

### Step 7. The account screen
**File: `app/src/main/kotlin/com/code101/tasks/ui/account/AccountViewModel.kt`**
```kotlin
package com.code101.tasks.ui.account

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.code101.tasks.R
import com.code101.tasks.domain.model.ApiFailure
import com.code101.tasks.domain.model.Profile
import com.code101.tasks.domain.repository.AccountRepository
import com.code101.tasks.domain.repository.TasksRepository
import com.code101.tasks.ui.common.UiState
import com.code101.tasks.ui.common.failureMessage
import dagger.hilt.android.lifecycle.HiltViewModel
import java.io.IOException
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

@HiltViewModel
class AccountViewModel @Inject constructor(
    private val account: AccountRepository,
    tasks: TasksRepository,
) : ViewModel() {
    private val _profile = MutableStateFlow<UiState<Profile>>(UiState.Loading)
    val profile: StateFlow<UiState<Profile>> = _profile.asStateFlow()

    private val _deleted = MutableStateFlow(false)
    val deleted: StateFlow<Boolean> = _deleted.asStateFlow()

    val pendingCount: StateFlow<Int> = tasks.pendingCount.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = 0,
    )

    init {
        load()
    }

    fun load() {
        viewModelScope.launch {
            _profile.value = UiState.Loading
            _profile.value = try {
                UiState.Success(account.profile())
            } catch (e: ApiFailure) {
                UiState.Failure(failureMessage(e))
            } catch (e: IOException) {
                UiState.Failure(R.string.problem_offline)
            }
        }
    }

    fun deleteOfflineData() {
        viewModelScope.launch {
            account.clearOfflineData()
            _deleted.value = true
        }
    }
}
```
**File: `app/src/main/kotlin/com/code101/tasks/ui/account/AccountScreen.kt`**
```kotlin
package com.code101.tasks.ui.account

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.code101.tasks.R
import com.code101.tasks.domain.model.Profile
import com.code101.tasks.ui.common.UiState
import com.code101.tasks.ui.components.AppScaffold
import com.code101.tasks.ui.components.UiStateContent

@Composable
fun AccountScreen(
    profile: UiState<Profile>,
    pendingCount: Int,
    deleted: Boolean,
    onRetry: () -> Unit,
    onDeleteOfflineData: () -> Unit,
    onSignOut: () -> Unit,
    onBack: () -> Unit,
) {
    var confirming by rememberSaveable { mutableStateOf(false) }

    AppScaffold(titleRes = R.string.account, onBack = onBack) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            UiStateContent(state = profile, onRetry = onRetry) { person ->
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(stringResource(R.string.signed_in_as))
                    Text(person.displayName, style = MaterialTheme.typography.titleLarge)
                    Text(person.email)
                }
            }
            Text(stringResource(R.string.offline_data), style = MaterialTheme.typography.titleMedium)
            Text(
                if (pendingCount > 0) {
                    pluralStringResource(R.plurals.pending_banner, pendingCount, pendingCount)
                } else {
                    stringResource(R.string.nothing_pending)
                },
            )
            OutlinedButton(onClick = { confirming = true }) {
                Text(stringResource(R.string.delete_offline_data))
            }
            if (deleted) {
                Text(
                    text = stringResource(R.string.offline_deleted),
                    modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite },
                )
            }
            Button(onClick = onSignOut) {
                Text(stringResource(R.string.sign_out))
            }
        }
    }

    if (confirming) {
        AlertDialog(
            onDismissRequest = { confirming = false },
            title = { Text(stringResource(R.string.delete_confirm_title)) },
            text = { Text(stringResource(R.string.delete_confirm_body)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        confirming = false
                        onDeleteOfflineData()
                    },
                ) {
                    Text(stringResource(R.string.delete))
                }
            },
            dismissButton = {
                TextButton(onClick = { confirming = false }) {
                    Text(stringResource(R.string.cancel))
                }
            },
        )
    }
}
```
- `confirming` is `rememberSaveable`, so the dialog survives rotation.
- The dialog says what is lost, and the button label says what it does ("Delete", not "OK").
- Sign out is passed in from `AppGraph`: the screen does not know about Intents or AppAuth (lesson 06).

### Step 8. The task row and screen: the button
**File: `app/src/main/kotlin/com/code101/tasks/ui/tasks/TaskRow.kt`** (replaces the lesson 09 file)
```kotlin
package com.code101.tasks.ui.tasks

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.code101.tasks.R
import com.code101.tasks.domain.model.TaskItem
import com.code101.tasks.ui.components.statusLabel

@Composable
fun TaskRow(task: TaskItem, onComplete: () -> Unit, modifier: Modifier = Modifier) {
    val canComplete = task.status != "done" &&
        task.status != "cancelled" &&
        task.syncState == "synced"
    Card(modifier = modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier
                .heightIn(min = 48.dp)
                .padding(16.dp),
        ) {
            Column(modifier = Modifier.semantics(mergeDescendants = true) { }) {
                Text(task.title, style = MaterialTheme.typography.titleMedium)
                Text(stringResource(statusLabel(task.status)))
                when (task.syncState) {
                    "pending" -> Text(stringResource(R.string.waiting_to_sync))
                    "failed" -> Text(
                        text = stringResource(R.string.sync_failed),
                        color = MaterialTheme.colorScheme.error,
                    )
                }
            }
            if (canComplete) {
                val description = stringResource(R.string.mark_done_for, task.title)
                TextButton(
                    onClick = onComplete,
                    modifier = Modifier.semantics { contentDescription = description },
                ) {
                    Text(stringResource(R.string.mark_done))
                }
            }
        }
    }
}
```
- The merged texts are now in an **inner** column, and the button sits next to it: TalkBack reads the task as one item, then "Mark done: <title>" as a separate button (a descendant that is itself an interactive, merging node stays a separate stop; confirm with TalkBack).
- The description *starts with* the visible label ("Mark done"), so voice-control users who say what they see still match it. The title is added so a list of identical buttons is not ambiguous.
- Material 3 buttons keep a 48 dp minimum touch target.

**File: `app/src/main/kotlin/com/code101/tasks/ui/tasks/TasksScreen.kt`** (two changed regions)
In the parameter list, add `onComplete` before `onBack`:
```kotlin
    onAdd: (String) -> Unit,
    onComplete: (String) -> Unit,
    onBack: () -> Unit,
```
and in the lazy list:
```kotlin
                            TaskRow(task, onComplete = { onComplete(task.id) })
```
**File: `app/src/main/kotlin/com/code101/tasks/ui/tasks/TasksViewModel.kt`** (added before the `companion object`)
```kotlin
    fun completeTask(taskId: String) {
        viewModelScope.launch {
            repository.completeTask(taskId)
            eventChannel.send(TasksEvent.Message(R.string.task_marked_done))
        }
    }
```

### Step 9. Navigation and strings
**File: `app/src/main/kotlin/com/code101/tasks/ui/navigation/Routes.kt`** (added)
```kotlin
@Serializable
data object AccountRoute
```
**File: `app/src/main/kotlin/com/code101/tasks/ui/navigation/AppGraph.kt`** (changed regions)

New imports:
```kotlin
import com.code101.tasks.ui.account.AccountScreen
import com.code101.tasks.ui.account.AccountViewModel
```
In the Teams destination, the sign-out argument becomes the account argument:
```kotlin
                    onCheckConnection = connectionViewModel::check,
                    onOpenAccount = { navController.navigate(AccountRoute) },
```
In the Tasks destination, add the callback, and add a new destination right after it:
```kotlin
                    onAdd = viewModel::addTask,
                    onComplete = viewModel::completeTask,
                    onBack = { navController.popBackStack() },
                )
            }
            composable<AccountRoute> {
                val viewModel: AccountViewModel = hiltViewModel()
                val profile by viewModel.profile.collectAsStateWithLifecycle()
                val pending by viewModel.pendingCount.collectAsStateWithLifecycle()
                val deleted by viewModel.deleted.collectAsStateWithLifecycle()
                AccountScreen(
                    profile = profile,
                    pendingCount = pending,
                    deleted = deleted,
                    onRetry = viewModel::load,
                    onDeleteOfflineData = viewModel::deleteOfflineData,
                    onSignOut = onSignOut,
                    onBack = { navController.popBackStack() },
                )
```
(The closing `}` of the destination is the one that was already there.)

**File: `app/src/main/kotlin/com/code101/tasks/ui/teams/TeamsScreen.kt`** (two changed regions)
The parameter `onSignOut: () -> Unit,` becomes:
```kotlin
    onOpenAccount: () -> Unit,
```
and the sign-out button in the connection row becomes:
```kotlin
                TextButton(onClick = onOpenAccount) {
                    Text(stringResource(R.string.account))
                }
```
**File: `app/src/main/res/values/strings.xml`** (the `sign_out` line is followed by these new lines)
```xml
    <string name="mark_done">Mark done</string>
    <string name="mark_done_for">Mark done: %1$s</string>
    <string name="task_marked_done">Marked done. It will sync when you are online.</string>
    <string name="account">Account</string>
    <string name="signed_in_as">Signed in as</string>
    <string name="offline_data">Offline data</string>
    <string name="nothing_pending">Everything is synced.</string>
    <string name="delete_offline_data">Delete offline data</string>
    <string name="delete_confirm_title">Delete offline data?</string>
    <string name="delete_confirm_body">Saved copies and any changes still waiting to sync are removed from this phone. This cannot be undone.</string>
    <string name="delete">Delete</string>
    <string name="cancel">Cancel</string>
    <string name="offline_deleted">Offline data deleted.</string>
```

Predict before you run: if you tap **Mark done** in airplane mode, what do you see immediately, and what do you see after you switch the network back on?

## Run it
Start the backend and Keycloak, sign in as a seeded user, and run the manual session below. Write "pass" or what you saw next to each line. This session is your test: the course has no automated test lessons.

| # | Do | Expect (described, not yet seen) |
|---|----|------|
| 1 | Cold start, sign in | Teams list appears; connection line shows the backend database |
| 2 | Open a team, a project | Lists load; rotating keeps the screen |
| 3 | Add a task online | Task appears at once as "Waiting to sync", then "To do" after a short moment |
| 4 | Airplane mode on, add a task | Banner "1 change is waiting to sync"; task shows "Waiting to sync" |
| 5 | Airplane mode on, **Mark done** on a synced task | Status becomes "Done" and "Waiting to sync"; button disappears; snackbar |
| 6 | Airplane mode off | Within a short time the banner disappears and both tasks read as synced |
| 7 | Mark a task done on another client (or with the HTTP file from the capstone), then mark it done here before refreshing | The row shows "Could not be saved ..." (412); after leaving and re-opening the screen it shows the server's state |
| 8 | Account screen | Your name and e-mail; "Everything is synced." |
| 9 | Delete offline data -> Cancel, then again -> Delete | Cancel changes nothing; Delete empties the lists (they refill on the next refresh) |
| 10 | Sign out, then kill and restart the app | Login screen; no tokens in `adb shell run-as com.code101.tasks.lab ls files` beyond encrypted data stores |
| 11 | TalkBack on, walk the Tasks screen | One stop per task, then a "Mark done: ..." button |

If any row fails, note the real message; do not edit the expectation to match.

## How it works
**Why a version?** Two people edit the same task. Without a check, the second save silently overwrites the first ("lost update"). With **optimistic concurrency**, each save names the version it started from (`If-Match`); the server applies it only if that version is still current, otherwise it answers 412 and nothing is overwritten. The client must then decide what to do; here the server wins.

**Optimistic UI + outbox.** The UI changes at once (the user sees "Done"), the real change travels later. The outbox is the promise to deliver it; the `pending` text is the honest state in between.

**Why one transaction in `queueComplete`?** If the row were marked done and the app died before the outbox row was inserted, the task would claim a change that nothing will ever send. Both writes happen together or not at all.

**Why this, not that.**
| Choice | Alternative | Why |
|---|---|---|
| Send `base_version` stored at tap time | Read the current version when sending | The user's decision was based on what they saw; a newer version means a conflict, and silently using it would overwrite it |
| Server wins on 412 | Last write wins, or a merge dialog | Simple, safe and honest; a merge UI needs product rules (capstone) |
| Hide the button until `synced` | Queue a complete after a create | A create's version is unknown until the server answers; chaining needs id mapping |
| `clearAllTables()` behind a confirmation | Silent wipe on sign out | The outbox may hold work the user has not delivered |

**Where this fails.** A 412 is also what you get when your own earlier request *succeeded* but the response was lost: the version moved. The app then shows a failure for a change that was in fact applied; the next refresh shows the truth. A stricter design compares the fetched task with the intended change before reporting a failure. Also, `clearAllTables()` does not remove the signed-in session or tokens: sign out for that.

**Where this reappears.** The capstone `capstones/mobile-kotlin` finishes this app: all resource screens (teams, projects, tasks with filters, edit and delete), conflict screens, release build, and ship notes.

## Try it
1. **Guided:** move the "can this task be completed?" rule out of the UI. Add `domain/model/TaskRules.kt` with `fun TaskItem.canComplete(): Boolean`. The starter returns `false` with a TODO; implement it and use it in `TaskRow` instead of the local `val canComplete`.

**File (starter): `app/src/main/kotlin/com/code101/tasks/domain/model/TaskRules.kt`**
```kotlin
package com.code101.tasks.domain.model

fun TaskItem.canComplete(): Boolean {
    // TODO: true only when the status is not "done" or "cancelled" AND syncState is "synced"
    return false
}
```
Expected: the button shows for a synced "To do" task and not for a done, cancelled or waiting one.

2. **Change:** in the `AccountScreen`, show the app version (`BuildConfig.VERSION_NAME`) under the profile. Where would you read it so the composable stays free of Android classes?
3. **Stretch (optional):** add a **Reopen** button for done tasks. Which API do you call (see `TasksApi.updateTask` and `TaskUpdate`), which `If-Match` value, and which outbox `kind` string?

<details><summary>Solution</summary>

**File: `app/src/main/kotlin/com/code101/tasks/domain/model/TaskRules.kt`**
```kotlin
package com.code101.tasks.domain.model

fun TaskItem.canComplete(): Boolean =
    status != "done" && status != "cancelled" && syncState == "synced"
```
In `TaskRow.kt` add `import com.code101.tasks.domain.model.canComplete`, delete the local `val canComplete = ...` and write `if (task.canComplete()) {`.
</details>

## Check yourself
1. What happens if `If-Match` is missing, and what if it is stale? <details><summary>Answer</summary>428 Precondition Required, and 412 Precondition Failed.</details>
2. Why does `replaceTasks` skip rows with a pending change? <details><summary>Answer</summary>So a refresh does not overwrite the user's optimistic change before it is delivered.</details>
3. Why is the confirmation dialog needed for "Delete offline data"? <details><summary>Answer</summary>It also deletes the outbox: changes not yet delivered would be lost.</details>
4. Why does the schema version stay at 2? <details><summary>Answer</summary>No table or column changed; only new queries and a new `kind` value.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `428` on every complete (typical) | `If-Match` not sent | Use the generated `completeTask(ifMatch, taskId)`; check the header with the debug logging interceptor |
| `412` on the first try (typical) | Header sent without quotes (`3`) or an old version | Send `"\"$version\""` |
| The task flips back to "To do" after a refresh | `replaceTasks` did not protect pending rows | Keep the `pendingTaskIds` filter |
| `Cannot access database on the main thread` (typical) | `clearAllTables()` called on the main thread | Call it inside `withContext(io)` |
| Hilt error "AccountRepository cannot be provided" (typical) | The `@Binds` is missing from `RepositoryModule` | Add it and rebuild |
| The button appears on a task that is still waiting | The `syncState == "synced"` check is missing | Restore it in `canComplete` |

## Best practice
Make every user change a small, versioned, idempotent unit of work that is stored before it is sent, and say honestly in the UI what state it is in. Source: Android guidance on offline-first apps https://developer.android.com/topic/architecture/data-layer/offline-first and the HTTP semantics for conditional requests, RFC 9110 section 13 https://www.rfc-editor.org/rfc/rfc9110#name-conditional-requests

## Going further
- Continue with the full capstone: `capstones/mobile-kotlin/README.md` and its TDD.
- Android app architecture recommendations: https://developer.android.com/topic/architecture/recommendations
- Level 301 (planned for this track) is not written yet; the capstone is your next step.

## Summary
- You added one feature through every layer: UI, ViewModel, repository, Room, outbox and API.
- You sent a versioned change with `If-Match` and chose a conflict policy.
- You built an account screen with a confirmed destructive action and ran a written manual session.

## Next lesson
This is the last lesson of the 201 level. Continue with the capstone `capstones/mobile-kotlin`.
