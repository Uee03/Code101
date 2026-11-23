package com.code101.tasks.ui.navigation

import android.app.Activity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.code101.tasks.domain.repository.SessionStatus
import com.code101.tasks.ui.login.LoginScreen
import com.code101.tasks.ui.login.SessionViewModel

@Composable
fun AppRoot(viewModel: SessionViewModel = hiltViewModel()) {
    val status by viewModel.status.collectAsStateWithLifecycle()
    val busy by viewModel.busy.collectAsStateWithLifecycle()
    val error by viewModel.error.collectAsStateWithLifecycle()

    val loginLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.StartActivityForResult(),
    ) { result -> viewModel.onLoginResult(result.data) }
    val logoutLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.StartActivityForResult(),
    ) { result -> viewModel.onLogoutResult(result.resultCode == Activity.RESULT_OK) }

    when (status) {
        SessionStatus.Checking -> Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center,
        ) {
            CircularProgressIndicator()
        }
        SessionStatus.SignedOut -> LoginScreen(
            busy = busy,
            error = error,
            onSignIn = { viewModel.signIn { intent -> loginLauncher.launch(intent) } },
        )
        SessionStatus.SignedIn -> AppGraph(
            onSignOut = { viewModel.signOut { intent -> logoutLauncher.launch(intent) } },
        )
    }
}
