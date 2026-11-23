package com.code101.tasks.ui.sync

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.code101.tasks.domain.model.ApiFailure
import com.code101.tasks.domain.repository.TasksRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import java.io.IOException
import javax.inject.Inject
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

@HiltViewModel
class SyncViewModel @Inject constructor(
    private val repository: TasksRepository,
) : ViewModel() {
    val pendingCount: StateFlow<Int> = repository.pendingCount.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = 0,
    )

    fun syncNow() {
        viewModelScope.launch {
            try {
                repository.sync()
            } catch (e: ApiFailure) {
                // The row stays in the queue and is retried with backoff.
            } catch (e: IOException) {
                // Offline: the queue keeps the work.
            }
        }
    }
}
