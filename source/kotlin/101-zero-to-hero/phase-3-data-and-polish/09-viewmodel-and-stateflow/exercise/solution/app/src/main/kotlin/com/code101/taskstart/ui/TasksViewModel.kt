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
