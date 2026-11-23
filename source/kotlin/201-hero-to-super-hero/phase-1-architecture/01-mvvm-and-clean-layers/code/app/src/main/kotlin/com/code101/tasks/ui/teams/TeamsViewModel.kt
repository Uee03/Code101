package com.code101.tasks.ui.teams

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.code101.tasks.R
import com.code101.tasks.domain.model.Team
import com.code101.tasks.domain.repository.TasksRepository
import com.code101.tasks.ui.common.UiState
import java.io.IOException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class TeamsViewModel(private val repository: TasksRepository) : ViewModel() {
    private val _state = MutableStateFlow<UiState<List<Team>>>(UiState.Loading)
    val state: StateFlow<UiState<List<Team>>> = _state.asStateFlow()

    init {
        load()
    }

    fun load() {
        viewModelScope.launch {
            _state.value = UiState.Loading
            _state.value = try {
                UiState.Success(repository.teams())
            } catch (e: IOException) {
                UiState.Failure(R.string.error_offline)
            }
        }
    }

    companion object {
        fun factory(repository: TasksRepository) = viewModelFactory {
            initializer { TeamsViewModel(repository) }
        }
    }
}
