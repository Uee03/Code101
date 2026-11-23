package com.code101.tasks.ui.teams

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.code101.tasks.R
import com.code101.tasks.data.remote.RemoteDataSource
import com.code101.tasks.domain.model.ApiFailure
import com.code101.tasks.ui.common.UiState
import com.code101.tasks.ui.common.failureMessage
import dagger.hilt.android.lifecycle.HiltViewModel
import java.io.IOException
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

// A data-layer probe kept from lesson 04; the real calls go through TasksRepository.
@HiltViewModel
class ConnectionViewModel @Inject constructor(
    private val remote: RemoteDataSource,
) : ViewModel() {
    private val _state = MutableStateFlow<UiState<String>>(UiState.Loading)
    val state: StateFlow<UiState<String>> = _state.asStateFlow()

    init {
        check()
    }

    fun check() {
        viewModelScope.launch {
            _state.value = UiState.Loading
            _state.value = try {
                UiState.Success(remote.health())
            } catch (e: ApiFailure) {
                UiState.Failure(failureMessage(e))
            } catch (e: IOException) {
                UiState.Failure(R.string.error_connection)
            }
        }
    }
}
