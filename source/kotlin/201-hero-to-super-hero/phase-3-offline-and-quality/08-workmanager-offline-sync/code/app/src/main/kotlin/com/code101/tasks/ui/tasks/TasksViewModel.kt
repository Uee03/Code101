package com.code101.tasks.ui.tasks

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.navigation.toRoute
import com.code101.tasks.R
import com.code101.tasks.domain.model.ApiFailure
import com.code101.tasks.domain.model.TaskItem
import com.code101.tasks.domain.repository.TasksRepository
import com.code101.tasks.ui.common.UiState
import com.code101.tasks.ui.common.failureMessage
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
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

sealed interface TasksEvent {
    data object Added : TasksEvent
    data class Message(val messageRes: Int) : TasksEvent
}

@HiltViewModel
class TasksViewModel @Inject constructor(
    private val repository: TasksRepository,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {
    private val projectId = savedStateHandle.toRoute<TasksRoute>().projectId
    private val refreshed = MutableStateFlow(false)
    private val failure = MutableStateFlow<Int?>(null)
    private val eventChannel = Channel<TasksEvent>(Channel.BUFFERED)
    private val _titleError = MutableStateFlow<Int?>(null)

    val events: Flow<TasksEvent> = eventChannel.receiveAsFlow()
    val titleError: StateFlow<Int?> = _titleError.asStateFlow()

    val state: StateFlow<UiState<List<TaskItem>>> = combine(
        repository.tasks(projectId),
        refreshed,
        failure,
    ) { tasks, isRefreshed, failureRes ->
        screenState(tasks, isRefreshed, failureRes)
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
            failure.value = null
            try {
                repository.refreshTasks(projectId)
            } catch (e: ApiFailure) {
                failure.value = failureMessage(e)
            } catch (e: IOException) {
                failure.value = failureMessage(e)
            } finally {
                refreshed.value = true
            }
        }
    }

    fun clearTitleError() {
        _titleError.value = null
    }

    fun addTask(title: String) {
        val clean = title.trim()
        if (clean.isEmpty() || clean.length > MAX_TITLE) {
            _titleError.value = R.string.error_title_invalid
            return
        }
        viewModelScope.launch {
            repository.addTask(projectId, clean)
            _titleError.value = null
            eventChannel.send(TasksEvent.Added)
        }
    }

    private companion object {
        const val MAX_TITLE = 200
    }
}
