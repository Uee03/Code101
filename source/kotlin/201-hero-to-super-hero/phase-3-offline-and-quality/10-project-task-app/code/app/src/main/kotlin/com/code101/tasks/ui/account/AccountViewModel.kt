package com.code101.tasks.ui.account

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.code101.tasks.R
import com.code101.tasks.domain.model.ApiFailure
import com.code101.tasks.domain.model.Profile
import com.code101.tasks.domain.repository.AccountRepository
import com.code101.tasks.domain.repository.TasksRepository
import com.code101.tasks.ui.common.UiState
import com.code101.tasks.ui.common.failureMessage
import dagger.hilt.android.lifecycle.HiltViewModel
import java.io.IOException
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

@HiltViewModel
class AccountViewModel @Inject constructor(
    private val account: AccountRepository,
    tasks: TasksRepository,
) : ViewModel() {
    private val _profile = MutableStateFlow<UiState<Profile>>(UiState.Loading)
    val profile: StateFlow<UiState<Profile>> = _profile.asStateFlow()

    private val _deleted = MutableStateFlow(false)
    val deleted: StateFlow<Boolean> = _deleted.asStateFlow()

    val pendingCount: StateFlow<Int> = tasks.pendingCount.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = 0,
    )

    init {
        load()
    }

    fun load() {
        viewModelScope.launch {
            _profile.value = UiState.Loading
            _profile.value = try {
                UiState.Success(account.profile())
            } catch (e: ApiFailure) {
                UiState.Failure(failureMessage(e))
            } catch (e: IOException) {
                UiState.Failure(R.string.problem_offline)
            }
        }
    }

    fun deleteOfflineData() {
        viewModelScope.launch {
            account.clearOfflineData()
            _deleted.value = true
        }
    }
}
