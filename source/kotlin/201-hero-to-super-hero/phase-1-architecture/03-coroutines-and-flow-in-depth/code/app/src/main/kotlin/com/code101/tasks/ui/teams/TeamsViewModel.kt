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
