package com.code101.tasks.ui.sync

import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.code101.tasks.R
import com.code101.tasks.ui.SyncViewModel
import com.code101.tasks.ui.components.*

@Composable
fun SyncScreen(vm: SyncViewModel, conflict: (String) -> Unit) {
    val state by vm.state.collectAsStateWithLifecycle()
    PageFrame(R.string.sync_queue, state) {
        item {
            Text(stringResource(R.string.queue_warning))
            Action(R.string.sync_now, R.drawable.ic_refresh_cw, !state.busy) { vm.sync() }
        }
        if (state.data.outbox.isEmpty()) item { Text(stringResource(R.string.empty)) }
        items(state.data.outbox.sortedBy { it.seq }, key = { it.id }) { write ->
            Value(R.string.id, write.entityId); Text(wireLabel(write.state))
            write.problem?.let { Text(problemText(it)) }
            if (write.state == "conflict") TextButton(onClick = { conflict(write.entityId) }) { Text(stringResource(R.string.conflict)) }
            else TextButton(onClick = { vm.retry(write.id) }, enabled = !state.busy) { Text(stringResource(R.string.retry)) }
            TextButton(onClick = { vm.discard(write.id) }, enabled = !state.busy) { Text(stringResource(R.string.discard)) }
        }
    }
}
