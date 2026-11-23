package com.code101.tasks.ui.tasks

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.code101.tasks.R
import com.code101.tasks.domain.model.TaskItem
import com.code101.tasks.domain.repository.TasksRepository
import com.code101.tasks.ui.common.UiState
import java.io.IOException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class TasksViewModel(
    private val repository: TasksRepository,
    private val projectId: String,
) : ViewModel() {
    private val _state = MutableStateFlow<UiState<List<TaskItem>>>(UiState.Loading)
    val state: StateFlow<UiState<List<TaskItem>>> = _state.asStateFlow()

    init {
        load()
    }

    fun load() {
        viewModelScope.launch {
            _state.value = UiState.Loading
            _state.value = try {
                UiState.Success(repository.tasks(projectId))
            } catch (e: IOException) {
                UiState.Failure(R.string.error_offline)
            }
        }
    }

    fun addTask(title: String) {
        val clean = title.trim()
        if (clean.isEmpty()) return
        viewModelScope.launch {
            try {
                repository.addTask(projectId, clean)
                _state.value = UiState.Success(repository.tasks(projectId))
            } catch (e: IOException) {
                _state.value = UiState.Failure(R.string.error_offline)
            }
        }
    }

    companion object {
        fun factory(repository: TasksRepository, projectId: String) = viewModelFactory {
            initializer { TasksViewModel(repository, projectId) }
        }
    }
}
