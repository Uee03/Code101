package com.code101.tasks.ui.login

import android.content.Intent
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.code101.tasks.data.auth.AuthStateManager
import com.code101.tasks.domain.repository.SessionStatus
import dagger.hilt.android.lifecycle.HiltViewModel
import java.io.IOException
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

// The sign-in flow hands around Android Intents, so this one ViewModel talks to the auth class directly.
@HiltViewModel
class SessionViewModel @Inject constructor(
    private val auth: AuthStateManager,
) : ViewModel() {
    val status: StateFlow<SessionStatus> = auth.status

    private val _busy = MutableStateFlow(false)
    val busy: StateFlow<Boolean> = _busy.asStateFlow()

    private val _error = MutableStateFlow(false)
    val error: StateFlow<Boolean> = _error.asStateFlow()

    init {
        viewModelScope.launch { auth.restore() }
    }

    fun signIn(launch: (Intent) -> Unit) {
        viewModelScope.launch {
            _busy.value = true
            _error.value = false
            try {
                launch(auth.loginIntent())
            } catch (e: IOException) {
                _error.value = true
                _busy.value = false
            } catch (e: IllegalArgumentException) {
                _error.value = true
                _busy.value = false
            }
        }
    }

    fun onLoginResult(data: Intent?) {
        viewModelScope.launch {
            try {
                if (data != null) auth.acceptLogin(data)
            } catch (e: IOException) {
                _error.value = true
            } finally {
                _busy.value = false
            }
        }
    }

    fun signOut(launch: (Intent) -> Unit) {
        viewModelScope.launch {
            val intent = auth.logoutIntent()
            if (intent != null) launch(intent) else auth.clear()
        }
    }

    fun onLogoutResult(ok: Boolean) {
        viewModelScope.launch {
            if (ok) auth.clear() else _error.value = true
        }
    }
}
