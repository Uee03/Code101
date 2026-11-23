package com.code101.tasks.ui.login

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.code101.tasks.R
import com.code101.tasks.domain.repository.SessionStatus

@Composable
fun SessionScreen(status: SessionStatus, busy: Boolean, error: Boolean,
                  login: () -> Unit, logout: () -> Unit) {
    Column(Modifier.fillMaxSize().padding(24.dp)) {
        Text(stringResource(R.string.app_name), style = MaterialTheme.typography.headlineMedium)
        Text(stringResource(if (status == SessionStatus.Checking) R.string.session_check else
            if (status == SessionStatus.SignedOut) R.string.login else R.string.teams))
        when (status) {
            SessionStatus.Checking -> CircularProgressIndicator()
            SessionStatus.SignedOut -> Button(onClick = login, enabled = !busy) {
                Icon(painterResource(R.drawable.ic_log_in), contentDescription = null)
                Text(stringResource(R.string.sign_in))
            }
            SessionStatus.SignedIn -> {
                Text(stringResource(R.string.teams))
                Button(onClick = logout, enabled = !busy) { Text(stringResource(R.string.sign_out)) }
            }
        }
        if (busy) CircularProgressIndicator()
        if (error) Text(stringResource(R.string.auth_error))
    }
}
