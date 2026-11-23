package com.code101.taskstart.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.code101.taskstart.data.TodoClient
import com.code101.taskstart.model.Task
import java.io.IOException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
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
    val tasks: List<Task> = listOf(
        Task(1, "Buy milk"),
        Task(2, "Call dentist"),
        Task(3, "Pay rent", done = true),
    ),
    val draft: String = "",
    val importState: ImportState = ImportState.Idle,
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

    fun importSamples() {
        if (_uiState.value.importState == ImportState.Loading) return
        viewModelScope.launch {
            _uiState.update { it.copy(importState = ImportState.Loading) }
            try {
                val todos = TodoClient.api.todos(limit = 5)
                _uiState.update { state ->
                    val start = (state.tasks.maxOfOrNull { it.id } ?: 0) + 1
                    val added = todos.mapIndexed { index, todo ->
                        Task(start + index, todo.title, todo.completed)
                    }
                    state.copy(
                        tasks = state.tasks + added,
                        importState = ImportState.Done(added.size),
                    )
                }
            } catch (e: IOException) {
                _uiState.update { it.copy(importState = ImportState.Failed) }
            } catch (e: HttpException) {
                _uiState.update { it.copy(importState = ImportState.Failed) }
            } catch (e: SerializationException) {
                _uiState.update { it.copy(importState = ImportState.Failed) }
            }
        }
    }
}
