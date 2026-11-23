package com.code101.tasks.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.code101.tasks.domain.model.*
import com.code101.tasks.domain.repository.TasksRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ScreenState(val data: Snapshot = Snapshot(), val busy: Boolean = false,
    val problem: ApiProblem? = null, val connectionName: String? = null)
open class ScreenModel(protected val repository: TasksRepository) : ViewModel() {
    private val operation = MutableStateFlow(ScreenState())
    val state = combine(repository.snapshot, operation) { data, op -> op.copy(data = data) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), ScreenState())
    val online = repository.online
    val backendKind = repository.backendKind
    val baseUrl = repository.baseUrl
    private val events = Channel<Unit>(Channel.BUFFERED)
    val saved = events.receiveAsFlow()
    protected fun action(block: suspend () -> Unit) {
        if (operation.value.busy) return
        viewModelScope.launch {
            operation.value = operation.value.copy(busy = true, problem = null)
            try { block() }
            catch (e: CancellationException) { throw e }
            catch (e: ApiFailure) { operation.value = operation.value.copy(problem = e.problem) }
            catch (_: IllegalArgumentException) { operation.value = operation.value.copy(problem = ApiProblem("bad-request", "", 400)) }
            catch (_: IllegalStateException) { operation.value = operation.value.copy(problem = ApiProblem("queue-not-empty", "", 0)) }
            catch (_: Exception) { operation.value = operation.value.copy(problem = ApiProblem("offline", "", 0)) }
            finally { operation.value = operation.value.copy(busy = false) }
        }
    }
    fun sync() = action { repository.sync() }
    fun save(projectId: String, id: String?, key: String, draft: TaskDraft, original: TaskItem?) = action {
        repository.save(projectId, id, key, draft, original); events.send(Unit); repository.sync()
    }
    fun resolve(id: String, keep: Set<String>) = action { repository.resolve(id, keep) }
    fun retry(id: String) = action { repository.retry(id) }
    fun discard(id: String) = action { repository.discard(id) }
    fun complete(id: String) = action { repository.complete(id); repository.sync() }
    fun comment(id: String, body: String, key: String) = action { repository.comment(id, body, key); repository.sync() }
    fun deleteComment(id: String) = action { repository.deleteComment(id) }
    fun backend(kind: Backend, url: String) = action { repository.backend(kind, url) }
    fun connection() = action {
        val name = repository.connection(); operation.value = operation.value.copy(connectionName = name)
    }
}
@HiltViewModel
class TeamsViewModel @Inject constructor(repo: TasksRepository) : ScreenModel(repo) {
    fun load(q: String) = action { repository.teams(q) }
}
@HiltViewModel
class ProjectsViewModel @Inject constructor(repo: TasksRepository) : ScreenModel(repo) {
    fun load(id: String, archived: Boolean) = action { repository.projects(id, archived) }
}
@HiltViewModel
class TasksViewModel @Inject constructor(repo: TasksRepository) : ScreenModel(repo) {
    fun load(id: String, statuses: Set<String>, sort: String, more: Boolean = false) =
        action { repository.tasks(id, statuses, sort, more) }
}
@HiltViewModel
class TaskDetailViewModel @Inject constructor(repo: TasksRepository) : ScreenModel(repo) {
    fun load(id: String) = action { repository.detail(id) }
}
@HiltViewModel
class TaskFormViewModel @Inject constructor(repo: TasksRepository) : ScreenModel(repo) {
    fun load(id: String) = action { repository.detail(id) }
}
@HiltViewModel
class SettingsViewModel @Inject constructor(repo: TasksRepository) : ScreenModel(repo)
@HiltViewModel
class SyncViewModel @Inject constructor(repo: TasksRepository) : ScreenModel(repo)
