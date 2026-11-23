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
