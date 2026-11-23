package com.code101.tasks.ui.tasks

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.code101.tasks.R
import com.code101.tasks.domain.model.TaskItem
import com.code101.tasks.ui.components.statusLabel

@Composable
fun TaskRow(task: TaskItem, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .semantics(mergeDescendants = true) { },
    ) {
        Column(
            modifier = Modifier
                .heightIn(min = 48.dp)
                .padding(16.dp),
        ) {
            Text(task.title, style = MaterialTheme.typography.titleMedium)
            Text(stringResource(statusLabel(task.status)))
            when (task.syncState) {
                "pending" -> Text(stringResource(R.string.waiting_to_sync))
                "failed" -> Text(
                    text = stringResource(R.string.sync_failed),
                    color = MaterialTheme.colorScheme.error,
                )
            }
        }
    }
}
