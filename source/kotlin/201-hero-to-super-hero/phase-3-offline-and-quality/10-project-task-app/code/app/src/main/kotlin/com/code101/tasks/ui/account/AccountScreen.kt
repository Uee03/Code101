package com.code101.tasks.ui.account

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.code101.tasks.R
import com.code101.tasks.domain.model.Profile
import com.code101.tasks.ui.common.UiState
import com.code101.tasks.ui.components.AppScaffold
import com.code101.tasks.ui.components.UiStateContent

@Composable
fun AccountScreen(
    profile: UiState<Profile>,
    pendingCount: Int,
    deleted: Boolean,
    onRetry: () -> Unit,
    onDeleteOfflineData: () -> Unit,
    onSignOut: () -> Unit,
    onBack: () -> Unit,
) {
    var confirming by rememberSaveable { mutableStateOf(false) }

    AppScaffold(titleRes = R.string.account, onBack = onBack) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            UiStateContent(state = profile, onRetry = onRetry) { person ->
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(stringResource(R.string.signed_in_as))
                    Text(person.displayName, style = MaterialTheme.typography.titleLarge)
                    Text(person.email)
                }
            }
            Text(stringResource(R.string.offline_data), style = MaterialTheme.typography.titleMedium)
            Text(
                if (pendingCount > 0) {
                    pluralStringResource(R.plurals.pending_banner, pendingCount, pendingCount)
                } else {
                    stringResource(R.string.nothing_pending)
                },
            )
            OutlinedButton(onClick = { confirming = true }) {
                Text(stringResource(R.string.delete_offline_data))
            }
            if (deleted) {
                Text(
                    text = stringResource(R.string.offline_deleted),
                    modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite },
                )
            }
            Button(onClick = onSignOut) {
                Text(stringResource(R.string.sign_out))
            }
        }
    }

    if (confirming) {
        AlertDialog(
            onDismissRequest = { confirming = false },
            title = { Text(stringResource(R.string.delete_confirm_title)) },
            text = { Text(stringResource(R.string.delete_confirm_body)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        confirming = false
                        onDeleteOfflineData()
                    },
                ) {
                    Text(stringResource(R.string.delete))
                }
            },
            dismissButton = {
                TextButton(onClick = { confirming = false }) {
                    Text(stringResource(R.string.cancel))
                }
            },
        )
    }
}
