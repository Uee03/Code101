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
