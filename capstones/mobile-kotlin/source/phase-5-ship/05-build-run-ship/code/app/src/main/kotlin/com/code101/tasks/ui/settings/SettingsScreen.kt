package com.code101.tasks.ui.settings

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.foundation.selection.toggleable
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.code101.tasks.R
import com.code101.tasks.domain.model.Backend
import com.code101.tasks.ui.SettingsViewModel
import com.code101.tasks.ui.components.*

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun SettingsScreen(vm: SettingsViewModel, queue: () -> Unit, logout: (Boolean) -> Unit) {
    val state by vm.state.collectAsStateWithLifecycle()
    val persistedBackend by vm.backendKind.collectAsStateWithLifecycle()
    val base by vm.baseUrl.collectAsStateWithLifecycle()
    var custom by rememberSaveable { mutableStateOf("") }
    var backend by rememberSaveable { mutableStateOf(persistedBackend) }
    var delete by rememberSaveable { mutableStateOf(false) }
    LaunchedEffect(persistedBackend) { backend = persistedBackend }
    LaunchedEffect(base) { custom = base }
    PageFrame(R.string.settings, state) {
        item {
            Text(stringResource(R.string.backend))
            FlowRow {
                listOf(Backend.AspNet to R.string.aspnet, Backend.Python to R.string.python,
                    Backend.Go to R.string.go, Backend.Custom to R.string.custom).forEach { (kind, label) ->
                    FilterChip(backend == kind, { backend = kind }, label = { Text(stringResource(label)) })
                }
            }
            Value(R.string.base_url, base)
            if (backend == Backend.Custom) {
                OutlinedTextField(custom, { custom = it }, label = { Text(stringResource(R.string.custom)) })
                Text(stringResource(R.string.backend_warning))
            }
            Action(R.string.apply_backend, R.drawable.ic_settings, !state.busy) { vm.backend(backend, custom) }
            Action(R.string.connection_test, R.drawable.ic_refresh_cw, !state.busy) { vm.connection() }
            state.connectionName?.let { Text(stringResource(R.string.connection_ok, it)) }
            state.data.me?.let { me ->
                Value(R.string.account, me.name)
                Value(R.string.roles, me.roles.joinToString())
                Value(R.string.scopes, me.scopes.joinToString())
            }
            Action(R.string.sync_queue, R.drawable.ic_wifi_off, click = queue)
            Row(Modifier.fillMaxWidth().heightIn(min = 48.dp).toggleable(delete, role = Role.Checkbox, onValueChange = { delete = it })) {
                Checkbox(delete, null); Text(stringResource(R.string.delete_offline))
            }
            Action(R.string.sign_out, R.drawable.ic_log_out, !state.busy) { logout(delete) }
        }
    }
}
